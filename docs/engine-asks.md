<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Engine asks from Tiamat Default Science

What this mod has needed from the engine, found by planning and building
it. Each entry says what was wanted, why the mod cannot do it, and the
smallest engine change that would. Newest first. Landed items stay here,
marked, as the record; the open ones are copied, without the history, to the
engine's `docs/engine-asks/tiamat_default_science.md`, so the engine side
finds every mod's open asks in one place.

## E-S3, actions that fire — open, 2026-09-29

*Wanted:* `register_on_action` delivering presses. *Why:* the stubs say
`register_action` is "stored now, inert until Task 13", and the brief binds
the *Theatrum* to N and calling the automata home to U. *Stands in:* the
*Theatrum* opens when the book is used and on `science book` in chat; the
automata are called by using the automaton key. Nothing to build here; this
records that the mod waits on Task 13. Magic's E-M3.

## E-S2, the instance in the generator — open, 2026-09-28

*Wanted:* `pos.domain = "template/key"` in a generator's position. *Why:* a
generator is told `{ x, y, z, seed }` only, so two instances of one
template generate the same world. *Stands in:* the slot trick (brief §6.8):
every block coordinate in every domain lies in −60,000..59,999
(`crates/core/src/coords.rs`), so each body kind's template is a 15 × 15
grid of 8,000-block slots and a body is a disc in one of them — 225 bodies
a kind, 1,125 a world, the cap. Magic's E-M1; this answer retires the slot
trick and its cap.

## E-S1, a gravity scale per player — open, 2026-09-28

*Wanted:* `set_player_abilities{ gravity = 0.17 }`, or a gravity per
domain. *Why:* gravity plating, cavorite soles and low-gravity star bodies
all mean less gravity, and the engine has no scale. *Stands in:* an upward
`push_player` every tick cancelling part of gravity. `push_player` is "added,
not set" and not documented as client-predicted, so this must be tried in a
real window for rubber-banding before it ships.
