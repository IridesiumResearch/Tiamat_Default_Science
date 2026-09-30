-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The Tinker's Bench (brief §4): the child's door into natural philosophy.
--
-- A six-year-old will never reach the Fork, so the first taste of science
-- is five SHARED nodes, open before it to every player, science, magic and
-- undecided alike; Progress keeps shared nodes through the Fork and a
-- repath, so nothing here is ever taken away. Every one shows something
-- within seconds of being learned — a kite in the sky, the hour told, a
-- needle that finds home — takes three ingredients at most at one station,
-- and never fails or loses anything.
--
-- This file registers the nodes, the recipes and the discoveries; what the
-- instruments DO is `instruments.lua`.

local C = tds.config
local U = tds.util

local A = {}

local progress = U.exports("tiamat_default_progress")
local craft = U.exports("tiamat_default_craft")

-- The nodes -----------------------------------------------------------------------

A.nodes = {}        -- node id -> its config entry, for the book
for _, node in ipairs(C.bench_nodes) do
    A.nodes[node.id] = node
    if progress then
        local ok, why = progress.register_node{
            id = node.id, tier = node.tier, cost = node.cost, requires = node.requires,
            label = node.label, text = node.text,
        }
        if not ok then game.log("tiamat_default_science: Progress refused " .. node.id .. ": " .. tostring(why)) end
    end
end

-- The recipes ---------------------------------------------------------------------

A.recipes = {}      -- node id -> list of its recipes, in config order, for the book

if craft then
    U.register_recipes(craft, C.bench_recipes, A.recipes)
end

-- Discoveries: play itself pays a little ---------------------------------------------

-- Progress splits a discovery id at its FIRST colon to find a family, so an
-- id here holds dots and no colon.
A.HOUR = game.mod_id .. ".hour"
A.KITE = game.mod_id .. ".kite"
A.HOME = game.mod_id .. ".home"
A.SUNFIRE = game.mod_id .. ".sunfire"
A.WATER = game.mod_id .. ".water"
A.INVENTION = game.mod_id .. ".invention"
A.READ = game.mod_id .. ".read"

if progress then
    progress.register_discovery{ id = A.HOUR, insight = C.toybox.hour, label = "The hour, told by the sun",
        group = "toybox" }
    progress.register_discovery{ id = A.KITE, insight = C.toybox.kite, label = "A kite in the sky",
        group = "toybox" }
    progress.register_discovery{ id = A.HOME, insight = C.toybox.home, label = "A needle that finds home",
        group = "toybox" }
    progress.register_discovery{ id = A.SUNFIRE, insight = C.toybox.sunfire, label = "A fire lit by sunshine",
        group = "toybox" }
    progress.register_discovery{ id = A.WATER, insight = C.toybox.water, label = "Water that climbs",
        group = "toybox" }
end

--- The player found something: paid once, by Progress.
function A.discover(uuid, id)
    if progress then progress.discover(uuid, id) end
end

--- Whether a player holds the node `id` (a Creative world holds all).
function A.has(uuid, id)
    return progress ~= nil and progress.has(uuid, id) == true
end

return A
