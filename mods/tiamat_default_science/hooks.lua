-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- One of each engine hook for the whole mod, with subscribers.
--
-- The engine keeps ONE callback per hook per mod — two for `on_use`, one
-- listed and one not — and refuses a second. So every file that wants a
-- chat word, a use or a tick subscribes here, and this file holds the
-- engine's registrations. They are made at the end of init.lua
-- (`tds.hooks.install`), once every file has said what it wants to hear.

local H = {}

local words = {}
local uses = {}
local listed = {}
local listed_materials = {}
local places = {}
local digs = {}
local dig_starts = {}
local moves = {}
local ticks = {}
local dialogs = {}
local actions = {}
local joins = {}
local leaves = {}

--- The players connected now, by UUID. Kept from join and leave, so a tick
--- walks the people who are here rather than asking the engine each time.
tds.online = {}

--- The space each connected player is in, by UUID: nil until their first
--- move, which is the overworld's answer anyway. A body's own table does not
--- say, and a placement does not either, so this is how a cairn knows where
--- it stands.
tds.domain_of = {}

--- The ticks this mod has seen since the server started: a clock for things
--- that last a few seconds (a crank turned, a fuse lit). Not saved.
tds.now = function() return 0 end

--- Runs `fn(player, rest)` when a player says `word` (case-insensitive),
--- alone or followed by more words. A string `fn` answers is its reply, said
--- to the speaker alone; `false` lets the line through to chat; anything
--- else swallows it.
function tds.on_chat(word, fn)
    assert(not words[word], "chat word registered twice: " .. word)
    words[word] = fn
end

--- Runs `fn(event)` when a player uses a block, or uses at nothing (`e.x`
--- nil). Answer a string (`""` for silence) to handle it; the first to
--- answer stops the rest. Subscribers are asked in the order they subscribed.
function tds.on_use(fn)
    uses[#uses + 1] = fn
end

--- Runs `fn(event)` for a use at one of `materials` (qualified ids), asked
--- BEFORE any mod's unlisted handler: a burning glass held to a laid fire
--- is for the glass, not for the fire's box. Materials nobody registered are
--- skipped. Answer as `tds.on_use` does; `nil` lets every other mod be asked.
function tds.on_use_at(materials, fn)
    for _, id in ipairs(materials) do
        if tds.util.material(id) then listed_materials[#listed_materials + 1] = id end
    end
    listed[#listed + 1] = fn
end

--- Runs `fn(event)` before a block is placed. It watches: this mod refuses
--- no placement, so what `fn` answers is ignored.
--- Runs `fn(event)` when a dig BEGINS. Answer as the engine's veto does
--- (`false`, a string, `""` refuse); the first to answer stops the rest.
function tds.on_dig_start(fn)
    dig_starts[#dig_starts + 1] = fn
end

--- Runs `fn(event)` when a player's feet cross into another block: the
--- engine's move event, after `tds.domain_of` has heard it.
function tds.on_move(fn)
    moves[#moves + 1] = fn
end

function tds.on_place(fn)
    places[#places + 1] = fn
end

--- Runs `fn(event)` when a dig is about to remove a block. It watches:
--- this mod refuses no dig, so what `fn` answers is ignored. The block is
--- still there when it runs, and a later mod may yet refuse the dig.
function tds.on_dig(fn)
    digs[#digs + 1] = fn
end

--- Runs `fn(tick)` every `period` ticks.
function tds.on_tick(period, fn)
    ticks[#ticks + 1] = { period = period, fn = fn }
end

--- Registers the action `id` (this mod's, unqualified) with a suggested
--- key, and runs `fn(player)` when a player presses whatever key they bound
--- to it. The engine owns the keys (charter rule 11): this mod never reads
--- one.
function tds.on_action(id, default_key, description, fn)
    game.register_action{ id = id, default_key = default_key, description = description }
    actions[game.mod_id .. ":" .. id] = fn
end

--- Runs `fn(event)` for events from the dialog this mod showed as `form`.
function tds.on_dialog(form, fn)
    dialogs[game.mod_id .. ":" .. form] = fn
end

function tds.on_join(fn)
    joins[#joins + 1] = fn
end

function tds.on_leave(fn)
    leaves[#leaves + 1] = fn
end

local function first_verdict(list, event)
    for _, fn in ipairs(list) do
        local verdict = fn(event)
        if verdict ~= nil then return verdict end
    end
    return nil
end

--- Makes the engine registrations. Called once, last thing in init.lua.
function H.install()
    game.register_on_chat(function(event)
        local first, rest = string.match(event.text, "^%s*(%S+)%s*(.*)$")
        if first == nil then return end
        local fn = words[string.lower(first)]
        if fn == nil then return end
        local verdict = fn(event.player, rest)
        if verdict == false then return end
        if type(verdict) == "string" and verdict ~= "" then return verdict end
        return false
    end)

    -- `anywhere`: the Theatrum is read, and the compass followed, wherever
    -- the player looks.
    game.register_on_use(function(event) return first_verdict(uses, event) end, { anywhere = true })
    if #listed_materials > 0 then
        game.register_on_use(function(event) return first_verdict(listed, event) end,
            { materials = listed_materials })
    end

    game.register_on_place(function(event)
        for _, fn in ipairs(places) do fn(event) end
        return nil
    end)

    if #dig_starts > 0 then
        game.register_on_dig_start(function(event) return first_verdict(dig_starts, event) end)
    end

    game.register_on_dig_complete(function(event)
        for _, fn in ipairs(digs) do fn(event) end
        return nil
    end)

    local now = 0
    tds.now = function() return now end
    game.register_on_tick(function(dt)
        for _ = 1, dt do
            now = now + 1
            for _, t in ipairs(ticks) do
                if now % t.period == 0 then t.fn(now) end
            end
        end
    end)

    -- A press, not the release: an action here is a thing done once.
    game.register_on_action(function(event)
        local fn = actions[event.id]
        if fn and event.pressed then fn(event.player) end
    end)

    game.register_on_dialog_event(function(event)
        local fn = dialogs[event.form]
        if fn then fn(event) end
    end)

    game.register_on_player_join(function(event)
        tds.online[event.player] = true
        for _, fn in ipairs(joins) do fn(event) end
    end)

    game.register_on_player_move(function(event)
        tds.domain_of[event.player] = event.domain
        for _, fn in ipairs(moves) do fn(event) end
    end)

    game.register_on_player_leave(function(event)
        tds.online[event.player] = nil
        tds.domain_of[event.player] = nil
        for _, fn in ipairs(leaves) do fn(event) end
    end)
end

return H
