<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Asks of the sibling mods

What this mod needs from the OTHER default mods (Progress, Craft, Life, the
world and the interface), as `docs/engine-asks.md` holds what it needs from
the engine. Each says what was wanted, what stands in for it today, and the
smallest change that would answer it. Newest first within each mod. The
design reasons are in `docs/brief.md` §14 and §2.1; where magic wants the
same thing, its ask is named beside ours so the two are answered once.

Where they stand on 2026-09-30. Struck through is answered or withdrawn;
the answer is under each.

| Mod | Answered | Open |
|---|---|---|
| Craft (`1d22935`, 0.5.0) | C-S1, C-S2, C-S3, C-S5, C-S6, C-S7 | — |
| Life (`87a95f6`) | L-S2, L-S3, L-S4, L-S5, L-S6 | L-S7 |
| World (`1d50d64`) | W-S1, W-S2, W-M1 | — |
| The interface (`ae8954a`) | U-S1 | — |
| Progress (`ef6014b`) | P-S1, P-S2 | — |
| Weather (`2f437fe`) | Wx-S1, Wx-S2, Wx-S3, Wx-S4 | — |

## Tiamat Default Craft

~~**C-S7, unattended perform.**~~ *Wanted:* the exported `perform` accepts
`{ unattended = true }`, as Craft's own auto stations use internally.
*Why:* the exported form rejects it (`exports.lua`), so every `perform` is
attended: a tool not found in the frame's slots is looked for in its
owner's own inventory (`registry.lua`). A frame's tools should be the
frame's. *Stands in:* attended, documented in brief §2.
*Answered (Craft `1d22935`):* `perform(uuid, id, container, { unattended = true })`; unattended, a container's tools must be in it, and nobody's inventory is looked in.

~~**C-S6, lighting a fire.**~~ *Wanted:* `ignite(pos, uuid)` lights a laid
campfire or an unlit heat station, answering whether it did. *Why:* a
campfire lights only to a held `fire_striker` (`fire.lua`) and a furnace
only through its own striker path (`furnace.lua`); `add_fuel_at` needs a
fire already lit. The burning glass lights a fire from the noon sun, a
bench node a small child reaches in the first hour. *Stands in:* the
burning glass is a magnifier only.
*Answered (Craft `1d22935`):* `ignite(pos, uuid)` lights a laid campfire or an unlit heat station with fuel in it, or answers why not. The burning glass uses it at noon (brief §4), listening at the fires by name so it is asked before the fire's box opens.

~~**C-S5, idempotent glyphs.**~~ Kept as a convenience, not a fault:
registering a mask again with the same id answers `nil, "that mask is
already <id>"` and never raises. Magic's C-M7; asked once, together.

~~**C-S4, long recipes.**~~ Withdrawn 2026-09-29: blister steel is one
in-game day (24,000 ticks), under `max_ticks`. Magic's C-M5 stands on its
own.

~~**C-S3, a glyph as an ingredient.**~~ Identical to magic's C-M1; asked once,
together. *Stands in:* relic recipes register their plain inputs, and the
assembly jig takes the carved parts itself with `game.container_take`
around `perform`, giving them back with `game.container_give` if it fails
(brief §7.5).
*Answered (Craft `1d22935`):* `{ glyph = id, material = id or #group, count = n }` as an input (consumed) or a tool (kept). Relics are ordinary recipes; the jig's take-and-give fallback is retired.

~~**C-S2, a boost that needs power.**~~ *Wanted:*
`boost = { tool, heat, when = fn(container) → bool }`. *Why:* the blowing
engine should blast only while a powered frame touches the furnace, and the
Bessemer converter likewise. *Stands in:* the blowing engine boosts
whenever it is in the tool slot (a documented simplification).
*Answered (Craft `1d22935`):* `boost = { tool, heat, when = fn(container) }`, asked every second while the tool is there.

~~**C-S1, a station run by a predicate.**~~ *Wanted:*
`register_station{ auto = true, runs = fn(container) → speed_percent }`, so
Craft advances a frame's recipe itself while the predicate answers more
than 0. *Why:* Craft's brief expected this mod to write "no job loop of its
own"; without this it must. *Stands in:* this mod's loop, every 20 ticks,
calls `craft.perform` when a frame's job reaches the recipe's ticks (brief
§6.1) — works today.
*Answered (Craft `1d22935`):* `register_station{ runs = fn(container) → percent }`, asked once a second for each placed, loaded station; Craft keeps the job and makes the recipe as the placer, unattended. The frame writes no job loop (brief §6.1).

## Tiamat Default Life

**L-S7, gravity in `set_ability`.** *Wanted:* a `gravity` field in
`set_ability(uuid, source, spec)`, a multiplier 0..4 (default 1), composed
across sources by multiplying and handed to `set_player_abilities` with
Life's own speed and flight. *Why:* the engine now takes a per-player
gravity (E-S1, engine `b0996cb`, client-predicted), but it rides on
`set_player_abilities`, which Life writes and the last writer wins. Gravity
plating (0.17 above it), cavorite soles (0.5) and light star bodies would
each set one. *Stands in:* nothing yet; gravity is tier 7. Asked
2026-09-30.

~~**L-S6, a tether.**~~ *Wanted:* a creature on a `lead` tied to a block, or
one player leading two. *Why:* the Magdeburg hemispheres are pulled by two
horses; today a lead makes a creature follow whoever holds it and nothing
ties one to a block (`husbandry.lua`). *Stands in:* one horse, led.
*Answered (Life `87a95f6`):* a lead right-clicked at a fence post ties everything its holder leads to it; one player leading two was already so. The Magdeburg hemispheres get their two horses.

~~**L-S5, reading the worn view.**~~ Not needed:
`game.inventory(uuid, "tiamat_default_life:worn")` reads it, and the view
is documented in Life's exports. Magic's L-M4 is answered the same way.

~~**L-S4, moving drop entities.**~~ *Wanted:* Life's agreement that the
electromagnet may `set_entity` the velocity of Life's dropped items, or an
export `pull_drops(pos, radius, uuid)`. *Why:* a held magnet draws drops
within 8 blocks. The engine does not check who owns an entity
(`mlua_vm.rs`), so this is a courtesy, not a permission. *Stands in:*
`set_entity`, once Life agrees.
*Answered (Life `87a95f6`):* yes, and `pull_drops(pos, radius, strength)`.

~~**L-S3, composed abilities.**~~ As magic's L-M3: a per-source ability
(`speed_mul`, `fly`) Life composes, since `set_player_abilities` is last
writer wins and Life writes it. For the levitator and gravity plating.
*Stands in:* upward impulses with `push_player`; no
`set_player_abilities` from this mod.
*Answered (Life `87a95f6`):* `set_ability(uuid, source, { speed_mul, fly })`, composed with Life's own cold and hunger. Levitator flight is a source of ours, never `set_player_abilities`.

~~**L-S2, act on Life's creatures.**~~ *Wanted:* `push(entity, velocity)` and
`freeze(entity, ticks)`, for gravity wells, repulsors and the stasis
field. *Why:* Life's AI drives its creatures, and a velocity written from
outside is overwritten or fights it. *Stands in:* wells and stasis act on
item entities and this mod's own; the Tesla coil already works on Life's
creatures through `set_alight`.
*Answered (Life `87a95f6`):* `push(entity, velocity)` and `freeze(entity, ticks)` on Life's creatures.

## Tiamat Default World

~~**W-S2, cave earth.**~~ *Wanted:* a nitrous earth block under overhangs and
in caves. *Why:* the saltpetre men leached cave earth and ash; World has no
such block. *Stands in:* `dirt` and `#ash` in the leaching vat.
*Answered (World `1d50d64`):* `cave_earth` (tags `soil`, `nitrous`) on cave floors. The saltpetre men leach it; `dirt` retired.

~~**W-S1, pitchblende.**~~ Landed: World generates `pitchblende` from
1,200 blocks down beside the lead and the silver (`blocks.lua`,
`generate.lua`). Craft's W3.

~~**W-M1, cinnabar.**~~ Magic's ask, shared. Science roasts it for
quicksilver (`cinnabar_roasting`). *Stands in:* as magic's fallback,
native droplets from sulfur crust.
*Answered (World `1d50d64`):* `cinnabar` (tags `ore`, `mineral`) round the vents. Quicksilver is roasted from it; the sulfur-crust stand-in retired.

## Tiamat Default UI

~~**U-S1, shape-crafter presets from siblings.**~~ Magic's U-M1, shared: a
way for another mod to add presets, so gear, wheel, pipe, coil, ring,
gnomon and cairn are one click, shown when their node is held. Pillar and
Slab (`rod` and `plate`) already are. *Why:* no API adds a preset
(`crafting.lua`). *Stands in:* carving by hand, with the *Theatrum*'s
pictures of each mask.
*Answered (interface ae8954a, 2026-09-29):* `add_preset{ id, label, mask,
visible? }` on the interface's exports, exactly as asked. Four to a row after
Block, Slab, Stairs and Pillar; `label` 1–8 bytes (a button is a quarter of
the column at 800x600); `mask` in `x + 3*y + 9*z`, neither empty nor full;
`visible(player)` asked each time the crafter is drawn, so keep it a lookup;
eight added presets show at most, in the order added. The crafter is now a
block's tab (the shape crafter block), so presets show where it is used.

## Tiamat Default Progress

~~**P-S2, a study-insight effect.**~~ *Wanted:* Progress reads an effect key
(say `progress.study_percent`) when it pays a study. *Why:* `register_study`
pays a fixed `insight` and `research.lua` reads no effect, so the
Difference Engine's "studies pay 20 % more" does nothing. *Stands in:* the
effect is carried and inert.
*Answered (Progress `ef6014b`):* studies read `progress.study_percent`, summed over the nodes a player holds, and pay that many per cent more. The Difference Engine carries 20.

~~**P-S1, a branch label and a reveal rule.**~~ Magic's P-M1, shared. This
path registers 107 nodes, 15 to 25 a tier where Progress's brief expected
four to six, so the tree screen wants checking against it too.
*Answered (Progress `ef6014b`):* `register_node{ branch, reveal }` and `register_path{ branches, reveal }`. The Research tab groups a tier by branch, and `reveal = "near"` shows a node only once all but one of its requirements are held.

## Tiamat Weather

~~**Wx-S4, fires near a point.**~~ *Wanted:* `fires_near(pos, r)` answering
positions. *Why:* a lightning rod puts out the fires round it;
`extinguish(x, y, z)` puts out one block and `fires()` answers counts.
*Stands in:* the strike's own block is put out.
*Answered (Weather `2f437fe`):* `fires_near(x, y, z, r)`, the blocks alight within `r` (up to 64), ordered.

~~**Wx-S3, domains.**~~ *Wanted:* Weather stands aside for a player off the
overworld. *Why:* Weather has no domain logic and sends sky and clouds by
x and z whatever domain a player is in (`fx.lua`), so a star body gets the
overworld's weather at the same coordinates. *Stands in:* a body has
Weather's sky and clouds.
*Answered (Weather `2f437fe`):* Weather is the overworld's. A player in another domain is in no square, and what was sent is taken back; `weather_for` and `falling_on` answer nil for them.

~~**Wx-S2, a layered sky overlay.**~~ Magic's Wx-M1, shared: the Core's
darkening and the atmosphere processor. *Stands in:* this mod never calls
`set_sky_modifier`; the Core has its hum alone.
*Answered (Weather `2f437fe`), with magic's Wx-M1:* `add_overlay(player, source, spec | nil)`, laid over the weather's own; intensities and saturations multiply, colours mix in source order, the fog stays the weather's.

~~**Wx-S1, wind.**~~ *Wanted:* an export `wind(x, z)`. Internally it is
`wind(x, z, tick) → { x, z }`, a direction with no strength
(`climate.lua`); a strength beside it, if Weather will. For windmills and
kites. *Stands in:* weather kind and intensity alone.
*Answered (Weather `2f437fe`):* `wind(x, z)` → `x, z, strength`: the climate's direction, and 0..1 from the weather there, 0.2 clear to 1 in a blizzard. The kite uses it (0.1.0).
