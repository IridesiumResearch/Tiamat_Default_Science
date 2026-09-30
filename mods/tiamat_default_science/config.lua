-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Every number and every table of names this mod turns (brief §18). Nothing
-- else in the mod holds a cost, a count or a duration: retuning is an edit
-- here and nothing else.
--
-- Ids are written short where they are this mod's own (`kite`), and with a
-- prefix where they are a sibling's: `W:` the world, `L:` Life, `C:` Craft.
-- `util.lua` qualifies both kinds.

local C = {}

-- The Tinker's Bench (brief §4) ----------------------------------------------------
--
-- Five shared nodes, open before the Fork to every player. Their `text` is
-- the first sentence a child reads: under 90 characters, plain words.

C.bench_nodes = {
    {
        id = "shared.theatrum", tier = 1, cost = 5, requires = "shared.firecraft",
        label = "Theatre of Machines",
        text = "A book of pictures that shows you how to make clever machines.",
    },
    {
        id = "shared.sundial", tier = 1, cost = 10, requires = "shared.theatrum",
        label = "The Sundial",
        text = "Carve a stone with a peg on top, and its shadow tells you the time.",
    },
    {
        id = "shared.burning_glass", tier = 1, cost = 15, requires = "shared.theatrum",
        label = "The Burning Glass",
        text = "A glass lens: look through it at anything to learn what it is.",
    },
    {
        id = "shared.kite", tier = 1, cost = 10, requires = "shared.theatrum",
        label = "The Kite",
        text = "Cloth, sticks and cord. Hold it under the sky and it flies up high.",
    },
    {
        id = "shared.compass", tier = 2, cost = 20, requires = "shared.burning_glass",
        label = "The Wet Compass",
        text = "A needle that points north, and points home to your cairn.",
    },
}

-- The Bench's items.
C.bench_items = {
    { id = "theatrum", name = "Theatrum Machinarum",
        description = "Theatre of Machines: a book of machines told in pictures. Use it to read." },
    { id = "lens", name = "Burning glass",
        description = "A ground glass lens. Use it on anything to see what it is." },
    { id = "kite", name = "Kite",
        description = "Cloth on sticks. Hold it under the open sky." },
    { id = "compass", name = "Wet compass",
        description = "A needle floating in a bowl. Use it to find north, or your cairn." },
}

-- The Bench's recipes, into Craft. `node` is the shared node that opens
-- each. Three ingredients at most, one station, nothing that fails.
C.bench_recipes = {
    { id = "theatrum", station = "hand", node = "shared.theatrum",
        inputs = { { "C:leather", count = 1 }, { "C:bark_strip", count = 2 }, { "C:charcoal", count = 1 } },
        outputs = { { "theatrum", count = 1 } } },
    -- Glass ground on sand into a lens.
    { id = "lens", station = "hand", node = "shared.burning_glass",
        inputs = { { "C:glass", count = 1 }, { "W:sand", units = 9 } },
        outputs = { { "lens", count = 1 } } },
    { id = "kite", station = "hand", node = "shared.kite",
        inputs = { { "C:cloth", count = 1 }, { "C:stick", count = 2 }, { "C:cord", count = 1 } },
        outputs = { { "kite", count = 1 } } },
    -- A needle stroked on iron, floating in a bowl of water.
    { id = "compass", station = "hand", node = "shared.compass",
        inputs = { { "C:iron_nails", count = 1 }, { "C:fired_clay", count = 1 } },
        outputs = { { "compass", count = 1 } } },
}

-- Glyphs (brief §7.1): carved 27-cell masks, index x + 3y + 9z. Every one of
-- the 48 turns and mirrors of each is registered with Craft, so a shape
-- means the same however it was carved. `preset` is the interface's
-- one-click button, 1 to 8 letters, shown once `node` is held.
C.glyphs = {
    -- A slab with a peg in its middle: the shadow-caster.
    { id = "gnomon", mask = 1846791, node = "shared.sundial", preset = "Gnomon" },
    -- A slab with a two-cell column on it: a heap of stones marking home.
    { id = "cairn", mask = 1912327, node = "shared.compass", preset = "Cairn" },
}

-- What a sundial and a cairn may be carved from: blocks tagged so.
C.stone_tag = "stone"

-- The instruments (brief §6.4) ------------------------------------------------------

-- The sundial reads the hour when the sun is up and falls on it: from dawn
-- to dusk (fractions of the day, 0 midnight), with the sky open above it.
C.sundial = { dawn = 0.25, dusk = 0.75, open_sky = 15 }

-- The compass: how near a cairn counts as home, and its needle — dots drawn
-- from the player toward where it points, seen by them alone.
C.compass = {
    home_radius = 3,
    needle_dots = 6,
    needle_start = 1.0,             -- blocks from the player to the first dot
    needle_step = 0.4,
    needle_height = 1.2,            -- above the feet
    colour = { r = 0.9, g = 0.15, b = 0.1 },
}

-- The kite, drawn in the sky over whoever holds it under the open sky.
-- Heights are blocks above the holder's feet; the weather lifts it.
C.kite = {
    period = 10,                    -- ticks between redraws
    height = 8,
    behind = 4,                     -- blocks behind the holder's facing
    storm_height = 6,               -- more in a storm or a blizzard
    per_mille_height = 4,           -- more at 1,000 permille of any other weather
    open_sky = 15,
    radius = 64,                    -- how far the kite is seen
    colour = { r = 0.9, g = 0.2, b = 0.15 },
    tail = { r = 1.0, g = 0.85, b = 0.2 },
}

-- Toybox discoveries (brief §6.9): insight for play itself.
C.toybox = {
    hour = 3,                       -- the first hour told by a sundial
    kite = 5,                       -- the first kite flown
    home = 5,                       -- the first time a compass finds home
}

return C
