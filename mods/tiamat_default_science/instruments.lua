-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The Bench's instruments (brief §4, §6.4): things a child holds or carves
-- that read the world and say what they read.
--
--   the sundial      a gnomon carved from stone: used in sunshine, it tells the hour
--   the burning glass held and used on anything: its name, what it is, how hard;
--                    on a laid fire in the noon sun, it lights it
--   the compass      used anywhere: a needle of dots to north, or to your cairn
--   the kite         held under the open sky: it flies over you, higher in storms
--
-- What may be lit, and whether it can be now, is Craft's to say: the glass
-- asks Craft's `ignite` (ask C-S6) at the blocks Craft lights.
--
-- What is read here is shown, never kept as the world's state, and every
-- number that decides anything is a whole one. The compass and the kite
-- place particles, which are decoration: nothing reads one back.

local C = tds.config
local U = tds.util
local A = tds.apprentice
local G = tds.glyphs
local I = tds.items

local S = {}

local weather = U.exports("tiamat_weather")
local craft = U.exports("tiamat_default_craft")

local LENS = I.ids.lens
local COMPASS = I.ids.compass
local KITE = I.ids.kite

local function holding(e, material)
    return e.held ~= nil and e.held.material == material and e.held.shape == nil
end

--- A player's body: its position and facing, or nil.
local function body_of(uuid)
    local id = game.player_entity(uuid)
    return id and game.entity(id)
end

-- The sundial ------------------------------------------------------------------------

--- "about 3 in the afternoon", from the day's fraction (0 midnight).
function S.hour_words(t)
    local hour = math.floor(t * 24) % 24
    if hour == 12 then return "about noon" end
    local twelve = hour % 12
    if twelve == 0 then twelve = 12 end
    local part = hour < 12 and "in the morning" or (hour < 18 and "in the afternoon" or "in the evening")
    return string.format("about %d %s", twelve, part)
end

--- What a sundial at `pos` says now, and whether it read the hour.
function S.sundial(pos)
    local light = game.get_light{ x = pos.x, y = pos.y + 1, z = pos.z, domain = pos.domain }
    if light.sun < C.sundial.open_sky then
        return "No sunlight falls on the dial.", false
    end
    local t = game.time_of_day()
    if t < C.sundial.dawn or t >= C.sundial.dusk then
        return "The sun is down, so the dial casts no shadow.", false
    end
    return "The shadow says it is " .. S.hour_words(t) .. ".", true
end

tds.on_use(function(e)
    if not e.x or holding(e, LENS) or holding(e, COMPASS) then return nil end
    if not U.tagged(e.material, C.stone_tag) then return nil end
    local pos = U.block_of(e)
    if G.of(game.get_block(pos)) ~= "gnomon" then return nil end
    if not A.has(e.player, "shared.sundial") then return nil end
    local said, read = S.sundial(pos)
    if read then A.discover(e.player, A.HOUR) end
    return said
end)

-- The burning glass ------------------------------------------------------------------------

--- Whether the noon sun falls on `pos`: the high hours, and the sky open
--- above it.
function S.high_sun(pos)
    local t = game.time_of_day()
    if t < C.burning_glass.from or t >= C.burning_glass.to then return false end
    local light = game.get_light{ x = pos.x, y = pos.y + 1, z = pos.z, domain = pos.domain }
    return light.sun >= C.burning_glass.open_sky
end

--- "Granite: stone. Two seconds to break by hand."
function S.magnify(material)
    local name = U.name_of(material)
    local tags = game.tags(material) or {}
    local seconds = math.floor((game.hardness(material) or 0) + 0.5)
    local what = #tags > 0 and (": " .. table.concat(tags, ", ")) or ""
    local hard
    if seconds < 1 then
        hard = "It breaks at a touch."
    elseif seconds == 1 then
        hard = "One second to break by hand."
    else
        hard = string.format("%d seconds to break by hand.", seconds)
    end
    return string.format("%s%s%s. %s", string.upper(string.sub(name, 1, 1)), string.sub(name, 2), what, hard)
end

tds.on_use(function(e)
    if not e.x or not holding(e, LENS) then return nil end
    return S.magnify(e.material)
end)

-- Held to a laid fire or a cold kiln: asked before the fire's box opens.
local lightable = {}
for i, id in ipairs(C.burning_glass.at) do lightable[i] = U.id(id) end
tds.on_use_at(lightable, function(e)
    if not holding(e, LENS) or not craft then return nil end
    local pos = U.block_of(e)
    if not S.high_sun(pos) then
        return "The glass needs the high noon sun on it to light a fire."
    end
    local lit, why = craft.ignite(pos, e.player)
    if not lit then return why end          -- Craft's words: no fuel, alight already
    A.discover(e.player, A.SUNFIRE)
    return "The sun through the glass sets it alight!"
end)

-- The compass, and the cairn it finds ------------------------------------------------------

local function cairn_key(uuid) return "cairn:" .. uuid end

--- A cairn placed is its placer's home: the newest one, one a player.
tds.on_place(function(e)
    if not U.tagged(e.material, C.stone_tag) or G.of(e.occupancy) ~= "cairn" then return end
    game.storage.set(cairn_key(e.player), U.pack{ x = e.x, y = e.y, z = e.z, domain = U.place(tds.domain_of[e.player]) })
    game.chat_to(e.player, "This cairn marks your home. A compass will point to it.")
end)

--- A player's cairn, if it still stands.
function S.cairn(uuid)
    local pos = U.unpack(game.storage.get(cairn_key(uuid)))
    if not pos then return nil end
    local at = game.get_block(pos)
    if at and U.tagged(at.material, C.stone_tag) and G.of(at) == "cairn" then return pos end
    -- Dug, or built over: forget it rather than point at nothing.
    if at then game.storage.set(cairn_key(uuid), nil) end
    return nil
end

--- A direction across the ground in words. `+z` is north and east is `-x`
--- in this engine's axes; a direction within about 27 degrees of one of the
--- four is that one, and between two it is both.
function S.direction(dx, dz)
    local ns = dz > 0 and "north" or "south"
    local ew = dx < 0 and "east" or "west"
    local adx, adz = math.abs(dx), math.abs(dz)
    if adz > 2 * adx then return ns end
    if adx > 2 * adz then return ew end
    return ns .. "-" .. ew
end

--- About how far, in whole blocks, without a square root: the long side and
--- two fifths of the short one, which is within a tenth of the true distance.
function S.distance(dx, dz)
    local a, b = math.floor(math.abs(dx) + 0.5), math.floor(math.abs(dz) + 0.5)
    if a < b then a, b = b, a end
    return a + (b * 41) // 100
end

--- Dots from the player toward `(dx, dz)`, seen by them alone.
local function needle(uuid, from, domain, dx, dz)
    local m = math.max(math.abs(dx), math.abs(dz))
    if m == 0 then return end
    local ux, uz = dx / m, dz / m
    for i = 0, C.compass.needle_dots - 1 do
        local d = C.compass.needle_start + i * C.compass.needle_step
        game.emit_particles{
            pos = { x = from.x + ux * d, y = from.y + C.compass.needle_height, z = from.z + uz * d, domain = domain },
            count = 1, colour = C.compass.colour, size = 0.12, lifetime = 1.5,
            gravity = 0, collide = false, player = uuid,
        }
    end
end

tds.on_use(function(e)
    if not holding(e, COMPASS) then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local here = body.pos
    local home = S.cairn(e.player)
    if home and home.domain ~= U.place(e.domain) then
        needle(e.player, here, U.place(e.domain), 0, 1)
        return "Your cairn is in another place. North is that way."
    end
    if not home then
        needle(e.player, here, U.place(e.domain), 0, 1)
        return "North is that way."
    end
    local dx, dz = home.x + 0.5 - here.x, home.z + 0.5 - here.z
    local far = S.distance(dx, dz)
    A.discover(e.player, A.HOME)
    if far <= C.compass.home_radius then return "You are home!" end
    needle(e.player, here, U.place(e.domain), dx, dz)
    return string.format("Home is about %d blocks away, to the %s.", far, S.direction(dx, dz))
end)

-- The surveyor's staff (Ibn al-Haytham's optics) -------------------------------------------

local STAFF = I.ids.surveyors_staff

--- "12 blocks away, 3 up, and 5 under the ground."
function S.survey(from, pos)
    local dx, dz = pos.x + 0.5 - from.x, pos.z + 0.5 - from.z
    local far = S.distance(dx, dz)
    local rise = pos.y - math.floor(from.y)
    local updown = rise == 0 and "level with you" or (rise > 0 and string.format("%d up", rise) or string.format("%d down", -rise))
    local ground = game.surface_at{ x = pos.x, z = pos.z, from = pos.y + 64, depth = 256, skip_passable = true,
        domain = pos.domain }
    local under = ground and ground.y - pos.y or 0
    local depth = under > 0 and string.format(", and %d under the ground", under) or ", at the surface"
    return string.format("%d blocks away, %s%s.", far, updown, depth)
end

tds.on_use(function(e)
    if not holding(e, STAFF) then return nil end
    if not e.x then return "Too far to measure." end
    local body = body_of(e.player)
    if not body then return nil end
    return S.survey(body.pos, U.block_of(e))
end)

-- The dip needle (Gilbert's De Magnete) -----------------------------------------------------

local NEEDLE = I.ids.dip_needle
local AXES = {
    { 0, -1, 0, "down" }, { 0, 1, 0, "up" }, { 0, 0, 1, "north" },
    { 0, 0, -1, "south" }, { -1, 0, 0, "east" }, { 1, 0, 0, "west" },
}

--- The nearest metal ore along the six axes from `pos`, within `reach`: its
--- direction and distance, or nil. Six rays, not a volume: a reading is 96
--- blocks read, never tens of thousands (brief §2.1).
function S.dip(pos, reach)
    local best = nil
    for _, axis in ipairs(AXES) do
        for d = 1, reach do
            local at = game.get_block{ x = pos.x + axis[1] * d, y = pos.y + axis[2] * d, z = pos.z + axis[3] * d,
                domain = pos.domain }
            if at and at.material and U.tagged(at.material, "metal_ore") then
                if not best or d < best.d then best = { d = d, way = axis[4] } end
                break
            end
        end
    end
    return best
end

tds.on_use(function(e)
    if not holding(e, NEEDLE) then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local p = body.pos
    local pos = { x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z), domain = U.place(e.domain) }
    local found = S.dip(pos, C.dip_reach)
    if not found then return "The needle hangs still." end
    local strength = found.d <= C.dip_reach // 3 and "hard" or (found.d <= (2 * C.dip_reach) // 3 and "gently" or "a little")
    return string.format("The needle leans %s %s: metal ore, %d blocks off.", strength, found.way, found.d)
end)

-- The kite -------------------------------------------------------------------------------

--- The wind over `pos`: its direction across the ground and its strength,
--- 0.2 on a clear day to 1 in a blizzard (Weather's `wind`, ask Wx-S1).
--- Nil where there is no weather: without Weather, before the world opens,
--- and off the overworld, which is the only place Weather blows.
function S.wind(pos, domain)
    if not (weather and weather.wind) or domain ~= nil then return nil end
    local x, z, strength = weather.wind(math.floor(pos.x), math.floor(pos.z))
    if x == nil then return nil end
    return x, z, strength
end

--- Where a kite flies over a body at `p` facing `facing`: downwind of its
--- holder and higher the harder it blows; with no wind, behind them at the
--- plain height.
function S.kite_at(p, facing, domain)
    local wx, wz, strength = S.wind(p, domain)
    if wx then
        return {
            x = p.x + wx * C.kite.behind,
            y = p.y + C.kite.height + math.floor(strength * C.kite.wind_height),
            z = p.z + wz * C.kite.behind,
            domain = domain,
        }
    end
    return {
        x = p.x - facing.x * C.kite.behind,
        y = p.y + C.kite.height,
        z = p.z - facing.z * C.kite.behind,
        domain = domain,
    }
end

local function fly(uuid, body)
    local p = body.pos
    local domain = U.place(tds.domain_of[uuid])
    local light = game.get_light{ x = math.floor(p.x), y = math.floor(p.y) + 2, z = math.floor(p.z), domain = domain }
    if light.sun < C.kite.open_sky then return false end
    local at = S.kite_at(p, body.facing, domain)
    local life = C.kite.period / 20 + 0.3
    game.emit_particles{ pos = at, count = 10, colour = C.kite.colour, size = 0.25, lifetime = life,
        area = { x = 0.35, y = 0.5, z = 0.35 }, gravity = 0, collide = false, radius = C.kite.radius }
    game.emit_particles{ pos = { x = at.x, y = at.y - 1.1, z = at.z, domain = domain }, count = 4,
        colour = C.kite.tail, size = 0.12, lifetime = life, area = { x = 0.05, y = 0.6, z = 0.05 },
        gravity = 0, collide = false, radius = C.kite.radius }
    return true
end

tds.on_tick(C.kite.period, function()
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        local held = game.held(uuid)
        if held and held.material == KITE then
            local body = body_of(uuid)
            if body and fly(uuid, body) then A.discover(uuid, A.KITE) end
        end
    end
end)

return S
