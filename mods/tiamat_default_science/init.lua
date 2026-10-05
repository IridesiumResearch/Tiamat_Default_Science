-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tiamat Default Science: natural philosophy (docs/brief.md). This file only
-- decides load order.
--
-- Every file below is loaded exactly once and hangs what it exports off the
-- `tds` global, which the sandbox shares between a mod's own files. The
-- engine's `require` is confined to this directory and does not cache, so a
-- file required twice would run twice; nothing but this file calls it.
--
-- Order: numbers and helpers, then the hook fan-out every file subscribes
-- to, then what the mod registers — items, blocks and glyphs before the
-- recipes and instruments that name them — then the book that shows them,
-- the path and its tree, and last the engine hooks and the export, both of
-- which must be whole before the registration window closes.

tds = {}

-- The host reports a failed load as "errored in init.lua" and nothing more,
-- so say which file and what the error was before letting it through.
local function load(name)
    local ok, result = pcall(require, name)
    if not ok then
        game.log(string.format("tiamat_default_science: %s.lua failed: %s", name, tostring(result)))
        error(result, 0)
    end
    return result
end

tds.config = load("config")
tds.util = load("util")
tds.hooks = load("hooks")               -- one engine registration per hook, many subscribers
tds.items = load("items")               -- every item, from config's tables
tds.blocks = load("blocks")             -- the blocks the path must have (the door, so far)
tds.glyphs = load("glyphs")             -- carved shapes that mean something, into Craft
tds.apprentice = load("apprentice")     -- the Tinker's Bench: shared nodes, recipes, discoveries
tds.networks = load("networks")         -- turning: shafts, gears, wheels, and what turns them
tds.frame = load("frame")               -- the machine frame, run by Craft at its network's speed
tds.furnace = load("furnace")           -- the furnace, blasted by a turning shaft
tds.mechanica = load("mechanica")       -- tier 3's recipes, studies and inventions
tds.tier4 = load("tier4")               -- tier 4's recipes, groups, steel tools, studies and discoveries
tds.instruments = load("instruments")   -- the sundial, the glass, the compass, the kite, the staff, the needle
tds.philosophy = load("philosophy")     -- the telescope, the microscope, the weather glasses, the chronometer
tds.electricity = load("electricity")   -- the Leyden jar, the friction globe, the lightning rod
tds.tier5 = load("tier5")               -- tier 5's recipes, studies, cards and interchangeable parts
tds.grid = load("grid")                 -- the charge network: piles, cells, dynamos, motors, lamps
tds.workshop = load("workshop")         -- the elevator, the camera, blueprints, the telegraph, the magnet
tds.automata = load("automata")         -- the clockwork automaton and its cards
tds.charges = load("charges")           -- mining charges, dynamite, and what loosens
tds.tier6 = load("tier6")               -- tier 6's recipes, chrome steel, studies, cavorite's class
load("electric_age")                    -- the Tesla coil's arcs, wireless, X-rays, the earthquake machine, the drill
tds.tier7 = load("tier7")               -- tier 7's recipes, relics, studies and discoveries
tds.gravity = load("gravity")           -- plating, soles, the levitator, wells and the stasis field
tds.bodies = load("bodies")             -- the worlds at the stars, terraforming, and the Deep
tds.fold = load("fold")                 -- wormhole gates, the Core, the Fold, recall and the Unified Field
load("printing")                        -- treatises, printed and read
tds.primer = load("primer")             -- the Theatrum Machinarum
tds.tree = load("tree")                 -- the science tree, tiers 3 to 7, as data
tds.path = load("path")                 -- the Antikythera Mechanism's path, and the tree, into Progress
load("commands")                        -- `science`, in chat

tds.hooks.install()

-- What other mods may call. One export per mod, built whole first.
game.export(load("exports"))

game.log(string.format("tiamat_default_science ready: the Tinker's Bench (%d nodes), the Antikythera Mechanism, %d of %d path nodes, %d glyph masks",
    #tds.config.bench_nodes, #tds.path.shipped, #tds.tree, tds.glyphs.count))
