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
    assert_eq!(r.ask("t count"), "22", "Progress validated what ships: tier 3");
    // A node that says no `reveal` of its own takes the path's, "near".
    assert_eq!(r.ask("t branch science.water_wheel"), "MECH/nil", "a branch, and the path's reveal");
    let answer = r.ask("t learn science.machine_frame");
    assert!(answer.starts_with("nil") && answer.contains("lies beyond the Fork"), "{answer}");
    assert!(r.ask("t learn science.telescope").starts_with("nil"), "tier 4 is data, not for sale yet");
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
