-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The clockwork automaton (brief §6.6; al-Jazari, Vaucanson, Jaquet-Droz): a
-- helper wound up from a spring, that follows its maker and carries what it
-- is given in a hold of 27 slots.
--
-- **Its program is cards.** The first slots of its hold are read as punched
-- cards (`glyph_table.lua`), each an instruction:
--
--   1 follow    keep near its maker            4 collect  frames' outputs into the hold
--   2 stay      stand where it is              5 deposit  the hold into a chest
--   3 feed      the hold into frames' inputs   6 fetch    a chest into the hold
--
-- Only the first card is read until its maker learns the Analytical Engine;
-- then the first four, one after another, an instruction every `step` ticks —
-- a program, which is what Lovelace saw in Babbage's cards. No card is
-- "follow". It works the frames and chests within `reach` of where it stands.
--
-- **Gravitic automata** (tier 7): one wound by a maker who knows them has no
-- body to fall with. It flies — following its maker a few blocks over their
-- head — and works frames and chests further off.
--
-- **Who it is** rides in its nametag ("Automaton 12"): an entity's id is
-- not promised to survive a restart, and its nametag is. The serial keys its
-- maker and its hold (`tiamat_default_science:hold:<serial>`).

local C = tds.config
local U = tds.util
local G = tds.glyphs
local I = tds.items

local AU = {}

local progress = U.exports("tiamat_default_progress")

local A = C.automaton
local SPRING = I.ids.automaton_spring
local KEY = I.ids.automaton_key
local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local CHESTS = "tiamat_default_craft:chest:"
local FIRST_CARGO = A.program_slots + 1

local function hold_of(serial) return game.mod_id .. ":hold:" .. serial end
local function owner_key(serial) return "automaton:" .. serial end

--- An automaton's serial, from its entity, or nil for any other entity.
function AU.serial(id)
    local ent = game.entity(id)
    local n = ent and ent.nametag and string.match(ent.nametag, "^Automaton (%d+)$")
    return n and math.tointeger(tonumber(n))
end

--- Whether the automata `maker` winds fly.
local function drones(maker)
    return maker ~= nil and progress ~= nil and progress.has(maker, "science.gravitic_drones") == true
end

--- How many automata `uuid` may have at once.
local function allowed(uuid)
    local extra = 0
    if progress then extra = (progress.effects_of(uuid, "science.") or {})["science.automata"] or 0 end
    return A.per_player + extra
end

local function count_of(uuid)
    local n = 0
    for _, key in ipairs(game.storage.keys("automaton:")) do
        if game.storage.get(key) == uuid then n = n + 1 end
    end
    return n
end

-- Winding one up -------------------------------------------------------------------------

tds.on_use(function(e)
    if not (e.x and e.held and e.held.material == SPRING) then return nil end
    if count_of(e.player) >= allowed(e.player) then return "You have as many automata as you can keep." end
    if game.take(e.player, { material = SPRING, count = 1 }) < U.UNITS then return nil end
    local serial = (game.storage.get("automata") or 0) + 1
    game.storage.set("automata", serial)
    local pos = U.block_of(e)
    local flies = drones(e.player)
    local id = game.spawn_entity{
        pos = { x = pos.x + 0.5, y = pos.y + 1, z = pos.z + 0.5 },
        model = A.model, nametag = "Automaton " .. serial, collider = not flies and A.collider or nil, speed = A.speed,
    }
    if not id then
        game.give(e.player, { material = SPRING, count = 1 })
        return "It will not wind here."
    end
    game.storage.set(owner_key(serial), e.player)
    game.make_container(hold_of(serial), A.hold)
    if flies then
        tds.tier7.toy(e.player, "drone")
        return "Tick, tick, tick: your automaton wakes, and rises."
    end
    return "Tick, tick, tick: your automaton wakes."
end)

-- Its hold, and winding it down ------------------------------------------------------------

game.register_on_use_entity(function(e)
    local serial = AU.serial(e.target)
    if not serial then return nil end
    local maker = game.storage.get(owner_key(serial))
    if maker ~= e.player then return "This automaton is not yours." end
    local hold = hold_of(serial)
    if e.held and e.held.material == KEY then
        for _, stack in ipairs(game.break_container(hold) or {}) do
            game.give(e.player, { material = stack.material, units = stack.units, shape = stack.shape, detail = stack.detail })
        end
        game.despawn_entity(e.target)
        game.storage.set(owner_key(serial), nil)
        game.give(e.player, { material = SPRING, count = 1 })
        return "It winds down, and folds into its spring."
    end
    if not game.open_container(hold, e.player) then return "Somebody is at its hold." end
    game.show_dialog{ player = e.player, form = "hold", tree = {
        type = "container", direction = "column", gap = 6, padding = 8, children = {
            { type = "label", text = "Automaton " .. serial .. ": the first slots are its cards" },
            { type = "item_grid", view = hold, columns = 9, first = 1, count = A.hold },
            { type = "item_grid", view = "player:main", columns = 9, first = 1, count = 27 },
        },
    } }
    return ""
end)

-- Its program -------------------------------------------------------------------------------

--- The instructions in an automaton's hold, in order: words from the cards.
function AU.program(serial, maker)
    local slots = 1
    if maker and progress and progress.has(maker, "science.analytical_engine") then slots = A.program_slots end
    local by_slot = {}
    for _, stack in ipairs(game.container(hold_of(serial)) or {}) do
        if stack.slot <= slots and stack.shape then by_slot[stack.slot] = G.card(stack.shape) end
    end
    local out = {}
    for slot = 1, slots do
        local card = by_slot[slot]
        if card and A.cards[card] then out[#out + 1] = A.cards[card] end
    end
    if #out == 0 then out[1] = "follow" end
    return out
end

local function near(pos, at, reach)
    return math.abs(pos.x + 0.5 - at.x) <= reach and math.abs(pos.y + 0.5 - at.y) <= reach + 1
        and math.abs(pos.z + 0.5 - at.z) <= reach
end

--- Moves one stack from `from`'s slots `a..b` into `to`'s slots `c..d`:
--- whatever does not fit goes back. Answers whether anything moved.
local function move_one(from, a, b, to, c, d)
    for _, stack in ipairs(game.container(from) or {}) do
        if stack.slot >= a and stack.slot <= b then
            local spec = { material = stack.material, units = stack.units, shape = stack.shape, detail = stack.detail,
                slot = stack.slot }
            local took = game.container_take(from, spec)
            if took > 0 then
                local given = 0
                for slot = c, d do
                    if given >= took then break end
                    given = given + game.container_give(to, { material = stack.material, units = took - given,
                        shape = stack.shape, detail = stack.detail, slot = slot })
                end
                if given < took then
                    game.container_give(from, { material = stack.material, units = took - given, shape = stack.shape,
                        detail = stack.detail, slot = stack.slot })
                end
                if given > 0 then return true end
            end
        end
    end
    return false
end

local function nearby(prefix, at, station, reach)
    local list = {}
    for _, name in ipairs(game.containers(prefix)) do
        local xyz = not station and string.match(name, ":(-?%d+,-?%d+,-?%d+)$")
        local pos = station and U.station_pos(name, station) or (xyz and U.unpack(xyz .. ","))
        if pos and near(pos, at, reach) then list[#list + 1] = name end
    end
    return list
end

--- One instruction, done once, by the automaton `id` standing at `at`.
local function toward(from, to, step)
    local d = to - from
    if d > step then return from + step elseif d < -step then return from - step end
    return to
end

function AU.run(id, serial, maker, word, at)
    local hold = hold_of(serial)
    local flies = drones(maker)
    local reach = flies and C.drone.reach or A.reach
    if word == "follow" then
        local body = maker and tds.online[maker] and game.player_entity(maker)
        local me = body and game.entity(body)
        if me and flies then
            local s = C.drone.step
            game.set_entity(id, { pos = { x = toward(at.x, me.pos.x, s), y = toward(at.y, me.pos.y + C.drone.above, s),
                z = toward(at.z, me.pos.z, s) } })
        elseif me and math.abs(me.pos.x - at.x) + math.abs(me.pos.z - at.z) > A.follow then
            game.steer_entity(id, me.pos, "walk")
        end
    elseif word == "feed" then
        for _, frame in ipairs(nearby(FRAMES, at, "frame", reach)) do
            if move_one(hold, FIRST_CARGO, A.hold, frame, 2, 5) then return end
        end
    elseif word == "collect" then
        for _, frame in ipairs(nearby(FRAMES, at, "frame", reach)) do
            if move_one(frame, 6, 9, hold, FIRST_CARGO, A.hold) then return end
        end
    elseif word == "deposit" then
        for _, chest in ipairs(nearby(CHESTS, at, nil, reach)) do
            if move_one(hold, FIRST_CARGO, A.hold, chest, 1, 27) then return end
        end
    elseif word == "fetch" then
        for _, chest in ipairs(nearby(CHESTS, at, nil, reach)) do
            if move_one(chest, 1, 27, hold, FIRST_CARGO, A.hold) then return end
        end
    end
end

local next_at = {}          -- serial -> the tick it next acts
local step_of = {}          -- serial -> where it is in its program

game.register_on_entity_step(function(id)
    local serial = AU.serial(id)
    if not serial then return end
    local now = tds.now()
    if next_at[serial] and now < next_at[serial] then return end
    next_at[serial] = now + A.step
    local maker = game.storage.get(owner_key(serial))
    local ent = game.entity(id)
    if not ent then return end
    local program = AU.program(serial, maker)
    local i = (step_of[serial] or 0) % #program + 1
    step_of[serial] = i
    AU.run(id, serial, maker, program[i], ent.pos)
end)

return AU
