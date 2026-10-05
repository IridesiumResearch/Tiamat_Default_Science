-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 6's devices that are not a frame's recipe (brief §5.4, §6.5):
--
--   the Tesla coil        while its network carries it (`grid.lua`): arcs leap to
--                         the creatures that hunt players, and jars and cells
--                         carried near it fill. Its lamps are the grid's.
--   wireless              `radio <words>`, said by a powered wireless set, is heard
--                         by everyone near every other powered set in the domain
--   the X-ray viewer      used, with a charged cell in the pack: the ore in the
--                         rock ahead glows, for the user alone
--   the earthquake        used on rock, with a charged cell: the column under it
--     machine             comes loose, as a charge's blast does
--   the diamond drill     a pick that draws a charge a block from a carried cell,
--                         and will not start a dig on a flat one
--   the aetherometer      used anywhere: which way the aether drifts, and how hard
--
-- Every reading is bounded: a viewer reads `ahead` × 5 × 5 blocks once, an
-- earthquake loosens at most `depth` × 3 × 3, and nothing scans on a tick.

local C = tds.config
local U = tds.util
local I = tds.items
local N = tds.networks
local Q = tds.grid
local E = tds.electricity
local T6 = tds.tier6
local CH = tds.charges

local life = U.exports("tiamat_default_life")

local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local CELL = I.ids.cell
local HOLDS = { [I.ids.leyden_jar] = C.electric.jar, [CELL] = C.grid.cell }
local PACK = { "player:hotbar", "player:main" }

local function holding(e, id)
    return e.held ~= nil and e.held.material == I.ids[id] and e.held.shape == nil
end

local function body_of(uuid)
    local id = game.player_entity(uuid)
    return id and game.entity(id)
end

local function block_pos(p, domain)
    return { x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z), domain = domain }
end

local function near(a, b, reach)
    return math.abs(a.x - b.x) <= reach and math.abs(a.y - b.y) <= reach and math.abs(a.z - b.z) <= reach
end

-- Charge carried ----------------------------------------------------------------------

local function rewrite(uuid, stack, e)
    if game.take(uuid, { material = stack.material, count = 1, detail = stack.detail }) < U.UNITS then return false end
    game.give(uuid, { material = stack.material, count = 1, detail = e > 0 and ("e=" .. e) or nil })
    return true
end

--- Takes `cost` charge from the first cell in a player's pack that holds as
--- much. Answers whether it was paid.
function T6.spend(uuid, cost)
    for _, view in ipairs(PACK) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            local e = stack.material == CELL and E.charge_of(stack) or 0
            if e >= cost then return rewrite(uuid, stack, e - cost) end
        end
    end
    return false
end

--- Whether a player carries a cell holding at least `cost`.
function T6.can_spend(uuid, cost)
    for _, view in ipairs(PACK) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            if stack.material == CELL and E.charge_of(stack) >= cost then return true end
        end
    end
    return false
end

--- Puts up to `amount` into the first jar or cell a player carries that is
--- not full. Answers what went in.
function T6.top_up(uuid, amount)
    for _, view in ipairs(PACK) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            local full = HOLDS[stack.material]
            if full and stack.units == U.UNITS * (stack.count or 1) then
                local e = E.charge_of(stack)
                if e < full then
                    local add = math.min(amount, full - e)
                    if rewrite(uuid, stack, e + add) then return add end
                end
            end
        end
    end
    return 0
end

-- The Tesla coil's arcs -------------------------------------------------------------------

local HOSTILE = {}
for _, kind in ipairs(C.tesla.hostile) do HOSTILE[kind] = true end

--- The kind of one of Life's creatures, as Life reads it: its model's name,
--- or else its nametag. Nil for anything else.
local function life_kind(ent)
    if not ent or ent.item then return nil end
    if ent.model then
        local short = string.match(ent.model, "^tiamat_default_life:(.+)$")
        if short then return (string.gsub(short, "_young$", "")) end
    end
    if ent.source == "tiamat_default_life" and ent.nametag then
        local short = string.gsub(ent.nametag, " %(young%)$", "")
        return (string.gsub(string.lower(short), " ", "_"))
    end
    return nil
end

T6.life_kind = life_kind
T6.HOSTILE = HOSTILE

local arcs = 0

local function top_of(coil)
    return { x = coil.x + 0.5, y = coil.y + 5, z = coil.z + 0.5, domain = coil.domain }
end

tds.on_tick(C.tesla.arc_every, function()
    if not life then return end
    for _, coil in ipairs(Q.live_coils()) do
        local top = top_of(coil)
        for _, id in ipairs(game.entities_in_radius(top, C.tesla.arc_reach, "tiamat_default_life") or {}) do
            local ent = game.entity(id)
            if HOSTILE[life_kind(ent) or ""] and life.set_alight(id, C.tesla.arc_ticks) then
                arcs = arcs + 1
                game.lightning{ from = top, to = { x = ent.pos.x, y = ent.pos.y + 1, z = ent.pos.z, domain = coil.domain },
                    seed = (game.world_seed or 0) + arcs, colour = { 0.7, 0.75, 1.0 }, width = 0.15, branches = 2,
                    ticks = 6, radius = 64 }
            end
        end
    end
end)

tds.on_tick(C.grid.period, function()
    local coils = Q.live_coils()
    if #coils == 0 then return end
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        local body = body_of(uuid)
        if body then
            local me = block_pos(body.pos, U.place(tds.domain_of[uuid]))
            for _, coil in ipairs(coils) do
                if coil.domain == me.domain and near(coil, me, C.tesla.charge_reach) then
                    T6.top_up(uuid, C.tesla.charge_rate)
                    local placer = U.placer(coil)
                    if placer then T6.toy(placer, "tesla") end
                    break
                end
            end
        end
    end
end)

-- Wireless -------------------------------------------------------------------------------

local function sets()
    local list = {}
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == "radio" then
            local pos = U.station_pos(name, "frame")
            if pos and Q.powered(pos) > 0 then list[#list + 1] = pos end
        end
    end
    return list
end

tds.on_chat("radio", function(player, words)
    if words == "" then return "Say 'radio' and your message, by a wireless set." end
    local body = body_of(player)
    if not body then return nil end
    local me = block_pos(body.pos, U.place(tds.domain_of[player]))
    local all = sets()
    local mine = nil
    for _, pos in ipairs(all) do
        if pos.domain == me.domain and near(pos, me, C.radio.reach) then mine = pos break end
    end
    if not mine then return "Stand by a wireless set with charge in it." end
    local told = {}
    for _, pos in ipairs(all) do
        if pos.domain == me.domain and not (pos.x == mine.x and pos.y == mine.y and pos.z == mine.z) then
            for _, uuid in ipairs(U.sorted_keys(tds.online)) do
                local b = uuid ~= player and not told[uuid] and body_of(uuid)
                if b and near(pos, block_pos(b.pos), C.radio.hear) then
                    game.chat_to(uuid, "(by wireless) " .. words)
                    told[uuid] = true
                end
            end
        end
    end
    T6.toy(player, "radio")
    return next(told) and "Sent." or "Sent, but no other set is listened to."
end)

-- The X-ray viewer -------------------------------------------------------------------------

--- The axis a facing points along most: { dx, dy, dz }, one of them ±1.
local function axis_of(f)
    local ax, ay, az = math.abs(f.x), math.abs(f.y), math.abs(f.z)
    if ay >= ax and ay >= az then return { 0, f.y < 0 and -1 or 1, 0 } end
    if ax >= az then return { f.x < 0 and -1 or 1, 0, 0 } end
    return { 0, 0, f.z < 0 and -1 or 1 }
end

--- The ore in a box `ahead` long and 5 × 5 across, in front of `pos`
--- along `axis`: a list of positions, nearest first.
function T6.xray(pos, axis, ahead, half)
    local found = {}
    for d = 1, ahead do
        for a = -half, half do
            for b = -half, half do
                local p
                if axis[1] ~= 0 then
                    p = { x = pos.x + axis[1] * d, y = pos.y + a, z = pos.z + b }
                elseif axis[2] ~= 0 then
                    p = { x = pos.x + a, y = pos.y + axis[2] * d, z = pos.z + b }
                else
                    p = { x = pos.x + a, y = pos.y + b, z = pos.z + axis[3] * d }
                end
                p.domain = pos.domain
                local at = game.get_block(p)
                if at and at.material and U.tagged(at.material, "ore") then found[#found + 1] = p end
            end
        end
    end
    return found
end

tds.on_use(function(e)
    if not holding(e, "xray_viewer") then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    if not T6.spend(e.player, C.xray.cost) then return "The tube is dark: carry a charged cell." end
    local eye = block_pos({ x = body.pos.x, y = body.pos.y + 1.6, z = body.pos.z }, U.place(e.domain))
    local found = T6.xray(eye, axis_of(body.facing), C.xray.ahead, C.xray.half)
    for _, p in ipairs(found) do
        game.emit_particles{ pos = { x = p.x + 0.5, y = p.y + 0.5, z = p.z + 0.5, domain = p.domain },
            count = 3, colour = { r = 0.55, g = 1.0, b = 0.6 }, size = 0.25, lifetime = C.xray.seconds,
            spread = 0.05, gravity = 0, collide = false, radius = 32, player = e.player }
    end
    if #found == 0 then return "Only rock, all the way through." end
    T6.toy(e.player, "xray")
    return string.format("Ore glows through the rock: %d blocks of it.", #found)
end)

-- The earthquake machine ---------------------------------------------------------------------

tds.on_use(function(e)
    if not (e.x and holding(e, "oscillator")) then return nil end
    if game.world_option(game.mod_id .. ":blasting") == false then return "Blasting is off in this world." end
    if not CH.loosens(e.material, true) then return "It shakes only rock." end
    if not T6.spend(e.player, C.oscillator.cost) then return "The oscillator needs a charged cell." end
    local top = U.block_of(e)
    local loose = 0
    for dy = 0, C.oscillator.depth - 1 do
        for dx = -C.oscillator.half, C.oscillator.half do
            for dz = -C.oscillator.half, C.oscillator.half do
                if CH.loosen({ x = top.x + dx, y = top.y - dy, z = top.z + dz, domain = top.domain }, true) then
                    loose = loose + 1
                end
            end
        end
    end
    T6.toy(e.player, "quake")
    return string.format("The ground hums, and shudders: %d blocks shaken loose.", loose)
end)

-- The diamond drill ------------------------------------------------------------------------------

local DRILL = I.ids.diamond_drill

local drilling = {}         -- player -> true while a dig they began with the drill runs

-- Asked as a dig begins, with the drill in hand: and remembered, because by
-- the time the block comes off Craft has worn the drill and rewritten its stack.
tds.on_dig_start(function(e)
    local held = game.held(e.player)
    drilling[e.player] = nil
    if held and held.material == DRILL then
        if not T6.can_spend(e.player, C.drill.cost) then return "The drill's cell is flat." end
        drilling[e.player] = true
    end
    return nil
end)

tds.on_dig(function(e)
    if e.player and drilling[e.player] then
        drilling[e.player] = nil
        T6.spend(e.player, C.drill.cost)
    end
end)

tds.on_leave(function(e) drilling[e.player] = nil end)

-- The aetherometer ------------------------------------------------------------------------------

local WAYS = { "north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west" }

--- Which way the aether drifts in this world, and how hard at `y`: the
--- world's own, from its seed, stronger the higher one stands.
function T6.aether(y)
    local seed = game.world_seed or 0
    local way = WAYS[seed % #WAYS + 1]
    local strength = y < 0 and "faintly" or (y < 96 and "steadily" or "strongly")
    return way, strength
end

tds.on_use(function(e)
    if not holding(e, "aetherometer") then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local way, strength = T6.aether(math.floor(body.pos.y))
    T6.toy(e.player, "aether")
    return string.format("The needle trembles: the aether drifts %s, %s.", way, strength)
end)

return T6
