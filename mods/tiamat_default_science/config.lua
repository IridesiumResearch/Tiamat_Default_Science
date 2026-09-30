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
        text = "A glass lens: it tells you what things are, and lights fires in the noon sun.",
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
        description = "A ground glass lens. Use it on anything to see what it is, or on a laid fire at noon." },
    { id = "kite", name = "Kite",
        description = "Cloth on sticks. Hold it under the open sky." },
    { id = "compass", name = "Wet compass",
        description = "A needle floating in a bowl. Use it to find north, or your cairn." },
}

-- Items the path gives or makes, beyond the Bench's.
C.path_items = {
    { id = "notebook", name = "Natural philosopher's notebook",
        description = "Where your readings and discoveries are written down." },
}

-- The Theatrum's key, a suggestion the player may move (brief §10.3).
C.theatrum_key = "KeyN"

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

-- The glyphs themselves are `glyph_table.lua`, plain data a tool reads.

-- What a sundial and a cairn may be carved from: blocks tagged so.
C.stone_tag = "stone"

-- The instruments (brief §6.4) ------------------------------------------------------

-- The sundial reads the hour when the sun is up and falls on it: from dawn
-- to dusk (fractions of the day, 0 midnight), with the sky open above it.
C.sundial = { dawn = 0.25, dusk = 0.75, open_sky = 15 }

-- The burning glass lights a laid campfire, or an unlit furnace with fuel
-- in it, only in the high sun: between these fractions of the day, with
-- the sky open above what it lights.
-- `at` is what it may be held to: blocks Craft lights, listed so the glass
-- is asked before the fire's own box opens. Craft says whether each can be
-- lit now.
C.burning_glass = {
    from = 0.40, to = 0.60, open_sky = 15,
    at = { "C:unlit_campfire", "C:unfired_kiln", "C:kiln", "C:bloomery" },
}

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
-- Heights are blocks above the holder's feet; the wind lifts it and carries it downwind.
C.kite = {
    period = 10,                    -- ticks between redraws
    height = 8,
    behind = 4,                     -- blocks downwind, or behind the holder in still air
    wind_height = 10,               -- more at the wind's full strength (1, a blizzard): 2 on a clear day
    open_sky = 15,
    radius = 64,                    -- how far the kite is seen
    colour = { r = 0.9, g = 0.2, b = 0.15 },
    tail = { r = 1.0, g = 0.85, b = 0.2 },
}

-- The door (brief §3) -------------------------------------------------------------
--
-- The Antikythera Mechanism (c. 100 BC), the oldest geared computer known:
-- thirty bronze gears in a wooden case, so the door is made of what a
-- player at the Keystone can already cast. Progress adds the Keystone to the
-- recipe and requires `shared.keystone`.
C.path = {
    id = "science",
    label = "Natural Philosophy",
    sentence = "The dials turn once, for you alone. This binds you; the other door closes.",
    refusal = "The bronze wheels will not turn for you.",
    inputs = {
        { "C:bronze_gear", count = 8 },
        { "C:bronze_ingot", count = 4 },
        { "C:plank", count = 4 },
    },
    root = "science.natural_philosophy",        -- cost 0, given the moment the door is chosen
    welcome = "The dials have turned. Build a frame.",
    -- The Research tab shows a tier's nodes grouped under these (Progress's
    -- `branches`), and a node only once all but one of what it needs is held.
    branches = {
        MECH = "Mechanics", METL = "Metallurgy", OPTI = "Optics", HEAT = "Heat and Steam",
        ELEC = "Electricity", CHEM = "Chemistry", AUTO = "Automata", TESL = "Tesla",
        GRAV = "Gravity", FOLD = "The Fold",
    },
    reveal = "near",
}

C.antikythera = {
    id = "antikythera", name = "The Antikythera Mechanism",
    description = "Bronze gears in a wooden case. Use it, holding the Keystone's knowledge, to take the path of natural philosophy.",
    hardness = 1.8, tags = { "metal" },
}

-- The tiers of `tree.lua` registered with Progress: those whose content is
-- built, so nobody buys a node that does nothing yet (the rest is data).
C.shipped_tier = 3

-- Toybox discoveries (brief §6.9): insight for play itself.
C.toybox = {
    hour = 3,                       -- the first hour told by a sundial
    kite = 5,                       -- the first kite flown
    home = 5,                       -- the first time a compass finds home
    sunfire = 5,                    -- the first fire lit by sunshine
}

return C
