# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""The pacing model, and a real session measured against it (brief §13).

Two kinds of number, and only one is a measurement:

- **The model** is the tree's own arithmetic: what each tier costs, read from
  mods/tiamat_default_science/tree.lua by tools/check_tree.py, against the
  income per hour §13 aims for. It says how long a tier SHOULD take.
- **A measurement** is a real session's log. With `pacing_log` on (Progress's
  default) every change to a player's insight is one line in the server's
  log:

      tiamat_default_progress: pacing t=<tick> player=<12 hex> source=<source> delta=<n> total=<n>

  Given that log, this tool tallies what one player earned, from where, hour
  by hour; works out which tier they were climbing from what they had spent;
  and sets each hour's income beside the target for that tier, naming the
  numbers in config.lua that pay each source. It changes nothing: after a
  real session only config.lua changes, and a person changes it.

Writes docs/pacing.md: the model, then the measurement of every log given so
far (a log measured again replaces its own section). Standard library only.
Run from the repository root:

    python tools/pacing.py                       # the model alone
    python tools/pacing.py --log server.log      # and a session, its busiest player
    python tools/pacing.py --log server.log --player 1a2b3c4d5e6f
"""
import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_tree  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "pacing.md"

TICKS_PER_HOUR = 20 * 60 * 60

# §13: the income per hour each tier is tuned for. Tiers 1 and 2 are the
# Tinker's Bench, bought with the shared tree's income and not modelled.
TARGET = {3: 450, 4: 600, 5: 1000, 6: 1150, 7: 1600}

# What pays each source, in config.lua (or tree.lua, for what things cost).
LEVERS = {
    "found_stars": "C.families.star, C.families.spectrum (insight per star, per spectrum)",
    "found_specimens": "C.families.specimen",
    "found_weather": "C.families.weather",
    "found_climate": "C.families.climate",
    "found_bodies": "C.body_family",
    "found_inventions": "C.inventions (each first), C.tier5_toys .. C.tier7_toys",
    "found_toybox": "C.toybox, C.tier4_toys",
    "found_reading": "C.reading (insight, cap)",
    "study": "C.tier3_studies .. C.tier7_studies (insight, ticks)",
    "spent": "the costs in tree.lua",
}

LINE = re.compile(r"pacing t=(\d+) player=([0-9a-f]+) source=(\S+) delta=(-?\d+) total=(-?\d+)")


def tiers():
    """`{tier: total insight}` for the whole tree, and the spine's share."""
    by_id, problems = check_tree.check(check_tree.load())
    if problems:
        sys.exit("the tree is not sound: run tools/check_tree.py")
    on_spine = check_tree.spine(by_id)
    whole, spine = defaultdict(int), defaultdict(int)
    for nid, n in by_id.items():
        whole[n["tier"]] += n["cost"]
        if nid in on_spine:
            spine[n["tier"]] += n["cost"]
    return dict(whole), dict(spine)


def model_section():
    whole, spine = tiers()
    rows = ["| Tier | Whole tier (insight) | On the spine | Target income / hour | Hours, whole tier | Hours, spine |",
            "|---|---|---|---|---|---|"]
    th = ts = 0.0
    for tier in sorted(TARGET):
        h, s = whole[tier] / TARGET[tier], spine[tier] / TARGET[tier]
        th, ts = th + h, ts + s
        rows.append(f"| {tier} | {whole[tier]:,} | {spine[tier]:,} | {TARGET[tier]:,} | {h:.1f} | {s:.1f} |")
    rows.append(f"| **all** | **{sum(whole[t] for t in TARGET):,}** | **{sum(spine[t] for t in TARGET):,}** | "
                f"| **{th:.1f}** | **{ts:.1f}** |")
    return "\n".join(rows)


def read_log(path):
    """Every pacing line in a log: `(tick, player, source, delta, total)`."""
    out = []
    with open(path, encoding="utf8", errors="replace") as f:
        for line in f:
            m = LINE.search(line)
            if m:
                out.append((int(m[1]), m[2], m[3], int(m[4]), int(m[5])))
    return out


def tier_at(spent, whole):
    """The tier a player is climbing once they have spent `spent` on the tree:
    every tier below it bought whole. An estimate — a player who skips nodes
    climbs further for the same spend — and the shared tree's spending
    counts too, which only makes the estimate cautious."""
    paid = 0
    for tier in sorted(TARGET):
        paid += whole[tier]
        if spent < paid:
            return tier
    return max(TARGET)


def measure(lines, player, label):
    whole, _ = tiers()
    mine = [l for l in lines if l[1].startswith(player)]
    if not mine:
        return None
    start = mine[0][0]
    hours = defaultdict(lambda: defaultdict(int))
    total_by = defaultdict(int)
    spent = 0
    tier_of_hour = {}
    for tick, _, source, delta, _ in mine:
        hour = (tick - start) // TICKS_PER_HOUR
        if source == "spent":
            spent -= delta
        else:
            hours[hour][source] += delta
            total_by[source] += delta
        tier_of_hour[hour] = tier_at(spent, whole)
    played = (mine[-1][0] - start) / TICKS_PER_HOUR
    sources = sorted(s for s in total_by if total_by[s] != 0)

    out = [f"## Measured: {label}, player {player}", "",
           f"{played:.1f} hours of play from the first line to the last; {spent:,} insight spent on nodes. "
           "The tier is estimated from what was spent (every tier below it bought whole).", ""]
    out.append("| Hour | Tier | " + " | ".join(sources) + " | Earned | Target | |")
    out.append("|---|---|" + "---|" * len(sources) + "---|---|---|")
    for hour in sorted(hours):
        earned = sum(hours[hour].values())
        tier = tier_of_hour.get(hour, 3)
        target = TARGET[tier]
        # The last hour is a part of one: scale its target to what was played.
        part = min(1.0, max(0.05, played - hour)) if hour == max(hours) else 1.0
        verdict = "under" if earned < 0.8 * target * part else ("over" if earned > 1.25 * target * part else "on pace")
        cells = " | ".join(f"{hours[hour].get(s, 0):,}" for s in sources)
        out.append(f"| {hour + 1} | {tier} | {cells} | {earned:,} | {round(target * part):,} | {verdict} |")
    out += ["", "**Where it came from, and what pays it:**", ""]
    earned_all = sum(v for v in total_by.values() if v > 0) or 1
    for s in sorted(total_by, key=lambda s: -total_by[s]):
        if total_by[s] <= 0:
            continue
        lever = LEVERS.get(s, "another mod's: not this mod's to turn")
        out.append(f"- `{s}`: {total_by[s]:,} ({100 * total_by[s] // earned_all}%) — {lever}")
    return "\n".join(out)


HEAD = """<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Pacing

How fast the science tree climbs (brief §13). Written by
`python tools/pacing.py`; the model is rewritten every run, and each
measured session keeps its own section until it is measured again.

**Measure, don't guess.** The model below is the tree's arithmetic against the
income §13 aims for. It is a target, not a finding. A finding is a real
session: play with `pacing_log` on (Progress's default), then

    python tools/pacing.py --log <the server's log>

and read each hour's income against its tier's target. Then change
`config.lua` (what discoveries, studies and toys pay) or `tree.lua` (what
nodes cost), and nothing else.

## The model

"""


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--log", help="a server log with Progress's pacing lines")
    ap.add_argument("--player", help="the first hex digits of the player to measure (default: the busiest)")
    args = ap.parse_args()

    kept = []
    if OUT.exists():
        text = OUT.read_text(encoding="utf8")
        kept = [s.strip() for s in re.split(r"\n(?=## Measured: )", text) if s.startswith("## Measured: ")]

    if args.log:
        lines = read_log(args.log)
        if not lines:
            sys.exit(f"no pacing lines in {args.log}: is Progress's pacing_log on?")
        player = args.player
        if not player:
            counts = defaultdict(int)
            for l in lines:
                counts[l[1]] += 1
            player = max(sorted(counts), key=lambda p: counts[p])
        label = Path(args.log).name
        section = measure(lines, player, label)
        if section is None:
            sys.exit(f"no pacing lines for player {player} in {args.log}")
        heading = section.splitlines()[0]
        kept = [k for k in kept if k.splitlines()[0] != heading] + [section]
        print(section)

    body = HEAD + model_section() + "\n"
    if kept:
        body += "\n" + "\n\n".join(kept) + "\n"
    OUT.write_text(body, encoding="utf8", newline="\n")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
