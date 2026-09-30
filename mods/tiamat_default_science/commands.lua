-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- `science`, in chat. For anyone: `science` says how far along the Bench
-- the speaker is; `science book` opens the Theatrum for a player who carries
-- one. A sentence that only begins with the word is chat.

local C = tds.config
local A = tds.apprentice
local P = tds.primer

tds.on_chat("science", function(player, rest)
    local word = string.lower(rest)
    if word == "" then
        local held = 0
        for _, node in ipairs(C.bench_nodes) do
            if A.has(player, node.id) then held = held + 1 end
        end
        return string.format("The Tinker's Bench: %d of %d learned.", held, #C.bench_nodes)
    elseif word == "book" then
        if not P.carries(player) then
            return "You have no Theatrum. Make one by hand: leather, two bark strips, charcoal."
        end
        P.open(player)
        return nil
    end
    return false
end)

return {}
