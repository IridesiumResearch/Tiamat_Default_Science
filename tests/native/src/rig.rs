// SPDX-FileCopyrightText: Iridesium
// SPDX-License-Identifier: GPL-3.0-only
//
// The fake server the mod runs in. Vendored from Tiamat Default Magic's rig
// (itself from Progress's), whose fakes of the engine it keeps as they were;
// what differs is at the bottom — the mods around this one are the real
// siblings, not stand-ins — and the few helpers the Bench's instruments need:
// carved blocks, placements, the hour, the sky's light and where the body
// stands.
//
// Nothing is mocked at the Lua level: the mod's own files load through
// `EngineVm::load_mod`, and its hooks fire through the same trait the server
// calls. What is faked is the world around it — a player body, an inventory,
// the world's containers, the tool in each hand, storage, a map of blocks and
// fluid, each player's chat — and each fake keeps the engine's rules where the
// mod leans on them: a container slot holds one stack, capped at ninety
// items; a take matches material, cut and detail exactly; a tool nobody
// registered is refused.

use std::{
    collections::{BTreeMap, HashMap},
    path::PathBuf,
    sync::{Arc, Mutex},
};

use tiamat_core::{
    BlockPos, MaterialId,
    ent::{self, Entity, EntityId, Owner, Transform},
    fluid::{self, Fluid, FluidId},
    hud::{self, Values},
    identity::PlayerUuid,
    inventory::{self, Shape, Stack, StackKey, stack_capacity},
    light::{Light, LightSource},
    particle::{self, BadgeRequest, EmitRequest},
    proto,
    phys::Abilities,
    modload::WorldOptionValue,

    script::{
        ActionEvent, ChatEvent, DialogEvent, EngineVm, JoinEvent, LeaveEvent, PlaceEvent, ScriptVm, UseAim, UseEvent,
        VmLimits,
        WorldEdit,
    },
    sight::{self, Looked, Reading, Sighting, Skip, Surface},
    sound::{self, LoopRequest, PlayRequest},
    storage,
    ui::host::{self as uihost, ShowRequest},
};

pub const MOD: &str = "tiamat_default_science";
pub const PLAYER: [u8; 32] = [7; 32];
pub const OTHER: [u8; 32] = [9; 32];

pub fn hex(player: [u8; 32]) -> String {
    player.iter().map(|b| format!("{b:02x}")).collect()
}

// --- Storage -------------------------------------------------------------------

#[derive(Default)]
pub struct Storage(pub Mutex<BTreeMap<(String, String), storage::Value>>);

impl storage::Access for Storage {
    fn get(&self, mod_id: &str, key: &str) -> Option<storage::Value> {
        self.0.lock().unwrap().get(&(mod_id.into(), key.into())).cloned()
    }
    fn set(&self, mod_id: &str, key: &str, value: Option<storage::Value>) {
        let mut map = self.0.lock().unwrap();
        match value {
            Some(v) => {
                map.insert((mod_id.into(), key.into()), v);
            }
            None => {
                map.remove(&(mod_id.into(), key.into()));
            }
        }
    }
    fn keys(&self, mod_id: &str, prefix: &str) -> Vec<String> {
        self.0
            .lock()
            .unwrap()
            .keys()
            .filter(|(m, k)| m == mod_id && k.starts_with(prefix))
            .map(|(_, k)| k.clone())
            .collect()
    }
}

impl Storage {
    /// This mod's storage as one sorted string, for comparing two runs.
    pub fn dump(&self) -> String {
        self.0
            .lock()
            .unwrap()
            .iter()
            .filter(|((m, _), _)| m == MOD)
            .map(|((_, k), v)| format!("{k}={v:?}"))
            .collect::<Vec<_>>()
            .join("\n")
    }
}

// --- Inventory -------------------------------------------------------------------

/// Each player's views, consolidated per material, cut and detail as the
/// engine reports them; and which stack is in the hand.
#[derive(Default)]
pub struct Inventory {
    pub views: Mutex<HashMap<([u8; 32], String), Vec<Stack>>>,
    pub held: Mutex<HashMap<[u8; 32], (MaterialId, Option<String>)>>,
}

fn same(a: &Stack, material: MaterialId, shape: Option<Shape>, detail: Option<&str>) -> bool {
    a.material == material && a.shape == shape && a.detail.as_deref() == detail
}

impl Inventory {
    pub fn units_of(&self, player: [u8; 32], material: MaterialId) -> u32 {
        self.views
            .lock()
            .unwrap()
            .get(&(player, "player:main".into()))
            .map(|v| v.iter().filter(|s| s.material == material).map(|s| s.units).sum())
            .unwrap_or(0)
    }
    pub fn stacks(&self, player: [u8; 32]) -> Vec<Stack> {
        self.views.lock().unwrap().get(&(player, "player:main".into())).cloned().unwrap_or_default()
    }
    pub fn put(&self, player: [u8; 32], stack: Stack) {
        inventory::Access::give(self, player, "player:main", None, stack);
    }
    pub fn clear(&self, player: [u8; 32]) {
        self.views.lock().unwrap().remove(&(player, "player:main".into()));
        self.held.lock().unwrap().remove(&player);
    }
}

impl inventory::Access for Inventory {
    fn contents(&self, player: [u8; 32], view: &str) -> Vec<Stack> {
        self.views.lock().unwrap().get(&(player, view.to_owned())).cloned().unwrap_or_default()
    }
    /// The view is kept consolidated, so a named slot lands where any give
    /// would: nothing here reads slot positions in a player's view.
    /// Answers the units that did not go in: none, since the view grows.
    fn give(&self, player: [u8; 32], view: &str, _slot: Option<usize>, stack: Stack) -> u32 {
        let mut views = self.views.lock().unwrap();
        let list = views.entry((player, view.to_owned())).or_default();
        if let Some(existing) = list.iter_mut().find(|s| same(s, stack.material, stack.shape, stack.detail.as_deref())) {
            existing.units += stack.units;
        } else {
            list.push(stack);
        }
        0
    }
    /// Slot positions are not kept, and nothing here reads one.
    fn slot(&self, _: [u8; 32], _: &str, _: usize) -> Option<Stack> {
        None
    }
    fn held(&self, player: [u8; 32]) -> Option<Stack> {
        let (material, detail) = self.held.lock().unwrap().get(&player).cloned()?;
        self.views
            .lock()
            .unwrap()
            .get(&(player, "player:main".into()))?
            .iter()
            .find(|s| s.material == material && s.detail == detail)
            .cloned()
    }
    fn take(&self, player: [u8; 32], view: &str, _slot: Option<usize>, which: StackKey<'_>, units: u32) -> u32 {
        let mut views = self.views.lock().unwrap();
        let Some(list) = views.get_mut(&(player, view.to_owned())) else { return 0 };
        let mut got = 0;
        for stack in list.iter_mut() {
            if stack.key() == which {
                let take = units.saturating_sub(got).min(stack.units);
                stack.units -= take;
                got += take;
            }
        }
        list.retain(|s| s.units > 0);
        got
    }
}

// --- Containers -------------------------------------------------------------------

#[derive(Default)]
pub struct Boxes {
    pub slots: Mutex<BTreeMap<String, Vec<Option<Stack>>>>,
    pub holders: Mutex<HashMap<String, [u8; 32]>>,
}

impl Boxes {
    /// Puts a stack straight into a slot (one-based), replacing what was there.
    pub fn set(&self, name: &str, slot: usize, stack: Option<Stack>) {
        let mut all = self.slots.lock().unwrap();
        let list = all.get_mut(name).unwrap_or_else(|| panic!("no container {name}"));
        list[slot - 1] = stack;
    }
    pub fn get(&self, name: &str, slot: usize) -> Option<Stack> {
        self.slots.lock().unwrap().get(name).and_then(|l| l.get(slot - 1).cloned().flatten())
    }
    pub fn exists(&self, name: &str) -> bool {
        self.slots.lock().unwrap().contains_key(name)
    }
}

impl inventory::Containers for Boxes {
    fn ensure(&self, name: &str, slots: usize) -> bool {
        let mut all = self.slots.lock().unwrap();
        if all.contains_key(name) {
            return false;
        }
        all.insert(name.to_owned(), vec![None; slots]);
        true
    }
    fn open(&self, name: &str, player: [u8; 32]) -> bool {
        if !self.exists(name) {
            return false;
        }
        let mut holders = self.holders.lock().unwrap();
        match holders.get(name) {
            Some(p) if *p != player => false,
            _ => {
                holders.insert(name.to_owned(), player);
                true
            }
        }
    }
    fn close(&self, name: &str, player: [u8; 32]) -> bool {
        let mut holders = self.holders.lock().unwrap();
        if holders.get(name) == Some(&player) {
            holders.remove(name);
            return true;
        }
        false
    }
    fn slots(&self, name: &str) -> Vec<Option<Stack>> {
        self.slots.lock().unwrap().get(name).cloned().unwrap_or_default()
    }
    fn give(&self, name: &str, slot: Option<usize>, stack: Stack) -> u32 {
        let mut all = self.slots.lock().unwrap();
        let Some(list) = all.get_mut(name) else { return 0 };
        let cap = stack_capacity(stack.shape);
        let mut left = stack.units;
        let indices: Vec<usize> = match slot {
            // Zero-based here: the engine has already taken one off the
            // mod's one-based slot.
            Some(s) if s < list.len() => vec![s],
            Some(_) => return 0,
            // Onto matching stacks first, then into empty slots, in slot order.
            None => {
                let mut matching: Vec<usize> = (0..list.len())
                    .filter(|i| list[*i].as_ref().is_some_and(|s| same(s, stack.material, stack.shape, stack.detail.as_deref())))
                    .collect();
                matching.extend((0..list.len()).filter(|i| list[*i].is_none()));
                matching
            }
        };
        for i in indices {
            if left == 0 {
                break;
            }
            match &mut list[i] {
                Some(existing) if same(existing, stack.material, stack.shape, stack.detail.as_deref()) => {
                    let room = cap.saturating_sub(existing.units).min(left);
                    existing.units += room;
                    left -= room;
                }
                Some(_) => {}
                empty @ None => {
                    let put = cap.min(left);
                    *empty = Some(Stack { units: put, ..stack.clone() });
                    left -= put;
                }
            }
        }
        stack.units - left
    }
    fn take(&self, name: &str, slot: Option<usize>, which: StackKey<'_>, units: u32) -> u32 {
        let mut all = self.slots.lock().unwrap();
        let Some(list) = all.get_mut(name) else { return 0 };
        let indices: Vec<usize> = match slot {
            // Zero-based here: the engine has already taken one off the
            // mod's one-based slot.
            Some(s) if s < list.len() => vec![s],
            Some(_) => return 0,
            None => (0..list.len()).collect(),
        };
        let mut got = 0;
        for i in indices {
            if let Some(stack) = &mut list[i]
                && stack.key() == which
            {
                let take = units.saturating_sub(got).min(stack.units);
                stack.units -= take;
                got += take;
                if stack.units == 0 {
                    list[i] = None;
                }
            }
        }
        got
    }
    fn remove(&self, name: &str) -> Vec<Stack> {
        if self.holders.lock().unwrap().contains_key(name) {
            return Vec::new();
        }
        self.slots.lock().unwrap().remove(name).unwrap_or_default().into_iter().flatten().collect()
    }
    fn holder(&self, name: &str) -> Option<[u8; 32]> {
        self.holders.lock().unwrap().get(name).copied()
    }
    fn names(&self, prefix: &str) -> Vec<String> {
        self.slots.lock().unwrap().keys().filter(|n| n.starts_with(prefix)).cloned().collect()
    }
}

// --- Tools -------------------------------------------------------------------

/// The tool in each player's hand, and every `set_tool` call, so a test can
/// count them: the engine cancels a dig on every call, so the mod must not
/// make one it does not need.
#[derive(Default)]
pub struct Tools {
    pub hand: Mutex<HashMap<[u8; 32], Option<String>>>,
    pub calls: Mutex<Vec<String>>,
    pub known: Mutex<Vec<String>>,
}

impl tiamat_core::dig::Tools for Tools {
    fn tool(&self, player: [u8; 32]) -> Option<String> {
        self.hand.lock().unwrap().get(&player).cloned().flatten()
    }
    fn set_tool(&self, player: [u8; 32], tool: Option<&str>) -> bool {
        if let Some(t) = tool
            && !self.known.lock().unwrap().iter().any(|k| k == t)
        {
            return false;
        }
        self.calls.lock().unwrap().push(tool.unwrap_or("-").to_owned());
        self.hand.lock().unwrap().insert(player, tool.map(str::to_owned));
        true
    }
}

// --- HUD, chat and operators ------------------------------------------------------

#[derive(Default)]
pub struct Huds {
    pub values: Mutex<HashMap<[u8; 32], Values>>,
    pub operators: Mutex<Vec<[u8; 32]>>,
    pub chat: Mutex<Vec<([u8; 32], String)>>,
}

impl hud::Access for Huds {
    fn set_hud(&self, mod_id: &str, player: [u8; 32], values: Values) -> bool {
        if mod_id == MOD {
            self.values.lock().unwrap().insert(player, values);
        }
        true
    }
    fn is_operator(&self, player: [u8; 32]) -> bool {
        self.operators.lock().unwrap().contains(&player)
    }
    fn chat_to(&self, player: [u8; 32], text: &str) -> bool {
        self.chat.lock().unwrap().push((player, text.to_owned()));
        true
    }
}

// --- Dialogs, sounds, particles -----------------------------------------------------

#[derive(Default)]
pub struct Dialogs {
    pub shown: Mutex<Vec<ShowRequest>>,
    pub closed: Mutex<Vec<(String, String)>>,
}

impl uihost::Access for Dialogs {
    fn show(&self, request: &ShowRequest) -> bool {
        tiamat_core::ui::check(&request.tree, tiamat_core::ui::Limits::default())
            .expect("every tree the mod sends passes the engine's checker");
        self.shown.lock().unwrap().push(request.clone());
        true
    }
    fn close(&self, player: &str, form: &str) -> bool {
        self.closed.lock().unwrap().push((player.to_owned(), form.to_owned()));
        true
    }
}

#[derive(Default)]
pub struct Sounds {
    pub plays: Mutex<Vec<String>>,
    pub time: Mutex<f32>,
}

impl sound::Access for Sounds {
    fn play(&self, request: &PlayRequest) -> u32 {
        self.plays.lock().unwrap().push(request.sound.clone());
        1
    }
    fn start_loop(&self, _: &LoopRequest) -> u32 {
        1
    }
    fn time_of_day(&self) -> f32 {
        *self.time.lock().unwrap()
    }
    fn stop_loop(&self, _: &sound::StopRequest) -> u32 {
        0
    }
    fn set_time_of_day(&self, fraction: f32) -> bool {
        *self.time.lock().unwrap() = fraction.rem_euclid(1.0);
        true
    }
}

#[derive(Default)]
pub struct Particles(pub Mutex<Vec<EmitRequest>>);

impl particle::Access for Particles {
    fn emit(&self, request: &EmitRequest) -> u32 {
        self.0.lock().unwrap().push(request.clone());
        1
    }
    fn show_over(&self, _: &BadgeRequest) -> u32 {
        1
    }
}

// --- The world -----------------------------------------------------------------

#[derive(Default)]
pub struct World {
    pub blocks: Mutex<HashMap<(i32, i32, i32), (MaterialId, u32)>>,
    pub fluids: Mutex<HashMap<(i32, i32, i32), u32>>,
    pub edits: Mutex<Vec<(BlockPos, String)>>,
    pub aimed: Mutex<Option<(i32, i32, i32)>>,
    pub names: Mutex<HashMap<String, MaterialId>>,
    /// Under a roof: no sky light anywhere.
    pub roofed: Mutex<bool>,
}

impl World {
    pub fn put(&self, x: i32, y: i32, z: i32, material: MaterialId) {
        self.blocks.lock().unwrap().insert((x, y, z), (material, 0x7FF_FFFF));
    }
    /// A block carved to `occupancy`, the cells `x + 3y + 9z` it keeps.
    pub fn put_carved(&self, x: i32, y: i32, z: i32, material: MaterialId, occupancy: u32) {
        self.blocks.lock().unwrap().insert((x, y, z), (material, occupancy));
    }
    pub fn apply(&self, pos: BlockPos, block: &str) {
        self.edits.lock().unwrap().push((pos, block.to_owned()));
        let key = (pos.x, pos.y, pos.z);
        if block == "engine:air" {
            self.blocks.lock().unwrap().insert(key, (MaterialId(0), 0));
        } else if let Some(material) = self.names.lock().unwrap().get(block) {
            self.blocks.lock().unwrap().insert(key, (*material, 0x7FF_FFFF));
        } else {
            panic!("the mod wrote a block nobody registered: {block}");
        }
    }
}

impl sight::Access for World {
    fn line_of_sight(&self, _: &str, _: [f64; 3], _: [f64; 3]) -> Sighting {
        Sighting::Clear
    }
    fn looking_at(&self, uuid: [u8; 32]) -> Option<Looked> {
        let (x, y, z) = (*self.aimed.lock().unwrap())?;
        if uuid != PLAYER {
            return None;
        }
        let Reading::Single { material, occupancy } = self.block_at("", BlockPos { x, y, z }) else { return None };
        (occupancy != 0).then(|| Looked::Block {
            domain: "overworld".into(),
            cell: tiamat_core::SubNodePos { x: x * 3 + 1, y: y * 3 + 2, z: z * 3 + 1 },
            material,
            face: [0, 1, 0],
        })
    }
    fn surface_at(&self, domain: &str, column: [i32; 2], from: i32, depth: u32, _: Skip) -> Option<Surface> {
        for y in (from - depth as i32..=from).rev() {
            if let Reading::Single { material, occupancy } = self.block_at(domain, BlockPos { x: column[0], y, z: column[1] })
                && occupancy != 0
            {
                return Some(Surface { y, material, occupancy, fluid: None });
            }
        }
        None
    }
    fn block_at(&self, _: &str, pos: BlockPos) -> Reading {
        match self.blocks.lock().unwrap().get(&(pos.x, pos.y, pos.z)) {
            Some((material, occupancy)) => Reading::Single { material: *material, occupancy: *occupancy },
            None => Reading::Single { material: MaterialId(0), occupancy: 0 },
        }
    }
}

impl fluid::Access for World {
    fn fluid_at(&self, _: &str, pos: BlockPos) -> Fluid {
        match self.fluids.lock().unwrap().get(&(pos.x, pos.y, pos.z)) {
            Some(volume) => Fluid::new(FluidId(1), *volume),
            None => Fluid::EMPTY,
        }
    }
    fn set_fluid_at(&self, _: &str, pos: BlockPos, fluid: Fluid) -> bool {
        let mut fluids = self.fluids.lock().unwrap();
        if fluid.volume() == 0 {
            fluids.remove(&(pos.x, pos.y, pos.z));
        } else {
            fluids.insert((pos.x, pos.y, pos.z), fluid.volume());
        }
        true
    }
    /// The world's water is fluid 1 and Weather's rainwater fluid 2: the two
    /// the siblings name. Volumes are kept, kinds are not.
    fn fluid_id(&self, name: &str) -> Option<FluidId> {
        match name {
            "tiamat_default_world:water" => Some(FluidId(1)),
            "tiamat_weather:rainwater" => Some(FluidId(2)),
            _ => None,
        }
    }
}

impl LightSource for World {
    fn light_at(&self, _: &str, _: BlockPos) -> Light {
        if *self.roofed.lock().unwrap() { Light::DARK } else { Light::DAYLIGHT }
    }
}

impl WorldEdit for World {
    fn set_block(&self, _: &str, pos: BlockPos, block: &str) -> bool {
        self.apply(pos, block);
        true
    }
    fn set_partial(&self, _: &str, pos: BlockPos, block: &str, _: u32) -> bool {
        self.apply(pos, block);
        true
    }
    fn merge_partial(&self, _: &str, pos: BlockPos, block: &str, _: u32) -> bool {
        self.apply(pos, block);
        true
    }
}

// --- Entities: the player's body --------------------------------------------------

#[derive(Clone)]
pub struct Entities(pub Arc<Mutex<HashMap<u64, Entity>>>);

impl Entities {
    fn new() -> Self {
        let mut map = HashMap::new();
        for (id, who) in [(1, PLAYER), (2, OTHER)] {
            let mut body = Entity::at(Transform::from_world(100.5, 64.0, 100.5), "engine:player");
            body.owner = Some(Owner(PlayerUuid::from_bytes(who)));
            body.on_ground = true;
            map.insert(id, body);
        }
        Self(Arc::new(Mutex::new(map)))
    }
}

impl ent::Access for Entities {
    fn spawn(&self, entity: Entity) -> Option<EntityId> {
        let mut map = self.0.lock().unwrap();
        let id = map.keys().max().copied().unwrap_or(0) + 1;
        map.insert(id, entity);
        Some(EntityId(id))
    }
    fn despawn(&self, id: EntityId) -> bool {
        self.0.lock().unwrap().remove(&id.0).is_some()
    }
    fn get(&self, id: EntityId) -> Option<Entity> {
        self.0.lock().unwrap().get(&id.0).cloned()
    }
    fn patch(&self, id: EntityId, patch: &ent::Patch) -> bool {
        match self.0.lock().unwrap().get_mut(&id.0) {
            Some(entity) => patch.apply(entity),
            None => false,
        }
    }
    fn player(&self, uuid: [u8; 32]) -> Option<EntityId> {
        match uuid {
            PLAYER => Some(EntityId(1)),
            OTHER => Some(EntityId(2)),
            _ => None,
        }
    }
    fn within(&self, centre: [f64; 3], radius: f64, _: Option<&str>) -> Vec<EntityId> {
        let mut near: Vec<(u64, f64)> = self
            .0
            .lock()
            .unwrap()
            .iter()
            .map(|(id, e)| {
                let p = e.transform.to_world();
                let d = (0..3).map(|i| (p[i] - centre[i]) * (p[i] - centre[i])).sum::<f64>();
                (*id, d)
            })
            .filter(|(_, d)| *d <= radius * radius)
            .collect();
        near.sort_by(|a, b| a.1.total_cmp(&b.1).then(a.0.cmp(&b.0)));
        near.into_iter().map(|(id, _)| EntityId(id)).collect()
    }
    fn move_player(&self, _: [u8; 32], _: [f64; 3]) -> bool {
        true
    }
    fn select_slot(&self, _: [u8; 32], _: u16) -> bool {
        true
    }
    fn shove_player(&self, _: [u8; 32], _: [f32; 3]) -> bool {
        true
    }
    fn transfer(&self, _: EntityId, _: &str, _: [f64; 3]) -> bool {
        false
    }
    fn set_abilities(&self, _: [u8; 32], _: Option<Abilities>) -> bool {
        true
    }
}

// --- The mods around this one ------------------------------------------------------
//
// The REAL siblings, from their repositories beside this one: a stand-in
// would test this mod against what somebody guessed Craft does, and the
// Bench leans on exactly how Craft's campfire and Progress's gate behave.
// Each is loaded in the order the engine would load it.

/// Where the sibling repositories are, relative to this crate.
fn sibling_dir(repo: &str, id: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..").join(repo).join("mods").join(id)
}

/// `(mod id, repository)`, in load order. The interface and the weather are
/// optional to this mod, and a test may leave them out.
const SIBLINGS: [(&str, &str); 6] = [
    ("tiamat_default_ui", "Tiamat_Default_Inventory"),
    ("tiamat_default_world", "Tiamat_Default_World"),
    ("tiamat_default_life", "Tiamat_Default_Life"),
    ("tiamat_default_craft", "Tiamat_Default_Craft"),
    ("tiamat_default_progress", "Tiamat_Default_Progress"),
    ("tiamat_weather", "Tiamat_Default_Weather"),
];

/// A mod loaded after this one that asks the siblings what they see: `t ...`
/// in chat (tests/native/fixtures/probe.lua).
pub const PROBE: &str = include_str!("../fixtures/probe.lua");

// --- The rig -----------------------------------------------------------------

/// Which of the world around the mod to load.
#[derive(Clone)]
pub struct Setup {
    /// The interface mod.
    pub ui: bool,
    /// The weather mod.
    pub weather: bool,
    /// Life's world option, "Default", "Creative" or "Adventure".
    pub mode: Option<String>,
}

impl Default for Setup {
    fn default() -> Self {
        Setup { ui: true, weather: true, mode: None }
    }
}

pub struct Rig {
    pub vm: EngineVm,
    pub storage: Arc<Storage>,
    pub inventory: Arc<Inventory>,
    pub boxes: Arc<Boxes>,
    pub huds: Arc<Huds>,
    pub dialogs: Arc<Dialogs>,
    pub sounds: Arc<Sounds>,
    pub particles: Arc<Particles>,
    pub world: Arc<World>,
    pub entities: Entities,
    pub materials: HashMap<String, MaterialId>,
}

impl Rig {
    pub fn new(setup: Setup) -> Self {
        Self::with_storage(setup, Arc::new(Storage::default()))
    }

    /// A rig over storage another run left behind: the same world, reopened.
    pub fn with_storage(setup: Setup, storage: Arc<Storage>) -> Self {
        let dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../mods").join(MOD);
        let mut vm = EngineVm::create(VmLimits::default()).unwrap();

        let inventory = Arc::new(Inventory::default());
        let boxes = Arc::new(Boxes::default());
        let tools = Arc::new(Tools::default());
        let huds = Arc::new(Huds::default());
        let dialogs = Arc::new(Dialogs::default());
        let sounds = Arc::new(Sounds::default());
        let particles = Arc::new(Particles::default());
        let world = Arc::new(World::default());
        let entities = Entities::new();

        vm.set_storage_access(storage.clone());
        vm.set_entity_access(Arc::new(entities.clone()));
        vm.set_inventory_access(inventory.clone());
        vm.set_container_access(boxes.clone());
        vm.set_tools_access(tools.clone());
        vm.set_hud_access(huds.clone());
        vm.set_dialog_access(dialogs.clone());
        vm.set_sound_access(sounds.clone());
        vm.set_particle_access(particles.clone());
        vm.set_sight_access(world.clone());
        vm.set_fluid_access(world.clone());
        vm.set_light_source(world.clone());
        vm.set_world_edit(world.clone());

        if let Some(mode) = &setup.mode {
            vm.set_world_options(&[("tiamat_default_life:mode".to_owned(), WorldOptionValue::Choice(mode.clone()))]);
        }

        let mut loaded: Vec<String> = Vec::new();
        for (id, repo) in SIBLINGS {
            if (id == "tiamat_default_ui" && !setup.ui) || (id == "tiamat_weather" && !setup.weather) {
                continue;
            }
            let sibling = sibling_dir(repo, id);
            let init = std::fs::read_to_string(sibling.join("init.lua"))
                .unwrap_or_else(|err| panic!("sibling `{id}` not found at {}: {err}", sibling.display()));
            vm.note_dependencies(id, &loaded);
            vm.load_mod(id, &init, &sibling).unwrap_or_else(|err| panic!("sibling `{id}` failed to load: {err:?}"));
            loaded.push(id.to_owned());
        }
        vm.note_dependencies(MOD, &loaded);
        let init = std::fs::read_to_string(dir.join("init.lua")).unwrap();
        vm.load_mod(MOD, &init, &dir).expect("the mod loads");
        loaded.push(MOD.to_owned());
        vm.note_dependencies("probe", &loaded);
        vm.load_mod("probe", PROBE, &dir).unwrap_or_else(|err| panic!("the probe failed to load: {err:?}"));
        vm.freeze().unwrap();
        assert!(vm.faulted_mods().is_empty(), "faulted at load: {:?}", vm.faulted_mods());

        let materials: HashMap<String, MaterialId> = vm.registered_blocks().into_iter().collect();
        *world.names.lock().unwrap() = materials.clone();
        *tools.known.lock().unwrap() = materials.keys().cloned().collect();
        Rig { vm, storage, inventory, boxes, huds, dialogs, sounds, particles, world, entities, materials }
    }

    pub fn material(&self, id: &str) -> MaterialId {
        let id = if id.contains(':') { id.to_owned() } else { format!("{MOD}:{id}") };
        *self.materials.get(&id).unwrap_or_else(|| panic!("no material {id}"))
    }

    pub fn assert_healthy(&self, after: &str) {
        assert!(self.vm.faulted_mods().is_empty(), "faulted after {after}: {:?}", self.vm.faulted_mods());
    }

    pub fn tick(&mut self, n: u32) {
        for _ in 0..n {
            let faults = self.vm.tick(1).expect("the tick itself");
            assert!(faults.is_empty(), "mod faulted in tick: {faults:?}");
        }
        self.assert_healthy("ticks");
    }

    pub fn join(&mut self, player: [u8; 32]) {
        let _ = self.vm.player_join(&JoinEvent { player, name: "someone".into() });
        self.assert_healthy("join");
    }

    pub fn leave(&mut self, player: [u8; 32]) {
        let _ = self.vm.player_leave(&LeaveEvent { player, name: "someone".into() });
        self.assert_healthy("leave");
    }

    /// A player says `text`. A refusal's reason reaches the speaker as a
    /// line of chat, as the server delivers it — which is how a chat
    /// command's reply arrives.
    pub fn say_as(&mut self, player: [u8; 32], text: &str) {
        let out = self.vm.chat(&ChatEvent { player, text: text.into() });
        if let (false, Some(line)) = (out.allowed, out.reason.clone()) {
            self.huds.chat.lock().unwrap().push((player, line));
        }
        self.assert_healthy(text);
    }

    pub fn say(&mut self, text: &str) {
        self.say_as(PLAYER, text);
    }

    /// Everything said to a player since the last call, oldest first.
    pub fn heard(&self, player: [u8; 32]) -> Vec<String> {
        let mut chat = self.huds.chat.lock().unwrap();
        let (mine, rest): (Vec<_>, Vec<_>) = chat.drain(..).partition(|(p, _)| *p == player);
        *chat = rest;
        mine.into_iter().map(|(_, t)| t).collect()
    }

    /// The last thing said to the player, clearing what they heard.
    pub fn said(&self) -> String {
        self.heard(PLAYER).pop().unwrap_or_default()
    }

    /// Says `text` as the player and answers the last line they heard back.
    pub fn ask(&mut self, text: &str) -> String {
        self.heard(PLAYER);
        self.say(text);
        self.said()
    }

    pub fn give(&self, player: [u8; 32], id: &str, units: u32) {
        let material = self.material(id);
        self.inventory.put(player, Stack::new(material, units).unwrap());
    }

    pub fn units(&self, player: [u8; 32], id: &str) -> u32 {
        self.inventory.units_of(player, self.material(id))
    }

    /// Puts what the player carries of `id` in their hand.
    pub fn hold(&self, player: [u8; 32], id: &str) {
        let material = self.material(id);
        self.inventory.held.lock().unwrap().insert(player, (material, None));
    }

    /// A block of `id` at `(x, y, z)`, whole.
    pub fn put_block(&self, x: i32, y: i32, z: i32, id: &str) {
        self.world.put(x, y, z, self.material(id));
    }

    /// The player looks at the block at `(x, y, z)`.
    pub fn aim(&self, x: i32, y: i32, z: i32) {
        *self.world.aimed.lock().unwrap() = Some((x, y, z));
    }

    /// A handled use's words reach the player as a line of chat, as the
    /// server delivers them: a string answered, when it is not `""`.
    fn told(&self, player: [u8; 32], out: &tiamat_core::script::HookOutcome) {
        if let (false, Some(line)) = (out.allowed, out.reason.clone())
            && !line.is_empty()
        {
            self.huds.chat.lock().unwrap().push((player, line));
        }
    }

    /// The player uses the block at `(x, y, z)`, whatever it is, with what
    /// they hold. Answers whether somebody handled it.
    pub fn use_at(&mut self, player: [u8; 32], x: i32, y: i32, z: i32) -> bool {
        let Reading::Single { material, .. } = sight::Access::block_at(&*self.world, "", BlockPos { x, y, z }) else { panic!("mixed") };
        let aim = UseAim { cell: tiamat_core::SubNodePos { x: x * 3 + 1, y: y * 3 + 2, z: z * 3 + 1 }, material };
        let held = inventory::Access::held(&*self.inventory, player);
        let out = self.vm.use_block(&UseEvent { player, domain: "overworld".into(), aim: Some(aim), held });
        assert!(out.faults.is_empty(), "faulted in use: {:?}", out.faults);
        self.told(player, &out);
        !out.allowed
    }

    /// The player uses what they hold at nothing: open sky.
    pub fn use_at_nothing(&mut self, player: [u8; 32]) -> bool {
        let held = inventory::Access::held(&*self.inventory, player);
        let out = self.vm.use_block(&UseEvent { player, domain: "overworld".into(), aim: None, held });
        assert!(out.faults.is_empty(), "faulted in use: {:?}", out.faults);
        self.told(player, &out);
        !out.allowed
    }

    /// The player presses the key bound to the action `id` (qualified).
    pub fn action(&mut self, player: [u8; 32], id: &str) {
        let _ = self.vm.action(&ActionEvent { player, id: id.into(), pressed: true });
        let _ = self.vm.action(&ActionEvent { player, id: id.into(), pressed: false });
        self.assert_healthy("an action");
    }

    /// A button pressed on a dialog `mod_id` showed as `form` (unqualified).
    pub fn press(&mut self, player: [u8; 32], mod_id: &str, form: &str, name: &str) {
        let _ = self.vm.dialog_event(&DialogEvent {
            player,
            mod_id: mod_id.into(),
            form: format!("{mod_id}:{form}"),
            event: proto::DialogEvent::Pressed { name: name.into(), click: proto::Press::Left },
        });
        self.assert_healthy("a press");
    }

    /// The last dialog shown or updated: its form and its tree's debug text.
    pub fn last_dialog(&self) -> Option<(String, String)> {
        self.dialogs.shown.lock().unwrap().last().map(|r| (r.form.clone(), format!("{:?}", r.tree)))
    }

    /// Every particle burst since the last call, as debug text.
    pub fn bursts(&self) -> Vec<String> {
        self.particles.0.lock().unwrap().drain(..).map(|b| format!("{b:?}")).collect()
    }

    /// A block of `id` carved to `occupancy` at `(x, y, z)`.
    pub fn put_carved(&self, x: i32, y: i32, z: i32, id: &str, occupancy: u32) {
        self.world.put_carved(x, y, z, self.material(id), occupancy);
    }

    /// The player places a block of `id` carved to `occupancy`. Answers
    /// whether the placement was let through.
    pub fn place(&mut self, player: [u8; 32], x: i32, y: i32, z: i32, id: &str, occupancy: u32) -> bool {
        let out = self.vm.place(&PlaceEvent {
            player,
            block: BlockPos { x, y, z },
            material: self.material(id),
            occupancy,
            units: occupancy.count_ones(),
            cells: None,
        });
        assert!(out.faults.is_empty(), "faulted in place: {:?}", out.faults);
        if out.allowed {
            self.world.put_carved(x, y, z, self.material(id), occupancy);
        }
        out.allowed
    }

    /// The world is open, with this seed: `game.world_seed` is set in every
    /// mod, as the server does once a world is loaded. Weather's wind and
    /// climate answer only then.
    pub fn open_world(&mut self, seed: u64) {
        self.vm.set_world_seed(seed);
    }

    /// The day's hour, as a fraction: 0 midnight, 0.5 noon.
    pub fn set_time(&self, fraction: f32) {
        *self.sounds.time.lock().unwrap() = fraction;
    }

    /// A roof over everything, or the open sky again.
    pub fn roof(&self, roofed: bool) {
        *self.world.roofed.lock().unwrap() = roofed;
    }

    /// The player's body stands at `(x, y, z)`, facing north as it was made.
    pub fn stand_at(&self, x: f64, y: f64, z: f64) {
        let mut map = self.entities.0.lock().unwrap();
        map.get_mut(&1).expect("the player's body").transform = Transform::from_world(x, y, z);
    }

    /// One of this mod's stored values, as debug text.
    pub fn stored(&self, key: &str) -> Option<String> {
        self.storage.0.lock().unwrap().get(&(MOD.to_owned(), key.to_owned())).map(|v| format!("{v:?}"))
    }
}
