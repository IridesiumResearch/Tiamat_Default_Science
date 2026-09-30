# SPDX-FileCopyrightText: Iridesium
# SPDX-License-Identifier: GPL-3.0-only
"""Generates the placeholder textures for mods/tiamat_default_science/textures.

An item is flat colours in one silhouette on a clear ground, so it reads in
a slot: a book, a lens, a kite, a compass. A block is one flat colour. Every
picture here is meant to be replaced.

No dependencies beyond the standard library, and no randomness: the same
bytes on every machine. Run from the repository root:

    python tools/make_textures.py
"""
import struct
import zlib
from pathlib import Path

SIZE = 16
OUT = Path(__file__).resolve().parent.parent / "mods" / "tiamat_default_science" / "textures"

LEATHER = (120, 78, 46)
LEATHER_DARK = (84, 52, 30)
PAGE = (232, 220, 186)
BRASS = (200, 160, 70)
BRASS_DARK = (140, 108, 40)
GLASS = (206, 226, 222)
GLASS_EDGE = (150, 176, 172)
WOOD = (150, 110, 70)
RED = (210, 50, 40)
YELLOW = (240, 200, 60)
CLAY = (176, 122, 88)
CLAY_DARK = (128, 86, 60)
WATER = (90, 140, 200)
IRON = (70, 70, 76)


def png(pixels):
    """RGBA rows of (r, g, b, a) tuples, as PNG bytes."""
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in row) for row in pixels)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


class Canvas:
    def __init__(self):
        self.p = [[(0, 0, 0, 0) for _ in range(SIZE)] for _ in range(SIZE)]

    def dot(self, x, y, colour):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            self.p[y][x] = colour + (255,)

    def rect(self, x0, y0, x1, y1, colour):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.dot(x, y, colour)

    def disc(self, cx, cy, r2, colour):
        """Every pixel whose centre is within sqrt(r2) of (cx, cy), in half-pixels."""
        for y in range(SIZE):
            for x in range(SIZE):
                if (2 * x + 1 - cx) ** 2 + (2 * y + 1 - cy) ** 2 <= r2:
                    self.dot(x, y, colour)


def theatrum():
    """A leather book with a brass gear on its cover."""
    c = Canvas()
    c.rect(2, 1, 13, 14, LEATHER)
    c.rect(2, 1, 3, 14, LEATHER_DARK)
    c.rect(13, 2, 14, 13, PAGE)
    c.disc(17, 15, 36, BRASS)
    c.disc(17, 15, 8, LEATHER)
    for x, y in ((8, 4), (8, 10), (5, 7), (11, 7)):
        c.dot(x, y, BRASS_DARK)
    return c


def lens():
    """A round glass on a wooden handle."""
    c = Canvas()
    c.rect(2, 11, 3, 14, WOOD)
    c.rect(4, 10, 5, 11, WOOD)
    c.disc(19, 13, 81, BRASS_DARK)
    c.disc(19, 13, 49, GLASS)
    c.dot(8, 4, (255, 255, 255))
    return c


def kite():
    """A red diamond on crossed sticks, with a yellow tail."""
    c = Canvas()
    for y in range(1, 11):
        half = 5 - abs(y - 5)
        c.rect(8 - half, y, 7 + half, y, RED)
    c.rect(7, 1, 8, 10, WOOD)
    c.rect(3, 5, 12, 5, WOOD)
    for i, (x, y) in enumerate(((8, 11), (9, 12), (8, 13), (7, 14), (8, 15))):
        c.dot(x, y, YELLOW if i % 2 == 0 else RED)
    return c


def compass():
    """A clay bowl of water with a needle floating in it."""
    c = Canvas()
    c.rect(1, 6, 14, 12, CLAY)
    c.rect(2, 13, 13, 14, CLAY_DARK)
    c.rect(2, 6, 13, 8, WATER)
    c.rect(4, 7, 7, 7, RED)
    c.rect(8, 7, 11, 7, IRON)
    return c


def notebook():
    """A plain notebook, tied with cord."""
    c = Canvas()
    c.rect(3, 2, 12, 14, LEATHER_DARK)
    c.rect(4, 3, 12, 13, PAGE)
    c.rect(4, 3, 5, 13, LEATHER)
    for y in (5, 7, 9, 11):
        c.rect(7, y, 11, y, (150, 140, 120))
    c.rect(3, 8, 12, 8, WOOD)
    return c


def antikythera():
    """A block: weathered bronze, the colour of the Mechanism as it was found.
    Flat, the Spindle's convention: variation across a surface is the
    renderer's."""
    c = Canvas()
    c.rect(0, 0, SIZE - 1, SIZE - 1, (96, 128, 104))
    return c


DRAW = {"theatrum": theatrum, "lens": lens, "kite": kite, "compass": compass, "notebook": notebook,
        "antikythera": antikythera}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in DRAW.items():
        (OUT / f"{name}.png").write_bytes(png(draw().p))
    print(f"{len(DRAW)} textures in {OUT}")


if __name__ == "__main__":
    main()
