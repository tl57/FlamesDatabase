local AceGUI = LibStub("AceGUI-3.0")

DungeonQuests = {}

local Dungeons = {
    RagefireChasmQuests,
    DeadminesQuests,
}

-- Build and return the content widget for the "Dungeon Quests" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function DungeonQuests:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    for _, dungeon in ipairs(Dungeons) do
        DungeonEntry:AddRows(scroll, parent, dungeon)
    end

    return scroll
end
