-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Glyphs (brief §7): a carved shape that means something. Craft keeps the
-- registry — one meaning a mask — and both trees read it, so every mask
-- this mod registers was checked against magic's (tools/glyphs.py).
--
-- A shape carved turned or mirrored is still the same shape, so each glyph
-- is registered in all its distinct orientations: the 48 symmetries of the
-- cube, of which a symmetric shape has fewer distinct images (a gnomon six,
-- a rod three). Masks are whole numbers and the turning is index arithmetic,
-- so nothing here is floating point.
--
-- Where the interface is loaded, each glyph is also a one-click preset in
-- the shape crafter, shown to a player once they know its node.

local C = tds.config
local U = tds.util

local G = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")
local ui = U.exports("tiamat_default_ui")

--- The 48 symmetries of the cube, each a function from a cell (x, y, z)
--- in 0..2 to its image: a permutation of the axes, then a mirror of any.
local SYMMETRIES = {}
do
    local perms = { { 1, 2, 3 }, { 1, 3, 2 }, { 2, 1, 3 }, { 2, 3, 1 }, { 3, 1, 2 }, { 3, 2, 1 } }
    for _, p in ipairs(perms) do
        for flips = 0, 7 do
            SYMMETRIES[#SYMMETRIES + 1] = { perm = p, flips = flips }
        end
    end
end

local function image(mask, s)
    local out = 0
    for index = 0, 26 do
        if mask & (1 << index) ~= 0 then
            local c = { index % 3, (index // 3) % 3, index // 9 }
            local d = { c[s.perm[1]], c[s.perm[2]], c[s.perm[3]] }
            for axis = 1, 3 do
                if s.flips & (1 << (axis - 1)) ~= 0 then d[axis] = 2 - d[axis] end
            end
            out = out | (1 << (d[1] + 3 * d[2] + 9 * d[3]))
        end
    end
    return out
end

--- Every distinct orientation of `mask`, smallest first.
function G.variants(mask)
    local seen, list = {}, {}
    for _, s in ipairs(SYMMETRIES) do
        local m = image(mask, s)
        if not seen[m] then
            seen[m] = true
            list[#list + 1] = m
        end
    end
    table.sort(list)
    return list
end

G.ids = {}          -- short id -> qualified glyph id
G.count = 0         -- masks registered

for _, glyph in ipairs(C.glyphs) do
    local id = U.id(glyph.id)
    G.ids[glyph.id] = id
    if craft then
        for _, mask in ipairs(G.variants(glyph.mask)) do
            local ok, why = craft.register_glyph(mask, id)
            if ok then
                G.count = G.count + 1
            else
                game.log("tiamat_default_science: Craft refused glyph " .. glyph.id .. ": " .. tostring(why))
            end
        end
    end
    if ui and ui.add_preset and glyph.preset then
        local node = glyph.node
        local ok, why = ui.add_preset{
            id = id, label = glyph.preset, mask = glyph.mask,
            visible = function(player) return progress ~= nil and progress.has(player, node) == true end,
        }
        if not ok then game.log("tiamat_default_science: the interface refused preset " .. glyph.id .. ": " .. tostring(why)) end
    end
end

--- The glyph (short id) a block is carved to, or nil: `at` is what
--- `game.get_block` answered, or a placement's occupancy as a number.
function G.of(at)
    if not craft or at == nil then return nil end
    local mask = type(at) == "number" and at or at.occupancy
    local id = craft.glyph_of(mask)
    for short, qualified in pairs(G.ids) do
        if qualified == id then return short end
    end
    return nil
end

return G
