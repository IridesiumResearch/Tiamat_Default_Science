-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Gravity, where history stops (brief §6.7):
--
--   gravity plating   a cavorite plate (the `plate` glyph) within 3 blocks under
--                     your feet: you weigh what you would on the Moon. Read as
--                     you move, never on the tick.
--   cavorite soles    worn: half your weight, anywhere
--   the levitator     a harness, worn, with a charged cell in the pack: flight,
--                     4 charge a second
--   gravity wells     a frame with an attractor draws dropped things within 8 to
--                     it; one with a repulsor thrusts what hunts you away
--   the stasis field  a frame with the stasis movement: creatures within 6 hang
--                     still
--
-- Each of the first three is a source of this mod's in Life's `set_ability`
-- (asks L-S3 and L-S7), so Life composes them with its own and with each
-- other: they multiply, and a plate under soles is lighter still. Not one of
-- them calls `set_player_abilities`, which Life writes.

local C = tds.config
local U = tds.util
local B = tds.blocks
local G = tds.glyphs
local I = tds.items
local N = tds.networks
local Q = tds.grid
local T6 = tds.tier6
local T7 = tds.tier7

local GR = {}

local life = U.exports("tiamat_default_life")

local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local WORN = "tiamat_default_life:worn"
local SOURCE = {
    plating = game.mod_id .. ":plating",
    soles = game.mod_id .. ":soles",
    levitator = game.mod_id .. ":levitator",
}

local set = {}              -- player -> source -> the spec last given, so a change is sent once

--- Gives (or with `spec` nil, takes off) one of this mod's sources of a
--- player's abilities, only when it changes. Answers whether it was taken.
function GR.ability(uuid, which, spec)
    set[uuid] = set[uuid] or {}
    local was = set[uuid][which]
    if (was == nil) == (spec == nil) and (was == nil or (was.gravity == spec.gravity and was.fly == spec.fly)) then
        return true
    end
    if not (life and life.set_ability) then return false end
    set[uuid][which] = spec
    return life.set_ability(uuid, SOURCE[which] or (game.mod_id .. ":" .. which), spec) == true
end

--- The source a player has from this mod, or nil.
function GR.has(uuid, which)
    return set[uuid] ~= nil and set[uuid][which] ~= nil
end

-- Plating ----------------------------------------------------------------------------

--- Whether a cavorite plate lies within `reach` blocks under the block `pos`.
function GR.plate_under(pos, reach)
    for d = 1, reach do
        local at = game.get_block{ x = pos.x, y = pos.y - d, z = pos.z, domain = pos.domain }
        if at and at.material == B.cavorite and G.of(at) == "plate" then return true end
    end
    return false
end

tds.on_move(function(e)
    local over = GR.plate_under({ x = e.x, y = e.y, z = e.z, domain = U.place(e.domain) }, C.plating.reach)
    if over then
        if not GR.has(e.player, "plating") then T7.toy(e.player, "plating") end
        GR.ability(e.player, "plating", { gravity = C.plating.gravity })
    else
        GR.ability(e.player, "plating", nil)
    end
end)

-- Soles and the levitator ---------------------------------------------------------------

local function wearing(uuid, id)
    for _, stack in ipairs(game.inventory(uuid, WORN) or {}) do
        if stack.material == I.ids[id] then return true end
    end
    return false
end

local paid = {}             -- player -> ticks of flight since the cell last paid

tds.on_tick(C.soles.period, function()
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        GR.ability(uuid, "soles", wearing(uuid, "cavorite_soles") and { gravity = C.soles.gravity } or nil)
        local flying = false
        if wearing(uuid, "levitator") then
            paid[uuid] = (paid[uuid] or C.grid.period) + C.soles.period
            if paid[uuid] < C.grid.period then
                flying = true
            elseif T6.spend(uuid, C.levitator_spec.cost) then
                paid[uuid] = 0
                flying = true
            end
        end
        if flying and not GR.has(uuid, "levitator") then T7.toy(uuid, "levitate") end
        GR.ability(uuid, "levitator", flying and { fly = true, speed_mul = C.levitator_spec.speed / 100 } or nil)
        if not flying then paid[uuid] = nil end
    end
end)

tds.on_leave(function(e)
    set[e.player] = nil
    paid[e.player] = nil
end)

-- Wells and the stasis field ------------------------------------------------------------------

local function frames_with(movement)
    local list = {}
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == movement then
            local pos = U.station_pos(name, "frame")
            if pos and Q.powered(pos) > 0 then list[#list + 1] = pos end
        end
    end
    return list
end

local function centre(pos)
    return { x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5, domain = pos.domain }
end

local function sign(n) return n < 0 and -1 or (n > 0 and 1 or 0) end

tds.on_tick(C.well.period, function()
    if not life then return end
    for _, pos in ipairs(frames_with("attractor")) do
        if life.pull_drops and (life.pull_drops(centre(pos), C.well.radius, C.well.pull) or 0) > 0 then
            local placer = U.placer(pos)
            if placer then T7.toy(placer, "well") end
        end
    end
    for _, pos in ipairs(frames_with("repulsor")) do
        local c = centre(pos)
        for _, id in ipairs(game.entities_in_radius(c, C.well.radius, "tiamat_default_life") or {}) do
            local ent = game.entity(id)
            if ent and T6.HOSTILE[T6.life_kind(ent) or ""] and life.push then
                local away = { x = sign(ent.pos.x - c.x) * C.well.push, y = 1, z = sign(ent.pos.z - c.z) * C.well.push }
                life.push(id, away)
            end
        end
    end
end)

tds.on_tick(C.stasis_spec.period, function()
    for _, pos in ipairs(frames_with("stasis")) do
        local c = centre(pos)
        local held = false
        for _, id in ipairs(game.entities_in_radius(c, C.stasis_spec.radius) or {}) do
            local ent = game.entity(id)
            if ent and not ent.item and ent.source == "tiamat_default_life" and life and life.freeze then
                held = life.freeze(id, C.stasis_spec.ticks) or held
            elseif ent and ent.source == game.mod_id then
                game.set_entity(id, { velocity = { x = 0, y = 0, z = 0 } })
                held = true
            end
        end
        local placer = held and U.placer(pos)
        if placer then T7.toy(placer, "stasis") end
    end
end)

return GR
