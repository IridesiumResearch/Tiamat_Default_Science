<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Engine asks from Tiamat Default Science

What this mod has needed from the engine, found by planning and building
it. Each entry says what was wanted, why the mod cannot do it, and the
smallest engine change that would. Newest first. Landed items stay here,
marked, as the record; the open ones are copied, without the history, to the
engine's `docs/engine-asks/tiamat_default_science.md`, so the engine side
finds every mod's open asks in one place.

## E-S5, a mod's world options under its own entry on the Mods tab — open, asked 2026-10-07

*Wanted:* the start screen draws a mod's `[[world_option]]`s under that
mod's own entry on the Mods tab (`listing_row` in `front.rs`), folded as
the settings page now folds its `register_setting`s (`fefad7be`), instead
of in one flat run under the seed box on the Play tab. *Why:* the designer
asked, 2026-10-07, that each mod's settings sit under its own tab in the
mods section of the pre-game menu. A mod can only declare its options in
`mod.toml`; where the start screen draws them is the client's, and no Lua
runs there. This mod declares two (`blasting` and `the_deep`); with eight
mods each offering a few, a flat run under the seed box does not say whose
each one is. *Stands in:* the two options, under the seed box, named so
they read on their own. *Smallest change:* in `mods_tab`, give each
enabled listing with world options a closed `CollapsingHeader` holding the
rows `world_option_rows` draws for it today, and draw nothing under the
seed box; the choices stay in `world_options`, keyed as now.

## E-S4, the domain on place and dig events — landed 2026-10-05 (engine e1becf0a)

*Wanted:* `domain` on the place event (`register_on_place`) and the dig
events (`register_on_dig_start`, `register_on_dig_complete`), as the use
event already carries it. *Why:* a block placed or dug off the overworld
cannot be told from one at the same coordinates in the overworld. A mod
has to keep each player's domain from `register_on_player_move` and trust
that the move was heard first. This mod does (`tds.domain_of`). Craft does
not, so a station placed on a world at a star, or in the Deep, is named
as if it stood in the overworld (sibling ask C-S8): a terraformer's frame
does not know it is on a body, and two frames, one in each domain at the
same coordinates, would share one box. *Stands in:* this mod's own
`domain_of` for its own records. *Smallest change:* the field, filled
where the use event's is.

*Landed (engine `e1becf0a`):* `domain` on the place event and both dig
events, `"overworld"` or a domain's id, as the use event carries it. This
mod reads it (`U.where(e)`) for every record it keeps of a placed or dug
block: a frame's placer, an arc lamp's, a lightning rod's, a cairn, and
strange matter dug in the Deep. Craft named its stations by the placer's
domain in the meantime (C-S8) and switches to the field now.

## E-S3, actions that fire — answered 2026-09-30

*Wanted:* `register_on_action` delivering presses. *Why:* the stubs say
`register_action` is "stored now, inert until Task 13", and the brief binds
the *Theatrum* to N and calling the automata home to U. *Stands in:* the
*Theatrum* opens when the book is used and on `science book` in chat; the
automata are called by using the automaton key. Nothing to build here; this
records that the mod waits on Task 13. Magic's E-M3.

*Answered (engine, 2026-09-30):* nothing to build — the stub's "inert
until Task 13" was stale. A `default_key` on `register_action` and presses
arrive at `register_on_action` as `{ player, id, pressed }`. The Theatrum
is on N (0.1.0); the book and chat stay as second ways in.

## E-S2, the instance in the generator — landed 2026-09-30 (engine 61b4c3e)

*Wanted:* `pos.domain = "template/key"` in a generator's position. *Why:* a
generator is told `{ x, y, z, seed }` only, so two instances of one
template generate the same world. *Stands in:* the slot trick (brief §6.8):
every block coordinate in every domain lies in −60,000..59,999
(`crates/core/src/coords.rs`), so each body kind's template is a 15 × 15
grid of 8,000-block slots and a body is a disc in one of them — 225 bodies
a kind, 1,125 a world, the cap. Magic's E-M1; this answer retires the slot
trick and its cap.

*Landed:* a generator's `pos` carries `domain` — `"template/key"` for an
instance — in every VM that generates, the workers' included. Each body
seeds its streams from its key; the slot grid and its cap are gone from
the brief (§6.8).

## E-S1, a gravity scale per player — landed 2026-09-30 (engine b0996cb, protocol 83)

*Wanted:* `set_player_abilities{ gravity = 0.17 }`, or a gravity per
domain. *Why:* gravity plating, cavorite soles and low-gravity star bodies
all mean less gravity, and the engine has no scale. *Stands in:* an upward
`push_player` every tick cancelling part of gravity. `push_player` is "added,
not set" and not documented as client-predicted, so this must be tried in a
real window for rubber-banding before it ships.

*Landed:* `set_player_abilities{ gravity }`, a multiplier from 0 to 4,
predicted by the client with the same number, so there is no
rubber-banding to test for. The `push_player` stand-in is dropped before
it was built. It reaches the engine through Life's `set_ability`, since
Life writes `set_player_abilities` and the last writer wins: sibling ask
L-S7 adds `gravity` to that spec. The feel (0.17: take-off, apex and
landing) is the designer's to try.
