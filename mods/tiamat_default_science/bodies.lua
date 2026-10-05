-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The worlds at the stars, and the Deep (brief §6.8).
--
-- **A body** is made for a star when someone folds to it: an instance of one
-- of five templates, chosen by the star's warmth — ice, rust, regolith,
-- basalt, glass — and made at the star's place in the universe, so the sky
-- from it is that star's. Its key is `<star id>_<size>`, the size chosen by
-- the star's magnitude, so its generator reads everything it needs from
-- `pos.domain`: a disc of barren ground, 1,000 to 3,000 blocks across, air
-- beyond. Every body is barren. Science reaches worlds; it does not make them.
--
-- **Terraforming** greens a body: a frame with the terraformer, on charge,
-- turns the ground round it to grass a column at a time. When enough of a
-- body is green it is living, and an atmosphere processor may give it a sky.
--
-- **The Deep** is a misfold: one registered domain, fragments of rock in a
-- void, no stars. It is `fold.lua` that sends people there and back.
--
-- Every field is compiled once, here, at load (AGENTS.md §5), and the
-- generators run in the workers on nothing but `pos`.

local C = tds.config
local U = tds.util
local N = tds.networks
local Q = tds.grid
local T7 = tds.tier7

local BO = {}

local function block_id(short)
    return game.get_block_id(U.id(short))
end

-- The fields -------------------------------------------------------------------------

local function k(v) return { op = "const", value = v } end
local function op(name, a, b) return { op = name, a = a, b = b } end

--- A body's ground: a rolling surface `height` high, `rough` deep, falling
--- away past `radius` from the centre so the disc has an edge.
local function body_field(kind, radius)
    local surface = op("add", k(kind.height), {
        op = "noise2", stream = "body_" .. kind.id, frequency = 0.008, octaves = 4, amplitude = kind.rough,
    })
    if kind.id == "regolith" then
        -- Craters: rings where a second noise crosses zero, pressed in.
        local ring = op("abs", { op = "noise2", stream = "craters", frequency = 0.02, octaves = 2 })
        surface = op("sub", surface, op("mul", k(4), op("sub", k(1), ring)))
    end
    local x2 = op("mul", { op = "x" }, { op = "x" })
    local z2 = op("mul", { op = "z" }, { op = "z" })
    local beyond = op("mul", op("sub", op("add", x2, z2), k(radius * radius)), k(1 / radius))
    local edge = { op = "clamp", a = beyond, low = 0, high = 400 }
    return game.density(op("sub", op("sub", surface, { op = "y" }), edge))
end

BO.kinds = {}               -- kind id -> its config, with its fields by size
BO.TEMPLATE = {}            -- kind id -> its template's qualified id

for _, kind in ipairs(C.bodies.kinds) do
    local fields = {}
    for size, s in ipairs(C.bodies.sizes) do fields[size] = body_field(kind, s.radius) end
    BO.kinds[kind.id] = { spec = kind, fields = fields }
    BO.TEMPLATE[kind.id] = U.id("body_" .. kind.id)
end

-- A body's key is `<star>_<size>`: everything its generator needs.
local function size_of(domain)
    local size = string.match(domain or "", "_(%d+)$")
    size = size and math.tointeger(tonumber(size))
    if not size or not C.bodies.sizes[size] then return 1 end
    return size
end

for _, kind in ipairs(C.bodies.kinds) do
    local top, under, deep = block_id(kind.top), block_id(kind.under), block_id(kind.deep)
    local fields = BO.kinds[kind.id].fields
    game.register_domain{
        id = "body_" .. kind.id,
        instanced = true,
        generator = function(buf, pos)
            local field = fields[size_of(pos.domain)]
            if field:bounds(pos).all_empty then return end
            buf:fill_palette(field, {
                { above = 0.0, material = top },
                { above = 1.0, material = under },
                { above = 5.0, material = deep },
            }, { detail = "smooth" })
        end,
    }
    game.register_sky{
        domain = BO.TEMPLATE[kind.id],
        day_length_ticks = 24000,
        keyframes = {
            { time = 0.0, sky = { 0.0, 0.0, 0.02 }, sun = { 0.0, 0.0, 0.0 }, intensity = 0.05, stars = 1.0 },
            { time = 0.25, sky = kind.sky, sun = kind.sun, intensity = 0.6, stars = 0.4 },
            { time = 0.5, sky = kind.sky, sun = kind.sun, intensity = 1.0, stars = 0.2 },
            { time = 0.75, sky = kind.sky, sun = kind.sun, intensity = 0.6, stars = 0.4 },
        },
    }
end

-- The sky a living body is given.
BO.LIVING_SKY = { keyframes = {
    { time = 0.0, sky = { 0.02, 0.03, 0.08 }, sun = { 0.0, 0.0, 0.0 }, intensity = 0.08, stars = 1.0 },
    { time = 0.25, sky = { 0.9, 0.6, 0.45 }, sun = { 1.0, 0.75, 0.5 }, intensity = 0.7 },
    { time = 0.5, sky = { 0.45, 0.65, 0.95 }, sun = { 1.0, 0.97, 0.9 }, intensity = 1.0 },
    { time = 0.75, sky = { 0.9, 0.55, 0.4 }, sun = { 1.0, 0.7, 0.45 }, intensity = 0.7 },
} }

--- The kind of body a star makes, by its warmth, and its size by its
--- magnitude: `kind id, size index, gravity`.
function BO.kind_for(star)
    local kind = C.bodies.kinds[#C.bodies.kinds].id
    for _, k in ipairs(C.bodies.kinds) do
        if star.warmth < k.below then kind = k.id break end
    end
    local size = #C.bodies.sizes
    for i, s in ipairs(C.bodies.sizes) do
        if star.magnitude < s.below then size = i break end
    end
    return kind, size, C.bodies.sizes[size].gravity
end

--- The body made for a star: its domain id (made now if it is new), and its
--- gravity.
function BO.body_for(star)
    local kind, size, gravity = BO.kind_for(star)
    local id = game.create_domain(BO.TEMPLATE[kind], tostring(star.id) .. "_" .. size,
        { position = { x = star.x, y = star.y, z = star.z } })
    return id, gravity, kind
end

--- Whether `domain` is a body, and if so its star's id and its gravity.
function BO.parse(domain)
    if type(domain) ~= "string" then return nil end
    local kind, star, size = string.match(domain, "^" .. game.mod_id .. ":body_(%a+)/(%d+)_(%d+)$")
    if not kind then return nil end
    size = math.tointeger(tonumber(size))
    local s = C.bodies.sizes[size or 1] or C.bodies.sizes[1]
    return { kind = kind, star = math.tointeger(tonumber(star)), gravity = s.gravity }
end

-- The Deep ---------------------------------------------------------------------------------

do
    local R = C.deep.platform
    local frag = op("sub", { op = "noise", stream = "deep", frequency = 0.04, octaves = 3,
        stretch = { x = 2, z = 2 } }, k(0.45))
    -- Fragments only in a band about the middle: nothing above 48 or below -48.
    local band = op("mul", op("sub", k(48), op("abs", { op = "y" })), k(0.05))
    local floating = op("min", frag, band)
    -- The fragment you arrive on, always there.
    local platform = op("min", op("min", op("sub", k(R), op("abs", { op = "x" })), op("sub", k(R), op("abs", { op = "z" }))),
        op("min", op("add", { op = "y" }, k(2)), op("sub", k(0.5), { op = "y" })))
    BO.DEEP_FIELD = game.density(op("max", floating, platform))
end

BO.DEEP = U.id("deep")
do
    local rock = {}
    for i, short in ipairs(C.deep.rock) do rock[i] = block_id(short) end
    game.register_domain{
        id = "deep",
        generator = function(buf, pos)
            if BO.DEEP_FIELD:bounds(pos).all_empty then return end
            buf:fill_palette(BO.DEEP_FIELD, {
                { above = 0.0, material = rock[1] },
                { above = 0.15, material = rock[2] },
                { above = 0.3, material = rock[3] },
            }, { detail = "smooth" })
        end,
    }
    game.register_sky{
        domain = BO.DEEP,
        day_length_ticks = 24000,
        keyframes = {
            { time = 0.0, sky = C.deep.sky, sun = C.deep.sun, intensity = 0.15, stars = 0.0 },
        },
    }
end

-- Terraforming ------------------------------------------------------------------------------

local FRAMES = "tiamat_default_craft:" .. game.mod_id .. ":frame:"
local GREEN = {}
for i, short in ipairs(C.terraform.green) do GREEN[i] = U.id(short) end
local PLANTS = {}
for i, short in ipairs(C.terraform.plants) do PLANTS[i] = U.id(short) end
local BARREN = {}           -- the materials a terraformer will green
for _, kind in ipairs(C.bodies.kinds) do
    for _, short in ipairs({ kind.top, kind.under }) do
        local m = U.material(U.id(short))
        if m then BARREN[m] = true end
    end
end

local cursor = {}           -- frame key -> the column it greens next

local function green_key(domain) return "green:" .. domain end
local function living_key(domain) return "living:" .. domain end

--- Whether a body is living: enough of it green.
function BO.living(domain)
    return game.storage.get(living_key(domain)) == true
end

local function threshold()
    return C.terraform.region * C.terraform.region * C.terraform.living_share // 100
end

--- Greens one column round the terraformer at `pos`: the barren top made
--- grass with earth under it, and now and then a plant. Answers whether a
--- column was greened.
function BO.green_one(pos)
    local key = U.key(pos)
    local side = 2 * C.terraform.half
    local n = cursor[key] or 0
    for _ = 1, side * side do
        local x = pos.x - C.terraform.half + n % side
        local z = pos.z - C.terraform.half + n // side
        n = (n + 1) % (side * side)
        local top = game.surface_at{ x = x, z = z, from = pos.y + side, depth = 2 * side, domain = pos.domain }
        if top and BARREN[top.material] then
            cursor[key] = n
            local at = { x = x, y = top.y, z = z, domain = pos.domain }
            game.set_block(at, GREEN[#GREEN])
            game.set_block({ x = x, y = top.y - 1, z = z, domain = pos.domain }, GREEN[1])
            if n % C.terraform.plant_every == 0 then
                game.set_block({ x = x, y = top.y + 1, z = z, domain = pos.domain }, PLANTS[n % #PLANTS + 1])
            end
            local done = (game.storage.get(green_key(pos.domain)) or 0) + 1
            game.storage.set(green_key(pos.domain), done)
            if done >= threshold() and not BO.living(pos.domain) then
                game.storage.set(living_key(pos.domain), true)
                local placer = U.placer(pos)
                if placer then T7.toy(placer, "living") end
            end
            return true
        end
    end
    cursor[key] = n
    return false
end

local function frames_on_bodies(movement)
    local list = {}
    for _, name in ipairs(game.containers(FRAMES)) do
        if N.movement(name) == movement then
            local pos = U.station_pos(name, "frame")
            if pos and BO.parse(pos.domain) and Q.powered(pos) > 0 then list[#list + 1] = pos end
        end
    end
    return list
end

tds.on_tick(C.terraform.period, function()
    for _, pos in ipairs(frames_on_bodies("terraformer")) do BO.green_one(pos) end
    for _, pos in ipairs(frames_on_bodies("atmosphere_processor")) do
        local key = "sky:" .. pos.domain
        if BO.living(pos.domain) and not game.storage.get(key) and game.set_domain_sky(pos.domain, BO.LIVING_SKY) then
            game.storage.set(key, true)
            local placer = U.placer(pos)
            if placer then T7.toy(placer, "atmosphere") end
        end
    end
end)

return BO
