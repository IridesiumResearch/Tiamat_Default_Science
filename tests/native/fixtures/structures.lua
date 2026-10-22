-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- A stand-in for Tiamat Default Structures, loaded as
-- `tiamat_default_structures` before this mod: the contract of its brief §4
-- as of 2026-10-22, before Structures has built it, and nothing more. It
-- places nothing; it keeps what is registered, checks it, and lets a test
-- say that a player found a site. `st ...` in chat.
--
--   st kinds             the kinds registered, by id, in order
--   st check             every kind's blocks and loot are registered ids,
--                        every chest stands in its place, and `build` lays
--                        the same blocks as `blocks`; "ok" or what is wrong
--   st loot <tag>        how many entries a loot tag holds
--   st found <kind>      the speaker finds a site of that kind

local kinds, order, loot, found = {}, {}, {}, {}

local function known(id)
    return type(id) == "string" and pcall(game.get_block_id, id)
end

local structures = { version = 1 }

function structures.register(spec)
    local id = game.mod_id .. ":" .. spec.id
    -- An export runs in its owner's sandbox, so the caller's id comes from
    -- the kind's own tags here; Science names itself in them.
    for _, tag in ipairs(spec.tags or {}) do
        if tag == "science" then id = "tiamat_default_science:" .. spec.id end
    end
    if kinds[id] then return false, "already registered" end
    kinds[id] = spec
    order[#order + 1] = id
    return true
end

function structures.add_loot(tag, entry)
    loot[tag] = loot[tag] or {}
    table.insert(loot[tag], entry)
end

function structures.on_found(fn)
    found[#found + 1] = fn
end

game.export(structures)

local function check()
    for _, id in ipairs(order) do
        local spec = kinds[id]
        local cells, laid = {}, 0
        for _, b in ipairs(spec.blocks) do
            if not known(b[4]) then return id .. ": no block " .. tostring(b[4]) end
            for i = 1, 3 do
                if math.type(b[i]) ~= "integer" or b[i] < 0 or b[i] > 31 then
                    return id .. ": a block outside 0..31: " .. table.concat({ b[1], b[2], b[3] }, ",")
                end
            end
            cells[b[1] .. "," .. b[2] .. "," .. b[3]] = b[4]
        end
        for _, c in ipairs(spec.chests or {}) do
            local key = c[1] .. "," .. c[2] .. "," .. c[3]
            if cells[key] then return id .. ": a chest in a wall at " .. key end
            if not loot[c.loot] then return id .. ": a chest with no loot under " .. tostring(c.loot) end
        end
        local B = {}
        function B.set(x, y, z, block)
            if cells[x .. "," .. y .. "," .. z] ~= block then laid = -1 end
            if laid >= 0 then laid = laid + 1 end
        end
        spec.build(B)
        if laid ~= #spec.blocks then return id .. ": build and blocks disagree" end
    end
    for tag, entries in pairs(loot) do
        for _, e in ipairs(entries) do
            if not known(e.material) then return tag .. ": no material " .. tostring(e.material) end
            if not (e.min >= 1 and e.max >= e.min and e.weight > 0) then return tag .. ": a bad entry" end
        end
    end
    return "ok"
end

game.register_on_chat(function(e)
    local word, rest = string.match(e.text, "^st (%S+)%s*(.*)$")
    if not word then return end
    local say
    if word == "kinds" then
        say = table.concat(order, " ")
    elseif word == "check" then
        say = check()
    elseif word == "loot" then
        say = tostring(#(loot[rest] or {}))
    elseif word == "found" then
        for _, fn in ipairs(found) do fn(e.player, { id = "overworld@0,64,0", kind = rest, tags = {} }) end
        say = "found"
    end
    if say then game.chat_to(e.player, say) end
    return false
end)
