# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""Generates the placeholder models for mods/tiamat_default_science/models.

A model block (the engine's `model` on `register_block`) is drawn as its
model in place of its cells: the Antikythera Mechanism, the machine frame,
the arc lamp dark and lit, and the Core's ring and the Deep's shade (entities). Each is a few boxes — rigid, self-contained .glb
with no image inside it (the engine refuses one that embeds its picture) and
a PNG beside it, drawn on with the boxes' UVs. Units are cells, three to a
block; the origin at the bottom centre of the block, so a block spans x and z
from -1.5 to 1.5 and y from 0 to 3; facing +Z. Every model here is meant to
be replaced by an artist's.

The glTF writer is magic's (tools/make_models.py there), as the texture
writer is shared between the two. No dependencies beyond the standard
library, and no randomness: the same bytes on every machine. Run from the
repository root:

    python tools/make_models.py
"""
import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_textures import Canvas, png  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "mods" / "tiamat_default_science" / "models"

# Each face: the axis it faces, its sign, and its four corners' (u, v) order.
FACES = [
    ((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]),
    ((-1, 0, 0), [(0, 0, 1), (0, 1, 1), (0, 1, 0), (0, 0, 0)]),
    ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]),
    ((0, -1, 0), [(0, 0, 1), (0, 0, 0), (1, 0, 0), (1, 0, 1)]),
    ((0, 0, 1), [(1, 0, 1), (1, 1, 1), (0, 1, 1), (0, 0, 1)]),
    ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]),
]


def boxes_to_mesh(boxes):
    """`(lo, hi, (u0, v0, u1, v1))` boxes -> positions, normals, uvs, indices."""
    pos, nor, uv, idx = [], [], [], []
    for lo, hi, (u0, v0, u1, v1) in boxes:
        for normal, corners in FACES:
            base = len(pos)
            for k, c in enumerate(corners):
                pos.append(tuple(lo[a] if c[a] == 0 else hi[a] for a in range(3)))
                nor.append(normal)
                uv.append(((u0, v1), (u0, v0), (u1, v0), (u1, v1))[k])
            idx += [base, base + 1, base + 2, base, base + 2, base + 3]
    return pos, nor, uv, idx


def glb(pos, nor, uv, idx):
    """A self-contained glTF 2.0 binary: one mesh, one primitive, no image."""
    blob = b"".join(struct.pack("<3f", *p) for p in pos)
    n_off = len(blob)
    blob += b"".join(struct.pack("<3f", *n) for n in nor)
    t_off = len(blob)
    blob += b"".join(struct.pack("<2f", *t) for t in uv)
    i_off = len(blob)
    blob += b"".join(struct.pack("<H", i) for i in idx)
    while len(blob) % 4:
        blob += b"\x00"
    lo = [min(p[a] for p in pos) for a in range(3)]
    hi = [max(p[a] for p in pos) for a in range(3)]
    doc = {
        "asset": {"version": "2.0", "generator": "tiamat_default_science make_models.py"},
        "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0}],
        "materials": [{"pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0}}],
        "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
                                    "indices": 3, "material": 0}]}],
        "buffers": [{"byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": n_off, "target": 34962},
            {"buffer": 0, "byteOffset": n_off, "byteLength": t_off - n_off, "target": 34962},
            {"buffer": 0, "byteOffset": t_off, "byteLength": i_off - t_off, "target": 34962},
            {"buffer": 0, "byteOffset": i_off, "byteLength": 2 * len(idx), "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(pos), "type": "VEC3", "min": lo, "max": hi},
            {"bufferView": 1, "componentType": 5126, "count": len(nor), "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": len(uv), "type": "VEC2"},
            {"bufferView": 3, "componentType": 5123, "count": len(idx), "type": "SCALAR"},
        ],
    }
    js = json.dumps(doc, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    body = struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(blob), 0x004E4942) + blob
    return struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body


# The texture is split in two: the left half one material, the right half
# another, so each box picks its own by its UVs.
LEFT = (0.0, 0.0, 0.5, 1.0)
RIGHT = (0.5, 0.0, 1.0, 1.0)

WOOD = (120, 84, 52)
BRONZE = (150, 120, 60)
VERDIGRIS = (96, 128, 104)
IRON = (90, 90, 98)
GLASS_DARK = (150, 160, 165)
GLASS_LIT = (255, 245, 200)


def halves(left, right, marks=()):
    c = Canvas()
    c.rect(0, 0, 7, 15, left)
    c.rect(8, 0, 15, 15, right)
    for x, y, colour in marks:
        c.dot(x, y, colour)
    return c


def antikythera():
    """A wooden case with a bronze dial face, as the Mechanism was rebuilt."""
    boxes = [
        ((-1.3, 0.0, -1.0), (1.3, 2.1, 1.0), LEFT),           # the case
        ((-1.0, 0.35, 1.0), (1.0, 1.85, 1.12), RIGHT),        # the front dial
        ((-0.15, 1.0, 1.12), (0.15, 1.2, 1.3), RIGHT),        # its pointer's boss
        ((-0.9, 0.35, -1.12), (0.9, 1.85, -1.0), RIGHT),      # the back dials
    ]
    marks = [(9 + i, 3 + (i * 5) % 9, VERDIGRIS) for i in range(6)]    # weathered bronze
    return boxes, halves(WOOD, BRONZE, marks)


def frame():
    """An open iron cage: the twelve edges of the block, as bars."""
    t = 0.3
    lo, hi = -1.5, 1.5
    boxes = []
    for y0, y1 in ((0.0, t), (3.0 - t, 3.0)):               # four bars round the foot, four round the top
        boxes += [
            ((lo, y0, lo), (hi, y1, lo + t), LEFT), ((lo, y0, hi - t), (hi, y1, hi), LEFT),
            ((lo, y0, lo), (lo + t, y1, hi), LEFT), ((hi - t, y0, lo), (hi, y1, hi), LEFT),
        ]
    for x0, z0 in ((lo, lo), (hi - t, lo), (lo, hi - t), (hi - t, hi - t)):   # four posts
        boxes.append(((x0, 0.0, z0), (x0 + t, 3.0, z0 + t), LEFT))
    boxes.append(((-0.5, 0.3, -0.5), (0.5, 0.6, 0.5), RIGHT))   # a bed plate for the movement
    return boxes, halves(IRON, BRONZE)


def lamp(lit):
    """A post, and a glass head where the arc burns."""
    boxes = [
        ((-0.6, 0.0, -0.6), (0.6, 0.25, 0.6), LEFT),          # the foot
        ((-0.2, 0.25, -0.2), (0.2, 2.1, 0.2), LEFT),          # the post
        ((-0.55, 2.1, -0.55), (0.55, 2.9, 0.55), RIGHT),      # the glass
        ((-0.3, 2.9, -0.3), (0.3, 3.0, 0.3), LEFT),           # the cap
    ]
    return boxes, halves(IRON, GLASS_LIT if lit else GLASS_DARK)


BRICK = (150, 72, 56)
SOOT = (40, 34, 32)
EMBER = (255, 150, 60)


def furnace(lit):
    """A brick furnace: a body nearly the block, a fire mouth in its face (+Z),
    and a chimney. Lit, the mouth glows."""
    mouth = RIGHT if lit else (0.5, 0.0, 0.75, 1.0)
    boxes = [
        ((-1.5, 0.0, -1.5), (1.5, 2.2, 1.5), LEFT),            # the body
        ((-0.7, 0.3, 1.5), (0.7, 1.3, 1.58), mouth),           # the fire mouth
        ((-1.3, 2.2, -1.3), (1.3, 2.45, 1.3), LEFT),           # the crown
        ((0.3, 2.45, -1.0), (1.1, 3.0, -0.2), LEFT),           # the chimney
    ]
    canvas = halves(BRICK, EMBER if lit else SOOT)
    for y in range(0, 16, 4):                                  # mortar courses
        for x in range(0, 8):
            canvas.dot(x, y, (120, 110, 100))
    return boxes, canvas


CAVORITE = (70, 50, 110)
VOID = (12, 10, 16)


def core_ring():
    """One of the Core's three rings: a square hoop five blocks across, as
    the rings of cavorite blocks are; the entity turns it."""
    r, t = 7.5, 0.6
    boxes = [
        ((-r, -t, -r), (r, t, -r + 2 * t), LEFT), ((-r, -t, r - 2 * t), (r, t, r), LEFT),
        ((-r, -t, -r), (-r + 2 * t, t, r), LEFT), ((r - 2 * t, -t, -r), (r, t, r), LEFT),
    ]
    return boxes, halves(CAVORITE, (150, 120, 220))


def shade():
    """A tall still silhouette, a little taller than a person."""
    boxes = [
        ((-0.7, 0.0, -0.4), (0.7, 5.4, 0.4), LEFT),           # the body
        ((-0.45, 5.4, -0.35), (0.45, 6.3, 0.35), LEFT),       # the head
    ]
    return boxes, halves(VOID, VOID)


MODELS = {"antikythera": antikythera, "frame": frame, "lamp": lambda: lamp(False), "lamp_lit": lambda: lamp(True),
          "core_ring": core_ring, "shade": shade,
          "furnace": lambda: furnace(False), "furnace_lit": lambda: furnace(True)}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, make in MODELS.items():
        boxes, canvas = make()
        (OUT / f"{name}.glb").write_bytes(glb(*boxes_to_mesh(boxes)))
        (OUT / f"{name}.png").write_bytes(png(canvas.p))
    print(f"wrote {len(MODELS)} models to {OUT}")


if __name__ == "__main__":
    main()
