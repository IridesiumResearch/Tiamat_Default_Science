-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- What other mods may call (brief §12; docs/exports.md is the list). Built
-- whole here, because the engine takes one export per mod. The brief's
-- fields — networks, charge, movements, sources, bodies, the Fold's
-- subscribers — are added as the machines they read are built, and not
-- before: an export that answers nothing yet is a promise nobody can test.

local G = tds.glyphs

-- The glyphs, as the brief's `glyphs` field: short id -> its canonical mask
-- and every registered orientation. A copy, so nobody holds this mod's own.
local glyphs = {}
for _, glyph in ipairs(G.table) do
    glyphs[glyph.id] = { mask = glyph.mask, variants = G.variants(glyph.mask) }
end

local N = tds.networks

--- The turning network at a block: `{ kind = "turning", supply, demand,
--- size }`, or nil where no network is. Answers nil for anything malformed.
local function network_at(pos)
    if type(pos) ~= "table" or math.type(pos.x) ~= "integer" or math.type(pos.y) ~= "integer"
        or math.type(pos.z) ~= "integer" then
        return nil
    end
    local net = N.at({ x = pos.x, y = pos.y, z = pos.z, domain = tds.util.place(pos.domain) })
    if not net then return nil end
    return { kind = "turning", supply = N.supply(net), demand = N.demand(net), size = net.size }
end

--- The charge a carried stack holds (a Leyden jar's), 0 for anything else.
local function charge_of(stack)
    if type(stack) ~= "table" then return nil end
    return tds.electricity.charge_of(stack)
end

return {
    version = 1,
    glyphs = glyphs,
    network_at = network_at,
    charge_of = charge_of,
}
