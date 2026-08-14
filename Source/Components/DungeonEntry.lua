--[[-----------------------------------------------------------------------------
DungeonEntry
Renders one dungeon's quest table - name header + DataTable - into a page's
scroll frame. Mirrors GatheringPage.lua's role for Mining/Herbalism: the data
files (DungeonQuestData.lua) hold plain name/columns/rows tables, this just
displays them.
-----------------------------------------------------------------------------]]

local AceGUI = LibStub("AceGUI-3.0")

DungeonEntry = {}

-- Add `dungeon.name`, then a DataTable of `dungeon.columns`/`dungeon.rows`
-- (see DataTable.lua), to `scroll`, followed by a spacer. `parent` is passed
-- through to DataTable:Build unchanged (see DataTable.lua).
function DungeonEntry:AddRows(scroll, parent, dungeon)
    local nameLbl = AceGUI:Create("Label")
    nameLbl:SetFullWidth(true)
    nameLbl:SetFontObject(GameFontHighlightLarge)
    nameLbl:SetText(dungeon.name)
    scroll:AddChild(nameLbl)

    scroll:AddChild(DataTable:Build(parent, { columns = dungeon.columns, rows = dungeon.rows }))

    scroll:AddChild(GeneralUI:BuildSpacer())
end
