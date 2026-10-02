-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Tier 5's devices that are not a frame's recipe (brief §5.3, §6.5, §6.6):
--
--   the safety elevator   a steel rail, steel brackets for landings, and a frame with
--                         a winding drum at the rail's foot; use a landing to ride
--                         to the next one up (from the top, back to the bottom)
--   the daguerreotype     a camera used on two corners of a building, a silvered
--                         plate spent: a photograph that holds the building (a plan)
--   blueprints            a photograph used at a block, by one who knows how,
--                         builds the building again there — paid for in its blocks
--   the telegraph         two keys on one charged wire: `wire <words>` said by one
--                         is heard by everyone standing near the other
--   the electromagnet     held, with a charged cell in the pack: drops fly to you

local C = tds.config
local U = tds.util
local B = tds.blocks
local G = tds.glyphs
local I = tds.items
local N = tds.networks
local Q = tds.grid
local T5 = tds.tier5
local E = tds.electricity

local W = {}

local progress = U.exports("tiamat_default_progress")
local life = U.exports("tiamat_default_life")

local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"

local function holding(e, id)
    return e.held ~= nil and e.held.material == I.ids[id] and e.held.shape == nil
end

local function body_of(uuid)
    local id = game.player_entity(uuid)
    return id and game.entity(id)
end

local function at_pos(x, y, z, domain) return { x = x, y = y, z = z, domain = domain } end

-- The safety elevator -------------------------------------------------------------------

local function is_steel(at, glyph)
    return at ~= nil and at.material == B.steel_stock and G.of(at) == glyph
end

local SIDES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

--- The landings of the rail column at `rail`: every bracket beside it, from
--- its foot up. Answers them and the foot.
function W.landings(rail)
    local foot = rail
    for _ = 1, C.elevator.reach do
        local below = at_pos(foot.x, foot.y - 1, foot.z, foot.domain)
        if not is_steel(game.get_block(below), "rail") then break end
        foot = below
    end
    local landings = {}
    local here = foot
    for _ = 1, C.elevator.reach do
        for _, side in ipairs(SIDES) do
            local p = at_pos(here.x + side[1], here.y, here.z + side[2], here.domain)
            if is_steel(game.get_block(p), "bracket") then landings[#landings + 1] = p end
        end
        local above = at_pos(here.x, here.y + 1, here.z, here.domain)
        if not is_steel(game.get_block(above), "rail") then break end
        here = above
    end
    return landings, foot
end

--- Whether a frame with a turning winding drum stands at the rail's foot.
local function wound(foot)
    for _, p in ipairs(U.neighbours(foot)) do
        local at = game.get_block(p)
        if at and at.material == B.frame and N.movement(U.station_name("frame", p)) == "winding_drum" then
            return N.speed(p, U.placer(p)) > 0
        end
    end
    return false
end

tds.on_use(function(e)
    if not e.x or e.material ~= B.steel_stock then return nil end
    local here = U.block_of(e)
    if not is_steel(game.get_block(here), "bracket") then return nil end
    local rail = nil
    for _, side in ipairs(SIDES) do
        local p = at_pos(here.x + side[1], here.y, here.z + side[2], here.domain)
        if is_steel(game.get_block(p), "rail") then rail = p break end
    end
    if not rail then return "A landing wants a steel rail beside it." end
    local landings, foot = W.landings(rail)
    if not wound(foot) then return "The winding drum at the foot of the rail is not turning." end
    local next = nil
    for _, p in ipairs(landings) do
        if p.y > here.y and (not next or p.y < next.y) then next = p end
    end
    if not next then
        for _, p in ipairs(landings) do
            if p.y < here.y and (not next or p.y < next.y) then next = p end
        end
    end
    if not next then return "This is the only landing." end
    game.move_player(e.player, { x = next.x + 0.5, y = next.y + 1, z = next.z + 0.5 })
    T5.toy(e.player, "elevator")
    return next.y > here.y and "Up you go." or "Down you go."
end)

-- The daguerreotype and blueprints --------------------------------------------------

local corner = {}            -- player -> the first corner their camera marked
local PLATE = I.ids.silvered_plate
local PHOTO = I.ids.photograph

tds.on_leave(function(e) corner[e.player] = nil end)

tds.on_use(function(e)
    if not holding(e, "camera") then return nil end
    if not e.x then return "Point the camera at a corner of what you want to catch." end
    local pos = U.block_of(e)
    local first = corner[e.player]
    if not first or first.domain ~= pos.domain then
        corner[e.player] = pos
        return "One corner. Now the other."
    end
    corner[e.player] = nil
    local lo = { x = math.min(first.x, pos.x), y = math.min(first.y, pos.y), z = math.min(first.z, pos.z), domain = pos.domain }
    local hi = { x = math.max(first.x, pos.x), y = math.max(first.y, pos.y), z = math.max(first.z, pos.z), domain = pos.domain }
    local side = C.camera.max_side
    if hi.x - lo.x >= side or hi.y - lo.y >= side or hi.z - lo.z >= side then
        return string.format("Too big for one plate: %d blocks on a side at most.", side)
    end
    if game.take(e.player, { material = PLATE, count = 1 }) < U.UNITS then return "You need a silvered plate." end
    local n = (game.storage.get("photos:" .. e.player) or 0) + 1
    local name = string.format("photo_%s_%d", string.sub(e.player, 1, 8), n)
    local made, why = game.plans.capture(name, lo, hi)
    if not made then
        game.give(e.player, { material = PLATE, count = 1 })
        return "The picture did not take: " .. tostring(why) .. "."
    end
    game.storage.set("photos:" .. e.player, n)
    game.give(e.player, { material = PHOTO, count = 1, detail = "p=" .. name })
    T5.toy(e.player, "photograph")
    return string.format("Caught: %d blocks.", made.blocks)
end)

tds.on_use(function(e)
    if not (e.held and e.held.material == PHOTO) then return nil end
    local name = e.held.detail and string.match(e.held.detail, "p=([%w_]+)")
    local info = name and game.plans.info(name)
    if not info then return "The picture has faded." end
    if not e.x then return string.format("A picture of a building: %d blocks.", info.blocks) end
    if not (progress and progress.has(e.player, "science.cyanotype")) then
        return "A picture of a building. Learn Blueprints to build it again."
    end
    -- Pay for every block first, all or nothing.
    local taken, short = {}, nil
    for _, id in ipairs(U.sorted_keys(info.materials)) do
        local want = info.materials[id]
        local got = game.take(e.player, { material = id, units = want })
        taken[id] = got
        if got < want and not short then short = { id = id, units = want - got } end
    end
    if short then
        for id, units in pairs(taken) do
            if units > 0 then game.give(e.player, { material = id, units = units }) end
        end
        return string.format("You need %d more of %s.", (short.units + U.UNITS - 1) // U.UNITS,
            string.gsub(string.match(short.id, ":(.+)$") or short.id, "_", " "))
    end
    local at = U.block_of(e)
    game.plans.stamp(name, { x = at.x, y = at.y + 1, z = at.z, domain = at.domain })
    T5.toy(e.player, "blueprint")
    return "The blueprint is building."
end)

-- The telegraph -------------------------------------------------------------------------

local function near(a, b, reach)
    return math.abs(a.x - b.x) <= reach and math.abs(a.y - b.y) <= reach and math.abs(a.z - b.z) <= reach
end

local function keys()
    local list = {}
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == "telegraph" then
            local pos = U.station_pos(name, "frame")
            if pos then list[#list + 1] = pos end
        end
    end
    return list
end

tds.on_chat("wire", function(player, words)
    if words == "" then return "Say 'wire' and your message, by a telegraph key." end
    local body = body_of(player)
    if not body then return nil end
    local me = { x = math.floor(body.pos.x), y = math.floor(body.pos.y), z = math.floor(body.pos.z) }
    local all = keys()
    local mine = nil
    for _, pos in ipairs(all) do
        if pos.domain == U.place(tds.domain_of[player]) and near(pos, me, C.grid.telegraph_reach) then mine = pos break end
    end
    if not mine then return "Stand by a telegraph key." end
    local net = Q.at(mine)
    if not net or Q.powered(mine) <= 0 then return "The wire is dead." end
    local heard = 0
    for _, pos in ipairs(all) do
        if (pos.x ~= mine.x or pos.y ~= mine.y or pos.z ~= mine.z) and Q.at(pos) == net then
            for _, uuid in ipairs(U.sorted_keys(tds.online)) do
                local b = uuid ~= player and body_of(uuid)
                if b and near(pos, { x = math.floor(b.pos.x), y = math.floor(b.pos.y), z = math.floor(b.pos.z) },
                    C.grid.telegraph_hear) then
                    game.chat_to(uuid, "(by wire) " .. words)
                    heard = heard + 1
                end
            end
        end
    end
    T5.toy(player, "telegraph")
    return heard > 0 and "Sent." or "Sent, but nobody is at the other key."
end)

-- The electromagnet ----------------------------------------------------------------------

local CELL = I.ids.cell
local MAGNET = I.ids.electromagnet
local drawn = {}             -- player -> ticks the magnet has drawn since the cell paid

--- A charged cell in a player's pack, or nil.
local function charged_cell(uuid)
    for _, view in ipairs({ "player:hotbar", "player:main" }) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            if stack.material == CELL and E.charge_of(stack) > 0 then return stack end
        end
    end
    return nil
end

tds.on_tick(C.kite.period, function()
    for _, uuid in ipairs(U.sorted_keys(tds.online)) do
        local held = game.held(uuid)
        if held and held.material == MAGNET and life and life.pull_drops then
            local cell = charged_cell(uuid)
            local body = cell and body_of(uuid)
            if body then
                life.pull_drops(body.pos, C.grid.magnet_radius, C.grid.magnet_strength)
                drawn[uuid] = (drawn[uuid] or 0) + C.kite.period
                if drawn[uuid] >= C.grid.period then
                    drawn[uuid] = 0
                    local e = E.charge_of(cell)
                    if game.take(uuid, { material = CELL, count = 1, detail = cell.detail }) >= U.UNITS then
                        local left = e - C.grid.magnet_drain
                        game.give(uuid, { material = CELL, count = 1, detail = left > 0 and ("e=" .. left) or nil })
                    end
                end
            end
        end
    end
end)

tds.on_leave(function(e) drawn[e.player] = nil end)

return W
