-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 6, the electrical age and the aether (brief §5.4): what the tier
-- registers with Craft and Progress. Its machinery is elsewhere — the Tesla
-- coil and Wardenclyffe are reckoned by `grid.lua`, and the coil's arcs,
-- wireless, X-rays, the earthquake machine, the drill and the aetherometer
-- are `electric_age.lua` — and its tables are `config.lua`'s.
--
-- Chrome steel is the fourth rung of the tool ladder and the diamond drill
-- the fifth. Cavorite is a block of a class of its own, `reinforced`, which
-- iron cannot break.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local T6 = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")

T6.recipes = {}     -- node id -> its recipes, for the Theatrum

if craft then
    U.register_recipes(craft, C.tier6_recipes, T6.recipes)

    for _, spec in ipairs(C.tier6_items) do
        if spec.tool then
            local ok, why = craft.register_tool{
                id = U.id(spec.id), type = spec.tool.type, tier = spec.tool.tier, uses = spec.tool.uses,
                digs = spec.speed ~= nil, name = spec.name,
            }
            if not ok then game.log("tiamat_default_science: Craft refused the tool " .. spec.id .. ": " .. tostring(why)) end
            if spec.group then craft.register_group(spec.group, { U.id(spec.id) }) end
        end
    end

    local class = U.id(C.reinforced.id)
    local ok, why = craft.register_class{ id = class, types = C.reinforced.types, tier = C.reinforced.tier,
        refusals = C.reinforced.refusals }
    if ok then ok, why = craft.classify(U.id(C.cavorite.id), class) end
    if not ok then game.log("tiamat_default_science: Craft refused cavorite's class: " .. tostring(why)) end
end

if progress then
    for _, study in ipairs(C.tier6_studies) do
        local inputs = {}
        for i, e in ipairs(study.inputs) do inputs[i] = U.entry(e) end
        local ok, why = progress.register_study{
            id = U.id(study.id), name = study.name, inputs = inputs, ticks = study.ticks, insight = study.insight,
        }
        if not ok then game.log("tiamat_default_science: Progress refused the study " .. study.id .. ": " .. tostring(why)) end
    end
end

-- Toys and firsts -----------------------------------------------------------------

T6.TOY = {}
for name in pairs(C.tier6_toys) do T6.TOY[name] = game.mod_id .. "." .. name end
local TOY_LABELS = {
    radio = "A message with no wire",
    tesla = "A Tesla coil alight",
    xray = "Ore seen through rock",
    quake = "A column shaken loose",
    aether = "The aether felt drifting",
    wardenclyffe = "Wardenclyffe sends power to the world",
}
if progress then
    for _, name in ipairs(U.sorted_keys(C.tier6_toys)) do
        progress.register_discovery{ id = T6.TOY[name], insight = C.tier6_toys[name], label = TOY_LABELS[name],
            group = "inventions" }
    end
end

function T6.toy(uuid, name)
    return A.discover(uuid, T6.TOY[name])
end

local FIRSTS = {}
for recipe, what in pairs(C.tier6_firsts) do FIRSTS["craft:" .. U.id(recipe)] = what end
if craft then
    craft.on_first(function(uuid, event)
        local what = FIRSTS[event]
        if what then A.discover(uuid, A.INVENTION .. ":" .. what) end
    end)
end

return T6
