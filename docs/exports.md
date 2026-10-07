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
| `glyphs` | `{ [id] = { mask, variants } }`, read-only | This mod's glyphs: the canonical mask of each (`x + 3y + 9z`) and every orientation registered with Craft, smallest first. The twelve of `glyph_table.lua`: `rod`, `plate`, `gear`, `wheel`, `pipe`, `coil`, `ring`, `gnomon`, `cairn`, `bracket`, `nozzle`, `rail`. |
| `network_at(pos)` | `{ x, y, z, domain? }`, whole blocks | The turning network at a block: `{ kind = "turning", supply, demand, size }` (turns supplied, turns its frames need, blocks in it), or nil where none is. |
| `charge_of(stack)` | a stack, as `game.inventory` reports one | The charge a Leyden jar carries (0 to 100, read from its detail `e=<n>`); 0 for anything else, nil for a stack that is not a table. |

That is all, for now. The brief's other fields (§12: `add_charge`,
`register_movement`, `register_source`, `bodies`, `on_fold`) are added as
the machines they read are built.

## Identifiers it registers

All are namespaced `tiamat_default_science:` by the engine.

- **Items:** `theatrum` (the Theatrum Machinarum), `lens` (the burning
  glass), `kite`, `compass`, `notebook`.
- **Blocks:** `antikythera` (the door; hardness 1.8, tag `metal`),
  `frame` (the machine frame), `furnace` and `furnace_lit` (light 13, 7, 2),
  `copper_stock` (one copper ingot's worth, to carve into wire).
- **Tier 3 items:** the movements `stamps`, `trip_hammer`, `pump`,
  `leaching_vat`, `press` and `blowing_engine`; `crank_handle`; `crushed_copper`,
  `_tin`, `_iron`, `_silver`, `_gold`, `_lead`; `pig_iron`, `slag`,
  `blister_steel`; `sand_mould_pipe`, `_cylinder`, `_wheel`, `_plate` and
  `cast_pipe`, `cast_cylinder`, `cast_wheel`, `frame_plate`; `clockwork`;
  `saltpeter`, `black_powder`, `mining_charge`; `treatise`; `blowpipe`,
  `glass_tube`, `glass_jar`, `glass_bulb`, `lens_blank`, `surveyors_staff`,
  `dip_needle`, `drawplate`; and the tool `crowbar` (Craft's `maul`, tier 1;
  an engine tool quick on `#cracked` rock).
- **Tier 4 items:** the instruments `telescope`, `microscope`,
  `chronometer`, `barometer`, `thermometer`, `orrery`; `air_pump`,
  `magdeburg_hemispheres`, `balloon_pack`; `leyden_jar` (charge in its detail,
  `e=<0..100>`) and the movement `friction_globe`; `digester`, `bone_broth`
  (food, through Life), `boiler` and the movement `cylinder`; `coke` (a fuel,
  heat 3), `coal_tar`, `steel_ingot`, `quicksilver`, `oil_of_vitriol`; the
  movements `lead_chamber`, `spinning_frame`, `lathe_bed`; `piston`,
  `bearing`; and the tools `steel_pick`, `steel_axe`, `steel_spade`,
  `steel_chisel` (tier 3, engine tools) and `steel_hammer` (in `#hammer`; the
  chisel in `#chisel`). The block `steel_stock`.
- **Tier 5 items:** the movements `steam_hammer`, `assembly_jig`,
  `winding_drum`, `voltaic_pile`, `electrolysis_cell`, `dynamo_armature`,
  `motor` and `telegraph`; `converter`, `screw`, `spring`, `camera`,
  `photograph` (its plan's name in its detail, `p=<name>`), `silvered_plate`,
  `gravimeter`, `dynamite`, `soda`, `hydrogen`, `cell` (charge in its detail,
  `e=<0..1000>`), `electromagnet`, `carbon_rod`, `difference_engine`,
  `automaton_spring`, `automaton_key`. The blocks `lamp` and `lamp_lit`.
- **Models:** `antikythera`, `frame`, `lamp`, `lamp_lit`, `furnace` and
  `furnace_lit` (`models/<id>.glb`, a PNG beside each), which the blocks of
  the same names are drawn as. Those blocks are `whole` — dug in one piece
  by any tool, never carved; the copper and steel stock are not, being made
  to be carved.
- **Tier 6 items:** the movements `radio`, `receiver`, `tesla_coil`,
  `arc_electrodes`, `resonator`, `radium_cell` and `aether_cell`;
  `crookes_tube`, `xray_viewer`, `oscillator`, `radium_grain`, `helium`,
  `chrome_steel_ingot`, `bakelite`, `aetherium_ingot`, `aetherometer`; the
  tools `chrome_pick`, `chrome_axe`, `chrome_spade`, `chrome_chisel`,
  `chrome_hammer` (Craft's tier 4) and `diamond_drill` (a pick, tier 5). The
  block `cavorite` (light 2, 1, 4), in this mod's dig class
  `tiamat_default_science:reinforced` (pick or chisel, tier 3).
- **Tier 7 items:** `cavorite_soles` and `levitator` (worn, in Life's worn
  slots), the movements `attractor`, `repulsor`, `stasis`, `terraformer` and
  `atmosphere_processor`; `fold_key`, `strange_matter`, `recall_beacon`,
  `unified_field_engine`. The blocks `wormhole` (passable, transparent, light
  6, 4, 12; placed and taken away by this mod alone) and `horizon_glass`.
  The models `core_ring` and `shade`, worn by entities. The sound
  `core_hum`, looped round a turning Core.
- **Domains:** the templates `body_ice`, `body_rust`, `body_regolith`,
  `body_basalt` and `body_glass`, each instanced as `<template>/<star>_<size>`
  at its star's place, with a sky of its own; and `deep`, the misfold.
- **Glyphs, tier 5:** the punched cards `card_1` to `card_8`, which recipes
  name as tools and automata read as instructions.
- **Entities:** automata, the engine's `engine:humanoid` named
  "Automaton <serial>", each with a hold container
  `tiamat_default_science:hold:<serial>` (27 slots).
- **Groups it adds to:** `#quicksilver`, `#oil_of_vitriol`, `#saltpeter` (each
  this mod's own reagent, so they trade across the Fork), `#furnace_carbon`
  (Craft's charcoal and this mod's coke).
- **Stations, into Craft:** `tiamat_default_science:frame` (tool 1, in 2–5,
  out 6–9; run by `runs`, its speed its network's turning) and
  `tiamat_default_science:furnace` (fuel 1, in 2–4, tool 5, out 6–8; heat,
  long, charcoal and coal; the blowing engine boosts it to heat 5 while its
  network turns 8); the group `#smeltable_iron`.
- **Into Progress:** the path `science`, "Natural Philosophy", whose door is
  `antikythera` (Progress registers its recipe as
  `tiamat_default_progress:door_science`: the Keystone, eight bronze gears,
  four bronze ingots, four planks), with branch names and the `near` reveal;
  the path nodes of `tree.lua` that ship — tier 3 so far, 22 of 102 —
  carrying the effect keys `craft.sluice_gold_period` and
  `craft.anvil_strikes` (and, as their tiers ship, `progress.study_percent`
  and `science.*`); the shared nodes `shared.theatrum`, `shared.sundial`,
  `shared.burning_glass`, `shared.kite` (tier 1) and `shared.compass`
  (tier 2); the discoveries `tiamat_default_science.hour`,
  `tiamat_default_science.kite`, `tiamat_default_science.home` and
  `tiamat_default_science.sunfire`, in the group `toybox`.
- **Into Craft:** the recipes `theatrum`, `lens`, `kite`, `compass` (by
  hand) and tier 3's forty-nine (`config.lua`'s `tier3_recipes`: at the
  workbench, the frame, the furnace, Craft's kiln and bloomery, and by
  hand), each qualified `tiamat_default_science:<id>`; the twelve glyphs,
  each in every orientation (81 masks).
- **Into Progress, tier 3:** the studies `study_pig_iron`, `study_lens`,
  `study_clockwork` and `study_steel`; the discovery families
  `tiamat_default_science.invention:*` (group `inventions`) and
  `tiamat_default_science.read:*` (group `reading`), and the toy
  `tiamat_default_science.water`.
- **Into Progress, tier 4:** the studies `study_leyden_jar` and
  `study_steel_ingot`; the discovery families `tiamat_default_science.star:*`
  (group `stars`), `.specimen:*` (`specimens`), `.weather:*` (`weather`) and
  `.climate:*` (`climate`); the toys `.spark`, `.magdeburg`, `.balloon`,
  `.franklin` and `.lightning` (group `inventions`).
- **Into Progress, tier 5:** the studies `study_engine_part`, `study_cell`,
  `study_difference_engine`, `study_automaton`; the discovery family
  `tiamat_default_science.spectrum:*` (group `stars`); the inventions
  `.photograph`, `.blueprint`, `.elevator`, `.telegraph`, `.lamp`.
- **Into Progress, tier 6:** the studies `study_radium`, `study_aetherium`,
  `study_cavorite`; the inventions `.radio`, `.tesla`, `.xray`, `.quake`,
  `.aether`, `.wardenclyffe`.
- **Into Progress, tier 7:** the studies `study_strange_matter`,
  `study_fold_key`; the discovery family `tiamat_default_science.body:*`
  (group `bodies`, 100 each); the inventions `.plating`, `.levitate`,
  `.well`, `.stasis`, `.core`, `.wormhole`, `.recall`, `.drone`, `.deep`,
  `.living`, `.atmosphere`.
- **Into Life:** the ability sources `tiamat_default_science:plating`,
  `:soles`, `:levitator` and `:body`.
- **World options:** `blasting` (default on): whether mining charges loosen
  rock. `the_deep` (default on): whether a Core may fold blind.
- **Into the interface:** the shape-crafter presets `gnomon`, `cairn`,
  `gear`, `wheel`, `pipe`, `coil` and `ring`, each shown to a player who
  holds its node.
- **Dialogs:** `theatrum`, the Theatrum Machinarum; `hold`, an automaton's hold;
  `unified`, the Unified Field Engine's places.
- **Action:** `theatrum` (default key N), which opens the Theatrum for a
  player who carries one.

## Commands it accepts

Chat words, said by a player and swallowed. For anyone: `science` (how far
along the Tinker's Bench the speaker is), `science book` (opens the
Theatrum for a player who carries one), `wire <message>` (sends it down
the telegraph whose key the speaker stands by) and `radio <message>` (sends
it from the wireless set the speaker stands by to everyone near every other
set in the domain). A sentence that only begins with
the word is chat.

## Data it stores or sends

- `cairn:<player UUID>` — the block of the last stone cairn that player
  placed, as `x,y,z,domain`. Forgotten when a compass finds it gone.
- `placer:<x,y,z,domain>` — who placed the frame there, for its speed.
- `read:<player UUID>` — how many treatises that player has learned from.
- `rod:<x,y,z,domain>` — who placed the copper lightning rod there; forgotten
  when a bolt finds it gone.
- `mark:<player UUID>` — the block that player's chronometer last marked.
- `lamp:<x,y,z,domain>` — who placed the arc lamp there.
- `photos:<player UUID>` — how many photographs that player has taken; each
  is a plan, `photo_<mark>_<n>`, in this mod's plans.
- `automata` — the last automaton serial; `automaton:<serial>` — its maker.
- `gate:<x,y,z,domain>` — a paired gate's twin, axis and owner;
  `pending:<player UUID>` — the gate they marked; `gates:<player UUID>` — how
  many pairs they hold open.
- `origin:<player UUID>` — the Core they last folded from;
  `visited:<player UUID>` — the stars whose worlds they have been to.
- `return:<domain>` — a body's return gate. `green:<domain>`,
  `living:<domain>`, `sky:<domain>` — how much of a body is green, whether it
  lives, whether its sky was remade.
- Particles: a compass's needle, to its holder alone; a kite over whoever
  flies it, to everyone within 64 blocks.

## What it reads from other mods

Not exports, listed so the direction is clear: Progress's `register_node`,
`register_discovery`, `discover`, `register_study`, `effects_of` and `has`; Craft's `register`,
`register_station`, `register_group`, `register_tool`, `on_crafted`, `on_first`, `in_group`,
`register_glyph`, `glyph_of` and `ignite` (the burning glass, which listens
for uses at Craft's `unlit_campfire`, `unfired_kiln`, `kiln` and `bloomery`
by name, so it is asked before a fire's box opens); the interface's `add_preset` and
`widgets`; Weather's `wind`, `weather_at`, `weather_for`, `warmth`,
`on_lightning`, `fires_near`, `extinguish` and `add_overlay`; World's
`biome_under` and its blocks by name; Life's `add_food`, `set_ability`,
`pull_drops`, `set_alight`, `push`, `freeze` and its `worn` view.
