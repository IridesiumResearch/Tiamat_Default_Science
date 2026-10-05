-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 5, the Industrial Revolution (brief §5.3): what the tier registers
-- with Craft and Progress. Its machinery is elsewhere — the charge network
-- `grid.lua`, the workshop's devices `workshop.lua`, the automata
-- `automata.lua` — and its tables are `config.lua`'s.
--
-- Two of the tier's ideas are carried here:
--
-- **Punched cards** choose a frame's recipe. A card is a carved plank face
-- (`glyph_table.lua`'s `card_1` to `card_8`), and a recipe that names one as a
-- tool is more particular than the same recipe without it, so Craft makes it
-- whenever the card lies in the frame. The trip hammer's plain work is plates;
-- with card 1 it makes nails, card 2 chain, card 3 hinges.
--
-- **Interchangeable parts** make every relic cheaper: when the assembly jig
-- makes one for a player who holds the node, a quarter of each kind of
-- carved part it took comes back (at least one), as the carving it was.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local T5 = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")

T5.recipes = {}     -- node id -> its recipes, for the Theatrum

if craft then
    U.register_recipes(craft, C.tier5_recipes, T5.recipes)
end

if progress then
    for _, study in ipairs(C.tier5_studies) do
        local inputs = {}
        for i, e in ipairs(study.inputs) do inputs[i] = U.entry(e) end
        local ok, why = progress.register_study{
            id = U.id(study.id), name = study.name, inputs = inputs, ticks = study.ticks, insight = study.insight,
        }
        if not ok then game.log("tiamat_default_science: Progress refused the study " .. study.id .. ": " .. tostring(why)) end
    end
end

-- Toys and firsts -----------------------------------------------------------------

T5.TOY = {}
for name in pairs(C.tier5_toys) do T5.TOY[name] = game.mod_id .. "." .. name end
local TOY_LABELS = {
    photograph = "A building caught on silver",
    blueprint = "A building built again",
    elevator = "Up in a safety elevator",
    telegraph = "A message down the wire",
    lamp = "An arc lamp lit",
}
if progress then
    for _, name in ipairs(U.sorted_keys(C.tier5_toys)) do
        progress.register_discovery{ id = T5.TOY[name], insight = C.tier5_toys[name], label = TOY_LABELS[name],
            group = "inventions" }
    end
end

function T5.toy(uuid, name)
    return A.discover(uuid, T5.TOY[name])
end

local FIRSTS = {}
for recipe, what in pairs(C.tier5_firsts) do FIRSTS["craft:" .. U.id(recipe)] = what end
if craft then
    craft.on_first(function(uuid, event)
        local what = FIRSTS[event]
        if what then A.discover(uuid, A.INVENTION .. ":" .. what) end
    end)
end

-- Interchangeable parts -------------------------------------------------------------

local G = tds.glyphs
local RELICS = {}           -- qualified recipe id -> its config entry
for _, list in ipairs({ C.tier5_recipes, C.tier6_recipes, C.tier7_recipes }) do
    for _, r in ipairs(list) do
        if r.relic then RELICS[U.id(r.id)] = r end
    end
end

-- What a carved part is made of, given back: a group's own first member.
local MATERIAL_OF = { ["#plank"] = "C:plank" }

--- How many of `count` parts a player's interchangeable parts give back.
function T5.refund(count, percent)
    if percent >= 0 or count <= 0 then return 0 end
    return math.max(1, (count * -percent) // 100)
end

if craft then
    craft.on_crafted(function(uuid, recipe_id, _, container)
        local relic = RELICS[recipe_id]
        if not (relic and container and uuid and progress) then return end
        local fx = progress.effects_of(uuid, "science.") or {}
        local percent = fx["science.assembly_parts_percent"] or 0
        if percent >= 0 then return end
        for _, e in ipairs(relic.inputs) do
            if e.glyph then
                local back = T5.refund(e.count or 1, percent)
                local material = U.material(U.id(MATERIAL_OF[e.material] or e.material))
                local mask = G.mask_of(e.glyph)
                if back > 0 and material and mask then
                    game.container_give(container, { material = material, count = back, shape = mask })
                end
            end
        end
    end)
end

return T5
