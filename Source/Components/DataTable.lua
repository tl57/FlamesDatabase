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

If a row has an `ItemLinkId` (an itemID, not part of `columns`), the Name
column shows that item's icon and gets tooltip/shift-click-to-chat behavior,
while still displaying the row's own Name text (see WireItemCell).

When `selectedExpansion` is given (one of Functions_General:GetExpansionLevels()),
only columns with no `exp` or with `exp == selectedExpansion` are included -
`exp` otherwise has no visual effect of its own (no separate header row for
it), it's purely a filtering key.

Row/header frames are pooled per AceGUI SimpleGroup and reused across rebuilds
(see AcquireRow/AcquireCell) rather than always creating new ones - AceGUI
recycles SimpleGroup widgets, and a given page (e.g. a profession tab) rebuilds
its table via a fresh DataTable:Build call every time it's reselected. WoW has
no API to destroy a frame, so never reusing them means each rebuild's cost
keeps growing with how many times that recycled container has ever been built.

Returns the AceGUI SimpleGroup, ready to be added to a page builder.
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

-- Build one row's cells directly under `container`, anchored at a fixed
-- vertical offset. The table is sized to fit all of them (the page around it
-- scrolls).
local function BuildRow(container, row, columns, yOffset, skill)
    local frame = AcquireRow(container, container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(ROW_HEIGHT)

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
        LayoutCell(cell, col.width, ROW_HEIGHT)

        local value = row[col.id]
        cell.text:SetJustifyH("LEFT")

        if i == 1 then
            -- Name column: always display the row's own Name string (never
            -- the item's own link text), and keep the skill-diff tint. When
            -- this row also has an ItemLinkId, additionally show that item's
            -- icon and wire up tooltip/shift-click-to-chat via WireItemCell,
            -- pinning `value` as the text so it keeps reading e.g. "Copper"
            -- instead of switching to the item's own link label once loaded.
            cell.text:SetText(value or "")
            if nameColor then
                cell.text:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
            end
            if row.ItemLinkId then
                WireItemCell(cell, row.ItemLinkId, value)
            end
        else
            cell.text:SetText(value or "")

            local color = value ~= nil and col.background and CELL_BACKGROUND_COLORS[col.background]
            if color then
                cell.text:SetTextColor(color[1], color[2], color[3])
            end
        end
    end
end

-- Build the table into an AceGUI SimpleGroup and return it. When
-- `selectedExpansion` is given, only columns with no `exp` (e.g. the id/name
-- column) or with `exp == selectedExpansion` are included - everything else
-- (and any row data only reachable through those columns) is left out
-- entirely, not just hidden.
function DataTable:Build(parent, options, selectedExpansion)
    options = options or {}
    local columns = options.columns or {}
    local rows = options.rows or {}

    if selectedExpansion then
        local filtered = {}
        for _, col in ipairs(columns) do
            if not col.exp or col.exp == selectedExpansion then
                filtered[#filtered + 1] = col
            end
        end
        columns = filtered
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
    local height = HEADER_HEIGHT + (#rows * ROW_HEIGHT)

    -- Container frame hosting header + rows.
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Fill")
    local container = group.frame
    group:SetWidth(width)
    group:SetHeight(height)

    -- AceGUI's SimpleGroup pool is shared by every SimpleGroup in the client
    -- session (every addon using this AceGUI-3.0, not just this one) - a
    -- frame that previously served as a table full of pooled row/cell
    -- children can later be handed back to us as a "fresh" container, or
    -- (worse) recycled elsewhere entirely as an unrelated widget (e.g. a
    -- spacer) whose code has no idea about rowPool/cellPool and won't hide
    -- them. Defensively hide everything already attached before
    -- reusing/reshowing whichever of our own pooled children this build
    -- actually needs. Cheap: pooling already bounds how many children a
    -- container can ever accumulate, unlike before pooling existed.
    for _, child in ipairs({ container:GetChildren() }) do
        child:Hide()
    end

    -- Hiding a parent doesn't change its children's own shown-state, only
    -- their effective visibility while the parent stays hidden - so if this
    -- container gets released (e.g. switching away from this page) and then
    -- recycled for something unrelated (a spacer, another addon's widget)
    -- before we ever rebuild into it again, that something else calling
    -- :Show() on it would also resurface our still-"shown" leftover cells
    -- riding along underneath. Closing that race requires cleaning up at
    -- release time, not just at the next build - AceGUI calls this hook
    -- when `group` is released, before the frame is handed back to the pool.
    --
    -- Only our own pooled row/cell frames (container.rowPool/cellPool) are
    -- hidden here - NOT container:GetChildren(), which would also catch
    -- AceGUI's own `content` sub-frame (always a direct child of the
    -- container). content is what every other AceGUI widget gets parented
    -- into via AddChild, and nothing ever calls content:Show() again once
    -- hidden - so if this exact SimpleGroup instance later gets recycled
    -- (from AceGUI's pool, shared across every SimpleGroup in the client)
    -- into a container that actually uses AddChild (e.g. GatheringPage's
    -- expansion radio group), hiding content here would permanently hide
    -- all of that unrelated future content, with no tab-switch able to fix
    -- it since content's hidden state persists on the recycled frame.
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
    -- one cell; other columns show column.title if provided, else column.name.
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
        local label = col.title or col.name
        local justify = "LEFT"

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
        BuildRow(container, row, columns, -(HEADER_HEIGHT + (idx - 1) * ROW_HEIGHT), skill)
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
