-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Gates, the Core and the Fold (brief §6.8).
--
--   a wormhole gate    an upright 3 × 3 ring of cavorite ring blocks, air in the
--                      middle. The fold key used on the ring's bottom middle
--                      block marks it; used on a second gate, it pairs the two.
--                      While a live Tesla coil stands near, a gate is open — its
--                      middle a wormhole — and stepping in steps out at its twin.
--   the Core           a throat in the middle of three 5 × 5 rings of cavorite
--                      ring blocks, one in each plane; four live Tesla coils near
--                      and a gravity engine within reach. The key used on the
--                      ring block under the throat turns it: the rings spin, the
--                      sky darkens round it, and the throat opens.
--   the Fold           while a Core turns, the key used at the star you are
--                      looking at, near the Core, folds you to that star's world.
--                      You arrive from the sky, lightly; a return gate is built
--                      beside where you land, and stepping into it brings you back.
--   the Deep           the key used on a turning Core's ring again, by one who
--                      knows the Deep, folds blind. Fall off a fragment and you
--                      are back at the Core; the strange matter you carried is not.
--   the recall beacon  a pocket fold to your own nearest gate, once an hour
--   the Unified Field  the capstone: fold to any gate or body you know, for 256
--     Engine           charge from a carried cell
--
-- Nothing here scans a volume: a gate is 9 reads, a Core 48, each checked when
-- a key is used, and a gate's ring again once a second while it is paired.

local C = tds.config
local U = tds.util
local B = tds.blocks
local G = tds.glyphs
local I = tds.items
local Q = tds.grid
local A = tds.apprentice
local T6 = tds.tier6
local T7 = tds.tier7
local GR = tds.gravity
local BO = tds.bodies

local F = {}

local weather = U.exports("tiamat_weather")
local progress = U.exports("tiamat_default_progress")

local KEY = I.ids.fold_key
local WORMHOLE = U.id(C.wormhole.id)
local STRANGE = I.ids.strange_matter
local MORPHIC = U.material(U.id(C.deep.strange))

local function body_of(uuid)
    local id = game.player_entity(uuid)
    return id and game.entity(id)
end

local function at(pos, dx, dy, dz)
    return { x = pos.x + dx, y = pos.y + dy, z = pos.z + dz, domain = pos.domain }
end

local function is_ring(pos)
    local b = game.get_block(pos)
    return b ~= nil and b.material == B.cavorite and G.of(b) == "ring"
end

local function is_open_air(pos)
    local b = game.get_block(pos)
    return b == nil or b.material == game.AIR or b.material == B.wormhole
end

--- The domain a position is in, as the engine names it.
local function domain_of(pos) return pos.domain or "overworld" end

--- Sends a player to `pos` (in its domain): a move within the domain they
--- are in, a transfer to any other.
local function send(uuid, pos)
    local here = tds.domain_of[uuid] or "overworld"
    local there = domain_of(pos)
    local to = { x = pos.x + 0.5, y = pos.y, z = pos.z + 0.5 }
    if here == there then return game.move_player(uuid, to) end
    local body = game.player_entity(uuid)
    return body ~= nil and game.transfer_entity(body, there, to)
end

-- Gates ---------------------------------------------------------------------------------

--- The gate whose bottom middle ring block is `bottom`: its middle and the
--- axis its ring spans ("x": across x and up, "z": across z and up), or nil.
function F.gate_at(bottom)
    local mid = at(bottom, 0, 1, 0)
    if not is_open_air(mid) then return nil end
    for _, axis in ipairs({ "x", "z" }) do
        local whole = true
        for a = -1, 1 do
            for b = -1, 1 do
                if not (a == 0 and b == 0) then
                    local p = axis == "x" and at(mid, a, b, 0) or at(mid, 0, b, a)
                    if not is_ring(p) then whole = false break end
                end
            end
            if not whole then break end
        end
        if whole then return mid, axis end
    end
    return nil
end

local function gate_key(mid) return "gate:" .. U.key(mid) end

--- A gate's record: `{ twin = <key>, axis, owner }`, or nil.
local function gate_record(mid)
    local text = game.storage.get(gate_key(mid))
    if type(text) ~= "string" then return nil end
    local twin, axis, owner = string.match(text, "^(.-)|(%a)|(%x+)$")
    return twin and { twin = U.unpack(twin), axis = axis, owner = owner } or nil
end

--- Where a player steps out of a gate: in front of its middle.
local function front_of(mid, axis)
    return axis == "x" and at(mid, 0, 0, 1) or at(mid, 1, 0, 0)
end

local function pairs_of(uuid)
    return game.storage.get("gates:" .. uuid) or 0
end

local function use_on_gate(e, mid, axis)
    if not A.has(e.player, "science.wormhole_gates") then return "You do not yet know how a gate is opened." end
    if gate_record(mid) then return "This gate is already paired." end
    local pending = game.storage.get("pending:" .. e.player)
    local first = type(pending) == "string" and U.unpack(string.match(pending, "^(.-)|") or "")
    local first_axis = type(pending) == "string" and string.match(pending, "|(%a)$")
    if first and U.key(first) ~= U.key(mid) and domain_of(first) == domain_of(mid) and not gate_record(first) then
        if pairs_of(e.player) >= C.gate.pairs then return "You have as many gates as you can hold open." end
        game.storage.set(gate_key(first), U.pack(mid) .. "|" .. axis .. "|" .. e.player)
        game.storage.set(gate_key(mid), U.pack(first) .. "|" .. first_axis .. "|" .. e.player)
        game.storage.set("pending:" .. e.player, nil)
        game.storage.set("gates:" .. e.player, pairs_of(e.player) + 1)
        return "The two gates know each other now."
    end
    game.storage.set("pending:" .. e.player, U.pack(mid) .. "|" .. axis)
    return "The gate is marked. Use the key on its twin."
end

local function unpair(mid, record)
    game.storage.set(gate_key(mid), nil)
    if record and record.twin then
        game.storage.set(gate_key(record.twin), nil)
        local b = game.get_block(record.twin)
        if b and b.material == B.wormhole then game.set_block(record.twin, "engine:air") end
        if record.owner then game.storage.set("gates:" .. record.owner, math.max(0, pairs_of(record.owner) - 1)) end
    end
    local b = game.get_block(mid)
    if b and b.material == B.wormhole then game.set_block(mid, "engine:air") end
end

-- Once a second: each paired gate still whole is open beside a live coil,
-- and shut without one; a broken gate forgets its twin.
tds.on_tick(C.gate.period, function()
    for _, key in ipairs(game.storage.keys("gate:")) do
        local mid = U.unpack(string.sub(key, 6))
        local record = mid and gate_record(mid)
        if mid and record and game.get_block(at(mid, 0, -1, 0)) then
            if not F.gate_at(at(mid, 0, -1, 0)) then
                unpair(mid, record)
            else
                local b = game.get_block(mid)
                local open = Q.coil_near(mid, C.gate.coil_reach)
                if open and b and b.material ~= B.wormhole then
                    game.set_block(mid, WORMHOLE)
                elseif not open and b and b.material == B.wormhole then
                    game.set_block(mid, "engine:air")
                end
                if open then F.carry(mid, record) end
            end
        end
    end
end)

--- Dropped things at an open gate's throat come out at its twin.
function F.carry(mid, record)
    local throat = { x = mid.x + 0.5, y = mid.y + 0.5, z = mid.z + 0.5, domain = mid.domain }
    local twin = record.twin and gate_record(record.twin)
    if not twin then return 0 end
    local out = front_of(record.twin, twin.axis)
    local n = 0
    for _, id in ipairs(game.entities_in_radius(throat, C.gate.carries) or {}) do
        local ent = game.entity(id)
        if ent and ent.item then
            game.set_entity(id, { pos = { x = out.x + 0.5, y = out.y + 0.5, z = out.z + 0.5 } })
            n = n + 1
        end
    end
    return n
end

--- The nearest gate a player owns, by their domain first: its record and middle.
function F.nearest_gate(uuid, from)
    local best, best_d
    for _, key in ipairs(game.storage.keys("gate:")) do
        local mid = U.unpack(string.sub(key, 6))
        local record = mid and gate_record(mid)
        if record and record.owner == uuid then
            local d = math.abs(mid.x - from.x) + math.abs(mid.y - from.y) + math.abs(mid.z - from.z)
            if domain_of(mid) ~= domain_of(from) then d = d + 1000000000 end
            if not best_d or d < best_d then best, best_d = { mid = mid, record = record }, d end
        end
    end
    return best
end

-- The Core ---------------------------------------------------------------------------------

--- Whether the three rings of a Core stand round `mid`: 48 reads.
function F.rings_at(mid)
    for a = -2, 2 do
        for b = -2, 2 do
            if math.max(math.abs(a), math.abs(b)) == 2 then
                if not (is_ring(at(mid, a, b, 0)) and is_ring(at(mid, 0, b, a)) and is_ring(at(mid, a, 0, b))) then
                    return false
                end
            end
        end
    end
    return is_open_air(mid)
end

--- What a Core at `mid` lacks, or nil when it would turn.
function F.lacks(mid)
    if not F.rings_at(mid) then return "rings" end
    local coils = 0
    for _, c in ipairs(Q.live_coils()) do
        if c.domain == mid.domain and math.abs(c.x - mid.x) <= C.core.coil_reach and math.abs(c.y - mid.y) <= C.core.coil_reach
            and math.abs(c.z - mid.z) <= C.core.coil_reach then
            coils = coils + 1
        end
    end
    if coils < C.core.coils then return "coils" end
    if not Q.engine_near(mid, C.core.engine_reach) then return "engine" end
    return nil
end

local LACKS = {
    rings = "These are not the Core's rings: three of them, five across, one in each plane, round the throat.",
    coils = "The rings are still. The Core wants four Tesla coils alight near it.",
    engine = "The rings are still. Nothing feeds them: the Core wants a gravity engine near it.",
}

local ok, why = pcall(game.register_sound, { id = C.core.hum.sound, file = "sounds/" .. C.core.hum.sound .. ".wav" })
if not ok then game.log("tiamat_default_science: the Core's hum was refused: " .. tostring(why)) end

local spinning = {}         -- Core key -> { mid, stops, rings = { entity ids }, owner }

local function hum_id(key) return "core_" .. string.gsub(key, "[^%w]", "_") end
local darkened = {}         -- player -> the Core key whose dark is on them
local flickering = {}       -- player -> the tick their light comes back
local FLICKER = game.mod_id .. ":shade"
local SOURCE = game.mod_id .. ":core"
local RATES = { { 0.05, 0.0 }, { 0.0, 0.07 }, { 0.09, 0.09 } }

local function spin_up(mid, owner)
    local key = U.key(mid)
    local rings = {}
    for i = 1, #RATES do
        rings[i] = game.spawn_entity{ pos = { x = mid.x + 0.5, y = mid.y + 0.5, z = mid.z + 0.5 },
            model = U.id(C.core.model) }
    end
    spinning[key] = { mid = mid, stops = tds.now() + C.core.spin_ticks, rings = rings, owner = owner }
    game.set_block(mid, WORMHOLE)
    game.play_loop{ id = hum_id(key), sound = U.id(C.core.hum.sound),
        pos = { x = mid.x + 0.5, y = mid.y + 0.5, z = mid.z + 0.5, domain = mid.domain },
        radius = C.core.hum.radius, gain = C.core.hum.gain, fade_ticks = C.core.hum.fade_ticks }
    T7.toy(owner, "core")
end

local function spin_down(key)
    local core = spinning[key]
    if not core then return end
    for _, id in ipairs(core.rings) do if id then game.despawn_entity(id) end end
    -- The rings stop dead, and so does the sound.
    game.stop_loop{ id = hum_id(key), fade_ticks = 0 }
    local b = game.get_block(core.mid)
    if b and b.material == B.wormhole then game.set_block(core.mid, "engine:air") end
    spinning[key] = nil
end

--- The Core turning nearest `pos`, within `reach`, or nil.
function F.turning_near(pos, reach)
    for _, key in ipairs(U.sorted_keys(spinning)) do
        local mid = spinning[key].mid
        if domain_of(mid) == domain_of(pos) and math.abs(mid.x - pos.x) <= reach and math.abs(mid.y - pos.y) <= reach
            and math.abs(mid.z - pos.z) <= reach then
            return spinning[key]
        end
    end
    return nil
end

tds.on_tick(1, function(now)
    for _, uuid in ipairs(U.sorted_keys(flickering)) do
        if now >= flickering[uuid] then
            flickering[uuid] = nil
            if weather and weather.add_overlay then weather.add_overlay(uuid, FLICKER, nil) end
        end
    end
    for _, key in ipairs(U.sorted_keys(spinning)) do
        local core = spinning[key]
        if now >= core.stops then
            spin_down(key)
        else
            for i, id in ipairs(core.rings) do
                if id then
                    game.set_entity(id, { yaw = (now * RATES[i][1]) % 6.2831853, pitch = (now * RATES[i][2]) % 6.2831853 })
                end
            end
        end
    end
end)

-- The sky darkens round a turning Core, through Weather when it is there.
tds.on_tick(C.grid.period, function()
    if not (weather and weather.add_overlay) then return end
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        local body = body_of(uuid)
        local where = body and { x = math.floor(body.pos.x), y = math.floor(body.pos.y), z = math.floor(body.pos.z),
            domain = U.place(tds.domain_of[uuid]) }
        local core = where and F.turning_near(where, C.core.dark_radius)
        local key = core and U.key(core.mid)
        if key ~= darkened[uuid] then
            weather.add_overlay(uuid, SOURCE, key and { intensity = 0.4, sky = { 0, 0, 0 }, sky_mix = 0.6,
                saturation = 0.5, ease_ticks = 40 } or nil)
            darkened[uuid] = key
        end
    end
end)

-- The Fold ------------------------------------------------------------------------------------

local stars_by_id = nil
local function star(id)
    if stars_by_id == nil then
        local all = game.stars()
        if not all then return nil end
        stars_by_id = {}
        for _, s in ipairs(all) do stars_by_id[s.id] = s end
    end
    return stars_by_id[id]
end

local function visited(uuid)
    local list = {}
    for id in string.gmatch(game.storage.get("visited:" .. uuid) or "", "%d+") do
        list[#list + 1] = math.tointeger(tonumber(id))
    end
    return list
end

local function remember(uuid, star_id)
    local list = visited(uuid)
    for _, id in ipairs(list) do if id == star_id then return end end
    list[#list + 1] = star_id
    local parts = {}
    for i, id in ipairs(list) do parts[i] = tostring(id) end
    game.storage.set("visited:" .. uuid, table.concat(parts, ","))
end

--- Folds a player to the body at star `id`, from `origin` (where they come
--- back to). Answers the domain, or nil and why not.
function F.fold_to(uuid, id, origin)
    local s = star(id)
    if not s then return nil, "There is no such star." end
    local known = false
    for _, v in ipairs(visited(uuid)) do if v == id then known = true end end
    if not known and #visited(uuid) >= C.bodies.per_player then return nil, "You have folded to as many worlds as you can." end
    local domain = BO.body_for(s)
    if not domain then return nil, "The fold would not hold." end
    local body = game.player_entity(uuid)
    if not (body and game.transfer_entity(body, domain, C.bodies.arrive)) then return nil, "The fold would not hold." end
    if origin then game.storage.set("origin:" .. uuid, U.pack(origin)) end
    remember(uuid, id)
    T7.body(uuid, id)
    return domain
end

--- Folds a player blind, into the Deep.
function F.misfold(uuid, origin)
    local body = game.player_entity(uuid)
    if not (body and game.transfer_entity(body, BO.DEEP, C.deep.arrive)) then return false end
    if origin then game.storage.set("origin:" .. uuid, U.pack(origin)) end
    return true
end

--- Back to where a player folded from: the Core, or the overworld's middle.
function F.home(uuid)
    local origin = U.unpack(game.storage.get("origin:" .. uuid))
    if not origin then origin = { x = 0, y = 80, z = 0 } end
    return send(uuid, at(origin, 0, -1, 0))
end

local function deep_allowed()
    return game.world_option(game.mod_id .. ":the_deep") ~= false
end

-- The key, used on a cavorite block: a gate's bottom, or a Core's.
tds.on_use_at({ U.id(C.cavorite.id) }, function(e)
    if not (e.held and e.held.material == KEY) then return nil end
    local bottom = U.block_of(e)
    local mid, axis = F.gate_at(bottom)
    if mid then return use_on_gate(e, mid, axis) end
    local core_mid = at(bottom, 0, 2, 0)
    if not F.rings_at(core_mid) then return nil end
    if not A.has(e.player, "science.the_core") then return "You do not yet know what these rings are for." end
    local core = spinning[U.key(core_mid)]
    if core then
        if A.has(e.player, "science.the_deep") and deep_allowed() then
            spin_down(U.key(core_mid))
            if F.misfold(e.player, core_mid) then return "The rings stop dead. This is not anywhere." end
        end
        return "The Core is turning. Look at a star, and use the key."
    end
    local lack = F.lacks(core_mid)
    if lack then return LACKS[lack] end
    spin_up(core_mid, e.player)
    return "The rings begin to turn, and the light goes out of the sky."
end)

-- The key, used at the sky near a turning Core: the Fold.
tds.on_use(function(e)
    if e.x or not (e.held and e.held.material == KEY) then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local here = { x = math.floor(body.pos.x), y = math.floor(body.pos.y), z = math.floor(body.pos.z),
        domain = U.place(e.domain) }
    local core = F.turning_near(here, C.core.fold_reach)
    if not core then return nil end
    if not A.has(e.player, "science.fold_to_stars") then return "The Core turns, and you do not know how to ride it." end
    local seen = game.star_in_view(e.player)
    if not (seen and seen.alignment >= C.core.alignment) then return "Look straight at a star." end
    local domain, why = F.fold_to(e.player, seen.id, core.mid)
    if not domain then return why end
    spin_down(U.key(core.mid))
    return "The rings stop dead, and the stars turn over."
end)

-- Arriving, leaving, and the way back -------------------------------------------------------------------

local function return_key(domain) return "return:" .. domain end

--- Builds a body's return gate, on the ground beside where folds arrive:
--- a cavorite plate with a wormhole on it. Answers whether it stands.
function F.build_return(domain)
    if game.storage.get(return_key(domain)) then return true end
    local top = game.surface_at{ x = 2, z = 0, from = 200, depth = 400, domain = domain }
    if not top then return false end
    local plate = { x = 2, y = top.y + 1, z = 0, domain = domain }
    game.set_block(plate, U.id(C.cavorite.id), G.mask_of("plate"))
    local throat = at(plate, 0, 1, 0)
    game.set_block(throat, WORMHOLE)
    game.storage.set(return_key(domain), U.pack(throat))
    return true
end

local shades = {}           -- player -> their shades' entity ids

local function clear_shades(uuid)
    for _, id in ipairs(shades[uuid] or {}) do game.despawn_entity(id) end
    shades[uuid] = nil
end

local function strange_matter_lost(uuid)
    local units = 0
    for _, view in ipairs({ "player:hotbar", "player:main" }) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            if stack.material == STRANGE then units = units + stack.units end
        end
    end
    if units > 0 then game.take(uuid, { material = STRANGE, units = units }) end
end

tds.on_move(function(e)
    -- Weight: a body's own, while on it.
    local on = BO.parse(e.domain)
    GR.ability(e.player, "body", on and { gravity = on.gravity } or nil)
    if e.domain ~= BO.DEEP then clear_shades(e.player) end
    local feet = { x = e.x, y = e.y, z = e.z, domain = U.place(e.domain) }
    if on then F.build_return(e.domain) end
    if e.domain == BO.DEEP and e.y < C.deep.fall then
        strange_matter_lost(e.player)
        clear_shades(e.player)
        F.home(e.player)
        T7.toy(e.player, "deep")
        return
    end
    local b = game.get_block(feet)
    if not (b and b.material == B.wormhole) then return end
    -- A gate's twin, or a body's way home.
    local record = gate_record(feet)
    if record and record.twin then
        local twin = gate_record(record.twin)
        send(e.player, front_of(record.twin, twin and twin.axis or record.axis))
        T7.toy(e.player, "wormhole")
        return
    end
    if game.storage.get(return_key(e.domain)) == U.pack(feet) then F.home(e.player) end
end)

tds.on_leave(function(e)
    clear_shades(e.player)
    darkened[e.player] = nil
    flickering[e.player] = nil
end)

-- The Deep's strange matter, and its shades ------------------------------------------------------

tds.on_dig(function(e)
    if e.brush == "block" and e.material == MORPHIC and U.where(e) == BO.DEEP then
        game.give(e.player, { material = STRANGE, count = 1 })
    end
end)

local function sign(n) return n < 0 and -1 or (n > 0 and 1 or 0) end
local SHADE_AT = { { 1, 0 }, { -1, 1 }, { -1, -1 } }

tds.on_tick(C.shades.period, function()
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        local body = tds.domain_of[uuid] == BO.DEEP and body_of(uuid)
        if body then
            local p = body.pos
            if not shades[uuid] then
                shades[uuid] = {}
                for i = 1, C.shades.count do
                    local o = SHADE_AT[(i - 1) % #SHADE_AT + 1]
                    shades[uuid][i] = game.spawn_entity{ pos = { x = p.x + o[1] * C.shades.far, y = p.y,
                        z = p.z + o[2] * C.shades.far }, model = U.id(C.shades.model) }
                end
            end
            for i, id in ipairs(shades[uuid]) do
                local s = id and game.entity(id)
                if s then
                    local dx, dz = p.x - s.pos.x, p.z - s.pos.z
                    if math.abs(dx) <= C.shades.near and math.abs(dz) <= C.shades.near then
                        -- It reached you: you are pushed toward the edge, and it is far again.
                        game.move_player(uuid, { x = p.x + sign(dx) * C.shades.push, y = p.y, z = p.z + sign(dz) * C.shades.push })
                        if weather and weather.add_overlay then
                            weather.add_overlay(uuid, FLICKER, { intensity = C.shades.flicker.intensity, ease_ticks = 1 })
                            flickering[uuid] = tds.now() + C.shades.flicker.ticks
                        end
                        local o = SHADE_AT[(i - 1) % #SHADE_AT + 1]
                        game.set_entity(id, { pos = { x = p.x + o[1] * C.shades.far, y = p.y, z = p.z + o[2] * C.shades.far } })
                    else
                        game.set_entity(id, { pos = { x = s.pos.x + sign(dx), y = p.y, z = s.pos.z + sign(dz) } })
                    end
                end
            end
        end
    end
end)

-- The recall beacon ---------------------------------------------------------------------------------

local recalled = {}         -- player -> the tick they last folded home

tds.on_use(function(e)
    if not (e.held and e.held.material == I.ids.recall_beacon) then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local now = tds.now()
    if recalled[e.player] and now - recalled[e.player] < C.recall.cooldown then
        return "The beacon is still gathering itself."
    end
    local from = { x = math.floor(body.pos.x), y = math.floor(body.pos.y), z = math.floor(body.pos.z),
        domain = U.place(e.domain) }
    local gate = F.nearest_gate(e.player, from)
    if not gate then return "You have no gate of your own to fold home to." end
    if not send(e.player, front_of(gate.mid, gate.record.axis)) then return "The fold would not hold." end
    recalled[e.player] = now
    T7.toy(e.player, "recall")
    return "A pocket fold, and you are home."
end)

-- The Unified Field Engine -----------------------------------------------------------------------------

local places = {}           -- player -> the places their open dialog lists

local function places_of(uuid)
    local list = {}
    for _, key in ipairs(game.storage.keys("gate:")) do
        local mid = U.unpack(string.sub(key, 6))
        local record = mid and gate_record(mid)
        if record and record.owner == uuid then
            list[#list + 1] = { label = string.format("Gate at %d, %d, %d", mid.x, mid.y, mid.z), gate = mid, axis = record.axis }
        end
    end
    for _, id in ipairs(visited(uuid)) do
        local s = star(id)
        local kind = s and BO.kind_for(s)
        list[#list + 1] = { label = string.format("The %s world at star %d", kind or "far", id), star = id }
    end
    return list
end

tds.on_use(function(e)
    if not (e.held and e.held.material == I.ids.unified_field_engine) then return nil end
    local list = places_of(e.player)
    if #list == 0 then return "You know nowhere to fold to yet." end
    places[e.player] = list
    local buttons = { { type = "label", text = "The Unified Field: fold to anywhere you know (" .. C.unified.cost .. " charge)" } }
    for i, p in ipairs(list) do
        buttons[#buttons + 1] = { type = "button", name = "go:" .. i, text = p.label }
    end
    game.show_dialog{ player = e.player, form = "unified", tree = {
        type = "container", direction = "column", gap = 6, padding = 8,
        children = { { type = "scroll", children = buttons } },
    } }
    return ""
end)

--- Folds a player to one of their places through the Unified Field.
function F.unified(uuid, i)
    local p = places[uuid] and places[uuid][i]
    if not p then return nil end
    if not T6.spend(uuid, C.unified.cost) then return "The engine needs a charged cell: " .. C.unified.cost .. " charge." end
    local body = body_of(uuid)
    local origin = body and { x = math.floor(body.pos.x), y = math.floor(body.pos.y) + 1, z = math.floor(body.pos.z),
        domain = U.place(tds.domain_of[uuid]) }
    if p.gate then
        send(uuid, front_of(p.gate, p.axis))
    else
        local domain, why = F.fold_to(uuid, p.star, origin)
        if not domain then return why end
    end
    return "The field folds, and you are there."
end

tds.on_dialog("unified", function(e)
    local i = e.kind == "pressed" and e.name and math.tointeger(tonumber(string.match(e.name, "^go:(%d+)$") or ""))
    if not i then return end
    game.close_dialog{ player = e.player, form = "unified" }
    local said = F.unified(e.player, i)
    if said then game.chat_to(e.player, said) end
end)

return F
