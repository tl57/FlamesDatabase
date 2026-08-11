--[[-----------------------------------------------------------------------------
DataTable
A reusable columnar table component. Sized to fit all of its rows; relies on
the surrounding page to provide scrolling if the table doesn't fit.

Takes a declarative structure:
    DataTable:Build(parent, {
        width   = 700,          -- optional, default is the sum of column widths
        columns = {
            { id = "Name", width = 200 },
            { id = "OrangeClassicMine", width = 60, group = "Mine" },
            ...
        },
        rows = {
            { Name = "Copper Vein", OrangeClassicMine = 1, ... },
            ...
        },
    })

Rows are keyed by column id. Values that are nil render as empty cells.
There are up to two header rows: consecutive columns sharing the same `exp`
value are merged into a cell in a super-header row above the regular header,
and consecutive columns sharing the same `group` value are merged into a cell
in the regular header row. Columns with neither `exp` nor `group` (e.g. an
id/name column) span both header rows; other columns show column.title if
provided, else column.name.

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

-- Thin white border settings.
local BORDER_THICKNESS = 1
local BORDER_COLOR     = { 1, 1, 1, 0.5 }
local TEXT_COLOR_DEFAULT = { 1, 1, 1 }

-- Muted (low-saturation) cell tints keyed by a column's `background` name,
-- e.g. { id = "OrangeClassicMine", background = "orange" }. CELL_BACKGROUND_ALPHA
-- controls how strong the tint reads for all colors at once.
local CELL_BACKGROUND_ALPHA  = 0.50
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
-- and reset to a blank state. Used for the super-header/header rows and each
-- data row. `container.rowsUsed` must be reset to 0 at the start of a build.
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
        cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cell.text:SetPoint("LEFT", PADDING, 0)
        cell.text:SetPoint("RIGHT", -PADDING, 0)
        container.cellPool[n] = cell
    end

    cell:SetParent(parent)
    cell:ClearAllPoints()
    cell:Show()
    cell.bg:Hide()
    cell.text:SetTextColor(TEXT_COLOR_DEFAULT[1], TEXT_COLOR_DEFAULT[2], TEXT_COLOR_DEFAULT[3])
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

-- Returns a list of { first, last, value } index ranges where consecutive
-- columns share the same non-nil value for columns[i][field].
local function GroupedSpans(columns, field)
    local spans = {}
    local i = 1
    while i <= #columns do
        local value = columns[i][field]
        if value then
            local last = i
            while columns[last + 1] and columns[last + 1][field] == value do
                last = last + 1
            end
            spans[#spans + 1] = { first = i, last = last, value = value }
            i = last + 1
        else
            i = i + 1
        end
    end
    return spans
end

-- Build one row's cells directly under `container`, anchored at a fixed
-- vertical offset. The table is sized to fit all of them (the page around it
-- scrolls).
local function BuildRow(container, row, columns, yOffset, skill)
    local frame = AcquireRow(container, container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(ROW_HEIGHT)

    -- The first (id/name) column borrows the skill-diff color computed for
    -- the second column, so its color reflects this row's status at a glance
    -- without needing to look further right.
    local nameColor
    local secondCol = columns[2]
    if skill and secondCol then
        local secondValue = row[secondCol.id]
        if type(secondValue) == "number" then
            nameColor = SkillDiffColor(skill - secondValue)
        end
    end

    for i, col in ipairs(columns) do
        local cell = AcquireCell(container, frame)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        LayoutCell(cell, col.width, ROW_HEIGHT)

        local value = row[col.id]

        local tint = value ~= nil and col.background and CELL_BACKGROUND_COLORS[col.background]
        if tint then
            cell.bg:SetAllPoints(cell)
            cell.bg:SetColorTexture(tint[1], tint[2], tint[3], CELL_BACKGROUND_ALPHA)
            cell.bg:Show()
        end

        cell.text:SetJustifyH("LEFT")
        cell.text:SetText(value or "")

        if skill and type(value) == "number" then
            local color = SkillDiffColor(skill - value)
            cell.text:SetTextColor(color[1], color[2], color[3])
        elseif i == 1 and nameColor then
            cell.text:SetTextColor(nameColor[1], nameColor[2], nameColor[3])
        end
    end
end

-- Build the table into an AceGUI SimpleGroup and return it.
function DataTable:Build(parent, options)
    options = options or {}
    local columns = options.columns or {}
    local rows = options.rows or {}

    -- Precompute each column's left x-offset.
    local x = 0
    for _, col in ipairs(columns) do
        col.width = col.width or 80
        col._x = x
        x = x + col.width
    end
    local totalWidth = x

    -- Columns with an `exp` field get a super-header row above the regular
    -- header, merging consecutive columns that share the same value.
    local hasExp = false
    for _, col in ipairs(columns) do
        if col.exp then
            hasExp = true
            break
        end
    end
    local superHeaderHeight = hasExp and HEADER_HEIGHT or 0

    local width = options.width or totalWidth
    local height = superHeaderHeight + HEADER_HEIGHT + (#rows * ROW_HEIGHT)

    -- Container frame hosting header + rows.
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Fill")
    local container = group.frame
    group:SetWidth(width)
    group:SetHeight(height)

    -- Reset this build's usage counters; AcquireRow/AcquireCell reuse
    -- container.rowPool/cellPool from a previous build of this (possibly
    -- recycled) container instead of creating fresh frames.
    container.rowsUsed = 0
    container.cellsUsed = 0

    -- Super header row, merging consecutive columns that share an `exp` value.
    if hasExp then
        local superHeader = AcquireRow(container, container)
        superHeader:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        superHeader:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
        superHeader:SetHeight(superHeaderHeight)
        superHeader.bg:SetAllPoints(superHeader)
        superHeader.bg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
        superHeader.bg:Show()

        for _, span in ipairs(GroupedSpans(columns, "exp")) do
            local first, last = columns[span.first], columns[span.last]
            local cell = AcquireCell(container, superHeader)
            cell:SetPoint("TOPLEFT", superHeader, "TOPLEFT", first._x, 0)
            LayoutCell(cell, (last._x + last.width) - first._x, superHeaderHeight)
            cell.text:SetJustifyH("CENTER")
            cell.text:SetText(span.value)
        end
    end

    -- Header row. Consecutive columns sharing a `group` value are merged into
    -- one cell; columns with neither `group` nor `exp` span both header rows.
    local header = AcquireRow(container, container)
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -superHeaderHeight)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -superHeaderHeight)
    header:SetHeight(HEADER_HEIGHT)
    header.bg:SetAllPoints(header)
    header.bg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    header.bg:Show()

    local i = 1
    while i <= #columns do
        local col = columns[i]
        local cellWidth = col.width
        local cellHeight = HEADER_HEIGHT
        local yOffset = 0
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
        elseif not col.exp then
            -- No header value at either tier: stretch to cover both rows.
            cellHeight = superHeaderHeight + HEADER_HEIGHT
            yOffset = superHeaderHeight
        end

        local cell = AcquireCell(container, header)
        cell:SetPoint("TOPLEFT", header, "TOPLEFT", col._x, yOffset)
        -- The table's very first cell (top-left corner) omits its top/left
        -- edges so it doesn't double up against the surrounding page chrome.
        LayoutCell(cell, cellWidth, cellHeight, i == 1, i == 1)
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
        BuildRow(container, row, columns, -(superHeaderHeight + HEADER_HEIGHT + (idx - 1) * ROW_HEIGHT), skill)
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
