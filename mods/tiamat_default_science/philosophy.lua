-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 4's instruments (brief §5.2, §6.4): the century that learned to
-- measure. Each is held and used, reads the world, and says what it read;
-- the first four are the long tail of insight that pays for tier 5, one
-- discovery for every star, material, kind of weather and climate.
--
--   the telescope     at night, under the open sky, at a star: logs it
--   the microscope    at anything: looks very closely, once per material
--   the barometer     anywhere: the weather, and whether it is coming or going
--   the thermometer   anywhere: how warm, and the climate it belongs to
--   the chronometer   at a block: marks it; anywhere: where you are, and a needle to the mark
--   the orrery        anywhere: the planets go round the sun (Principia)
--   the hemispheres   near two horses: they strain, and cannot part them (the air pump)
--   the balloon       held, with charcoal in the pack: slow flight while the charcoal burns
--
-- Shown, never kept as the world's state; every number that decides
-- anything is a whole one. The orrery's circle is a table, not a sine.

local C = tds.config
local U = tds.util
local I = tds.items
local S = tds.instruments
local T4 = tds.tier4

local P = {}

local weather = U.exports("tiamat_weather")
local world = U.exports("tiamat_default_world")
local life = U.exports("tiamat_default_life")
local progress = U.exports("tiamat_default_progress")

local function holding(e, id)
    return e.held ~= nil and e.held.material == I.ids[id] and e.held.shape == nil
end

local function body_of(uuid)
    local id = game.player_entity(uuid)
    return id and game.entity(id)
end

-- The telescope -------------------------------------------------------------------------

local function night(t)
    return t >= C.telescope.dusk or t < C.telescope.dawn
end

tds.on_use(function(e)
    if not holding(e, "telescope") then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local p = body.pos
    if not night(game.time_of_day()) then return "The sky is too bright to see the stars." end
    local light = game.get_light{ x = math.floor(p.x), y = math.floor(p.y) + 2, z = math.floor(p.z), domain = U.place(e.domain) }
    if light.sun < C.telescope.open_sky then return "You cannot see the sky from here." end
    local seen = game.star_in_view(e.player)
    if not seen or seen.alignment < C.telescope.alignment then return "Point it straight at a star." end
    -- With the spectroscope, each star's light is a second lesson (brief §5.3).
    local split = progress and progress.has(e.player, "science.spectroscope") and T4.found(e.player, "spectrum", seen.id)
    if T4.found(e.player, "star", seen.id) or split then return "" end
    return string.format("Star %d: you have logged it already.", seen.id)
end)

-- The microscope --------------------------------------------------------------------------

tds.on_use(function(e)
    if not holding(e, "microscope") then return nil end
    if not e.x then return "Look at something close." end
    local id = game.block_of(e.material)
    if id then T4.found(e.player, "specimen", id) end
    return "Under the microscope: " .. S.magnify(e.material)
end)

-- The barometer ---------------------------------------------------------------------------

local readings = {}         -- player -> their last few readings, as intensities, oldest first

--- "rising", "falling" or "steady", from a player's last readings.
local function trend(uuid, intensity)
    local list = readings[uuid] or {}
    local first = list[1]
    list[#list + 1] = intensity
    while #list > C.barometer.history do table.remove(list, 1) end
    readings[uuid] = list
    if first == nil or intensity == first then return "steady" end
    return intensity > first and "coming on" or "going off"
end

tds.on_leave(function(e) readings[e.player] = nil end)

tds.on_use(function(e)
    if not holding(e, "barometer") then return nil end
    if not (weather and weather.weather_for) then return "The quicksilver does not move." end
    local kind, intensity, label = weather.weather_for(e.player)
    if not kind then return "The quicksilver does not move." end
    T4.found(e.player, "weather", kind)
    local name = label or kind
    if kind == "clear" then return "Clear, and set fair." end
    return string.format("%s, %d in a thousand, and %s.", name, intensity or 0, trend(e.player, intensity or 0))
end)

-- The thermometer ---------------------------------------------------------------------------

tds.on_use(function(e)
    if not holding(e, "thermometer") then return nil end
    local body = body_of(e.player)
    if not (body and weather and weather.warmth) then return "The quicksilver does not move." end
    local p = body.pos
    local x, y, z = math.floor(p.x), math.floor(p.y), math.floor(p.z)
    local warmth = weather.warmth(x, y, z)
    if not warmth then return "The quicksilver does not move." end
    local degrees = warmth * 110 // 1000 - 10
    local biome = world and world.biome_under and world.biome_under(x, y, z)
    if biome then T4.found(e.player, "climate", biome) end
    return string.format("%d degrees Fahrenheit.", degrees)
end)

-- The chronometer ---------------------------------------------------------------------------

local function mark_key(uuid) return "mark:" .. uuid end

tds.on_use(function(e)
    if not holding(e, "chronometer") then return nil end
    if e.x then
        local pos = U.block_of(e)
        game.storage.set(mark_key(e.player), U.pack(pos))
        return string.format("Marked: %d, %d, %d.", pos.x, pos.y, pos.z)
    end
    local body = body_of(e.player)
    if not body then return nil end
    local p = body.pos
    local here = string.format("You are at %d, %d, %d.", math.floor(p.x), math.floor(p.y), math.floor(p.z))
    local mark = U.unpack(game.storage.get(mark_key(e.player)))
    if not mark or mark.domain ~= U.place(e.domain) then return here end
    local dx, dz = mark.x + 0.5 - p.x, mark.z + 0.5 - p.z
    local far = S.distance(dx, dz)
    if far <= C.chronometer.home_radius then return here .. " You are at your mark." end
    S.needle(e.player, p, U.place(e.domain), dx, dz)
    return string.format("%s Your mark is about %d blocks to the %s.", here, far, S.direction(dx, dz))
end)

-- The orrery --------------------------------------------------------------------------------

tds.on_use(function(e)
    if not holding(e, "orrery") then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local p, domain = body.pos, U.place(e.domain)
    local centre = { x = p.x, y = p.y + 2.2, z = p.z, domain = domain }
    game.emit_particles{ pos = centre, count = 6, colour = { r = 1.0, g = 0.85, b = 0.2 }, size = 0.25,
        lifetime = 3, gravity = 0, collide = false, player = e.player }
    -- Each planet one step further round for each hour, the inner ones faster.
    local step = math.floor(game.time_of_day() * 24)
    for i = 1, C.orrery.planets do
        local point = C.circle[(step * (C.orrery.planets + 1 - i)) % #C.circle + 1]
        local r = 0.5 * i
        game.emit_particles{
            pos = { x = centre.x + r * point[1] / 1000, y = centre.y, z = centre.z + r * point[2] / 1000, domain = domain },
            count = 2, colour = C.orrery.colours[i], size = 0.12, lifetime = 3, gravity = 0, collide = false,
            player = e.player,
        }
    end
    return "The planets go round the sun, as Newton said they must."
end)

-- The gravimeter (Cavendish) -------------------------------------------------------------------

local HEAVY = {}
for _, id in ipairs(C.gravimeter.heavy) do
    local m = U.material(U.id(id))
    if m then HEAVY[m] = true end
end
local AXES = {
    { 0, -1, 0, "down" }, { 0, 1, 0, "up" }, { 0, 0, 1, "north" },
    { 0, 0, -1, "south" }, { -1, 0, 0, "east" }, { 1, 0, 0, "west" },
}

--- The nearest heavy ore along the six axes from `pos`: six rays, as the dip
--- needle reads, a little further.
function P.heavy(pos, reach)
    local best = nil
    for _, axis in ipairs(AXES) do
        for d = 1, reach do
            local at = game.get_block{ x = pos.x + axis[1] * d, y = pos.y + axis[2] * d, z = pos.z + axis[3] * d,
                domain = pos.domain }
            if at and at.material and HEAVY[at.material] then
                if not best or d < best.d then best = { d = d, way = axis[4], what = U.name_of(at.material) } end
                break
            end
        end
    end
    return best
end

tds.on_use(function(e)
    if not holding(e, "gravimeter") then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local p = body.pos
    local found = P.heavy({ x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z), domain = U.place(e.domain) },
        C.gravimeter.reach)
    if not found then return "The balance hangs level." end
    return string.format("The balance tips %s: %s, %d blocks off.", found.way, found.what, found.d)
end)

-- The Magdeburg hemispheres ------------------------------------------------------------------

local HORSE = U.id(C.magdeburg.horse)

tds.on_use(function(e)
    if not holding(e, "magdeburg_hemispheres") then return nil end
    local body = body_of(e.player)
    if not body then return nil end
    local horses = 0
    for _, id in ipairs(game.entities_in_radius(body.pos, C.magdeburg.radius) or {}) do
        local ent = game.entity(id)
        if ent and ent.model == HORSE then horses = horses + 1 end
    end
    if horses < C.magdeburg.horses then
        return "Bring two horses, and let them pull."
    end
    T4.toy(e.player, "magdeburg")
    return "The horses strain and strain, and cannot pull the hemispheres apart!"
end)

-- The balloon -------------------------------------------------------------------------------
--
-- Flight through Life's `set_ability`, as one source among Life's own (sibling
-- ask L-S3): slow, while a charcoal burns. Each charcoal lasts `charcoal_ticks`.

local SOURCE = game.mod_id .. ":balloon"
local CHARCOAL = U.id("C:charcoal")
local HYDROGEN = U.id("hydrogen")
local HELIUM = U.id("helium")
local JAR = U.id("glass_jar")
local burning = {}          -- player -> the tick their charcoal burns out

local function land(uuid)
    if burning[uuid] and life and life.set_ability then life.set_ability(uuid, SOURCE, nil) end
    burning[uuid] = nil
end

tds.on_tick(C.kite.period, function(now)
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        local held = game.held(uuid)
        if held and held.material == I.ids.balloon_pack and life and life.set_ability then
            if not burning[uuid] or burning[uuid] <= now then
                -- Helium first (tier 6), then hydrogen (tier 5's electrolysis): each lifts longer.
                local lift = nil
                if game.take(uuid, { material = HELIUM, count = 1 }) >= U.UNITS then
                    game.give(uuid, { material = JAR, count = 1 })
                    lift = C.helium_balloon
                elseif game.take(uuid, { material = HYDROGEN, count = 1 }) >= U.UNITS then
                    game.give(uuid, { material = JAR, count = 1 })
                    lift = C.balloon.hydrogen
                elseif game.take(uuid, { material = CHARCOAL, count = 1 }) >= U.UNITS then
                    lift = { ticks = C.balloon.charcoal_ticks, speed = C.balloon.speed }
                end
                if lift then
                    if not burning[uuid] then T4.toy(uuid, "balloon") end
                    burning[uuid] = now + lift.ticks
                    life.set_ability(uuid, SOURCE, { fly = true, speed_mul = lift.speed / 100 })
                else
                    land(uuid)
                end
            end
        elseif burning[uuid] then
            land(uuid)
        end
    end
end)

tds.on_leave(function(e) burning[e.player] = nil end)

return P
