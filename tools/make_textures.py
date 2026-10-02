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


def flat(colour):
    """A block: one flat colour."""
    def draw():
        c = Canvas()
        c.rect(0, 0, SIZE - 1, SIZE - 1, colour)
        return c
    return draw


def heap(colour):
    """Loose stuff: crushed ore, powder, saltpetre, slag."""
    def draw():
        c = Canvas()
        for y in range(8, 15):
            half = min(y - 7, 6)
            c.rect(8 - half, y, 7 + half, y, colour)
        c.rect(6, 7, 9, 7, colour)
        return c
    return draw


def bar(colour):
    """Metal: pig iron, blister steel, a plate."""
    def draw():
        c = Canvas()
        c.rect(2, 6, 13, 10, colour)
        c.rect(3, 5, 12, 5, tuple(min(255, v + 30) for v in colour))
        return c
    return draw


def part(colour):
    """A made part or movement: a squared frame of the colour."""
    def draw():
        c = Canvas()
        c.rect(2, 2, 13, 13, colour)
        c.rect(4, 4, 11, 11, (0, 0, 0))
        c.rect(5, 5, 10, 10, colour)
        return c
    return draw


def glassware():
    c = Canvas()
    c.rect(6, 2, 9, 13, GLASS_EDGE)
    c.rect(7, 3, 8, 12, GLASS)
    return c


def staff():
    c = Canvas()
    for i in range(12):
        c.dot(2 + i, 13 - i, WOOD)
    c.disc(25, 7, 12, BRASS)
    return c


IRON_GREY = (110, 110, 118)
STEEL = (150, 160, 175)
COPPER_C = (196, 116, 70)

DRAW = {"theatrum": theatrum, "lens": lens, "kite": kite, "compass": compass, "notebook": notebook,
        "antikythera": antikythera,
        # tier 3 blocks
        "frame": flat((88, 80, 72)), "furnace": flat((150, 72, 56)), "furnace_lit": flat((210, 120, 60)),
        "copper_stock": flat(COPPER_C),
        # movements and tools
        "crank_handle": part(WOOD), "stamps": part(IRON_GREY), "trip_hammer": part((90, 90, 96)),
        "pump": part(WOOD), "leaching_vat": part((130, 100, 70)), "press": part((80, 80, 88)),
        "blowing_engine": part(LEATHER), "blowpipe": bar(IRON_GREY), "drawplate": bar(IRON_GREY),
        "crowbar": bar((70, 70, 76)), "surveyors_staff": staff, "dip_needle": part(BRASS),
        # materials
        "crushed_copper": heap(COPPER_C), "crushed_tin": heap((200, 200, 205)), "crushed_iron": heap((150, 100, 80)),
        "crushed_silver": heap((215, 215, 225)), "crushed_gold": heap((230, 190, 60)),
        "crushed_lead": heap((90, 95, 110)), "pig_iron": bar((95, 90, 90)), "slag": heap((60, 55, 60)),
        "blister_steel": bar(STEEL), "saltpeter": heap((240, 240, 235)), "black_powder": heap((40, 40, 40)),
        "mining_charge": part((150, 40, 30)), "treatise": notebook, "clockwork": part(BRASS),
        "sand_mould_pipe": part((220, 200, 150)), "sand_mould_cylinder": part((220, 200, 150)),
        "sand_mould_wheel": part((220, 200, 150)), "sand_mould_plate": part((220, 200, 150)),
        "cast_pipe": bar((100, 100, 108)), "cast_cylinder": part((100, 100, 108)),
        "cast_wheel": part((100, 100, 108)), "frame_plate": bar((100, 100, 108)),
        "glass_tube": glassware, "glass_jar": glassware, "glass_bulb": glassware, "lens_blank": lens,
        # tier 4
        "steel_stock": flat(STEEL),
        "telescope": bar(BRASS), "microscope": part(BRASS), "chronometer": part((210, 210, 215)),
        "barometer": glassware, "thermometer": glassware, "orrery": part((230, 190, 60)),
        "magdeburg_hemispheres": part(COPPER_C), "air_pump": part(IRON_GREY), "balloon_pack": part((200, 60, 50)),
        "leyden_jar": glassware, "friction_globe": part(GLASS_EDGE),
        "digester": part(IRON_GREY), "bone_broth": part((200, 170, 120)), "boiler": part((80, 80, 88)),
        "cylinder": part((100, 100, 108)),
        "coke": heap((50, 50, 55)), "coal_tar": heap((20, 20, 20)), "steel_ingot": bar(STEEL),
        "quicksilver": heap((200, 205, 215)), "oil_of_vitriol": glassware, "lead_chamber": part((90, 95, 110)),
        "spinning_frame": part(WOOD), "lathe_bed": part(IRON_GREY), "piston": bar(IRON_GREY), "bearing": part(STEEL),
        "steel_pick": bar(STEEL), "steel_axe": bar(STEEL), "steel_spade": bar(STEEL), "steel_chisel": bar(STEEL),
        "steel_hammer": bar(STEEL),
        # tier 5
        "lamp": flat((120, 120, 110)), "lamp_lit": flat((255, 250, 220)),
        "steam_hammer": part((80, 80, 88)), "converter": part((90, 70, 60)), "screw": bar(IRON_GREY),
        "spring": part(STEEL), "assembly_jig": part(IRON_GREY), "winding_drum": part((100, 100, 108)),
        "camera": part(LEATHER), "photograph": part((200, 200, 205)), "silvered_plate": bar((215, 215, 225)),
        "gravimeter": part(BRASS), "dynamite": part((190, 40, 30)), "soda": heap((235, 235, 225)),
        "hydrogen": glassware, "cell": part((90, 95, 110)), "voltaic_pile": part(COPPER_C),
        "electrolysis_cell": glassware, "electromagnet": part((120, 40, 40)), "dynamo_armature": part(COPPER_C),
        "motor": part((70, 90, 120)), "telegraph": part(BRASS), "carbon_rod": bar((40, 40, 40)),
        "difference_engine": part((230, 190, 60)), "automaton_spring": part(BRASS), "automaton_key": bar(BRASS),
        }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in DRAW.items():
        (OUT / f"{name}.png").write_bytes(png(draw().p))
    print(f"{len(DRAW)} textures in {OUT}")


if __name__ == "__main__":
    main()
