-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The furnace (brief §6.3): a Craft heat station of brick. It burns charcoal,
-- coal or coke (heat 3, tier 4's) at their own heat; a blowing engine in its
-- tool slot blasts it to heat 5 — but only while the shaft it stands on turns (Craft's
-- `boost.when`, sibling ask C-S2), because a blowing engine with no power is
-- a set of bellows nobody works.
--
-- It is `long`: a furnace in a chunk nobody is near keeps its fire, and
-- works the time it missed when the chunk is next loaded, fuel permitting.
-- Blister steel's day passes whether or not anybody stands by it.
--
-- Its recipes — the metallurgy ladder, pig iron to blister steel — are in
-- `config.lua` with the rest of tier 3's, and Craft makes, while it burns,
-- the first of them by id that its slots and heat allow.

local C = tds.config
local U = tds.util
local N = tds.networks

local FU = {}

local craft = U.exports("tiamat_default_craft")

--- Whether the furnace a container names is blasting: its network turns
--- enough to work the blowing engine.
function FU.blasting(name)
    local pos = U.station_pos(name, "furnace")
    local net = pos and N.at(pos)
    return net ~= nil and N.supply(net) >= C.furnace.blast_need
end

if craft then
    local ok, why = craft.register_station{
        id = U.id("furnace"),
        name = C.furnace.name,
        slots = { fuel = 1, input = { from = 2, to = 4 }, tool = 5, output = { from = 6, to = 8 } },
        heat = true,
        long = true,
        fuels = { U.id("C:charcoal"), U.id("W:coal"), U.id("coke") },
        block = U.id(C.furnace.id),
        lit_block = U.id(C.furnace.lit),
        boost = { tool = U.id("blowing_engine"), heat = C.furnace.blast_heat, when = FU.blasting },
    }
    if not ok then game.log("tiamat_default_science: Craft refused the furnace: " .. tostring(why)) end
end

return FU
