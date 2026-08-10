--[[-----------------------------------------------------------------------------
DataTable
A reusable columnar table component. Sized to fit all of its rows; relies on
the surrounding page to provide scrolling if the table doesn't fit.

Takes a declarative structure:
    DataTable:Build(parent, {
        width   = 700,          -- optional, default is the sum of column widths
        columns = {
            { id = "Name", width = 200 },
            { id = "OrangeClassicMine", width = 60 },
            ...
        },
        rows = {
            { Name = "Copper Vein", OrangeClassicMine = 1, ... },
            ...
        },
    })

Rows are keyed by column id. Values that are nil render as empty cells.
Headers use column.title if provided, else the column id.

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

-- Build one row's cells directly under `container`, anchored at a fixed
-- vertical offset. No pooling/virtualization: every row gets its own frame,
-- and the table is sized to fit all of them (the page around it scrolls).
local function BuildRow(container, row, columns, yOffset)
    local frame = CreateFrame("Frame", nil, container)
    frame:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
    frame:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, yOffset)
    frame:SetHeight(ROW_HEIGHT)

    for _, col in ipairs(columns) do
        local cell = CreateFrame("Frame", nil, frame)
        AddBorder(cell)
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        cell:SetSize(col.width, ROW_HEIGHT)

        local text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetJustifyH("LEFT")
        text:SetPoint("LEFT", PADDING, 0)
        text:SetPoint("RIGHT", -PADDING, 0)
        text:SetText(row[col.id] or "")
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

    local width = options.width or totalWidth
    local height = HEADER_HEIGHT + (#rows * ROW_HEIGHT)

    -- Container frame hosting header + rows.
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Fill")
    local container = group.frame
    container:SetWidth(width)
    container:SetHeight(height)

    -- Header row.
    local header = CreateFrame("Frame", nil, container)
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_HEIGHT)
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(header)
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
    for _, col in ipairs(columns) do
        -- Header cell with thin border, matching the data cells.
        local cell = CreateFrame("Frame", nil, header)
        cell:SetPoint("TOPLEFT", header, "TOPLEFT", col._x, 0)
        cell:SetSize(col.width, HEADER_HEIGHT)
        AddBorder(cell)
        local fs = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetJustifyH("LEFT")
        fs:SetText(col.title or col.name)
        fs:SetPoint("LEFT", PADDING, 0)
        fs:SetPoint("RIGHT", -PADDING, 0)
    end

    -- Rows, stacked directly below the header. No inner scrollbar: the page
    -- around this table already scrolls, so the table is just as tall as its data.
    for idx, row in ipairs(rows) do
        BuildRow(container, row, columns, -(HEADER_HEIGHT + (idx - 1) * ROW_HEIGHT))
    end

    return group
end
