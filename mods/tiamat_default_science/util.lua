-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Small helpers with no opinion about natural philosophy.

local U = {}

--- Units in one item of loose material: an item is a block's worth.
U.UNITS = 27

local PREFIXES = {
    W = "tiamat_default_world",
    L = "tiamat_default_life",
    C = "tiamat_default_craft",
}

--- A qualified id from `config.lua`'s short forms: `"kite"` is this mod's,
--- `"W:sand"` the world's, `"L:wool"` Life's, `"C:glass"` Craft's. A name
--- already qualified with a mod id, or a `#group`, is left alone.
function U.id(name)
    if string.sub(name, 1, 1) == "#" then return name end
    local prefix, rest = string.match(name, "^(%u):(.+)$")
    if prefix then return PREFIXES[prefix] .. ":" .. rest end
    if string.find(name, ":", 1, true) then return name end
    return game.mod_id .. ":" .. name
end

--- Whether `name` is a qualified id, `"mod:thing"`.
function U.qualified(name)
    return type(name) == "string" and #name <= 128 and string.match(name, "^[%a_][%w_]*:[%w_]+$") ~= nil
end

--- A numeric material id for a qualified id, or nil when nothing registered
--- it. `game.get_block_id` errors on an unknown id, which is right for a
--- typo in this mod's own names and wrong for another mod's block that may
--- or may not be there.
function U.material(id)
    if not U.qualified(id) then return nil end
    local ok, material = pcall(game.get_block_id, id)
    if ok then return material end
    return nil
end

--- Another mod's exports at version 1, or nil when it is not loaded.
function U.exports(id)
    local ok, exports = pcall(game.exports, id)
    if ok and type(exports) == "table" and exports.version == 1 then return exports end
    return nil
end

--- A domain as a position carries it: nil for the overworld, which is what
--- a position without one means, and the name for any other space. An event
--- says "overworld" where a position says nothing, so every domain this mod
--- keeps or compares goes through here first.
function U.place(domain)
    if domain == nil or domain == "" or domain == "overworld" then return nil end
    return domain
end

--- The domain a place or dig event happened in, as `U.place` gives it: the
--- event's own (engine E-S4), or, from an engine older than that, the one
--- the player's feet were last heard in.
function U.where(e)
    return U.place(e.domain or tds.domain_of[e.player])
end

--- The block a use or dig event's cell is in.
function U.block_of(e)
    return { x = e.x // 3, y = e.y // 3, z = e.z // 3, domain = U.place(e.domain) }
end

--- A position as one storable string, and back.
function U.pack(pos)
    return string.format("%d,%d,%d,%s", pos.x, pos.y, pos.z, pos.domain or "")
end

function U.unpack(text)
    local x, y, z, domain = string.match(text or "", "^(-?%d+),(-?%d+),(-?%d+),(.*)$")
    if not x then return nil end
    return { x = math.tointeger(tonumber(x)), y = math.tointeger(tonumber(y)), z = math.tointeger(tonumber(z)),
        domain = domain ~= "" and domain or nil }
end

--- Whether a material was registered with `tag`.
function U.tagged(material, tag)
    for _, t in ipairs(material and game.tags(material) or {}) do
        if t == tag then return true end
    end
    return false
end

--- The readable name of a material: its id's last part, spaced
--- ("tiamat_default_world:white_sand" -> "white sand").
function U.name_of(material)
    local id = material and game.block_of(material)
    if not id then return "something unknown" end
    local short = string.match(id, ":([^:]+)$") or id
    return (string.gsub(short, "_", " "))
end

--- A plain copy of data another mod handed over. What crosses an export is
--- a read-only VIEW, which Lua code reads like a table but the engine's own
--- calls do not — `game.show_dialog` sees a view's colour as no numbers at
--- all — so a widget built by the interface is copied before it is shown.
function U.plain(value)
    if type(value) ~= "table" and type(value) ~= "userdata" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = U.plain(v) end
    return out
end

-- Recipes into Craft -------------------------------------------------------------

-- Stations this mod registers: a recipe's `station = "frame"` is ours and is
-- qualified; Craft's own (`hand`, `workbench`, `kiln`, ...) are bare.
U.OWN_STATIONS = { frame = true, furnace = true }

--- One entry of `config.lua`'s recipe lists, in Craft's form: a short id
--- (`"C:glass"`, `"kite"`), `{ "id", count = n }`, `{ "id", units = n }`,
--- `{ "id", wear = n }`, or a glyph, `{ glyph = "gear", material = "#plank",
--- count = n }` — the glyph this mod's.
function U.entry(e)
    if type(e) == "string" then return U.id(e) end
    if e.glyph then
        return { glyph = U.id(e.glyph), material = U.id(e.material), count = e.count, units = e.units, wear = e.wear }
    end
    return { U.id(e[1]), count = e.count, units = e.units, wear = e.wear }
end

local function entries(list)
    if not list then return nil end
    local out = {}
    for i, e in ipairs(list) do out[i] = U.entry(e) end
    return out
end

--- A recipe from `config.lua`, as Craft's `register` takes it.
function U.recipe(r)
    local key = nil
    if r.key then
        key = {}
        for letter, e in pairs(r.key) do key[letter] = U.entry(e) end
    end
    return {
        id = U.id(r.id),
        station = U.OWN_STATIONS[r.station] and U.id(r.station) or r.station,
        inputs = entries(r.inputs),
        pattern = r.pattern,
        key = key,
        outputs = entries(r.outputs),
        tools = entries(r.tools),
        heat = r.heat,
        ticks = r.ticks,
        requires = r.node,
    }
end

--- Registers `list` with Craft, logging any it refuses, and files each by
--- its node into `by_node` (node id -> list of recipes, in order) for the
--- Theatrum. Answers how many were registered.
function U.register_recipes(craft, list, by_node)
    local n = 0
    for _, r in ipairs(list) do
        local ok, why = craft.register(U.recipe(r))
        if ok then
            n = n + 1
            if r.node and by_node then
                by_node[r.node] = by_node[r.node] or {}
                table.insert(by_node[r.node], r)
            end
        else
            game.log("tiamat_default_science: Craft refused the recipe " .. r.id .. ": " .. tostring(why))
        end
    end
    return n
end

--- The block position a Craft container of one of this mod's stations names:
--- `tiamat_default_craft:tiamat_default_science:<station>:[domain@]x,y,z`.
function U.station_pos(name, station)
    local prefix = "tiamat_default_craft:" .. game.mod_id .. ":" .. station .. ":"
    if string.sub(name, 1, #prefix) ~= prefix then return nil end
    local rest = string.sub(name, #prefix + 1)
    local domain, xyz = string.match(rest, "^(.+)@(.+)$")
    xyz = xyz or rest
    local x, y, z = string.match(xyz, "^(-?%d+),(-?%d+),(-?%d+)$")
    if not x then return nil end
    return { x = math.tointeger(tonumber(x)), y = math.tointeger(tonumber(y)), z = math.tointeger(tonumber(z)),
        domain = U.place(domain) }
end

--- The Craft container of one of this mod's stations at `pos`.
function U.station_name(station, pos)
    local at = pos.domain and (pos.domain .. "@") or ""
    return string.format("tiamat_default_craft:%s:%s:%s%d,%d,%d", game.mod_id, station, at, pos.x, pos.y, pos.z)
end

--- A position as a key: `x,y,z` and the domain when it is not the overworld.
function U.key(pos)
    return string.format("%d,%d,%d,%s", pos.x, pos.y, pos.z, pos.domain or "")
end

--- The six blocks beside `pos`.
function U.neighbours(pos)
    return {
        { x = pos.x + 1, y = pos.y, z = pos.z, domain = pos.domain },
        { x = pos.x - 1, y = pos.y, z = pos.z, domain = pos.domain },
        { x = pos.x, y = pos.y + 1, z = pos.z, domain = pos.domain },
        { x = pos.x, y = pos.y - 1, z = pos.z, domain = pos.domain },
        { x = pos.x, y = pos.y, z = pos.z + 1, domain = pos.domain },
        { x = pos.x, y = pos.y, z = pos.z - 1, domain = pos.domain },
    }
end

--- Who placed one of this mod's station blocks at `pos`, or nil (one a plan
--- stamped). Kept by `frame.lua`; read by the networks for a placer's effects.
function U.placer(pos)
    return game.storage.get("placer:" .. U.key(pos))
end

--- A sorted copy of a table's keys.
function U.sorted_keys(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

return U
