-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The glyphs (brief §7.1), as DATA and nothing else: `glyphs.lua` registers
-- every orientation of each with Craft, and `tools/glyphs.py` reads this very
-- file to prove no two collide, nor any with magic's. So it stays a plain
-- table literal.
--
-- A glyph is `id`, `mask` (27 cells, index x + 3y + 9z, the canonical
-- carving), `reading` (what the part means, by material: brief §7.1), and,
-- for the interface's shape crafter, `preset` (1 to 8 bytes) and `node`,
-- the node that shows it. `rod` and `plate` are the interface's own Pillar
-- and Slab, on purpose: the two commonest parts are one click for everyone.

return {
    { id = "rod", mask = 74752, reading = "plank shaft, steel shaft, copper wire, cavorite spoke" },
    { id = "plate", mask = 1838599, reading = "plank sail, glass lens blank, copper plate, cavorite plating" },
    { id = "gear", mask = 10560552, preset = "Gear", node = "science.gearing", reading = "plank gear, steel gear" },
    { id = "wheel", mask = 14775352, preset = "Wheel", node = "science.gearing", reading = "plank water wheel or windmill hub, steel flywheel, cavorite rotor" },
    { id = "pipe", mask = 134142975, preset = "Pipe", node = "science.newcomen_engine", reading = "copper steam pipe, steel high-pressure pipe" },
    { id = "coil", mask = 119450567, preset = "Coil", node = "science.electromagnet", reading = "copper coil" },
    { id = "ring", mask = 1837575, preset = "Ring", node = "science.chronometer", reading = "steel bearing, cavorite ring" },
    { id = "gnomon", mask = 1846791, preset = "Gnomon", node = "shared.sundial", reading = "any stone: a sundial" },
    { id = "cairn", mask = 1912327, preset = "Cairn", node = "shared.compass", reading = "any stone: a home marker" },
    { id = "bracket", mask = 79, reading = "steel elevator landing" },
    { id = "nozzle", mask = 6061591, reading = "copper boiler nozzle" },
    { id = "rail", mask = 1313285, reading = "steel elevator rail" },
    -- Punched cards (brief §6.6, Jacquard): a plank face with holes punched
    -- in it. Eight patterns, no two alike however turned, and none the plate,
    -- ring, rail or bracket. A recipe names a card as a tool, which makes it
    -- the more particular, so Craft makes it when the card is there.
    { id = "card_1", mask = 1838598, card = 1, reading = "a card: one corner punched" },
    { id = "card_2", mask = 1838597, card = 2, reading = "a card: one edge punched" },
    { id = "card_3", mask = 1838594, card = 3, reading = "a card: two corners on one side punched" },
    { id = "card_4", mask = 790022, card = 4, reading = "a card: two opposite corners punched" },
    { id = "card_5", mask = 1838596, card = 5, reading = "a card: a corner and its edge punched" },
    { id = "card_6", mask = 1314309, card = 6, reading = "a card: two opposite edges punched" },
    { id = "card_7", mask = 1837574, card = 7, reading = "a card: the middle and a corner punched" },
    { id = "card_8", mask = 1576450, card = 8, reading = "a card: three corners punched" },
}
