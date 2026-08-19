Mining = {}

local Recommendations = {
    enchantItemId = 11203,
    enchantItemIconId = 134327,
    materialItemIds = { 11137, 6037 },
    materialItemIconIds = { 132859, 133222 },
}

-- Build and return the content widget for the "Mining" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function Mining:Build(parent)
    local scroll = Functions_Ace:CreateScrollFrame()
    scroll:SetLayout("List")

    GatheringPage:AddHeader(scroll, parent, "Mining", MiningData, Recommendations)

    return scroll
end
