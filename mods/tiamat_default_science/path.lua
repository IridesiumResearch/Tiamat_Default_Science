-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The science path: the door (brief §3) and the tree (§5), into Progress.
--
-- Progress owns the graph, the insight and the lock: this file registers
-- into it and keeps no second copy of who chose what. A path node is `false`
-- to every player of the other path, and "lies beyond the Fork" to a player
-- with none, whatever this mod does.
--
-- Only the tiers whose content is built are registered (`config.lua`'s
-- `shipped_tier`): a node that unlocks nothing yet is not for sale. The
-- rest of the tree stays data, which `tools/check_tree.py` proves sound.
--
-- Choosing the Antikythera Mechanism gives Natural Philosophy, free, and the
-- notebook and the Theatrum to a player who has none. `on_choose` also runs
-- when a player repaths INTO science, which is right: the root went with the
-- old path and comes back. Repathing away needs nothing from this mod yet —
-- Progress takes the path's nodes itself, and nothing built so far belongs
-- to a player.

local C = tds.config
local U = tds.util
local P = tds.primer

local T = {}

local progress = U.exports("tiamat_default_progress")

T.nodes = tds.tree               -- the data; tools/check_tree.py reads the same file
T.shipped = {}                   -- the nodes registered with Progress
for _, node in ipairs(T.nodes) do
    if node.tier <= C.shipped_tier then T.shipped[#T.shipped + 1] = node end
end

--- A node reference from tree.lua, qualified: bare names are `science.` nodes.
function T.node_id(ref)
    return string.find(ref, ".", 1, true) and ref or ("science." .. ref)
end

local NOTEBOOK = U.id("notebook")
local BOOK = U.id("theatrum")

local function carries(uuid, id)
    local material = U.material(id)
    for _, view in ipairs({ "player:hotbar", "player:main" }) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            if stack.material == material then return true end
        end
    end
    return false
end

--- A player has just taken the path of natural philosophy.
function T.on_choose(uuid)
    local ok, why = progress.unlock(uuid, C.path.root)
    if not ok and not progress.has(uuid, C.path.root) then
        game.log("tiamat_default_science: the root was refused: " .. tostring(why))
    end
    if not carries(uuid, NOTEBOOK) then game.give(uuid, { material = NOTEBOOK, count = 1 }) end
    if not P.carries(uuid) then game.give(uuid, { material = BOOK, count = 1 }) end
    game.chat_to(uuid, C.path.welcome)
end

if progress then
    local inputs = {}
    for i, entry in ipairs(C.path.inputs) do
        inputs[i] = { U.id(entry[1]), count = entry.count, units = entry.units }
    end
    local ok, why = progress.register_path{
        id = C.path.id,
        label = C.path.label,
        door = U.id(C.antikythera.id),
        recipe = { inputs = inputs },
        sentence = C.path.sentence,
        refusal = C.path.refusal,
        on_choose = function(uuid) T.on_choose(uuid) end,
        branches = C.path.branches,
        reveal = C.path.reveal,
    }
    if not ok then game.log("tiamat_default_science: Progress refused the path: " .. tostring(why)) end

    for _, node in ipairs(T.shipped) do
        local requires = {}
        for i, ref in ipairs(node.requires) do requires[i] = T.node_id(ref) end
        local effects = nil
        if node.effects then
            effects = {}
            for i, fx in ipairs(node.effects) do effects[i] = { fx[1], fx[2] } end
        end
        local added, refused = progress.register_node{
            id = T.node_id(node.id), tier = node.tier, cost = node.cost, requires = requires,
            label = node.label, text = node.text, effects = effects, branch = node.branch,
        }
        if not added then
            game.log("tiamat_default_science: Progress refused " .. node.id .. ": " .. tostring(refused))
        end
    end
end

return T
