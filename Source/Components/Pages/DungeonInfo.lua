local AceGUI = LibStub("AceGUI-3.0")

DungeonInfo = {}

local Dungeons = {
    RagefireChasmInfo,
    DeadminesInfo,
}

-- Add a Label showing `text` to `scroll`.
local function AddInfoRow(scroll, text)
    local lbl = AceGUI:Create("Label")
    lbl:SetFullWidth(true)
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetText(text)
    scroll:AddChild(lbl)
end

-- Build and return the content widget for the "Dungeon Info" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function DungeonInfo:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    for _, dungeon in ipairs(Dungeons) do
        local nameLbl = AceGUI:Create("Label")
        nameLbl:SetFullWidth(true)
        nameLbl:SetFontObject(GameFontHighlightLarge)
        nameLbl:SetText(dungeon.name)
        scroll:AddChild(nameLbl)

        AddInfoRow(scroll, ("Zone ID: %s"):format(dungeon.zoneid or "?"))
        AddInfoRow(scroll, ("Mob Levels: %s-%s"):format(dungeon.minMobLevel or "?", dungeon.maxMobLevel or "?"))
        AddInfoRow(scroll, ("Boss Levels: %s"):format(table.concat(dungeon.bossLevels or {}, ", ")))

        scroll:AddChild(GeneralUI:BuildSpacer())
    end

    return scroll
end
