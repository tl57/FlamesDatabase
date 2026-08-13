local AceGUI = LibStub("AceGUI-3.0")

Herbalism = {}

local Recommendations = {
    enchantItemId = 11205,
    enchantItemIconId = 134327,
    materialItemIds = { 11137, 8838 },
    materialItemIconIds = { 132859, 134199 },
}

-- Build and return the content widget for the "Herbalism" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function Herbalism:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    GatheringPage:AddHeader(scroll, parent, "Herbalism", HerbalismData, Recommendations)

    return scroll
end
