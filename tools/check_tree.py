# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""Proves the science tree sound, from the very file the mod loads.

Reads mods/tiamat_default_science/tree.lua (a plain Lua table literal) and
checks what Progress would otherwise find only at load, and more:

- every requirement names a node of the tree, or `shared.fork`;
- no cycles, and no node requires one of a higher tier;
- every node reaches `shared.fork` (Progress disables one that does not);
- Progress's limits: tier 3..7, cost 0..100,000, at most 8 requires and 8
  integer effects, an id of at most 64 characters;
- this mod's own: a label of at most 32 characters, a text of at most 90,
  a branch the brief names, effects under `science.`, `craft.` or
  `progress.`, and a year (where there is one) that is whole.

Then prints the pacing model's table (brief §13): nodes, insight and the
spine's share per tier, the spine being every ancestor of the capstone.

With --write it also writes docs/history.md: every node's year and source,
in tree order (brief §15, rule 4), so historical accuracy is data a
reviewer can check.

Standard library only. Run from the repository root:

    python tools/check_tree.py [--write]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TREE = ROOT / "mods" / "tiamat_default_science" / "tree.lua"
HISTORY = ROOT / "docs" / "history.md"
CAPSTONE = "science.unified_field"
ROOTS = {"shared.fork"}
BRANCHES = {"MECH", "METL", "OPTI", "HEAT", "ELEC", "CHEM", "AUTO", "TESL", "GRAV", "FOLD"}
EFFECT = re.compile(r"^(science|craft|progress)\.")


# A reader for the Lua a data file is written in: tables, strings, integers,
# booleans. Anything else is an error, which keeps the file plain data.
TOKEN = re.compile(r'\s*(?:(--[^\n]*)|("(?:[^"\\]|\\.)*")|(-?\d+)|([A-Za-z_]\w*)|(.))', re.S)


def tokens(text):
    pos = 0
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m or m.end() == pos:
            break
        pos = m.end()
        comment, string, number, name, punct = m.groups()
        if comment:
            continue
        if string:
            yield ("str", bytes(string[1:-1], "utf8").decode("unicode_escape").encode("latin1").decode("utf8"))
        elif number:
            yield ("int", int(number))
        elif name:
            yield ("name", name)
        elif punct and not punct.isspace():
            yield ("punct", punct)


class Reader:
    def __init__(self, text):
        self.toks = list(tokens(text))
        self.i = 0

    def peek(self):
        return self.toks[self.i] if self.i < len(self.toks) else (None, None)

    def take(self, kind=None, value=None):
        tok = self.peek()
        if (kind and tok[0] != kind) or (value is not None and tok[1] != value):
            raise SyntaxError(f"expected {value or kind}, got {tok}")
        self.i += 1
        return tok

    def value(self):
        kind, v = self.peek()
        if kind == "punct" and v == "{":
            return self.table()
        if kind in ("str", "int"):
            self.i += 1
            return v
        if kind == "name" and v in ("true", "false"):
            self.i += 1
            return v == "true"
        raise SyntaxError(f"not data: {v}")

    def table(self):
        self.take("punct", "{")
        items, fields = [], {}
        while self.peek() != ("punct", "}"):
            kind, v = self.peek()
            nxt = self.toks[self.i + 1] if self.i + 1 < len(self.toks) else (None, None)
            if kind == "name" and nxt == ("punct", "="):
                self.i += 2
                fields[v] = self.value()
            else:
                items.append(self.value())
            if self.peek() == ("punct", ","):
                self.i += 1
        self.take("punct", "}")
        if fields and items:
            raise SyntaxError("a table is a list or a record, not both")
        return fields if fields else items


def load():
    r = Reader(TREE.read_text(encoding="utf8"))
    r.take("name", "return")
    nodes = r.value()
    if r.peek() != (None, None):
        raise SyntaxError("anything after the table")
    return nodes


def qualify(ref):
    return ref if "." in ref else "science." + ref


def check(nodes):
    problems = []
    by_id = {}
    for n in nodes:
        nid = "science." + n["id"]
        if nid in by_id:
            problems.append(f"{nid} twice")
        by_id[nid] = n
        if not 3 <= n["tier"] <= 7:
            problems.append(f"{nid}: tier {n['tier']}")
        if not 0 <= n["cost"] <= 100_000:
            problems.append(f"{nid}: cost {n['cost']}")
        if len(nid) > 64:
            problems.append(f"{nid}: id over 64")
        if not 1 <= len(n["requires"]) <= 8:
            problems.append(f"{nid}: {len(n['requires'])} requires")
        if len(n["label"]) > 32:
            problems.append(f"{nid}: label over 32 ({len(n['label'])})")
        if len(n["text"]) > 90:
            problems.append(f"{nid}: text over 90 ({len(n['text'])})")
        if n.get("branch") not in BRANCHES:
            problems.append(f"{nid}: branch {n.get('branch')}")
        if "year" in n and not isinstance(n["year"], int):
            problems.append(f"{nid}: year {n['year']}")
        effects = n.get("effects", [])
        if len(effects) > 8 or any(not isinstance(e[1], int) or not EFFECT.match(e[0]) for e in effects):
            problems.append(f"{nid}: effects {effects}")

    for nid, n in by_id.items():
        for ref in map(qualify, n["requires"]):
            if ref in ROOTS:
                continue
            if ref not in by_id:
                problems.append(f"{nid} requires {ref}, which is not a node")
            elif by_id[ref]["tier"] > n["tier"]:
                problems.append(f"{nid} (tier {n['tier']}) requires {ref} (tier {by_id[ref]['tier']})")

    state = {}

    def reaches_fork(nid, trail):
        if nid in ROOTS:
            return True
        if state.get(nid) == "busy":
            problems.append("cycle: " + " -> ".join(trail + [nid]))
            return False
        if nid in state:
            return state[nid]
        state[nid] = "busy"
        ok = any(reaches_fork(ref, trail + [nid]) for ref in map(qualify, by_id[nid]["requires"])
                 if ref in by_id or ref in ROOTS)
        state[nid] = ok
        return ok

    for nid in by_id:
        if not reaches_fork(nid, []):
            problems.append(f"{nid} does not reach shared.fork")
    if CAPSTONE not in by_id:
        problems.append(f"no capstone {CAPSTONE}")
    return by_id, problems


def spine(by_id):
    seen, stack = set(), [CAPSTONE]
    while stack:
        nid = stack.pop()
        if nid in seen or nid not in by_id:
            continue
        seen.add(nid)
        stack.extend(map(qualify, by_id[nid]["requires"]))
    return seen


def history(nodes):
    lines = [
        "<!-- SPDX-FileCopyrightText: Iridesium -->",
        "<!-- SPDX-License-Identifier: GPL-3.0-only -->",
        "",
        "# History",
        "",
        "Every node of the science tree, its year and its source, in tree order.",
        "Written by `tools/check_tree.py --write` from",
        "`mods/tiamat_default_science/tree.lua`: edit that, not this. A node with",
        "no year is past the point where the world leaves history (brief §6.7):",
        "Michelson and Morley found no aether in 1887, and here they find it.",
        "",
        "| Node | Tier | Year | Source |",
        "|---|---|---|---|",
    ]
    for n in nodes:
        year = n.get("year")
        when = "" if year is None else (f"{-year} BC" if year < 0 else str(year))
        lines.append(f"| {n['label']} (`science.{n['id']}`) | {n['tier']} | {when} | {n.get('source', 'fiction')} |")
    return "\n".join(lines) + "\n"


def main():
    nodes = load()
    by_id, problems = check(nodes)
    if problems:
        print("THE TREE IS NOT SOUND:")
        for p in problems:
            print("  " + p)
        return 1
    on_spine = spine(by_id)
    print(f"{len(by_id)} nodes, sound.")
    print(f"{'tier':>4} {'nodes':>6} {'insight':>8} {'spine':>8} {'stars':>6}")
    total = [0, 0, 0, 0]
    for tier in range(3, 8):
        row = [n for n in by_id.values() if n["tier"] == tier]
        cost = sum(n["cost"] for n in row)
        sp = sum(n["cost"] for nid, n in by_id.items() if n["tier"] == tier and nid in on_spine)
        stars = sum(1 for n in row if n.get("star"))
        print(f"{tier:>4} {len(row):>6} {cost:>8,} {sp:>8,} {stars:>6}")
        for i, v in enumerate((len(row), cost, sp, stars)):
            total[i] += v
    print(f"{'all':>4} {total[0]:>6} {total[1]:>8,} {total[2]:>8,} {total[3]:>6}")
    if "--write" in sys.argv:
        HISTORY.write_text(history(nodes), encoding="utf8", newline="\n")
        print(f"wrote {HISTORY.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
