--[[-----------------------------------------------------------------------------
DungeonEntry
Renders the "Dungeon Quests" page content: a dungeon-picker Dropdown and a
Faction-filter Dropdown (see QuestFilters, DungeonQuestData.lua) in one row,
followed by the selected dungeon's level line + (filtered) quest table,
rebuilt in place whenever either selection changes (not one section per
dungeon anymore - see BuildDungeonContent/RebuildContent below). The data
files (DungeonQuestData.lua) hold plain name/minLvl/maxLvl/columns/rows
tables, this just displays them.
-----------------------------------------------------------------------------]]

local AceGUI = LibStub("AceGUI-3.0")

DungeonEntry = {}

-- Row height for every dungeon's quest table (DataTable's default 20px is
-- single-line only; taller here so the NPC column's word-wrap gets a 2nd
-- line without overlapping the row border below).
local RowSize = 24

local DROPDOWN_WIDTH = 250

-- Returns `rows` filtered down to the ones whose Faction is in `filter.show`
-- (see QuestFilters, DungeonQuestData.lua). `filter` is always given a real
-- entry (including "All") by DungeonEntry:Build, so this doesn't need a
-- no-filter fallback.
local function FilterRows(rows, filter)
    local allowed = {}
    for _, faction in ipairs(filter.show) do
        allowed[faction] = true
    end

    local filtered = {}
    for _, row in ipairs(rows) do
        if allowed[row.Faction] then
            filtered[#filtered + 1] = row
        end
    end
    return filtered
end

-- Build the level line + quest table (rows narrowed to `filter`) for
-- `dungeon`, wrapped in one List-layout group so callers can add/remove/
-- release it as a single widget.
local function BuildDungeonContent(parent, dungeon, filter)
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("List")
    group:SetFullWidth(true)

    group:AddChild(GeneralUI:BuildSpacer())

    local levelLabel = AceGUI:Create("Label")
    levelLabel:SetFullWidth(true)
    levelLabel:SetFontObject(GameFontHighlight)
    levelLabel:SetText(("Appropriate levels: %s-%s"):format(dungeon.minLvl, dungeon.maxLvl))
    group:AddChild(levelLabel)

    local rows = FilterRows(dungeon.rows, filter)
    group:AddChild(DataTable:Build(parent, { columns = dungeon.columns, rows = rows, rowHeight = RowSize }))

    return group
end

-- Create a Label + Dropdown pair (not yet attached to anything - the caller
-- adds both to its own row once every pair's width is known). A plain Label
-- beside the control (mirrors GatheringPage.lua's BuildExpansionRadioGroup)
-- rather than Dropdown's own SetLabel, which stacks the label above the
-- control instead of beside it. Returns the label, the dropdown, and the
-- label's measured width (the caller needs it to size the row).
-- `dropdownWidth` defaults to DROPDOWN_WIDTH if omitted.
local function BuildLabeledDropdown(labelText, items, dropdownWidth)
    local label = AceGUI:Create("Label")
    label:SetFontObject(GameFontHighlightLarge)
    label:SetText(labelText)
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetWidth(dropdownWidth or DROPDOWN_WIDTH)
    dropdown:SetList(items)
    -- The Dropdown widget's selected-text FontString (self.text in
    -- AceGUIWidget-DropDown.lua) inherits UIDropDownMenuTemplate's default
    -- CENTER justify; left-align it to match every other label in this addon.
    dropdown.text:SetJustifyH("LEFT")

    return label, dropdown, labelWidth
end

-- Add the Dungeon + Filter by Dropdowns to `scroll`, followed by the
-- selected dungeon's level line + (filtered) quest table. Changing either
-- dropdown releases the old content widget and builds a fresh one in its
-- place (mirrors GatheringPage.lua's RebuildTable). `dungeons` is the full
-- DungeonQuestData array; `parent` is passed through to DataTable:Build
-- unchanged (see DataTable.lua).
function DungeonEntry:Build(scroll, parent, dungeons)
    local names = {}
    for i, dungeon in ipairs(dungeons) do
        names[i] = dungeon.name
    end

    -- Ordered view of QuestFilters (DungeonQuestData.lua) - a plain
    -- key => {name, show} table has no defined pairs() order, so this keeps
    -- the Filter by dropdown's entries in a stable order across rebuilds.
    local filterKeys = {}
    for key in pairs(QuestFilters) do
        filterKeys[#filterKeys + 1] = key
    end
    table.sort(filterKeys)

    local filterNames = {}
    local defaultFilterIndex = 1
    for i, key in ipairs(filterKeys) do
        filterNames[i] = QuestFilters[key].name
        if key == "All" then
            defaultFilterIndex = i
        end
    end

    -- Replaced in place (see RebuildContent) whenever either dropdown's
    -- selection changes, rather than rebuilding the whole page.
    local contentWidget
    local selectedDungeonIndex = 1
    local selectedFilterIndex = defaultFilterIndex

    local function RebuildContent()
        if contentWidget then
            for idx, child in ipairs(scroll.children) do
                if child == contentWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            AceGUI:Release(contentWidget)
        end
        local dungeon = dungeons[selectedDungeonIndex]
        local filter = QuestFilters[filterKeys[selectedFilterIndex]]
        contentWidget = BuildDungeonContent(parent, dungeon, filter)
        scroll:AddChild(contentWidget)
    end

    -- Whole pixels only: Flow's per-child fit check compares this exact
    -- Lua-side number against `width` (see AceGUI-3.0.lua), while the
    -- widget's actual on-screen edge (used to anchor the *next* sibling) is
    -- whatever the frame system settles a fractional SetWidth to - a
    -- fractional value like 250*2/3 here risks drifting out of sync with
    -- that and wrapping a later sibling onto its own row.
    local DUNGEON_DROPDOWN_WIDTH = math.floor(DROPDOWN_WIDTH * 2 / 3)
    local dungeonLabel, dungeonDropdown, dungeonLabelWidth = BuildLabeledDropdown("Dungeon:", names, DUNGEON_DROPDOWN_WIDTH)
    dungeonDropdown:SetCallback("OnValueChanged", function(_, _, index)
        selectedDungeonIndex = index
        RebuildContent()
    end)

    -- Grey out (SetItemDisabled - see AceGUIWidget-DropDown.lua, it also
    -- blocks the item's own OnClick, so a disabled entry can't be picked)
    -- any dungeon with 0 rows under the currently-selected filter. If the
    -- dungeon currently selected is one of them, falls back to the first
    -- dungeon that still has rows instead of leaving an emptied-out
    -- selection in place.
    local function UpdateDungeonAvailability()
        local filter = QuestFilters[filterKeys[selectedFilterIndex]]
        local fallbackIndex
        for i, dungeon in ipairs(dungeons) do
            local empty = #FilterRows(dungeon.rows, filter) == 0
            dungeonDropdown:SetItemDisabled(i, empty)
            if not empty and not fallbackIndex then
                fallbackIndex = i
            end
        end
        if fallbackIndex and #FilterRows(dungeons[selectedDungeonIndex].rows, filter) == 0 then
            selectedDungeonIndex = fallbackIndex
            dungeonDropdown:SetValue(selectedDungeonIndex)
        end
    end

    local FILTER_DROPDOWN_WIDTH = DROPDOWN_WIDTH / 2
    local filterLabel, filterDropdown, filterLabelWidth = BuildLabeledDropdown("Filter by:", filterNames, FILTER_DROPDOWN_WIDTH)
    filterDropdown:SetCallback("OnValueChanged", function(_, _, index)
        selectedFilterIndex = index
        UpdateDungeonAvailability()
        RebuildContent()
    end)

    -- Horizontal gap between the Filter by and Dungeon pairs - just an
    -- empty, fixed-width Flow child, since Flow itself adds no spacing
    -- between children.
    local PAIR_SPACING = 20
    local spacer = AceGUI:Create("Label")
    spacer:SetText("")
    spacer:SetWidth(PAIR_SPACING)

    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    local totalWidth = filterLabelWidth + FILTER_DROPDOWN_WIDTH + PAIR_SPACING + dungeonLabelWidth + DUNGEON_DROPDOWN_WIDTH
    row:SetWidth(totalWidth)
    -- See BuildExpansionRadioGroup's identical line: Flow reads
    -- content.width directly, which SetWidth only updates asynchronously
    -- via the frame's OnSizeChanged - without this a group recycled from
    -- AceGUI's shared SimpleGroup pool can carry over a stale, narrower
    -- width and wrap a dropdown onto its own row.
    row.content.width = totalWidth
    row:AddChild(filterLabel)
    row:AddChild(filterDropdown)
    row:AddChild(spacer)
    row:AddChild(dungeonLabel)
    row:AddChild(dungeonDropdown)
    scroll:AddChild(row)

    dungeonDropdown:SetValue(selectedDungeonIndex)
    filterDropdown:SetValue(selectedFilterIndex)
    UpdateDungeonAvailability()
    RebuildContent()
end
