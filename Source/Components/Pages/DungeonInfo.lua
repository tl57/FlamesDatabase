local AceGUI = LibStub("AceGUI-3.0")

DungeonInfo = {}

local Dungeons = {
    RagefireChasmInfo,
    DeadminesInfo,
}

-- Add a Label showing `text` to `container`.
local function AddInfoRow(container, text)
    local lbl = AceGUI:Create("Label")
    lbl:SetFullWidth(true)
    lbl:SetFontObject(GameFontHighlight)
    lbl:SetText(text)
    container:AddChild(lbl)
end

-- Build and return the content widget (zone id, mob levels, one row per
-- boss) for `dungeon`.
local function BuildInfoContent(dungeon)
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("List")
    group:SetFullWidth(true)

    AddInfoRow(group, ("Zone ID: %s"):format(dungeon.zoneid or "?"))
    AddInfoRow(group, ("Mob Levels: %s-%s"):format(dungeon.minMobLevel or "?", dungeon.maxMobLevel or "?"))

    AddInfoRow(group, "Boss Levels:")
    for _, boss in ipairs(dungeon.bosses or {}) do
        AddInfoRow(group, ("%s: %s"):format(boss.name, boss.level))
    end

    return group
end

-- Build and return the content widget for the "Dungeon Info" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function DungeonInfo:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    for _, dungeon in ipairs(Dungeons) do
        GeneralUI:AddCollapsibleSection(scroll, dungeon.name, function()
            return BuildInfoContent(dungeon)
        end)
    end

    return scroll
end
