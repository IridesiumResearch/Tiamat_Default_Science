<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Tiamat Default Science

Natural philosophy: one of the two doors at the Fork of the default game,
and everything behind it — the real history of technology in order, from
Hero's simple machines to Tesla's tower, and past the aether into gravity
engines and the Fold. `docs/brief.md` is the design, checked against the
engine and the siblings; the mod itself is `mods/tiamat_default_science/`.
This repository sits beside the engine (`Tiamat`) and its siblings, and the
engine's `bundle.toml` pins the commit a release carries.

## What is built

Step 2 of the brief's build order (§17): **the Tinker's Bench**, five
shared nodes a child can reach long before the Fork. A picture book of
recipes (the Theatrum Machinarum); a sundial carved from stone that tells
the hour in sunshine; a burning glass that says what anything is and how
hard; a kite that flies over whoever holds it under the open sky, higher in
a storm; and a wet compass whose needle points north, or home to the stone
cairn its owner placed. The gnomon and the cairn are glyphs, registered with
Craft in every orientation and offered as one-click shapes in the
interface's shape crafter.

Step 3: **the door and the tree.** The Antikythera Mechanism is the science
path's door in Progress; choosing it gives Natural Philosophy, the notebook
and the Theatrum. All 102 nodes of tiers 3 to 7 are data in `tree.lua`,
which `tools/check_tree.py` proves sound and writes into `docs/history.md`;
the tiers whose content is built are registered, tier 3 first. The twelve
glyphs are `glyph_table.lua`, which `tools/glyphs.py` checks against magic's.

Step 4: **tier 3, Mechanica** (0.2.0). A machine frame takes a movement —
stamps that crush ore for a third more metal, a trip hammer, a screw pump, a
leaching vat for saltpetre, a printing press — and turns at the speed its
network supplies: a crank handle, a carved plank water wheel in water, or a
windmill high in the wind, joined by carved rods and gears. A brick furnace
with a blowing engine and a turning shaft makes pig iron, then wrought iron,
sand-cast parts and, over a day and a night, blister steel. Black powder and
mining charges, glass blown and ground, the surveyor's staff and the dip
needle, clockwork from carved gears, and copper drawn into stock. Where the
build departs from the brief is its §2.4.

Step 5: **tier 4, natural philosophy** (0.3.0). The instruments that pay
the long tail of insight — a telescope that logs every star, a microscope
every material, a barometer every kind of weather and a thermometer every
climate — with the chronometer, the orrery, the Magdeburg hemispheres and a
balloon. Charge in Leyden jars, filled by a friction globe, a lightning rod
or Franklin's kite. The Newcomen engine: a burning furnace with a boiler,
a copper pipe, and a frame with a cylinder. Coke, crucible steel, steel
stock and steel tools; quicksilver, oil of vitriol, the water frame and the
lathe. Its departures from the brief are §2.5.

## What is here

| File | What |
|---|---|
| `mods/tiamat_default_science/` | The mod. `init.lua` decides load order; `config.lua` holds every number; the rest is one file a system. |
| `tools/make_textures.py` | Draws the placeholder textures. Standard library only; the same bytes on every machine. |
| `tools/check_tree.py` | Proves the tree sound from `tree.lua`, prints the pacing table (brief §13), and with `--write` writes `docs/history.md`. |
| `tools/glyphs.py` | Proves the glyph table sound, and that no glyph meets magic's or the interface's shapes. |
| `tests/native/` | The mod run in the engine's real script VM, beside the REAL sibling mods, with a fake server around it. |
| `docs/brief.md` | The design, and §2.1: what was checked and what changed. |
| `docs/exports.md` | What other mods may call, and every id this mod registers. |
| `docs/sibling-asks.md`, `docs/engine-asks.md` | What this mod needs from others, with what stands in until then. |
| `stubs/game.lua`, `AGENTS.md` | The engine's API, vendored (MIT). Re-copy when the engine moves. |

## Check it

Without starting a server, from the engine repository, over a directory
holding the engine's `core` mods, every sibling and this mod:

```sh
cargo run -p server -- --check-mods <that directory>
```

The native check loads the real siblings from their repositories, so the
engine and each sibling must be checked out beside this one:

```sh
cargo run --manifest-path tests/native/Cargo.toml
```

## Your editor

Any editor with the Lua language server reads `.luarc.json` and gets
completion, signatures and types for every `game.*` call from `stubs/game.lua`.
The stubs are kept in step with the engine by its CI, so when you update the
engine, copy its `api/stubs/game.lua` over yours.

## Where to read next

- `AGENTS.md` — the rules that fail quietly when broken, and the shape of every
  kind of thing a mod can register.
- `stubs/game.lua` — every function, with the reason it behaves as it does.
- The engine repository's `game/` directory — reference mods, each the
  smallest thing that proves one mechanism.

## Licence

GPL-3.0-only, © Iridesium, with an Additional Permission under GPLv3 §7 in
`LICENSE.EXCEPTION` (version 1.0, 24 September 2026): a mod that interacts
with Tiamat Default Science only through its exports, the engine's scripting API or
the network protocol is an independent work and may be licensed however
its author likes. Copying or adapting this mod's code or assets is not
covered by that permission and stays under the GPL. `docs/exports.md`
lists the exports; the engine's `MOD-LICENSING.md` has the plain-language
version and a matrix of what needs which permission. Third-party assets
are listed in `docs/assets.md` with their own licences. Contributions are
taken under the Developer Certificate of Origin with authors retaining
copyright; see `CONTRIBUTING.md`.
