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

-- Tier 3: Mechanica (brief §5.1, §6) ------------------------------------------------

-- What tier 3 makes that is an item. `tool` registers it with Craft's tools
-- (type, tier, uses) and, where `speeds` is given, as an engine tool too.
C.tier3_items = {
    -- The frame's movements: the works a frame's tool slot holds.
    { id = "crank_handle", name = "Crank handle", description = "Use it on a machine frame to turn it by hand." },
    { id = "stamps", name = "Stamps", description = "A movement: crushes ore in a frame, for a third more metal." },
    { id = "trip_hammer", name = "Trip hammer", description = "A movement: beats iron bars into plates in a frame." },
    { id = "pump", name = "Screw pump", description = "A movement: lifts water from under a frame to over it." },
    { id = "leaching_vat", name = "Leaching vat", description = "A movement: draws saltpetre out of cave earth and ash." },
    { id = "press", name = "Screw press", description = "A movement: prints treatises in a frame." },
    { id = "blowing_engine", name = "Blowing engine", description = "In a furnace's tool slot, blasts it white-hot while its shaft turns." },
    -- Parts and materials.
    { id = "crushed_copper", name = "Crushed copper ore", description = "Smelts like ore, and gives more." },
    { id = "crushed_tin", name = "Crushed tin ore", description = "Smelts like ore, and gives more." },
    { id = "crushed_iron", name = "Crushed iron ore", description = "Smelts like ore, and gives more." },
    { id = "crushed_silver", name = "Crushed silver ore", description = "Smelts like ore, and gives more." },
    { id = "crushed_gold", name = "Crushed gold ore", description = "Smelts like ore, and gives more." },
    { id = "crushed_lead", name = "Crushed lead ore", description = "Smelts like ore, and gives more." },
    { id = "pig_iron", name = "Pig iron", description = "Brittle iron from the blast furnace." },
    { id = "slag", name = "Slag", description = "What the blast furnace leaves behind." },
    { id = "blister_steel", name = "Blister steel", description = "Iron that sat a day and a night in charcoal." },
    { id = "sand_mould_pipe", name = "Sand mould: pipe", description = "Pour pig iron into it in a furnace." },
    { id = "sand_mould_cylinder", name = "Sand mould: cylinder", description = "Pour pig iron into it in a furnace." },
    { id = "sand_mould_wheel", name = "Sand mould: wheel", description = "Pour pig iron into it in a furnace." },
    { id = "sand_mould_plate", name = "Sand mould: frame plate", description = "Pour pig iron into it in a furnace." },
    { id = "cast_pipe", name = "Cast iron pipe", description = "For engines and telescopes." },
    { id = "cast_cylinder", name = "Cast iron cylinder", description = "For engines." },
    { id = "cast_wheel", name = "Cast iron wheel", description = "A heavy wheel." },
    { id = "frame_plate", name = "Cast frame plate", description = "Two make a machine frame." },
    { id = "clockwork", name = "Clockwork", description = "Gears that keep time." },
    { id = "saltpeter", name = "Saltpetre", description = "White crystals drawn from cave earth." },
    { id = "black_powder", name = "Black powder", description = "Saltpetre, charcoal and sulfur, ground together." },
    { id = "mining_charge", name = "Mining charge", description = "Use it on rock: it loosens the rock around it. It hurts no one." },
    { id = "treatise", name = "Treatise", description = "A printed book. Read it to learn what its author knew." },
    -- Glass and optics.
    { id = "blowpipe", name = "Blowpipe", description = "An iron pipe for blowing glass." },
    { id = "glass_tube", name = "Glass tube", description = "Blown glass." },
    { id = "glass_jar", name = "Glass jar", description = "Blown glass." },
    { id = "glass_bulb", name = "Glass bulb", description = "Blown glass." },
    { id = "lens_blank", name = "Lens blank", description = "Glass ground true on sand." },
    { id = "surveyors_staff", name = "Surveyor's staff", description = "Use it on anything: how far, how high, how deep." },
    { id = "dip_needle", name = "Dip needle", description = "Use it anywhere: it leans toward metal ore in the rock." },
    { id = "drawplate", name = "Drawplate", description = "An iron plate with holes, for drawing copper." },
    -- Tools.
    { id = "crowbar", name = "Crowbar", description = "An iron lever: quick work of cracked rock.",
        tool = { type = "maul", tier = 1, uses = 400 }, speeds = { ["#cracked"] = 6.0 } },
}

-- What a movement needs, in turns, and the node that opens the movement's
-- own recipe. A frame runs at supply / demand of its network, capped at 100%.
C.movements = {
    stamps = { need = 8 },
    trip_hammer = { need = 8 },
    pump = { need = 4, period = 40 },   -- makes nothing: lifts a block of water every `period` ticks at full speed
    leaching_vat = { need = 2 },
    press = { need = 4 },
}

-- The turning network (brief §6.2). Parts are carved plank rods, gears and
-- wheels; frames and furnaces join the network they touch.
C.network = {
    parts = { "rod", "gear", "wheel" },     -- glyphs that carry turning, in plank
    max_blocks = 512,                        -- a flood fill stops here
    wood_capacity = 16,                      -- turns a plank network carries at most
    wood_run = 16,                           -- carved parts a plank network may have; more carries nothing
    refresh = 20,                            -- ticks a network's supply is kept before it is read again
}

-- Sources, in turns. A plank wheel is a water wheel if water touches it,
-- else a windmill if it has sails and stands high enough.
C.sources = {
    crank = 4, crank_ticks = 40,             -- a turn of the handle: 4 turns for two seconds
    water_per_side = 4, water_sides = 4,     -- 4 turns a side with water, 4 sides at most: 4 to 16
    wind_base = 2, wind_per = 16, wind_cap = 8, wind_height = 8,
    wind_sails = 2,                          -- plank plates beside the hub
    still_air = 50,                          -- the wind's strength, per cent, with no Weather to ask
}

-- The furnace (brief §6.3): a Craft heat station, long-burning.
C.furnace = {
    id = "furnace", name = "Furnace", lit = "furnace_lit",
    description = "A brick furnace. With a blowing engine and a turning shaft, a blast furnace.",
    hardness = 2.5, tags = { "stone" }, light = { r = 13, g = 7, b = 2 },
    blast_heat = 5, blast_need = 8,          -- the blowing engine blasts at heat 5 while its network turns 8
}

C.frame = {
    id = "frame", name = "Machine frame",
    description = "Put a movement in its tool slot, and turn it: a crank, a water wheel, a windmill.",
    hardness = 2.0, tags = { "metal" },
}

C.copper_stock = {
    id = "copper_stock", name = "Copper stock",
    description = "A block of drawn copper, one ingot's worth. Carve it into wire.",
    hardness = 1.5, tags = { "metal" },
}

-- The dip needle reads six rays of this many blocks from the player (brief §2.1).
C.dip_reach = 16

-- Mining charges (brief §5.1): 3 by 3 by 3 of rock loosened into drops,
-- rock only (a `hard` block holds), after a short fuse. Nothing is hurt.
C.charge = { radius = 1, fuse = 40 }

-- Reading treatises: once per author, and at most this many for a reader.
C.reading = { insight = 10, cap = 20 }

-- Tier 3's recipes, into Craft. `station` is Craft's or this mod's (`frame`,
-- `furnace`, qualified by util); `node` gates it. A movement is named as a
-- tool, and that is what chooses a frame's recipe: Craft makes the most
-- particular recipe the slots allow, and only one movement's are possible.
-- A movement is worn by nothing (`wear = 0`): the works outlast the work.
C.tier3_recipes = {
    -- The frame and the crank.
    { id = "frame", station = "workbench", node = "science.machine_frame",
        inputs = { { "C:iron_frame", count = 1 }, { "#plank", count = 4 }, { "C:iron_nails", count = 1 } },
        outputs = { { "frame", count = 1 } } },
    { id = "frame_cast", station = "workbench", node = "science.cast_iron",
        inputs = { { "frame_plate", count = 2 }, { "#plank", count = 4 } }, outputs = { { "frame", count = 1 } } },
    { id = "crank_handle", station = "workbench", node = "science.machine_frame",
        inputs = { { "C:stick", count = 2 }, { "C:iron_nails", count = 1 } }, outputs = { { "crank_handle", count = 1 } } },
    { id = "crowbar", station = "workbench", node = "science.simple_machines", tools = { { "#hammer", wear = 1 } },
        inputs = { { "C:iron_bar", count = 2 } }, outputs = { { "crowbar", count = 1 } } },

    -- Movements. Carved parts are glyph inputs: `{ glyph = id, material, count }`.
    { id = "stamps", station = "workbench", node = "science.stamp_mill",
        inputs = { { "C:iron_bar", count = 2 }, { "#plank", count = 2 }, { glyph = "gear", material = "#plank", count = 1 } },
        outputs = { { "stamps", count = 1 } } },
    { id = "trip_hammer", station = "workbench", node = "science.trip_hammer",
        inputs = { { "C:iron_bar", count = 2 }, { "#plank", count = 2 }, { glyph = "wheel", material = "#plank", count = 1 } },
        outputs = { { "trip_hammer", count = 1 } } },
    { id = "pump", station = "workbench", node = "science.archimedes_screw",
        inputs = { { glyph = "rod", material = "#plank", count = 3 }, { "#plank", count = 2 } },
        outputs = { { "pump", count = 1 } } },
    { id = "leaching_vat", station = "workbench", node = "science.saltpetre_works",
        inputs = { { "#plank", count = 6 }, { "C:cord", count = 1 } }, outputs = { { "leaching_vat", count = 1 } } },
    { id = "press", station = "workbench", node = "science.printing_press",
        inputs = { { "C:iron_bar", count = 2 }, { "#plank", count = 4 }, { "C:iron_plate", count = 1 } },
        outputs = { { "press", count = 1 } } },
    { id = "blowing_engine", station = "workbench", node = "science.blast_furnace",
        inputs = { { "C:bellows", count = 1 }, { "C:iron_bar", count = 2 }, { glyph = "wheel", material = "#plank", count = 1 } },
        outputs = { { "blowing_engine", count = 1 } } },
    { id = "furnace", station = "workbench", node = "science.blast_furnace",
        inputs = { { "C:brick", count = 8 }, { "C:iron_plate", count = 1 } }, outputs = { { "furnace", count = 1 } } },

    -- What the movements do, at the frame.
    { id = "crush_copper", station = "frame", node = "science.stamp_mill", tools = { { "stamps", wear = 0 } }, ticks = 200,
        inputs = { { "W:copper_ore", units = 20 } }, outputs = { { "crushed_copper", units = 27 } } },
    { id = "crush_tin", station = "frame", node = "science.stamp_mill", tools = { { "stamps", wear = 0 } }, ticks = 200,
        inputs = { { "W:tin_ore", units = 20 } }, outputs = { { "crushed_tin", units = 27 } } },
    { id = "crush_iron", station = "frame", node = "science.stamp_mill", tools = { { "stamps", wear = 0 } }, ticks = 200,
        inputs = { { "W:iron_ore", units = 20 } }, outputs = { { "crushed_iron", units = 27 } } },
    { id = "crush_silver", station = "frame", node = "science.stamp_mill", tools = { { "stamps", wear = 0 } }, ticks = 200,
        inputs = { { "W:silver_ore", units = 20 } }, outputs = { { "crushed_silver", units = 27 } } },
    { id = "crush_gold", station = "frame", node = "science.stamp_mill", tools = { { "stamps", wear = 0 } }, ticks = 200,
        inputs = { { "W:gold_ore", units = 20 } }, outputs = { { "crushed_gold", units = 27 } } },
    { id = "crush_lead", station = "frame", node = "science.stamp_mill", tools = { { "stamps", wear = 0 } }, ticks = 200,
        inputs = { { "W:lead_ore", units = 20 } }, outputs = { { "crushed_lead", units = 27 } } },
    { id = "hammer_plate", station = "frame", node = "science.trip_hammer", tools = { { "trip_hammer", wear = 0 } }, ticks = 200,
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_plate", count = 1 } } },
    { id = "leach_saltpeter", station = "frame", node = "science.saltpetre_works", tools = { { "leaching_vat", wear = 0 } }, ticks = 400,
        inputs = { { "W:cave_earth", units = 27 }, { "#ash", units = 9 } }, outputs = { { "saltpeter", count = 1 } } },
    { id = "print_treatise", station = "frame", node = "science.printing_press", tools = { { "press", wear = 0 }, { "notebook", wear = 0 } }, ticks = 400,
        inputs = { { "C:leather", count = 1 }, { "#plank", units = 9 } }, outputs = { { "treatise", count = 1 } } },

    -- Crushed ore smelts as ore does, in Craft's kiln and bloomery.
    { id = "smelt_crushed_copper", station = "kiln", node = "science.stamp_mill", heat = 2, ticks = 600, tools = { "C:crucible" },
        inputs = { { "crushed_copper", units = 27 } }, outputs = { { "C:copper_ingot", count = 1 } } },
    { id = "smelt_crushed_tin", station = "kiln", node = "science.stamp_mill", heat = 2, ticks = 600, tools = { "C:crucible" },
        inputs = { { "crushed_tin", units = 27 } }, outputs = { { "C:tin_ingot", count = 1 } } },
    { id = "smelt_crushed_silver", station = "kiln", node = "science.stamp_mill", heat = 2, ticks = 600, tools = { "C:crucible" },
        inputs = { { "crushed_silver", units = 27 } }, outputs = { { "C:silver_ingot", count = 1 } } },
    { id = "smelt_crushed_gold", station = "kiln", node = "science.stamp_mill", heat = 2, ticks = 600, tools = { "C:crucible" },
        inputs = { { "crushed_gold", units = 27 } }, outputs = { { "C:gold_ingot", count = 1 } } },
    { id = "smelt_crushed_lead", station = "kiln", node = "science.stamp_mill", heat = 2, ticks = 600, tools = { "C:crucible" },
        inputs = { { "crushed_lead", units = 27 } }, outputs = { { "C:lead_ingot", count = 1 } } },
    { id = "bloom_crushed_iron", station = "bloomery", node = "science.stamp_mill", heat = 3, ticks = 2400,
        inputs = { { "crushed_iron", units = 54 }, { "C:charcoal", units = 27 } }, outputs = { { "C:iron_bloom", count = 1 } } },

    -- The furnace's ladder (brief §6.3).
    { id = "pig_iron", station = "furnace", node = "science.blast_furnace", heat = 5, ticks = 1200,
        inputs = { { "#smeltable_iron", units = 54 }, { "C:charcoal", units = 27 }, { "W:calcite", units = 9 } },
        outputs = { { "pig_iron", count = 3 }, { "slag", count = 1 } } },
    { id = "finery_iron", station = "furnace", node = "science.finery_forge", heat = 3, ticks = 600,
        inputs = { { "pig_iron", count = 2 } }, outputs = { { "C:iron_bar", count = 3 } } },
    { id = "cast_pipe", station = "furnace", node = "science.cast_iron", heat = 3, ticks = 400,
        inputs = { { "pig_iron", count = 1 }, { "sand_mould_pipe", count = 1 } }, outputs = { { "cast_pipe", count = 1 } } },
    { id = "cast_cylinder", station = "furnace", node = "science.cast_iron", heat = 3, ticks = 400,
        inputs = { { "pig_iron", count = 1 }, { "sand_mould_cylinder", count = 1 } }, outputs = { { "cast_cylinder", count = 1 } } },
    { id = "cast_wheel", station = "furnace", node = "science.cast_iron", heat = 3, ticks = 400,
        inputs = { { "pig_iron", count = 1 }, { "sand_mould_wheel", count = 1 } }, outputs = { { "cast_wheel", count = 1 } } },
    { id = "cast_plate", station = "furnace", node = "science.cast_iron", heat = 3, ticks = 400,
        inputs = { { "pig_iron", count = 1 }, { "sand_mould_plate", count = 1 } }, outputs = { { "frame_plate", count = 1 } } },
    { id = "blister_steel", station = "furnace", node = "science.cementation_steel", heat = 2, ticks = 24000,
        inputs = { { "C:iron_bar", count = 4 }, { "C:charcoal", units = 27 } }, outputs = { { "blister_steel", count = 4 } } },

    -- Sand moulds, shaped at the workbench: the pattern is the casting.
    { id = "sand_mould_pipe", station = "workbench", node = "science.cast_iron",
        pattern = { "S.S", "S.S", "S.S" }, key = { S = "W:sand" }, outputs = { { "sand_mould_pipe", count = 1 } } },
    { id = "sand_mould_cylinder", station = "workbench", node = "science.cast_iron",
        pattern = { "SSS", "S.S", "SSS" }, key = { S = "W:sand" }, outputs = { { "sand_mould_cylinder", count = 1 } } },
    { id = "sand_mould_wheel", station = "workbench", node = "science.cast_iron",
        pattern = { ".S.", "S.S", ".S." }, key = { S = "W:sand" }, outputs = { { "sand_mould_wheel", count = 1 } } },
    { id = "sand_mould_plate", station = "workbench", node = "science.cast_iron",
        pattern = { "SSS", "SSS" }, key = { S = "W:sand" }, outputs = { { "sand_mould_plate", count = 1 } } },

    -- Glass, blown and ground (brief §5.1): at the workbench, with the blowpipe.
    { id = "blowpipe", station = "workbench", node = "science.glassworks", tools = { { "#hammer", wear = 1 } },
        inputs = { { "C:iron_bar", count = 2 } }, outputs = { { "blowpipe", count = 1 } } },
    { id = "glass_tube", station = "workbench", node = "science.glassworks", tools = { { "blowpipe", wear = 0 } },
        inputs = { { "C:glass", count = 1 } }, outputs = { { "glass_tube", count = 2 } } },
    { id = "glass_jar", station = "workbench", node = "science.glassworks", tools = { { "blowpipe", wear = 0 } },
        inputs = { { "C:glass", count = 2 } }, outputs = { { "glass_jar", count = 1 } } },
    { id = "glass_bulb", station = "workbench", node = "science.glassworks", tools = { { "blowpipe", wear = 0 } },
        inputs = { { "C:glass", count = 1 }, { "glass_tube", count = 1 } }, outputs = { { "glass_bulb", count = 2 } } },
    { id = "lens_blank", station = "workbench", node = "science.glassworks",
        inputs = { { "C:glass", count = 1 }, { "W:sand", units = 27 } }, outputs = { { "lens_blank", count = 1 } } },
    { id = "surveyors_staff", station = "workbench", node = "science.alhazen_optics",
        inputs = { { "lens_blank", count = 1 }, { "glass_tube", count = 1 }, { "C:stick", count = 2 } },
        outputs = { { "surveyors_staff", count = 1 } } },
    { id = "dip_needle", station = "workbench", node = "science.magnetism",
        inputs = { { "C:iron_nails", count = 1 }, { "C:bronze_ingot", count = 1 }, { "C:stick", count = 1 } },
        outputs = { { "dip_needle", count = 1 } } },

    -- Copper drawn into stock (brief §7.4): one ingot, one block, conserved.
    { id = "drawplate", station = "workbench", node = "science.wire_drawing", tools = { { "#hammer", wear = 1 } },
        inputs = { { "C:iron_plate", count = 1 }, { "C:iron_nails", count = 1 } }, outputs = { { "drawplate", count = 1 } } },
    { id = "copper_stock", station = "workbench", node = "science.wire_drawing", tools = { { "drawplate", wear = 0 } },
        inputs = { { "C:copper_ingot", count = 1 } }, outputs = { { "copper_stock", count = 1 } } },

    -- Clockwork (brief §7.5): two carved plank gears and a plate.
    { id = "clockwork", station = "workbench", node = "science.escapement",
        inputs = { { glyph = "gear", material = "#plank", count = 2 }, { "C:iron_plate", count = 1 } },
        outputs = { { "clockwork", count = 1 } } },

    -- Powder and charges.
    { id = "black_powder", station = "hand", node = "science.gunpowder",
        inputs = { { "saltpeter", count = 1 }, { "C:charcoal", count = 1 }, { "W:sulfur", units = 9 } },
        outputs = { { "black_powder", count = 2 } } },
    { id = "mining_charge", station = "hand", node = "science.gunpowder",
        inputs = { { "black_powder", count = 1 }, { "C:cord", count = 1 } }, outputs = { { "mining_charge", count = 1 } } },
}

-- Iron the blast furnace takes: the world's ore, and the stamps' crushed.
C.smeltable_iron = { "W:iron_ore", "crushed_iron" }

-- Studies at the research table (brief §6.9): a thing made, studied once.
C.tier3_studies = {
    { id = "study_pig_iron", name = "Pig iron", inputs = { { "pig_iron", count = 1 } }, ticks = 600, insight = 15 },
    { id = "study_lens", name = "A lens blank", inputs = { { "lens_blank", count = 1 } }, ticks = 1200, insight = 20 },
    { id = "study_clockwork", name = "Clockwork", inputs = { { "clockwork", count = 1 } }, ticks = 2400, insight = 40 },
    { id = "study_steel", name = "Blister steel", inputs = { { "blister_steel", count = 1 } }, ticks = 2400, insight = 40 },
}

-- Inventions (brief §6.9): the first thing each movement makes.
C.inventions = {
    insight = 10,
    firsts = {
        crush_copper = "stamps", crush_tin = "stamps", crush_iron = "stamps", crush_silver = "stamps",
        crush_gold = "stamps", crush_lead = "stamps", hammer_plate = "trip_hammer",
        leach_saltpeter = "leaching_vat", print_treatise = "press", pig_iron = "blast_furnace",
        blister_steel = "blister_steel",
    },
}

-- Toybox discoveries (brief §6.9): insight for play itself.
C.toybox = {
    hour = 3,                       -- the first hour told by a sundial
    kite = 5,                       -- the first kite flown
    home = 5,                       -- the first time a compass finds home
    sunfire = 5,                    -- the first fire lit by sunshine
    water = 5,                      -- the first water lifted by a pump
}

return C
