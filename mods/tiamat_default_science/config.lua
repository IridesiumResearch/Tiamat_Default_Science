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
    -- A model block: drawn as the Mechanism, dug whole. Its cells are the
    -- case, the lower two layers.
    model = "antikythera", shape = { "### ### ###", "### ### ###", "... ... ..." },
}

-- The tiers of `tree.lua` registered with Progress: those whose content is
-- built, so nobody buys a node that does nothing yet (the rest is data).
C.shipped_tier = 7

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
    friction_globe = { need = 4, period = 40 },     -- makes nothing: charges a Leyden jar in its inputs
    lead_chamber = { need = 4 },
    spinning_frame = { need = 8 },
    lathe_bed = { need = 8 },
    -- An engine needs nothing and gives: a frame with a cylinder, a copper
    -- pipe from a burning furnace with a boiler in it, turns its network.
    cylinder = { need = 0, engine = 16 },
    -- Tier 5. `power = "charge"` runs on the charge network, not on turning.
    steam_hammer = { need = 32 },
    assembly_jig = { need = 16 },
    winding_drum = { need = 8 },
    dynamo_armature = { need = 16, dynamo = true },     -- takes turning, gives charge
    motor = { need = 0, motor = true },                 -- takes charge, gives turning
    voltaic_pile = { need = 0, pile = true },           -- gives charge while it has acid
    electrolysis_cell = { need = 8, power = "charge" },
    telegraph = { need = 1, power = "charge" },
    -- Tier 6.
    radio = { need = 2, power = "charge" },
    receiver = { need = 0, power = "charge" },          -- Wardenclyffe's: joins the tower's network, wherever it stands
    tesla_coil = { need = 8, power = "charge" },        -- the coil's base frame: three copper coils above it, a steel ring on top
    arc_electrodes = { need = 32, power = "charge" },
    resonator = { need = 16, power = "charge" },        -- rings orichalcum into aetherium, a Tesla coil within reach
    radium_cell = { need = 0, source = 1 },             -- gives charge for ever
    aether_cell = { need = 0, source = 10 },
    -- Tier 7.
    attractor = { need = 16, power = "charge" },        -- draws dropped things in
    repulsor = { need = 16, power = "charge" },         -- thrusts what hunts you away
    stasis = { need = 16, power = "charge" },           -- holds everything near it still
    terraformer = { need = 128, power = "charge" },     -- greens a body, a column at a time
    atmosphere_processor = { need = 64, power = "charge" },   -- remakes a living body's sky
}

-- The turning network (brief §6.2). Parts are carved plank rods, gears and
-- wheels; frames and furnaces join the network they touch.
C.network = {
    parts = { "rod", "gear", "wheel" },     -- glyphs that carry turning, in plank
    max_blocks = 512,                        -- a flood fill stops here
    wood_capacity = 16,                      -- turns a network with any plank part carries at most
    wood_run = 16,                           -- carved parts it may have; more carries nothing
    steel_capacity = 128,                    -- an all-steel network's
    steel_run = 64,
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
    -- A model block: drawn as a brick furnace with a fire mouth, dark and lit;
    -- its cells the whole block. Whole, as every model block is.
    model = "furnace", lit_model = "furnace_lit", whole = true,
    blast_heat = 5, blast_need = 8,          -- the blowing engine blasts at heat 5 while its network turns 8
}

C.frame = {
    id = "frame", name = "Machine frame",
    description = "Put a movement in its tool slot, and turn it: a crank, a water wheel, a windmill.",
    hardness = 2.0, tags = { "metal" },
    model = "frame",                -- an open cage; its cells the whole block, for shafts to touch
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
        inputs = { { "#smeltable_iron", units = 54 }, { "#furnace_carbon", units = 27 }, { "W:calcite", units = 9 } },
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

-- Tier 4: Natural philosophy, 1600–1760 (brief §5.2, §6.4, §6.5) -------------------------

C.tier4_items = {
    -- Instruments: each reads the world and says what it reads.
    { id = "telescope", name = "Telescope", description = "Use it at night under the open sky, at a star, to log it." },
    { id = "microscope", name = "Microscope", description = "Use it on anything to look very closely." },
    { id = "chronometer", name = "Chronometer", description = "Use it at a block to mark it; anywhere, for where you are and your mark." },
    { id = "barometer", name = "Barometer", description = "Use it anywhere: the weather, and which way it is going." },
    { id = "thermometer", name = "Thermometer", description = "Use it anywhere: how warm it is." },
    { id = "orrery", name = "Orrery", description = "Use it to watch the planets go round the sun." },
    { id = "magdeburg_hemispheres", name = "Magdeburg hemispheres", description = "Pumped empty of air. Two horses cannot pull them apart." },
    { id = "air_pump", name = "Air pump", description = "Guericke's pump: it draws the air out of a vessel." },
    { id = "balloon_pack", name = "Balloon", description = "Hold it with charcoal in your pack: it rises, and falls softly." },
    -- Charge.
    { id = "leyden_jar", name = "Leyden jar", description = "A jar lined with tin foil that keeps charge. Use a charged one for a spark." },
    { id = "friction_globe", name = "Friction globe", description = "A movement: turning it charges the Leyden jars in a frame." },
    -- Heat and steam.
    { id = "digester", name = "Papin's digester", description = "In a kiln's tool slot: cooks bones into broth under pressure." },
    { id = "bone_broth", name = "Bone broth", description = "Hearty and warm.",
        food = { food = 8, saturation = 6, effects = { { "hearty", 2400 } }, temperature = "warm" } },
    { id = "boiler", name = "Boiler", description = "In a furnace's tool slot: the furnace raises steam for an engine." },
    { id = "cylinder", name = "Engine cylinder", description = "A movement: a frame with it, piped to a boiler, is an engine." },
    -- Metallurgy and chemistry.
    { id = "coke", name = "Coke", description = "Coal baked hard: a hotter fuel." },
    { id = "coal_tar", name = "Coal tar", description = "Black and sticky, left when coal is coked." },
    { id = "steel_ingot", name = "Steel ingot", description = "Cast steel, from the crucible." },
    { id = "quicksilver", name = "Quicksilver", description = "Liquid silver metal, roasted out of cinnabar." },
    { id = "oil_of_vitriol", name = "Oil of vitriol", description = "A strong acid, made in a chamber of lead." },
    { id = "lead_chamber", name = "Lead chamber", description = "A movement: sulfur and saltpetre, burned in lead, give oil of vitriol." },
    { id = "spinning_frame", name = "Spinning frame", description = "A movement: spins wool into cloth, three times over." },
    { id = "lathe_bed", name = "Lathe bed", description = "A movement: turns pistons and bearings." },
    { id = "piston", name = "Piston", description = "Turned on a lathe." },
    { id = "bearing", name = "Bearing", description = "Turned on a lathe." },
    -- Steel tools (tier 3 of the dig classes): Craft's tools, engine tools where they dig.
    { id = "steel_pick", name = "Steel pick", description = "Tier 3. Digs rock.",
        tool = { type = "pick", tier = 3, uses = 800 }, speed = 3.4 },
    { id = "steel_axe", name = "Steel axe", description = "Tier 3. Digs wood.",
        tool = { type = "axe", tier = 3, uses = 800 }, speed = 3.9 },
    { id = "steel_spade", name = "Steel spade", description = "Tier 3. Digs earth.",
        tool = { type = "spade", tier = 3, uses = 800 }, speed = 4.2 },
    { id = "steel_chisel", name = "Steel chisel", description = "Tier 3. Carves one cell at a time.",
        tool = { type = "chisel", tier = 3, uses = 1600 }, speed = 1.2, brush = "subnode", group = "#chisel" },
    { id = "steel_hammer", name = "Steel hammer", description = "Tier 3. For the anvil.",
        tool = { type = "hammer", tier = 3, uses = 800 }, group = "#hammer" },
}

-- Groups the reagents join, so they trade across the Fork (brief §2): each
-- mod adds its own item, and every recipe names the group.
C.tier4_groups = {
    ["#quicksilver"] = { "quicksilver" },
    ["#oil_of_vitriol"] = { "oil_of_vitriol" },
    ["#saltpeter"] = { "saltpeter" },
    ["#furnace_carbon"] = { "C:charcoal", "coke" },
}

C.coke_fuel = { heat = 3, ticks = 1800 }         -- hotter than charcoal (2): the finery without a blast

C.steel_stock = {
    id = "steel_stock", name = "Steel stock",
    description = "A block of steel, one ingot's worth. Carve it into shafts, gears and rings.",
    hardness = 3.0, tags = { "metal" },
}

C.tier4_recipes = {
    -- Instruments.
    { id = "telescope", station = "workbench", node = "science.telescope",
        inputs = { { glyph = "plate", material = "C:glass", count = 2 }, { "cast_pipe", count = 1 }, { "C:bronze_ingot", count = 1 } },
        outputs = { { "telescope", count = 1 } } },
    { id = "microscope", station = "workbench", node = "science.microscope",
        inputs = { { "lens_blank", count = 2 }, { "glass_tube", count = 1 }, { "C:bronze_ingot", count = 1 } },
        outputs = { { "microscope", count = 1 } } },
    { id = "chronometer", station = "workbench", node = "science.chronometer",
        inputs = { { "clockwork", count = 1 }, { "C:silver_ingot", count = 1 }, { "lens_blank", count = 1 } },
        outputs = { { "chronometer", count = 1 } } },
    { id = "barometer", station = "workbench", node = "science.barometer",
        inputs = { { "glass_tube", count = 1 }, { "#quicksilver", count = 1 }, { "#plank", count = 1 } },
        outputs = { { "barometer", count = 1 } } },
    { id = "thermometer", station = "workbench", node = "science.thermometer",
        inputs = { { "glass_tube", count = 1 }, { "#quicksilver", count = 1 } }, outputs = { { "thermometer", count = 1 } } },
    { id = "orrery", station = "workbench", node = "science.newtonian_mechanics",
        inputs = { { "clockwork", count = 1 }, { "C:bronze_gear", count = 2 }, { "C:gold_ingot", count = 1 } },
        outputs = { { "orrery", count = 1 } } },
    { id = "air_pump", station = "workbench", node = "science.vacuum_pump",
        inputs = { { "cast_cylinder", count = 1 }, { "C:bellows", count = 1 }, { "glass_jar", count = 1 } },
        outputs = { { "air_pump", count = 1 } } },
    { id = "magdeburg_hemispheres", station = "workbench", node = "science.vacuum_pump", tools = { { "air_pump", wear = 0 } },
        inputs = { { "C:copper_ingot", count = 2 }, { "C:iron_hinge", count = 1 } }, outputs = { { "magdeburg_hemispheres", count = 1 } } },
    { id = "balloon_pack", station = "workbench", node = "science.balloon",
        inputs = { { "C:cloth", count = 4 }, { "C:cord", count = 2 }, { "C:iron_plate", count = 1 } },
        outputs = { { "balloon_pack", count = 1 } } },

    -- Charge.
    { id = "leyden_jar", station = "workbench", node = "science.leyden_jar",
        inputs = { { "glass_jar", count = 1 }, { "C:tin_ingot", count = 1 } }, outputs = { { "leyden_jar", count = 1 } } },
    { id = "friction_globe", station = "workbench", node = "science.electrostatics",
        inputs = { { "C:glass", count = 2 }, { "#plank", count = 2 }, { glyph = "wheel", material = "#plank", count = 1 } },
        outputs = { { "friction_globe", count = 1 } } },

    -- Heat and steam.
    { id = "digester", station = "workbench", node = "science.papin_digester",
        inputs = { { "cast_cylinder", count = 1 }, { "C:iron_plate", count = 1 }, { "C:iron_nails", count = 1 } },
        outputs = { { "digester", count = 1 } } },
    { id = "bone_broth", station = "kiln", node = "science.papin_digester", heat = 1, ticks = 400,
        tools = { { "digester", wear = 0 } }, inputs = { { "L:bone", count = 2 } }, outputs = { { "bone_broth", count = 2 } } },
    { id = "boiler", station = "workbench", node = "science.newcomen_engine",
        inputs = { { "C:iron_plate", count = 4 }, { "copper_stock", count = 1 } }, outputs = { { "boiler", count = 1 } } },
    { id = "cylinder", station = "workbench", node = "science.newcomen_engine",
        inputs = { { "cast_cylinder", count = 1 }, { "C:iron_chain", count = 1 }, { "#plank", count = 2 } },
        outputs = { { "cylinder", count = 1 } } },

    -- Metallurgy.
    { id = "coke", station = "furnace", node = "science.coke", heat = 2, ticks = 2400,
        inputs = { { "W:coal", units = 27 } }, outputs = { { "coke", units = 18 }, { "coal_tar", units = 9 } } },
    { id = "crucible_steel", station = "furnace", node = "science.crucible_steel", heat = 5, ticks = 1200,
        tools = { "C:crucible" }, inputs = { { "blister_steel", count = 2 } }, outputs = { { "steel_ingot", count = 1 } } },
    { id = "steel_stock", station = "workbench", node = "science.crucible_steel", tools = { { "#hammer", wear = 1 } },
        inputs = { { "steel_ingot", count = 1 } }, outputs = { { "steel_stock", count = 1 } } },
    { id = "steel_pick", station = "workbench", node = "science.crucible_steel", tools = { { "#hammer", wear = 1 } },
        inputs = { { "steel_ingot", count = 3 }, { "C:haft", count = 1 } }, outputs = { { "steel_pick", count = 1 } } },
    { id = "steel_axe", station = "workbench", node = "science.crucible_steel", tools = { { "#hammer", wear = 1 } },
        inputs = { { "steel_ingot", count = 3 }, { "C:haft", count = 1 }, { "C:cord", count = 1 } }, outputs = { { "steel_axe", count = 1 } } },
    { id = "steel_spade", station = "workbench", node = "science.crucible_steel", tools = { { "#hammer", wear = 1 } },
        inputs = { { "steel_ingot", count = 2 }, { "C:haft", count = 1 } }, outputs = { { "steel_spade", count = 1 } } },
    { id = "steel_chisel", station = "workbench", node = "science.crucible_steel", tools = { { "#hammer", wear = 1 } },
        inputs = { { "steel_ingot", count = 1 }, { "C:stick", count = 1 } }, outputs = { { "steel_chisel", count = 1 } } },
    { id = "steel_hammer", station = "workbench", node = "science.crucible_steel", tools = { { "#hammer", wear = 1 } },
        inputs = { { "steel_ingot", count = 2 }, { "C:stick", count = 1 } }, outputs = { { "steel_hammer", count = 1 } } },

    -- Chemistry.
    { id = "quicksilver", station = "furnace", node = "science.cinnabar_roasting", heat = 2, ticks = 600,
        tools = { { "glass_jar", wear = 0 } }, inputs = { { "W:cinnabar", units = 27 } }, outputs = { { "quicksilver", count = 1 } } },
    { id = "lead_chamber", station = "workbench", node = "science.lead_chamber",
        inputs = { { "C:lead_ingot", count = 4 }, { "#plank", count = 4 } }, outputs = { { "lead_chamber", count = 1 } } },
    { id = "oil_of_vitriol", station = "frame", node = "science.lead_chamber", tools = { { "lead_chamber", wear = 0 } }, ticks = 600,
        inputs = { { "W:sulfur", units = 27 }, { "#saltpeter", count = 1 } }, outputs = { { "oil_of_vitriol", count = 3 } } },

    -- The water frame and the lathe.
    { id = "spinning_frame", station = "workbench", node = "science.water_frame",
        inputs = { { "#plank", count = 4 }, { "C:iron_bar", count = 1 }, { glyph = "gear", material = "#plank", count = 2 } },
        outputs = { { "spinning_frame", count = 1 } } },
    { id = "spin_cloth", station = "frame", node = "science.water_frame", tools = { { "spinning_frame", wear = 0 } }, ticks = 300,
        inputs = { { "L:wool", count = 3 } }, outputs = { { "C:cloth", count = 3 } } },
    { id = "lathe_bed", station = "workbench", node = "science.lathe",
        inputs = { { "cast_wheel", count = 1 }, { "C:iron_bar", count = 2 }, { "#plank", count = 2 } },
        outputs = { { "lathe_bed", count = 1 } } },
    { id = "turn_piston", station = "frame", node = "science.lathe", tools = { { "lathe_bed", wear = 0 } }, ticks = 400,
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "piston", count = 1 } } },
    { id = "turn_bearing", station = "frame", node = "science.lathe", tools = { { "lathe_bed", wear = 0 } }, ticks = 400,
        inputs = { { "cast_wheel", count = 1 } }, outputs = { { "bearing", count = 2 } } },
}

C.tier4_studies = {
    { id = "study_leyden_jar", name = "The Leyden jar", inputs = { { "leyden_jar", count = 1 } }, ticks = 1200, insight = 30 },
    { id = "study_steel_ingot", name = "Cast steel", inputs = { { "steel_ingot", count = 1 } }, ticks = 2400, insight = 40 },
}

-- What tier 4's inventions are: the first of each.
C.tier4_firsts = {
    spin_cloth = "spinning_frame", turn_piston = "lathe", turn_bearing = "lathe", oil_of_vitriol = "lead_chamber",
    coke = "coke", crucible_steel = "crucible_steel", bone_broth = "digester",
}

-- The instruments (brief §6.4).
C.telescope = { alignment = 0.9998, dusk = 0.78, dawn = 0.22, open_sky = 15 }
C.barometer = { history = 5 }                    -- readings kept, for rising or falling
C.chronometer = { home_radius = 2 }
C.orrery = { planets = 4, colours = {
    { r = 0.7, g = 0.7, b = 0.75 }, { r = 0.95, g = 0.85, b = 0.6 }, { r = 0.3, g = 0.5, b = 1.0 }, { r = 0.9, g = 0.35, b = 0.2 } } }
-- Eight points on a circle, as whole numbers over 1,000: the orrery's
-- planets step round them, so no sine is taken.
C.circle = { { 1000, 0 }, { 707, 707 }, { 0, 1000 }, { -707, 707 }, { -1000, 0 }, { -707, -707 }, { 0, -1000 }, { 707, -707 } }
C.magdeburg = { radius = 8, horses = 2, horse = "L:horse" }
C.balloon = { charcoal_ticks = 600, speed = 50,    -- a charcoal burns 30 seconds; flying at half speed
    hydrogen = { ticks = 2400, speed = 75 } }      -- a jar of hydrogen lifts two minutes, faster; the jar comes back

-- Charge (brief §6.5): carried in a jar's detail, `e=<n>`, 0 to 100.
C.electric = { jar = 100, static = 5,               -- what one turn of the globe gives, every `period` at full speed
    lightning = 2000, rod_reach = 8, rod_wire = 64, rod_fires = 16,
    franklin = 3 }                                -- what a kite in a storm gives the jar in the off-hand, each redraw

-- Discoveries, by family: what each pays.
C.families = {
    spectrum = { insight = 1, group = "stars", label = "A star's spectrum: %s" },
    star = { insight = 1, group = "stars", label = "A star: %s" },
    specimen = { insight = 3, group = "specimens", label = "Under the microscope: %s" },
    weather = { insight = 20, group = "weather", label = "Weather measured: %s" },
    climate = { insight = 3, group = "climate", label = "A climate recorded: %s" },
}
C.tier4_toys = { spark = 3, magdeburg = 5, balloon = 5, franklin = 10, lightning = 30 }

-- Tier 5: the Industrial Revolution, 1760–1870 (brief §5.3) -------------------------------

C.tier5_items = {
    -- Steam, iron and steel.
    { id = "steam_hammer", name = "Steam hammer", description = "A movement: one blow does an anvil's work. Wants a steel shaft." },
    { id = "converter", name = "Bessemer converter", description = "In a blasting furnace, it blows pig iron into steel." },
    -- Precision.
    { id = "screw", name = "Screw", description = "Cut true on Maudslay's lathe." },
    { id = "spring", name = "Steel spring", description = "Coiled steel, turned on the lathe." },
    { id = "assembly_jig", name = "Assembly jig", description = "A movement: relics are built in it from carved parts." },
    { id = "winding_drum", name = "Winding drum", description = "A movement: at the foot of an elevator's rail, it winds the platform." },
    -- Optics.
    { id = "camera", name = "Camera", description = "Use it on two corners of a building, with a silvered plate in your pack." },
    { id = "photograph", name = "Daguerreotype", description = "A building, caught on silver. With Blueprints, use it to build that building again." },
    { id = "silvered_plate", name = "Silvered plate", description = "Iron plated with silver, ready for a picture." },
    { id = "gravimeter", name = "Gravimeter", description = "Use it anywhere: it leans toward heavy ore." },
    -- Chemistry.
    { id = "dynamite", name = "Dynamite", description = "Use it on rock: it loosens even the hardest. It hurts no one." },
    { id = "soda", name = "Soda", description = "Split from brine by a current." },
    { id = "hydrogen", name = "Jar of hydrogen", description = "Lighter than air: a balloon that floats longer." },
    -- Electricity.
    { id = "cell", name = "Cell", description = "Stores charge for a frame's network. Charge rides in it." },
    { id = "voltaic_pile", name = "Voltaic pile", description = "A movement: copper, tin and acid give a steady current." },
    { id = "electrolysis_cell", name = "Electrolysis cell", description = "A movement on the charge network: splits and plates." },
    { id = "electromagnet", name = "Electromagnet", description = "Hold it with a charged cell: dropped things fly to you." },
    { id = "dynamo_armature", name = "Dynamo armature", description = "A movement: a turning frame on copper wire makes charge." },
    { id = "motor", name = "Electric motor", description = "A movement: a frame on charged wire turns its shaft." },
    { id = "telegraph", name = "Telegraph key", description = "A movement: two keys on one wire. Say 'wire' and your words at one." },
    { id = "carbon_rod", name = "Carbon rod", description = "For an arc lamp." },
    -- Automata.
    { id = "difference_engine", name = "The Difference Engine", description = "Babbage's engine: twelve gears of steel that calculate." },
    { id = "automaton_spring", name = "Automaton", description = "Use it on the ground to wind up a clockwork helper." },
    { id = "automaton_key", name = "Automaton key", description = "Use it on your automaton to wind it down and carry it." },
}

C.lamp = {
    id = "lamp", lit = "lamp_lit", name = "Arc lamp",
    description = "Lit while its copper's network has charge to spare.",
    hardness = 1.0, tags = { "metal", "glass" }, light = { r = 15, g = 15, b = 14 },
    -- A lamp on a post: drawn as its model, its cells the post's column.
    model = "lamp", lit_model = "lamp_lit", shape = { "... .#. ...", "... .#. ...", "... .#. ..." },
}

-- The models model blocks are drawn as (`tools/make_models.py`). In cells,
-- three to the block; a PNG beside each.
C.models = { "antikythera", "frame", "lamp", "lamp_lit", "furnace", "furnace_lit", "core_ring", "shade" }

-- The charge network (brief §6.2): copper stock, any carving of it, carries
-- charge between frames and lamps. Units a second.
C.grid = {
    period = 20,                  -- ticks between reckonings
    max_blocks = 512,
    pile = 2, pile_acid_ticks = 6000,     -- a pile gives 2 a second, and drinks an oil of vitriol in five minutes
    dynamo = 16,                  -- at full turning
    motor = 16,                   -- charge in, turning out, at full charge
    lamp = 1,
    cell = 1000,                  -- what a cell holds
    loss_per = 16,                -- 1 lost a second for every this many blocks of wire
    telegraph_reach = 4,          -- how near a key a speaker stands
    telegraph_hear = 16,          -- how near the far key a listener stands
    magnet_radius = 8, magnet_strength = 0.3, magnet_drain = 1,   -- a second, from the carried cell
}

C.camera = { max_side = 16 }
C.gravimeter = { reach = 24, heavy = { "W:gold_ore", "W:lead_ore", "W:diamond", "W:orichalcum" } }
C.dynamite = { radius = 2 }
C.elevator = { reach = 64 }       -- how far up a rail an elevator looks for landings

C.tier5_recipes = {
    -- Steam, iron and steel.
    { id = "steam_hammer", station = "workbench", node = "science.steam_hammer",
        inputs = { { "cast_cylinder", count = 1 }, { "piston", count = 2 }, { "steel_ingot", count = 2 } },
        outputs = { { "steam_hammer", count = 1 } } },
    { id = "steam_plate", station = "frame", node = "science.steam_hammer", tools = { { "steam_hammer", wear = 0 } },
        ticks = 40, inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_plate", count = 1 } } },
    { id = "decarburise_pig", station = "furnace", node = "science.puddling", heat = 3, ticks = 1200,
        inputs = { { "pig_iron", count = 1 } }, outputs = { { "C:iron_bar", count = 2 } } },
    { id = "converter", station = "workbench", node = "science.bessemer",
        inputs = { { "C:iron_plate", count = 4 }, { "C:brick", count = 2 }, { "bearing", count = 1 } },
        outputs = { { "converter", count = 1 } } },
    { id = "bessemer_steel", station = "furnace", node = "science.bessemer", heat = 5, ticks = 1200,
        tools = { { "converter", wear = 0 } }, inputs = { { "pig_iron", count = 3 } }, outputs = { { "steel_ingot", count = 3 } } },

    -- Precision: Maudslay's lathe, and the elevator.
    { id = "turn_screw", station = "frame", node = "science.maudslay_lathe", tools = { { "lathe_bed", wear = 0 } }, ticks = 200,
        inputs = { { "C:iron_nails", count = 1 } }, outputs = { { "screw", count = 3 } } },
    { id = "turn_spring", station = "frame", node = "science.maudslay_lathe", tools = { { "lathe_bed", wear = 0 } }, ticks = 400,
        inputs = { { "steel_ingot", count = 1 } }, outputs = { { "spring", count = 2 } } },
    { id = "assembly_jig", station = "workbench", node = "science.maudslay_lathe",
        inputs = { { "C:iron_frame", count = 1 }, { "screw", count = 2 }, { "spring", count = 1 }, { "bearing", count = 1 } },
        outputs = { { "assembly_jig", count = 1 } } },
    { id = "winding_drum", station = "workbench", node = "science.otis_elevator",
        inputs = { { "cast_wheel", count = 1 }, { "C:iron_chain", count = 2 }, { "spring", count = 1 } },
        outputs = { { "winding_drum", count = 1 } } },

    -- Optics.
    { id = "camera", station = "workbench", node = "science.daguerreotype",
        inputs = { { "lens_blank", count = 1 }, { "#plank", count = 4 }, { "C:leather", count = 1 } },
        outputs = { { "camera", count = 1 } } },
    { id = "gravimeter", station = "workbench", node = "science.cavendish_balance",
        inputs = { { "steel_ingot", count = 1 }, { "C:lead_ingot", count = 2 }, { "clockwork", count = 1 } },
        outputs = { { "gravimeter", count = 1 } } },

    -- Chemistry.
    { id = "dynamite", station = "hand", node = "science.dynamite",
        inputs = { { "black_powder", count = 2 }, { "#oil_of_vitriol", count = 1 }, { "C:cord", count = 1 } },
        outputs = { { "dynamite", count = 2 } } },

    -- Electricity.
    { id = "cell", station = "workbench", node = "science.voltaic_pile",
        inputs = { { "C:lead_ingot", count = 2 }, { "#oil_of_vitriol", count = 1 }, { "C:copper_ingot", count = 1 } },
        outputs = { { "cell", count = 1 } } },
    { id = "voltaic_pile", station = "workbench", node = "science.voltaic_pile",
        inputs = { { "C:copper_ingot", count = 4 }, { "C:tin_ingot", count = 4 }, { "C:cloth", count = 1 } },
        outputs = { { "voltaic_pile", count = 1 } } },
    { id = "electrolysis_cell", station = "workbench", node = "science.electrolysis",
        inputs = { { "glass_jar", count = 2 }, { "copper_stock", count = 1 }, { "C:lead_ingot", count = 1 } },
        outputs = { { "electrolysis_cell", count = 1 } } },
    { id = "soda", station = "frame", node = "science.electrolysis", tools = { { "electrolysis_cell", wear = 0 } }, ticks = 400,
        inputs = { { "W:salt", units = 27 }, { "L:water_bucket", count = 1 } },
        outputs = { { "soda", count = 1 }, { "L:bucket", count = 1 } } },
    { id = "hydrogen", station = "frame", node = "science.electrolysis", tools = { { "electrolysis_cell", wear = 0 } }, ticks = 400,
        inputs = { { "L:water_bucket", count = 1 }, { "glass_jar", count = 1 } },
        outputs = { { "hydrogen", count = 1 }, { "L:bucket", count = 1 } } },
    { id = "silvered_plate", station = "frame", node = "science.electrolysis", tools = { { "electrolysis_cell", wear = 0 } }, ticks = 400,
        inputs = { { "C:iron_plate", count = 1 }, { "C:silver_ingot", count = 1 } }, outputs = { { "silvered_plate", count = 2 } } },
    { id = "electromagnet", station = "workbench", node = "science.electromagnet",
        inputs = { { glyph = "coil", material = "copper_stock", count = 1 }, { "C:iron_bar", count = 1 }, { "cell", count = 1 } },
        outputs = { { "electromagnet", count = 1 } } },
    { id = "dynamo_armature", station = "workbench", node = "science.dynamo",
        inputs = { { glyph = "coil", material = "copper_stock", count = 2 }, { glyph = "wheel", material = "steel_stock", count = 1 },
            { "C:iron_bar", count = 2 } },
        outputs = { { "dynamo_armature", count = 1 } } },
    { id = "motor", station = "workbench", node = "science.electric_motor",
        inputs = { { glyph = "coil", material = "copper_stock", count = 2 }, { "bearing", count = 2 }, { "C:iron_bar", count = 2 } },
        outputs = { { "motor", count = 1 } } },
    { id = "telegraph", station = "workbench", node = "science.telegraph",
        inputs = { { glyph = "coil", material = "copper_stock", count = 1 }, { "C:iron_plate", count = 1 }, { "C:iron_hinge", count = 1 } },
        outputs = { { "telegraph", count = 1 } } },
    { id = "carbon_rod", station = "furnace", node = "science.arc_lamp", heat = 3, ticks = 600,
        inputs = { { "coke", units = 27 } }, outputs = { { "carbon_rod", count = 4 } } },
    { id = "lamp", station = "workbench", node = "science.arc_lamp",
        inputs = { { "C:glass", count = 1 }, { "carbon_rod", count = 2 }, { "copper_stock", count = 1 } },
        outputs = { { "lamp", count = 1 } } },

    -- Punched cards (Jacquard): the same bar, chosen into something else by
    -- the card that lies in the frame with it.
    { id = "trip_nails", station = "frame", node = "science.jacquard_cards", ticks = 200,
        tools = { { "trip_hammer", wear = 0 }, { glyph = "card_1", material = "#plank", count = 1 } },
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_nails", count = 1 } } },
    { id = "trip_chain", station = "frame", node = "science.jacquard_cards", ticks = 200,
        tools = { { "trip_hammer", wear = 0 }, { glyph = "card_2", material = "#plank", count = 1 } },
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_chain", count = 1 } } },
    { id = "trip_hinge", station = "frame", node = "science.jacquard_cards", ticks = 200,
        tools = { { "trip_hammer", wear = 0 }, { glyph = "card_3", material = "#plank", count = 1 } },
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_hinge", count = 1 } } },
    { id = "steam_nails", station = "frame", node = "science.jacquard_cards", ticks = 40,
        tools = { { "steam_hammer", wear = 0 }, { glyph = "card_1", material = "#plank", count = 1 } },
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_nails", count = 1 } } },
    { id = "steam_chain", station = "frame", node = "science.jacquard_cards", ticks = 40,
        tools = { { "steam_hammer", wear = 0 }, { glyph = "card_2", material = "#plank", count = 1 } },
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_chain", count = 1 } } },
    { id = "steam_hinge", station = "frame", node = "science.jacquard_cards", ticks = 40,
        tools = { { "steam_hammer", wear = 0 }, { glyph = "card_3", material = "#plank", count = 1 } },
        inputs = { { "C:iron_bar", count = 1 } }, outputs = { { "C:iron_hinge", count = 1 } } },

    -- Relics, at the assembly jig, from carved parts (brief §7.5).
    { id = "difference_engine", station = "frame", node = "science.difference_engine", relic = true, ticks = 2400,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "gear", material = "steel_stock", count = 12 }, { glyph = "rod", material = "steel_stock", count = 4 },
            { "frame_plate", count = 1 }, { "C:bronze_ingot", count = 4 } },
        outputs = { { "difference_engine", count = 1 } } },
    { id = "automaton_spring", station = "frame", node = "science.clockwork_automaton", relic = true, ticks = 1200,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "gear", material = "steel_stock", count = 4 }, { glyph = "rod", material = "steel_stock", count = 2 },
            { glyph = "coil", material = "copper_stock", count = 1 }, { "clockwork", count = 2 }, { "C:leather", count = 1 } },
        outputs = { { "automaton_spring", count = 1 } } },
    { id = "automaton_key", station = "workbench", node = "science.clockwork_automaton",
        inputs = { { "C:iron_bar", count = 1 }, { "C:bronze_ingot", count = 1 } }, outputs = { { "automaton_key", count = 1 } } },
}

C.tier5_studies = {
    { id = "study_engine_part", name = "An engine cylinder", inputs = { { "cylinder", count = 1 } }, ticks = 4800, insight = 120 },
    { id = "study_cell", name = "A cell", inputs = { { "cell", count = 1 } }, ticks = 2400, insight = 80 },
    { id = "study_difference_engine", name = "The Difference Engine", inputs = { { "difference_engine", count = 1 } },
        ticks = 12000, insight = 250 },
    { id = "study_automaton", name = "An automaton", inputs = { { "automaton_spring", count = 1 } }, ticks = 12000, insight = 250 },
}

C.tier5_firsts = {
    steam_plate = "steam_hammer", bessemer_steel = "bessemer", decarburise_pig = "puddling",
    turn_screw = "screw_cutting", soda = "electrolysis", hydrogen = "electrolysis", silvered_plate = "electroplating",
    trip_nails = "punched_cards", difference_engine = "difference_engine", automaton_spring = "automaton",
}
C.tier5_toys = { photograph = 10, blueprint = 20, elevator = 5, telegraph = 10, lamp = 10 }

-- Automata (brief §6.6): a clockwork helper. Its hold's first slots are its
-- program: the cards there, read in order, each an instruction; without the
-- Analytical Engine only the first is read.
C.automaton = {
    hold = 27, program_slots = 4, step = 40,      -- ticks an instruction runs
    reach = 6,                                     -- blocks it works frames and chests within
    follow = 3,                                    -- blocks it keeps from its owner
    model = "engine:humanoid", collider = { width = 1.2, height = 3.6 }, speed = 0.8,
    per_player = 1,                                -- raised by `science.automata` (the Teleautomaton)
    -- What each card means, by its number.
    cards = { [1] = "follow", [2] = "stay", [3] = "feed", [4] = "collect", [5] = "deposit", [6] = "fetch" },
}

-- Tier 6: the electrical age, 1870–1905, and the aether (brief §5.4) ----------------------

C.tier6_items = {
    { id = "radio", name = "Wireless set", description = "A movement on charged wire: 'radio' and your words reach every other set." },
    { id = "receiver", name = "Receiver", description = "A movement: a frame with it draws from Wardenclyffe's tower, however far." },
    { id = "tesla_coil", name = "Tesla coil base", description = "A movement: under three copper coils and a steel ring, a frame becomes a Tesla coil." },
    { id = "arc_electrodes", name = "Arc electrodes", description = "A movement on charged wire: an electric furnace for chromium." },
    { id = "resonator", name = "Aether resonator", description = "A movement: near a Tesla coil, it rings orichalcum into aetherium." },
    { id = "crookes_tube", name = "Crookes tube", description = "A glass tube with no air in it, where cathode rays glow." },
    { id = "xray_viewer", name = "X-ray viewer", description = "Use it with a charged cell: ore glows through the rock ahead of you." },
    { id = "oscillator", name = "Earthquake machine", description = "Use it on rock with a charged cell: the column under it shakes loose." },
    { id = "radium_grain", name = "Radium", description = "A grain that glows in the dark, from a great deal of pitchblende." },
    { id = "radium_cell", name = "Radium cell", description = "A movement: gives a little charge, for ever." },
    { id = "helium", name = "Jar of helium", description = "Lighter than air: a balloon that floats a long while." },
    { id = "chrome_steel_ingot", name = "Chrome steel ingot", description = "Steel with chromium in it: harder than any." },
    { id = "bakelite", name = "Bakelite", description = "The first plastic, from coal tar." },
    { id = "aetherium_ingot", name = "Aetherium ingot", description = "Orichalcum that rings with the aether. It hums." },
    { id = "aether_cell", name = "Aether cell", description = "A movement: a great, endless trickle of charge." },
    { id = "aetherometer", name = "Aetherometer", description = "Use it anywhere: a needle that feels the aether drift." },
    -- Chrome steel tools (tier 4 of the dig classes), and the diamond drill (tier 5).
    { id = "chrome_pick", name = "Chrome steel pick", description = "Tier 4. Digs rock.",
        tool = { type = "pick", tier = 4, uses = 2000 }, speed = 4.4 },
    { id = "chrome_axe", name = "Chrome steel axe", description = "Tier 4. Digs wood.",
        tool = { type = "axe", tier = 4, uses = 2000 }, speed = 5.0 },
    { id = "chrome_spade", name = "Chrome steel spade", description = "Tier 4. Digs earth.",
        tool = { type = "spade", tier = 4, uses = 2000 }, speed = 5.4 },
    { id = "chrome_chisel", name = "Chrome steel chisel", description = "Tier 4. Carves one cell at a time.",
        tool = { type = "chisel", tier = 4, uses = 4000 }, speed = 1.6, brush = "subnode", group = "#chisel" },
    { id = "chrome_hammer", name = "Chrome steel hammer", description = "Tier 4. For the anvil.",
        tool = { type = "hammer", tier = 4, uses = 2000 }, group = "#hammer" },
    { id = "diamond_drill", name = "Diamond drill", description = "Tier 5. Digs any rock, a charge a block from a carried cell.",
        tool = { type = "pick", tier = 5, uses = 4000 }, speed = 7.0, charged = true },
}

C.cavorite = {
    id = "cavorite", name = "Cavorite",
    description = "Wells' alloy: gravity cannot pass it. Carve it.",
    hardness = 4.0, tags = { "metal" }, light = { r = 2, g = 1, b = 4 },
}
-- Cavorite resists iron: a class of this mod's, broken by steel or better.
C.reinforced = { id = "reinforced", types = { "pick", "chisel" }, tier = 3,
    refusals = { tier = "Cavorite turns iron aside. It wants steel." } }

C.tier6_recipes = {
    { id = "radio", station = "workbench", node = "science.radio",
        inputs = { { glyph = "coil", material = "copper_stock", count = 2 }, { "glass_bulb", count = 2 }, { "cell", count = 1 } },
        outputs = { { "radio", count = 1 } } },
    { id = "receiver", station = "workbench", node = "science.wardenclyffe",
        inputs = { { glyph = "coil", material = "copper_stock", count = 1 }, { glyph = "plate", material = "copper_stock", count = 1 },
            { "bakelite", count = 1 } },
        outputs = { { "receiver", count = 1 } } },
    { id = "tesla_coil", station = "workbench", node = "science.tesla_coil",
        inputs = { { "leyden_jar", count = 4 }, { "C:iron_frame", count = 1 }, { glyph = "coil", material = "copper_stock", count = 1 } },
        outputs = { { "tesla_coil", count = 1 } } },
    { id = "arc_electrodes", station = "workbench", node = "science.arc_furnace",
        inputs = { { "carbon_rod", count = 4 }, { "C:brick", count = 4 }, { "copper_stock", count = 2 } },
        outputs = { { "arc_electrodes", count = 1 } } },
    { id = "crookes_tube", station = "workbench", node = "science.crookes_tube", tools = { { "air_pump", wear = 0 } },
        inputs = { { "glass_tube", count = 1 }, { glyph = "rod", material = "copper_stock", count = 2 } },
        outputs = { { "crookes_tube", count = 1 } } },
    { id = "xray_viewer", station = "workbench", node = "science.x_rays",
        inputs = { { "crookes_tube", count = 1 }, { "lens_blank", count = 1 }, { "C:lead_ingot", count = 2 } },
        outputs = { { "xray_viewer", count = 1 } } },
    { id = "oscillator", station = "workbench", node = "science.tesla_oscillator",
        inputs = { { "piston", count = 2 }, { "spring", count = 2 }, { "steel_ingot", count = 2 } },
        outputs = { { "oscillator", count = 1 } } },
    { id = "radium_grain", station = "furnace", node = "science.radioactivity", heat = 5, ticks = 6000,
        inputs = { { "W:pitchblende", units = 729 }, { "#oil_of_vitriol", count = 1 } }, outputs = { { "radium_grain", count = 1 } } },
    { id = "radium_cell", station = "workbench", node = "science.radioactivity",
        inputs = { { "radium_grain", count = 1 }, { "cell", count = 1 }, { "C:lead_ingot", count = 2 } },
        outputs = { { "radium_cell", count = 1 } } },
    { id = "helium", station = "furnace", node = "science.helium", heat = 5, ticks = 1200,
        inputs = { { "W:pitchblende", units = 27 }, { "glass_jar", count = 1 } },
        outputs = { { "helium", count = 1 } } },
    { id = "chrome_steel", station = "frame", node = "science.arc_furnace", tools = { { "arc_electrodes", wear = 0 } }, ticks = 1200,
        inputs = { { "W:chromium_ore", units = 27 }, { "steel_ingot", count = 2 } }, outputs = { { "chrome_steel_ingot", count = 2 } } },
    { id = "chrome_pick", station = "workbench", node = "science.arc_furnace", tools = { { "#hammer", wear = 1 } },
        inputs = { { "chrome_steel_ingot", count = 3 }, { "C:haft", count = 1 } }, outputs = { { "chrome_pick", count = 1 } } },
    { id = "chrome_axe", station = "workbench", node = "science.arc_furnace", tools = { { "#hammer", wear = 1 } },
        inputs = { { "chrome_steel_ingot", count = 3 }, { "C:haft", count = 1 }, { "C:cord", count = 1 } }, outputs = { { "chrome_axe", count = 1 } } },
    { id = "chrome_spade", station = "workbench", node = "science.arc_furnace", tools = { { "#hammer", wear = 1 } },
        inputs = { { "chrome_steel_ingot", count = 2 }, { "C:haft", count = 1 } }, outputs = { { "chrome_spade", count = 1 } } },
    { id = "chrome_chisel", station = "workbench", node = "science.arc_furnace", tools = { { "#hammer", wear = 1 } },
        inputs = { { "chrome_steel_ingot", count = 1 }, { "C:stick", count = 1 } }, outputs = { { "chrome_chisel", count = 1 } } },
    { id = "chrome_hammer", station = "workbench", node = "science.arc_furnace", tools = { { "#hammer", wear = 1 } },
        inputs = { { "chrome_steel_ingot", count = 2 }, { "C:stick", count = 1 } }, outputs = { { "chrome_hammer", count = 1 } } },
    { id = "diamond_drill", station = "workbench", node = "science.diamond_drill",
        inputs = { { "W:diamond", units = 27 }, { "chrome_steel_ingot", count = 2 }, { "motor", count = 1 } },
        outputs = { { "diamond_drill", count = 1 } } },
    { id = "bakelite", station = "furnace", node = "science.bakelite", heat = 2, ticks = 600,
        inputs = { { "coal_tar", units = 27 }, { "soda", count = 1 } }, outputs = { { "bakelite", count = 2 } } },
    { id = "aetherium", station = "frame", node = "science.luminiferous_aether", tools = { { "resonator", wear = 0 } }, ticks = 2400,
        inputs = { { "W:orichalcum", units = 27 } }, outputs = { { "aetherium_ingot", count = 1 } } },
    { id = "resonator", station = "workbench", node = "science.luminiferous_aether",
        inputs = { { glyph = "ring", material = "steel_stock", count = 2 }, { "crookes_tube", count = 1 }, { "C:silver_ingot", count = 2 } },
        outputs = { { "resonator", count = 1 } } },
    { id = "aetherometer", station = "workbench", node = "science.luminiferous_aether",
        inputs = { { "aetherium_ingot", count = 1 }, { "clockwork", count = 1 }, { "C:glass", count = 1 } },
        outputs = { { "aetherometer", count = 1 } } },
    { id = "aether_cell", station = "frame", node = "science.aether_cell", relic = true, ticks = 2400,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "ring", material = "steel_stock", count = 1 }, { glyph = "coil", material = "copper_stock", count = 1 },
            { "aetherium_ingot", count = 4 }, { "radium_grain", count = 1 } },
        outputs = { { "aether_cell", count = 1 } } },
    { id = "cavorite", station = "furnace", node = "science.cavorite", heat = 5, ticks = 2400,
        inputs = { { "aetherium_ingot", count = 1 }, { "C:lead_ingot", count = 1 }, { "helium", count = 1 } },
        tools = { { "C:crucible", wear = 1 } }, outputs = { { "cavorite", count = 1 }, { "glass_jar", count = 1 } } },
}

C.tier6_studies = {
    { id = "study_radium", name = "Radium", inputs = { { "radium_grain", count = 1 } }, ticks = 6000, insight = 400 },
    { id = "study_aetherium", name = "Aetherium", inputs = { { "aetherium_ingot", count = 1 } }, ticks = 9000, insight = 500 },
    { id = "study_cavorite", name = "Cavorite", inputs = { { "cavorite", count = 1 } }, ticks = 12000, insight = 800 },
}

C.tier6_firsts = {
    chrome_steel = "arc_furnace", radium_grain = "radium", helium = "helium", bakelite = "bakelite",
    aetherium = "aetherium", aether_cell = "aether_cell", cavorite = "cavorite",
}
C.tier6_toys = { radio = 10, tesla = 10, xray = 5, quake = 10, aether = 20, wardenclyffe = 50 }

-- The Tesla coil (brief §6.5): around a coil whose network carries it.
C.tesla = {
    lamp_reach = 16,              -- lamps light with no wire
    arc_reach = 8, arc_every = 100, arc_ticks = 60,
    charge_reach = 8, charge_rate = 5,     -- carried jars and cells, a second
    -- Life's creatures that the arcs find: the ones that come for you.
    hostile = { "wolf", "spider", "scurrier", "cave_troll", "swamp_hag", "ghost" },
}

-- Wardenclyffe (brief §6.5): a tower over a frame with the tesla_coil base,
-- `height` blocks of anything above the coil's ring, copper on its crown, and
-- `root` blocks of copper rods under the frame. One per player.
C.wardenclyffe = { height = 40, root = 30 }

C.radio = { hear = 16, reach = 4 }
C.xray = { ahead = 16, half = 2, seconds = 5, cost = 8 }
C.oscillator = { half = 1, depth = 12, cost = 50 }   -- 3 × 3 × 12: at most 108 stacks dropped
C.drill = { cost = 1 }
C.resonator = { coil_reach = 8 }
C.helium_balloon = { ticks = 12000, speed = 100 }  -- ten minutes, at a walk; the jar comes back

-- Tier 7: beyond the event horizon (brief §5.5, §6.7, §6.8) -----------------------------------

C.tier7_items = {
    { id = "cavorite_soles", name = "Cavorite soles", description = "Worn: you weigh half as much, anywhere." },
    { id = "levitator", name = "Levitator harness", description = "Worn, with a charged cell in the pack: flight." },
    { id = "attractor", name = "Attractor", description = "A movement on charge: dropped things within 8 are drawn to the frame." },
    { id = "repulsor", name = "Repulsor", description = "A movement on charge: what hunts you is thrust away from the frame." },
    { id = "stasis", name = "Stasis field", description = "A movement on charge: creatures near the frame hang still." },
    { id = "fold_key", name = "Fold key", description = "Turns the Core, opens gates, and folds space." },
    { id = "terraformer", name = "Terraformer", description = "A movement on charge: greens the barren ground of a body around its frame." },
    { id = "atmosphere_processor", name = "Atmosphere processor", description = "A movement on charge: gives a living body a sky." },
    { id = "strange_matter", name = "Strange matter", description = "From the Deep. It is heavier than it looks, and colder." },
    { id = "recall_beacon", name = "Recall beacon", description = "Use it: a pocket fold to your nearest gate, once an hour." },
    { id = "unified_field_engine", name = "Unified Field Engine", description = "Use it: fold to any gate or body you know." },
}

C.wormhole = {
    id = "wormhole", name = "Wormhole", description = "A throat in space. Step in.",
    hardness = 100, light = { r = 6, g = 4, b = 12 },
}
C.horizon_glass = {
    id = "horizon_glass", name = "Horizon glass", description = "Glass from strange matter: darker inside than out.",
    hardness = 3.0, tags = { "glass" },
}

C.tier7_recipes = {
    { id = "cavorite_soles", station = "workbench", node = "science.gravity_plating",
        inputs = { { glyph = "plate", material = "cavorite", count = 2 }, { "C:leather", count = 2 } },
        outputs = { { "cavorite_soles", count = 1 } } },
    { id = "attractor", station = "workbench", node = "science.gravity_well",
        inputs = { { glyph = "wheel", material = "cavorite", count = 1 }, { glyph = "coil", material = "copper_stock", count = 2 },
            { "motor", count = 1 } },
        outputs = { { "attractor", count = 1 } } },
    { id = "repulsor", station = "workbench", node = "science.gravity_well",
        inputs = { { glyph = "ring", material = "cavorite", count = 1 }, { glyph = "coil", material = "copper_stock", count = 2 },
            { "motor", count = 1 } },
        outputs = { { "repulsor", count = 1 } } },
    { id = "stasis", station = "workbench", node = "science.stasis_field",
        inputs = { { glyph = "ring", material = "cavorite", count = 2 }, { "crookes_tube", count = 1 }, { "cell", count = 1 } },
        outputs = { { "stasis", count = 1 } } },
    { id = "levitator", station = "frame", node = "science.levitator", relic = true, ticks = 2400,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "plate", material = "cavorite", count = 4 }, { glyph = "coil", material = "copper_stock", count = 1 },
            { "C:leather", count = 4 }, { "cell", count = 1 } },
        outputs = { { "levitator", count = 1 } } },
    { id = "fold_key", station = "frame", node = "science.the_core", relic = true, ticks = 2400,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "ring", material = "cavorite", count = 1 }, { glyph = "rod", material = "cavorite", count = 1 },
            { "aetherium_ingot", count = 9 }, { "radium_grain", count = 1 } },
        outputs = { { "fold_key", count = 1 } } },
    { id = "fold_key_strange", station = "frame", node = "science.the_core", relic = true, ticks = 2400,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "ring", material = "cavorite", count = 1 }, { glyph = "rod", material = "cavorite", count = 1 },
            { "strange_matter", count = 9 }, { "radium_grain", count = 1 } },
        outputs = { { "fold_key", count = 1 } } },
    { id = "terraformer", station = "workbench", node = "science.terraforming",
        inputs = { { "steel_ingot", count = 4 }, { "motor", count = 1 }, { "aetherium_ingot", count = 1 } },
        outputs = { { "terraformer", count = 1 } } },
    { id = "atmosphere_processor", station = "workbench", node = "science.atmosphere_processor",
        inputs = { { "steel_ingot", count = 4 }, { "helium", count = 2 }, { "aetherium_ingot", count = 2 } },
        outputs = { { "atmosphere_processor", count = 1 } } },
    { id = "horizon_glass", station = "furnace", node = "science.strange_matter", heat = 5, ticks = 1200,
        inputs = { { "strange_matter", count = 1 }, { "C:glass", units = 27 * 4 } }, outputs = { { "horizon_glass", count = 4 } } },
    { id = "recall_beacon", station = "workbench", node = "science.recall_beacon",
        inputs = { { glyph = "ring", material = "cavorite", count = 1 }, { "aetherium_ingot", count = 1 },
            { "radium_grain", count = 1 }, { "cell", count = 1 } },
        outputs = { { "recall_beacon", count = 1 } } },
    { id = "unified_field_engine", station = "frame", node = "science.unified_field", relic = true, ticks = 6000,
        tools = { { "assembly_jig", wear = 0 } },
        inputs = { { glyph = "ring", material = "cavorite", count = 3 }, { glyph = "wheel", material = "cavorite", count = 1 },
            { "strange_matter", count = 27 }, { "aether_cell", count = 1 }, { "fold_key", count = 1 } },
        outputs = { { "unified_field_engine", count = 1 } } },
}

-- Strange matter where there is no Deep. In a world made with the Deep off,
-- the resonator, by a live Tesla coil, condenses the overworld's own abyss
-- rock (World's morphic rock, below 4 km) into it, so the horizon glass, the
-- strange matter study and the Unified Field Engine can still be made.
-- Registered only in such a world: where the Deep is, the Deep is the source.
C.tier7_without_deep = {
    { id = "strange_matter_condensed", station = "frame", node = "science.strange_matter", ticks = 2400,
        tools = { { "resonator", wear = 0 } },
        inputs = { { "W:morphic_rock", units = 27 * 3 }, { "aetherium_ingot", count = 1 } },
        outputs = { { "strange_matter", count = 1 } } },
}

C.tier7_studies = {
    { id = "study_strange_matter", name = "Strange matter", inputs = { { "strange_matter", count = 1 } }, ticks = 12000, insight = 800 },
    { id = "study_fold_key", name = "The fold key", inputs = { { "fold_key", count = 1 } }, ticks = 18000, insight = 1200 },
}

C.tier7_firsts = {
    levitator = "levitator", fold_key = "fold_key", fold_key_strange = "fold_key",
    horizon_glass = "horizon_glass", unified_field_engine = "unified_field",
}
C.tier7_toys = {
    plating = 20, levitate = 20, well = 10, stasis = 10, core = 100, wormhole = 50, recall = 20,
    drone = 20, deep = 100, living = 500, atmosphere = 100,
}
-- Every body first visited is a discovery of its own (`body:<star id>`).
C.body_family = { insight = 100, group = "bodies", label = "A world at a star: %s" }

-- Gravity (§6.7): each a source of this mod's in Life's `set_ability`, so
-- Life composes them with its own, and they multiply together.
C.plating = { reach = 3, gravity = 0.17 }       -- standing within 3 above a cavorite plate: the Moon's
C.soles = { gravity = 0.5, period = 20 }         -- worn, read once a second
C.levitator_spec = { cost = 4, speed = 100 }     -- charge a second, from a carried cell
C.well = { radius = 8, period = 10, pull = 0.4, push = 2 }
C.stasis_spec = { radius = 6, period = 20, ticks = 40 }
-- The gravity engine: two cavorite wheels on a steel shaft (wheel, rod, wheel,
-- standing) beside a frame with the dynamo armature.
C.gravity_engine = { charge = 512 }

-- The Core (§6.8): three 5 × 5 rings of cavorite ring blocks round a throat,
-- four live Tesla coils near, and a gravity engine within reach. The key is
-- used on the ring block under the throat.
C.core = { coils = 4, coil_reach = 8, engine_reach = 16, spin_ticks = 1200, dark_radius = 64,
    fold_reach = 16, alignment = 0.9998, model = "core_ring",
    hum = { sound = "core_hum", radius = 64, gain = 0.8, fade_ticks = 60 } }
-- A wormhole gate: an upright 3 × 3 ring of cavorite ring blocks, the key used
-- on the ring's bottom middle block. Open while a live Tesla coil is near.
C.gate = { pairs = 8, coil_reach = 16, period = 20,
    carries = 0.75 }   -- dropped things within the throat block go through; the twin's front is a block out, so nothing comes back

-- The bodies (§6.8): a star's warmth chooses its kind, its magnitude its size
-- and gravity. Materials are the world's.
C.bodies = {
    kinds = {
        { id = "ice", below = 0.2, top = "W:snow", under = "W:ice", deep = "W:stone", height = 24, rough = 6,
            sky = { 0.55, 0.65, 0.8 }, sun = { 0.8, 0.9, 1.0 } },
        { id = "rust", below = 0.4, top = "W:rust_red_sandstone", under = "W:ochre_sandstone", deep = "W:stone", height = 28, rough = 10,
            sky = { 0.7, 0.45, 0.3 }, sun = { 1.0, 0.75, 0.55 } },
        { id = "regolith", below = 0.6, top = "W:gravel", under = "W:slate", deep = "W:stone", height = 20, rough = 8,
            sky = { 0.05, 0.05, 0.08 }, sun = { 1.0, 1.0, 0.95 } },
        { id = "basalt", below = 0.8, top = "W:volcanic_ash", under = "W:dark_basalt", deep = "W:dark_basalt", height = 32, rough = 14,
            sky = { 0.35, 0.2, 0.18 }, sun = { 1.0, 0.6, 0.4 } },
        { id = "glass", below = 2.0, top = "W:sand", under = "W:obsidian", deep = "W:obsidian", height = 26, rough = 9,
            sky = { 0.85, 0.75, 0.55 }, sun = { 1.0, 0.95, 0.8 } },
    },
    -- Magnitude below each bound: the body's radius in blocks, and its gravity.
    sizes = { { below = 0.34, radius = 1000, gravity = 0.4 }, { below = 0.67, radius = 2000, gravity = 0.6 },
        { below = 2.0, radius = 3000, gravity = 0.8 } },
    per_player = 16,                 -- bodies a player may fold to
    arrive = { x = 0.5, y = 80, z = 0.5 },   -- falls from here to the ground, lightly
}

C.terraform = { period = 10, half = 8, region = 64, living_share = 60,
    green = { "W:dirt", "W:grass" }, plants = { "W:tall_grass", "W:fern" }, plant_every = 5,
    -- On an ice world every fourth column's ice melts instead: a block of ice
    -- under the snow becomes a block of the world's water.
    melt_every = 4, ice = "W:ice", snow = "W:snow", water = "tiamat_default_world:water" }

-- The Deep (§6.8): a misfold. Fragments in a void; fall off and you come back.
C.deep = { fall = -64, arrive = { x = 0.5, y = 4, z = 0.5 }, platform = 6,
    rock = { "W:dark_basalt", "W:obsidian", "W:morphic_rock" }, strange = "W:morphic_rock",
    sky = { 0.06, 0.0, 0.02 }, sun = { 0.35, 0.05, 0.05 } }
C.shades = { count = 3, far = 24, near = 2, period = 40, push = 8, model = "shade",
    flicker = { ticks = 8, intensity = 0.15 } }      -- the light dips when one reaches you

C.recall = { cooldown = 72000 }           -- an hour of ticks
C.unified = { cost = 256 }
C.drone = { reach = 16, step = 4, above = 3 }  -- gravitic automata: further, and flying

-- Toybox discoveries (brief §6.9): insight for play itself.
C.toybox = {
    hour = 3,                       -- the first hour told by a sundial
    kite = 5,                       -- the first kite flown
    home = 5,                       -- the first time a compass finds home
    sunfire = 5,                    -- the first fire lit by sunshine
    water = 5,                      -- the first water lifted by a pump
}

return C
