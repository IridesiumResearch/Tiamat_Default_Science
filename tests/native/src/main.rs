// SPDX-FileCopyrightText: Iridesium
// SPDX-License-Identifier: GPL-3.0-only
//
// The mod, run for real: the engine's script VM with a fake server around it
// (rig.rs), the real sibling mods loaded beside it, and a probe above it
// that asks them what they see (fixtures/probe.lua).

// The rig carries fakes not every test reads.
#[allow(dead_code)]
mod rig;

use rig::{MOD, PLAYER, Rig, Setup};

/// A gnomon as the brief draws it: a slab with a peg in its middle.
const GNOMON: u32 = 1_846_791;
/// The same gnomon carved upside down: the slab on top, the peg under it.
const GNOMON_UPSIDE_DOWN: u32 = 117_678_528;
/// A cairn: a slab with two stones on it.
const CAIRN: u32 = 1_912_327;
const STONE: &str = "tiamat_default_world:stone";

fn main() {
    loads();
    loads_without_the_optional_mods();
    the_bench();
    the_sundial();
    the_burning_glass();
    sunfire();
    the_compass();
    the_kite();
    the_book();
    the_tree();
    the_door();
    tier3_loads();
    the_crank();
    the_water_wheel();
    the_windmill_and_pump();
    the_blast_furnace();
    blister_steel();
    mining_charges();
    printing();
    survey_and_dip();
    tier4_instruments();
    the_weather_glasses();
    hemispheres_and_balloon();
    leyden_jars();
    the_lightning_rod();
    the_newcomen_engine();
    coke_and_steel();
    tier4_works();
    punched_cards();
    puddling_and_bessemer();
    the_steam_hammer();
    the_charge_network();
    dynamo_and_motor();
    the_safety_elevator();
    camera_and_blueprint();
    gravimeter_and_dynamite();
    relics_and_parts();
    the_automaton();
    radium_and_lamps();
    the_tesla_coil();
    wireless();
    xrays_and_earthquakes();
    the_arc_furnace();
    wardenclyffe();
    gravity();
    the_core_and_the_fold();
    gates_and_recall();
    the_diamond_drill();
    gravitic_drones();
    worlds_generated();
    wells_and_stasis();
    terraforming();
    determinism();
    println!("science native check: all passed");
}

fn op(r: &Rig) {
    r.huds.operators.lock().unwrap().push(PLAYER);
}

/// A player who has lit a first fire and has insight to spend.
fn ready(r: &mut Rig, insight: i32) {
    r.join(PLAYER);
    r.tick(1);
    op(r);
    assert_eq!(r.ask("progress grant shared.firecraft"), "Learned: Firecraft", "an operator's grant");
    assert_eq!(r.ask(&format!("t award {insight}")), insight.to_string());
}

fn learn(r: &mut Rig, node: &str) {
    assert_eq!(r.ask(&format!("t learn {node}")), "true", "learning {node}");
}

fn insight(r: &mut Rig) -> i32 {
    r.ask("t insight").parse().unwrap()
}

/// Bursts this mod's kite drew since the last call: the kite is seen from
/// further than anything else here, so its radius picks it out.
fn kite_bursts(r: &Rig) -> usize {
    kite_positions(r).len()
}

/// Where each of those bursts was drawn, `[x, y, z]`.
fn kite_positions(r: &Rig) -> Vec<[f64; 3]> {
    r.bursts()
        .iter()
        .filter(|b| b.contains("radius: 64.0"))
        .map(|b| {
            let at = b.split("pos: [").nth(1).expect("a position").split(']').next().unwrap();
            let v: Vec<f64> = at.split(", ").map(|n| n.parse().unwrap()).collect();
            [v[0], v[1], v[2]]
        })
        .collect()
}

/// Everything registers into the real siblings, and nothing is refused.
fn loads() {
    let mut r = Rig::new(Setup::default());
    r.join(PLAYER);
    r.tick(1);
    let mut nodes: Vec<String> = r.ask("t nodes").split(' ').map(str::to_owned).collect();
    nodes.sort();
    assert_eq!(
        nodes,
        ["shared.burning_glass/1/15", "shared.compass/2/20", "shared.kite/1/10", "shared.sundial/1/10", "shared.theatrum/1/5"],
        "Progress validated all five Bench nodes"
    );
    assert_eq!(r.ask("t science"), "1", "the export is version 1");
    assert_eq!(r.ask("science"), "The Tinker's Bench: 0 of 5 learned.");
    // Every Bench recipe is in Craft, and gated on its node.
    for recipe in ["theatrum", "lens", "kite", "compass"] {
        let answer = r.ask(&format!("t can {MOD}:{recipe}"));
        assert!(answer.starts_with("nil") && !answer.contains("no such"), "{recipe}: {answer}");
    }
    // Every orientation of a glyph is Craft's, and means the same.
    assert_eq!(r.ask("t glyph gnomon"), "6");
    assert_eq!(r.ask("t glyph cairn"), "6");
    assert_eq!(r.ask(&format!("t glyph_of {GNOMON}")), format!("{MOD}:gnomon"));
    assert_eq!(r.ask(&format!("t glyph_of {GNOMON_UPSIDE_DOWN}")), format!("{MOD}:gnomon"));
    assert_eq!(r.ask(&format!("t glyph_of {CAIRN}")), format!("{MOD}:cairn"));
    println!("loads: ok");
}

/// Without the interface and the weather, which are optional, it still
/// loads: the book is a plain dialog and the kite flies at one height.
fn loads_without_the_optional_mods() {
    let mut r = Rig::new(Setup { ui: false, weather: false, ..Setup::default() });
    ready(&mut r, 5);
    learn(&mut r, "shared.theatrum");
    r.give(PLAYER, "theatrum", 27);
    r.hold(PLAYER, "theatrum");
    assert!(r.use_at_nothing(PLAYER), "the book is read at nothing");
    let (form, tree) = r.last_dialog().expect("the book");
    assert_eq!(form, format!("{MOD}:theatrum"));
    assert!(tree.contains("Theatrum Machinarum"), "{tree}");

    r.give(PLAYER, "kite", 27);
    r.hold(PLAYER, "kite");
    r.bursts();
    r.tick(10);
    let at = kite_positions(&r);
    assert_eq!(at.len(), 2, "a kite and its tail");
    assert_eq!(at[0], [100.5, 72.0, 96.5], "with no weather: eight up, four behind a body facing north");
    println!("loads without the optional mods: ok");
}

/// The child's first hour: the book, the glass, the kite, the compass. Every
/// node costs what the brief says, and nothing a child makes is lost.
fn the_bench() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 60);

    assert!(r.ask(&format!("t can {MOD}:theatrum")).starts_with("nil"), "gated before its node");
    learn(&mut r, "shared.theatrum");
    assert_eq!(insight(&mut r), 55);
    r.give(PLAYER, "tiamat_default_craft:leather", 27);
    r.give(PLAYER, "tiamat_default_craft:bark_strip", 54);
    r.give(PLAYER, "tiamat_default_craft:charcoal", 27);
    assert_eq!(r.ask(&format!("t make {MOD}:theatrum")), "made");
    assert_eq!(r.units(PLAYER, "theatrum"), 27);
    assert_eq!(r.units(PLAYER, "tiamat_default_craft:bark_strip"), 0);

    learn(&mut r, "shared.sundial");
    learn(&mut r, "shared.burning_glass");
    r.give(PLAYER, "tiamat_default_craft:glass", 27);
    r.give(PLAYER, "tiamat_default_world:sand", 9);
    assert_eq!(r.ask(&format!("t make {MOD}:lens")), "made");
    assert_eq!(r.units(PLAYER, "lens"), 27);
    assert_eq!(r.units(PLAYER, "tiamat_default_world:sand"), 0);

    learn(&mut r, "shared.kite");
    r.give(PLAYER, "tiamat_default_craft:cloth", 27);
    r.give(PLAYER, "tiamat_default_craft:stick", 54);
    r.give(PLAYER, "tiamat_default_craft:cord", 27);
    assert_eq!(r.ask(&format!("t make {MOD}:kite")), "made");
    assert_eq!(r.units(PLAYER, "kite"), 27);

    learn(&mut r, "shared.compass");
    r.give(PLAYER, "tiamat_default_craft:iron_nails", 27);
    r.give(PLAYER, "tiamat_default_craft:fired_clay", 27);
    assert_eq!(r.ask(&format!("t make {MOD}:compass")), "made");
    assert_eq!(r.units(PLAYER, "compass"), 27);

    assert_eq!(r.ask("science"), "The Tinker's Bench: 5 of 5 learned.");
    assert_eq!(insight(&mut r), 0, "the Bench's nodes cost 60 insight");
    println!("the bench: ok");
}

/// A gnomon carved from stone tells the hour in sunshine, and only then.
fn the_sundial() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 15);
    r.put_carved(10, 64, 10, STONE, GNOMON);

    // Before the node, a carved stone is only a carved stone.
    r.set_time(0.625);
    assert!(!r.use_at(PLAYER, 10, 64, 10), "nobody reads a dial they have not learned");

    learn(&mut r, "shared.theatrum");
    learn(&mut r, "shared.sundial");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 10, 64, 10));
    let heard = r.heard(PLAYER);
    assert!(heard.iter().any(|l| l == "The shadow says it is about 3 in the afternoon."), "{heard:?}");
    assert_eq!(insight(&mut r), 3, "the hour, told by the sun, the first time");

    r.set_time(0.5);
    assert!(r.use_at(PLAYER, 10, 64, 10));
    assert!(r.heard(PLAYER).iter().any(|l| l == "The shadow says it is about noon."));
    assert_eq!(insight(&mut r), 3, "and only the first time");

    // Upside down it is still a gnomon.
    r.put_carved(12, 64, 12, STONE, GNOMON_UPSIDE_DOWN);
    r.set_time(0.3);
    assert!(r.use_at(PLAYER, 12, 64, 12));
    assert!(r.heard(PLAYER).iter().any(|l| l == "The shadow says it is about 7 in the morning."));

    r.set_time(0.9);
    assert!(r.use_at(PLAYER, 10, 64, 10));
    assert!(r.heard(PLAYER).iter().any(|l| l == "The sun is down, so the dial casts no shadow."));

    r.set_time(0.5);
    r.roof(true);
    assert!(r.use_at(PLAYER, 10, 64, 10));
    assert!(r.heard(PLAYER).iter().any(|l| l == "No sunlight falls on the dial."));
    r.roof(false);

    // A whole block of stone is not a dial.
    r.put_block(14, 64, 14, STONE);
    assert!(!r.use_at(PLAYER, 14, 64, 14));
    println!("the sundial: ok");
}

/// The burning glass says what anything is, and how hard.
fn the_burning_glass() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    r.give(PLAYER, "lens", 27);
    r.hold(PLAYER, "lens");
    r.put_block(5, 64, 5, "tiamat_default_world:granite");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 5, 64, 5), "anyone holding one may look through it");
    let heard = r.heard(PLAYER);
    let line = heard.last().expect("a reading");
    assert!(line.starts_with("Granite: ") && line.contains("stone"), "{line}");
    assert!(line.ends_with("to break by hand.") || line.ends_with("It breaks at a touch."), "{line}");
    assert!(!r.use_at_nothing(PLAYER), "at the sky there is nothing to see");
    println!("the burning glass: ok");
}

/// A laid campfire lit by the noon sun through the glass, and only then;
/// with nothing in hand, the fire's box opens as it always did.
fn sunfire() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    let unlit = "tiamat_default_craft:unlit_campfire";
    r.put_block(7, 64, 7, unlit);
    r.give(PLAYER, "lens", 27);
    r.hold(PLAYER, "lens");

    r.set_time(0.3);
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 7, 64, 7));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The glass needs the high noon sun on it to light a fire."));

    r.set_time(0.5);
    r.roof(true);
    assert!(r.use_at(PLAYER, 7, 64, 7));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The glass needs the high noon sun on it to light a fire."));
    r.roof(false);

    assert!(r.use_at(PLAYER, 7, 64, 7));
    let heard = r.heard(PLAYER);
    assert!(heard.iter().any(|l| l == "The sun through the glass sets it alight!"), "{heard:?}");
    // With Life loaded, a burning campfire is Life's block (Craft, `fire.lua`).
    let lit = r.material("tiamat_default_life:campfire");
    assert_eq!(r.world.blocks.lock().unwrap().get(&(7, 64, 7)).map(|b| b.0), Some(lit), "Craft lit it");
    // Ours for sunshine, and Progress's own for a first fire lit (Craft's `fire:lit`).
    assert_eq!(insight(&mut r), 10, "a fire lit by sunshine, and a first fire");

    // Nothing in hand at another laid fire: Craft's box, not the glass.
    r.put_block(9, 64, 9, unlit);
    r.inventory.held.lock().unwrap().remove(&PLAYER);
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 9, 64, 9), "Craft still hears it");
    assert!(!r.heard(PLAYER).iter().any(|l| l.contains("glass")), "the glass says nothing");
    println!("sunfire: ok");
}

/// North, then home: a cairn placed is where the needle points.
fn the_compass() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    r.give(PLAYER, "compass", 27);
    r.hold(PLAYER, "compass");
    r.stand_at(100.5, 64.0, 100.5);

    r.bursts();
    r.heard(PLAYER);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("North is that way."));
    let needle = r.bursts();
    assert_eq!(needle.len(), 6, "a needle of six dots: {needle:?}");
    assert!(needle[0].contains("pos: [100.5, 65.2, 101.5]"), "a block north of the player, at chest height: {}", needle[0]);

    // A cairn of plank is no cairn; of stone, it is home. East is -x.
    assert!(r.place(PLAYER, 40, 64, 100, "tiamat_default_craft:plank", CAIRN));
    assert!(r.stored(&format!("cairn:{}", rig::hex(PLAYER))).is_none(), "wood marks nothing");
    assert!(r.place(PLAYER, 40, 64, 100, STONE, CAIRN), "the placement goes ahead");
    assert!(r.heard(PLAYER).iter().any(|l| l.starts_with("This cairn marks your home.")));
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Home is about 60 blocks away, to the east."));
    assert_eq!(insight(&mut r), 5, "a needle that finds home");

    // The newest cairn is home.
    assert!(r.place(PLAYER, 150, 64, 150, STONE, CAIRN));
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Home is about 70 blocks away, to the north-west."));
    r.stand_at(150.5, 64.0, 151.0);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("You are home!"));

    // Dug up, it is forgotten, and the needle points north again.
    r.world.blocks.lock().unwrap().remove(&(150, 64, 150));
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("North is that way."));
    assert!(r.stored(&format!("cairn:{}", rig::hex(PLAYER))).is_none());
    assert_eq!(insight(&mut r), 5, "found once, paid once");
    println!("the compass: ok");
}

/// Held under the open sky, a kite flies; under a roof, or put away, not.
fn the_kite() {
    let mut r = Rig::new(Setup::default());
    r.open_world(20260930);
    ready(&mut r, 0);
    r.give(PLAYER, "kite", 27);

    r.bursts();
    r.tick(10);
    assert_eq!(kite_bursts(&r), 0, "a kite in the pack does not fly");

    r.hold(PLAYER, "kite");
    r.tick(10);
    let at = kite_positions(&r);
    assert_eq!(at.len(), 2, "a kite and its tail");
    // Weather's wind: at least a clear day's 0.2 lifts it two blocks, and
    // it stands four blocks off downwind, whichever way that is.
    assert!(at[0][1] >= 74.0 && at[0][1] <= 82.0, "lifted by the wind: {:?}", at[0]);
    let (dx, dz) = (at[0][0] - 100.5, at[0][2] - 100.5);
    assert!((dx.abs() + dz.abs() - 4.0).abs() < 1e-6, "four blocks off along |x| + |z|: {:?}", at[0]);
    assert_eq!(insight(&mut r), 5, "a kite in the sky, the first time");
    r.tick(10);
    assert_eq!(kite_bursts(&r), 2, "drawn again every half second");
    assert_eq!(insight(&mut r), 5);

    r.roof(true);
    r.tick(10);
    assert_eq!(kite_bursts(&r), 0, "no sky, no kite");
    println!("the kite: ok");
}

/// The Theatrum: a page for each node held or next, with what it makes.
fn the_book() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 15);
    assert_eq!(r.ask("science book"), "You have no Theatrum. Make one by hand: leather, two bark strips, charcoal.");
    r.action(PLAYER, &format!("{MOD}:theatrum"));
    assert!(r.last_dialog().is_none(), "the key opens no book for a player without one");
    learn(&mut r, "shared.theatrum");
    r.give(PLAYER, "theatrum", 27);

    r.action(PLAYER, &format!("{MOD}:theatrum"));
    let (form, _) = r.last_dialog().expect("the key opens it");
    assert_eq!(form, format!("{MOD}:theatrum"));

    assert_eq!(r.ask("science book"), "", "opened, and nothing said");
    let (form, tree) = r.last_dialog().expect("the book");
    assert_eq!(form, format!("{MOD}:theatrum"));
    assert!(tree.contains("Theatre of Machines"), "{tree}");
    assert!(tree.contains("Learn it at the research table for 10 insight."), "the next nodes, unlearned: {tree}");
    assert!(!tree.contains("The Wet Compass"), "never the whole tree at once: {tree}");

    learn(&mut r, "shared.sundial");
    r.ask("science book");
    let (_, tree) = r.last_dialog().expect("the book");
    assert!(tree.contains("the Gnomon button"), "how to carve one: {tree}");
    println!("the book: ok");
}

/// What ships of the tree is registered, gated beyond the Fork, and grouped
/// by branch with the frontier revealed.
fn the_tree() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 5000);
    assert_eq!(r.ask("t count"), "102", "Progress validated what ships: tiers 3 to 7, the whole tree");
    // A node that says no `reveal` of its own takes the path's, "near".
    assert_eq!(r.ask("t branch science.water_wheel"), "MECH/nil", "a branch, and the path's reveal");
    let answer = r.ask("t learn science.machine_frame");
    assert!(answer.starts_with("nil") && answer.contains("lies beyond the Fork"), "{answer}");
    assert_eq!(insight(&mut r), 5000, "nothing was spent");
    println!("the tree: ok");
}

/// The Antikythera Mechanism: its recipe waits for the Keystone; choosing it
/// binds the player, gives Natural Philosophy free and the notebook and the
/// Theatrum once, and opens the tree, whose effects Progress then sums.
fn the_door() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 600);
    let answer = r.ask("t can tiamat_default_progress:door_science");
    assert!(answer.starts_with("nil") && !answer.contains("no such"), "the door's recipe, gated: {answer}");

    r.put_block(20, 64, 20, "antikythera");
    assert!(r.use_at(PLAYER, 20, 64, 20));
    assert_eq!(r.said(), "The door is shut to you. Learn the Keystone first.");

    assert_eq!(r.ask("progress grant shared.keystone"), "Learned: The Keystone");
    assert!(r.use_at(PLAYER, 20, 64, 20));
    let (form, tree) = r.last_dialog().expect("the Fork's question");
    assert_eq!(form, "tiamat_default_progress:fork");
    assert!(tree.contains("The dials turn once, for you alone."), "{tree}");
    r.heard(PLAYER);
    r.press(PLAYER, "tiamat_default_progress", "fork", "yes");
    let heard = r.heard(PLAYER);
    assert!(heard.iter().any(|l| l == "The dials have turned. Build a frame."), "{heard:?}");
    assert_eq!(r.ask("t path"), "science");
    assert_eq!(r.ask("t has science.natural_philosophy"), "true", "the root, free");
    assert_eq!(insight(&mut r), 600, "and it cost nothing");
    assert_eq!(r.units(PLAYER, "notebook"), 27, "the notebook, once");
    assert_eq!(r.units(PLAYER, "theatrum"), 27, "and the Theatrum, once");

    // The tree is open now, and its effects are summed where Craft reads them.
    assert_eq!(r.ask("t learn science.machine_frame"), "true");
    assert_eq!(r.ask("t learn science.simple_machines"), "true");
    assert_eq!(r.ask("t learn science.gearing"), "true");
    assert_eq!(r.ask("t learn science.water_wheel"), "true");
    assert_eq!(r.ask("t learn science.trip_hammer"), "true");
    assert_eq!(r.ask("t effects craft."), "craft.anvil_strikes=-1");
    assert_eq!(insight(&mut r), 600 - 100 - 80 - 100 - 120 - 120);

    assert!(r.use_at(PLAYER, 20, 64, 20));
    assert_eq!(r.said(), "You are already of Natural Philosophy.");
    assert_eq!(r.units(PLAYER, "notebook"), 27, "no second notebook");
    println!("the door: ok");
}

/// A player on the science path, holding `nodes` (granted by an operator).
fn scientist(r: &mut Rig, nodes: &[&str]) {
    ready(r, 0);
    assert_eq!(r.ask("progress grant shared.keystone"), "Learned: The Keystone");
    r.put_block(20, 64, 20, "antikythera");
    assert!(r.use_at(PLAYER, 20, 64, 20));
    r.press(PLAYER, "tiamat_default_progress", "fork", "yes");
    assert_eq!(r.ask("t path"), "science");
    for node in nodes {
        let answer = r.ask(&format!("progress grant {node}"));
        assert!(answer.starts_with("Learned"), "{node}: {answer}");
    }
}

const FULL: u32 = 0x7FF_FFFF;
const PLANK: &str = "tiamat_default_craft:plank";
const WHEEL: u32 = 14_775_352;
const ROD: u32 = 74_752;
const PLATE: u32 = 1_838_599;

fn frame_at(x: i32, y: i32, z: i32) -> String {
    format!("tiamat_default_craft:{MOD}:frame:{x},{y},{z}")
}

fn furnace_at(x: i32, y: i32, z: i32) -> String {
    format!("tiamat_default_craft:{MOD}:furnace:{x},{y},{z}")
}

/// Every tier 3 recipe, the Bench's and the studies are in Craft: nothing
/// was refused.
fn tier3_loads() {
    let mut r = Rig::new(Setup::default());
    r.join(PLAYER);
    r.tick(1);
    assert_eq!(r.ask("t ours"), "167", "4 on the Bench, 49 in tier 3, 31 in tier 4, 33 in tier 5, 23 in tier 6, 12 in tier 7, 15 studies");
    for recipe in ["frame", "crush_iron", "pig_iron", "blister_steel", "sand_mould_pipe", "clockwork", "print_treatise"] {
        let answer = r.ask(&format!("t can {MOD}:{recipe}"));
        assert!(!answer.contains("no such"), "{recipe}: {answer}");
    }
    println!("tier 3 loads: ok");
}

/// A frame turned by hand: stamps crush iron ore, a third more, and the
/// first crushing is an invention.
fn the_crank() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.stamp_mill"]);
    assert!(r.place(PLAYER, 30, 64, 30, "frame", FULL));
    let frame = frame_at(30, 64, 30);
    r.put_in(&frame, 1, "stamps", 27);
    r.put_in(&frame, 2, "tiamat_default_world:iron_ore", 20);
    r.give(PLAYER, "crank_handle", 27);
    r.hold(PLAYER, "crank_handle");
    let before = insight(&mut r);
    // A crank gives 4 turns against the stamps' 8: half speed, while it turns.
    for _ in 0..40 {
        if r.units_in(&frame, 6, 9, &format!("{MOD}:crushed_iron")) > 0 {
            break;
        }
        assert!(r.use_at(PLAYER, 30, 64, 30), "the crank is heard, not the box");
        r.tick(40);
    }
    assert_eq!(r.units_in(&frame, 6, 9, &format!("{MOD}:crushed_iron")), 27, "20 units of ore, 27 crushed");
    assert_eq!(r.units_in(&frame, 2, 5, "tiamat_default_world:iron_ore"), 0);
    assert_eq!(r.units_in(&frame, 1, 1, &format!("{MOD}:stamps")), 27, "the stamps are kept, unworn");

    // The Theatrum has the tier's pages: what is held, with its recipes and
    // how to use it, and what could be learned next.
    r.give(PLAYER, "theatrum", 27);
    assert_eq!(r.ask("science book"), "");
    let (_, tree) = r.last_dialog().expect("the book");
    assert!(tree.contains("The Machine Frame") && tree.contains("Crank handle"), "held, with its recipes: {tree}");
    assert!(tree.contains("use a crank handle on the frame"), "and how to use it: {tree}");
    assert!(tree.contains("The Windmill") && tree.contains("Learn it at the research table for 120 insight."),
        "the next, unlearned: {tree}");
    assert!(!tree.contains("Blister Steel"), "never the whole tree: {tree}");
    assert_eq!(insight(&mut r) - before, 10, "an invention: the stamps");

    // Left alone, it stops.
    r.put_in(&frame, 2, "tiamat_default_world:iron_ore", 20);
    r.tick(600);
    assert_eq!(r.units_in(&frame, 2, 5, "tiamat_default_world:iron_ore"), 20, "nobody turned it");
    println!("the crank: ok");
}

/// A carved plank wheel with water beside it turns the frame it touches.
fn the_water_wheel() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.stamp_mill"]);
    assert!(r.place(PLAYER, 40, 64, 40, "frame", FULL));
    let frame = frame_at(40, 64, 40);
    r.put_in(&frame, 1, "stamps", 27);
    r.put_in(&frame, 2, "tiamat_default_world:copper_ore", 20);
    assert!(r.place(PLAYER, 41, 64, 40, PLANK, WHEEL), "the wheel");
    r.water(42, 64, 40, 27);
    r.water(41, 63, 40, 27);
    r.tick(260);
    assert_eq!(r.units_in(&frame, 6, 9, &format!("{MOD}:crushed_copper")), 27, "two wet sides, 8 turns: full speed");

    // A shaft between: the wheel two blocks off turns it just the same.
    assert!(r.place(PLAYER, 50, 64, 40, "frame", FULL));
    let far = frame_at(50, 64, 40);
    r.put_in(&far, 1, "stamps", 27);
    r.put_in(&far, 2, "tiamat_default_world:tin_ore", 20);
    assert!(r.place(PLAYER, 51, 64, 40, PLANK, ROD));
    assert!(r.place(PLAYER, 52, 64, 40, PLANK, WHEEL));
    r.water(53, 64, 40, 27);
    r.water(52, 63, 40, 27);
    r.tick(260);
    assert_eq!(r.units_in(&far, 6, 9, &format!("{MOD}:crushed_tin")), 27, "through a shaft");
    println!("the water wheel: ok");
}

/// A windmill high on a hill turns a pump that lifts water up through its frame.
fn the_windmill_and_pump() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.windmill", "science.archimedes_screw"]);
    r.put_block(60, 64, 60, "tiamat_default_world:stone");
    assert!(r.place(PLAYER, 60, 80, 60, PLANK, WHEEL), "the hub, sixteen up");
    assert!(r.place(PLAYER, 61, 80, 60, PLANK, PLATE), "a sail");
    assert!(r.place(PLAYER, 59, 80, 60, PLANK, PLATE), "another");
    assert!(r.place(PLAYER, 60, 80, 61, "frame", FULL));
    let frame = frame_at(60, 80, 61);
    r.put_in(&frame, 1, "pump", 27);
    r.water(60, 79, 61, 27);
    let before = insight(&mut r);
    r.tick(20);
    assert_eq!(r.ask("t net 60 80 61"), "3/4/2", "a hub sixteen up in still air: 3 turns, against the pump's 4");
    r.tick(200);
    assert_eq!(r.water_at(60, 79, 61), 0, "lifted from under the frame");
    assert_eq!(r.water_at(60, 81, 61), 27, "to over it, every cell");
    assert_eq!(insight(&mut r) - before, 5, "water that climbs");
    println!("the windmill and the pump: ok");
}

/// Pig iron needs the blast: a blowing engine, and a shaft that turns.
fn the_blast_furnace() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.blast_furnace", "science.finery_forge"]);
    assert!(r.place(PLAYER, 70, 64, 70, "furnace", FULL));
    let furnace = furnace_at(70, 64, 70);
    r.put_in(&furnace, 1, "tiamat_default_craft:charcoal", 27 * 20);
    r.put_in(&furnace, 2, "tiamat_default_world:iron_ore", 54);
    r.put_in(&furnace, 3, "tiamat_default_craft:charcoal", 27);
    r.put_in(&furnace, 4, "tiamat_default_world:calcite", 9);
    r.put_in(&furnace, 5, "blowing_engine", 27);
    assert_eq!(r.ask("t ignite 70 64 70"), "true");

    // No shaft turning: charcoal's own heat is 2, and pig iron wants 5.
    r.tick(1400);
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:pig_iron")), 0, "no blast, no iron");

    // A wheel in water beside it: the engine blows.
    assert!(r.place(PLAYER, 71, 64, 70, PLANK, WHEEL));
    r.water(72, 64, 70, 27);
    r.water(71, 63, 70, 27);
    r.tick(1400);
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:pig_iron")), 81, "three pigs");
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:slag")), 27, "and slag");
    println!("the blast furnace: ok");
}

/// Blister steel: four bars and charcoal, a day in the furnace.
fn blister_steel() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.blast_furnace", "science.finery_forge", "science.cementation_steel"]);
    assert!(r.place(PLAYER, 80, 64, 80, "furnace", FULL));
    let furnace = furnace_at(80, 64, 80);
    r.put_in(&furnace, 1, "tiamat_default_craft:charcoal", 27 * 60);
    r.put_in(&furnace, 2, "tiamat_default_craft:iron_bar", 27 * 4);
    r.put_in(&furnace, 3, "tiamat_default_craft:charcoal", 27);
    assert_eq!(r.ask("t ignite 80 64 80"), "true");
    r.tick(40);
    assert_eq!(r.ask(&format!("t progress 23960 {furnace}")), "true", "a job in hand: the steel");
    r.tick(40);
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:blister_steel")), 27 * 4, "a day, and four blister steel");
    println!("blister steel: ok");
}

/// A mining charge loosens the rock round it, and never what is hard.
fn mining_charges() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.saltpetre_works", "science.gunpowder"]);
    for x in 89..=91 {
        for y in 63..=65 {
            for z in 89..=91 {
                r.put_block(x, y, z, "tiamat_default_world:stone");
            }
        }
    }
    r.put_block(91, 65, 91, "tiamat_default_world:obsidian");
    r.give(PLAYER, "mining_charge", 27);
    r.hold(PLAYER, "mining_charge");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 90, 64, 90));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The fuse is lit. Stand back!"));
    assert_eq!(r.units(PLAYER, "mining_charge"), 0, "the charge is set");
    r.tick(45);
    let stone = r.material("tiamat_default_world:stone");
    let left = r.world.blocks.lock().unwrap().values().filter(|b| b.0 == stone && b.1 != 0).count();
    assert_eq!(left, 0, "every stone loosened");
    let obsidian = r.material("tiamat_default_world:obsidian");
    assert_eq!(r.world.blocks.lock().unwrap().get(&(91, 65, 91)).map(|b| b.0), Some(obsidian), "hard rock holds");
    let drops = r.entities.0.lock().unwrap().values().filter(|e| e.item.is_some()).count();
    assert_eq!(drops, 26, "each block a drop");
    println!("mining charges: ok");
}

/// A press prints a signed treatise; another player learns from it once.
fn printing() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.blast_furnace", "science.cast_iron", "science.printing_press"]);
    assert!(r.place(PLAYER, 100, 64, 120, "frame", FULL));
    let frame = frame_at(100, 64, 120);
    r.put_in(&frame, 1, "press", 27);
    r.put_in(&frame, 2, "notebook", 27);
    r.put_in(&frame, 3, "tiamat_default_craft:leather", 27);
    r.put_in(&frame, 4, PLANK, 9);
    assert!(r.place(PLAYER, 101, 64, 120, PLANK, WHEEL));
    r.water(102, 64, 120, 27);
    r.water(101, 63, 120, 27);
    r.tick(460);
    let printed = (6..=9).filter_map(|s| r.slot_of(&frame, s)).find(|(id, _, _)| id == &format!("{MOD}:treatise"));
    let (_, units, detail) = printed.expect("a treatise");
    assert_eq!(units, 27);
    let mark = &rig::hex(PLAYER)[..8];
    assert_eq!(detail.as_deref(), Some(format!("a={mark}").as_str()), "signed by its printer");
    assert_eq!(r.units_in(&frame, 2, 5, &format!("{MOD}:notebook")), 27, "the notebook is kept");

    // Another player reads it: insight, once.
    let other = rig::OTHER;
    r.join(other);
    r.tick(1);
    r.hold_detailed(other, "treatise", &format!("a={mark}"));
    assert!(r.use_at_nothing(other));
    let heard = r.heard(other);
    assert!(heard.iter().any(|l| l.contains("Read a treatise")), "{heard:?}");
    assert!(r.use_at_nothing(other));
    assert_eq!(r.heard(other).last().map(String::as_str), Some("You have read this author before."));
    // Its author learns nothing from it.
    r.hold_detailed(PLAYER, "treatise", &format!("a={mark}"));
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("You wrote this one."));
    println!("printing: ok");
}

/// The surveyor's staff and the dip needle.
fn survey_and_dip() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    r.stand_at(100.5, 64.0, 100.5);
    r.put_block(110, 64, 100, "tiamat_default_world:stone");
    r.give(PLAYER, "surveyors_staff", 27);
    r.hold(PLAYER, "surveyors_staff");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 110, 64, 100));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("10 blocks away, level with you, at the surface."));

    r.give(PLAYER, "dip_needle", 27);
    r.hold(PLAYER, "dip_needle");
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The needle hangs still."));
    r.put_block(100, 58, 100, "tiamat_default_world:iron_ore");
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The needle leans gently down: metal ore, 6 blocks off."));
    println!("survey and dip: ok");
}

/// The telescope, the microscope, the chronometer and the orrery.
fn tier4_instruments() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    r.stand_at(100.5, 64.0, 100.5);

    // The telescope wants the night, and the sky.
    r.give(PLAYER, "telescope", 27);
    r.hold(PLAYER, "telescope");
    r.set_time(0.5);
    r.heard(PLAYER);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The sky is too bright to see the stars."));
    r.set_time(0.9);
    r.roof(true);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("You cannot see the sky from here."));
    r.roof(false);

    // The microscope: once per material.
    r.give(PLAYER, "microscope", 27);
    r.hold(PLAYER, "microscope");
    r.put_block(105, 64, 100, "tiamat_default_world:granite");
    let before = insight(&mut r);
    assert!(r.use_at(PLAYER, 105, 64, 100));
    let heard = r.heard(PLAYER);
    assert!(heard.iter().any(|l| l.starts_with("Under the microscope: Granite")), "{heard:?}");
    assert_eq!(insight(&mut r) - before, 3, "a specimen");
    assert!(r.use_at(PLAYER, 105, 64, 100));
    assert_eq!(insight(&mut r) - before, 3, "once");

    // The chronometer: a mark, and the way back to it.
    r.give(PLAYER, "chronometer", 27);
    r.hold(PLAYER, "chronometer");
    r.put_block(110, 64, 100, "tiamat_default_world:stone");
    assert!(r.use_at(PLAYER, 110, 64, 100));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Marked: 110, 64, 100."));
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str),
        Some("You are at 100, 64, 100. Your mark is about 10 blocks to the west."));

    // The orrery: a sun and four planets, for the player alone.
    r.give(PLAYER, "orrery", 27);
    r.hold(PLAYER, "orrery");
    r.bursts();
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.bursts().len(), 5, "a sun and four planets");
    println!("tier 4 instruments: ok");
}

/// The barometer and the thermometer read Weather, and log what they read.
fn the_weather_glasses() {
    let mut r = Rig::new(Setup { weather: false, ..Setup::default() });
    ready(&mut r, 0);
    r.give(PLAYER, "barometer", 27);
    r.hold(PLAYER, "barometer");
    r.heard(PLAYER);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The quicksilver does not move."), "no Weather");

    let mut r = Rig::new(Setup::default());
    r.open_world(20261001);
    ready(&mut r, 0);
    r.stand_at(100.5, 64.0, 100.5);
    r.tick(40);
    r.give(PLAYER, "barometer", 27);
    r.hold(PLAYER, "barometer");
    let before = insight(&mut r);
    assert!(r.use_at_nothing(PLAYER));
    let said = r.heard(PLAYER).last().cloned().unwrap_or_default();
    assert!(said != "The quicksilver does not move." && !said.is_empty(), "a reading: {said}");
    assert_eq!(insight(&mut r) - before, 20, "a kind of weather, measured: {said}");

    r.give(PLAYER, "thermometer", 27);
    r.hold(PLAYER, "thermometer");
    assert!(r.use_at_nothing(PLAYER));
    let said = r.heard(PLAYER).last().cloned().unwrap_or_default();
    assert!(said.ends_with("degrees Fahrenheit."), "{said}");
    println!("the weather glasses: ok");
}

/// Two horses cannot part the hemispheres; the balloon burns charcoal.
fn hemispheres_and_balloon() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    r.stand_at(100.5, 64.0, 100.5);
    r.give(PLAYER, "magdeburg_hemispheres", 27);
    r.hold(PLAYER, "magdeburg_hemispheres");
    r.heard(PLAYER);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Bring two horses, and let them pull."));
    r.creature(102.0, 64.0, 100.0, "tiamat_default_life:horse");
    r.creature(99.0, 64.0, 103.0, "tiamat_default_life:horse");
    let before = insight(&mut r);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str),
        Some("The horses strain and strain, and cannot pull the hemispheres apart!"));
    assert_eq!(insight(&mut r) - before, 5);

    r.give(PLAYER, "balloon_pack", 27);
    r.give(PLAYER, "tiamat_default_craft:charcoal", 54);
    r.hold(PLAYER, "balloon_pack");
    let before = insight(&mut r);
    r.tick(10);
    assert_eq!(r.units(PLAYER, "tiamat_default_craft:charcoal"), 27, "one charcoal alight");
    assert_eq!(insight(&mut r) - before, 5, "up in a balloon");
    r.tick(600);
    assert_eq!(r.units(PLAYER, "tiamat_default_craft:charcoal"), 0, "and the next, when it burns out");
    println!("hemispheres and balloon: ok");
}

/// The friction globe fills a Leyden jar; a charged jar sparks.
fn leyden_jars() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.glassworks", "science.electrostatics", "science.leyden_jar"]);
    assert!(r.place(PLAYER, 110, 64, 110, "frame", FULL));
    let frame = frame_at(110, 64, 110);
    r.put_in(&frame, 1, "friction_globe", 27);
    r.put_in(&frame, 2, "leyden_jar", 27);
    assert!(r.place(PLAYER, 111, 64, 110, PLANK, WHEEL));
    r.water(112, 64, 110, 27);
    r.water(111, 63, 110, 27);
    r.tick(400);
    let jar = r.slot_of(&frame, 2).expect("the jar");
    assert_eq!(jar.0, format!("{MOD}:leyden_jar"));
    let charge: u32 = jar.2.as_deref().and_then(|d| d.strip_prefix("e=")).and_then(|n| n.parse().ok()).expect("charged");
    assert!(charge >= 40 && charge <= 100, "rubbed for twenty seconds: {charge}");

    r.hold_detailed(PLAYER, "leyden_jar", &format!("e={charge}"));
    let before = insight(&mut r);
    assert!(r.use_at_nothing(PLAYER));
    let said = r.heard(PLAYER).last().cloned().unwrap_or_default();
    assert!(said.starts_with("Crack! A blue spark leaps from the jar"), "{said}");
    assert_eq!(insight(&mut r) - before, 3, "a spark from a jar");
    r.hold(PLAYER, "leyden_jar");
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The jar is empty."), "it gave all it had");
    println!("leyden jars: ok");
}

/// A bolt near a copper rod fills the jars its copper reaches, and puts the fires out.
fn the_lightning_rod() {
    let mut r = Rig::new(Setup::default());
    r.open_world(20261001);
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.wire_drawing",
        "science.glassworks", "science.electrostatics", "science.leyden_jar", "science.lightning_rod"]);
    // Built where the world's ground is, which is where Weather looks for it:
    // the rod on top, copper stock down to a frame holding a jar.
    let g: i32 = r.ask("t ground 122 122").parse().expect("the world has ground there");
    assert!(r.place(PLAYER, 120, g + 2, 120, "frame", FULL));
    let frame = frame_at(120, g + 2, 120);
    r.put_in(&frame, 2, "leyden_jar", 27);
    assert!(r.place(PLAYER, 120, g + 3, 120, "copper_stock", FULL));
    assert!(r.place(PLAYER, 120, g + 4, 120, "copper_stock", ROD));
    r.put_block(122, g, 122, "tiamat_default_world:stone");
    r.aim(122, g, 122);
    let before = insight(&mut r);
    let said = r.ask("/weather strike");
    assert!(said.starts_with("a bolt at"), "{said}");
    let jar = r.slot_of(&frame, 2).expect("the jar");
    assert_eq!(jar.2.as_deref(), Some("e=100"), "filled from the sky");
    assert_eq!(insight(&mut r) - before, 30, "you caught lightning");
    println!("the lightning rod: ok");
}

/// A burning furnace with a boiler, a copper pipe, a frame with a cylinder:
/// an engine, whose turning crushes ore in the next frame.
fn the_newcomen_engine() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.stamp_mill", "science.blast_furnace", "science.cast_iron",
        "science.papin_digester", "science.wire_drawing", "science.newcomen_engine"]);
    assert!(r.place(PLAYER, 130, 64, 130, "furnace", FULL));
    let furnace = furnace_at(130, 64, 130);
    r.put_in(&furnace, 1, "tiamat_default_craft:charcoal", 27 * 20);
    r.put_in(&furnace, 5, "boiler", 27);
    assert_eq!(r.ask("t ignite 130 64 130"), "true");
    assert!(r.place(PLAYER, 131, 64, 130, "copper_stock", 134_142_975), "a copper pipe");
    assert!(r.place(PLAYER, 132, 64, 130, "frame", FULL));
    r.put_in(&frame_at(132, 64, 130), 1, "cylinder", 27);
    assert!(r.place(PLAYER, 133, 64, 130, "frame", FULL));
    let mill = frame_at(133, 64, 130);
    r.put_in(&mill, 1, "stamps", 27);
    r.put_in(&mill, 2, "tiamat_default_world:lead_ore", 20);
    r.tick(40);
    assert_eq!(r.ask("t net 133 64 130"), "16/8/2", "the engine's 16 turns, against the stamps' 8");
    r.tick(260);
    assert_eq!(r.units_in(&mill, 6, 9, &format!("{MOD}:crushed_lead")), 27, "the engine works the mill");
    println!("the Newcomen engine: ok");
}

/// Coke burns hot enough for the finery without a blast; crucible steel.
fn coke_and_steel() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.blast_furnace", "science.finery_forge", "science.cementation_steel",
        "science.coke", "science.crucible_steel"]);
    assert!(r.place(PLAYER, 140, 64, 140, "furnace", FULL));
    let furnace = furnace_at(140, 64, 140);
    r.put_in(&furnace, 1, "tiamat_default_craft:charcoal", 27 * 20);
    r.put_in(&furnace, 2, "tiamat_default_world:coal", 27);
    assert_eq!(r.ask("t ignite 140 64 140"), "true");
    r.tick(2500);
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:coke")), 18, "coal baked to coke");
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:coal_tar")), 9, "and tar");

    // On coke alone, the finery: heat 3, no blowing engine.
    assert!(r.place(PLAYER, 150, 64, 150, "furnace", FULL));
    let finery = furnace_at(150, 64, 150);
    r.put_in(&finery, 1, &format!("{MOD}:coke"), 27 * 10);
    r.put_in(&finery, 2, &format!("{MOD}:pig_iron"), 27 * 2);
    assert_eq!(r.ask("t ignite 150 64 150"), "true");
    r.tick(700);
    assert_eq!(r.units_in(&finery, 6, 8, "tiamat_default_craft:iron_bar"), 27 * 3, "three bars from two pigs");

    // Crucible steel: blister steel and a crucible, in a blast.
    assert!(r.place(PLAYER, 160, 64, 160, "furnace", FULL));
    let crucible = furnace_at(160, 64, 160);
    r.put_in(&crucible, 1, &format!("{MOD}:coke"), 27 * 10);
    r.put_in(&crucible, 2, &format!("{MOD}:blister_steel"), 27 * 2);
    r.put_in(&crucible, 3, "tiamat_default_craft:crucible", 27);
    r.put_in(&crucible, 5, "blowing_engine", 27);
    assert!(r.place(PLAYER, 161, 64, 160, PLANK, WHEEL));
    r.water(162, 64, 160, 27);
    r.water(161, 63, 160, 27);
    assert_eq!(r.ask("t ignite 160 64 160"), "true");
    r.tick(1300);
    assert_eq!(r.units_in(&crucible, 6, 8, &format!("{MOD}:steel_ingot")), 27, "a steel ingot");
    println!("coke and steel: ok");
}

/// The lead chamber, the spinning frame and the lathe, each in a frame on
/// one water wheel; bone broth in a kiln; quicksilver in a furnace.
fn tier4_works() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, &["science.machine_frame", "science.simple_machines", "science.gearing",
        "science.water_wheel", "science.blast_furnace", "science.cast_iron", "science.saltpetre_works",
        "science.lead_chamber", "science.water_frame", "science.lathe", "science.papin_digester",
        "science.glassworks", "science.cinnabar_roasting"]);
    // Three frames in a row on a wheel: 16 turns against 4 + 8 + 8 = 20, so 80%.
    assert!(r.place(PLAYER, 170, 64, 170, PLANK, WHEEL));
    r.water(170, 63, 170, 27);
    r.water(169, 64, 170, 27);
    r.water(170, 64, 169, 27);
    r.water(170, 65, 170, 27);
    let chamber = frame_at(171, 64, 170);
    let spinner = frame_at(172, 64, 170);
    let lathe = frame_at(173, 64, 170);
    for x in 171..=173 {
        assert!(r.place(PLAYER, x, 64, 170, "frame", FULL));
    }
    r.put_in(&chamber, 1, "lead_chamber", 27);
    r.put_in(&chamber, 2, "tiamat_default_world:sulfur", 27);
    r.put_in(&chamber, 3, "saltpeter", 27);
    r.put_in(&spinner, 1, "spinning_frame", 27);
    r.put_in(&spinner, 2, "tiamat_default_life:wool", 81);
    r.put_in(&lathe, 1, "lathe_bed", 27);
    r.put_in(&lathe, 2, "tiamat_default_craft:iron_bar", 27);
    r.tick(20);
    assert_eq!(r.ask("t net 171 64 170"), "16/20/4");
    r.tick(800);
    assert_eq!(r.units_in(&chamber, 6, 9, &format!("{MOD}:oil_of_vitriol")), 81, "three of oil of vitriol");
    assert_eq!(r.units_in(&spinner, 6, 9, "tiamat_default_craft:cloth"), 81, "three cloth from three wool");
    assert_eq!(r.units_in(&lathe, 6, 9, &format!("{MOD}:piston")), 27, "a piston");

    // Quicksilver, roasted out of cinnabar with a jar to catch it.
    assert!(r.place(PLAYER, 180, 64, 180, "furnace", FULL));
    let furnace = furnace_at(180, 64, 180);
    r.put_in(&furnace, 1, "tiamat_default_craft:charcoal", 27 * 10);
    r.put_in(&furnace, 2, "tiamat_default_world:cinnabar", 27);
    r.put_in(&furnace, 3, "glass_jar", 27);
    assert_eq!(r.ask("t ignite 180 64 180"), "true");
    r.tick(700);
    assert_eq!(r.units_in(&furnace, 6, 8, &format!("{MOD}:quicksilver")), 27, "quicksilver");
    assert_eq!(r.units_in(&furnace, 2, 4, &format!("{MOD}:glass_jar")), 27, "and the jar kept");
    println!("tier 4 works: ok");
}

const CARD_1: u32 = 1_838_598;
const CARD_3: u32 = 1_838_594;
const GEAR: u32 = 10_560_552;
const STEEL: &str = "tiamat_default_science:steel_stock";
const COPPER: &str = "tiamat_default_science:copper_stock";

/// Every node of tiers 3 to 5, for a player who has done it all.
const TO_TIER5: &[&str] = &["science.machine_frame", "science.simple_machines", "science.gearing",
    "science.water_wheel", "science.stamp_mill", "science.trip_hammer", "science.blast_furnace",
    "science.finery_forge", "science.cast_iron", "science.cementation_steel", "science.glassworks",
    "science.wire_drawing", "science.saltpetre_works", "science.gunpowder", "science.escapement",
    "science.coke", "science.crucible_steel", "science.lathe", "science.water_frame", "science.papin_digester",
    "science.newcomen_engine", "science.lead_chamber", "science.electrostatics", "science.leyden_jar",
    "science.watt_engine", "science.high_pressure_steam", "science.steam_hammer", "science.puddling",
    "science.bessemer", "science.maudslay_lathe", "science.interchangeable_parts", "science.jacquard_cards",
    "science.difference_engine", "science.analytical_engine", "science.clockwork_automaton",
    "science.voltaic_pile", "science.electrolysis", "science.electromagnet", "science.dynamo",
    "science.electric_motor", "science.telegraph", "science.arc_lamp", "science.otis_elevator",
    "science.cinnabar_roasting", "science.daguerreotype", "science.cyanotype", "science.alhazen_optics",
    "science.telescope", "science.pendulum_clock", "science.newtonian_mechanics", "science.cavendish_balance",
    "science.lightning_rod", "science.dynamite"];

/// A carved plank wheel at `(x, y, z)` with water on two sides: 8 turns.
fn wheel_at(r: &mut Rig, x: i32, y: i32, z: i32) {
    assert!(r.place(PLAYER, x, y, z, PLANK, WHEEL));
    r.water(x + 1, y, z, 27);
    r.water(x, y - 1, z, 27);
}

/// A card in a hammer's frame chooses what the bar becomes.
fn punched_cards() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    assert!(r.place(PLAYER, 200, 64, 200, "frame", FULL));
    let frame = frame_at(200, 64, 200);
    r.put_in(&frame, 1, "trip_hammer", 27);
    r.put_in(&frame, 2, "tiamat_default_craft:iron_bar", 27);
    r.put_carved_in(&frame, 3, PLANK, 1, CARD_1);
    wheel_at(&mut r, 201, 64, 200);
    r.tick(260);
    assert_eq!(r.units_in(&frame, 6, 9, "tiamat_default_craft:iron_nails"), 27, "card 1: nails, not a plate");
    assert_eq!(r.units_in(&frame, 6, 9, "tiamat_default_craft:iron_plate"), 0);
    // Card 3: hinges. And the card is kept.
    r.put_carved_in(&frame, 3, PLANK, 1, CARD_3);
    r.put_in(&frame, 2, "tiamat_default_craft:iron_bar", 27);
    r.tick(260);
    assert_eq!(r.units_in(&frame, 6, 9, "tiamat_default_craft:iron_hinge"), 27, "card 3: a hinge");
    assert!(r.stacks_in(&frame).iter().any(|(_, _, sh)| *sh == Some(CARD_3)), "the card stays in the frame");
    println!("punched cards: ok");
}

/// Puddled iron on coke's heat; Bessemer steel in a blast, through the converter.
fn puddling_and_bessemer() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    assert!(r.place(PLAYER, 210, 64, 210, "furnace", FULL));
    let puddle = furnace_at(210, 64, 210);
    r.put_in(&puddle, 1, &format!("{MOD}:coke"), 27 * 10);
    r.put_in(&puddle, 2, &format!("{MOD}:pig_iron"), 27);
    assert_eq!(r.ask("t ignite 210 64 210"), "true");
    r.tick(1300);
    assert_eq!(r.units_in(&puddle, 6, 8, "tiamat_default_craft:iron_bar"), 54, "two bars from one pig");

    assert!(r.place(PLAYER, 220, 64, 220, "furnace", FULL));
    let bessemer = furnace_at(220, 64, 220);
    r.put_in(&bessemer, 1, &format!("{MOD}:coke"), 27 * 10);
    r.put_in(&bessemer, 2, &format!("{MOD}:pig_iron"), 27 * 3);
    r.put_in(&bessemer, 3, "converter", 27);
    r.put_in(&bessemer, 5, "blowing_engine", 27);
    wheel_at(&mut r, 221, 64, 220);
    assert_eq!(r.ask("t ignite 220 64 220"), "true");
    r.tick(1300);
    assert_eq!(r.units_in(&bessemer, 6, 8, &format!("{MOD}:steel_ingot")), 81, "three steel from three pigs");
    println!("puddling and the converter: ok");
}

/// Watt's engine gives 32 turns, which only steel carries: a steam hammer's need.
fn the_steam_hammer() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    assert!(r.place(PLAYER, 230, 64, 230, "furnace", FULL));
    let furnace = furnace_at(230, 64, 230);
    r.put_in(&furnace, 1, "tiamat_default_craft:charcoal", 27 * 20);
    r.put_in(&furnace, 5, "boiler", 27);
    assert_eq!(r.ask("t ignite 230 64 230"), "true");
    assert!(r.place(PLAYER, 231, 64, 230, "copper_stock", 134_142_975));
    assert!(r.place(PLAYER, 232, 64, 230, "frame", FULL));
    r.put_in(&frame_at(232, 64, 230), 1, "cylinder", 27);
    assert!(r.place(PLAYER, 233, 64, 230, "frame", FULL));
    let hammer = frame_at(233, 64, 230);
    r.put_in(&hammer, 1, "steam_hammer", 27);
    r.put_in(&hammer, 2, "tiamat_default_craft:iron_bar", 27);
    r.tick(40);
    assert_eq!(r.ask("t net 233 64 230"), "48/32/2", "Newcomen's 16, Watt's twice it, strong steam three times");
    r.tick(60);
    assert_eq!(r.units_in(&hammer, 6, 9, "tiamat_default_craft:iron_plate"), 27, "a plate in two seconds");
    println!("the steam hammer: ok");
}

/// A pile charges the wire; lamps light; cells fill; keys carry words.
fn the_charge_network() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    // A pile in a frame, with acid; copper wire along x; a lamp; a frame of cells; two keys.
    assert!(r.place(PLAYER, 240, 64, 240, "frame", FULL));
    let pile = frame_at(240, 64, 240);
    r.put_in(&pile, 1, "voltaic_pile", 27);
    r.put_in(&pile, 2, "oil_of_vitriol", 27 * 4);
    for x in 241..=250 {
        assert!(r.place(PLAYER, x, 64, 240, COPPER, ROD));
    }
    assert!(r.place(PLAYER, 245, 65, 240, "lamp", FULL));
    assert!(r.place(PLAYER, 251, 64, 240, "frame", FULL));
    let bank = frame_at(251, 64, 240);
    r.put_in(&bank, 2, "cell", 27);
    r.tick(80);
    let lit = r.material("lamp_lit");
    assert_eq!(r.world.blocks.lock().unwrap().get(&(245, 65, 240)).map(|b| b.0), Some(lit), "the lamp is lit");
    let cell = r.slot_of(&bank, 2).expect("the cell");
    assert!(cell.2.as_deref().is_some_and(|d| d.starts_with("e=")), "the surplus fills the cell: {cell:?}");

    // Two telegraph keys on the same wire: words go from one to the other.
    assert!(r.place(PLAYER, 246, 63, 240, "frame", FULL));
    r.put_in(&frame_at(246, 63, 240), 1, "telegraph", 27);
    assert!(r.place(PLAYER, 250, 63, 240, "frame", FULL));
    r.put_in(&frame_at(250, 63, 240), 1, "telegraph", 27);
    let other = rig::OTHER;
    r.join(other);
    r.tick(40);
    r.stand_at(246.5, 64.0, 241.5);
    {
        let mut map = r.entities.0.lock().unwrap();
        map.get_mut(&2).unwrap().transform = rig_transform(250.5, 64.0, 241.5);
    }
    r.heard(other);
    assert_eq!(r.ask("wire hello from the pile"), "Sent.");
    assert!(r.heard(other).iter().any(|l| l == "(by wire) hello from the pile"), "the far key's listener hears");
    println!("the charge network: ok");
}

fn rig_transform(x: f64, y: f64, z: f64) -> tiamat_core::ent::Transform {
    tiamat_core::ent::Transform::from_world(x, y, z)
}

/// A water wheel turns a dynamo; the wire carries its charge to a motor,
/// which turns a stamp mill on a shaft of its own.
fn dynamo_and_motor() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    // The dynamo's side: a wheel on four wet sides (16 turns) beside the dynamo's frame.
    assert!(r.place(PLAYER, 260, 64, 260, PLANK, WHEEL));
    r.water(259, 64, 260, 27);
    r.water(260, 63, 260, 27);
    r.water(260, 64, 259, 27);
    r.water(260, 65, 260, 27);
    assert!(r.place(PLAYER, 261, 64, 260, "frame", FULL));
    r.put_in(&frame_at(261, 64, 260), 1, "dynamo_armature", 27);
    // Copper to the motor, two blocks over.
    assert!(r.place(PLAYER, 262, 64, 260, COPPER, ROD));
    assert!(r.place(PLAYER, 263, 64, 260, "frame", FULL));
    r.put_in(&frame_at(263, 64, 260), 1, "motor", 27);
    // The motor's own shaft: a plank rod to the mill.
    assert!(r.place(PLAYER, 263, 65, 260, PLANK, ROD));
    assert!(r.place(PLAYER, 263, 66, 260, "frame", FULL));
    let mill = frame_at(263, 66, 260);
    r.put_in(&mill, 1, "stamps", 27);
    r.put_in(&mill, 2, "tiamat_default_world:gold_ore", 20);
    r.tick(80);
    assert_eq!(r.ask("t net 263 66 260"), "16/8/3", "the motor turns its shaft: 16, against the stamps' 8");
    r.tick(240);
    assert_eq!(r.units_in(&mill, 6, 9, &format!("{MOD}:crushed_gold")), 27, "water, to charge, to turning, to gold");
    println!("the dynamo and the motor: ok");
}

/// Two landings on a steel rail, wound by a turning drum at its foot.
fn the_safety_elevator() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    const RAIL: u32 = 1_313_285;
    const BRACKET: u32 = 79;
    for y in 64..=74 {
        assert!(r.place(PLAYER, 270, y, 270, STEEL, RAIL));
    }
    assert!(r.place(PLAYER, 271, 65, 270, STEEL, BRACKET), "the lower landing");
    assert!(r.place(PLAYER, 271, 72, 270, STEEL, BRACKET), "the upper landing");
    r.heard(PLAYER);
    r.hold(PLAYER, "crank_handle");
    r.inventory.held.lock().unwrap().remove(&PLAYER);
    assert!(r.use_at(PLAYER, 271, 65, 270));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str),
        Some("The winding drum at the foot of the rail is not turning."));
    assert!(r.place(PLAYER, 270, 63, 270, "frame", FULL));
    r.put_in(&frame_at(270, 63, 270), 1, "winding_drum", 27);
    wheel_at(&mut r, 270, 63, 271);
    r.tick(40);
    let before = insight(&mut r);
    assert!(r.use_at(PLAYER, 271, 65, 270));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Up you go."));
    assert_eq!(insight(&mut r) - before, 5);
    assert!(r.use_at(PLAYER, 271, 72, 270));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Down you go."), "from the top, back to the bottom");
    println!("the safety elevator: ok");
}

/// A photograph of a hut, and the hut built again from it, paid for.
fn camera_and_blueprint() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    for (x, y, z) in [(280, 64, 280), (281, 64, 280), (280, 65, 280), (281, 65, 281)] {
        r.put_block(x, y, z, "tiamat_default_world:stone");
    }
    r.give(PLAYER, "camera", 27);
    r.give(PLAYER, "silvered_plate", 27);
    r.hold(PLAYER, "camera");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 280, 64, 280));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("One corner. Now the other."));
    assert!(r.use_at(PLAYER, 281, 65, 281));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Caught: 4 blocks."));
    assert_eq!(r.units(PLAYER, "silvered_plate"), 0, "the plate is spent");
    let name = format!("photo_{}_1", &rig::hex(PLAYER)[..8]);
    r.hold_detailed(PLAYER, "photograph", &format!("p={name}"));
    r.put_block(290, 63, 290, "tiamat_default_world:stone");
    assert!(r.use_at(PLAYER, 290, 63, 290));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("You need 4 more of stone."), "nothing for nothing");
    r.give(PLAYER, "tiamat_default_world:stone", 27 * 4);
    assert!(r.use_at(PLAYER, 290, 63, 290));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The blueprint is building."));
    assert_eq!(r.units(PLAYER, "tiamat_default_world:stone"), 0, "paid in its blocks");
    let stone = r.material("tiamat_default_world:stone");
    assert_eq!(r.world.blocks.lock().unwrap().get(&(291, 65, 291)).map(|b| b.0), Some(stone), "built again");
    println!("the camera and the blueprint: ok");
}

/// The gravimeter finds gold; dynamite loosens even obsidian.
fn gravimeter_and_dynamite() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    r.stand_at(300.5, 64.0, 300.5);
    r.put_block(300, 52, 300, "tiamat_default_world:gold_ore");
    r.give(PLAYER, "gravimeter", 27);
    r.hold(PLAYER, "gravimeter");
    r.heard(PLAYER);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The balance tips down: gold ore, 12 blocks off."));

    r.put_block(310, 64, 310, "tiamat_default_world:obsidian");
    r.put_block(312, 64, 310, "tiamat_default_world:obsidian");
    r.give(PLAYER, "dynamite", 27);
    r.hold(PLAYER, "dynamite");
    assert!(r.use_at(PLAYER, 310, 64, 310));
    r.tick(45);
    let obsidian = r.material("tiamat_default_world:obsidian");
    let left = r.world.blocks.lock().unwrap().values().filter(|b| b.0 == obsidian && b.1 != 0).count();
    assert_eq!(left, 0, "hard rock loosened, two blocks out");
    println!("the gravimeter and dynamite: ok");
}

/// The Difference Engine at the jig, and a quarter of its parts given back.
fn relics_and_parts() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    assert!(r.place(PLAYER, 320, 64, 320, "frame", FULL));
    let jig = frame_at(320, 64, 320);
    r.put_in(&jig, 1, "assembly_jig", 27);
    r.put_carved_in(&jig, 2, STEEL, 12, GEAR);
    r.put_carved_in(&jig, 3, STEEL, 4, ROD);
    r.put_in(&jig, 4, "frame_plate", 27);
    r.put_in(&jig, 5, "tiamat_default_craft:bronze_ingot", 27 * 4);
    assert!(r.place(PLAYER, 321, 64, 320, PLANK, WHEEL));
    r.water(322, 64, 320, 27);
    r.water(321, 63, 320, 27);
    r.water(321, 64, 319, 27);
    r.water(321, 65, 320, 27);
    let before = insight(&mut r);
    r.tick(2500);
    assert_eq!(r.units_in(&jig, 6, 9, &format!("{MOD}:difference_engine")), 27, "the Difference Engine");
    let back: Vec<_> = r.stacks_in(&jig).into_iter().filter(|(_, _, sh)| sh.is_some()).collect();
    // A carving's units are its cells: a gear is 7, a rod 3.
    assert!(back.contains(&(STEEL.to_owned(), 3 * 7, Some(GEAR))), "three gears of twelve back: {back:?}");
    assert!(back.contains(&(STEEL.to_owned(), 3, Some(ROD))), "and one rod of four: {back:?}");
    assert_eq!(insight(&mut r) - before, 10, "an invention: the Difference Engine");
    println!("relics and interchangeable parts: ok");
}

/// An automaton wound up, with a card for its program: it feeds a frame.
fn the_automaton() {
    let mut r = Rig::new(Setup::default());
    scientist(&mut r, TO_TIER5);
    r.put_block(330, 63, 330, "tiamat_default_world:stone");
    r.give(PLAYER, "automaton_spring", 27);
    r.hold(PLAYER, "automaton_spring");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 330, 63, 330));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Tick, tick, tick: your automaton wakes."));
    r.give(PLAYER, "automaton_spring", 27);
    assert!(r.use_at(PLAYER, 330, 63, 330));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("You have as many automata as you can keep."));

    // Card 3 in its first slot: feed. Iron ore in its hold, a frame beside it.
    let hold = format!("{MOD}:hold:1");
    const CARD_FEED: u32 = 1_838_594;   // card_3
    r.put_carved_in(&hold, 1, PLANK, 1, CARD_FEED);
    r.put_in(&hold, 5, "tiamat_default_world:iron_ore", 27);
    assert!(r.place(PLAYER, 332, 64, 330, "frame", FULL));
    let frame = frame_at(332, 64, 330);
    r.tick(100);
    assert_eq!(r.units_in(&frame, 2, 5, "tiamat_default_world:iron_ore"), 27, "fed from its hold");
    println!("the automaton: ok");
}

/// Every node of tier 6, after the rest.
const TIER6: &[&str] = &["science.incandescent_lamp", "science.polyphase_ac", "science.transformer",
    "science.induction_motor", "science.tesla_coil", "science.radio", "science.teleautomaton",
    "science.crookes_tube", "science.x_rays", "science.radioactivity", "science.helium",
    "science.tesla_oscillator", "science.arc_furnace", "science.diamond_drill", "science.wardenclyffe",
    "science.bakelite", "science.luminiferous_aether", "science.aether_cell", "science.cavorite"];

fn tier6_scientist(r: &mut Rig) {
    let all: Vec<&str> = TO_TIER5.iter().chain(TIER6.iter()).copied().collect();
    scientist(r, &all);
}

const COIL: u32 = 119_450_567;
const RING: u32 = 1_837_575;

/// A frame with `movement` in its tool slot.
fn movement_at(r: &mut Rig, x: i32, y: i32, z: i32, movement: &str) {
    assert!(r.place(PLAYER, x, y, z, "frame", FULL));
    r.put_in(&frame_at(x, y, z), 1, movement, 27);
}

fn block_is(r: &Rig, x: i32, y: i32, z: i32, id: &str) -> bool {
    let m = r.material(id);
    r.world.blocks.lock().unwrap().get(&(x, y, z)).map(|b| b.0) == Some(m)
}

/// A radium cell gives a little charge for ever: enough for a lamp.
fn radium_and_lamps() {
    let mut r = Rig::new(Setup::default());
    tier6_scientist(&mut r);
    movement_at(&mut r, 400, 64, 400, "radium_cell");
    assert!(r.place(PLAYER, 401, 64, 400, COPPER, ROD));
    assert!(r.place(PLAYER, 402, 64, 400, "lamp", FULL));
    r.tick(60);
    assert!(block_is(&r, 402, 64, 400, &format!("{MOD}:lamp_lit")), "radium lights a lamp");
    println!("radium and lamps: ok");
}

/// A Tesla coil on an aether cell's wire: a lamp nearby lights with no wire,
/// and a cell carried near it fills.
fn the_tesla_coil() {
    let mut r = Rig::new(Setup::default());
    tier6_scientist(&mut r);
    movement_at(&mut r, 410, 64, 410, "aether_cell");
    assert!(r.place(PLAYER, 411, 64, 410, COPPER, ROD));
    movement_at(&mut r, 412, 64, 410, "tesla_coil");
    for y in 65..=67 {
        assert!(r.place(PLAYER, 412, y, 410, COPPER, COIL));
    }
    assert!(r.place(PLAYER, 412, 68, 410, STEEL, RING));
    assert!(r.place(PLAYER, 420, 64, 410, "lamp", FULL));
    r.give_detailed(PLAYER, "cell", "e=10");
    r.stand_at(413.5, 64.0, 411.5);
    r.tick(60);
    assert!(block_is(&r, 420, 64, 410, &format!("{MOD}:lamp_lit")), "a lamp eight blocks off, lit with no wire");
    let details = r.details_of(PLAYER, "cell");
    assert!(!details.contains(&Some("e=10".to_owned())), "the carried cell fills: {details:?}");

    // Without its ring it is only a frame, and the lamp goes dark.
    r.world.blocks.lock().unwrap().remove(&(412, 68, 410));
    r.tick(60);
    assert!(block_is(&r, 420, 64, 410, &format!("{MOD}:lamp")), "no ring, no coil");
    println!("the Tesla coil: ok");
}

/// Two wireless sets on charge, far apart and unwired to each other.
fn wireless() {
    let mut r = Rig::new(Setup::default());
    tier6_scientist(&mut r);
    for (x, z) in [(430, 430), (470, 470)] {
        movement_at(&mut r, x, 64, z, "aether_cell");
        assert!(r.place(PLAYER, x + 1, 64, z, COPPER, ROD));
        movement_at(&mut r, x + 2, 64, z, "radio");
    }
    let other = rig::OTHER;
    r.join(other);
    r.tick(40);
    r.stand_at(432.5, 64.0, 431.5);
    {
        let mut map = r.entities.0.lock().unwrap();
        map.get_mut(&2).unwrap().transform = rig_transform(472.5, 64.0, 471.5);
    }
    r.heard(other);
    assert_eq!(r.ask("radio hello over the air"), "Sent.");
    assert!(r.heard(other).iter().any(|l| l == "(by wireless) hello over the air"), "the far set's listener hears");
    println!("wireless: ok");
}

/// The X-ray viewer and the earthquake machine, each paid from a carried cell;
/// and the aetherometer, which needs nothing.
fn xrays_and_earthquakes() {
    let mut r = Rig::new(Setup::default());
    tier6_scientist(&mut r);
    r.open_world(7);
    r.stand_at(500.5, 64.0, 500.5);
    // Ore five blocks off along every level axis, at eye height: whichever
    // way the body faces, the viewer sees one of them.
    for (x, z) in [(505, 500), (495, 500), (500, 505), (500, 495)] {
        r.put_block(x, 65, z, "tiamat_default_world:iron_ore");
    }
    r.give(PLAYER, "xray_viewer", 27);
    r.hold(PLAYER, "xray_viewer");
    r.heard(PLAYER);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The tube is dark: carry a charged cell."));
    r.give_detailed(PLAYER, "cell", "e=100");
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Ore glows through the rock: 1 blocks of it."));
    assert!(r.details_of(PLAYER, "cell").contains(&Some("e=92".to_owned())), "eight charge spent");

    // A column of stone, three across and twelve deep, shaken loose.
    for y in 40..=63 {
        for x in 519..=521 {
            for z in 519..=521 {
                r.put_block(x, y, z, STONE);
            }
        }
    }
    r.give(PLAYER, "oscillator", 27);
    r.hold(PLAYER, "oscillator");
    assert!(r.use_at(PLAYER, 520, 63, 520));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The ground hums, and shudders: 108 blocks shaken loose."));
    assert!(block_is(&r, 520, 51, 520, STONE), "thirteen down is still rock");
    assert!(r.details_of(PLAYER, "cell").contains(&Some("e=42".to_owned())), "fifty charge spent");

    r.give(PLAYER, "aetherometer", 27);
    r.hold(PLAYER, "aetherometer");
    assert!(r.use_at_nothing(PLAYER));
    let reading = r.heard(PLAYER).last().cloned().unwrap_or_default();
    assert!(reading.starts_with("The needle trembles: the aether drifts "), "{reading}");
    println!("X-rays and earthquakes: ok");
}

/// Four aether cells feed an arc furnace: chromium and steel to chrome steel.
fn the_arc_furnace() {
    let mut r = Rig::new(Setup::default());
    tier6_scientist(&mut r);
    for x in 540..=543 {
        movement_at(&mut r, x, 64, 540, "aether_cell");
        assert!(r.place(PLAYER, x, 64, 541, COPPER, ROD));
    }
    assert!(r.place(PLAYER, 544, 64, 541, COPPER, ROD));
    movement_at(&mut r, 545, 64, 541, "arc_electrodes");
    let arc = frame_at(545, 64, 541);
    r.put_in(&arc, 2, "tiamat_default_world:chromium_ore", 27);
    r.put_in(&arc, 3, "steel_ingot", 27 * 2);
    r.tick(1400);
    assert_eq!(r.units_in(&arc, 6, 9, &format!("{MOD}:chrome_steel_ingot")), 27 * 2, "chrome steel");
    println!("the arc furnace: ok");
}

/// Wardenclyffe: a Tesla coil built tall, with a root of copper. A receiver
/// two hundred blocks away, wired to nothing but its own lamp, lights it.
fn wardenclyffe() {
    let mut r = Rig::new(Setup::default());
    tier6_scientist(&mut r);
    let (x, z) = (600, 600);
    movement_at(&mut r, x, 64, z, "tesla_coil");
    for y in 65..=67 {
        assert!(r.place(PLAYER, x, y, z, COPPER, COIL));
    }
    assert!(r.place(PLAYER, x, 68, z, STEEL, RING));
    for y in 69..=107 {
        r.put_block(x, y, z, STONE);
    }
    assert!(r.place(PLAYER, x, 108, z, COPPER, ROD));
    for y in 34..=63 {
        assert!(r.place(PLAYER, x, y, z, COPPER, ROD));
    }
    // Two aether cells on the root.
    movement_at(&mut r, x + 1, 40, z, "aether_cell");
    movement_at(&mut r, x - 1, 40, z, "aether_cell");
    // The receiver, far off.
    movement_at(&mut r, 800, 64, 800, "receiver");
    assert!(r.place(PLAYER, 801, 64, 800, COPPER, ROD));
    assert!(r.place(PLAYER, 802, 64, 800, "lamp", FULL));
    let before = insight(&mut r);
    r.tick(60);
    assert!(block_is(&r, 802, 64, 800, &format!("{MOD}:lamp_lit")), "the receiver's lamp, lit from the tower");
    assert_eq!(insight(&mut r) - before, 50 + 10, "Wardenclyffe, and the first lamp lit");

    // A gap in the column and it is no tower: air is not "anything".
    r.world.blocks.lock().unwrap().remove(&(x, 90, z));
    r.tick(60);
    assert!(block_is(&r, 802, 64, 800, &format!("{MOD}:lamp")), "a hollow tower sends nothing");
    r.put_block(x, 90, z, STONE);
    r.tick(60);
    assert!(block_is(&r, 802, 64, 800, &format!("{MOD}:lamp_lit")), "mended, it sends again");

    // Topple the crown and the tower is only a coil: the receiver goes dark.
    r.world.blocks.lock().unwrap().remove(&(x, 108, z));
    r.tick(60);
    assert!(block_is(&r, 802, 64, 800, &format!("{MOD}:lamp")), "no tower, nothing sent");
    println!("Wardenclyffe: ok");
}

/// Every node of tier 7.
const TIER7: &[&str] = &["science.gravity_plating", "science.gravity_well", "science.levitator",
    "science.gravity_engine", "science.stasis_field", "science.the_core", "science.wormhole_gates",
    "science.fold_to_stars", "science.terraforming", "science.atmosphere_processor", "science.the_deep",
    "science.strange_matter", "science.recall_beacon", "science.gravitic_drones", "science.unified_field"];

fn tier7_scientist(r: &mut Rig) {
    let all: Vec<&str> = TO_TIER5.iter().chain(TIER6.iter()).chain(TIER7.iter()).copied().collect();
    scientist(r, &all);
}

const CAVORITE: &str = "tiamat_default_science:cavorite";

/// The gravity the engine was last told for the player, through Life.
fn gravity_now() -> f32 {
    rig::ABILITIES.lock().unwrap().iter().rev().find(|(p, _)| *p == PLAYER)
        .and_then(|(_, a)| *a).map_or(1.0, |a| a.gravity)
}

fn flying_now() -> bool {
    rig::ABILITIES.lock().unwrap().iter().rev().find(|(p, _)| *p == PLAYER)
        .and_then(|(_, a)| *a).is_some_and(|a| a.fly)
}

fn near(a: f32, b: f32) -> bool {
    (a - b).abs() < 0.001
}

/// A plate under your feet, soles on them, and a harness on your back.
fn gravity() {
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    assert!(r.place(PLAYER, 700, 62, 700, CAVORITE, PLATE));
    r.move_to(PLAYER, 700, 64, 700, "overworld");
    r.tick(2);
    assert!(near(gravity_now(), 0.17), "on the plate, the Moon's: {}", gravity_now());
    r.move_to(PLAYER, 703, 64, 700, "overworld");
    r.tick(2);
    assert!(near(gravity_now(), 1.0), "off it, the world's: {}", gravity_now());

    r.wear(PLAYER, "cavorite_soles");
    r.tick(40);
    assert!(near(gravity_now(), 0.5), "soles: half: {}", gravity_now());
    r.move_to(PLAYER, 700, 64, 700, "overworld");
    r.tick(2);
    assert!(near(gravity_now(), 0.085), "soles on a plate: they multiply: {}", gravity_now());
    r.undress(PLAYER);
    r.move_to(PLAYER, 703, 64, 700, "overworld");

    r.wear(PLAYER, "levitator");
    r.tick(40);
    assert!(!flying_now(), "no cell, no flight");
    r.give_detailed(PLAYER, "cell", "e=100");
    r.tick(40);
    assert!(flying_now(), "the levitator flies on charge");
    let details = r.details_of(PLAYER, "cell");
    assert!(details.iter().any(|d| d.as_deref().is_some_and(|d| d != "e=100")), "and the cell pays: {details:?}");
    println!("gravity: ok");
}

/// Wires a frame's foot into the line under it.
fn wire_line(r: &mut Rig, xs: std::ops::RangeInclusive<i32>, y: i32, z: i32) {
    for x in xs {
        let _ = r.place(PLAYER, x, y, z, COPPER, ROD);
    }
}

/// A gravity engine and four Tesla coils, on one wire round a Core whose
/// throat is at (810, 70, 800).
fn build_core(r: &mut Rig) {
    // The wire: along z = 800 and across at x = 808 and x = 812, at y = 63.
    wire_line(r, 800..=812, 63, 800);
    for z in 798..=802 {
        let _ = r.place(PLAYER, 808, 63, z, COPPER, ROD);
        let _ = r.place(PLAYER, 812, 63, z, COPPER, ROD);
    }
    // The gravity engine: a dynamo beside a cavorite wheel, a steel rod and a wheel.
    movement_at(r, 800, 64, 800, "dynamo_armature");
    assert!(r.place(PLAYER, 801, 64, 800, CAVORITE, WHEEL));
    assert!(r.place(PLAYER, 801, 65, 800, STEEL, ROD));
    assert!(r.place(PLAYER, 801, 66, 800, CAVORITE, WHEEL));
    // Four coils at the corners.
    for (x, z) in [(808, 798), (812, 798), (808, 802), (812, 802)] {
        movement_at(r, x, 64, z, "tesla_coil");
        for y in 65..=67 {
            assert!(r.place(PLAYER, x, y, z, COPPER, COIL));
        }
        assert!(r.place(PLAYER, x, 68, z, STEEL, RING));
    }
    // The three rings, five across, round (810, 70, 800).
    for a in -2i32..=2 {
        for b in -2i32..=2 {
            if a.abs().max(b.abs()) == 2 {
                for (x, y, z) in [(810 + a, 70 + b, 800), (810, 70 + b, 800 + a), (810 + a, 70, 800 + b)] {
                    if !r.world.blocks.lock().unwrap().contains_key(&(x, y, z)) {
                        assert!(r.place(PLAYER, x, y, z, CAVORITE, RING));
                    }
                }
            }
        }
    }
}

/// The Core turned; the Fold to a star and home through the return gate;
/// and a blind fold into the Deep, its strange matter, and the fall home.
fn the_core_and_the_fold() {
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    r.open_world(11);
    build_core(&mut r);
    r.give(PLAYER, "fold_key", 27);
    r.hold(PLAYER, "fold_key");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 810, 68, 800));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str),
        Some("The rings are still. The Core wants four Tesla coils alight near it."), "not reckoned yet");
    r.tick(60);
    let before = insight(&mut r);
    assert!(r.use_at(PLAYER, 810, 68, 800));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The rings begin to turn, and the light goes out of the sky."));
    assert!(block_is(&r, 810, 70, 800, &format!("{MOD}:wormhole")), "the throat opens");
    let rings = r.entities.0.lock().unwrap().values().filter(|e| e.model.as_deref() == Some("tiamat_default_science:core_ring")).count();
    assert_eq!(rings, 3, "three rings turn");

    // Look at a star, near the Core, and use the key at the sky.
    r.stand_at(810.5, 64.0, 805.5);
    let star = r.look_at_star(40);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The rings stop dead, and the stars turn over."));
    let (_, domain, _) = rig::TRANSFERS.lock().unwrap().last().cloned().expect("a transfer");
    assert!(domain.starts_with("tiamat_default_science:body_") && domain.contains(&format!("/{star}_")), "{domain}");
    assert!(r.places.0.lock().unwrap().contains(&domain), "the body was made");
    assert_eq!(insight(&mut r) - before, 100 + 100, "the Core turned, and a world at a star");

    // On the body: its own weight, and a gate home beside where folds land.
    r.put_block(2, 30, 0, STONE);
    r.move_to(PLAYER, 0, 40, 0, &domain);
    r.tick(2);
    assert!(gravity_now() < 1.0, "a body is lighter: {}", gravity_now());
    assert!(block_is(&r, 2, 32, 0, &format!("{MOD}:wormhole")), "the return gate");
    r.move_to(PLAYER, 2, 32, 0, &domain);
    let (_, home, at) = rig::TRANSFERS.lock().unwrap().last().cloned().expect("home");
    assert_eq!(home, "overworld");
    assert_eq!(at, [810.5, 69.0, 800.5], "back at the Core");
    r.move_to(PLAYER, 810, 69, 800, "overworld");
    r.tick(2);
    assert!(near(gravity_now(), 1.0), "and your own weight again");

    // A blind fold: the key at the turning Core's ring again.
    r.tick(60);
    assert!(r.use_at(PLAYER, 810, 68, 800));
    assert!(r.use_at(PLAYER, 810, 68, 800));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The rings stop dead. This is not anywhere."));
    let (_, deep, _) = rig::TRANSFERS.lock().unwrap().last().cloned().expect("the Deep");
    assert_eq!(deep, "tiamat_default_science:deep");
    r.move_to(PLAYER, 0, 1, 0, &deep);
    r.tick(45);
    let shades = r.entities.0.lock().unwrap().values().filter(|e| e.model.as_deref() == Some("tiamat_default_science:shade")).count();
    assert_eq!(shades, 3, "the shades stand off");
    r.put_block(3, 0, 0, "tiamat_default_world:morphic_rock");
    r.give(PLAYER, "chrome_pick", 27);
    r.hold(PLAYER, "chrome_pick");
    assert!(r.dig_complete_event(PLAYER, (3, 0, 0)), "a chrome pick digs it");
    assert_eq!(r.units(PLAYER, "strange_matter"), 27, "strange matter, from the Deep's rock");
    let before = insight(&mut r);
    r.move_to(PLAYER, 0, -70, 0, &deep);
    assert_eq!(r.units(PLAYER, "strange_matter"), 0, "what you carried stays behind");
    let (_, back, _) = rig::TRANSFERS.lock().unwrap().last().cloned().expect("back");
    assert_eq!(back, "overworld");
    assert_eq!(insight(&mut r) - before, 100, "the Deep, and back");
    r.move_to(PLAYER, 810, 69, 800, "overworld");
    r.tick(2);
    let shades = r.entities.0.lock().unwrap().values().filter(|e| e.model.as_deref() == Some("tiamat_default_science:shade")).count();
    assert_eq!(shades, 0, "the shades are gone");
    println!("the Core and the Fold: ok");
}

/// Builds an upright ring of cavorite ring blocks across x, its bottom middle
/// at `(x, y, z)`.
fn gate(r: &mut Rig, x: i32, y: i32, z: i32) {
    for a in -1..=1 {
        for b in 0..=2 {
            if !(a == 0 && b == 1) {
                assert!(r.place(PLAYER, x + a, y + b, z, CAVORITE, RING));
            }
        }
    }
}

/// Two gates paired, open beside a coil; through one and out of the other;
/// the recall beacon home; the Unified Field to the far gate.
fn gates_and_recall() {
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    gate(&mut r, 900, 64, 900);
    gate(&mut r, 920, 64, 900);
    movement_at(&mut r, 910, 64, 905, "aether_cell");
    assert!(r.place(PLAYER, 911, 64, 905, COPPER, ROD));
    movement_at(&mut r, 912, 64, 905, "tesla_coil");
    for y in 65..=67 {
        assert!(r.place(PLAYER, 912, y, 905, COPPER, COIL));
    }
    assert!(r.place(PLAYER, 912, 68, 905, STEEL, RING));
    r.give(PLAYER, "fold_key", 27);
    r.hold(PLAYER, "fold_key");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 900, 64, 900));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The gate is marked. Use the key on its twin."));
    assert!(r.use_at(PLAYER, 920, 64, 900));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The two gates know each other now."));
    r.tick(60);
    assert!(block_is(&r, 900, 65, 900, &format!("{MOD}:wormhole")), "open beside a live coil");
    assert!(block_is(&r, 920, 65, 900, &format!("{MOD}:wormhole")), "both");
    let before = insight(&mut r);
    r.move_to(PLAYER, 900, 65, 900, "overworld");
    assert_eq!(rig::MOVES.lock().unwrap().last().map(|m| m.1), Some([920.5, 65.0, 901.5]), "out of the twin");
    assert_eq!(insight(&mut r) - before, 50, "through a wormhole");

    // The recall beacon: to the nearest of your own gates.
    r.give(PLAYER, "recall_beacon", 27);
    r.hold(PLAYER, "recall_beacon");
    r.stand_at(930.5, 64.0, 950.5);
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("A pocket fold, and you are home."));
    assert_eq!(rig::MOVES.lock().unwrap().last().map(|m| m.1), Some([920.5, 65.0, 901.5]), "the nearer gate");
    assert!(r.use_at_nothing(PLAYER));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The beacon is still gathering itself."));

    // The Unified Field: a list of places, and 256 charge to go.
    r.give(PLAYER, "unified_field_engine", 27);
    r.hold(PLAYER, "unified_field_engine");
    assert!(r.use_at_nothing(PLAYER));
    let (form, tree) = r.last_dialog().expect("the field's places");
    assert!(form.ends_with(":unified") && tree.contains("Gate at 900, 65, 900"), "{form} {tree}");
    r.press(PLAYER, MOD, "unified", "go:1");
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The engine needs a charged cell: 256 charge."));
    r.give_detailed(PLAYER, "cell", "e=1000");
    assert!(r.use_at_nothing(PLAYER));
    r.press(PLAYER, MOD, "unified", "go:1");
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("The field folds, and you are there."));
    assert!(r.details_of(PLAYER, "cell").contains(&Some("e=744".to_owned())), "256 charge spent");
    println!("gates and recall: ok");
}

/// The diamond drill will not start on a flat cell, and pays a charge a block.
fn the_diamond_drill() {
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    r.put_block(950, 64, 950, STONE);
    r.give(PLAYER, "diamond_drill", 27);
    r.hold(PLAYER, "diamond_drill");
    let (allowed, why) = r.dig_start_event(PLAYER, (950, 64, 950));
    assert!(!allowed && why.as_deref() == Some("The drill's cell is flat."), "{allowed} {why:?}");
    r.give_detailed(PLAYER, "cell", "e=10");
    let (allowed, _) = r.dig_start_event(PLAYER, (950, 64, 950));
    assert!(allowed, "a charged cell, and it starts");
    assert!(r.dig_complete_event(PLAYER, (950, 64, 950)), "the drill digs stone");
    let cells = r.details_of(PLAYER, "cell");
    assert!(cells.contains(&Some("e=9".to_owned())), "a charge a block: {cells:?}");
    println!("the diamond drill: ok");
}

/// An automaton wound by one who knows gravitic automata flies.
fn gravitic_drones() {
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    r.put_block(960, 63, 960, STONE);
    r.give(PLAYER, "automaton_spring", 27);
    r.hold(PLAYER, "automaton_spring");
    r.heard(PLAYER);
    assert!(r.use_at(PLAYER, 960, 63, 960));
    assert_eq!(r.heard(PLAYER).last().map(String::as_str), Some("Tick, tick, tick: your automaton wakes, and rises."));
    let drone = r.entities.0.lock().unwrap().values().find(|e| matches!(&e.nametag, Some(tiamat_core::ent::Nametag::Text(t)) if t == "Automaton 1")).cloned()
        .expect("the drone");
    assert!(drone.collider.is_none(), "no body to fall with");
    println!("gravitic drones: ok");
}

/// An attractor draws Life's dropped stacks in; a stasis field stops this
/// mod's automata where they stand.
fn wells_and_stasis() {
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    movement_at(&mut r, 1000, 64, 1000, "aether_cell");
    movement_at(&mut r, 1000, 64, 1002, "aether_cell");
    for z in 1000..=1002 {
        let _ = r.place(PLAYER, 1001, 64, z, COPPER, ROD);
    }
    movement_at(&mut r, 1002, 64, 1001, "attractor");
    assert_ne!(r.ask("t drop 1006 64 1001"), "nil", "Life drops a stone");
    let before = insight(&mut r);
    r.tick(60);
    assert_eq!(insight(&mut r) - before, 10, "the attractor draws it: a gravity well");

    movement_at(&mut r, 1000, 64, 1010, "aether_cell");
    assert!(r.place(PLAYER, 1001, 64, 1010, COPPER, ROD));
    movement_at(&mut r, 1002, 64, 1010, "stasis");
    r.put_block(1004, 63, 1010, STONE);
    r.give(PLAYER, "automaton_spring", 27);
    r.hold(PLAYER, "automaton_spring");
    assert!(r.use_at(PLAYER, 1004, 63, 1010));
    let before = insight(&mut r);
    r.tick(60);
    assert_eq!(insight(&mut r) - before, 10, "the field holds the automaton: stasis");
    println!("wells and stasis: ok");
}

/// A terraformer on a body greens it a column at a time; a body green
/// enough lives, and an atmosphere processor gives it a sky.
fn terraforming() {
    use tiamat_core::storage::{Access as _, Value};
    let mut r = Rig::new(Setup::default());
    tier7_scientist(&mut r);
    r.open_world(11);
    let body = format!("{MOD}:body_rust/40_1");
    r.places.0.lock().unwrap().push(body.clone());
    // Stand on the body: what is placed now is placed there.
    r.move_to(PLAYER, 1100, 31, 1100, &body);
    for x in 1092..=1107 {
        for z in 1092..=1107 {
            r.put_block(x, 30, z, "tiamat_default_world:rust_red_sandstone");
        }
    }
    // Craft names a station placed here without its domain until it answers
    // C-S8 (engine ask E-S4), so the boxes are made as it will name them.
    let on_body = |x: i32, y: i32, z: i32| format!("tiamat_default_craft:{MOD}:frame:{body}@{x},{y},{z}");
    // And as Craft's own `ensure` would, with who placed it.
    let made = |r: &Rig, name: &str| {
        tiamat_core::inventory::Containers::ensure(&*r.boxes, name, 9);
        r.storage.set("tiamat_default_craft", &format!("placer:{name}"), Some(Value::Text(rig::hex(PLAYER))));
    };
    for (x, z, movement) in [(1102, 1100, "dynamo_armature"), (1100, 1100, "terraformer")] {
        assert!(r.place(PLAYER, x, 31, z, "frame", FULL));
        made(&r, &on_body(x, 31, z));
        r.put_in(&on_body(x, 31, z), 1, movement, 27);
    }
    assert!(r.place(PLAYER, 1103, 31, 1100, CAVORITE, WHEEL));
    assert!(r.place(PLAYER, 1103, 32, 1100, STEEL, ROD));
    assert!(r.place(PLAYER, 1103, 33, 1100, CAVORITE, WHEEL));
    assert!(r.place(PLAYER, 1101, 31, 1100, COPPER, ROD));
    r.tick(220);
    let grass = r.material("tiamat_default_world:grass");
    let green = r.world.blocks.lock().unwrap().iter().filter(|(k, b)| k.1 == 30 && b.0 == grass).count();
    assert!(green >= 15, "a column every ten ticks: {green}");
    assert!(block_is(&r, 1092, 29, 1092, "tiamat_default_world:dirt"), "earth under the grass");

    // Nearly living: the last columns tip it.
    r.storage.set(MOD, &format!("green:{body}"), Some(Value::Number(2456.0)));
    let before = insight(&mut r);
    r.tick(20);
    assert_eq!(insight(&mut r) - before, 500, "a barren world, living");
    r.move_to(PLAYER, 1096, 31, 1096, &body);
    assert!(r.place(PLAYER, 1101, 31, 1101, COPPER, ROD));
    assert!(r.place(PLAYER, 1100, 31, 1101, "frame", FULL));
    made(&r, &on_body(1100, 31, 1101));
    r.put_in(&on_body(1100, 31, 1101), 1, "atmosphere_processor", 27);
    let before = insight(&mut r);
    r.tick(60);
    assert_eq!(insight(&mut r) - before, 100, "and a sky remade");
    assert_eq!(r.stored(&format!("sky:{body}")).as_deref(), Some("Flag(true)"), "once, kept with the world");
    println!("terraforming: ok");
}

/// The solid blocks in one generated chunk of `domain`.
fn solid_in(r: &mut Rig, domain: &str, (x, y, z): (i32, i32, i32)) -> usize {
    use tiamat_core::{block::BlockView, script::ScriptVm, MaterialId};
    let (chunk, _) = r.vm.generate_chunk(domain, r.seed, tiamat_core::ChunkPos::new(x, y, z), MaterialId::AIR)
        .unwrap_or_else(|e| panic!("{domain} would not generate: {e:?}"));
    chunk.blocks().filter(|(_, b)| !matches!(&b, BlockView::Uniform(m) if *m == MaterialId::AIR)).count()
}

/// The generators run: a body has ground round its middle and nothing past
/// its edge; the Deep has the fragment folds arrive on.
fn worlds_generated() {
    let mut r = Rig::new(Setup::default());
    ready(&mut r, 0);
    r.open_world(11);
    for kind in ["ice", "rust", "regolith", "basalt", "glass"] {
        let body = format!("{MOD}:body_{kind}/40_1");
        let ground: usize = (0..=2).map(|y| solid_in(&mut r, &body, (0, y, 0))).sum();
        assert!(ground > 0, "{kind}: ground at the middle");
        assert!(ground < 3 * 4096, "{kind}: and sky over it");
        assert_eq!(solid_in(&mut r, &body, (100, 1, 0)), 0, "{kind}: nothing past the edge (1,000 blocks)");
    }
    assert!(solid_in(&mut r, &format!("{MOD}:body_rust/40_3"), (100, 1, 0)) > 0, "a larger body reaches further");
    let deep = format!("{MOD}:deep");
    assert!(solid_in(&mut r, &deep, (0, -1, 0)) > 0, "the Deep's fragment, where folds arrive");
    assert_eq!(solid_in(&mut r, &deep, (0, 5, 0)), 0, "and nothing far above it");
    println!("worlds generated: ok");
}

/// Two runs of the same play leave the same storage behind.
fn determinism() {
    let run = || {
        let mut r = Rig::new(Setup::default());
        ready(&mut r, 0);
        r.give(PLAYER, "compass", 27);
        r.hold(PLAYER, "compass");
        assert!(r.place(PLAYER, 40, 64, 100, STONE, CAIRN));
        assert!(r.use_at_nothing(PLAYER));
        r.hold(PLAYER, "kite");
        r.give(PLAYER, "kite", 27);
        r.tick(20);
        r.storage.dump()
    };
    assert_eq!(run(), run());
    println!("determinism: ok");
}
