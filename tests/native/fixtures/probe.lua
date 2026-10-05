-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- A mod loaded after Tiamat Default Science that asks the siblings what
-- they see, the way any mod would: through their exports. `t ...` in chat.
--
--   t nodes              the Bench's nodes Progress knows, as id/tier/cost
--   t has <node>         whether the speaker holds it
--   t award <n>          insight, as another mod's milestone
--   t learn <node>       Progress's unlock, paid in insight
--   t insight            the speaker's insight
--   t can <recipe>       Craft's `can`, by hand
--   t make <recipe>      Craft's `perform`, by hand
--   t science            this mod's export version
--   t glyph <id>         how many orientations of a glyph this mod exports
--   t glyph_of <mask>    what Craft says a mask is carved to
--   t path               the speaker's path, or nil
--   t count              how many science nodes Progress validated
--   t effects <prefix>   the speaker's summed effects, "key=value" sorted
--   t branch <node>      the branch Progress holds for a node
--   t ours               how many Craft recipes carry this mod's id
--   t net <x> <y> <z>    this mod's network there: supply/demand/size
--   t ground <x> <z>     the world's ground height there, as generated
--   t ignite <x> <y> <z> Craft lights the station there, for the speaker
--   t progress <ticks> <container>  Craft's add_progress on a container
--   t drop <x> <y> <z>   Life drops a block of stone there, as a dug block falls

local p = game.exports("tiamat_default_progress")
local c = game.exports("tiamat_default_craft")
local s = game.exports("tiamat_default_science")
assert(p and c and s, "the probe sees Progress, Craft and Science")

local BENCH = {
    ["shared.theatrum"] = true, ["shared.sundial"] = true, ["shared.burning_glass"] = true,
    ["shared.kite"] = true, ["shared.compass"] = true,
}

game.register_on_chat(function(e)
    local word, rest = string.match(e.text, "^t (%S+)%s*(.*)$")
    if not word then return end
    local say
    if word == "nodes" then
        local ids = {}
        for _, n in ipairs(p.nodes()) do
            if BENCH[n.id] then ids[#ids + 1] = n.id .. "/" .. n.tier .. "/" .. n.cost end
        end
        say = table.concat(ids, " ")
    elseif word == "has" then
        say = tostring(p.has(e.player, rest))
    elseif word == "award" then
        say = tostring(p.award(e.player, math.tointeger(tonumber(rest)), "a probe"))
    elseif word == "learn" then
        local ok, why = p.unlock(e.player, rest)
        say = tostring(ok) .. (why and (" " .. why) or "")
    elseif word == "insight" then
        say = tostring(p.insight(e.player))
    elseif word == "can" then
        local ok, why = c.can(e.player, rest)
        say = tostring(ok) .. (why and (" " .. why) or "")
    elseif word == "make" then
        local ok, why = c.perform(e.player, rest)
        say = ok and "made" or ("not " .. tostring(why))
    elseif word == "science" then
        say = tostring(s.version)
    elseif word == "glyph" then
        local g = s.glyphs[rest]
        say = g and tostring(#g.variants) or "none"
    elseif word == "path" then
        say = tostring(p.path(e.player))
    elseif word == "count" then
        local n = 0
        for _, node in ipairs(p.nodes()) do
            if node.path == "science" then n = n + 1 end
        end
        say = tostring(n)
    elseif word == "effects" then
        local fx = p.effects_of(e.player, rest ~= "" and rest or nil)
        local keys = {}
        for k in pairs(fx) do keys[#keys + 1] = k end
        table.sort(keys)
        for i, k in ipairs(keys) do keys[i] = k .. "=" .. fx[k] end
        say = table.concat(keys, " ")
    elseif word == "branch" then
        say = "none"
        for _, node in ipairs(p.nodes()) do
            if node.id == rest then say = tostring(node.branch) .. "/" .. tostring(node.reveal) end
        end
    elseif word == "ours" then
        local n = 0
        for _, r in ipairs(c.recipes()) do
            if string.sub(r.id, 1, 23) == "tiamat_default_science:" then n = n + 1 end
        end
        say = tostring(n)
    elseif word == "net" then
        local x, y, z = string.match(rest, "^(-?%d+) (-?%d+) (-?%d+)$")
        local n = s.network_at({ x = math.tointeger(tonumber(x)), y = math.tointeger(tonumber(y)),
            z = math.tointeger(tonumber(z)) })
        say = n and string.format("%d/%d/%d", n.supply, n.demand, n.size) or "none"
    elseif word == "ground" then
        -- The ground's height as the world generated it: y + blocks under it.
        local w = game.exports("tiamat_default_world")
        local x, z = string.match(rest, "^(-?%d+) (-?%d+)$")
        x, z = math.tointeger(tonumber(x)), math.tointeger(tonumber(z))
        local d = w and w.depth_under and w.depth_under(x, 0, z)
        say = d and tostring(math.floor(d)) or "none"
    elseif word == "ignite" then
        local x, y, z = string.match(rest, "^(-?%d+) (-?%d+) (-?%d+)$")
        local ok, why = c.ignite({ x = math.tointeger(tonumber(x)), y = math.tointeger(tonumber(y)),
            z = math.tointeger(tonumber(z)) }, e.player)
        say = tostring(ok) .. (why and (" " .. why) or "")
    elseif word == "progress" then
        local ticks, name = string.match(rest, "^(%d+) (.+)$")
        say = tostring(c.add_progress(name, math.tointeger(tonumber(ticks))))
    elseif word == "drop" then
        local life = game.exports("tiamat_default_life")
        local x, y, z = string.match(rest, "^(-?%d+) (-?%d+) (-?%d+)$")
        local id = life and life.drop({ x = tonumber(x) + 0.5, y = tonumber(y) + 0.5, z = tonumber(z) + 0.5 },
            { material = "tiamat_default_world:stone", count = 1 })
        say = tostring(id)
    elseif word == "glyph_of" then
        say = tostring(c.glyph_of(math.tointeger(tonumber(rest))))
    end
    game.chat_to(e.player, say or "?")
    return false
end)
