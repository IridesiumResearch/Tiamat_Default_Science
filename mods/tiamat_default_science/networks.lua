-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The turning network (brief §6.2): how turning gets from a water wheel, a
-- windmill or a crank to the frames that use it.
--
-- A network is the blocks that touch, face to face: carved plank parts that
-- carry turning (rods for shafts, gears, wheels), and the frames and
-- furnaces they reach. It is found by a flood fill bounded at
-- `max_blocks`, and kept in memory until any block of a kind that could
-- belong to one is placed or dug — then every network is found again, the
-- next time something asks. That is a departure from the brief's stored
-- networks (§15, rule 2), taken because the world is already the record:
-- finding one again reads each member once, a restart costs one flood per
-- network, and there is no second copy to fall out of step.
--
-- Turning is never stored: a millrace stops, the mill stops. A network's
-- supply is summed from its sources and kept `refresh` ticks, and it is
-- shared among the frames on it by what each movement needs.

local C = tds.config
local U = tds.util
local G = tds.glyphs
local B = tds.blocks

local N = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")
local weather = U.exports("tiamat_weather")

local PARTS = {}
for _, glyph in ipairs(C.network.parts) do PARTS[glyph] = true end

local plank = {}            -- numeric material -> is a plank, answered once each
local function is_plank(material)
    if material == nil then return false end
    local known = plank[material]
    if known ~= nil then return known end
    local id = game.block_of(material)
    known = id ~= nil and craft ~= nil and craft.in_group("#plank", id) == true
    plank[material] = known
    return known
end

--- What a block is to a network: `"frame"`, `"furnace"`, the part's glyph
--- (`"rod"`, `"gear"`, `"wheel"`), or nil. `at` is `game.get_block`'s answer.
function N.kind(at)
    if at == nil or at.material == nil then return nil end
    local m = at.material
    if m == B.frame then return "frame" end
    if m == B.furnace or m == B.furnace_lit then return "furnace" end
    if is_plank(m) then
        local glyph = G.of(at)
        if glyph and PARTS[glyph] then return glyph end
    end
    return nil
end

-- The cache ----------------------------------------------------------------------

local networks = {}         -- position key -> its network

--- Forgets every network: something that could belong to one changed.
function N.forget()
    networks = {}
end

local function could_belong(material)
    return material == B.frame or material == B.furnace or material == B.furnace_lit or is_plank(material)
end

tds.on_place(function(e)
    if could_belong(e.material) then N.forget() end
end)
tds.on_dig(function(e)
    if could_belong(e.material) then N.forget() end
end)

--- The network the block at `pos` belongs to, found now if it is not known.
--- A block that belongs to none (or is not loaded) answers nil.
function N.at(pos)
    local key = U.key(pos)
    local net = networks[key]
    if net then return net end
    local first = N.kind(game.get_block(pos))
    if not first then return nil end
    net = { frames = {}, furnaces = {}, wheels = {}, parts = 0, size = 0 }
    local seen = { [key] = true }
    local queue = { { pos = pos, kind = first } }
    local head = 1
    while queue[head] and net.size < C.network.max_blocks do
        local item = queue[head]
        head = head + 1
        net.size = net.size + 1
        networks[U.key(item.pos)] = net
        if item.kind == "frame" then
            net.frames[#net.frames + 1] = item.pos
        elseif item.kind == "furnace" then
            net.furnaces[#net.furnaces + 1] = item.pos
        else
            net.parts = net.parts + 1
            if item.kind == "wheel" then net.wheels[#net.wheels + 1] = item.pos end
        end
        for _, next in ipairs(U.neighbours(item.pos)) do
            local k = U.key(next)
            if not seen[k] then
                seen[k] = true
                local kind = N.kind(game.get_block(next))
                if kind then queue[#queue + 1] = { pos = next, kind = kind } end
            end
        end
    end
    return net
end

-- Sources --------------------------------------------------------------------------

local cranked = {}          -- frame key -> the tick its crank stops

--- A turn of the crank at the frame at `pos`: turning for a few seconds.
function N.crank(pos)
    cranked[U.key(pos)] = tds.now() + C.sources.crank_ticks
end

--- The wind over `pos`, 0..1: Weather's where it blows, else still air.
local function wind(pos)
    if weather and weather.wind and pos.domain == nil then
        local x, _, strength = weather.wind(pos.x, pos.z)
        if x ~= nil then return strength end
    end
    return C.sources.still_air / 100
end

local function wetted_sides(pos)
    local n = 0
    for _, side in ipairs(U.neighbours(pos)) do
        local f = game.get_fluid(side)
        if f and not f.empty and f.volume > 0 then n = n + 1 end
    end
    return n
end

local function sails(pos)
    local n = 0
    for _, side in ipairs({
        { x = pos.x + 1, y = pos.y, z = pos.z, domain = pos.domain },
        { x = pos.x - 1, y = pos.y, z = pos.z, domain = pos.domain },
        { x = pos.x, y = pos.y, z = pos.z + 1, domain = pos.domain },
        { x = pos.x, y = pos.y, z = pos.z - 1, domain = pos.domain },
    }) do
        local at = game.get_block(side)
        if at and is_plank(at.material) and G.of(at) == "plate" then n = n + 1 end
    end
    return n
end

--- What one wheel gives, in turns: a water wheel if water touches it,
--- else a windmill if it has sails and stands high enough, else nothing.
function N.wheel(pos)
    local S = C.sources
    local wet = wetted_sides(pos)
    if wet > 0 then return math.min(wet, S.water_sides) * S.water_per_side end
    if sails(pos) < S.wind_sails then return 0 end
    local ground = game.surface_at{ x = pos.x, z = pos.z, from = pos.y - 1, depth = 256, skip_passable = true,
        domain = pos.domain }
    if not ground then return 0 end
    local height = pos.y - ground.y
    if height < S.wind_height then return 0 end
    local base = math.min(S.wind_base + height // S.wind_per, S.wind_cap)
    return math.floor(base * 2 * wind(pos))
end

--- What a network turns now, kept `refresh` ticks.
function N.supply(net)
    local now = tds.now()
    if net.supply_at and now - net.supply_at < C.network.refresh then return net.supply end
    local s = 0
    for _, pos in ipairs(net.frames) do
        local until_tick = cranked[U.key(pos)]
        if until_tick and until_tick > now then s = s + C.sources.crank end
    end
    for _, pos in ipairs(net.wheels) do s = s + N.wheel(pos) end
    if net.parts > C.network.wood_run then s = 0 end
    s = math.min(s, C.network.wood_capacity)
    net.supply, net.supply_at = s, now
    return s
end

-- Demand ---------------------------------------------------------------------------

--- The movement in a frame's tool slot, by short id, or nil.
function N.movement(name)
    for _, stack in ipairs(game.container(name) or {}) do
        if stack.slot == 1 then
            local id = game.block_of(stack.material)
            local short = id and string.match(id, "^" .. game.mod_id .. ":(.+)$")
            if short and C.movements[short] then return short end
        end
    end
    return nil
end

--- What the frames on a network need, in turns.
function N.demand(net)
    local d = 0
    for _, pos in ipairs(net.frames) do
        local m = N.movement(U.station_name("frame", pos))
        if m then d = d + C.movements[m].need end
    end
    return d
end

--- A frame's speed in per cent: its share of its network's turning, and
--- faster by its placer's machine speed (the pendulum's effect).
function N.speed(pos, placer)
    local net = N.at(pos)
    if not net then return 0 end
    local supply, demand = N.supply(net), N.demand(net)
    if supply <= 0 or demand <= 0 then return 0 end
    local speed = math.min(100, supply * 100 // demand)
    if placer and progress then
        local fx = progress.effects_of(placer, "science.") or {}
        speed = speed * (100 + (fx["science.machine_speed_percent"] or 0)) // 100
    end
    return speed
end

return N
