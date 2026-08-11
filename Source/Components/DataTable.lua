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

-- Draw a thin border around a frame using 4 edge textures.
local function AddBorder(frame)
    local edges = {}
    for i = 1, 4 do
        local tex = frame:CreateTexture(nil, "BORDER")
        tex:SetColorTexture(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
        edges[i] = tex
    end
    local t = BORDER_THICKNESS
    -- top
    edges[1]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges[1]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges[1]:SetHeight(t)
    -- bottom
    edges[2]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges[2]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges[2]:SetHeight(t)
    -- left
    edges[3]:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edges[3]:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edges[3]:SetWidth(t)
    -- right
    edges[4]:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edges[4]:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edges[4]:SetWidth(t)
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
-- vertical offset. No pooling/virtualization: every row gets its own frame,
-- and the table is sized to fit all of them (the page around it scrolls).
local function BuildRow(container, row, columns, yOffset, skill)
    local frame = CreateFrame("Frame", nil, container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(ROW_HEIGHT)

    for _, col in ipairs(columns) do
        local cell = CreateFrame("Frame", nil, frame)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        cell:SetSize(col.width, ROW_HEIGHT)

        local tint = col.background and CELL_BACKGROUND_COLORS[col.background]
        if tint then
            local bg = cell:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(cell)
            bg:SetColorTexture(tint[1], tint[2], tint[3], CELL_BACKGROUND_ALPHA)
        end

        AddBorder(cell)

        local value = row[col.id]
        local text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetJustifyH("LEFT")
        text:SetPoint("LEFT", PADDING, 0)
        text:SetPoint("RIGHT", -PADDING, 0)
        text:SetText(value or "")

        if skill and type(value) == "number" then
            local color = SkillDiffColor(skill - value)
            text:SetTextColor(color[1], color[2], color[3])
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
    container:SetWidth(width)
    container:SetHeight(height)

    -- Super header row, merging consecutive columns that share an `exp` value.
    if hasExp then
        local superHeader = CreateFrame("Frame", nil, container)
        superHeader:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        superHeader:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
        superHeader:SetHeight(superHeaderHeight)
        local superHeaderBg = superHeader:CreateTexture(nil, "BACKGROUND")
        superHeaderBg:SetAllPoints(superHeader)
        superHeaderBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)

        for _, span in ipairs(GroupedSpans(columns, "exp")) do
            local first, last = columns[span.first], columns[span.last]
            local cell = CreateFrame("Frame", nil, superHeader)
            cell:SetPoint("TOPLEFT", superHeader, "TOPLEFT", first._x, 0)
            cell:SetSize((last._x + last.width) - first._x, superHeaderHeight)
            AddBorder(cell)
            local fs = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetJustifyH("CENTER")
            fs:SetText(span.value)
            fs:SetPoint("LEFT", PADDING, 0)
            fs:SetPoint("RIGHT", -PADDING, 0)
        end
    end

    -- Header row. Consecutive columns sharing a `group` value are merged into
    -- one cell; columns with neither `group` nor `exp` span both header rows.
    local header = CreateFrame("Frame", nil, container)
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -superHeaderHeight)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -superHeaderHeight)
    header:SetHeight(HEADER_HEIGHT)
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(header)
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)

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

        local cell = CreateFrame("Frame", nil, header)
        cell:SetPoint("TOPLEFT", header, "TOPLEFT", col._x, yOffset)
        cell:SetSize(cellWidth, cellHeight)
        AddBorder(cell)
        local fs = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetJustifyH(justify)
        fs:SetText(label or "")
        fs:SetPoint("LEFT", PADDING, 0)
        fs:SetPoint("RIGHT", -PADDING, 0)

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

    return group
end
