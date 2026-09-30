-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The printing press (brief §6.6): a frame with the press movement and its
-- placer's notebook prints treatises, each signed with who printed it. A
-- player who reads one printed by somebody else learns from it once per
-- author, up to a cap — sharing what you know helps new players of either
-- path, which was the historical point of the press.
--
-- Craft makes the treatise plain; this file signs it where it lies, in the
-- frame's output slot, by taking the plain one and giving back one whose
-- detail names its author. A signed treatise never stacks with another's.

local C = tds.config
local U = tds.util
local A = tds.apprentice
local I = tds.items

local PR = {}

local craft = U.exports("tiamat_default_craft")
local progress = U.exports("tiamat_default_progress")

local TREATISE = I.ids.treatise
local PRINT = U.id("print_treatise")

--- An author's mark: the first eight hex characters of their UUID.
function PR.mark(uuid)
    return string.sub(uuid, 1, 8)
end

if craft then
    craft.on_crafted(function(uuid, recipe_id, _, container)
        if recipe_id ~= PRINT or not (container and uuid) then return end
        -- The plain one Craft just gave, in an output slot (6 to 9): taken
        -- from that slot and given back, signed, into the same one.
        for _, stack in ipairs(game.container(container) or {}) do
            if stack.material == TREATISE and stack.detail == nil and stack.slot >= 6 then
                if game.container_take(container, { material = TREATISE, count = 1, slot = stack.slot }) >= U.UNITS then
                    game.container_give(container, { material = TREATISE, count = 1, slot = stack.slot,
                        detail = "a=" .. PR.mark(uuid) })
                end
                return
            end
        end
    end)
end

if progress then
    progress.register_discovery{ id = A.READ .. ":*", insight = C.reading.insight, label = "Read a treatise by %s",
        group = "reading" }
end

local function read_key(uuid) return "read:" .. uuid end

tds.on_use(function(e)
    if not (e.held and e.held.material == TREATISE) then return nil end
    local author = e.held.detail and string.match(e.held.detail, "a=(%x+)")
    if not author then return "The pages are blank: it was never signed." end
    if author == PR.mark(e.player) then return "You wrote this one." end
    local read = game.storage.get(read_key(e.player)) or 0
    if read >= C.reading.cap then return "You have learned all that treatises can teach you." end
    if progress and progress.discover(e.player, A.READ .. ":" .. author) then
        game.storage.set(read_key(e.player), read + 1)
        return ""
    end
    return "You have read this author before."
end)

return PR
