-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The machine frame (brief §6.1): one block, one Craft station, and what it
-- is depends on the movement in its tool slot — a clockmaker's word, the
-- works inside the case.
--
-- Craft runs it (`runs`, sibling ask C-S1): once a second it asks this file
-- how fast the frame turns, and keeps the job, chooses the recipe and makes
-- it itself, as the frame's placer, from the frame's own slots. The recipe
-- is chosen by the movement: every frame recipe names its movement as a
-- tool, so only one movement's recipes are possible in any frame, and Craft
-- makes the most particular of those. This file writes no job loop.
--
-- A frame turns by its network's turning (`networks.lua`), or by a player's
-- hand: a crank handle held and used on it turns it for two seconds.

local C = tds.config
local U = tds.util
local N = tds.networks
local A = tds.apprentice
local I = tds.items
local B = tds.blocks

local F = {}

local craft = U.exports("tiamat_default_craft")

local function placer_key(pos) return "placer:" .. U.key(pos) end

--- Who placed the frame at `pos`, or nil (a frame a plan stamped).
F.placer = U.placer

tds.on_place(function(e)
    if e.material == B.frame then
        game.storage.set(placer_key({ x = e.x, y = e.y, z = e.z, domain = U.place(tds.domain_of[e.player]) }), e.player)
    end
end)

tds.on_dig(function(e)
    if e.material == B.frame and e.brush == "block" then
        local pos = { x = e.x // 3, y = e.y // 3, z = e.z // 3, domain = U.place(tds.domain_of[e.player]) }
        game.storage.set(placer_key(pos), nil)
    end
end)

if craft then
    local ok, why = craft.register_station{
        id = U.id("frame"),
        name = C.frame.name,
        slots = { tool = 1, input = { from = 2, to = 5 }, output = { from = 6, to = 9 } },
        block = U.id(C.frame.id),
        runs = function(name)
            local pos = U.station_pos(name, "frame")
            local movement = N.movement(name)
            -- An engine gives turning and makes nothing: it does not run.
            if not pos or not movement or C.movements[movement].need == 0 then return 0 end
            if movement == "resonator" and not tds.grid.coil_near(pos, C.resonator.coil_reach) then return 0 end
            if C.movements[movement].power == "charge" then return tds.grid.speed(pos, F.placer(pos)) end
            return N.speed(pos, F.placer(pos))
        end,
    }
    if not ok then game.log("tiamat_default_science: Craft refused the frame: " .. tostring(why)) end
end

-- The crank: a frame turned by hand ---------------------------------------------------

local HANDLE = I.ids.crank_handle

-- Asked before Craft opens the frame's box: with a crank handle in hand, a
-- use is a turn of the crank; with anything else, the box opens as ever.
tds.on_use_at({ U.id(C.frame.id) }, function(e)
    if not (e.held and e.held.material == HANDLE) then return nil end
    local pos = U.block_of(e)
    N.crank(pos)
    game.emit_particles{
        pos = { x = pos.x + 0.5, y = pos.y + 1.05, z = pos.z + 0.5, domain = pos.domain },
        count = 6, colour = { r = 0.6, g = 0.45, b = 0.3 }, size = 0.08, lifetime = 0.6,
        velocity = { y = 1 }, spread = 1, gravity = 4, collide = true, radius = 24,
    }
    return ""
end)

-- The pump: water lifted from under a frame to over it --------------------------------

local FLUIDS = { "tiamat_default_world:water", "tiamat_weather:rainwater" }
local fluid_name = nil      -- numeric fluid -> its name, built when first asked

local function name_of_fluid(id)
    if not fluid_name then
        fluid_name = {}
        for _, name in ipairs(FLUIDS) do
            local ok, n = pcall(game.fluid_id, name)
            if ok and n then fluid_name[n] = name end
        end
    end
    return fluid_name[id]
end

--- Lifts up to a block of water from under `pos` to over it, conserved:
--- what leaves below arrives above, no more. Answers the cells moved.
function F.lift(pos)
    local below = { x = pos.x, y = pos.y - 1, z = pos.z, domain = pos.domain }
    local above = { x = pos.x, y = pos.y + 1, z = pos.z, domain = pos.domain }
    local from, to = game.get_fluid(below), game.get_fluid(above)
    if not from or from.empty or from.volume <= 0 then return 0 end
    local name = name_of_fluid(from.fluid)
    if not name or not to or (not to.empty and to.fluid ~= from.fluid) then return 0 end
    local room = 27 - (to.empty and 0 or to.volume)
    local moved = math.min(from.volume, room)
    if moved <= 0 then return 0 end
    game.set_fluid(below, { fluid = name, volume = from.volume - moved })
    game.set_fluid(above, { fluid = name, volume = (to.empty and 0 or to.volume) + moved })
    return moved
end

-- A pump makes nothing, so it is no Craft recipe (a recipe takes something):
-- this file works it, frame by frame, at the speed Craft is told.
local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local pumped = {}           -- frame container -> ticks of work toward the next lift

tds.on_tick(C.movements.pump.period, function()
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == "pump" then
            local pos = U.station_pos(name, "frame")
            local placer = pos and F.placer(pos)
            local speed = pos and game.get_block(pos) and N.speed(pos, placer) or 0
            local work = (pumped[name] or 0) + C.movements.pump.period * speed // 100
            if work >= C.movements.pump.period then
                work = work - C.movements.pump.period
                if F.lift(pos) > 0 and placer then A.discover(placer, A.WATER) end
            end
            pumped[name] = work
        else
            pumped[name] = nil
        end
    end
end)

return F
