# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""Proves the science path can be climbed, recipe by recipe, in theory.

Runs the native rig with SCIENCE_DUMP set, which loads this mod beside the
real siblings and has the test probe list every material, every Craft
recipe of every mod (inputs, tools, outputs, the node that gates it) and the
members of every group. Then, from what the world itself holds:

1. **Everything.** Which items can ever be made, recipe after recipe, with
   every node known; and which of this mod's recipes never can, naming the
   input nothing makes.
2. **Node by node.** For each science node, whether its own recipes can be
   made by a player who knows only that node, the nodes it requires (all the
   way down) and the shared tree — so no node's work waits on a later node's.

Where a thing comes from is not always a recipe: the world's blocks are
dug, Life's creatures drop wool and hide, and a few of this mod's things
come from playing — strange matter dug in the Deep, a photograph from the
camera. Those are SOURCES, named below with why; anything else that no
recipe makes is reported. Standard library only. Run from the repository
root:

    python tools/reach.py
"""
import os
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_tree  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SCI = "tiamat_default_science:"

# What is had without a recipe, and why.
SOURCES = {
    "tiamat_default_life:wool": "a sheep's drop",
    "tiamat_default_life:hide": "a creature's drop",
    "tiamat_default_life:bone": "a creature's drop",
    "tiamat_default_life:feather": "a hen's drop",
    "tiamat_default_life:raw_meat": "a creature's drop",
    "tiamat_default_life:water_bucket": "Life's bucket, filled at water",
    SCI + "notebook": "given at the door, with the Theatrum",
    SCI + "strange_matter": "digging morphic rock in the Deep (or condensed from it, in a world without the Deep)",
    SCI + "photograph": "the camera, used on two corners of a building",
}
# World blocks are dug; every registered one counts, ores included.
WORLD = "tiamat_default_world:"


def dump():
    env = dict(os.environ, SCIENCE_DUMP="1")
    out = subprocess.run(["cargo", "run", "-q", "--manifest-path", "tests/native/Cargo.toml"],
                         cwd=ROOT, env=env, capture_output=True, text=True, encoding="utf8")
    if out.returncode != 0:
        sys.exit(out.stderr[-2000:])
    materials, recipes, groups = [], [], {}
    for line in out.stdout.splitlines():
        part = line.split("|")
        if part[0] == "M":
            materials.append(part[1])
        elif part[0] == "G":
            groups[part[1]] = [m for m in part[2].split(",") if m]
        elif part[0] == "R":
            _, rid, station, requires, ins, tools, outs = part

            def names(field):
                got = []
                for e in [x for x in field.split(";") if x]:
                    if e.startswith("P:"):
                        got += [k[2:] if k.startswith("T:") else k for k in e[2:].split(",")]
                    else:
                        got.append(e.split("*")[0])
                return got
            recipes.append({"id": rid, "station": station, "requires": requires if requires not in ("", "nil") else None,
                            "needs": names(ins) + names(tools), "outs": names(outs)})
    return materials, recipes, groups


def have(name, got, groups):
    if name.startswith("#"):
        return any(m in got for m in groups.get(name, []))
    return name in got


STATIONS = {"frame": SCI + "frame", "furnace": SCI + "furnace"}


def close(recipes, groups, start, allowed):
    """Every item reachable from `start` with recipes whose node is in `allowed`
    (None: every node). Answers the items and the recipes that fired."""
    got, fired = set(start), set()
    changed = True
    while changed:
        changed = False
        for r in recipes:
            if r["id"] in fired:
                continue
            if allowed is not None and r["requires"] and r["requires"] not in allowed:
                continue
            station = STATIONS.get(r["station"].split(":")[-1]) if r["station"].startswith(SCI) else None
            if station and station not in got:
                continue
            if all(have(n, got, groups) for n in r["needs"]):
                fired.add(r["id"])
                for o in r["outs"]:
                    if o not in got:
                        got.add(o)
                        changed = True
                changed = True
    return got, fired


def main():
    materials, recipes, groups = dump()
    start = {m for m in materials if m.startswith(WORLD)} | set(SOURCES)
    got, fired = close(recipes, groups, start, None)
    ours = [r for r in recipes if r["id"].startswith(SCI)]
    print(f"{len(materials)} materials, {len(recipes)} recipes ({len(ours)} this mod's), {len(groups)} groups")

    stuck = [r for r in ours if r["id"] not in fired]
    print(f"\n1. With every node known: {len(ours) - len(stuck)} of {len(ours)} of this mod's recipes can be made.")
    for r in stuck:
        missing = [n for n in r["needs"] if not have(n, got, groups)]
        print(f"   NEVER: {r['id']} — nothing makes {', '.join(missing)}")

    # Node by node.
    by_id, problems = check_tree.check(check_tree.load())
    if problems:
        sys.exit("the tree is not sound: run tools/check_tree.py")
    shared = {r["requires"] for r in recipes if r["requires"] and r["requires"].startswith("shared.")}
    shared |= {"shared.keystone", "shared.fork"}

    def ancestors(nid):
        seen, stack = set(), [nid]
        while stack:
            n = stack.pop()
            if n in seen or n not in by_id:
                continue
            seen.add(n)
            stack.extend(map(check_tree.qualify, by_id[n]["requires"]))
        return seen

    # The science nodes an item needs, followed down every recipe that makes
    # it: of the recipes that can make it, the one asking the lowest tiers.
    producers = defaultdict(list)
    for r in recipes:
        if r["id"] in fired:
            for o in r["outs"]:
                producers[o].append(r)
    memo = {}

    def need(item, visiting=frozenset()):
        if item.startswith("#"):
            options = [need(m, visiting) for m in groups.get(item, []) if m in got]
            options = [o for o in options if o is not None]
            return min(options, key=weight) if options else None
        if item in start:
            return frozenset()
        if item in memo:
            return memo[item]
        if item in visiting:
            return None
        best = None
        for r in producers.get(item, []):
            got_r = recipe_need(r, visiting | {item})
            if got_r is not None and (best is None or weight(got_r) < weight(best)):
                best = got_r
        if best is not None:             # a failure met inside a cycle is no answer
            memo[item] = best
        return best

    def recipe_need(r, visiting=frozenset()):
        nodes = set()
        if r["requires"] in by_id:
            nodes |= ancestors(r["requires"])
        station = STATIONS.get(r["station"].split(":")[-1]) if r["station"].startswith(SCI) else None
        for item in r["needs"] + ([station] if station else []):
            n = need(item, visiting)
            if n is None:
                return None
            nodes |= n
        return frozenset(nodes)

    def weight(nodes):
        return (max((by_id[n]["tier"] for n in nodes), default=0), len(nodes))

    late = []
    for nid in sorted(by_id, key=lambda n: (by_id[n]["tier"], n)):
        mine = [r for r in ours if r["requires"] == nid]
        if not mine:
            continue
        have_nodes = ancestors(nid) | shared
        needed = set()
        for r in mine:
            got_r = recipe_need(r)
            if got_r is None:
                late.append((nid, [f"(untraced: {r['id']})"]))
                continue
            needed |= got_r
        extra = needed - have_nodes
        # Root causes only: drop any that another extra one already requires.
        roots = {e for e in extra if not any(e != o and e in ancestors(o) for o in extra)}
        if roots:
            late.append((nid, sorted(roots, key=lambda e: (by_id[e]["tier"], e))))
    print(f"\n2. Node by node: {'every node' if not late else 'all but these'} can make its own recipes "
          "with only what it requires.")
    for nid, roots in late:
        tiers = ", ".join(f"{e} (tier {by_id[e]['tier']})" if e in by_id else e for e in roots)
        print(f"   {nid} (tier {by_id[nid]['tier']}) also needs {tiers}")
    return 1 if stuck or late else 0


if __name__ == "__main__":
    sys.exit(main())
