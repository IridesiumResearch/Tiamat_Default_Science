-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 7, beyond the event horizon (brief §5.5, §6.7, §6.8): what the tier
-- registers with Craft and Progress. Its machinery is elsewhere — gravity is
-- `gravity.lua`, the gravity engine is reckoned by `grid.lua`, the worlds at
-- the stars and the Deep are `bodies.lua`, and gates, the Core and the Fold
-- are `fold.lua` — and its tables are `config.lua`'s.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local T7 = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")

T7.recipes = {}     -- node id -> its recipes, for the Theatrum

if craft then
    U.register_recipes(craft, C.tier7_recipes, T7.recipes)
end

if progress then
    for _, study in ipairs(C.tier7_studies) do
        local inputs = {}
        for i, e in ipairs(study.inputs) do inputs[i] = U.entry(e) end
        local ok, why = progress.register_study{
            id = U.id(study.id), name = study.name, inputs = inputs, ticks = study.ticks, insight = study.insight,
        }
        if not ok then game.log("tiamat_default_science: Progress refused the study " .. study.id .. ": " .. tostring(why)) end
    end
end

-- Toys, firsts and bodies --------------------------------------------------------------

T7.TOY = {}
for name in pairs(C.tier7_toys) do T7.TOY[name] = game.mod_id .. "." .. name end
local TOY_LABELS = {
    plating = "Light on a cavorite plate",
    levitate = "Lifted by a levitator",
    well = "A gravity well drawing",
    stasis = "A creature held still",
    core = "The Core turns",
    wormhole = "Through a wormhole",
    recall = "Folded home",
    drone = "An automaton that flies",
    deep = "Lost in the Deep, and back",
    living = "A barren world, living",
    atmosphere = "A sky remade",
}
T7.BODY = game.mod_id .. ".body"

if progress then
    for _, name in ipairs(U.sorted_keys(C.tier7_toys)) do
        progress.register_discovery{ id = T7.TOY[name], insight = C.tier7_toys[name], label = TOY_LABELS[name],
            group = "inventions" }
    end
    progress.register_discovery{ id = T7.BODY .. ":*", insight = C.body_family.insight, label = C.body_family.label,
        group = C.body_family.group }
end

function T7.toy(uuid, name)
    return A.discover(uuid, T7.TOY[name])
end

--- A body first visited: `T7.body(uuid, star id)`.
function T7.body(uuid, star)
    return A.discover(uuid, T7.BODY .. ":" .. tostring(star))
end

local FIRSTS = {}
for recipe, what in pairs(C.tier7_firsts) do FIRSTS["craft:" .. U.id(recipe)] = what end
if craft then
    craft.on_first(function(uuid, event)
        local what = FIRSTS[event]
        if what then A.discover(uuid, A.INVENTION .. ":" .. what) end
    end)
end

return T7
