TabProfessions = {}

-- Build and return the inner tab group widget for the "Professions" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function TabProfessions:Build(parent)
    local tabs = CategoryTabs:New({
        tabs = {
            { value = "mining",      text = "Mining" },
            { value = "herbalism",   text = "Herbalism" },
            { value = "prospecting", text = "Prospecting" },
        },
    })

    tabs:AddPage("mining", function(p)
        return Mining:Build(p)
    end)

    tabs:AddPage("herbalism", function(p)
        return Herbalism:Build(p)
    end)

    tabs:AddPage("prospecting", function(p)
        return Prospecting:Build(p)
    end)

    -- Return the underlying AceGUI TabGroup widget
    return tabs.widget
end