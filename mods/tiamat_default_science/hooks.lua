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
local places = {}
local ticks = {}
local dialogs = {}
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

--- Runs `fn(event)` before a block is placed. It watches: this mod refuses
--- no placement, so what `fn` answers is ignored.
function tds.on_place(fn)
    places[#places + 1] = fn
end

--- Runs `fn(tick)` every `period` ticks.
function tds.on_tick(period, fn)
    ticks[#ticks + 1] = { period = period, fn = fn }
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

    game.register_on_place(function(event)
        for _, fn in ipairs(places) do fn(event) end
        return nil
    end)

    local now = 0
    game.register_on_tick(function(dt)
        for _ = 1, dt do
            now = now + 1
            for _, t in ipairs(ticks) do
                if now % t.period == 0 then t.fn(now) end
            end
        end
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
    end)

    game.register_on_player_leave(function(event)
        tds.online[event.player] = nil
        tds.domain_of[event.player] = nil
        for _, fn in ipairs(leaves) do fn(event) end
    end)
end

return H
