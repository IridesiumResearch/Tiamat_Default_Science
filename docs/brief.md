<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Tiamat Default Science: starting brief

*Draft 0, 2026-09-29, written by the engine session when this repository was
scaffolded. For an AI coding assistant and the person supervising it.*

**What this file is.** The long plan is the designer's two-path design
(`schism_design.md`), which is not in this repository. This brief collects
what that design and the sibling mods have already fixed about this tree,
and the contracts this mod builds on. It does not design the tree. Where it
is silent the answer is the designer's: ask, and do not invent. When the
designer's build prompt for this mod arrives, it replaces this file.

**A name to settle first.** The design and the sibling mods' documents call
this tree "tech" (`schism_tech`, "the tech tree", "tech reading"). The
repository and the mod are named Science. The mod's id is
`tiamat_default_science` and will not change. The PATH id this mod registers
with Progress is a separate string, and nothing has registered one yet:
Progress's code names no path. Ask the designer whether the path is
`science` or `tech` before registering it, because node ids
(`<path>.<name>`) and every player's saved record carry that word.

Read first, in this order: `AGENTS.md` and `stubs/game.lua` (the engine's mod
API; the stubs win over anything written here), then the `docs/exports.md` of
Progress, Craft, Life, World and the interface, which are the only ways into
those mods.

---

## 1. One paragraph

`tiamat_default_science` is one of the two doors at the Fork. A player
climbs the shared tree (tiers 0 to 2) in Craft and Progress, makes the
Keystone, and chooses: this mod, or `tiamat_default_magic`. The choice is per
player and final unless the world was made with Progress's `repath` option.
This mod owns its door, its nodes of tiers 3 to 7, and everything those
nodes unlock. Progress owns the graph, the insight and the lock; this mod
registers into it and never keeps a second copy of who chose what.

## 2. Where it sits

| Mod | What this mod takes from it |
|---|---|
| `tiamat_default_progress` | `register_path`, `register_node`, `has`, `path`, `award`, `register_study`, `register_discovery`, `on_fork`, `on_repath` |
| `tiamat_default_craft` | the recipe registry (`register`, `register_station`, `register_fuel`, `register_group`), tool classes (`register_class`, `register_tool`, `classify`, `wear`), glyphs (`register_glyph`, `glyph_of`) |
| `tiamat_default_life` | `add_stat`, `stat`, `set_stat`, `spend_stat` for charge; `mode`, `is_ghost`; creatures and food through its `add_*` exports |
| `tiamat_default_world` | the ores and blocks it generates; `biome_under`, `depth_under` |
| `tiamat_default_ui` | `add_tab`, the theme and widget builders |
| `tiamat_default_magic` | nothing. The two trees do not call each other; trade between players is inventories and needs no code |

Every one is an `optional_depends`. The mod must load and pass its checks on
a bare engine, and degrade one sibling at a time: no Progress means no door
and no gating; no Craft means no recipes.

## 3. What is already decided

Each line names where it is recorded. Anything not listed here is open.

**The shape of the climb** (Progress, `docs/brief.md` and `docs/exports.md`)

- Tiers 3 to 7. Default costs in insight: 100, 200, 400, 800, 1500. Four to
  six nodes a tier.
- A node id is `<path>.<name>`. Every node of tier 3 or more must require
  `shared.fork`, directly or through what it requires, or Progress disables
  it and logs why.
- Both trees' content is always loaded, because registries freeze at load.
  The lock is a question asked at run time: `progress.has(uuid, node)`
  answers `false`, always, for a node of the other path.
- The shared tree is affordable from exploring and making alone; the path
  trees are priced so that a player needs the research table. This mod's
  studies (`register_study`) and milestones (`award`) are how its own
  materials pay insight.

**The door** (Progress, `docs/brief.md` section 7)

- This mod registers a door block and a recipe for it; Progress adds the
  Keystone to the recipe and requires `shared.keystone`.
- What the door says to a player of the other path: "The dials mean nothing
  to you."
- On `on_repath` away from this path, this mod wipes the player's charge.
- The door's block id, the path's label and what `on_choose` gives are not
  recorded.

**Charge** (Life, `docs/exports.md`; Progress, `docs/sibling-asks.md`)

- Charge is a Life stat registered with `add_stat`, so it is drawn in Life's
  status tray and saved with the player. This mod does not own a second HUD
  for it.

**The same rock, two readings** (Craft, `docs/brief.md` section 3.1)

| World block | This tree's reading |
|---|---|
| `copper_ore` | wire, dynamo |
| `tin_ore` | solder |
| `iron_ore` | steel, with coke |
| `coal` | coke for steel; coal tar for plastic |
| `salt` | chemistry |
| `sulfur` | blasting charge, acid |
| `silver_ore` | catalysts |
| `gold_ore` | conductors |
| `lead_ore` | batteries, shielding |
| `chromium_ore` | stainless steel, in an arc smelter, at tier 4 |
| `crystal` | oscillators, glass optics |
| `diamond` | cutting heads, precision |
| `orichalcum` | exotic matter |
| `metal` (quenched lava) | a free, impure alloy for the early tiers |
| `pyrite` | a source of sulphur when roasted |
| `pitchblende` | fission |

Craft reserves every ore: none is to be given a throwaway use. Two notes
from the same section. There is no zinc in the world, so the design's brass
gears are bronze gears, which Craft already casts. Pitchblende was asked of
World for this tree (Craft's sibling ask W3); World's block list describes
it from 1,200 blocks down, and that work was not yet committed in World's
repository when this was written, so check before relying on the id.

**Steel is tier 3** (Craft, `docs/brief.md`, out of scope list)

- Smithing beyond wrought iron is this mod's: steel from coke at tier 3,
  chromium later.
- Craft's iron parts (frame, plates, nails, hinges, gears) exist so that
  this tree's stations have something to be built from.

**Stations and classes** (Craft, `docs/brief.md`)

- This mod adds an assembler, as a station in Craft's registry. It writes
  no job loop of its own.
- Its block class is `reinforced`, registered with `register_class`.

**Where both trees end** (the designer's plan, as recorded by the engine
session on 2026-09-27)

- Both trees end at making creatures and at making or remaking worlds, and
  they reach both through mechanisms shared with Magic:
  - **Glyphs.** A carved 27-cell shape that means something. This tree reads
    them as punch cards; Magic reads the same masks as runes. Craft keeps
    the registry.
  - **A creature trait vector.** This tree calls the traits genomes; Magic
    calls them essences.
  - **Worlds as domains registered before the freeze.** This tree modifies
    worlds; Magic creates and destroys them.

## 4. Rules that bind

From the engine's charter and `AGENTS.md`. These fail quietly when broken.

1. Everything is registered while `init.lua` runs. A `register_*` call after
   that is a hard error.
2. Identity is the player's UUID. Never key anything on a display name.
3. Arithmetic that decides anything is in whole numbers. No floats in
   rules, no `math.random`: randomness comes from the engine's seeded
   streams.
4. One callback per hook per mod: `hooks.lua` registers each engine hook
   once and fans out.
5. An export never raises. Bad input answers `nil` and a reason a person
   can read.
6. Quantities are units: 27 to a block. A recipe conserves units or says
   plainly that it does not.
7. The engine knows no content. If something cannot be built through the
   API, that is an engine ask (section 6), not a workaround.

## 5. The repository

```
mods/tiamat_default_science/ the mod: what ships
stubs/game.lua, AGENTS.md    the engine's API, vendored (MIT); re-copy when the engine moves
docs/brief.md                this file
docs/exports.md              what this mod offers others; LICENSE.EXCEPTION names it
docs/assets.md               third-party assets and their licences
docs/engine-asks.md          what this mod needs from the engine
docs/sibling-asks.md         what it needs from the other default mods
scripts/check-spdx.sh        every source file carries both SPDX lines
scripts/check-dco.sh         every commit is signed off
```

`mods/tiamat_default_science/init.lua` is the engine's template as it came:
a tour that registers a beacon, a hand, a sound, an action and a dialog. It
is there as a worked example and is the first thing to replace.

Check the mod without starting a world, from the engine repository, in a
directory that holds this mod and the engine's `core` (the manifest depends
on it). The engine's `game/` is one, once this mod is linked into it:

```sh
cargo run -p server -- --check-mods game
```

Commits are signed off (`git commit -s`, or enable the hook once with
`git config core.hooksPath .githooks`). The licence is GPL-3.0-only with this
mod's own Additional Permission; `CONTRIBUTING.md` has the terms.

## 6. Asks

An ask is written in this repository first, in `docs/engine-asks.md` or
`docs/sibling-asks.md`: what was wanted, why the mod cannot do it, and the
smallest change that would. The engine's copy of the open ones is
`docs/engine-asks/tiamat_default_science.md` in the engine repository.

The engine session expects these from the two trees and has not built them:

- Machines that run while nobody is near them, if the design wants that.
  Find out what the engine ticks far from every player before designing on
  it, and ask if it is not enough.
- Whatever modifying a world at run time turns out to need beyond what
  `game.set_block` and domains registered before the freeze already give.

## 7. First steps

Only as far as section 3 reaches.

1. Settle the path id with the designer (the note at the top).
2. Replace the tour: `init.lua` for load order only, `config.lua`,
   `hooks.lua`. Set `optional_depends` in `mod.toml`.
3. Register the path and the door with Progress. Register charge with Life;
   wipe it in `on_repath`.
4. Register the assembler and the `reinforced` class with Craft; coke and
   steel as the first tier-3 recipes.
5. Stop. The rest of tiers 3 to 7 needs the designer's node list.

## 8. Open, for the designer

1. The path id and label, the door's block and recipe, and what choosing
   gives the player.
2. The node list: every node of tiers 3 to 7, its cost, what it requires
   and what it unlocks.
3. What charge is: how it is made, stored and spent, and whether it is the
   player's alone or also a machine's.
4. Whether machines run unattended, and power between blocks (wire,
   dynamo): what carries it and how far.
5. The assembler's recipes.
6. Which glyphs are punch cards, and what each means.
7. The creature trait vector: its traits, their ranges, and who owns the
   registry that both trees read.
8. Modifying worlds: what may be changed, at what scale, and at what cost.
