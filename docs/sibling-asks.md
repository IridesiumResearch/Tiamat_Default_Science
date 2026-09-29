<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Asks of the sibling mods

What this mod needs from the OTHER default mods (Progress, Craft, Life, the
world and the interface), as `docs/engine-asks.md` holds what it needs from
the engine. Each says what was wanted, what stands in for it today, and the
smallest change that would answer it. Newest first within each mod. The
design reasons are in `docs/brief.md` §14 and §2.1; where magic wants the
same thing, its ask is named beside ours so the two are answered once.

Every ask below is **open** as of 2026-09-29 unless it is struck through.

## Tiamat Default Craft

**C-S7, unattended perform.** *Wanted:* the exported `perform` accepts
`{ unattended = true }`, as Craft's own auto stations use internally.
*Why:* the exported form rejects it (`exports.lua`), so every `perform` is
attended: a tool not found in the frame's slots is looked for in its
owner's own inventory (`registry.lua`). A frame's tools should be the
frame's. *Stands in:* attended, documented in brief §2.

**C-S6, lighting a fire.** *Wanted:* `ignite(pos, uuid)` lights a laid
campfire or an unlit heat station, answering whether it did. *Why:* a
campfire lights only to a held `fire_striker` (`fire.lua`) and a furnace
only through its own striker path (`furnace.lua`); `add_fuel_at` needs a
fire already lit. The burning glass lights a fire from the noon sun, a
bench node a small child reaches in the first hour. *Stands in:* the
burning glass is a magnifier only.

~~**C-S5, idempotent glyphs.**~~ Kept as a convenience, not a fault:
registering a mask again with the same id answers `nil, "that mask is
already <id>"` and never raises. Magic's C-M7; asked once, together.

~~**C-S4, long recipes.**~~ Withdrawn 2026-09-29: blister steel is one
in-game day (24,000 ticks), under `max_ticks`. Magic's C-M5 stands on its
own.

**C-S3, a glyph as an ingredient.** Identical to magic's C-M1; asked once,
together. *Stands in:* relic recipes register their plain inputs, and the
assembly jig takes the carved parts itself with `game.container_take`
around `perform`, giving them back with `game.container_give` if it fails
(brief §7.5).

**C-S2, a boost that needs power.** *Wanted:*
`boost = { tool, heat, when = fn(container) → bool }`. *Why:* the blowing
engine should blast only while a powered frame touches the furnace, and the
Bessemer converter likewise. *Stands in:* the blowing engine boosts
whenever it is in the tool slot (a documented simplification).

**C-S1, a station run by a predicate.** *Wanted:*
`register_station{ auto = true, runs = fn(container) → speed_percent }`, so
Craft advances a frame's recipe itself while the predicate answers more
than 0. *Why:* Craft's brief expected this mod to write "no job loop of its
own"; without this it must. *Stands in:* this mod's loop, every 20 ticks,
calls `craft.perform` when a frame's job reaches the recipe's ticks (brief
§6.1) — works today.

## Tiamat Default Life

**L-S6, a tether.** *Wanted:* a creature on a `lead` tied to a block, or
one player leading two. *Why:* the Magdeburg hemispheres are pulled by two
horses; today a lead makes a creature follow whoever holds it and nothing
ties one to a block (`husbandry.lua`). *Stands in:* one horse, led.

~~**L-S5, reading the worn view.**~~ Not needed:
`game.inventory(uuid, "tiamat_default_life:worn")` reads it, and the view
is documented in Life's exports. Magic's L-M4 is answered the same way.

**L-S4, moving drop entities.** *Wanted:* Life's agreement that the
electromagnet may `set_entity` the velocity of Life's dropped items, or an
export `pull_drops(pos, radius, uuid)`. *Why:* a held magnet draws drops
within 8 blocks. The engine does not check who owns an entity
(`mlua_vm.rs`), so this is a courtesy, not a permission. *Stands in:*
`set_entity`, once Life agrees.

**L-S3, composed abilities.** As magic's L-M3: a per-source ability
(`speed_mul`, `fly`) Life composes, since `set_player_abilities` is last
writer wins and Life writes it. For the levitator and gravity plating.
*Stands in:* upward impulses with `push_player`; no
`set_player_abilities` from this mod.

**L-S2, act on Life's creatures.** *Wanted:* `push(entity, velocity)` and
`freeze(entity, ticks)`, for gravity wells, repulsors and the stasis
field. *Why:* Life's AI drives its creatures, and a velocity written from
outside is overwritten or fights it. *Stands in:* wells and stasis act on
item entities and this mod's own; the Tesla coil already works on Life's
creatures through `set_alight`.

## Tiamat Default World

**W-S2, cave earth.** *Wanted:* a nitrous earth block under overhangs and
in caves. *Why:* the saltpetre men leached cave earth and ash; World has no
such block. *Stands in:* `dirt` and `#ash` in the leaching vat.

~~**W-S1, pitchblende.**~~ Landed: World generates `pitchblende` from
1,200 blocks down beside the lead and the silver (`blocks.lua`,
`generate.lua`). Craft's W3.

**W-M1, cinnabar.** Magic's ask, shared. Science roasts it for
quicksilver (`cinnabar_roasting`). *Stands in:* as magic's fallback,
native droplets from sulfur crust.

## Tiamat Default UI

**U-S1, shape-crafter presets from siblings.** Magic's U-M1, shared: a
way for another mod to add presets, so gear, wheel, pipe, coil, ring,
gnomon and cairn are one click, shown when their node is held. Pillar and
Slab (`rod` and `plate`) already are. *Why:* no API adds a preset
(`crafting.lua`). *Stands in:* carving by hand, with the *Theatrum*'s
pictures of each mask.

## Tiamat Default Progress

**P-S2, a study-insight effect.** *Wanted:* Progress reads an effect key
(say `progress.study_percent`) when it pays a study. *Why:* `register_study`
pays a fixed `insight` and `research.lua` reads no effect, so the
Difference Engine's "studies pay 20 % more" does nothing. *Stands in:* the
effect is carried and inert.

**P-S1, a branch label and a reveal rule.** Magic's P-M1, shared. This
path registers 107 nodes, 15 to 25 a tier where Progress's brief expected
four to six, so the tree screen wants checking against it too.

## Tiamat Weather

**Wx-S4, fires near a point.** *Wanted:* `fires_near(pos, r)` answering
positions. *Why:* a lightning rod puts out the fires round it;
`extinguish(x, y, z)` puts out one block and `fires()` answers counts.
*Stands in:* the strike's own block is put out.

**Wx-S3, domains.** *Wanted:* Weather stands aside for a player off the
overworld. *Why:* Weather has no domain logic and sends sky and clouds by
x and z whatever domain a player is in (`fx.lua`), so a star body gets the
overworld's weather at the same coordinates. *Stands in:* a body has
Weather's sky and clouds.

**Wx-S2, a layered sky overlay.** Magic's Wx-M1, shared: the Core's
darkening and the atmosphere processor. *Stands in:* this mod never calls
`set_sky_modifier`; the Core has its hum alone.

**Wx-S1, wind.** *Wanted:* an export `wind(x, z)`. Internally it is
`wind(x, z, tick) → { x, z }`, a direction with no strength
(`climate.lua`); a strength beside it, if Weather will. For windmills and
kites. *Stands in:* weather kind and intensity alone.
