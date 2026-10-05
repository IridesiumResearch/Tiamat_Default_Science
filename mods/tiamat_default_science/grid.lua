-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The charge network (brief §6.2): what copper wire carries.
--
-- A charge network is the blocks that touch, face to face: copper stock in
-- any carving (a rod is wire, a coil is a coil, a pipe or a plate is copper
-- all the same), and the frames and arc lamps it reaches. Like the turning
-- network it is found by a bounded flood fill when asked and forgotten when
-- copper, a frame or a lamp is placed or dug.
--
-- Once a second (`period`) every network is reckoned:
--
--   supply   a voltaic pile in a frame (while it has oil of vitriol to drink),
--            a dynamo (as much as its share of turning lets it), and a radium
--            or aether cell (for ever)
--   loss     a unit a second for every `loss_per` blocks of wire, less by the
--            line-loss effects of the tiers to come (`science.line_loss_percent`)
--   demand   motors, electric movements (electrolysis, the telegraph), lamps,
--            less by the induction motor's and the incandescent lamp's effects
--
-- Tier 6 adds two things a network does at a distance. A **Tesla coil** is a
-- frame with the coil's base movement under three copper coils and a steel
-- ring; while its network carries it, lamps near it light with no wire
-- (`electric_age.lua` throws its arcs). **Wardenclyffe** is a Tesla coil
-- built tall — a column of anything over the ring crowned with copper, and a
-- root of copper under the frame — for a placer who knows it: what its
-- network has to spare is shared by every receiver frame in the domain, with
-- nothing lost on the way.
--
-- What is left over fills the cells in the network's frames; what is short is
-- drawn from them; and what still is short slows everything on the network
-- alike. Each frame's share is kept as `powered`, a per cent, which a motor
-- turns into turning and an electric movement into speed. Charge is not
-- stored anywhere else: a network with no cells and no supply is dark.

local C = tds.config
local U = tds.util
local B = tds.blocks
local N = tds.networks
local E = tds.electricity
local I = tds.items

local G = tds.glyphs

local Q = {}

local progress = U.exports("tiamat_default_progress")

local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local ALL_SLOTS = { 2, 3, 4, 5, 6, 7, 8, 9 }
local ACID = U.material(U.id("oil_of_vitriol"))

--- What a block is to a charge network: "wire", "frame", "lamp", or nil.
function Q.kind(at)
    if at == nil or at.material == nil then return nil end
    if at.material == B.copper_stock then return "wire" end
    if at.material == B.frame then return "frame" end
    if at.material == B.lamp or at.material == B.lamp_lit then return "lamp" end
    return nil
end

local networks = {}          -- position key -> its network

function Q.forget() networks = {} end

local function could_belong(material)
    return material == B.copper_stock or material == B.frame or material == B.lamp or material == B.lamp_lit
end

local function lamp_key(pos) return "lamp:" .. U.key(pos) end

tds.on_place(function(e)
    if could_belong(e.material) then Q.forget() end
    if e.material == B.lamp then
        game.storage.set(lamp_key({ x = e.x, y = e.y, z = e.z, domain = U.place(tds.domain_of[e.player]) }), e.player)
    end
end)
tds.on_dig(function(e)
    if could_belong(e.material) then Q.forget() end
end)

--- The charge network a block belongs to, found now if it is not known.
function Q.at(pos)
    local key = U.key(pos)
    local net = networks[key]
    if net then return net end
    local first = Q.kind(game.get_block(pos))
    if not first then return nil end
    net = { frames = {}, lamps = {}, wires = 0, size = 0, powered = 0 }
    local seen = { [key] = true }
    local queue = { { pos = pos, kind = first } }
    local head = 1
    while queue[head] and net.size < C.grid.max_blocks do
        local item = queue[head]
        head = head + 1
        net.size = net.size + 1
        networks[U.key(item.pos)] = net
        if item.kind == "frame" then
            net.frames[#net.frames + 1] = item.pos
        elseif item.kind == "lamp" then
            net.lamps[#net.lamps + 1] = item.pos
        else
            net.wires = net.wires + 1
        end
        -- Wire reaches anything; a frame or a lamp reaches only wire, so two
        -- frames side by side are not wired by touching.
        for _, next in ipairs(U.neighbours(item.pos)) do
            local k = U.key(next)
            if not seen[k] then
                local kind = Q.kind(game.get_block(next))
                if kind and (item.kind == "wire" or kind == "wire") then
                    seen[k] = true
                    queue[#queue + 1] = { pos = next, kind = kind }
                end
            end
        end
    end
    return net
end

-- The reckoning --------------------------------------------------------------------

local powered = {}           -- frame key -> its share of charge, per cent
local drunk = {}             -- pile frame container -> ticks since it last drank

--- A frame's share of its network's charge, per cent, as last reckoned.
function Q.powered(pos)
    return powered[U.key(pos)] or 0
end

--- What a motor at `pos` turns, from the charge it was given.
function Q.motor_turns(pos)
    return C.grid.motor * Q.powered(pos) // 100
end

--- An electric frame's speed, per cent, faster by its placer's machine speed.
function Q.speed(pos, placer)
    local speed = Q.powered(pos)
    if speed > 0 and placer and progress then
        local fx = progress.effects_of(placer, "science.") or {}
        speed = speed * (100 + (fx["science.machine_speed_percent"] or 0)) // 100
    end
    return speed
end

-- The Tesla coil and the tower ----------------------------------------------------------

local function glyph_at(pos, material, glyph)
    local at = game.get_block(pos)
    return at ~= nil and at.material == material and G.of(at) == glyph
end

local function up(pos, dy) return { x = pos.x, y = pos.y + dy, z = pos.z, domain = pos.domain } end

--- Whether the frame at `pos` is a Tesla coil: its base movement, three
--- copper coils stacked on it, and a steel ring on top.
function Q.is_coil(pos)
    if N.movement(U.station_name("frame", pos)) ~= "tesla_coil" then return false end
    for dy = 1, 3 do
        if not glyph_at(up(pos, dy), B.copper_stock, "coil") then return false end
    end
    return glyph_at(up(pos, 4), B.steel_stock, "ring")
end

local AIR = U.material("engine:air")

--- Whether the coil at `pos` is Wardenclyffe: `height` blocks of anything
--- standing on its ring, the topmost copper, and `root` copper under it.
function Q.is_tower(pos)
    local h = C.wardenclyffe.height
    for dy = 5, 4 + h do
        local at = game.get_block(up(pos, dy))
        if not (at and at.material and at.material ~= AIR) then return false end
        if dy == 4 + h and at.material ~= B.copper_stock then return false end
    end
    for dy = 1, C.wardenclyffe.root do
        local at = game.get_block(up(pos, -dy))
        if not (at and at.material == B.copper_stock) then return false end
    end
    return true
end

local live = {}              -- coil key -> its position, while its network carries it
local live_next = {}

--- The Tesla coils carried at the last reckoning, in a fixed order.
function Q.live_coils()
    local list = {}
    for _, key in ipairs(U.sorted_keys(live)) do list[#list + 1] = live[key] end
    return list
end

--- Whether a live Tesla coil stands within `reach` of `pos`, in its domain.
function Q.coil_near(pos, reach)
    for _, c in pairs(live) do
        if c.domain == pos.domain and math.abs(c.x - pos.x) <= reach and math.abs(c.y - pos.y) <= reach
            and math.abs(c.z - pos.z) <= reach then
            return true
        end
    end
    return false
end

local function has_acid(name)
    for _, stack in ipairs(game.container(name) or {}) do
        if stack.material == ACID and stack.slot >= 2 and stack.slot <= 5 then return true end
    end
    return false
end

--- What one network gives and needs, and what it does about the difference.
--- `bonus` is charge sent from Wardenclyffe to this network's receivers. A
--- network holding a tower, with receivers to send to (`broadcast`), answers
--- what it has to spare instead of filling its cells with it.
local function reckon(net, bonus, broadcast)
    local supply, demand = bonus or 0, 0
    local consumers, coils = {}, {}
    local fx = nil
    for _, pos in ipairs(net.frames) do
        local placer = U.placer(pos)
        if placer and progress and not fx then fx = progress.effects_of(placer, "science.") or {} end
    end
    fx = fx or {}
    local use = math.max(0, 100 + (fx["science.charge_use_percent"] or 0))
    local lamp_use = math.max(0, 100 + (fx["science.lamp_use_percent"] or 0))
    local loss_percent = fx["science.line_loss_percent"] or 0
    for _, pos in ipairs(net.frames) do
        local name = U.station_name("frame", pos)
        local m = N.movement(name)
        local spec = m and C.movements[m]
        if spec then
            if spec.pile and has_acid(name) then
                supply = supply + C.grid.pile
                drunk[name] = (drunk[name] or 0) + C.grid.period
                if drunk[name] >= C.grid.pile_acid_ticks then
                    drunk[name] = 0
                    game.container_take(name, { material = ACID, count = 1 })
                end
            elseif spec.dynamo then
                supply = supply + C.grid.dynamo * N.speed(pos, U.placer(pos)) // 100
            elseif spec.source then
                supply = supply + spec.source
            elseif spec.motor then
                demand = demand + C.grid.motor
                consumers[#consumers + 1] = pos
            elseif spec.power == "charge" then
                demand = demand + spec.need
                consumers[#consumers + 1] = pos
                if m == "tesla_coil" then coils[#coils + 1] = pos end
            end
        end
    end
    -- The induction motor and the incandescent lamp: less charge for the same
    -- work, rounded up so that a lamp is never free.
    demand = (demand * use + 99) // 100 + (#net.lamps * C.grid.lamp * lamp_use + 99) // 100
    local loss = (net.wires // C.grid.loss_per) * math.max(0, 100 + loss_percent) // 100
    local available = math.max(0, supply - loss)
    local share = 100
    local spare = 0
    if available >= demand and broadcast then
        spare = available - demand
    elseif available >= demand then
        local surplus = available - demand
        for _, pos in ipairs(net.frames) do
            if surplus <= 0 then break end
            surplus = surplus - E.fill_container(U.station_name("frame", pos), ALL_SLOTS, surplus, 6, 9, I.ids.cell)
        end
    else
        local short = demand - available
        for _, pos in ipairs(net.frames) do
            if short <= 0 then break end
            short = short - E.drain_container(U.station_name("frame", pos), ALL_SLOTS, short)
        end
        share = demand > 0 and (demand - short) * 100 // demand or 0
    end
    net.powered = share
    for _, pos in ipairs(net.frames) do powered[U.key(pos)] = share end
    if share > 0 then
        for _, pos in ipairs(coils) do
            if Q.is_coil(pos) then live_next[U.key(pos)] = pos end
        end
    end
    -- Lamps: lit while the network carries them, or a Tesla coil is near;
    -- dark when neither.
    local lit_id, dark_id = U.id(C.lamp.lit), U.id(C.lamp.id)
    for _, pos in ipairs(net.lamps) do
        local at = game.get_block(pos)
        local want_lit = (share > 0 and demand > 0) or Q.coil_near(pos, C.tesla.lamp_reach)
        if at and at.material == B.lamp and want_lit then
            game.set_block(pos, lit_id)
            local placer = game.storage.get(lamp_key(pos))
            if type(placer) == "string" then tds.tier5.toy(placer, "lamp") end
        elseif at and at.material == B.lamp_lit and not want_lit then
            game.set_block(pos, dark_id)
        end
    end
    return spare
end

--- The frames with a receiver in them, by domain.
local function receivers()
    local by = {}
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == "receiver" then
            local pos = U.station_pos(name, "frame")
            if pos then
                local d = pos.domain or ""
                by[d] = by[d] or {}
                by[d][#by[d] + 1] = pos
            end
        end
    end
    return by
end

--- The towers on a network: its Tesla coils that are Wardenclyffe, for a
--- placer who knows it.
local function towers(net)
    local list = {}
    for _, pos in ipairs(net.frames) do
        local placer = U.placer(pos)
        if Q.is_coil(pos) and placer and progress and progress.has(placer, "science.wardenclyffe")
            and Q.is_tower(pos) then
            list[#list + 1] = { pos = pos, placer = placer }
        end
    end
    return list
end

Q.towers = towers

tds.on_tick(C.grid.period, function()
    local done, order = {}, {}
    local function visit(pos)
        if not game.get_block(pos) then return end
        local net = Q.at(pos)
        if net and not done[net] then
            done[net] = true
            order[#order + 1] = net
        end
    end
    for _, name in ipairs(game.containers(FRAMES)) do
        local pos = U.station_pos(name, "frame")
        if pos then visit(pos) end
    end
    for _, key in ipairs(game.storage.keys("lamp:")) do
        local pos = U.unpack(string.sub(key, 6))
        if pos then
            local at = game.get_block(pos)
            if at and Q.kind(at) ~= "lamp" then game.storage.set(key, nil) else visit(pos) end
        end
    end
    -- Towers first: what they spare is what the receivers are sent.
    live_next = {}
    local by_domain = receivers()
    local sent = {}              -- domain -> charge to share among its receivers
    local rest = {}
    for _, net in ipairs(order) do
        local list = towers(net)
        if #list > 0 then
            local d = list[1].pos.domain or ""
            local spare = reckon(net, 0, by_domain[d] ~= nil)
            sent[d] = (sent[d] or 0) + spare
            for _, t in ipairs(list) do
                if Q.powered(t.pos) > 0 then tds.tier6.toy(t.placer, "wardenclyffe") end
            end
        else
            rest[#rest + 1] = net
        end
    end
    for _, net in ipairs(rest) do
        local bonus = 0
        for _, pos in ipairs(net.frames) do
            local d = pos.domain or ""
            if sent[d] and by_domain[d] and N.movement(U.station_name("frame", pos)) == "receiver" then
                bonus = bonus + sent[d] // #by_domain[d]
            end
        end
        reckon(net, bonus, false)
    end
    live = live_next
end)

return Q
