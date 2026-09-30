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

return {
    version = 1,
    glyphs = glyphs,
}
