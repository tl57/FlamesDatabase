--[[-----------------------------------------------------------------------------
DataTable
A reusable columnar table component. Sized to fit all of its rows; relies on
the surrounding page to provide scrolling if the table doesn't fit.

Takes a declarative structure:
    DataTable:Build(parent, {
        width   = 700,          -- optional, default is the sum of column widths
        columns = {
            { id = "Name", width = 200 },
            { id = "OrangeClassicMine", width = 60, group = "Mine", exp = LE_EXPANSION_CLASSIC },
            ...
        },
        rows = {
            { Name = "Copper Vein", OrangeClassicMine = 1, ... },
            ...
        },
    }, selectedExpansion)

Rows are keyed by column id. Values that are nil render as empty cells.
Consecutive columns sharing the same `group` value are merged into one header
cell; other columns show column.title if provided, else column.name.

`options.rowHeight` overrides the default row height (ROW_HEIGHT below) for
every row in this table - useful when a column's word-wrapped text needs a
taller row so its second line doesn't overlap the row border below.

Non-Name columns can tint their text: `column.background` (a key into
CELL_BACKGROUND_COLORS) gives every cell in the column the same fixed color;
`column.valueColors` (e.g. { Horde = {0.9,0.2,0.2}, Alliance = {0.3,0.55,0.95} })
instead looks the color up by each cell's own value - values with no entry
stay untinted. At most one of the two applies per column in practice.

`column.valueBackgrounds` is the same value-lookup idea as `valueColors`, but
fills the cell's own background texture instead of its text (e.g.
{ Low = {0,1,0}, Medium = {1,1,0}, High = {1,0,0} }, each {r,g,b[,a]} -
alpha defaults to 0.35). A value with no entry stays unfilled.

If a row has an `ItemLinkId` (an itemID, not part of `columns`), the Name
column shows that item's icon and gets tooltip/shift-click-to-chat behavior,
while still displaying the row's own Name text (see WireItemCell).

If a row has a `QuestLinkId` (a questID, not part of `columns`) instead, the
Name column gets the same tooltip/shift-click-to-chat behavior wired to a
quest hyperlink rather than an item one (see WireQuestCell). An optional
`QuestLevel` (also not part of `columns`) is used when building the link's
level field. ItemLinkId and QuestLinkId are mutually exclusive per row.

When `selectedExpansion` is given (one of Functions_General:GetExpansionLevels()),
only columns with no `exp` or with `exp == selectedExpansion` are included -
`exp` otherwise has no visual effect of its own (no separate header row for
it), it's purely a filtering key. Rows are filtered the same way by their own
`Introduced` field (also not part of `columns`): a row is included only if it
has no `Introduced`, or `Introduced <= selectedExpansion` - e.g. a herb with
`Introduced = LE_EXPANSION_BURNING_CRUSADE` is left out entirely while Classic
is selected, since LE_EXPANSION_* values increase with each expansion and this
is a plain `<=` comparison, this keeps working unmodified as later expansions
are added - nothing here needs to change.

Row/header frames are pooled per container frame and reused across rebuilds
(see AcquireRow/AcquireCell) rather than always creating new ones - a given
page (e.g. a profession tab) rebuilds its table via a fresh DataTable:Build
call every time it's reselected, and WoW has no API to destroy a frame, so
never reusing them means each rebuild's cost keeps growing with how many
times that recycled container has ever been built.

The container itself is a dedicated custom AceGUI widget type
("FlamesDataTable", see AceGUIWidget-FlamesDataTable.lua) rather than the
stock "SimpleGroup" - AceGUI pools widgets separately per registered type
name, so this guarantees this frame (and the pooled row/cell frames
attached directly to it, bypassing AceGUI's own child-tracking) is only
ever reused for another DataTable, never handed to or received from any
other widget in this addon.

Returns the widget, ready to be added to a page builder.
-------------------------------------------------------------------------------]]
local AceGUI           = LibStub("AceGUI-3.0")

DataTable              = {}

local ROW_HEIGHT       = 20
local HEADER_HEIGHT    = 24
local PADDING          = 8
local ICON_SIZE        = 16
local ICON_TEXT_GAP    = 4

-- Thin white border settings.
local BORDER_THICKNESS = 1
local BORDER_COLOR     = { 1, 1, 1, 0.5 }
local TEXT_COLOR_DEFAULT = { 1, 1, 1 }

-- Column-identity text colors keyed by a column's `background` name, e.g.
-- { id = "OrangeClassicMine", background = "orange" } -> that column's
-- numbers render in this color, regardless of skill.
local CELL_BACKGROUND_COLORS = {
    orange = { 0.75, 0.55, 0.35 },
    yellow = { 0.75, 0.70, 0.40 },
    green  = { 0.45, 0.60, 0.45 },
    grey   = { 0.55, 0.55, 0.55 },
}

-- Text colors for a numeric cell, based on (playerSkill - cellValue).
local SKILL_DIFF_RED    = { 0.90, 0.15, 0.15 }
local SKILL_DIFF_ORANGE = { 0.90, 0.55, 0.15 }
local SKILL_DIFF_YELLOW = { 0.85, 0.85, 0.15 }
local SKILL_DIFF_GREEN  = { 0.35, 0.75, 0.35 }
local SKILL_DIFF_GREY   = { 0.60, 0.60, 0.60 }

-- diff < 0: red. 0-25: orange. 26-50: yellow. 51-75: green. 100+: grey.
local function SkillDiffColor(diff)
    if diff < 0 then
        return SKILL_DIFF_RED
    elseif diff <= 25 then
        return SKILL_DIFF_ORANGE
    elseif diff <= 50 then
        return SKILL_DIFF_YELLOW
    elseif diff <= 100 then
        return SKILL_DIFF_GREEN
    else
        return SKILL_DIFF_GREY
    end
end

-- Returns the next reusable plain wrapper frame from `container`'s row pool
-- (creating one if the pool doesn't have enough yet), parented under `parent`
-- and reset to a blank state. Used for the header row and each data row.
-- `container.rowsUsed` must be reset to 0 at the start of a build.
local function AcquireRow(container, parent)
    container.rowPool = container.rowPool or {}
    container.rowsUsed = container.rowsUsed + 1
    local n = container.rowsUsed

    local frame = container.rowPool[n]
    if not frame then
        frame = CreateFrame("Frame", nil, parent)
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        container.rowPool[n] = frame
    end

    frame:SetParent(parent)
    frame:ClearAllPoints()
    frame:Show()
    frame.bg:Hide()
    return frame
end

-- Returns the next reusable bordered/labeled cell from `container`'s cell
-- pool (creating one if needed), parented under `parent` and reset to a blank
-- state (caller sets position, size/border via LayoutCell, background, and
-- text). `container.cellsUsed` must be reset to 0 at the start of a build.
local function AcquireCell(container, parent)
    container.cellPool = container.cellPool or {}
    container.cellsUsed = container.cellsUsed + 1
    local n = container.cellsUsed

    local cell = container.cellPool[n]
    if not cell then
        cell = CreateFrame("Frame", nil, parent)
        cell.bg = cell:CreateTexture(nil, "BACKGROUND")
        cell.bg:SetAllPoints(cell)
        cell.edgeTop = cell:CreateTexture(nil, "BORDER")
        cell.edgeBottom = cell:CreateTexture(nil, "BORDER")
        cell.edgeLeft = cell:CreateTexture(nil, "BORDER")
        cell.edgeRight = cell:CreateTexture(nil, "BORDER")
        for _, tex in ipairs({ cell.edgeTop, cell.edgeBottom, cell.edgeLeft, cell.edgeRight }) do
            tex:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
        end
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.icon:SetSize(ICON_SIZE, ICON_SIZE)
        cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        -- Cells are a fixed single-line ROW_HEIGHT tall - without this,
        -- long text wraps to a second line that gets clipped by the cell's
        -- fixed height anyway, and (for reasons not fully pinned down)
        -- whether a given cell wraps has been observed to flip inconsistently
        -- depending on how many other DataTables happen to be built/alive at
        -- the same time. Forcing it off keeps every cell single-line always.
        cell.text:SetWordWrap(true)
        cell.text:SetPoint("RIGHT", -PADDING, 0)
        container.cellPool[n] = cell
    end

    cell:SetParent(parent)
    cell:ClearAllPoints()
    cell:Show()
    cell.bg:Hide()
    cell.icon:ClearAllPoints()
    cell.icon:Hide()
    cell.text:SetTextColor(TEXT_COLOR_DEFAULT[1], TEXT_COLOR_DEFAULT[2], TEXT_COLOR_DEFAULT[3])
    cell.text:SetPoint("LEFT", PADDING, 0)
    -- Reset any item-link hover/click behavior a previous use of this pooled
    -- cell may have wired up (see BuildRow) - cleared here, opted back into
    -- per-cell by whichever caller actually needs it this build. pendingItemId
    -- invalidates any in-flight ContinueOnItemLoad callback still targeting
    -- this cell from a previous use.
    cell:EnableMouse(false)
    cell:SetScript("OnEnter", nil)
    cell:SetScript("OnLeave", nil)
    cell:SetScript("OnMouseUp", nil)
    cell.pendingItemId = nil
    return cell
end

-- Sizes a cell acquired via AcquireCell and (re)draws its border. Pass
-- skipTop/skipLeft to omit those edges (e.g. for the table's first cell).
local function LayoutCell(cell, width, height, skipTop, skipLeft)
    cell:SetSize(width, height)

    -- cell.text is anchored via LEFT+RIGHT points (see AcquireCell), so its
    -- word-wrap boundary is only ever implied by cell's own rendered width -
    -- which, right after SetSize above, hasn't necessarily propagated yet
    -- (frame geometry changes can take a frame to settle). Giving it this
    -- width explicitly makes the wrap boundary apply immediately instead of
    -- only after something else later forces a layout pass (e.g. building
    -- another DataTable, or resizing the window).
    cell.text:SetWidth(math.max(width - 2 * PADDING, 0))

    local t = BORDER_THICKNESS

    cell.edgeTop:ClearAllPoints()
    if skipTop then
        cell.edgeTop:Hide()
    else
        cell.edgeTop:Show()
        cell.edgeTop:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        cell.edgeTop:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
        cell.edgeTop:SetHeight(t)
    end

    cell.edgeBottom:ClearAllPoints()
    cell.edgeBottom:Show()
    cell.edgeBottom:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)
    cell.edgeBottom:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
    cell.edgeBottom:SetHeight(t)

    cell.edgeLeft:ClearAllPoints()
    if skipLeft then
        cell.edgeLeft:Hide()
    else
        cell.edgeLeft:Show()
        cell.edgeLeft:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
        cell.edgeLeft:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)
        cell.edgeLeft:SetWidth(t)
    end

    cell.edgeRight:ClearAllPoints()
    cell.edgeRight:Show()
    cell.edgeRight:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
    cell.edgeRight:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
    cell.edgeRight:SetWidth(t)
end

-- Resolves `itemId` asynchronously and, once loaded, turns `cell` into an
-- icon + item-link-aware cell: shows the item's icon to the left of the
-- text, and wires GameTooltip:SetHyperlink on hover and ChatEdit_InsertLink
-- on shift-click. `displayText`, if given, is shown as the cell's text once
-- the item loads instead of the item's own link text (used by the Name
-- column to keep showing the row's custom Name string, e.g. "Copper",
-- rather than the item's real link label). Leave nil to show the raw item
-- link text.
--
-- GetItemInfo/GetItemLink can return nothing on the very first query for an
-- item the client hasn't cached yet, so ContinueOnItemLoad's callback fires
-- immediately if already cached, or once the data arrives otherwise. Cells
-- are pooled/reused across rebuilds (switching tabs/expansions), so
-- cell.pendingItemId guards against a delayed callback overwriting a cell
-- that's since been recycled for something unrelated.
local function WireItemCell(cell, itemId, displayText)
    cell.pendingItemId = itemId

    local item = Item:CreateFromItemID(itemId)
    if item:IsItemEmpty() then
        return
    end

    item:ContinueOnItemLoad(function()
        if cell.pendingItemId ~= itemId then
            return
        end
        local itemLink = item:GetItemLink()

        cell.icon:SetTexture(item:GetItemIcon())
        cell.icon:SetPoint("LEFT", PADDING, 0)
        cell.icon:Show()
        cell.text:ClearAllPoints()
        cell.text:SetPoint("LEFT", cell.icon, "RIGHT", ICON_TEXT_GAP, 0)
        cell.text:SetPoint("RIGHT", -PADDING, 0)
        cell.text:SetText(displayText or itemLink)

        cell:EnableMouse(true)
        cell:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        cell:SetScript("OnMouseUp", function()
            if IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(itemLink)
            end
        end)
    end)
end

-- Resolves `questId` into a real quest hyperlink where possible (falls back
-- to a manually-built "quest:id:level" link, in the same hyperlink format,
-- if the client doesn't have the quest's title cached yet), and turns `cell`
-- into a link-aware cell: wires GameTooltip:SetHyperlink on hover and
-- ChatEdit_InsertLink on shift-click - the quest-link counterpart to
-- WireItemCell above. Unlike items, a quest's link text resolves
-- synchronously (no item cache / ContinueOnItemLoad-style async load to wait
-- on), so this wires everything up immediately rather than deferring to a
-- callback. `displayText`, if given, is shown instead of the link's own
-- bracketed title text (mirrors WireItemCell's `displayText`).
local function WireQuestCell(cell, questId, level, displayText)
    local questLink = (GetQuestLink and GetQuestLink(questId))
        or ("|cffffff00|Hquest:%d:%d|h[%s]|h|r"):format(questId, level or 0, displayText or ("Quest " .. questId))

    cell.text:SetText(displayText or questLink)
    -- displayText (the row's own Name string) has no color codes of its own,
    -- unlike questLink's raw text - without this it'd read as plain white
    -- text with no visual sign it's a clickable/hoverable link. Standard
    -- WoW quest-hyperlink yellow (matches the |cffffff00 used above).
    cell.text:SetTextColor(1, 1, 0)

    cell:EnableMouse(true)
    cell:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(questLink)
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    cell:SetScript("OnMouseUp", function()
        if IsModifiedClick("CHATLINK") then
            ChatEdit_InsertLink(questLink)
        end
    end)
end

-- Build one row's cells directly under `container`, anchored at a fixed
-- vertical offset. The table is sized to fit all of them (the page around it
-- scrolls). `rowHeight` overrides the default ROW_HEIGHT (see DataTable:Build).
local function BuildRow(container, row, columns, yOffset, skill, rowHeight)
    local frame = AcquireRow(container, container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(rowHeight)

    -- The first (id/name) column borrows the skill-diff color of the first
    -- other column that has a number in this row, so its color reflects this
    -- row's status at a glance without needing to look further right. Grey
    -- if none of the other columns have a number for this row.
    local nameColor
    if skill then
        local firstValue
        for i = 2, #columns do
            local value = row[columns[i].id]
            if type(value) == "number" then
                firstValue = value
                break
            end
        end
        nameColor = firstValue and SkillDiffColor(skill - firstValue) or SKILL_DIFF_GREY
    end

    for i, col in ipairs(columns) do
        local cell = AcquireCell(container, frame)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        LayoutCell(cell, col.width, rowHeight)

        local value = row[col.id]
        cell.text:SetJustifyH(col.justify or "LEFT")

        if i == 1 then
            -- Name column: always display the row's own Name string (never
            -- the item's/quest's own link text), and keep the skill-diff
            -- tint. When this row also has an ItemLinkId, additionally show
            -- that item's icon and wire up tooltip/shift-click-to-chat via
            -- WireItemCell, pinning `value` as the text so it keeps reading
            -- e.g. "Copper" instead of switching to the item's own link
            -- label once loaded. QuestLinkId is the same idea for a quest
            -- hyperlink instead (see WireQuestCell) - mutually exclusive
            -- with ItemLinkId.
            cell.text:SetText(value or "")
            if nameColor then
                cell.text:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
            end
            if row.ItemLinkId then
                WireItemCell(cell, row.ItemLinkId, value)
            elseif row.QuestLinkId then
                WireQuestCell(cell, row.QuestLinkId, row.QuestLevel, value)
            end
        else
            cell.text:SetText(value or "")

            -- col.background gives every cell in the column the same fixed
            -- color; col.valueColors instead looks the color up by this
            -- cell's own value (e.g. { Horde = {...}, Alliance = {...} } -
            -- a value with no entry, like a future "Both", just stays
            -- untinted). At most one applies per column in practice.
            local color = value ~= nil and col.background and CELL_BACKGROUND_COLORS[col.background]
            if not color and value ~= nil and col.valueColors then
                color = col.valueColors[value]
            end
            if color then
                cell.text:SetTextColor(color[1], color[2], color[3])
            end

            -- col.valueBackgrounds fills the cell's own background texture
            -- (rather than tinting its text) based on this cell's value -
            -- e.g. { Low = {0,1,0}, Medium = {1,1,0}, High = {1,0,0} }.
            -- AcquireCell hides cell.bg by default, so a value with no entry
            -- just stays unfilled.
            local bgColor = value ~= nil and col.valueBackgrounds and col.valueBackgrounds[value]
            if bgColor then
                cell.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.35)
                cell.bg:Show()
            end
        end
    end
end

-- Build the table into an AceGUI SimpleGroup and return it. When
-- `selectedExpansion` is given, only columns with no `exp` (e.g. the id/name
-- column) or with `exp == selectedExpansion` are included - everything else
-- (and any row data only reachable through those columns) is left out
-- entirely, not just hidden. Rows with a numeric `Introduced` greater than
-- selectedExpansion are dropped the same way (rows with no `Introduced` are
-- always kept) - a plain `<=` comparison against LE_EXPANSION_* values, so it
-- needs no changes as later expansions are added.
function DataTable:Build(parent, options, selectedExpansion)
    options = options or {}
    local columns = options.columns or {}
    local rows = options.rows or {}

    if selectedExpansion then
        local filteredColumns = {}
        for _, col in ipairs(columns) do
            if not col.exp or col.exp == selectedExpansion then
                filteredColumns[#filteredColumns + 1] = col
            end
        end
        columns = filteredColumns

        local filteredRows = {}
        for _, row in ipairs(rows) do
            if not row.Introduced or row.Introduced <= selectedExpansion then
                filteredRows[#filteredRows + 1] = row
            end
        end
        rows = filteredRows
    end

    -- Precompute each column's left x-offset.
    local x = 0
    for _, col in ipairs(columns) do
        col.width = col.width or 80
        col._x = x
        x = x + col.width
    end
    local totalWidth = x

    local width = options.width or totalWidth
    local rowHeight = options.rowHeight or ROW_HEIGHT
    local height = HEADER_HEIGHT + (#rows * rowHeight)

    -- Container frame hosting header + rows. A dedicated widget type (see
    -- AceGUIWidget-FlamesDataTable.lua) - AceGUI pools widgets separately
    -- per registered type name, so this frame is never shared with (or
    -- polluted by) any other kind of widget in this addon, unlike the
    -- stock "SimpleGroup" every spacer/section/etc. also draws from. No
    -- defensive "hide whatever's already attached" cleanup is needed here
    -- as a result: the only thing that can ever be attached is our own
    -- pooled rows/cells (container.rowPool/cellPool below), which are
    -- already correctly shown/hidden by AcquireRow/AcquireCell and the
    -- hide-the-excess loop at the end of this function.
    local group = AceGUI:Create("FlamesDataTable")
    local container = group.frame
    group:SetWidth(width)
    group:SetHeight(height)

    -- Belt-and-suspenders: makes sure a released-while-expanded table's
    -- rows/cells are hidden immediately rather than relying solely on the
    -- next build's hide-the-excess loop to catch them.
    group.OnRelease = function(self)
        for _, frame in ipairs(self.frame.rowPool or {}) do
            frame:Hide()
        end
        for _, frame in ipairs(self.frame.cellPool or {}) do
            frame:Hide()
        end
    end

    -- Reset this build's usage counters; AcquireRow/AcquireCell reuse
    -- container.rowPool/cellPool from a previous build of this (possibly
    -- recycled) container instead of creating fresh frames.
    container.rowsUsed = 0
    container.cellsUsed = 0

    -- Header row. Consecutive columns sharing a `group` value are merged into
    -- one cell; other columns show column.title if provided, else
    -- column.name, else column.id (e.g. quest columns that only ever set
    -- `id`/`width`, with no separate display-name field).
    local header = AcquireRow(container, container)
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    header.bg:SetAllPoints(header)
    header.bg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    header.bg:Show()

    local i = 1
    while i <= #columns do
        local col = columns[i]
        local cellWidth = col.width
        local label = col.title or col.name or col.id
        local justify = col.justify or "LEFT"

        if col.group then
            local last = i
            while columns[last + 1] and columns[last + 1].group == col.group do
                last = last + 1
            end
            cellWidth = (columns[last]._x + columns[last].width) - col._x
            label = col.group
            justify = "CENTER"
            i = last
        end

        local cell = AcquireCell(container, header)
        cell:SetPoint("TOPLEFT", header, "TOPLEFT", col._x, 0)
        -- The table's very first cell (top-left corner) omits its top/left
        -- edges so it doesn't double up against the surrounding page chrome.
        LayoutCell(cell, cellWidth, HEADER_HEIGHT, i == 1, i == 1)
        cell.text:SetJustifyH(justify)
        cell.text:SetText(label or "")

        i = i + 1
    end

    -- When `profession` is given and the character has it, numeric cells are
    -- colorized by (skill - cellValue) via SkillDiffColor. Otherwise untouched.
    local skill = options.profession and Functions_Professions:GetProfessionSkillNumber(options.profession)

    -- Rows, stacked directly below the header. No inner scrollbar: the page
    -- around this table already scrolls, so the table is just as tall as its data.
    for idx, row in ipairs(rows) do
        BuildRow(container, row, columns, -(HEADER_HEIGHT + (idx - 1) * rowHeight), skill, rowHeight)
    end

    -- Hide any pooled rows/cells left over from a build with more rows or
    -- columns than this one (e.g. switching from Mining to the smaller
    -- Herbalism table in the same recycled container).
    for n = container.rowsUsed + 1, #container.rowPool do
        container.rowPool[n]:Hide()
    end
    for n = container.cellsUsed + 1, #container.cellPool do
        container.cellPool[n]:Hide()
    end

    return group
end
