--[[-----------------------------------------------------------------------------
DungeonEntry
Renders one dungeon's quest table - a collapsible header (collapsed by
default) that expands into a DataTable - into a page's scroll frame. The
DataTable is only built the first time it's expanded, not up front, since
this list is expected to grow long. The data files (DungeonQuestData.lua)
hold plain name/columns/rows tables, this just displays them.
-----------------------------------------------------------------------------]]

local AceGUI = LibStub("AceGUI-3.0")

DungeonEntry = {}

local COLLAPSED_PREFIX = "+ "
local EXPANDED_PREFIX  = "- "

-- Add a collapsible header for `dungeon` to `scroll`, followed by a spacer.
-- Clicking the header toggles a DataTable of `dungeon.columns`/`dungeon.rows`
-- (see DataTable.lua) in and out, right below it. `parent` is passed through
-- to DataTable:Build unchanged (see DataTable.lua).
function DungeonEntry:AddRows(scroll, parent, dungeon)
    local expanded = false
    local tableWidget

    local header = AceGUI:Create("InteractiveLabel")
    header:SetFullWidth(true)
    header:SetFontObject(GameFontHighlightLarge)
    header:SetText(COLLAPSED_PREFIX .. dungeon.name)

    local spacer = GeneralUI:BuildSpacer()

    header:SetCallback("OnClick", function()
        expanded = not expanded
        header:SetText((expanded and EXPANDED_PREFIX or COLLAPSED_PREFIX) .. dungeon.name)

        if expanded then
            tableWidget = DataTable:Build(parent, { columns = dungeon.columns, rows = dungeon.rows })
            -- beforeWidget = spacer inserts the table between the header and
            -- the trailing spacer (AddChild triggers DoLayout itself).
            scroll:AddChild(tableWidget, spacer)
        elseif tableWidget then
            -- Same removal idiom as GatheringPage.lua's RebuildTable: pull
            -- the widget out of scroll.children directly (AceGUI has no
            -- RemoveChild), then release it and reflow.
            for idx, child in ipairs(scroll.children) do
                if child == tableWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            AceGUI:Release(tableWidget)
            tableWidget = nil
            scroll:DoLayout()
        end
    end)

    scroll:AddChild(header)
    scroll:AddChild(spacer)
end
