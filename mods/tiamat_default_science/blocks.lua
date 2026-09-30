-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The blocks this mod registers (brief §8). There will be ten, and each is
-- a block only because it must be one; every machine, network and structure
-- beyond them is carved from the world's blocks, Craft's plank and glass,
-- and this mod's three stocks. So far: the door (Progress's door must be a
-- block a player uses), the frame and the furnace (a Craft station in the
-- world is a block), and copper stock (carving needs placeable metal).

local C = tds.config

local B = {}

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
    return game.register_block(def)
end

B.antikythera = block(C.antikythera)
B.frame = block(C.frame)
B.copper_stock = block(C.copper_stock)
B.furnace = block(C.furnace)
-- The lit furnace glows; Craft swaps it in while the fire burns.
B.furnace_lit = block({
    id = C.furnace.lit, name = C.furnace.name .. " (burning)", description = C.furnace.description,
    hardness = C.furnace.hardness, tags = C.furnace.tags,
}, { light_emit = C.furnace.light })

return B
