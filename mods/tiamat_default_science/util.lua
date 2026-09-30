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

--- A sorted copy of a table's keys.
function U.sorted_keys(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

return U
