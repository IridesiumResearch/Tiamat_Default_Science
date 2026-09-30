-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Mining charges (brief §5.1, Black Powder): a charge used on rock is set,
-- and after a short fuse the rock round it — three blocks by three by three
-- — comes loose into drops. Rock only: stone and ore the world generated,
-- and Craft's cracked rock, never anything `hard`, never a block a player
-- built with (a station, a furnace, a chest), and never a creature: the
-- charge hurts no one.
--
-- The world option `blasting` turns it off, and then a charge is an item to
-- study and nothing more.

local C = tds.config
local U = tds.util
local I = tds.items

local CH = {}

local life = U.exports("tiamat_default_life")

local CHARGE = I.ids.mining_charge
local ALLOWED = { ["tiamat_default_world"] = true }

local pending = {}          -- charges set and burning: { pos, at }

--- Whether a block may be blasted loose: the world's own rock, or Craft's
--- rock cracked by fire, and never anything hard.
function CH.loosens(material)
    local id = material and game.block_of(material)
    if not id then return false end
    local mod, name = string.match(id, "^([^:]+):(.+)$")
    local rock = ALLOWED[mod] or (mod == "tiamat_default_craft" and string.sub(name, 1, 8) == "cracked_")
    if not rock then return false end
    if U.tagged(material, "hard") then return false end
    return U.tagged(material, "stone") or U.tagged(material, "ore") or U.tagged(material, "cracked")
end

local function drop(pos, material, units)
    local at = { x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5 }
    if life and life.drop then
        life.drop(at, { material = material, units = units })
    else
        game.spawn_entity{ pos = at, item = { material = material, units = units },
            collider = { width = 0.5, height = 0.5 } }
    end
end

local function cells(occupancy)
    local n = 0
    while occupancy ~= 0 do
        n = n + (occupancy & 1)
        occupancy = occupancy >> 1
    end
    return n
end

--- The charge at `pos` goes off: every block it may loosen within the
--- radius comes loose, whole.
function CH.blast(pos)
    local r = C.charge.radius
    for dy = r, -r, -1 do
        for dx = -r, r do
            for dz = -r, r do
                local at_pos = { x = pos.x + dx, y = pos.y + dy, z = pos.z + dz, domain = pos.domain }
                local at = game.get_block(at_pos)
                if at and at.material and at.cells == nil and CH.loosens(at.material) then
                    local units = cells(at.occupancy)
                    if units > 0 and game.set_block(at_pos, "engine:air") then
                        drop(at_pos, at.material, units)
                    end
                end
            end
        end
    end
    game.emit_particles{ pos = { x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5, domain = pos.domain },
        count = 40, colour = { r = 0.55, g = 0.5, b = 0.45 }, size = 0.3, lifetime = 1.5,
        spread = 4, area = { x = 1, y = 1, z = 1 }, gravity = 2, collide = true, radius = 64 }
end

tds.on_use(function(e)
    if not (e.x and e.held and e.held.material == CHARGE) then return nil end
    if game.world_option(game.mod_id .. ":blasting") == false then
        return "Blasting is off in this world."
    end
    local pos = U.block_of(e)
    if not CH.loosens(e.material) then return "A charge only loosens rock." end
    if game.take(e.player, { material = CHARGE, count = 1 }) < U.UNITS then return nil end
    pending[#pending + 1] = { pos = pos, at = tds.now() + C.charge.fuse }
    return "The fuse is lit. Stand back!"
end)

tds.on_tick(1, function(now)
    local i = 1
    while i <= #pending do
        if pending[i].at <= now then
            CH.blast(table.remove(pending, i).pos)
        else
            i = i + 1
        end
    end
end)

return CH
