<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Exports

What Tiamat Default Science (`tiamat_default_science`) deliberately offers other mods. This is the document
`LICENSE.EXCEPTION` names as "the Exports": a mod that reaches this one only
through what is listed here, the engine's scripting API or the network
protocol is an independent work. A mod that copies or adapts this mod's code
or assets is not, and stays under the GPL.

An interface this mod offers in fact is an export whether or not it is listed
here, so this file changes in the same commit as any change to one.

## The exported table

`game.exports("tiamat_default_science")` answers it to a mod that lists this
one in `depends` or `optional_depends`. Source:
`mods/tiamat_default_science/exports.lua`.

| Field | Shape | What it does |
|---|---|---|
| `version` | integer, `1` | Bumped only when a change would break a reader. |
| `glyphs` | `{ [id] = { mask, variants } }`, read-only | This mod's glyphs: the canonical mask of each (`x + 3y + 9z`) and every orientation registered with Craft, smallest first. `gnomon` and `cairn` so far. |

That is all, for now. The brief's other fields (§12: `network_at`,
`charge_of`, `add_charge`, `register_movement`, `register_source`,
`bodies`, `on_fold`) are added as the machines they read are built.

## Identifiers it registers

All are namespaced `tiamat_default_science:` by the engine.

- **Items:** `theatrum` (the Theatrum Machinarum), `lens` (the burning
  glass), `kite`, `compass`.
- **Into Progress:** the shared nodes `shared.theatrum`, `shared.sundial`,
  `shared.burning_glass`, `shared.kite` (tier 1) and `shared.compass`
  (tier 2); the discoveries `tiamat_default_science.hour`,
  `tiamat_default_science.kite` and `tiamat_default_science.home`, in the
  group `toybox`.
- **Into Craft:** the recipes `theatrum`, `lens`, `kite`, `compass` (by
  hand), each qualified `tiamat_default_science:<id>`; the glyphs `gnomon`
  and `cairn`, each in its six orientations.
- **Into the interface:** the shape-crafter presets `gnomon` and `cairn`,
  each shown to a player who holds its node.
- **Dialog:** `theatrum`, the Theatrum Machinarum.

## Commands it accepts

Chat words, said by a player and swallowed. For anyone: `science` (how far
along the Tinker's Bench the speaker is) and `science book` (opens the
Theatrum for a player who carries one). A sentence that only begins with
the word is chat.

## Data it stores or sends

- `cairn:<player UUID>` — the block of the last stone cairn that player
  placed, as `x,y,z,domain`. Forgotten when a compass finds it gone.
- Particles: a compass's needle, to its holder alone; a kite over whoever
  flies it, to everyone within 64 blocks.

## What it reads from other mods

Not exports, listed so the direction is clear: Progress's `register_node`,
`register_discovery`, `discover` and `has`; Craft's `register`,
`register_glyph` and `glyph_of`; the interface's `add_preset` and
`widgets`; Weather's `weather_at`.
