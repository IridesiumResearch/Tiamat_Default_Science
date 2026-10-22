-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- Places in the world that belong to natural philosophy: the Antikythera
-- wreck, a philosopher's study, an engine house, the mills, a mine adit, an
-- observatory and a fallen tower (Structures' ask ST-S1). Structures places
-- them, as a pure function of the seed, and says when a player finds one;
-- this file only describes them and pays for finding them.
--
-- Structures is optional: without it this file does nothing, and nothing
-- else in the mod knows it is missing. The world is shared, so a mage finds
-- the same engine house a scientist does; what finding it is worth is the
-- path's (Structures' brief §2).
--
-- Each place is described WHOLE, as a list of blocks; Structures makes the
-- ruin from it with its own seeded decay, and keeps the whole for Science's
-- Blueprints (`plan(id)`). Offsets are from the root: `dy = 0` is the first
-- course above the ground, `+z` the front. Whole blocks, by string id.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local P = {}

local structures = U.exports("tiamat_default_structures")
P.loaded = structures ~= nil

-- The blocks ------------------------------------------------------------------------

local COBBLES, GRANITE, SLATE = U.id("W:cobbles"), U.id("W:granite"), U.id("W:slate")
local LOG, GRAVEL, CLAY = U.id("W:oak_log"), U.id("W:gravel"), U.id("W:pale_terracotta")
local PLANK, BRICK, GLASS = U.id("C:plank"), U.id("C:brick"), U.id("C:glass")
local FRAME, FURNACE, COPPER = U.id("frame"), U.id("furnace"), U.id("copper_stock")

--- A list of blocks, and the few ways a building is laid.
local function list()
    local blocks, at = {}, {}
    local L = {}
    function L.put(x, y, z, id)
        local key = x .. "," .. y .. "," .. z
        if at[key] then blocks[at[key]][4] = id; return end
        blocks[#blocks + 1] = { x, y, z, id }
        at[key] = #blocks
    end
    --- Every cell of a box, inclusive.
    function L.box(x0, y0, z0, x1, y1, z1, id)
        for y = y0, y1 do for z = z0, z1 do for x = x0, x1 do L.put(x, y, z, id) end end end
    end
    --- The four walls of a box, inclusive, and nothing inside.
    function L.walls(x0, y0, z0, x1, y1, z1, id)
        for y = y0, y1 do
            for x = x0, x1 do L.put(x, y, z0, id); L.put(x, y, z1, id) end
            for z = z0 + 1, z1 - 1 do L.put(x0, y, z, id); L.put(x1, y, z, id) end
        end
    end
    --- Takes a cell back out: a door, a window's frame before its glass.
    function L.clear(x, y, z)
        local key = x .. "," .. y .. "," .. z
        local i = at[key]
        if not i then return end
        table.remove(blocks, i)
        at = {}
        for j, b in ipairs(blocks) do at[b[1] .. "," .. b[2] .. "," .. b[3]] = j end
    end
    L.blocks = blocks
    return L
end

-- The places, whole ---------------------------------------------------------------

local BUILD = {}

--- A merchant ship gone down off a headland, as the one off Antikythera did:
--- a keel, a split hull, a snapped mast, amphorae, and a chest in the silt.
function BUILD.wreck()
    local L = list()
    L.box(2, 0, 0, 2, 0, 8, LOG)                     -- the keel
    L.box(1, 0, 1, 3, 0, 7, PLANK)                   -- the bottom
    L.put(2, 0, 0, LOG); L.put(2, 0, 8, LOG)
    L.box(0, 1, 1, 0, 2, 7, PLANK)                   -- the side still standing
    L.box(4, 1, 1, 4, 1, 7, PLANK)                   -- the side broken low
    L.clear(4, 1, 3); L.clear(4, 1, 6)
    L.box(2, 1, 8, 2, 3, 8, LOG)                     -- the stern post
    L.put(2, 1, 4, LOG); L.put(3, 1, 5, LOG)         -- the mast, snapped and fallen
    L.put(1, 1, 6, CLAY); L.put(1, 1, 7, CLAY); L.put(3, 1, 7, CLAY)
    return L.blocks, { { 2, 1, 2, "tiamat_default_science:wreck" } }
end

--- A scholar's house of rubble stone: a plank floor, two glazed windows, a
--- slate roof, and a chest of papers.
function BUILD.study()
    local L = list()
    L.box(1, 0, 1, 5, 0, 5, PLANK)
    L.walls(0, 0, 0, 6, 3, 6, COBBLES)
    L.clear(3, 1, 0); L.clear(3, 2, 0)               -- the door
    L.put(0, 2, 3, GLASS); L.put(6, 2, 3, GLASS)
    L.box(0, 4, 0, 6, 4, 6, SLATE)
    return L.blocks, { { 1, 1, 5, "study" }, { 5, 1, 5, "tiamat_default_science:study" } }
end

--- A Cornish engine house: a tall granite box with the beam's opening high
--- in its front, a brick chimney at the back corner, and inside the furnace
--- and the frame the engine stood on.
function BUILD.engine_house()
    local L = list()
    L.box(1, 0, 1, 3, 0, 5, COBBLES)
    L.walls(0, 0, 0, 4, 8, 6, GRANITE)
    L.clear(2, 1, 6); L.clear(2, 2, 6)               -- the door, at the back
    for x = 1, 3 do L.clear(x, 6, 0); L.clear(x, 7, 0) end   -- the bob wall's opening
    L.box(5, 0, 5, 6, 0, 6, GRANITE)
    L.box(5, 1, 6, 5, 13, 6, BRICK)                  -- the chimney
    L.put(2, 1, 2, FRAME)
    L.put(2, 1, 4, FURNACE)
    return L.blocks, { { 1, 1, 5, "tiamat_default_science:engine_house" } }
end

--- A mill on a bank: a stone base, plank walls over it, a frame inside, and
--- the wheel's rim standing in the stream at its side.
function BUILD.watermill()
    local L = list()
    L.box(2, 0, 1, 4, 0, 5, COBBLES)
    L.walls(1, 0, 0, 5, 1, 6, COBBLES)
    L.walls(1, 2, 0, 5, 3, 6, PLANK)
    L.box(1, 4, 0, 5, 4, 6, PLANK)
    L.clear(3, 1, 6); L.clear(3, 2, 6)
    L.put(3, 1, 3, FRAME)
    for _, c in ipairs({ { 0, 1 }, { 0, 5 }, { 1, 0 }, { 1, 6 }, { 2, 0 }, { 2, 6 }, { 3, 0 }, { 3, 6 },
        { 4, 1 }, { 4, 5 }, { 5, 2 }, { 5, 3 }, { 5, 4 } }) do
        L.put(0, c[1], c[2], LOG)                    -- the wheel, a rim of timber
    end
    return L.blocks, { { 4, 1, 1, "tiamat_default_science:mill" } }
end

--- A tower mill on high ground: a stone tower, a plank cap, sails in a cross
--- on its front, and the frame the sails turned.
function BUILD.windmill()
    local L = list()
    L.box(2, 0, 2, 4, 0, 4, PLANK)
    L.walls(1, 0, 1, 5, 6, 5, COBBLES)
    L.clear(3, 1, 5); L.clear(3, 2, 5)
    L.box(1, 7, 1, 5, 7, 5, PLANK)
    L.put(3, 1, 3, FRAME)
    L.put(3, 6, 0, LOG)                              -- the windshaft
    for d = 1, 3 do                                  -- the sails
        L.put(3, 6 + d, 0, PLANK); L.put(3, 6 - d, 0, PLANK)
        L.put(3 + d, 6, 0, PLANK); L.put(3 - d, 6, 0, PLANK)
    end
    return L.blocks, { { 2, 1, 2, "tiamat_default_science:mill" } }
end

--- A drift into a hillside, propped with timber, and the stamp battery that
--- crushed what came out of it, fallen in.
function BUILD.mine_adit()
    local L = list()
    for z = 0, 9, 3 do                               -- a set of props every three blocks
        L.box(0, 0, z, 0, 1, z, LOG); L.box(2, 0, z, 2, 1, z, LOG)
        L.box(0, 2, z, 2, 2, z, PLANK)
    end
    L.put(1, 0, 10, FRAME)
    L.box(0, 0, 11, 2, 0, 11, GRAVEL); L.put(1, 1, 11, GRAVEL)
    return L.blocks, { { 2, 0, 8, "tiamat_default_science:mine" } }
end

--- A round-shouldered observatory on open ground: granite walls, a dome of
--- slate with a glazed slit, and a chest of glasses.
function BUILD.observatory()
    local L = list()
    L.box(1, 0, 1, 5, 0, 5, GRANITE)
    L.walls(0, 0, 0, 6, 4, 6, GRANITE)
    for _, c in ipairs({ { 0, 0 }, { 0, 6 }, { 6, 0 }, { 6, 6 } }) do
        for y = 1, 4 do L.clear(c[1], y, c[2]) end   -- the shoulders, rounded
    end
    L.clear(3, 1, 6); L.clear(3, 2, 6)
    L.walls(1, 5, 1, 5, 5, 5, SLATE)
    L.box(2, 6, 2, 4, 6, 4, SLATE)
    L.put(3, 5, 1, GLASS); L.put(3, 6, 2, GLASS); L.put(3, 6, 3, GLASS)   -- the slit
    return L.blocks, { { 5, 1, 5, "tiamat_default_science:observatory" } }
end

--- A lattice tower of copper that stood on a granite plinth and fell its
--- length across the ground, as Wardenclyffe's did.
function BUILD.fallen_tower()
    local L = list()
    L.box(0, 0, 0, 2, 1, 2, GRANITE)
    for _, c in ipairs({ { 0, 0 }, { 0, 2 }, { 2, 0 }, { 2, 2 } }) do
        L.box(c[1], 2, c[2], c[1], 5, c[2], COPPER)  -- the stump of the legs
    end
    for z = 4, 14 do                                 -- the rest, lying where it fell
        L.put(0, 0, z, COPPER); L.put(2, 0, z, COPPER)
        if z % 2 == 0 then L.put(1, 0, z, COPPER) end
    end
    L.box(0, 0, 15, 2, 1, 16, COPPER)                -- the crown
    return L.blocks, { { 1, 2, 1, "tiamat_default_science:tower" } }
end

-- What each place's chests draw from ----------------------------------------------

-- A loot tag per kind of chest. `study` is Structures' own, shared with every
-- mod that stocks a study; the rest are this mod's.
local LOOT = {
    wreck = "tiamat_default_science:wreck",
    study = "tiamat_default_science:study",
    engine_house = "tiamat_default_science:engine_house",
    watermill = "tiamat_default_science:mill",
    windmill = "tiamat_default_science:mill",
    mine_adit = "tiamat_default_science:mine",
    observatory = "tiamat_default_science:observatory",
    fallen_tower = "tiamat_default_science:tower",
}

-- Finding them ---------------------------------------------------------------------

-- Progress splits a discovery id at its FIRST colon to find a family, so the
-- family is dotted and the place follows the colon.
P.FOUND = game.mod_id .. ".found"

--- The places, built: short id -> { blocks, chests }. Built here, at load,
--- whether or not Structures is there, so the tests can read them.
P.built = {}
for _, short in ipairs(C.place_order) do
    local blocks, chests = BUILD[short]()
    P.built[short] = { blocks = blocks, chests = chests }
end

if not structures then return P end

local progress = U.exports("tiamat_default_progress")
if progress then
    for _, short in ipairs(C.place_order) do
        local place = C.places[short]
        progress.register_discovery{ id = P.FOUND .. ":" .. short, insight = place.insight,
            label = "Found: " .. string.lower(string.sub(place.name, 1, 1)) .. string.sub(place.name, 2),
            group = "places" }
    end
end

P.registered = {}
for _, short in ipairs(C.place_order) do
    local place, built = C.places[short], P.built[short]
    local chests = {}
    for i, c in ipairs(built.chests) do chests[i] = { c[1], c[2], c[3], loot = c[4] } end
    local ok, why = structures.register{
        id = short,
        name = place.name,
        tags = { "science", short },
        layer = place.layer,
        rarity = place.rarity,
        where = place.where,
        blocks = built.blocks,
        build = function(B)
            for _, b in ipairs(built.blocks) do B.set(b[1], b[2], b[3], b[4]) end
        end,
        decay = place.decay,
        chests = chests,
    }
    if ok == false then
        game.log("tiamat_default_science: Structures refused the place " .. short .. ": " .. tostring(why))
    else
        P.registered[#P.registered + 1] = short
    end
end

-- Loot, by tag. A study's draw is Structures' shared tag as well as ours, so
-- a lens can turn up in a study Structures built itself.
local stocked = {}
for _, short in ipairs(C.place_order) do
    local tag = LOOT[short]
    if not stocked[tag] then
        stocked[tag] = true
        for _, e in ipairs(C.places[short].loot) do
            structures.add_loot(tag, { material = U.id(e[1]), min = e[2], max = e[3], weight = e[4] })
            if short == "study" then
                structures.add_loot("study", { material = U.id(e[1]), min = e[2], max = e[3], weight = e[4] })
            end
        end
    end
end

-- Paid once a player, by Progress. An open place pays anyone; the rest wait
-- for a player who has taken up natural philosophy, and the wreck says what
-- it is to one who has not.
local PREFIX = game.mod_id .. ":"
structures.on_found(function(uuid, site)
    if type(site) ~= "table" or type(site.kind) ~= "string" then return end
    if string.sub(site.kind, 1, #PREFIX) ~= PREFIX then return end
    local short = string.sub(site.kind, #PREFIX + 1)
    local place = C.places[short]
    if not place then return end
    if place.open or A.has(uuid, C.path.root) then
        A.discover(uuid, P.FOUND .. ":" .. short)
    end
    if short == "wreck" and not A.has(uuid, C.path.root) then
        game.chat_to(uuid, "Bronze wheels in the silt, thirty of them, cut by hand. Somebody made a machine that thought.")
    end
end)

return P
