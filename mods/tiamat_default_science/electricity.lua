-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Charge, its first form (brief §5.2, §6.5): the Leyden jar and what fills
-- one. A jar carries its charge in its own detail, `e=<0..100>`, so a charged
-- jar is a particular thing — it never stacks with an empty one, and it is
-- never a recipe's ingredient. An empty jar has no detail at all.
--
-- What fills one, at tier 4:
--
--   the friction globe   a movement: a turning frame charges the jars in its inputs
--   the lightning rod    a copper rod open to the sky; a bolt within reach fills the
--                        jars in every frame its copper reaches, and puts out the fires
--   Franklin's kite      a kite flown in a storm fills the jar in the off-hand
--
-- And a charged jar, used, empties itself in a spark: Franklin's party trick.
-- Wires that carry charge to machines are tier 5 (the pile), not here.

local C = tds.config
local U = tds.util
local A = tds.apprentice
local N = tds.networks
local G = tds.glyphs
local B = tds.blocks
local T4 = tds.tier4
local I = tds.items

local E = {}

local weather = U.exports("tiamat_weather")
local progress = U.exports("tiamat_default_progress")

local JAR = I.ids.leyden_jar
local FULL = C.electric.jar

local CELL = I.ids.cell

-- What each kind of charged thing holds at most.
local HOLDS = { [JAR] = FULL, [CELL] = C.grid.cell }

--- The charge a stack carries: 0 for an empty jar or cell, or anything else.
function E.charge_of(stack)
    if not (stack and HOLDS[stack.material] and stack.detail) then return 0 end
    return math.tointeger(tonumber(string.match(stack.detail, "e=(%d+)") or "0")) or 0
end

local function detail(e) return "e=" .. e end

local function free_slot(stacks, from, to)
    local used = {}
    for _, s in ipairs(stacks) do used[s.slot] = true end
    for slot = from, to do
        if not used[slot] then return slot end
    end
    return nil
end

local function rewrite(name, stack, e)
    if game.container_take(name, { material = stack.material, count = 1, slot = stack.slot, detail = stack.detail }) < U.UNITS then
        return false
    end
    game.container_give(name, { material = stack.material, count = 1, slot = stack.slot, detail = e > 0 and detail(e) or nil })
    return true
end

--- Puts up to `amount` charge into the jars (or, with `material`, the cells)
--- in `slots` of a container, the first first. A pile of empty ones gives up
--- one to be charged, which goes to a free slot among `spare_from..spare_to`.
--- Answers what was added.
function E.fill_container(name, slots, amount, spare_from, spare_to, material)
    material = material or JAR
    local full = HOLDS[material]
    local added = 0
    for _, stack in ipairs(game.container(name) or {}) do
        if added >= amount then break end
        local in_range = false
        for _, s in ipairs(slots) do if s == stack.slot then in_range = true end end
        if in_range and stack.material == material then
            local e = E.charge_of(stack)
            if e < full then
                local give = math.min(full - e, amount - added)
                if stack.units > U.UNITS then
                    -- Several empty ones: charge one of them, beside the rest.
                    local spare = free_slot(game.container(name), spare_from, spare_to)
                    if spare and game.container_take(name, { material = material, count = 1, slot = stack.slot }) >= U.UNITS then
                        game.container_give(name, { material = material, count = 1, slot = spare, detail = detail(give) })
                        added = added + give
                    end
                elseif rewrite(name, stack, e + give) then
                    added = added + give
                end
            end
        end
    end
    return added
end

--- Takes up to `amount` charge out of the cells in `slots` of a container.
--- Answers what was taken.
function E.drain_container(name, slots, amount)
    local taken = 0
    for _, stack in ipairs(game.container(name) or {}) do
        if taken >= amount then break end
        local in_range = false
        for _, s in ipairs(slots) do if s == stack.slot then in_range = true end end
        if in_range and stack.material == CELL then
            local e = E.charge_of(stack)
            local take = math.min(e, amount - taken)
            if take > 0 and rewrite(name, stack, e - take) then taken = taken + take end
        end
    end
    return taken
end

local INPUTS = { 2, 3, 4, 5 }

-- The friction globe ---------------------------------------------------------------------
--
-- It makes nothing Craft could name, so this file works it, as `frame.lua`
-- works the pump: every `period`, at the frame's speed.

local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local rubbed = {}           -- frame container -> ticks of work toward the next charge

tds.on_tick(C.movements.friction_globe.period, function()
    local period = C.movements.friction_globe.period
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == "friction_globe" then
            local pos = U.station_pos(name, "frame")
            local speed = pos and game.get_block(pos) and N.speed(pos, U.placer(pos)) or 0
            local work = (rubbed[name] or 0) + period * speed // 100
            if work >= period then
                work = work - period
                E.fill_container(name, INPUTS, C.electric.static, 6, 9)
            end
            rubbed[name] = work
        else
            rubbed[name] = nil
        end
    end
end)

-- The lightning rod ---------------------------------------------------------------------
--
-- A rod is a carved copper rod (copper stock, the `rod` glyph) with the sky
-- open over it. Rods are remembered where they are placed (`rod:<key>` = who
-- placed it) and checked again when a bolt comes; a rod dug or built over is
-- forgotten then.

local function rod_key(pos) return "rod:" .. U.key(pos) end

local function is_rod(at)
    return at ~= nil and at.material == B.copper_stock and G.of(at) == "rod"
end

tds.on_place(function(e)
    if e.material == B.copper_stock and G.of(e.occupancy) == "rod" then
        game.storage.set(rod_key({ x = e.x, y = e.y, z = e.z, domain = U.where(e) }), e.player)
    end
end)

--- The frames a rod's copper reaches: a flood through copper stock, any
--- carving of it, bounded at `rod_wire` blocks.
function E.wired_frames(pos)
    local frames, seen, queue, head = {}, { [U.key(pos)] = true }, { pos }, 1
    while queue[head] and head <= C.electric.rod_wire do
        local here = queue[head]
        head = head + 1
        for _, side in ipairs(U.neighbours(here)) do
            local k = U.key(side)
            if not seen[k] then
                seen[k] = true
                local at = game.get_block(side)
                if at and at.material == B.frame then
                    frames[#frames + 1] = side
                elseif at and at.material == B.copper_stock then
                    queue[#queue + 1] = side
                end
            end
        end
    end
    return frames
end

--- A bolt struck at `(x, y, z)`: every rod within reach that still stands
--- under the open sky catches it.
function E.strike(x, y, z)
    for _, key in ipairs(game.storage.keys("rod:")) do
        local placer = game.storage.get(key)
        local rx, ry, rz, domain = string.match(key, "^rod:(-?%d+),(-?%d+),(-?%d+),(.*)$")
        local pos = rx and { x = math.tointeger(tonumber(rx)), y = math.tointeger(tonumber(ry)),
            z = math.tointeger(tonumber(rz)), domain = U.place(domain) }
        if pos and pos.domain == nil and math.abs(pos.x - x) <= C.electric.rod_reach
            and math.abs(pos.z - z) <= C.electric.rod_reach then
            local at = game.get_block(pos)
            if at and not is_rod(at) then
                game.storage.set(key, nil)
            elseif at and game.get_light{ x = pos.x, y = pos.y + 1, z = pos.z }.sun >= 15
                and progress and progress.has(placer, "science.lightning_rod") then
                local left = C.electric.lightning
                for _, frame in ipairs(E.wired_frames(pos)) do
                    if left <= 0 then break end
                    left = left - E.fill_container(U.station_name("frame", frame), { 2, 3, 4, 5, 6, 7, 8, 9 }, left, 6, 9)
                end
                if weather and weather.fires_near then
                    for _, fire in ipairs(weather.fires_near(pos.x, pos.y, pos.z, C.electric.rod_fires) or {}) do
                        weather.extinguish(fire.x, fire.y, fire.z)
                    end
                end
                T4.toy(placer, "lightning")
                game.emit_particles{ pos = { x = pos.x + 0.5, y = pos.y + 1, z = pos.z + 0.5 }, count = 30,
                    colour = { r = 0.7, g = 0.8, b = 1.0 }, size = 0.12, lifetime = 0.8, spread = 3, gravity = 0,
                    collide = false, radius = 96 }
            end
        end
    end
end

if weather and weather.on_lightning then
    weather.on_lightning(function(x, y, z) E.strike(x, y, z) end)
end

-- Franklin's kite -----------------------------------------------------------------------

local OFF_HAND = 28

--- A kite flying over `uuid`: in a storm, with Franklin's node, the jar in
--- the off-hand fills a little. Called by the kite's own tick (`instruments.lua`).
function E.kite(uuid, pos)
    if not (weather and weather.weather_at and progress and progress.has(uuid, "science.franklins_kite")) then return end
    local kind = weather.weather_at(math.floor(pos.x), math.floor(pos.y), math.floor(pos.z))
    if kind ~= "storm" then return end
    local stack = game.slot(uuid, "player:main", OFF_HAND)
    if not (stack and stack.material == JAR and stack.units == U.UNITS) then return end
    local e = E.charge_of(stack)
    if e >= FULL then return end
    if game.take(uuid, { material = JAR, count = 1, slot = OFF_HAND, detail = stack.detail }) >= U.UNITS then
        local now = math.min(FULL, e + C.electric.franklin)
        game.give(uuid, { material = JAR, count = 1, slot = OFF_HAND, detail = detail(now) })
        if now >= FULL then T4.toy(uuid, "franklin") end
    end
end

-- A spark ---------------------------------------------------------------------------------

tds.on_use(function(e)
    if not (e.held and e.held.material == JAR) then return nil end
    local charge = E.charge_of(e.held)
    if charge <= 0 then return "The jar is empty." end
    if game.take(e.player, { material = JAR, count = 1, detail = e.held.detail }) < U.UNITS then return nil end
    game.give(e.player, { material = JAR, count = 1 })
    local id = game.player_entity(e.player)
    local body = id and game.entity(id)
    if body then
        game.emit_particles{ pos = { x = body.pos.x, y = body.pos.y + 1.2, z = body.pos.z, domain = U.place(e.domain) },
            count = 12 + charge // 10, colour = { r = 0.6, g = 0.75, b = 1.0 }, size = 0.06, lifetime = 0.4,
            spread = 3, gravity = 0, collide = false, radius = 24 }
    end
    T4.toy(e.player, "spark")
    return string.format("Crack! A blue spark leaps from the jar (%d charge).", charge)
end)

return E
