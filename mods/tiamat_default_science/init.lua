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
-- to, then what the Bench registers — items and glyphs before the recipes
-- and instruments that name them — then the book that shows them, and last
-- the engine hooks and the export, both of which must be whole before the
-- registration window closes.

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
tds.glyphs = load("glyphs")             -- carved shapes that mean something, into Craft
tds.apprentice = load("apprentice")     -- the Tinker's Bench: shared nodes, recipes, discoveries
tds.instruments = load("instruments")   -- the sundial, the glass, the compass, the kite
tds.primer = load("primer")             -- the Theatrum Machinarum
load("commands")                        -- `science`, in chat

tds.hooks.install()

-- What other mods may call. One export per mod, built whole first.
game.export(load("exports"))

game.log(string.format("tiamat_default_science ready: the Tinker's Bench (%d nodes), %d glyph masks",
    #tds.config.bench_nodes, tds.glyphs.count))
