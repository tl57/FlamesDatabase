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
        return Mining:Build(p)
    end)

    -- Return the underlying AceGUI TabGroup widget
    return tabs.widget
end