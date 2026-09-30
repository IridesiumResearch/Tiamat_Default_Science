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
-- player, and the book is only for whoever has one. It opens when the book
-- is used, anywhere, and on `science book` in chat: the engine's actions,
-- which would give it a key, are inert until its Task 13 (engine ask E-S3).

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
for _, spec in ipairs(C.bench_items) do
    local ok, hash = pcall(game.content_hash, "textures/" .. spec.id .. ".png")
    if ok then pictures[spec.id] = hash end
end

local STATIONS = {
    hand = "by hand",
    workbench = "at a workbench",
    kiln = "in a burning kiln",
}

-- What a node's page says besides its recipes: how to use what it teaches.
local HOW = {
    ["shared.sundial"] = "Carve a stone into a gnomon — a flat slab with a peg in its middle "
        .. "(the Gnomon button in the shape crafter). Use it in sunshine.",
    ["shared.burning_glass"] = "Hold the glass and use it on anything.",
    ["shared.kite"] = "Hold the kite under the open sky. It flies higher when the weather blows.",
    ["shared.compass"] = "Use the compass anywhere. Carve a cairn from stone — a slab with two stones "
        .. "on top (the Cairn button) — and place it, and the needle will point home.",
}

--- The name a player reads for a config id: this mod's item's own name, or
--- the other mod's id made readable ("C:bark_strip" -> "bark strip").
local names = {}
for _, spec in ipairs(C.bench_items) do names[spec.id] = spec.name end

local function name_of(id)
    if names[id] then return names[id] end
    local short = string.match(id, ":([^:]+)$") or id
    return (string.gsub(short, "_", " "))
end

local function amount(entry)
    if entry.count and entry.count > 1 then return entry.count .. " " .. name_of(entry[1]) end
    if entry.units then return "a handful of " .. name_of(entry[1]) end
    return name_of(entry[1])
end

--- One line: "leather + 2 bark strip + charcoal -> Theatrum Machinarum, by hand".
function P.line(r)
    local parts = {}
    for i, entry in ipairs(r.inputs) do parts[i] = amount(entry) end
    local out = r.outputs[1]
    return string.format("%s  ->  %s, %s", table.concat(parts, " + "), amount(out), STATIONS[r.station] or r.station)
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
    local out = r.outputs[1][1]
    local children = {}
    if pictures[out] then
        children[1] = { type = "image", hash = pictures[out], size = 40, cross_size = 40 }
    end
    children[#children + 1] = text(P.line(r))
    return row(children, 44)
end

--- The book's pages for a player, as one dialog tree.
function P.build(uuid)
    local pages = { label("Theatrum Machinarum", 22) }
    local shown = 0
    for _, node in ipairs(C.bench_nodes) do
        local held = A.has(uuid, node.id)
        if held or A.has(uuid, node.requires) then
            shown = shown + 1
            local page = { label(node.label, 18), text(node.text) }
            if held then
                for _, r in ipairs(A.recipes[node.id] or {}) do
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

-- Using the book, at a block or at nothing, opens it.
tds.on_use(function(e)
    if not (e.held and e.held.material == BOOK) then return nil end
    P.open(e.player)
    return ""
end)

return P
