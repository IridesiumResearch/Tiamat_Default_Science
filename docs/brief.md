<!-- SPDX-FileCopyrightText: Iridesium -->
<!-- SPDX-License-Identifier: GPL-3.0-only -->

# Tiamat Default Science — the brief

*Draft 2, 2026-09-29: the designer's build prompt (draft 1, 2026-09-28), with every engine and sibling fact re-checked against the stubs, the engine's source and the sibling repositories on 2026-09-29 and corrected in place; what changed and why is §2.1, and what was decided with the designer that day is §2.2. It replaces draft 0 of this file. Draft 1 was: a brief for an AI coding assistant and the person supervising it. Design and plan only. Companion to `Tiamat_default_magic-PROMPT.md` (its sibling on the other side of the Fork), to the shipped briefs of `tiamat_default_craft` and `tiamat_default_progress`, and to the long plan `schism_design.md`. Read, in this order: the engine's `api/AGENTS.md` and `api/stubs/game.lua`; the `docs/exports.md` of World, Life, UI, Craft, Progress and Weather; then this. Every engine and sibling fact below was checked against those files on 2026-09-28. **Where they disagree with this text, they win**, and the disagreement goes in `docs/engine-asks.md` or `docs/sibling-asks.md`.*

*Not "tech": the id is `tiamat_default_science`, the path id `science`. Schism's `schism_tech` is superseded by this brief.*

---

## 0. One paragraph

`tiamat_default_science` is Natural Philosophy: the science door of Progress's Fork and everything behind it. Its apprentice bench and tiers 3 to 5 are **the real history of technology, in order** — Hero's simple machines, Vitruvius' water wheel, the escapement, Agricola's mines, the blast furnace and crucible steel, Galileo's telescope and Hooke's microscope, Guericke's vacuum, the Leyden jar and Franklin's kite, Newcomen and Watt, Maudslay's lathe, Jacquard's cards and Babbage's engines, Volta, Faraday and Morse — and its sixth is **Tesla's**: alternating current, the coil, wireless power, the teleautomaton, the earthquake machine, Wardenclyffe. Then, at exactly the moment history found nothing (Michelson and Morley, 1887), this world **finds the aether**, and the tree leaves history for a steam-and-lightning future of cavorite, gravity engines, wormholes and a gravity drive that folds space — with the cold, wrong, beautiful dread of *Event Horizon* (1997) at its very top. It adds **107 nodes** over tiers 1–7, is built to take **roughly sixty hours** to climb in full, gives a small child a kite, a sundial and a burning glass in its first half hour, and registers **ten blocks**.

---

## 0.1 Where it sits

| Mod | What this mod takes from it |
|---|---|
| `tiamat_default_world` | Ores (`copper_ore`, `tin_ore`, `iron_ore`, `coal`, `calcite` flux, `lead_ore`, `silver_ore`, `gold_ore`, `chromium_ore`, `diamond`, `orichalcum`, `pitchblende`), `white_sand`, `sand`, `wet_clay`, stone, wood; biomes and `depth_under`/`depth_band` for instruments; `climate` |
| `tiamat_default_life` | `add_food` (broth), `set_alight` (the Tesla coil's arc), `drop` entities (the electromagnet), the `horse` and `lead` (the Magdeburg hemispheres), `on_kill` for specimens; `wool`; the `worn` view (read with `game.inventory`) |
| `tiamat_default_ui` (optional) | Tabs, widgets, theme; the shape crafter, where every part is carved |
| `tiamat_default_craft` | The recipe registry, stations, fuels, groups, tool registration and dig classes, `register_glyph` / `glyph_of`, `perform`, `can`, `wear`, the firsts; its kiln, anvil, workbench, bloomery; its `iron_bar`, `iron_plate`, `iron_frame`, `iron_nails`, `bronze_gear`, ingots, `glass`, `charcoal`, `cloth`, `leather` |
| `tiamat_default_progress` | `register_path` (the door), `register_node`, `register_study`, `register_discovery`, `award`, `has`, `effects_of`, `on_fork` / `on_repath` |
| `tiamat_weather` (optional) | `weather_at`, `weather_for` (windmills, kites, the barometer), `warmth(x, y, z)` (the thermometer), `on_lightning` (the lightning rod), `extinguish` (rods put out lightning fires), `ignite` |
| `tiamat_default_magic` | **Nothing.** Siblings, never dependants. Both are loaded so a science player and a magic player can trade; neither names the other. |

Craft owns recipes, stations, fire and tools. Progress owns insight, nodes and the lock. Life owns bodies, food and creatures. This mod owns **what machines are**: its movements, its two power networks, its instruments, its constructs and the Fold — and reaches every owner only through their exports.

---

## 1. Repository shape and manifest

Same skeleton as the siblings: `mods/tiamat_default_science/`, vendored `AGENTS.md` and `stubs/game.lua`, `tests/native`, `tools/`, `docs/exports.md`, `docs/engine-asks.md`, `docs/sibling-asks.md`, `docs/pacing.md`, `docs/history.md` (sources, §15).

```
mods/tiamat_default_science/
  mod.toml
  init.lua            load order only
  config.lua          EVERY number: costs, ticks, power ratings, losses, radii, caps, yields, pacing targets
  util.lua  hooks.lua  store.lua
  items.lua           every item, from a data table (§9)
  blocks.lua          the ten blocks (§8)
  path.lua            register_path (the Antikythera Mechanism), on_choose, on_repath
  tree.lua            the node table (§5) → progress.register_node
  apprentice.lua      the shared Tinker's Bench (§4)
  frame.lua           the frame station, movements, the job loop that calls craft.perform
  furnace.lua         the furnace station, boosts, the metallurgy recipes
  networks.lua        the two networks: turning and charge (§6.2)
  sources.lua         water wheel, windmill, engines, piles, cells, lightning, gravity engine
  instruments.lua     held instruments: glass, compass, needle, staff, telescope, microscope, barometer…
  electric.lua        jars, cells, lamps, telegraph, radio, coils
  automata.lua        cards, decks, automata (entities)
  glyphs.lua          masks, the 48 symmetries, register_glyph for every variant
  constructs.lua      the bounded pattern matcher and every construct (§7.3)
  gravity.lua         cavorite, plating, wells, levitator, stasis
  fold.lua            the Core, wormholes, star bodies, the Deep, terraforming
  studies.lua         register_study / register_discovery / award
  primer.lua          the Theatrum Machinarum (picture pages)
  screens.lua  commands.lua  exports.lua
  hud.lua             the instruments' read-outs (one HUD script)
  textures/ sounds/ models/ pictures/
```

```toml
id = "tiamat_default_science"
name = "Tiamat Default Science"
version = "0.1.0"
description = "Natural philosophy: machines, steam, electricity, Tesla — and past the aether, gravity and the Fold."
license = "GPL-3.0-only"
depends = [
  "core >=0.1",
  "tiamat_default_world >=0.1",
  "tiamat_default_life >=0.1",
  "tiamat_default_craft >=0.4",
  "tiamat_default_progress >=0.1",
]
optional_depends = ["tiamat_default_ui", "tiamat_weather"]

[[world_option]]
id = "blasting"
name = "Blasting charges"
description = "May charges loosen rock? Off: black powder and dynamite are study items only."
default = 1

[[world_option]]
id = "the_deep"
name = "The Deep"
description = "May a misfolded Core open the Deep? Off: strange matter is refined from orichalcum instead, slowly."
default = 1
```

No `[theme]`, no `conflicts` — in particular not `tiamat_default_magic`. Without the interface the *Theatrum* and the frame, network and automata tabs are dialogs; without Weather, windmills turn at their calm rate, the kite flies at a fixed height, the barometer and thermometer read nothing, and no lightning is caught (§2.2).

---

## 2. Engine and sibling facts this design rests on

Everything in Craft's and Progress's briefs §2 still applies. The ones that shape this mod:

| Need | Fact (source) | Consequence |
|---|---|---|
| A path and a door | Progress `register_path`; the door recipe adds the Keystone and `shared.keystone` (Progress exports) | Door = `tiamat_default_science:antikythera` (§3). |
| Path nodes before the Fork | refused while a player has no path; tier ≥ 3 must reach `shared.fork` (Progress `nodes.lua`) | The child's door is the **Tinker's Bench**: five `shared.*` nodes this mod registers (§4). |
| Node limits | tier 0..7; cost ≤ 100,000; ≤ 8 requires; ≤ 8 integer effects (Progress `config.lua`) | Proven by `tools/check_tree.py` (§13). |
| Stations that are driven by something other than fuel | Craft `register_station{ auto = true }` — "its recipes are not pressed"; the campfire is one, burned by Craft's own code; `perform(uuid, recipe_id, container)` is one transaction on a station's slots (Craft exports) | The **frame** is an `auto` station; this mod's power loop decides when a frame's recipe is done and calls `craft.perform` for it. Recipes, screens, containers and digging-out stay Craft's. Ask **C-S1** would let Craft run it. `perform` is always *attended* — a tool missing from the slots is looked for in the owner's inventory (Craft `registry.lua`); **C-S7** would export the unattended form. |
| Heat | heat tiers 1..9 from fuels; `boost = { tool, heat }` (Craft exports) | The **furnace** is a Craft heat station: coke is heat 3, the blowing engine boosts to 5 (blast), the converter tool is Bessemer. |
| Carved parts | `register_glyph`, `glyph_of`; a carved stack is never a Craft ingredient (Craft exports) | Glyphs work today; assembly from carved parts needs **C-M1/C-S3** (shared with magic), fallback §7.5. |
| Node effects on Craft | Craft sums `craft.*` effects over every node a player holds (Progress `effects_of`) | Science nodes carry `craft.smelt_ore_units`, `craft.sluice_gold_period`, `craft.anvil_strikes`… (§5.6). |
| Reading what a player looks at | `game.looking_at(uuid)` → block `{x,y,z,material,face}` in **cell** coordinates (three per block; divide by 3) or an entity; `game.star_in_view(uuid)` → `{ id, alignment }`; `game.stars()` → `{ id, x, y, z, magnitude, warmth }` (stubs) | Instruments are held items that read these; no new blocks. |
| Damage | Life exports none; exports `set_alight` (Life exports) | The Tesla coil's arc sets hostile creatures alight. Stasis on Life's creatures: **L-S2**. |
| Movement and gravity | `set_player_abilities` (fly, speed — last writer wins, client-predicted, and Life writes it); `push_player(uuid, impulse)` — "added, not set", **not** documented as predicted; **no per-player or per-domain gravity** (stubs) | Low gravity is an upward impulse per tick, tried in a real window for rubber-banding before it ships; flight is the same until **L-S3** and **E-S1**. |
| The sky | `set_sky_modifier` is one per player, last writer wins, and **Weather writes it for everyone**, whenever its value changes (Weather `fx.lua`) | The Core's darkening and the atmosphere processor wait on Weather ask **Wx-S2** (= magic's Wx-M1, a layered overlay). This mod never calls `set_sky_modifier` until then. |
| Long recipes | Craft refuses any recipe over **72,000 ticks** (`max_ticks`) | Blister steel is one in-game day (24,000 ticks at the core sky's day), one recipe (§2.2). Stations pause while their chunk is unloaded (Craft `furnace.lua`), so every time in this brief is time with a player near. |
| Detailed stacks | a stack with a `detail` is never a Craft ingredient | Charged jars and cells (detail `e=`) are never ingredients; recipes take **empty** jars and cells, which carry no detail until first charged. |
| Shared reagents | magic also makes saltpeter, oil of vitriol and quicksilver | Each mod registers its own item and adds it to the Craft groups `#saltpeter`, `#oil_of_vitriol`, `#quicksilver`; every recipe names the group, so reagents trade across the Fork. |
| Worlds at stars | `create_domain(template, key, { position })` makes a body AT a star, which then has that star's sky; generator told `{x,y,z,seed}` only (stubs; engine `core_space` proves the mechanism) | Star bodies use the **slot trick** (§6.8): every coordinate in every domain lies in −60,000..59,999 (engine `coords.rs`), so bodies are tiled inside that; **E-S2** would retire it. |
| Plans | `plans.capture/stamp/info/list/forget`, 64 per side, paced by the engine (stubs, `core_plans`) | The daguerreotype captures; the blueprint stamps — paying blocks first (§6.6). |
| Lightning | Weather `on_lightning(fn(x,y,z))` after every bolt (Weather exports) | Franklin's rod. |
| Actions | `register_action` is stored and inert until the engine's Task 13 (stubs) | Every screen also opens by using its item and by chat until then. |
| Using a station | Craft's unlisted `on_use` opens a station's box, asked in load order ahead of this mod (Craft `stations.lua`, `hooks.lua`) | The crank is heard through `register_on_use(fn, { materials = { frame } })`, asked first, and answers `nil` unless a `crank_handle` is held. |
| Pictures | ≤ 512 per server | The *Theatrum* uses ≤ 120. |
| Models | ≤ 64 per server | Three (§10.1). |

### 2.1 Checked on 2026-09-29 — what changed from draft 1

Every claim in §2 and below was re-checked against `stubs/game.lua`, the engine's source and the sibling repositories. These did not hold, and the text has been corrected where they appear:

| Draft 1 said | What is so (source) | What changes |
|---|---|---|
| Star bodies at `x0 = (slot × 2 + 1) × 2^20` | Every block coordinate in every domain lies in −60,000..59,999 (engine `crates/core/src/coords.rs`); `move_player` refuses outside it. Slot 0 was already past it | The slot trick: 15 × 15 slots of 8,000 blocks per kind, 225 bodies a kind; §6.8 |
| The burning glass lights a laid campfire or kiln | Craft exports no way to light anything: a campfire lights only to a held `fire_striker`, a furnace only through its own striker path (Craft `fire.lua`, `furnace.lua`) | A magnifier until ask **C-S6**; §4, §6.4 |
| The Difference Engine makes studies pay 20 % more | `register_study` pays a fixed `insight`; Progress reads no effect when it pays (Progress `research.lua`) | Ask **P-S2**; the effect is carried and inert until then |
| A star pays 2 with the spectroscope (`science.star_insight`) | A discovery family has one value for every member (Progress `insight.lua`) | A second family, `spectrum:*`; §6.9 |
| Blister steel takes 7 days, a three-step chain under C-S4 | Stations pause while their chunk is unloaded (Craft `furnace.lua`); a day is the sky's `day_length_ticks`, 24,000 in the core sky — so 7 days was 2 h 20 min with a player standing by, on the spine at tier 3 | One day, one recipe (§2.2); C-S4 withdrawn |
| World has no pitchblende; a lead-ore stand-in until W-S1 | World generates `pitchblende` from 1,200 down (World `blocks.lua`, `generate.lua`) | Stand-in deleted; W-S1 marked landed. Cinnabar is still missing (W-M1) |
| Bench nodes require `firecraft`, `theatrum`, `burning_glass` | Progress resolves no bare id; a node requiring an unregistered one is disabled with everything after it (Progress `nodes.lua`) | Written `shared.*`; `tree.lua` expands bare ids to `science.` itself |
| Using the frame cranks it | Craft's unlisted `on_use` opens a station's box, in load order ahead of this mod (Craft `stations.lua`, `hooks.lua`) | A `crank_handle` in hand, heard by a listed `on_use` that is asked first; §6.1 |
| `perform` runs the frame on the tools in its tool slot | The exported `perform` is always attended: a tool not in the slots is looked for in the owner's inventory (Craft `registry.lua`) | Documented; ask **C-S7** |
| The jig `game.take`s carved parts from the frame | `game.take` takes from a player; a container is `game.container_take`, which matches shape exactly (stubs) | `container_take` / `container_give`; §7.5 |
| A frame leaves the list on `on_dig_complete` | That hook is a veto asked before removal, which a later mod may refuse; plan-stamped stations have no placer (Craft `stations.lua`) | A slow sweep confirms removal; ownerless frames wait to be claimed; §6.1 |
| Steel tools "speed 8/10/14" through Craft's `register_tool` | Craft's takes `{ id, type, tier, uses }`; speed is the engine's `speed_multiplier` (Craft `tools.lua`; stubs) | Split between the two; §6.3 |
| The rod puts out every fire within 16 | `extinguish(x, y, z)` puts out one block, and no list of fires is exported (Weather `exports.lua`) | The strike's own fire; ask **Wx-S4** |
| `on_lightning` gives the strike column | A bolt that found no ground is reported 40 blocks above a player, in the air (Weather `docs/exports-contract.md`) | The rod compares x and z only |
| Weather has wind as `dx, dz, strength` | `wind(x, z, tick) → { x, z }`, a direction with no strength, not exported (Weather `climate.lua`) | Wx-S1 reworded |
| `weather.warmth` | `warmth(x, y, z)`, 0..1000 | So written |
| Weather does not run on a body's domain | Weather has no domain logic; it sends sky and clouds by x and z (Weather `fx.lua`) | Ask **Wx-S3** |
| Weather writes the sky modifier continuously | Only when its value changes | Wx-S2 still stands (one modifier a player, last writer wins) |
| Until Wx-S2, a `flash` of dark colour | `flash` adds light; it cannot darken (stubs) | The hum alone |
| Fold at `star_in_view` alignment ≥ 0.98; a misfold when no star is in view | The nearest star is always answered; 0.98 is about 11° off, and with 2,048 stars "no star in view" almost never happens (stubs) | 0.9998 (a degree); folding blind is an explicit choice in the Core dialog |
| The Deep's drop override "only in that domain" | A dig event has no `domain`; a drops override is last-answer-wins (stubs) | Domain kept per player from `register_on_player_move`; §6.8 |
| `bone_broth`: `hearty`, warm | `add_food` takes `effects = { { id, ticks } }` and `temperature = "warm"`; `hearty` is an effect id (Life `exports.lua`, `effects.lua`) | So written; §9 |
| Life supplies cloth and leather | `cloth` and `leather` are Craft's; only `wool` is Life's (Craft `materials.lua`) | §0.1, §4 |
| Cave earth, sand, clay | World has no cave earth; glass is `white_sand` + `#ash`; clay is `wet_clay` / `dry_clay` (World `blocks.lua`; Craft `recipes.lua`) | `dirt` for saltpetre until **W-S2**; exact ids |
| Craft's iron blowpipe | Craft has none | This mod's `blowpipe` |
| The door is "the shared tree's own last lesson" | Craft casts bronze gears (kiln, heat 2, `mould_gear`), but no shared node gates it | Reworded |
| The magnetism node finds iron ore | The `metal_ore` tag is every metal ore (World `blocks.lua`) | "Metal ore" |
| Terraforming seeds World's covers | World exports no cover call | `set_block` of World's plant ids |
| Cards are any one-face carving, numbered 1..510 | `plate`, `ring`, `rail` and `bracket` lie in one face, so seven numbers were glyphs; a rotated card had another number; an edge carving lies in two faces | A canonical reading; §6.6 |
| The Magdeburg hemispheres held by two horses | Life's `lead` makes a creature follow its holder; nothing ties one to a block (Life `husbandry.lua`) | One horse, led; two with **L-S6** |
| Cavorite soles need L-S5 | Life's worn view is an inventory: `game.inventory(uuid, "tiamat_default_life:worn")` | L-S5 withdrawn |
| L-S4 asks permission to move Life's drops | The engine does not check who owns an entity (engine `mlua_vm.rs`) | A courtesy to agree, not a permission |
| `on_repath` as an ordinary event | It fires only with Progress's `repath` world option, which revokes every `science.` node without refund and halves insight (Progress `fork.lua`) | Stated; restoring anything is this mod's |
| The *Theatrum* on N, automata on U | `register_action` is "stored now, inert until Task 13" (stubs) | Also by using the item and by chat until then |
| Node `label` ≤ 32, text ≤ 90 | Progress keeps 48 and 200 (`nodes.lua`); ours are tighter by choice | Unchanged: ours |

**Held**, and not repeated above: every other Craft, Progress, World, Life, Weather, interface and engine call and id the text names; the UI's Pillar (74752) and Slab (1838599) masks; all twelve glyph masks against their drawings, their variant counts under the 48 symmetries, and no collision with magic's fifteen or the UI's Stairs; any mod may register `shared.*` nodes; and the tree's own arithmetic — 107 nodes, 66,870 insight, 40,050 on the spine, ≈ 58 h — recomputed from the tables.

**Design repairs in this draft**, the designer's to overrule:

- The dip needle and the gravimeter read the six axis rays from the player (96 and 144 reads) instead of a 33³ and a 49³ volume — tens of thousands of `get_block` crossings a reading, which §15's rule 1 forbids.
- Principia was "the root of everything gravity", but only Cavendish requires it; the gravity lane arrives through the aether. The text now says what the graph does. The other fix — `luminiferous_aether` requiring `newtonian_mechanics` — would add 250 to the spine.

### 2.2 Decided 2026-09-29

- **Charge lives in things.** Jars, cells and networks hold it and machines run on it; a carried cell keeps its charge through a repath, because items are the world's. Draft 0's note that charge would be a Life stat drawn in Life's tray is retired, and this mod draws a held cell's charge in its own HUD.
- **Dependencies match magic's.** Hard on `core`, World, Life, Craft and Progress; optional on the interface and Weather (§1).
- **Science's creatures are made, not bred.** Draft 0 recorded that both trees end at making creatures through a shared trait vector (genomes here, essences in magic). This tree's answer is the automaton and the gravitic drone; genetics stays out of scope (§19) and science does not read the trait vector. Magic and Life should hear this before either builds that vector as shared.
- **Blister steel is one day**: 24,000 ticks, one recipe under Craft's 72,000-tick cap. The node's text says history took a week.

Also departing from draft 0, and to be said to the sibling concerned: Craft expected this mod to write "no job loop of its own", and it writes one (§6.1) until C-S1; and Progress expected four to six nodes a tier, where this tree has 15 to 25 — Progress allows it, and P-S1 should check its tree screen against it.

---

## 3. The door: the Antikythera Mechanism

```lua
progress.register_path{
  id       = "science",
  label    = "Natural Philosophy",
  door     = "tiamat_default_science:antikythera",
  recipe   = { inputs = {
    { "tiamat_default_craft:bronze_gear", count = 8 },   -- it is thirty bronze gears in a wooden case
    { "tiamat_default_craft:bronze_ingot", count = 4 },
    { "tiamat_default_craft:plank", count = 4 },
  } },
  sentence = "The dials turn once, for you alone. This binds you; the other door closes.",
  refusal  = "The bronze wheels will not turn for you.",
  on_choose = function(uuid) path.on_choose(uuid) end,
}
```

The Antikythera Mechanism (c. 100 BC) is the oldest known geared computer — and Craft already casts bronze gears (kiln, heat 2, the gear mould), so the door is made of things a player at the Keystone can already make. A placed Mechanism is a block (hardness 1.8, tags `metal`) whose dials turn (a slow `anim`-less particle sweep) when used.

`path.on_choose(uuid)`: `progress.unlock(uuid, "science.natural_philosophy")` (cost 0); gives a `notebook` (the instrument log) and a `theatrum` if missing; cue `science_door`; chat: *"The dials have turned. Build a frame."*

`on_repath` from science (only in a world made with Progress's `repath` option, which revokes every `science.` node without refund and halves insight — restoring anything on a return is this mod's business, not Progress's): automata dormant (records kept), carried cells keep their charge (items are the world's), the player's gates and bodies **sealed not destroyed**, network ownership kept (machines keep running — a factory is a place, not a player).

---

## 4. The children's door — the Tinker's Bench (shared, tiers 1–2)

A six-year-old will never reach the Fork. So the first taste of science is five `shared.*` nodes, 5 to 20 insight, open before the Fork to **every** player, kept through the Fork and through a repath. The sundial needs only stone (minute one); the kite wants Craft's `cloth` (three of Life's wool); the burning glass wants Craft's glass (a heat-2 kiln recipe, Craft's second hour); the compass, iron.

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `shared.theatrum` **Theatre of Machines** ★ | 5 | `shared.firecraft` | APPR | Leupold's *Theatrum Machinarum* (1724), a picture-only primer: the science recipe book a child can read. Recipe: 1 `leather`, 2 `bark_strip`, 1 `charcoal` (hand). |
| `shared.sundial` **The Sundial** ★ | 10 | `shared.theatrum` | APPR | Carve a *gnomon* (the shape-crafter preset) from any stone: use it in daylight and it tells the hour. Egypt, 1500 BC. |
| `shared.burning_glass` **The Burning Glass** ★ | 15 | `shared.theatrum` | APPR | A ground glass lens. Held as a magnifier it names any block and its hardness; once Craft can be asked to light a fire (**C-S6**), it lights a laid campfire or kiln from the noon sun, no striker. |
| `shared.kite` **The Kite** ★ | 10 | `shared.theatrum` | APPR | Cloth, sticks and cord (China, 5th c. BC). Held in the open it flies above you, higher in wind and storm, and tugs when you run. |

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `shared.compass` **The Wet Compass** ★ | 20 | `shared.burning_glass` | APPR | A needle magnetised on iron floating in a bowl (Song dynasty): points north, and to your *cairn* glyph (your home marker) once you place one. |

**Design rules for the bench and every ★ node:**

1. **Instantly visible.** A kite in the sky, the hour told, a fire lit by sunshine, a needle that finds home, water that climbs.
2. **Three ingredients at most, one station, no timers over 60 seconds, no failure, nothing lost.**
3. **Readable without reading.** The *Theatrum Machinarum* (§11) is a book of machine pictures.
4. **One-click carving.** The sundial's gnomon and the cairn are UI presets (ask **U-S1**, shared with magic's U-M1). The rod and plate are the UI's own Pillar and Slab.
5. **Nobody gets lost.** The compass pointing to your cairn is the most useful thing a small child can own in a world 118 km across.
6. **Toybox discoveries** (§6.12).

---

## 5. The tree (tiers 3–7)

Legend: ★ a child can enjoy it; ◆ on the **spine** (an ancestor of the capstone). Branches: **MECH** mechanics and power, **METL** metallurgy, **OPTI** optics, instruments and astronomy, **HEAT** heat and steam, **ELEC** electricity and magnetism, **CHEM** chemistry, **AUTO** automata, printing and computing, **TESL** the Tesla era, **GRAV** gravity and the aether, **FOLD** the Fold. A requirement without a prefix is a `science.` node.

Leaves (rewards, not tolls): `shared.sundial`, `shared.kite`, `shared.compass`, `science.archimedes_screw`, `science.windmill`, `science.de_re_metallica`, `science.trip_hammer`, `science.magnetism`, `science.printing_press`, `science.microscope`, `science.barometer`, `science.thermometer`, `science.franklins_kite`, `science.balloon`, `science.analytical_engine`, `science.cavendish_balance`, `science.otis_elevator`, `science.cyanotype`, `science.dynamite`, `science.incandescent_lamp`, `science.diamond_drill`, `science.bakelite`, `science.stasis_field`, `science.atmosphere_processor`, `science.recall_beacon`, `science.gravitic_drones`, `science.unified_field`.

### 5.1 Tier 3 — *Mechanica*: antiquity to the Renaissance

The frame, the crank and the water wheel come first and are ★: the first thing after the Fork is a machine a child can turn by hand and then watch a river turn for them.

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `science.natural_philosophy` **Natural Philosophy** ★ ◆ | 0 | `shared.fork` | MECH | Granted free on choosing the Antikythera Mechanism. The root. |
| `science.machine_frame` **The Machine Frame** ★ ◆ | 100 | `natural_philosophy` | MECH | The **frame** station: a movement in its tool slot makes it a machine. The hand crank movement: use it to turn it. "Crank it!" |
| `science.simple_machines` **The Five Simple Machines** ★ ◆ | 80 | `natural_philosophy` | MECH | Hero of Alexandria: lever, wheel & axle, pulley, wedge, screw. Rod, gear and wheel glyphs; a crowbar (fast on cracked rock). |
| `science.glassworks` **The Glassworks** ◆ | 80 | `natural_philosophy` | OPTI | Lens, tube, jar and bulb blanks from Craft glass (kiln, with this mod's iron `blowpipe`). |
| `science.wire_drawing` **Wire Drawing** ◆ | 80 | `simple_machines` | ELEC | The drawplate: a copper ingot → a block of **copper stock**, carvable into wire rods. |
| `science.gearing` **Gear Trains** ★ ◆ | 100 | `simple_machines`, `machine_frame` | MECH | Shafts (rod glyphs) and gears carry turning power up to 16 blocks from its source to frames. |
| `science.archimedes_screw` **Archimedes' Screw** ★ | 100 | `gearing` | MECH | A wooden screw column lifts water one block per turn: crank it and watch the water climb. |
| `science.water_wheel` **The Water Wheel** ★ ◆ | 120 | `gearing` | MECH | Vitruvius' wheel (a wheel glyph in plank) in moving water: steady power. |
| `science.windmill` **The Windmill** ★ | 120 | `gearing` | MECH | A post mill: power grows with height and with the weather — twice in a storm. |
| `science.stamp_mill` **The Stamp Mill** | 120 | `water_wheel` | METL | The stamps movement crushes ore: 20 units of ore give 27 of crushed ore, which smelts like ore — a third more metal. |
| `science.de_re_metallica` **De Re Metallica** | 120 | `stamp_mill` | METL | Agricola (1556): buddles, washing and mine pumps. Sluice gold every 6th wash; powered pumps drain a flooded shaft. |
| `science.trip_hammer` **The Trip Hammer** | 120 | `water_wheel` | METL | The cam-driven hammer movement makes plates, nails, chain, hinges and heads by power; every anvil recipe one blow less. |
| `science.blast_furnace` **The Blast Furnace** ◆ | 160 | `water_wheel` | METL | The **furnace** station with water-driven bellows: iron ore, charcoal and calcite flux → pig iron and slag. |
| `science.finery_forge` **The Finery** ◆ | 120 | `blast_furnace` | METL | Pig iron → Craft's wrought iron bars, three for every two pigs. |
| `science.cast_iron` **Cast Iron** ◆ | 120 | `blast_furnace` | METL | Sand-mould casting: cast iron pipe, cylinder, wheel and frame plates. |
| `science.saltpetre_works` **The Saltpetre Men** ◆ | 100 | `machine_frame` | CHEM | `dirt` and `#ash` leached in the frame → saltpeter (cave earth when World has it: **W-S2**). |
| `science.gunpowder` **Black Powder** | 140 | `saltpetre_works` | CHEM | The *Wujing Zongyao* ratio (1044): a mining charge that loosens 3×3×3 of rock into drops. Hurts no one. |
| `science.escapement` **The Escapement** ◆ | 140 | `gearing` | MECH | The verge and foliot (c. 1300): the clock movement; frames can be timed; clockwork parts. |
| `science.alhazen_optics` **The Book of Optics** ★ ◆ | 100 | `glassworks` | OPTI | Ibn al-Haytham (1021): the reading stone and the surveyor's staff — distance, height and depth of whatever you look at. |
| `science.magnetism` **De Magnete** ★ | 120 | `natural_philosophy` | ELEC | Gilbert (1600): the dip needle leans toward the nearest metal ore within 16 blocks along the six directions. |
| `science.printing_press` **The Printing Press** ★ | 150 | `simple_machines`, `cast_iron` | AUTO | Gutenberg's screw press and lead type: print a treatise of what you have learned. Any player who reads it gains insight once. |
| `science.cementation_steel` **Blister Steel** ◆ | 160 | `finery_forge` | METL | Iron bars packed in charcoal, a day and a night in the furnace (history took a week) → blister steel. |

### 5.2 Tier 4 — Natural Philosophy, 1600–1760

Instruments (each a long-tail discovery source), the vacuum, the first charge, the first steam, the first steel, and Newton.

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `science.telescope` **The Telescope** ★ ◆ | 180 | `alhazen_optics`, `cast_iron` | OPTI | Galileo (1609): look at a star and log it. Every star is a discovery. |
| `science.microscope` **The Microscope** ★ | 180 | `alhazen_optics` | OPTI | Hooke's *Micrographia* (1665): examine any material; each is a discovery. |
| `science.pendulum_clock` **The Pendulum** ◆ | 150 | `escapement` | MECH | Huygens (1656): every machine 10 % faster. |
| `science.chronometer` **The Chronometer** ★ ◆ | 200 | `pendulum_clock`, `telescope` | OPTI | Harrison (1761): longitude — your coordinates on the HUD, and a needle to any waypoint. |
| `science.cinnabar_roasting` **Quicksilver** | 150 | `blast_furnace`, `glassworks` | CHEM | Cinnabar roasted in the furnace with a condenser → quicksilver. |
| `science.barometer` **The Barometer** ★ | 180 | `cinnabar_roasting` | OPTI | Torricelli (1643): the weather here and whether it is coming or going; each kind of weather measured is a discovery. |
| `science.thermometer` **The Thermometer** | 150 | `cinnabar_roasting` | OPTI | Fahrenheit (1714): reads the warmth anywhere; each biome's warmth logged is a discovery. |
| `science.vacuum_pump` **The Air Pump** ★ ◆ | 220 | `cast_iron`, `glassworks` | HEAT | Guericke (1650): vacuum. The Magdeburg hemispheres (lead a horse against them and try). |
| `science.electrostatics` **The Friction Machine** ★ ◆ | 200 | `glassworks`, `machine_frame` | ELEC | Guericke's globe, Hauksbee's glass: a movement that makes static charge from turning. |
| `science.leyden_jar` **The Leyden Jar** ◆ | 200 | `electrostatics` | ELEC | 1745: charge kept in a jar (an item; its charge rides in its detail). |
| `science.lightning_rod` **The Lightning Rod** ★ | 250 | `leyden_jar`, `wire_drawing` | ELEC | Franklin: a copper rod on the highest block catches bolts into the jars wired to it, and puts out fires near it. |
| `science.franklins_kite` **Franklin's Kite** ★ | 150 | `lightning_rod` | ELEC | 1752: fly your kite in a storm with a Leyden jar in the off-hand and it fills. |
| `science.papin_digester` **Papin's Digester** ◆ | 180 | `cast_iron` | HEAT | 1679: the pressure cooker and its safety valve. Bone broth (hearty food). |
| `science.newcomen_engine` **The Atmospheric Engine** ◆ | 280 | `papin_digester`, `blast_furnace` | HEAT | Newcomen (1712): fire, boiler, cylinder and beam → great power, and hungry. |
| `science.coke` **Coke** ◆ | 200 | `blast_furnace` | METL | Darby (1709): coal baked to coke (+ coal tar). The blast furnace no longer needs charcoal. |
| `science.crucible_steel` **Crucible Steel** ◆ | 250 | `cementation_steel`, `coke` | METL | Huntsman (1740): cast steel ingots; **steel stock** block; steel pick, axe, spade, chisel, hammer (tier 3). |
| `science.newtonian_mechanics` **Principia** ★ | 250 | `telescope`, `pendulum_clock` | GRAV | Newton (1687): gravitation. The orrery, and the road to weighing the Earth. |
| `science.balloon` **The Montgolfier** ★ | 180 | `papin_digester` | HEAT | 1783: a hot-air balloon pack — rise slowly, fall softly, burning charcoal. |
| `science.lead_chamber` **The Lead Chamber** ◆ | 200 | `saltpetre_works` | CHEM | Roebuck (1746): sulfur, saltpeter and steam in lead → oil of vitriol, by the barrel. |
| `science.water_frame` **The Water Frame** | 180 | `water_wheel`, `gearing` | AUTO | Arkwright (1769): powered spinning and weaving — cloth from wool three times over. |
| `science.lathe` **The Powered Lathe** ◆ | 180 | `cast_iron`, `water_wheel` | MECH | Turned shafts, pistons and bearings. |

### 5.3 Tier 5 — The Industrial Revolution, 1760–1870

Watt, steel in bulk, precision (and with it the **assembly jig**, where relics are built from carved parts), cards and engines that compute, and electricity from pile to dynamo to lamp.

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `science.watt_engine` **The Separate Condenser** ◆ | 450 | `newcomen_engine`, `lathe` | HEAT | Watt (1769): twice the power for the fuel; the sun-and-planet gear. |
| `science.high_pressure_steam` **Strong Steam** ◆ | 450 | `watt_engine`, `crucible_steel` | HEAT | Trevithick (1800): small engines of great power. |
| `science.steam_hammer` **The Steam Hammer** | 400 | `high_pressure_steam` | METL | Nasmyth (1839): every anvil recipe in one blow; steel plate in bulk. |
| `science.puddling` **Puddling** ◆ | 350 | `coke` | METL | Cort (1784): pig iron stirred to wrought iron, two bars per pig. |
| `science.bessemer` **The Converter** ◆ | 500 | `puddling`, `high_pressure_steam` | METL | Bessemer (1856): pig iron → steel in one minute, by a blast of air. |
| `science.maudslay_lathe` **The Screw-Cutting Lathe** | 450 | `lathe`, `crucible_steel` | MECH | Maudslay (1800): precision. Screws, springs, bearings — and the **assembly jig** movement, where relics are built from carved parts. |
| `science.interchangeable_parts` **Interchangeable Parts** | 400 | `maudslay_lathe` | MECH | Standard parts: every assembly takes a quarter fewer. |
| `science.jacquard_cards` **Punched Cards** ★ | 400 | `water_frame`, `maudslay_lathe` | AUTO | Jacquard (1804): a carved card in a frame chooses what it makes. |
| `science.difference_engine` **The Difference Engine** | 550 | `jacquard_cards`, `interchangeable_parts` | AUTO | Babbage (1822): the relic; studies pay 20 % more insight (with **P-S2**). |
| `science.analytical_engine` **The Analytical Engine** | 600 | `difference_engine` | AUTO | Babbage and Lovelace (1837, 1843): card decks — programs for automata. |
| `science.clockwork_automaton` **The Automaton** ★ | 600 | `jacquard_cards`, `escapement`, `maudslay_lathe` | AUTO | Al-Jazari, Vaucanson, Jaquet-Droz: a clockwork helper that follows, carries 27 slots and fetches for frames by its card. |
| `science.voltaic_pile` **The Pile** ◆ | 400 | `leyden_jar`, `lead_chamber` | ELEC | Volta (1800): a steady current. Cells; wires now carry charge. |
| `science.electrolysis` **Electrolysis** | 450 | `voltaic_pile` | CHEM | Davy: water → hydrogen (a better balloon); brine → soda; electroplating. |
| `science.electromagnet` **The Electromagnet** ★ ◆ | 400 | `voltaic_pile`, `wire_drawing` | ELEC | Sturgeon (1825): a held magnet draws every dropped item within 8 blocks to you. |
| `science.dynamo` **The Dynamo** ◆ | 500 | `electromagnet`, `watt_engine` | ELEC | Faraday (1831): turning → charge. |
| `science.electric_motor` **The Motor** ◆ | 450 | `dynamo` | ELEC | Charge → turning: any frame on a wire runs. |
| `science.telegraph` **The Telegraph** ★ ◆ | 400 | `electromagnet`, `wire_drawing` | ELEC | Morse (1837): two wired keys send words; tap it and it clicks. |
| `science.arc_lamp` **The Arc Lamp** ★ | 400 | `dynamo` | ELEC | Davy's arc: the **lamp** block, brightest light, while charge feeds it. |
| `science.cavendish_balance` **Weighing the Earth** | 450 | `newtonian_mechanics`, `maudslay_lathe` | GRAV | Cavendish (1798): the gravimeter points to dense ore (gold, lead, diamond, orichalcum) within 24 blocks. |
| `science.otis_elevator` **The Safety Elevator** ★ | 400 | `high_pressure_steam`, `crucible_steel` | MECH | Otis (1852): a platform carries you between landings in a shaft. |
| `science.daguerreotype` **The Daguerreotype** ★ | 400 | `cinnabar_roasting`, `electrolysis` | OPTI | 1839: a silvered plate and mercury vapour photograph a place (a captured plan). |
| `science.cyanotype` **Blueprints** | 500 | `daguerreotype` | OPTI | Herschel (1842): build a photographed structure again, paying its blocks. |
| `science.maxwell` **Maxwell's Equations** ◆ | 550 | `dynamo`, `telegraph` | ELEC | 1865: light is electromagnetic. The root of radio and of the aether. |
| `science.spectroscope` **The Spectroscope** ◆ | 400 | `telescope`, `glassworks` | OPTI | Kirchhoff and Bunsen (1859): a star seen through it pays double; its lines show helium (1868). |
| `science.dynamite` **Dynamite** | 400 | `gunpowder`, `lead_chamber` | CHEM | Nobel (1867): a charge that loosens 5×5×5, hard rock included. |

### 5.4 Tier 6 — The Electrical Age, 1870–1905, and the Aether

Tesla's decade. Then **the Aether Drift** — the one node where the world leaves history — and cavorite.

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `science.incandescent_lamp` **The Incandescent Lamp** | 700 | `arc_lamp`, `vacuum_pump` | ELEC | Swan and Edison (1879), carbonised thread: lamps cost a quarter of the charge. |
| `science.polyphase_ac` **Alternating Current** ◆ | 900 | `electric_motor`, `maxwell` | TESL | Tesla (1888): polyphase power; transmission lines reach across the whole domain. |
| `science.transformer` **The Transformer** ◆ | 700 | `polyphase_ac` | TESL | Line losses halved. |
| `science.induction_motor` **The Induction Motor** | 800 | `polyphase_ac` | TESL | Tesla (1888): machines use a quarter less charge. |
| `science.tesla_coil` **The Tesla Coil** ★ ◆ | 1000 | `transformer`, `leyden_jar` | TESL | 1891: lamps within 16 light with no wire; arcs set hostile creatures alight; jars charge through the air. |
| `science.radio` **Wireless** ★ ◆ | 900 | `tesla_coil`, `maxwell` | TESL | Tesla (1893), Marconi (1895): messages to every radio in the domain; beacons. |
| `science.teleautomaton` **The Teleautomaton** | 900 | `radio`, `clockwork_automaton` | AUTO | Tesla's radio boat (1898): automata take orders from anywhere; three at once. |
| `science.crookes_tube` **The Crookes Tube** ◆ | 800 | `vacuum_pump`, `transformer` | TESL | Cathode rays in an evacuated tube. |
| `science.x_rays` **X-Rays** ★ ◆ | 900 | `crookes_tube` | TESL | Röntgen (1895): see ores glow through 16 blocks of rock ahead of you. |
| `science.radioactivity` **Radium** ◆ | 900 | `x_rays` | CHEM | Becquerel, the Curies (1898): 27 blocks of pitchblende → 1 radium grain; the radium cell makes charge forever, slowly. |
| `science.helium` **Helium** ◆ | 800 | `radioactivity`, `spectroscope` | CHEM | Ramsay (1895): helium out of pitchblende. A balloon that floats. |
| `science.tesla_oscillator` **The Earthquake Machine** ★ | 1000 | `induction_motor`, `steam_hammer` | TESL | Tesla's oscillator (1898): shakes a 5×5 column 16 deep loose into drops. |
| `science.arc_furnace` **The Arc Furnace** | 900 | `polyphase_ac` | METL | Héroult (1900): chromium ore reduced; chrome steel tools (tier 4). |
| `science.diamond_drill` **The Diamond Drill** | 1000 | `arc_furnace`, `tesla_oscillator` | METL | Leschot's core drill (1863), electric: a drill tool (tier 5). |
| `science.wardenclyffe` **Wardenclyffe** ★ ◆ | 1200 | `tesla_coil`, `radio`, `polyphase_ac` | TESL | Tesla's tower (1901): a 40-block tower rooted 30 blocks into the earth sends charge to every receiver in the domain. |
| `science.bakelite` **Bakelite** | 700 | `coke`, `electrolysis` | CHEM | Baekeland (1907) from coal tar: insulators; wire losses down; relic cases. |
| `science.luminiferous_aether` **The Aether Drift** ★ ◆ | 1000 | `maxwell`, `x_rays` | GRAV | **Here the world leaves history.** Michelson and Morley found nothing in 1887; here they find the drift. Orichalcum rings to it: aetherium ingots. |
| `science.aether_cell` **The Aether Cell** ◆ | 1000 | `luminiferous_aether`, `radioactivity` | GRAV | An aetherium cell: a great, endless trickle of charge. |
| `science.cavorite` **Cavorite** ★ ◆ | 1200 | `luminiferous_aether`, `helium` | GRAV | Wells' alloy (1901): aetherium, lead, helium and steel. The **cavorite** block: gravity cannot pass it. |

### 5.5 Tier 7 — Beyond the Event Horizon

| Node | Cost | Requires | Branch | Unlocks |
|---|---|---|---|---|
| `science.gravity_plating` **Gravity Plating** ★ | 1500 | `cavorite` | GRAV | Cavorite plates: low gravity above them. Cavorite soles: moon-jumps anywhere. |
| `science.gravity_well` **The Gravity Well** ◆ | 1500 | `cavorite`, `tesla_coil` | GRAV | Attractor (draws items in) and repulsor (thrusts hostile creatures away). |
| `science.levitator` **The Levitator** ★ | 1600 | `gravity_plating`, `aether_cell` | GRAV | A harness: flight, paid in charge per second. |
| `science.gravity_engine` **The Gravity Engine** ◆ | 2000 | `gravity_well`, `aether_cell` | GRAV | Counter-rotating cavorite rotors: the greatest power source there is. |
| `science.stasis_field` **The Stasis Field** | 1500 | `gravity_well` | GRAV | Everything in the field hangs still. |
| `science.the_core` **The Core** ★ ◆ | 3000 | `gravity_engine`, `wardenclyffe` | FOLD | The gravity drive: three counter-rotating rings round an artificial singularity. It folds space. |
| `science.wormhole_gates` **Wormholes** ★ | 2000 | `the_core` | FOLD | Paired gates in one domain, any distance apart. |
| `science.fold_to_stars` **The Fold** ★ ◆ | 3000 | `the_core`, `spectroscope`, `chronometer` | FOLD | Fold to the star in view: a world made at that star, its kind read from the star's colour. |
| `science.terraforming` **Terraforming** ◆ | 2000 | `fold_to_stars`, `bessemer` | FOLD | A terraformer turns a barren body green, 16×16 at a time. |
| `science.atmosphere_processor` **The Atmosphere Processor** | 1800 | `terraforming` | FOLD | A body's sky, remade. |
| `science.the_deep` **The Deep** ◆ | 2500 | `the_core` | FOLD | A misfold. Somewhere that is not anywhere. Strange matter lies there. |
| `science.strange_matter` **Strange Matter** ◆ | 2000 | `the_deep` | FOLD | Strange matter refined: horizon glass and the last relic parts. |
| `science.recall_beacon` **The Recall Beacon** ★ | 1500 | `wormhole_gates` | FOLD | A pocket fold home to your own gate, once an hour. |
| `science.gravitic_drones` **Gravitic Automata** ★ | 1800 | `teleautomaton`, `levitator` | AUTO | Automata that fly: scouts and carriers. |
| `science.unified_field` **The Unified Field** ★ ◆ | 4000 | `the_core`, `strange_matter`, `fold_to_stars`, `terraforming` | FOLD | The capstone: Tesla's dynamic theory of gravity, finished. The Unified Field Engine, a pocket wormhole to any gate or body you know. |

### 5.6 Registration and effects

`tree.lua` holds the table as data and loops `progress.register_node`, expanding every bare id in `requires` to `science.` — Progress resolves none itself, and a node requiring an unregistered id is disabled with everything after it. `label` ≤ 32 characters; `text` = one child-readable sentence (≤ 90 characters) + one adult line — tighter than Progress's 48 and 200, by choice. Effects the tree carries:

| Node | Effects |
|---|---|
| `de_re_metallica` | `craft.sluice_gold_period` −3 |
| `trip_hammer` | `craft.anvil_strikes` −1 |
| `pendulum_clock` | `science.machine_speed_percent` 10 |
| `interchangeable_parts` | `science.assembly_parts_percent` −25 |
| `difference_engine` | `science.study_bonus_percent` 20 (inert until **P-S2**) |
| `watt_engine` / `high_pressure_steam` | `science.steam_percent` 100 / 100 (so ×2, then ×3) |
| `induction_motor` | `science.charge_use_percent` −25 |
| `incandescent_lamp` | `science.lamp_use_percent` −75 |
| `polyphase_ac` / `transformer` / `bakelite` | `science.line_loss_percent` −90 / −50 / −25 |
| `spectroscope` | none: it opens a second discovery family, `spectrum:*` (§6.9) |
| `teleautomaton` | `science.automata` 2 |

---

## 6. The machinery, system by system

### 6.1 The frame and its movements

The **frame** is one block and one Craft station; what it *is* depends on the **movement** in its tool slot (a clockmaker's word: the works inside the case).

```lua
craft.register_station{
  id = "tiamat_default_science:frame",
  name = "Machine frame",
  slots = { tool = 1, input = { from = 2, to = 5 }, output = { from = 6, to = 9 } },
  auto = true,                          -- this mod's power loop runs it
  block = "tiamat_default_science:frame",
}
```

Recipe: Craft's `iron_frame` + 4 `plank` + 4 `iron_nails` at the workbench (`science.machine_frame`); the cast-iron frame (`cast_iron`) is the same block, cheaper.

| Movement (item, in slot 1) | Node | Needs | Makes |
|---|---|---|---|
| `crank` | machine_frame | a player using the frame with a `crank_handle` in hand (each use = 40 ticks of 4 turning) | turning, into the network |
| `millstones` | gearing | 4 turning | flour; `crushed_<ore>` (stamp mill) |
| `stamps` | stamp_mill | 8 | 20 units ore → 27 crushed ore, smelted by this mod's own kiln/furnace recipes exactly as ore (a third more metal) |
| `leaching_vat` | saltpetre_works | 2 | saltpeter from cave earth + ash |
| `trip_hammer` | trip_hammer | 8 | this mod's own powered copies of Craft's anvil products (plate, nails, chain, hinge, heads: same inputs and outputs, registered at the frame) |
| `blowing_engine` *(sits in the **furnace's** tool slot, not a frame's; it should blow only while a powered frame touches the furnace — ask C-S2)* | blast_furnace | 8 | heat 5 |
| `friction_globe` | electrostatics | 4 | charge into Leyden jars in its inputs |
| `pump` | archimedes_screw / de_re_metallica | 4 | lifts or drains water (`set_fluid`, conserved by tally) |
| `lathe_bed` | lathe | 8 | turned shafts, pistons, bearings |
| `spinning_frame` | water_frame | 8 | cloth ×3 from wool |
| `press` | printing_press | 4 | printed treatises (§6.8) |
| `digester` | papin_digester | heat from an adjacent lit furnace | bone broth |
| `cylinder` | newcomen_engine | a lit furnace with a `boiler` below, a copper `pipe` glyph between | turning out: 16 (Newcomen), ×2 Watt, ×3 high pressure |
| `dynamo_armature` | dynamo | turning in | charge out, 1:1 |
| `motor` | electric_motor | charge in | turning out, 1:1 |
| `assembly_jig` | maudslay_lathe | 16 turning or 16 charge | relics from carved parts (§7.5) |
| `electrolysis_cell` | electrolysis | charge | hydrogen, soda, plating |
| `arc_electrodes` | arc_furnace | 64 charge | chrome steel from chromium ore |
| `telegraph` | telegraph | 1 charge / message | a telegraph (§6.5) |
| `terraformer` | terraforming | 128 charge | §6.10 |

**The job loop** (`frame.lua`): frames are kept on this mod's own list, from `register_on_place` / `register_on_dig_complete` of the `frame` block (and rebuilt at load from `game.containers("tiamat_default_craft:tiamat_default_science:frame:")`, the containers Craft names for them). Every 20 ticks, per frame: read its movement; if its network supplies the movement's need (§6.2), add 20 × (1 + machine speed %) to its job; the recipe is the card's choice, else the first in `craft.recipes(station)` whose tools include the movement and for which `craft.can(owner, id, container)` answers true; when the job reaches the recipe's `ticks`, `craft.perform(owner, id, container)`. *Owner* is the player who placed it (Craft keeps `placer:<container>` in its private storage; this mod keeps its own copy from `on_place`), so the gate and the firsts are theirs. `on_dig_complete` is a veto asked before removal, which a later mod may still refuse, so a frame leaves the list only when its container is gone, found by a slow sweep within the tick budget; a plan-stamped frame has no placer and runs for nobody until a player uses it and claims it.

### 6.2 The two networks — turning and charge

Two integer quantities. **Turning** (mechanical, units per tick: "turns") travels through carved shafts, gears and wheels. **Charge** (electrical, stored units) travels through carved copper rods (wire).

- **Graph.** Network blocks are carved blocks whose glyph and material this mod reads (rod/gear/wheel of `plank` or `steel_stock` → turning; rod/coil of `copper_stock` → charge; frames and furnaces join the graphs they touch). Rebuilt **only** on `register_on_place` / `register_on_dig_complete` of a network block (a bounded flood fill, ≤ 512 blocks), stored as `net:<x,y,z>` → network id and `netrec:<id>` → encoded record. Never scanned on the tick.
- **Wooden shafts** carry ≤ 16 turns and a run of ≤ 16 blocks; **steel** 128 and 64; gears change nothing but direction (the history lesson is the escapement, not gear ratios — keep it simple for children).
- **Wire loss**: 1 charge per 16 blocks of copper per second (DC), cut by 90 % with `polyphase_ac`, then halved by `transformer`, then −25 % with `bakelite` insulation. Wardenclyffe (§7.3) removes distance for its receivers entirely.
- **Every 20 ticks**, per network: sum supply, sum demand, share supply in frame order; surplus charge fills stores (jars 100, cells 1,000, accumulator banks = frames full of cells). Turning is never stored — a millrace stops, the mill stops.
- **Sources** (turns or charge per second, before effects): crank 4 while used; water wheel 4 × (water blocks touching its lower half, max 4) — so 4–16; windmill 2 + 1 per 16 blocks above ground (`depth_under` negative) capped 8, ×2 in `storm`/`blizzard`, ×0 in `clear` with intensity < 100‰ (`weather_at`), and as in `cloudy` without Weather; Newcomen 16 (1 coal / 30 s); Watt 32; high pressure 48; voltaic pile 2 charge (a cell item slowly drained, recharged by electrolysis reversed); radium cell 1 forever; aether cell 10 forever; lightning 2,000 at once; gravity engine 512.
- **Budget.** Every network tick is O(frames + sources) in that network; networks are capped per player (32) and in size (512 blocks).

### 6.3 The furnace and the metallurgy ladder

```lua
craft.register_station{
  id = "tiamat_default_science:furnace", name = "Furnace",
  slots = { fuel = 1, input = { from = 2, to = 4 }, tool = 5, output = { from = 6, to = 8 } },
  heat = true,
  block = "tiamat_default_science:furnace", lit_block = "tiamat_default_science:furnace_lit",
  boost = { tool = "tiamat_default_science:blowing_engine", heat = 5 },
}
craft.register_fuel("tiamat_default_science:coke", 3, 1800)
```

The ladder is the real one, each step cheaper or better than the last:

| Step | Recipe | Node |
|---|---|---|
| Pig iron | 54 units iron ore + 27 charcoal (or coke) + 9 units `calcite` (flux), heat 5 → 3 pig iron + slag | blast_furnace |
| Wrought iron | 2 pig → 3 Craft `iron_bar` (finery, heat 3) | finery_forge |
| Cast iron | pig in a sand mould → pipe, cylinder, wheel, frame plate (heat 3) | cast_iron |
| Coke | 27 units coal, heat 2, 2 min → 18 coke + 1 coal tar | coke |
| Blister steel | 4 `iron_bar` + 27 charcoal, **one in-game day** (24,000 ticks) at heat 2 → 4 blister steel | cementation_steel |
| Crucible steel | 2 blister steel + Craft crucible (tool) at heat 5 → 1 steel ingot; ingot → `steel_stock` block (27 units) | crucible_steel |
| Puddled iron | pig, heat 3, 1 min → 2 bars | puddling |
| Bessemer steel | 3 pig + the `converter` tool + blast (heat 5 *and* powered — C-S2), 1 min → 3 steel | bessemer |
| Chrome steel | 27 units chromium ore + 2 steel in a frame with `arc_electrodes` | arc_furnace |

**Tools** (tier and uses through Craft `register_tool`; speed is `speed_multiplier` on the engine's `game.register_tool` of the same id): steel pick, axe, spade, chisel, hammer — tier 3, 800 uses, speed 8; chrome steel — tier 4, 2,000 uses, speed 10; the diamond drill — type `pick`, tier 5, 4,000 uses, speed 14, spends 1 charge from a carried cell per block (Craft `wear` for uses; this mod for charge). Science registers a dig class `reinforced` (tier 3) for cavorite, so cavorite resists iron.

### 6.4 Instruments — held things that read the world

One HUD script (`hud.lua`, reserve 0 — it draws top-left) shows the held instrument's reading. Polled for online players round-robin, one player per tick.

| Instrument | Reads | Shows / does | Discovery family |
|---|---|---|---|
| burning glass | the hour and the open sky: `time_of_day()` between 0.40 and 0.60 **and** `get_light(pos).sun == 15` (sun is sky *exposure*, not brightness) | lights a laid campfire or kiln you look at, once **C-S6** lands; until then, nothing | — |
| magnifier | `looking_at` (cells ÷ 3) → material → `game.tags`, hardness | name, tags, hardness | — |
| compass | your cairn, else north | a needle | — |
| dip needle | nearest `metal_ore` block ≤ 16 along the six axis rays from you (96 reads, spread over 6 ticks) | a needle and "near"/"far" | — |
| surveyor's staff | `looking_at` | distance, height, depth below ground | — |
| telescope | `star_in_view` | the star's id and brightness; logs it | `star:*` (1), and through the spectroscope `spectrum:*` (1) |
| microscope | `looking_at` or the off-hand stack | a line about what it is | `specimen:*` (3; one per material, ~250) |
| barometer | `weather_for` | kind, intensity, and rising/falling (its own last 5 readings) | `weather:*` (20; 9 kinds) |
| thermometer | `weather.warmth(x, y, z)` (0..1000) | degrees (a Fahrenheit reading from warmth: `F = warmth × 110 / 1000 − 10`) | `climate:*` (3; per biome) |
| chronometer | position | x, z and a needle to a waypoint you set | — |
| gravimeter | the nearest of gold, lead, diamond or orichalcum ≤ 24 along the six axis rays (144 reads over 6 ticks) | a needle | — |
| X-ray viewer | ores in a 5×5×16 cone ahead | particles on them for 5 s (8 charge) | — |
| aetherometer | the aether drift | an absurd, beautiful needle — and the node's lore | — |

### 6.5 Electricity

- **Leyden jar** (item, detail `e=<0..100>`); **cell** (item, `e=<0..1000>`); the detail is rewritten in place (Craft does the same for tool wear), so a charged jar never stacks with an empty one.
- **Lightning rod** (construct §7.3): Weather's `on_lightning(x, y, z)` → if a rod construct's tip is within 8 blocks of the strike in x and z (a bolt that found no ground is reported 40 blocks above a player, in the air, so y is not compared), every jar and cell in frames on its network fills, up to 2,000 in total; and the strike's own fire is `extinguish`ed (Weather puts out one block a call and exports no list of fires; **Wx-S4** would let a rod clear 16 round it). Discovery *"You caught lightning!"* (30).
- **Franklin's kite**: while flying a kite (§4) in `storm` with a jar in the off-hand, the jar gains 5 per second. Historically dangerous; here harmless.
- **Lamp** (`lamp` / `lamp_lit` blocks): lit while its network (or a Tesla coil within 16, or Wardenclyffe) pays 1 charge / s (¼ with the incandescent lamp). Swapped by the network tick, not by a random tick.
- **Electromagnet** (held): every Life `drop` item entity within 8 is pulled toward you (`set_entity` velocity; the engine does not check who owns an entity, so **L-S4** is a courtesy to agree with Life, not a permission).
- **Telegraph**: no new block — a telegraph is a *frame* with the `telegraph` movement; two of them joined by copper wire are a line. Chat `t <message>` while standing at one sends it to players within 16 of the other. With `radio`, any radio frame in the domain, no wire.
- **Tesla coil** (construct): lamps within 16 light with no wire; hostile Life creatures within 8 are `set_alight` for 60 ticks every 5 s (2 charge each); jars and cells carried by anyone within 8 charge 5/s.
- **Wardenclyffe** (construct): every receiver (a frame with `receiver` movement) in the domain is on its network, with no loss. One per world per player; the tower must stand ≥ 40 blocks above ground and root ≥ 30 below — as Tesla's did.

### 6.6 Automata, cards, printing and photography

- **Cards.** A carved `plank` whose remaining cells lie in exactly **one** outer face plane (a carving along one edge, or of fewer than three cells, lies in two and is not a card) and which is not a registered glyph is a **punched card**. It is read turned into the bottom face and then into whichever of the square's eight symmetries gives the smallest pattern, so a card means the same however it was carved; its number is that pattern's rank among the readable ones. `plate`, `ring`, `rail` and `bracket` lie in one face and are never cards. The card goes in the frame's *input* slot 5 and is never consumed (the loop skips it); the number picks the recipe (`n mod #recipes`, in id order, shown on the frame's tab). Carved from `plank`, like Jacquard's pasteboard.
- **Decks** (`analytical_engine`): a `card_deck` item (detail = the list of card numbers, ≤ 16) — a program. Built at a frame with the `assembly_jig` from cards held in the pack.
- **Clockwork automaton** (entity; model `automaton`): a 27-slot hold (container `tiamat_default_science:hold:<id>`); follows its owner or runs its deck: each card is an instruction — `1`–`64` "carry from chest *n* to frame *n*" (chests and frames numbered by the order the owner tags them with the automaton key), `65` "follow", `66` "wait for the frame to finish", … (table in `config.lua`). One stack per 40 ticks. Paths ≤ once per 20 ticks, budget 400.
- **Teleautomaton** (Tesla, 1898): orders by radio from anywhere in the domain; 3 active.
- **Gravitic automata**: the same model, flying (set_entity velocity, no pathing: straight lines, stop at obstacles), scouting (reports biome and ore finds 200 ahead) or carrying between two tagged containers anywhere in the domain.
- **Printing press**: a `treatise` item (detail `a=<author 8 hex>;t=<topic>`), printed from a `notebook` page the author has (a topic = a science node they hold) + 1 leather + 9 `#plank` units (paper). Anyone who uses a treatise not by them gains a once-per-(author, topic) discovery `read:*` worth 10, **at most 20 per reader** (a counter) — sharing knowledge helps new players of either path, the historical point of the press.
- **Daguerreotype**: `plans.capture` of a box you mark with the camera (≤ 16 per side), giving a `photograph` (detail = the plan name). **Blueprint** (`cyanotype`): used at a spot, it takes the plan's block counts from your inventory (`plans.info` → counts; `game.take` each; refunded if short) and `plans.stamp`s it. Buildings copied, materials paid.

### 6.7 Gravity and the aether (T6–T7, where history stops)

The **aether** is the period's own physics: Maxwell's waves needed a medium, and in 1887 Michelson and Morley failed to find it. Here they succeed. `luminiferous_aether` says so in its text, once, plainly, so an older player knows exactly where the fiction starts.

- **Aetherium** (item): orichalcum "rung" in a frame with a Tesla coil within 8 → aetherium ingot. World's orichalcum finally has its science reading.
- **Cavorite** (block): 1 aetherium + 1 lead ingot + 1 `helium` + 1 steel ingot → 27 units (Wells: an alloy with helium). Class `reinforced`. Carvable like any block.
- **Gravity plating**: a `plate` glyph of cavorite under your feet → an upward impulse each tick that cancels 5/6 of gravity (moon gravity) while you stand within 3 blocks above it. **Cavorite soles** (worn; read from `game.inventory(uuid, "tiamat_default_life:worn")`): the same anywhere, halved. Until **E-S1** (engine gravity scale) this is `push_player` per tick — test that it does not rubber-band.
- **Gravity well**: a frame with `attractor` / `repulsor` movement; 16 charge/s; radius 8; item entities and Life creatures pushed toward/away (L-S2 for Life's creatures; own entities always).
- **Levitator** (worn harness + carried cell): flight, 4 charge/s (fly ability via L-S3, else impulses).
- **Stasis field**: frame movement; entities in radius 6 have velocity zeroed each tick (own entities; Life's via L-S2).
- **Gravity engine** (construct): 512 charge/s. The only thing that can feed the Core.

### 6.8 The Core, wormholes and the Fold

**Tone.** The Core is *Event Horizon*: something enormous, beautiful and wrong. Three concentric rings turn on three axes around a sphere of black; the sound is a low choir that is almost a hum; the sky dims when it spins up; the rings stop dead when it opens. Nothing is gory, ever. The dread is scale and silence.

- **The Core** (construct §7.3): anchor = a **throat** block (`wormhole`, the one block the Fold adds) at the centre of three orthogonal 5×5 rings of cavorite `ring` glyph blocks; a gravity engine within 16; four Tesla coils at the corners of its base. Checked on use of the throat with a `fold_key` (relic §7.5). While spinning: three entities with the `core_ring` model spawned at the centre, each yawing/pitching at a different rate (`set_entity yaw/pitch` every tick — three entities, cheap); the sky darkens for everyone within 64 (through Weather's overlay, Wx-S2; until then the hum alone — `flash` adds light and cannot darken); `play_loop` of `core_hum`.
- **Wormholes** (`wormhole_gates`): two gate constructs (3×3 upright ring of 8 cavorite ring blocks, air at the centre) linked by using each with your `fold_key` (the pairing is kept in storage against you, so the key carries no detail). Powered (32 charge/s each while open), the centre becomes a `wormhole` block (passable, transparent, light {6,4,12}); `register_on_player_move` into it → `move_player` to the twin (same domain). Items thrown in follow. Cap 8 pairs per player.
- **The Fold to the stars** (`fold_to_stars`): at a Core, the player looks at a star (`star_in_view`, alignment ≥ 0.9998, about a degree — the nearest star is always answered, so the threshold is the aim) and chooses *Fold to the star* in the Core dialog. A body is made for that star: `create_domain("tiamat_default_science:body_<kind>", tostring(star.id), { position = star })`. `kind` from the star's `warmth`: < 0.2 **ice**, < 0.4 **rust** (red desert), < 0.6 **regolith** (grey, cratered), < 0.8 **basalt** (volcanic), else **glass** (obsidian and sand, scorched). Magnitude → size of the body's habitable disc and its gravity (low-g bodies push you up, as plating does). Every body is **barren**: no plants, no water on the surface (ice below, on ice bodies), no life. Science reaches worlds; it does not make them (magic weaves; science travels and changes). The first visit to each star's body is a discovery (`body:*`, 100).
- **The slot trick** (because a generator is not told its instance — **E-S2**): five templates (one per kind) registered at load. Every block coordinate in every domain lies in −60,000..59,999 (engine `coords.rs`), so each kind's template is a 15 × 15 grid of 8,000-block slots; a body takes the next free slot of its kind and is a disc of at most 3,000 blocks radius at that slot's centre, air beyond. Each body is its own slice of noise, and its size and gravity band are readable from the slot in the generator (a pure function of position) and in this mod. That is 225 bodies of each kind, 1,125 in a world — the cap, in `config.lua`; the Fold refuses a star whose kind is full and says so. A return gate is built for you on arrival (a single wormhole block on a cavorite plate); stepping into it `transfer_entity`s you back to the Core's domain — the one cross-domain gate, since wormhole pairs are same-domain `move_player`.
- **Terraforming**: a frame with the `terraformer` movement on a body converts its 16×16 footprint around it, one column per 10 ticks at 128 charge/s: regolith/rust/ash → World `dirt` → `grass`; places World's plants (`tall_grass`, `fern`, … by `set_block`; World exports no cover call) from a palette; on ice bodies, melts ice to water (`set_fluid` from ice units: conserved). When 60 % of a 64×64 region is green, the body is *living* (discovery 500) and the `atmosphere_processor` may change its sky (per player on arrival through Weather's overlay, Wx-S2; Weather has no domain logic and sends sky and clouds by x and z whatever domain a player is in, so until **Wx-S3** lets this mod own a body's sky, a body has Weather's).
- **The Deep** (`the_deep`, world option): a Core folded *blind* — the Core dialog's second choice, offered only in a world with the option — misfolds. A registered (not instanced) domain `tiamat_default_science:deep`: floating fragments of World's `dark_basalt`, `obsidian` and `morphic_rock` in a black void, no stars, a dim red grade, a slow wind loop and far-off voices that are almost your own chat played backwards (sound design, not text). **Strange matter**: digging `morphic_rock` in the Deep drops `strange_matter` units instead (a `register_on_dig_complete` drops override; a dig event names no domain, so this mod keeps each player's domain from `register_on_player_move` and answers only in the Deep — and a drops override is last-answer-wins, so agree with World that it does not answer for `morphic_rock`). **The shades** (model `shade`): tall, still silhouettes that are always a little further away than they were; if one reaches you, you are pushed toward the nearest edge and your lamp-light flickers. **Falling off a fragment** (below y = −64) returns you through your throat to the Core — alive, but the strange matter you carried stays behind. That is the whole danger, and it is enough.
- **Recall beacon**: a carried pocket fold home to your nearest gate, once an hour.
- **The Unified Field Engine** (capstone relic): a pocket wormhole to any gate or body you have visited, 256 charge per use.

### 6.9 Insight: where this path's comes from

| Source | How | Value |
|---|---|---|
| **Studies** (research table) | `study_pig_iron` · `study_lens` · `study_clockwork` · `study_steel` · `study_charged_jar` · `study_cell` · `study_engine_part` · `study_relic` (any assembled relic, once each) · `study_radium` · `study_aetherium` · `study_cavorite` · `study_strange_matter` | 15 · 20 · 40 · 40 · 30 · 80 · 120 · 250 · 400 · 500 · 800 · 1,500 (600 → 12,000 ticks) |
| **Stars** (`star:*`) | every star logged with the telescope; `spectrum:*`, every star seen through the spectroscope | 1 each; 2,048 stars |
| **Specimens** (`specimen:*`) | every material examined | 3; ~250 |
| **Weather** (`weather:*`), **climate** (`climate:*`) | barometer, thermometer | 20 × 9; 3 × ~55 |
| **Bodies** (`body:*`) | first visit to each star body | 100 |
| **Inventions** (discoveries) | first run of each movement; first lightning caught; first steel; first lamp lit; first wormhole | 10–100 |
| **Reading** (`read:*`) | others' treatises | 10, ≤ 20 per reader |
| **Toybox** | first kite flown, first hour told, first fire by sunshine (with C-S6), first water lifted, the Magdeburg hemispheres pulled by a led horse (two horses with **L-S6**) | 3–10 |
| **Milestones** (`award`, logged as `milestone` in `progress sources`) | first body made living (500), first Core spin (300), first return from the Deep (300) | — |
| **Difference engine** | +20 % on every study, with **P-S2** | — |

---

## 7. Glyphs, constructs and relics — the 3-D crafting

### 7.1 The part set

Every part is a 27-cell mask (index `x + 3y + 9z`) carved in the UI's shape crafter from a block — `plank`, stone, `glass`, or this mod's stock blocks (`copper_stock`, `steel_stock`, `cavorite`). **The part is the glyph; the material decides what it does** (the "reading" column). Rotation and mirror do not matter: all 48 symmetries registered (`variants`). `rod` and `plate` are deliberately the UI's own **Pillar** and **Slab** presets — so the two most common parts are one click for everyone, from day one. `tools/glyphs.py` proves no variant collides with magic's glyphs or with the UI's Stairs preset.

| Glyph | Cells | Canonical mask | Variants to register | Shape (top · middle · bottom layer; rows z=0..2, columns x=0..2) | Reading |
|---|---|---|---|---|---|
| `rod` | 3 | 74752 | 3 | <code>...  ...  ...<br>.#.  .#.  .#.<br>...  ...  ...</code> | = the UI **Pillar** preset. `plank` shaft (16-block run), `steel_stock` shaft (64), `copper_stock` wire, `cavorite` gravity spoke. |
| `plate` | 9 | 1838599 | 6 | <code>...  ...  ###<br>...  ...  ###<br>...  ...  ###</code> | = the UI **Slab** preset. `plank` sail, `glass` pane/lens blank, `copper_stock` lightning-rod plate / Wardenclyffe dome, `cavorite` gravity plating. A single outer face with cells removed is a **card** (§6.6). |
| `gear` | 7 | 10560552 | 3 | <code>...  #.#  ...<br>.#.  .#.  .#.<br>...  #.#  ...</code> | `plank` wooden gear, `steel_stock` steel gear (no loss). |
| `wheel` | 11 | 14775352 | 3 | <code>...  ###  ...<br>.#.  ###  .#.<br>...  ###  ...</code> | `plank` water-wheel / windmill hub, `steel_stock` flywheel, `cavorite` rotor. |
| `pipe` | 24 | 134142975 | 3 | <code>###  ###  ###<br>#.#  #.#  #.#<br>###  ###  ###</code> | `copper_stock` steam pipe, `steel_stock` high-pressure pipe. |
| `coil` | 17 | 119450567 | 3 | <code>###  ...  ###<br>#.#  .#.  #.#<br>###  ...  ###</code> | `copper_stock` coil (electromagnet, dynamo, Tesla secondary). |
| `ring` | 8 | 1837575 | 6 | <code>...  ...  ###<br>...  ...  #.#<br>...  ...  ###</code> | `steel_stock` bearing / Tesla top-load, `cavorite` Core and gate ring segment. |
| `gnomon` | 10 | 1846791 | 6 | <code>...  ...  ###<br>...  .#.  ###<br>...  ...  ###</code> | Any stone: a sundial. |
| `cairn` | 11 | 1912327 | 6 | <code>...  ...  ###<br>.#.  .#.  ###<br>...  ...  ###</code> | Any stone: your home marker (the compass). |
| `bracket` | 5 | 79 | 24 | <code>#..  #..  ###<br>...  ...  ...<br>...  ...  ...</code> | `steel_stock`: an elevator landing. |
| `nozzle` | 14 | 6061591 | 6 | <code>...  .#.  ###<br>...  ###  ###<br>...  .#.  ###</code> | `copper_stock`: the boiler's steam nozzle (and a whistle). |
| `rail` | 6 | 1313285 | 12 | <code>...  ...  #.#<br>...  ...  #.#<br>...  ...  #.#</code> | `steel_stock`: an elevator guide rail. |

### 7.2 Reading parts in the world

As magic's §7.2: `get_block` → material + occupancy → `glyph_of`. Constructs are checked on use and place only (≤ 125 reads), cached until any block in their box changes. Networks (§6.2) are the one structure maintained continuously — and only on place/dig.

### 7.3 Constructs

| Construct | Pattern (anchor in **bold**) | Node |
|---|---|---|
| Water wheel | a `plank` **wheel** whose lower half touches water, a shaft on its axis | water_wheel |
| Windmill | a `plank` **wheel** with 4 `plank` plates (sails) on its faces, ≥ 8 blocks above ground | windmill |
| Archimedes' screw | a column of `plank` rods rising from water, a frame with `pump` at its foot | archimedes_screw |
| Steam engine | **furnace** (lit, `boiler` in its tool slot) — `copper_stock` pipe — frame with `cylinder` | newcomen_engine |
| Lightning rod | a `copper_stock` **rod** as the highest block of its column (open sky), a copper rod wire down to a frame | lightning_rod |
| Tesla coil | **frame** (charged); 3 `copper_stock` coils stacked on it; a `steel_stock` ring on top | tesla_coil |
| Wardenclyffe | a column ≥ 40 blocks of any block with a 3×3 `copper_stock` plate dome on top and a `copper_stock` rod column ≥ 30 below the base; a Tesla coil at the base | wardenclyffe |
| Elevator | a `steel_stock` rail column; `steel_stock` bracket landings; a frame with `motor` at the foot | otis_elevator |
| Gravity engine | two `cavorite` **wheels** one above the other on a `steel_stock` shaft, a frame with `dynamo_armature` beside | gravity_engine |
| Wormhole gate | 3×3 upright ring of 8 `cavorite` ring blocks, air centre | wormhole_gates |
| **The Core** | **wormhole** throat at the centre of three orthogonal 5×5 rings of cavorite ring blocks (16 each); 4 Tesla coils at the base corners; a gravity engine within 16 | the_core |

### 7.4 Stock blocks

Carving needs a placeable material, and Craft's metals are ingots. So three stock blocks, each exactly one ingot (27 units, conserved): `copper_stock` (drawplate, `wire_drawing`), `steel_stock` (`crucible_steel`), `cavorite` (`cavorite`). No other metal becomes a block.

### 7.5 Relics — Technic-style assembly

At a frame with the `assembly_jig` movement. Each relic is carved parts + items:

| Relic | Carved parts | Other | Node |
|---|---|---|---|
| Clockwork (part) | 2 `plank` gears | spring (steel) | escapement |
| Telescope | 2 `glass` plates (lenses) | cast iron pipe, bronze ingot | telescope |
| Chronometer | 4 `steel_stock` gears, 1 steel ring | clockwork, silver ingot | chronometer |
| Difference Engine | 12 `steel_stock` gears, 4 steel rods | frame plate, 4 bronze ingots (World has no zinc, so no brass — Craft's own ruling) | difference_engine |
| Automaton | 4 steel gears, 2 steel rods, 1 `copper_stock` coil | clockwork ×2, leather | clockwork_automaton |
| Dynamo armature | 2 copper coils, 1 steel wheel | 2 iron bars | dynamo |
| Crookes tube | 1 `glass` pipe | 2 copper rods, vacuum (pump run) | crookes_tube |
| Tesla top-load | 1 steel ring | 4 empty Leyden jars | tesla_coil |
| Aether cell | 1 `steel_stock` ring, 1 `copper_stock` coil | aetherium ×4, radium | aether_cell |
| Levitator harness | 4 `cavorite` plates | leather ×4, an empty cell, coil | levitator |
| Fold key | 1 `cavorite` ring, 1 cavorite rod | strange matter or aetherium ×9, radium | the_core |
| Unified Field Engine | 3 `cavorite` rings, 1 cavorite wheel | strange matter ×27, an aether cell (a source, no detail), the fold key (no detail: its pair id is kept in storage against the player) | unified_field |

**Mechanism.** With Craft ask **C-S3** (= magic's C-M1: a glyph named as an ingredient) these are ordinary recipes. **Fallback (today):** the recipe is registered with its non-carved inputs; the jig's job, when its time is up, first takes the carved parts from the frame's input slots with `game.container_take` (which matches shape exactly — each registered variant tried), then `craft.perform`s; if perform fails, the parts are given back with `game.container_give`. `interchangeable_parts` removes a quarter of each relic's parts (rounded down, min 1).

---

## 8. Blocks — ten

| Block | Why it must be a block | Notes |
|---|---|---|
| `antikythera` | Progress's door | hardness 1.8, tags `metal` |
| `frame` | a Craft station in the world | hardness 2.0, tags `metal`, `hard` |
| `furnace`, `furnace_lit` | a Craft heat station and its lit form | lit: light {13,7,2}, contact fire |
| `lamp`, `lamp_lit` | light needs a block, and on/off is two | lit: light {15,15,14} |
| `copper_stock`, `steel_stock`, `cavorite` | carving needs placeable metal | 1 ingot each; cavorite class `reinforced`, faint light {2,1,4} |
| `wormhole` | the throat has to be *there* | passable, transparent, light {6,4,12}; placed and removed only by this mod |

Every machine, network and structure beyond these is carved from World's blocks, Craft's `plank`/`glass`, or the three stocks.

---

## 9. Items

From a table in `items.lua` (≈ 130). Groups: `#movement`, `#instrument`, `#cell` (jar, cell), `#steel`, `#crushed_ore`.

- **Bench:** `theatrum`, `notebook`, `lens`, `magnifier`, `kite`, `compass`, `crowbar` (Craft tool, type `maul`, tier 1).
- **Movements:** §6.1 table, plus `crank_handle`, `boiler`, `converter`, `blowing_engine`, `receiver`, `attractor`, `repulsor`, `stasis_coil`, `telegraph`.
- **Metallurgy:** `blowpipe`, `pig_iron`, `slag`, `coke`, `coal_tar`, `blister_steel`, `steel_ingot`, `chrome_steel_ingot`, `crushed_copper`, `crushed_tin`, `crushed_iron`, `crushed_silver`, `crushed_gold`, `crushed_lead`, cast parts (`cast_pipe`, `cast_cylinder`, `cast_wheel`, `frame_plate`), `spring`, `bearing`, `screw`, `piston`, `clockwork`; tools (steel ×5, chrome ×5, `diamond_drill`).
- **Chemistry:** `saltpeter`, `black_powder`, `mining_charge`, `dynamite`, `oil_of_vitriol`, `quicksilver`, `hydrogen`, `soda`, `helium`, `radium_grain`, `radium_paint`, `bakelite`.
- **Optics & instruments:** §6.4 table items; `photograph`, `blueprint`, `treatise`.
- **Electricity:** `leyden_jar`, `cell`, `radium_cell`, `aether_cell`, `carbon_rod`, `filament`.
- **Automata:** `card_deck`, `automaton_key`, `automaton_spring` (spawns an automaton).
- **Aether and gravity:** `aetherium_ingot`, `cavorite_soles`, `levitator_harness`, `fold_key`, `strange_matter`, `horizon_glass`, `recall_beacon`, `unified_field_engine`.
- **Food:** `bone_broth` (Life `add_food`: food 8, saturation 6, `effects = { { "hearty", ticks } }`, `temperature = "warm"`).

**Pitchblende.** World has it: `pitchblende`, from 1,200 blocks down beside the lead and the silver (World `blocks.lua`, `generate.lua`). 27 blocks of it give 1 radium grain (§5.4).

**Quicksilver** needs cinnabar, as for magic: **W-M1** (shared ask), same fallback (native droplets from sulfur crust).

---

## 10. Sounds, models, screens

### 10.1 Models (3 of the server's 64)

`automaton` (brass, cheerful, clanking; clips `idle`, `walk`, `run`; the gravitic drone reuses it with no legs moving), `core_ring` (one ring; three instances), `shade` (a tall silhouette with no face; clip `idle` only — shades never visibly move).

### 10.2 Sounds

`crank`, `mill`, `hammer`, `hiss` (steam), `engine` (loop), `spark`, `zap` (Tesla), `telegraph_click`, `hum` (dynamo), `core_hum` (loop, the choir), `fold` (a pressure drop), `deep_wind` (loop), `deep_voices` (loop, very quiet). Bound to cues of their names.

### 10.3 Screens

- ***Theatrum Machinarum*** (action `theatrum`, default key **N** once actions work; until then by using the book and by chat `science book`; UI tab): machine pictures, one page per node held or next learnable.
- **Frame tab**: movement, network supply/demand, job progress, the card's choice.
- **Network tab**: sources, loads, stores, losses for the network under the cursor (`looking_at`).
- **Automata tab**; action `automaton` (default key **U**, and meanwhile by using the automaton key) calls the first home.
- **Core dialog**: spin up, the star in view, the destinations known.
- **HUD** (one script): the held instrument's reading, and the held cell's charge.

---

## 11. The picture primer (*Theatrum Machinarum*)

Jacob Leupold's *Theatrum Machinarum* (1724–39) was the first systematic encyclopedia of machines, mostly plates. Ours is the same idea as magic's *Mutus Liber*: per recipe node, input icons → station + movement icon → output icon, caption = the node's first sentence. ≤ 120 pictures; text form always.

---

## 12. Exports

`game.exports("tiamat_default_science")`, version 1, never raises:

| Field | What |
|---|---|
| `version` | `1` |
| `network_at(pos)` | `{ kind, supply, demand, stored }` or nil |
| `charge_of(stack)` / `add_charge(uuid, slot, n)` | read / change a carried cell's charge |
| `register_movement(spec)` | another mod's movement for the frame (while mods load) |
| `register_source(spec)` | another mod's power source |
| `glyphs` | read-only `{ id = { mask, variants } }` |
| `bodies(uuid)` | `{ { star, domain, living } }` |
| `on_fold(fn(uuid, from, to))` | a player folds |

---

## 13. Pacing — the climb, and how it is measured

**Target: about sixty hours for the whole tree, about thirty-five for the spine**, after the ~3 hours of the shared tree and ~2 hours for the Keystone. Model (a guess, in `docs/pacing.md` and `config.lua`):

| Tier | Nodes | Whole tier (insight) | On the spine | ★ kid nodes | Target income / hour | Hours for the whole tier |
|---|---|---|---|---|---|---|
| 1 | 4 | 40 | 0 | 4 | — | — |
| 2 | 1 | 20 | 0 | 1 | — | — |
| 3 | 22 | 2,450 | 1,460 | 10 | 450 | 5.4 |
| 4 | 21 | 4,110 | 2,440 | 10 | 600 | 6.8 |
| 5 | 25 | 11,250 | 4,850 | 7 | 1000 | 11.2 |
| 6 | 19 | 17,300 | 11,300 | 7 | 1150 | 15.0 |
| 7 | 15 | 31,700 | 20,000 | 8 | 1600 | 19.8 |
| **all** | **107** | **66,870** | **40,050** | | | **≈ 58 h** |

Every time in this section is time with a player near: stations pause in unloaded chunks. Tier 4 is cheap on purpose: it is the instrument tier, and instruments earn the long-tail insight (stars, specimens, weather, climate) that pays for tier 5's expense. What a player waits on besides insight:

| Tier | Material gate | Time gate | Place gate |
|---|---|---|---|
| 3 | iron, copper, plank, calcite, cave earth | a river or a hill (power) | water, height |
| 4 | coal, tin, silver, glass, cinnabar | blister steel: one day | a storm (the rod, the kite) |
| 5 | lead, sulfur, steel in bulk, gold (lamps, plating) | — | a mine deep enough to need an elevator |
| 6 | chromium, diamond, pitchblende (1,200+), orichalcum (2,000+) | radium: 27 blocks per grain | Wardenclyffe's 70-block height |
| 7 | aetherium, cavorite, strange matter | terraforming | the stars; the Deep |

**Measure, don't guess**: Progress's ledger (`progress sources`) sees every point by source; this mod's discovery groups are `found_stars`, `found_specimens`, `found_weather`, `found_climate`, `found_bodies`, `found_inventions`, `found_reading`, `found_toybox`. After a real session only `config.lua` changes.

`tools/check_tree.py` and `tools/glyphs.py` ship with the repo and run in CI, as magic's do.

---

## 14. Asks

### `docs/sibling-asks.md`

**Craft**
- **C-S1, a station run by a predicate.** `register_station{ auto = true, runs = fn(container) → speed_percent }` so Craft advances a frame's recipe itself while the predicate answers > 0. Fallback: this mod's loop + `perform` (§6.1) — works today.
- **C-S2, a boost that needs power.** `boost = { tool, heat, when = fn(container) → bool }`. Fallback: the blowing engine boosts whenever present (documented simplification).
- **C-S3, a glyph as an ingredient** — identical to magic's C-M1; the two mods ask once, together.
- ~~**C-S4, long recipes**~~ — withdrawn: blister steel is one day (§2.2).
- **C-S5, idempotent glyphs** — as C-M7; a convenience, since a repeat already answers `nil` and never raises.
- **C-S6, lighting a fire.** Export `ignite(pos, uuid)` for a laid campfire or an unlit station, so the burning glass can light one without the striker. Fallback: the burning glass is a magnifier only.
- **C-S7, unattended perform.** Export `perform`'s `{ unattended = true }` form, so a frame's tools are the frame's and never its owner's pockets. Fallback: attended, documented.

**Life**
- **L-S2, act on Life's creatures.** `push(entity, velocity)` / `freeze(entity, ticks)` for wells, repulsors and stasis; the Tesla coil already works through `set_alight`.
- **L-S3, composed abilities** (as magic's L-M3) for the levitator and gravity plating.
- **L-S4, moving drop entities.** The engine does not check who owns an entity, so this is a courtesy: agree with Life that the electromagnet may `set_entity` its drops, or have it export `pull_drops(pos, radius, uuid)`.
- ~~**L-S5, reading the worn view**~~ — not needed: `game.inventory(uuid, "tiamat_default_life:worn")` reads it.
- **L-S6, a tether.** Tie a creature on a `lead` to a block, so two horses can pull the Magdeburg hemispheres. Fallback: one horse, led.

**World**
- ~~**W-S1, pitchblende**~~ — landed: World generates it from 1,200 down.
- **W-S2, cave earth.** A nitrous earth under overhangs and in caves, for the saltpetre men. Fallback: `dirt`.
- **W-M1, cinnabar** — shared with magic.

**UI**
- **U-S1, shape-crafter presets from siblings** — shared with magic's U-M1: gear, wheel, pipe, coil, ring, gnomon, cairn as buttons, shown when their node is held.

**Weather**
- **Wx-S2, a layered sky overlay** — shared with magic's Wx-M1.
- **Wx-S1, wind.** Export `wind(x, z)` — internally `wind(x, z, tick) → { x, z }`, a direction with no strength — and, if Weather will, a strength beside it, for windmills and kites. Fallback: weather intensity alone.
- **Wx-S3, domains.** Weather stands aside for players off the overworld (it sends sky and clouds by x and z whatever the domain), so a body's sky is this mod's.
- **Wx-S4, fires near a point.** `fires_near(pos, r)`, so a lightning rod can put out every fire round it. Fallback: the strike's own block.

**Progress**
- **P-S1, branch labels and a reveal rule** — shared with magic's P-M1. Check the tree screen against 15 to 25 nodes a tier (§2.2).
- **P-S2, a study-insight effect.** Progress reads an effect key (say `progress.study_percent`) when it pays a study, so the Difference Engine's +20 % does something. Until then the effect is carried and inert.

### `docs/engine-asks.md`

- **E-S1, a gravity scale per player** (`set_player_abilities{ gravity = 0.17 }` or per domain). Retires the per-tick impulse of plating, soles, low-g bodies.
- **E-S2, the instance in the generator** — shared with magic's E-M1. Retires the slot trick and its cap of 225 bodies a kind (§6.8).
- **E-S3, actions that fire** — shared with magic's E-M3: `register_action` is inert until the engine's Task 13, so every screen also opens by its item and by chat (§10.3).

---

## 15. Code rules

Craft's and Progress's code rules verbatim. Additions:

1. **Nothing scans the world on the tick.** Frames, networks, instruments, automata, gates and bodies each live on a list walked with a per-tick budget (`config.tick_budget`, default 64).
2. **Networks rebuild on place and dig only**, bounded, and are stored — a restart reloads them, never recomputes them from the world.
3. **No randomness where a counter will do**; where randomness is needed, the LCG or `rng_stream`.
4. **Historical accuracy is testable data**: every node's year and source live in `config.lua` and are printed in `docs/history.md` by `tools/check_tree.py`.
5. **Sources in `docs/history.md`:** Hero's *Mechanica*; Vitruvius *De architectura* X; the *Wujing Zongyao* (1044); Ibn al-Haytham *Kitāb al-Manāẓir*; Agricola *De re metallica* (1556); Gilbert *De magnete* (1600); Galileo *Sidereus nuncius* (1610); Hooke *Micrographia* (1665); Newton *Principia* (1687); Leupold *Theatrum Machinarum* (1724); Franklin's letters (1750–52); Faraday's *Experimental Researches*; Lovelace's Notes (1843); Maxwell (1865); Michelson & Morley (1887); Tesla's lectures (1891–93) and patents; Wells *The First Men in the Moon* (1901). Tone reference for tier 7: *Event Horizon* (1997, dir. Paul W. S. Anderson) — concepts only (a gravity drive folding space; the thing beyond); no names, likenesses or imagery from the film.

---

## 16. Tests (`tests/native`)

- Load with every sibling, and again without Weather and without the interface (the mod loads and degrades); the tree registers with none disabled; `check_tree.py` agrees; bench buyable before the Fork, path nodes refused.
- **Door:** the Mechanism recipe appears only with `shared.keystone`; choosing grants `natural_philosophy`, gives notebook and primer.
- **Glyphs:** every variant registered; no collision with magic's table (fixture); `rod` = Pillar and `plate` = Slab accepted as intentional.
- **Frames:** no registered recipe exceeds Craft's `max_ticks`; a frame with no power never performs; with a crank, each use advances it; a water wheel beside water powers it; `perform` is called with the placer as owner; the card chooses the recipe.
- **Networks:** build/dig a shaft line → rebuilt once; wooden cap enforced; wire loss by distance; AC effects; stores fill with surplus; a restart restores networks from storage bit-for-bit.
- **Furnace:** each ladder step with and without its node; boost to 5 only with the blowing engine; blister steel after one simulated day.
- **Instruments:** each reading against stubbed World/Weather/stars; discoveries once each.
- **Lightning:** a stubbed `on_lightning` near a rod fills jars and extinguishes a stubbed fire.
- **Automata:** a deck runs its cards; hold never duplicates or loses a stack; path budget respected.
- **Gravity:** plating applies impulses only above it; no `set_player_abilities` without L-S3; no `set_sky_modifier` without Wx-S2.
- **Fold:** a star body is created at the star's position with the kind from warmth; two bodies generate different terrain (slots); no coordinate leaves −60,000..59,999; the Fold refuses a full kind; terraforming converts a footprint; the Deep's morphic rock drops strange matter only in the Deep; falling off returns the player and keeps the strange matter behind.
- **Repath:** automata dormant, bodies sealed not destroyed; back again → restored.
- **Determinism:** full suite twice → identical storage dump.

---

## 17. Build order

1. Scaffold, manifest, config, hooks, store, items, blocks. **Tests: load.**
2. **Tinker's Bench** (§4) end to end. `0.1.0` — shippable before the Fork has a door.
3. Door, `tree.lua`, `check_tree.py`, glyphs. **Tests: tree, door, glyphs.**
4. Frame + crank + job loop; turning network; water wheel, windmill, screw, mills; furnace and the ladder to cast iron and blister steel; saltpeter and powder; optics basics. **Tier 3 playable.** `0.2.0`.
5. Instruments and their discoveries; vacuum; jars, rod, kite; Newcomen; coke and crucible steel; steel tools. `0.3.0`.
6. Tier 5: Watt, Bessemer, lathe and assembly jig (relic fallback), cards, automaton, charge network, pile, dynamo, motor, lamp, telegraph, elevator, photography. `0.4.0`.
7. Tier 6: AC, Tesla coil, radio, X-rays, radium, oscillator, arc furnace, drill, Wardenclyffe, aether, cavorite. `0.5.0`.
8. Tier 7: gravity devices, gravity engine, the Core, wormholes, star bodies, terraforming, the Deep, capstone. `1.0.0`.
9. Pacing from a real session's ledger; `config.lua` only.

---

## 18. Numbers a designer will turn (`config.lua`)

Every node cost; every recipe; every movement's need; every source's output; shaft caps and runs; wire loss and its effects; store sizes; instrument radii and costs; discovery values; study yields; automaton rates and card table; gravity impulse fractions; Core power and check sizes; body slot layout and kind thresholds; terraform rates; Deep fall height; tick budget; per-player caps (networks, gates, automata, bodies).

---

## 19. Out of scope

Weapons: no guns, no death rays (Tesla's "teleforce" stays a rumour in a node text), no charges that hurt anyone. Vehicles and rails (entity riding is not in the engine; the elevator and wormholes are the transport). Nuclear fission and anything past 1930s physics except the aether fiction. Genetic engineering (Schism's tech tier 6 — it does not fit this tree's steam-and-lightning soul). Horror imagery: no gore, no body horror, no jump scares in the Deep. Magic's content, in any form.
