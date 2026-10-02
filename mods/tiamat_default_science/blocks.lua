-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The blocks this mod registers (brief §8). There will be ten, and each is
-- a block only because it must be one; every machine, network and structure
-- beyond them is carved from the world's blocks, Craft's plank and glass,
-- and this mod's three stocks. So far: the door (Progress's door must be a
-- block a player uses), the frame and the furnace (a Craft station in the
-- world is a block), the arc lamp (light needs a block, and on and off is
-- two), and copper and steel stock (carving needs placeable metal). The door,
-- the frame and the lamp are drawn as models, and they and the furnace are
-- whole: dug in one piece, never carved.

local C = tds.config

local B = {}

-- Models first: a model block names one.
for _, id in ipairs(C.models) do
    local ok, why = pcall(game.register_model, { id = id, file = "models/" .. id .. ".glb", texture = "models/" .. id .. ".png" })
    if not ok then game.log("tiamat_default_science: the " .. id .. " model was refused: " .. tostring(why)) end
end

-- What makes a block whole or a model (Sub-Node Contract §7.5, §8.6). An
-- engine older than these fields refuses them, and the block is then
-- registered without them: a cube that a chisel can carve, which is how it
-- always was, rather than no block at all.
local SHAPED = { "whole", "model", "shape" }

local function block(spec, extra)
    local def = {
        id = spec.id,
        name = spec.name,
        description = spec.description,
        hardness = spec.hardness,
        tags = spec.tags,
        textures = { all = "textures/" .. spec.id .. ".png" },
    }
    for k, v in pairs(extra or {}) do def[k] = v end
    local ok, material = pcall(game.register_block, def)
    if ok then return material end
    for _, k in ipairs(SHAPED) do def[k] = nil end
    game.log("tiamat_default_science: " .. spec.id .. " registered without its model or wholeness: " .. tostring(material))
    return game.register_block(def)
end

local function shaped(spec, model)
    return { whole = spec.whole, model = model or spec.model, shape = spec.shape }
end

B.antikythera = block(C.antikythera, shaped(C.antikythera))
B.frame = block(C.frame, shaped(C.frame))
-- The stocks are carved: never whole.
B.copper_stock = block(C.copper_stock)
B.steel_stock = block(C.steel_stock)
B.furnace = block(C.furnace, shaped(C.furnace))
-- The lit furnace glows; Craft swaps it in while the fire burns.
B.furnace_lit = block({
    id = C.furnace.lit, name = C.furnace.name .. " (burning)", description = C.furnace.description,
    hardness = C.furnace.hardness, tags = C.furnace.tags,
}, { light_emit = C.furnace.light, whole = C.furnace.whole })
-- The arc lamp, dark and lit: the charge network swaps one for the other.
B.lamp = block({ id = C.lamp.id, name = C.lamp.name, description = C.lamp.description,
    hardness = C.lamp.hardness, tags = C.lamp.tags }, shaped(C.lamp))
local lit = shaped(C.lamp, C.lamp.lit_model)
lit.light_emit = C.lamp.light
B.lamp_lit = block({ id = C.lamp.lit, name = C.lamp.name .. " (lit)", description = C.lamp.description,
    hardness = C.lamp.hardness, tags = C.lamp.tags }, lit)

return B
