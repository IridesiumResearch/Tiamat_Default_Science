-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Every item this mod registers, from the tables in `config.lua` (brief §9).
-- Each has a texture of its own name; `tools/make_textures.py` draws the
-- placeholders. An instrument works for whoever holds it: a science player
-- makes a compass, anyone may follow it, and trade across the Fork needs no
-- code.

local C = tds.config

local I = {}

I.ids = {}          -- short id -> numeric material id

local function register(spec)
    I.ids[spec.id] = game.register_item{
        id = spec.id,
        name = spec.name,
        description = spec.description,
        texture = "textures/" .. spec.id .. ".png",
    }
end

for _, list in ipairs({ C.bench_items, C.path_items, C.tier3_items }) do
    for _, spec in ipairs(list) do register(spec) end
end

-- A tool that digs is an engine tool of the same id as its item; Craft puts
-- it in the hand of whoever holds the item (`mechanica.lua`).
for _, spec in ipairs(C.tier3_items) do
    if spec.speeds then
        game.register_tool{ id = spec.id, name = spec.name, brush = "block", speeds = spec.speeds }
    end
end

return I
