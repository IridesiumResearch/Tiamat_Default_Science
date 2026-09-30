-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 3, Mechanica (brief §5.1): what the tier registers with Craft and
-- Progress. The machinery itself is `networks.lua`, `frame.lua` and
-- `furnace.lua`; the tables are `config.lua`'s. Here: the recipes, the
-- group of iron a blast furnace takes, the crowbar, the studies at the
-- research table, and the discoveries — the first thing each movement
-- makes is an invention, and the first water a pump lifts is a toy.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local M = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")

M.recipes = {}      -- node id -> its recipes, for the Theatrum

if craft then
    local members = {}
    for i, id in ipairs(C.smeltable_iron) do members[i] = U.id(id) end
    craft.register_group("#smeltable_iron", members)

    U.register_recipes(craft, C.tier3_recipes, M.recipes)

    -- Tools: gated and worn by Craft; those that dig are engine tools too.
    for _, spec in ipairs(C.tier3_items) do
        if spec.tool then
            local ok, why = craft.register_tool{
                id = U.id(spec.id), type = spec.tool.type, tier = spec.tool.tier, uses = spec.tool.uses,
                digs = spec.speeds ~= nil, name = spec.name,
            }
            if not ok then game.log("tiamat_default_science: Craft refused the tool " .. spec.id .. ": " .. tostring(why)) end
        end
    end
end

if progress then
    for _, study in ipairs(C.tier3_studies) do
        local inputs = {}
        for i, e in ipairs(study.inputs) do inputs[i] = U.entry(e) end
        local ok, why = progress.register_study{
            id = U.id(study.id), name = study.name, inputs = inputs, ticks = study.ticks, insight = study.insight,
        }
        if not ok then game.log("tiamat_default_science: Progress refused the study " .. study.id .. ": " .. tostring(why)) end
    end

    -- Progress splits a discovery id at its FIRST colon to find a family.
    progress.register_discovery{ id = A.INVENTION .. ":*", insight = C.inventions.insight, label = "Invented: %s",
        group = "inventions" }
end

-- The first thing each movement makes, heard from Craft's firsts: the frame's
-- recipes are made as its placer, so the invention is theirs.
local FIRSTS = {}
for recipe, what in pairs(C.inventions.firsts) do FIRSTS["craft:" .. U.id(recipe)] = what end

if craft then
    craft.on_first(function(uuid, event)
        local what = FIRSTS[event]
        if what then A.discover(uuid, A.INVENTION .. ":" .. what) end
    end)
end

return M
