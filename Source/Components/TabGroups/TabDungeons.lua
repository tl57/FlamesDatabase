TabDungeons = {}

-- Build and return the inner tab group widget for the "Dungeons" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function TabDungeons:Build(parent)
    local tabs = CategoryTabs:New({
        tabs = {
            { value = "dungeonInfo",   text = "Dungeon Info" },
            { value = "dungeonQuests", text = "Dungeon Quests" },
        },
    })

    tabs:AddPage("dungeonInfo", function(p)
        return DungeonInfo:Build(p)
    end)

    tabs:AddPage("dungeonQuests", function(p)
        return DungeonQuests:Build(p)
    end)

    -- Return the underlying AceGUI TabGroup widget
    return tabs.widget
end
