-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The blocks this mod registers (brief §8). There will be ten, and each is
-- a block only because it must be one; every machine, network and structure
-- beyond them is carved from the world's blocks, Craft's plank and glass,
-- and this mod's three stocks. So far there is the door: Progress's door
-- must be a block a player uses.

local C = tds.config

local B = {}

local door = C.antikythera
B.antikythera = game.register_block{
    id = door.id,
    name = door.name,
    description = door.description,
    hardness = door.hardness,
    tags = door.tags,
    textures = { all = "textures/" .. door.id .. ".png" },
}

return B
