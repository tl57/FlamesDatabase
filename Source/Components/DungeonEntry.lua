--[[-----------------------------------------------------------------------------
DungeonEntry
Renders the "Dungeon Quests" page content: a dungeon-picker Dropdown followed
by the selected dungeon's level line + quest table, rebuilt in place whenever
the selection changes (not one section per dungeon anymore - see
BuildDungeonContent/SelectDungeon below). The data files (DungeonQuestData.lua)
hold plain name/minLvl/maxLvl/columns/rows tables, this just displays them.
-----------------------------------------------------------------------------]]

local AceGUI = LibStub("AceGUI-3.0")

DungeonEntry = {}

-- Row height for every dungeon's quest table (DataTable's default 20px is
-- single-line only; taller here so the NPC column's word-wrap gets a 2nd
-- line without overlapping the row border below).
local RowSize = 24

local DROPDOWN_WIDTH = 250

-- Build the level line + quest table for `dungeon`, wrapped in one
-- List-layout group so callers can add/remove/release it as a single widget.
local function BuildDungeonContent(parent, dungeon)
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("List")
    group:SetFullWidth(true)

    group:AddChild(GeneralUI:BuildSpacer())

    local levelLabel = AceGUI:Create("Label")
    levelLabel:SetFullWidth(true)
    levelLabel:SetFontObject(GameFontHighlight)
    levelLabel:SetText(("Appropriate levels: %s-%s"):format(dungeon.minLvl, dungeon.maxLvl))
    group:AddChild(levelLabel)

    group:AddChild(DataTable:Build(parent, { columns = dungeon.columns, rows = dungeon.rows, rowHeight = RowSize }))

    return group
end

-- Add a dungeon-picker Dropdown to `scroll`, followed by the selected
-- dungeon's level line + quest table. Picking a different dungeon releases
-- the old content widget and builds a fresh one in its place (mirrors
-- GatheringPage.lua's RebuildTable). `dungeons` is the full DungeonQuestData
-- array; `parent` is passed through to DataTable:Build unchanged (see
-- DataTable.lua).
function DungeonEntry:Build(scroll, parent, dungeons)
    local names = {}
    for i, dungeon in ipairs(dungeons) do
        names[i] = dungeon.name
    end

    -- Replaced in place (see SelectDungeon) whenever the dropdown's
    -- selected dungeon changes, rather than rebuilding the whole page.
    local contentWidget

    local function SelectDungeon(index)
        if contentWidget then
            for idx, child in ipairs(scroll.children) do
                if child == contentWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            AceGUI:Release(contentWidget)
        end
        contentWidget = BuildDungeonContent(parent, dungeons[index])
        scroll:AddChild(contentWidget)
    end

    -- A Flow-layout row (mirrors GatheringPage.lua's BuildExpansionRadioGroup)
    -- rather than Dropdown's own SetLabel, which stacks the label above the
    -- control instead of beside it.
    local label = AceGUI:Create("Label")
    label:SetFontObject(GameFontHighlightLarge)
    label:SetText("Dungeon:")
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetWidth(DROPDOWN_WIDTH)
    dropdown:SetList(names)
    -- The Dropdown widget's selected-text FontString (self.text in
    -- AceGUIWidget-DropDown.lua) inherits UIDropDownMenuTemplate's default
    -- CENTER justify; left-align it to match every other label in this addon.
    dropdown.text:SetJustifyH("LEFT")
    dropdown:SetCallback("OnValueChanged", function(_, _, index)
        SelectDungeon(index)
    end)

    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    local totalWidth = labelWidth + DROPDOWN_WIDTH
    row:SetWidth(totalWidth)
    -- See BuildExpansionRadioGroup's identical line: Flow reads
    -- content.width directly, which SetWidth only updates asynchronously
    -- via the frame's OnSizeChanged - without this a group recycled from
    -- AceGUI's shared SimpleGroup pool can carry over a stale, narrower
    -- width and wrap the dropdown onto its own row.
    row.content.width = totalWidth
    row:AddChild(label)
    row:AddChild(dropdown)
    scroll:AddChild(row)

    dropdown:SetValue(1)
    SelectDungeon(1)
end
