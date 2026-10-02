# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""Proves the glyph table sound, from the very file the mod loads.

Reads mods/tiamat_default_science/glyph_table.lua and checks that:

- every mask is a real carving: at least one cell, not all 27;
- each glyph has as many orientations as the brief says (§7.1);
- no two science glyphs share a mask in any of their 48 orientations
  (Craft keeps one meaning a mask, so a clash would silently lose one);
- no science glyph is one of the interface's presets in any orientation —
  except `rod` and `plate`, which ARE its Pillar and Slab, on purpose;
- no science glyph meets one of magic's, read from magic's own table when
  its repository is checked out beside this one;
- a preset label is 1 to 8 bytes, the interface's limit, and names a node.

Then prints the table: glyph, cells, orientations. Standard library only.
Run from the repository root:

    python tools/glyphs.py
"""
import itertools
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_tree import Reader  # noqa: E402  (the same reader, the same rules)

ROOT = Path(__file__).resolve().parent.parent
TABLE = ROOT / "mods" / "tiamat_default_science" / "glyph_table.lua"
MAGIC = ROOT.parent / "Tiamat_Default_Magic" / "mods" / "tiamat_default_magic" / "glyph_table.lua"
FULL = (1 << 27) - 1

# The brief's §7.1: how many distinct orientations each has.
ORIENTATIONS = {"rod": 3, "plate": 6, "gear": 3, "wheel": 3, "pipe": 3, "coil": 3, "ring": 6,
                "gnomon": 6, "cairn": 6, "bracket": 24, "nozzle": 6, "rail": 12,
                # The cards: a face (6 ways) turned and mirrored in it (up to 8).
                "card_1": 24, "card_2": 24, "card_3": 24, "card_4": 12, "card_5": 48,
                "card_6": 12, "card_7": 24, "card_8": 24}


def preset(rule):
    return sum(1 << (x + 3 * y + 9 * z) for z in range(3) for y in range(3) for x in range(3) if rule(x, y, z))


INTERFACE = {
    "slab": preset(lambda x, y, z: y == 0),
    "stairs": preset(lambda x, y, z: y <= z),
    "pillar": preset(lambda x, y, z: x == 1 and z == 1),
}
ON_PURPOSE = {("rod", "pillar"), ("plate", "slab")}


def variants(mask):
    cells = [(i % 3, (i // 3) % 3, i // 9) for i in range(27) if mask >> i & 1]
    out = set()
    for order in itertools.permutations(range(3)):
        for flips in itertools.product((0, 1), repeat=3):
            m = 0
            for c in cells:
                v = [c[order[a]] for a in range(3)]
                v = [2 - v[a] if flips[a] else v[a] for a in range(3)]
                m |= 1 << (v[0] + 3 * v[1] + 9 * v[2])
            out.add(m)
    return out


def read(path):
    r = Reader(path.read_text(encoding="utf8"))
    r.take("name", "return")
    return r.value()


def main():
    glyphs = read(TABLE)
    problems = []
    others = {f"interface {k}": variants(v) for k, v in INTERFACE.items()}
    if MAGIC.exists():
        others.update({f"magic {g['id']}": variants(g["mask"]) for g in read(MAGIC)})
    else:
        print(f"(magic's table is not beside this repository: {MAGIC} — its glyphs are not checked)")
    seen = {}
    rows = []
    for g in glyphs:
        gid, mask = g["id"], g["mask"]
        if not 0 < mask < FULL:
            problems.append(f"{gid}: mask {mask} is empty or whole")
            continue
        vs = variants(mask)
        want = ORIENTATIONS.get(gid)
        if want is not None and len(vs) != want:
            problems.append(f"{gid}: {len(vs)} orientations, the brief says {want}")
        for m in vs:
            if m in seen:
                problems.append(f"{gid} meets {seen[m]} at mask {m}")
            seen[m] = gid
        for name, ovs in others.items():
            if vs & ovs and (gid, name.split(" ")[1]) not in ON_PURPOSE:
                problems.append(f"{gid} meets {name}")
        if "preset" in g:
            if not 1 <= len(g["preset"].encode("utf8")) <= 8:
                problems.append(f"{gid}: preset label {g['preset']!r} is not 1 to 8 bytes")
            if "node" not in g:
                problems.append(f"{gid}: a preset names the node that shows it")
        rows.append((gid, bin(mask).count("1"), len(vs), g.get("preset", "")))
    if problems:
        print("THE GLYPHS ARE NOT SOUND:")
        for p in problems:
            print("  " + p)
        return 1
    print(f"{len(rows)} glyphs, {len(seen)} masks, sound.")
    print(f"{'glyph':<8} {'cells':>5} {'turns':>5}  preset")
    for gid, cells, turns, label in rows:
        print(f"{gid:<8} {cells:>5} {turns:>5}  {label}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
