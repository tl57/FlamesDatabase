local AceGUI = LibStub("AceGUI-3.0")

TabProfessions = {}

-- Build and return the inner tab group widget for the "Professions" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function TabProfessions:Build(parent)
    local tabs = CategoryTabs:New({
        tabs = {
            { value = "mining", text = "Mining" },
        },
    })

    tabs:AddPage("mining", function(p)
        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("List")

        local label = AceGUI:Create("Label")
        label:SetText("Mining content")
        scroll:AddChild(label)

        return scroll
    end)

    -- Return the underlying AceGUI TabGroup widget
    return tabs.widget
end