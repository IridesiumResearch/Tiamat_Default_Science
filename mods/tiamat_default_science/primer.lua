-- SPDX-FileCopyrightText: Iridesium
-- SPDX-License-Identifier: GPL-3.0-only
--
-- The Theatrum Machinarum (brief §11): Jacob Leupold's Theatre of Machines
-- (1724–39) was the first encyclopedia of machines, and mostly plates, which
-- makes it the right model for a child's recipe book. A page for each node
-- the reader holds or could learn next — never the whole tree at once — and
-- on it, for each thing that node makes, the picture of what comes out and
-- one line of what goes in and where.
--
-- A dialog, not a tab on the interface's screen: a tab is drawn for every
-- player, and the book is only for whoever has one. It opens on the
-- `theatrum` action (N unless the player moved it), when the book is used,
-- anywhere, and on `science book` in chat.

local C = tds.config
local U = tds.util
local A = tds.apprentice

local P = {}

local FORM = "theatrum"
local BOOK = tds.items.ids.theatrum

local ui = U.exports("tiamat_default_ui")
local W = ui and ui.widgets

-- Pictures ride in the dialog's own tree, so they cost none of the
-- server's 512 registered pictures: a content hash is enough.
local pictures = {}
for _, list in ipairs({ C.bench_items, C.path_items, C.tier3_items }) do
    for _, spec in ipairs(list) do
        local ok, hash = pcall(game.content_hash, "textures/" .. spec.id .. ".png")
        if ok then pictures[spec.id] = hash end
    end
end

local STATIONS = {
    hand = "by hand",
    workbench = "at a workbench",
    kiln = "in a burning kiln",
    bloomery = "in a burning bloomery",
    frame = "in a turning machine frame",
    furnace = "in a burning furnace",
}

-- What a node's page says besides its recipes: how to use what it teaches.
local HOW = {
    ["shared.sundial"] = "Carve a stone into a gnomon — a flat slab with a peg in its middle "
        .. "(the Gnomon button in the shape crafter). Use it in sunshine.",
    ["shared.burning_glass"] = "Hold the glass and use it on anything.",
    ["shared.kite"] = "Hold the kite under the open sky. It flies higher when the weather blows.",
    ["shared.compass"] = "Use the compass anywhere. Carve a cairn from stone — a slab with two stones "
        .. "on top (the Cairn button) — and place it, and the needle will point home.",
    ["science.machine_frame"] = "Put a movement in the frame's first slot, and use a crank handle on the "
        .. "frame to turn it by hand.",
    ["science.gearing"] = "Carve planks into rods, gears and wheels (the Pillar, Gear and Wheel buttons) and "
        .. "set them face to face, from a wheel to your frames and furnaces.",
    ["science.water_wheel"] = "A carved plank wheel with water beside it turns everything its shafts touch: "
        .. "more water, more turning.",
    ["science.windmill"] = "A carved plank wheel with two plank slabs beside it for sails, eight or more "
        .. "blocks above the ground, turns in the wind.",
    ["science.archimedes_screw"] = "A pump in a turning frame lifts water from under the frame to over it.",
    ["science.blast_furnace"] = "Put a blowing engine in the furnace's tool slot, and a turning shaft "
        .. "touching the furnace, and it burns hot enough for pig iron.",
    ["science.gunpowder"] = "Use a mining charge on rock, and stand back.",
    ["science.alhazen_optics"] = "Use the surveyor's staff on anything to measure it.",
    ["science.magnetism"] = "Use the dip needle anywhere: it leans toward metal ore.",
    ["science.printing_press"] = "Put the press in a frame and your notebook in its inputs. Give "
        .. "treatises to other players: each one teaches them.",
}

--- The name a player reads for a config id: this mod's item's own name, or
--- the other mod's id made readable ("C:bark_strip" -> "bark strip").
local names = {}
for _, list in ipairs({ C.bench_items, C.path_items, C.tier3_items }) do
    for _, spec in ipairs(list) do names[spec.id] = spec.name end
end
for _, spec in ipairs({ C.frame, C.furnace, C.copper_stock }) do names[spec.id] = spec.name end

local function name_of(id)
    if names[id] then return names[id] end
    local short = string.match(id, ":([^:]+)$") or id
    return (string.gsub(short, "_", " "))
end

local function amount(entry)
    if type(entry) == "string" then return name_of(entry) end
    local what = entry.glyph and ("carved " .. name_of(entry.material) .. " " .. entry.glyph) or name_of(entry[1])
    if entry.count and entry.count > 1 then return entry.count .. " " .. what end
    if entry.units then return "a handful of " .. what end
    return what
end

--- A pattern's cells, counted: `{ "S.S", "S.S" }` with S sand is 4 sand.
local function pattern_inputs(r)
    local count = {}
    for _, row in ipairs(r.pattern) do
        for letter in string.gmatch(row, "%a") do count[letter] = (count[letter] or 0) + 1 end
    end
    local out = {}
    for letter, n in pairs(count) do
        local e = r.key[letter]
        out[#out + 1] = { type(e) == "string" and e or e[1], count = n }
    end
    table.sort(out, function(a, b) return a[1] < b[1] end)
    return out
end

--- One line: "leather + 2 bark strip + charcoal -> Theatrum Machinarum, by hand".
function P.line(r)
    local parts = {}
    for i, entry in ipairs(r.inputs or pattern_inputs(r)) do parts[i] = amount(entry) end
    local out = r.outputs[1]
    local made = out and amount(out) or "water, lifted"
    return string.format("%s  ->  %s, %s", #parts > 0 and table.concat(parts, " + ") or "nothing",
        made, STATIONS[r.station] or r.station)
end

-- Widgets: the interface's look when it is here, plain ones without it.
-- The interface's come back as read-only views, copied into plain tables
-- before a dialog can carry them (util.plain).
local function label(text, size)
    if W then return U.plain(W.label(text, size)) end
    return { type = "label", text = text, style = { text_size = size or 17 } }
end
local function text(t)
    if W then return U.plain(W.text(t)) end
    return { type = "label", text = t, style = { text_size = 15 } }
end
local function hint(t)
    if W then return U.plain(W.hint(t)) end
    return { type = "label", text = t, style = { text_size = 13 } }
end
local function column(children, gap)
    return { type = "container", direction = "column", children = children, gap = gap or 6, align = "stretch" }
end
local function row(children, size)
    return { type = "container", direction = "row", children = children, gap = 8, size = size, align = "center" }
end

local function recipe_row(r)
    local out = r.outputs[1] and r.outputs[1][1]
    local children = {}
    if pictures[out] then
        children[1] = { type = "image", hash = pictures[out], size = 40, cross_size = 40 }
    end
    children[#children + 1] = text(P.line(r))
    return row(children, 44)
end

--- Every page the book could hold, in order: the Bench's nodes, then the
--- path's that ship, each `{ id, label, text, cost, requires = { ids } }`.
local function all_pages()
    local out = {}
    for _, node in ipairs(C.bench_nodes) do
        out[#out + 1] = { id = node.id, label = node.label, text = node.text, cost = node.cost,
            requires = { node.requires } }
    end
    for _, node in ipairs(tds.path and tds.path.shipped or {}) do
        local requires = {}
        for i, ref in ipairs(node.requires) do requires[i] = tds.path.node_id(ref) end
        out[#out + 1] = { id = tds.path.node_id(node.id), label = node.label, text = node.text, cost = node.cost,
            requires = requires }
    end
    return out
end

local function next_for(uuid, page)
    for _, id in ipairs(page.requires) do
        if not A.has(uuid, id) then return false end
    end
    return true
end

local function recipes_of(id)
    local list = {}
    for _, source in ipairs({ A.recipes, tds.mechanica and tds.mechanica.recipes or {} }) do
        for _, r in ipairs(source[id] or {}) do list[#list + 1] = r end
    end
    return list
end

--- The book's pages for a player, as one dialog tree.
function P.build(uuid)
    local pages = { label("Theatrum Machinarum", 22) }
    local shown = 0
    for _, node in ipairs(all_pages()) do
        local held = A.has(uuid, node.id)
        if held or next_for(uuid, node) then
            shown = shown + 1
            local page = { label(node.label, 18), text(node.text) }
            if held then
                for _, r in ipairs(recipes_of(node.id)) do
                    page[#page + 1] = recipe_row(r)
                end
                if HOW[node.id] then page[#page + 1] = hint(HOW[node.id]) end
            else
                page[#page + 1] = hint(string.format("Learn it at the research table for %d insight.", node.cost))
            end
            pages[#pages + 1] = column(page, 4)
        end
    end
    if shown == 0 then
        pages[#pages + 1] = text("The pages are blank. Light your first fire, and they will fill.")
    end
    return column({ { type = "scroll", grow = 1, children = { column(pages, 14) } } }, 0)
end

--- Opens the book for a player.
function P.open(uuid)
    game.show_dialog{ player = uuid, form = FORM, tree = P.build(uuid) }
end

--- Whether a player carries a Theatrum.
function P.carries(uuid)
    for _, view in ipairs({ "player:hotbar", "player:main" }) do
        for _, stack in ipairs(game.inventory(uuid, view) or {}) do
            if stack.material == BOOK then return true end
        end
    end
    return false
end

-- Its key opens it for a player who carries one; for anyone else the key
-- does nothing, as a key for a book you do not have should.
tds.on_action("theatrum", C.theatrum_key, "Open the Theatrum Machinarum", function(player)
    if P.carries(player) then P.open(player) end
end)

-- Using the book, at a block or at nothing, opens it.
tds.on_use(function(e)
    if not (e.held and e.held.material == BOOK) then return nil end
    P.open(e.player)
    return ""
end)

return P
