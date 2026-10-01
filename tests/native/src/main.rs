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
    assert_eq!(r.ask("t count"), "43", "Progress validated what ships: tiers 3 and 4");
    // A node that says no `reveal` of its own takes the path's, "near".
    assert_eq!(r.ask("t branch science.water_wheel"), "MECH/nil", "a branch, and the path's reveal");
    let answer = r.ask("t learn science.machine_frame");
    assert!(answer.starts_with("nil") && answer.contains("lies beyond the Fork"), "{answer}");
    assert!(r.ask("t learn science.watt_engine").starts_with("nil"), "tier 5 is data, not for sale yet");
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
    assert_eq!(r.ask("t ours"), "90", "4 on the Bench, 49 in tier 3, 31 in tier 4, 6 studies");
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
