--[[-----------------------------------------------------------------------------
DungeonEntry
Renders one dungeon's quest table - a collapsible header (collapsed by
default, see GeneralUI:AddCollapsibleSection) that expands into a DataTable -
into a page's scroll frame. The DataTable is only built the first time it's
expanded, not up front, since this list is expected to grow long. The data
files (DungeonQuestData.lua) hold plain name/columns/rows tables, this just
displays them.
-----------------------------------------------------------------------------]]

DungeonEntry = {}

-- Row height for every dungeon's quest table (DataTable's default 20px is
-- single-line only; taller here so the NPC column's word-wrap gets a 2nd
-- line without overlapping the row border below).
local RowSize = 24

-- Add a collapsible section for `dungeon` to `scroll` (see
-- GeneralUI:AddCollapsibleSection). `parent` is passed through to
-- DataTable:Build unchanged (see DataTable.lua).
function DungeonEntry:AddRows(scroll, parent, dungeon)
    GeneralUI:AddCollapsibleSection(scroll, dungeon.name, function()
        return DataTable:Build(parent, { columns = dungeon.columns, rows = dungeon.rows, rowHeight = RowSize })
    end)
end
