Functions_Ace = {}

-- Registers an options table with AceConfig-3.0.
function Functions_Ace:RegisterOptionsTable(appName, options)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(appName, options)
end

-- Adds a registered options table to the Blizzard Options/Settings panel.
-- Returns the container frame and the settings category ID (if any).
function Functions_Ace:AddToBlizOptions(appName, name, parent)
    return LibStub("AceConfigDialog-3.0"):AddToBlizOptions(appName, name, parent)
end

-- Opens the standalone AceConfigDialog popup window for the given app.
function Functions_Ace:OpenStandalone(appName)
    LibStub("AceConfigDialog-3.0"):Open(appName)
end

-- Opens the Blizzard Settings panel to the given category ID.
-- Returns true on success, false if unavailable or the attempt failed.
function Functions_Ace:OpenToCategory(categoryID)
    if not (Settings and Settings.OpenToCategory and categoryID) then
        return false
    end
    return pcall(Settings.OpenToCategory, categoryID)
end
