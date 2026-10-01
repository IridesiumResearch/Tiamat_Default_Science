-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 4, natural philosophy 1600–1760 (brief §5.2): what the tier registers
-- with Craft and Progress. The instruments are `philosophy.lua`, charge is
-- `electricity.lua`, and the Newcomen engine is a source of `networks.lua`;
-- the tables are `config.lua`'s. Here: the reagents' groups (each mod's own
-- item in a shared group, so they trade across the Fork), coke as a fuel,
-- the recipes, the steel tools, the studies and the discoveries.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local T4 = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")

T4.recipes = {}     -- node id -> its recipes, for the Theatrum

if craft then
    for _, name in ipairs(U.sorted_keys(C.tier4_groups)) do
        local members = {}
        for i, id in ipairs(C.tier4_groups[name]) do members[i] = U.id(id) end
        craft.register_group(name, members)
    end
    craft.register_fuel(U.id("coke"), C.coke_fuel.heat, C.coke_fuel.ticks)

    U.register_recipes(craft, C.tier4_recipes, T4.recipes)

    for _, spec in ipairs(C.tier4_items) do
        if spec.tool then
            local ok, why = craft.register_tool{
                id = U.id(spec.id), type = spec.tool.type, tier = spec.tool.tier, uses = spec.tool.uses,
                digs = spec.speed ~= nil, name = spec.name,
            }
            if not ok then game.log("tiamat_default_science: Craft refused the tool " .. spec.id .. ": " .. tostring(why)) end
            if spec.group then craft.register_group(spec.group, { U.id(spec.id) }) end
        end
    end
end

-- Discoveries -------------------------------------------------------------------

T4.FAMILY = {}      -- family name -> its id prefix: `tiamat_default_science.star`
for name in pairs(C.families) do T4.FAMILY[name] = game.mod_id .. "." .. name end
T4.TOY = {}         -- toy name -> its discovery id
for name in pairs(C.tier4_toys) do T4.TOY[name] = game.mod_id .. "." .. name end

local TOY_LABELS = {
    spark = "A spark from a jar",
    magdeburg = "Two horses, and the hemispheres held",
    balloon = "Up in a balloon",
    franklin = "A jar filled from a storm",
    lightning = "You caught lightning!",
}

if progress then
    for _, study in ipairs(C.tier4_studies) do
        local inputs = {}
        for i, e in ipairs(study.inputs) do inputs[i] = U.entry(e) end
        local ok, why = progress.register_study{
            id = U.id(study.id), name = study.name, inputs = inputs, ticks = study.ticks, insight = study.insight,
        }
        if not ok then game.log("tiamat_default_science: Progress refused the study " .. study.id .. ": " .. tostring(why)) end
    end
    for _, name in ipairs(U.sorted_keys(C.families)) do
        local f = C.families[name]
        progress.register_discovery{ id = T4.FAMILY[name] .. ":*", insight = f.insight, label = f.label, group = f.group }
    end
    for _, name in ipairs(U.sorted_keys(C.tier4_toys)) do
        progress.register_discovery{ id = T4.TOY[name], insight = C.tier4_toys[name], label = TOY_LABELS[name],
            group = name == "lightning" and "inventions" or "toybox" }
    end
end

--- A member of a family, found: `T4.found(uuid, "star", 1234)`. A name is
--- made safe for a discovery id (Progress splits at the first colon only, so
--- later colons would do, but a dot reads better in a ledger).
function T4.found(uuid, family, name)
    local safe = string.gsub(tostring(name), ":", ".")
    return A.discover(uuid, T4.FAMILY[family] .. ":" .. safe)
end

function T4.toy(uuid, name)
    return A.discover(uuid, T4.TOY[name])
end

-- Inventions: the first of each of tier 4's works.
local FIRSTS = {}
for recipe, what in pairs(C.tier4_firsts) do FIRSTS["craft:" .. U.id(recipe)] = what end
if craft then
    craft.on_first(function(uuid, event)
        local what = FIRSTS[event]
        if what then A.discover(uuid, A.INVENTION .. ":" .. what) end
    end)
end

return T4
