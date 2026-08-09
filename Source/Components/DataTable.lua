--[[-----------------------------------------------------------------------------
DataTable
A reusable columnar table component built on Blizzard's ScrollBox API.

Takes a declarative structure:
    DataTable:Build(parent, {
        width   = 700,          -- optional, default 800
        height  = 300,          -- optional, default 300
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

-- Initializer used by the ScrollBox view for each row element.
-- `data` is the row table, which carries the column layout via `data.columns`.
local function RowInitializer(frame, data)
    local columns = data.columns or {}
    if not frame.cells then
        frame.cells = {}
    end
    for idx, col in ipairs(columns) do
        local cell = frame.cells[idx]
        if not cell then
            -- Each cell is a Frame with a thin border + inner text.
            cell = CreateFrame("Frame", nil, frame)
            frame.cells[idx] = cell
            AddBorder(cell)
            cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cell.text:SetJustifyH("LEFT")
            cell.text:SetPoint("LEFT", PADDING, 0)
            cell.text:SetPoint("RIGHT", -PADDING, 0)
        end
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", col._x, 0)
        cell:SetSize(col.width, ROW_HEIGHT)
        cell.text:SetText(data[col.id] or "")
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

    local width = options.width or 800
    local height = options.height or 300

    -- Container frame hosting header + scrollbox.
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

    -- ScrollBox + scrollbar (the ScrollBox is itself the scroll container).
    local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)

    local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", container, "TOPRIGHT", -2, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -2, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(ROW_HEIGHT)
    view:SetElementInitializer("Button", RowInitializer)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- Attach the column layout to each row so the initializer can read it.
    local dataProvider = CreateDataProvider()
    for _, row in ipairs(rows) do
        row.columns = columns
        dataProvider:Insert(row)
    end
    scrollBox:SetDataProvider(dataProvider, true)

    return group
end
