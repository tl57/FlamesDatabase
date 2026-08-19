Functions_Ace = {}

-- Kept private (not exposed as a field) - every other file goes through the
-- wrapper methods below (CreateLabel/CreateGroup/ReleaseWidget/etc.) instead
-- of calling LibStub or the AceGUI API directly, so this is the one place in
-- the addon that knows AceGUI-3.0 is the library behind them, or that any of
-- these widget-type strings ("Label", "SimpleGroup", ...) exist at all. This
-- file loads immediately after embeds.xml (see FlamesDatabase.toc) - before
-- every other file, including AceGUIWidget-FlamesDataTable.lua which
-- registers its widget type at file-load time - so those wrappers are
-- always available by the time anything else needs them.
local AceGUI = LibStub("AceGUI-3.0")

-- Creates a resizable top-level window (the main addon window - see mainframe.lua).
function Functions_Ace:CreateWindow()
    return AceGUI:Create("Window")
end

-- Creates a top-level popup dialog (title + status text + close button -
-- see welcomeframe.lua/changelogframe.lua).
function Functions_Ace:CreateDialog()
    return AceGUI:Create("Frame")
end

-- Creates a scrollable content area.
function Functions_Ace:CreateScrollFrame()
    return AceGUI:Create("ScrollFrame")
end

-- Creates a plain text label.
function Functions_Ace:CreateLabel()
    return AceGUI:Create("Label")
end

-- Creates a clickable text label (see GeneralUI:AddCollapsibleSection's header).
function Functions_Ace:CreateInteractiveLabel()
    return AceGUI:Create("InteractiveLabel")
end

-- Creates a section-heading label (see changelogframe.lua's per-version headings).
function Functions_Ace:CreateHeading()
    return AceGUI:Create("Heading")
end

-- Creates a plain, unstyled container that lays out its own children.
function Functions_Ace:CreateGroup()
    return AceGUI:Create("SimpleGroup")
end

-- Creates a dropdown/select control.
function Functions_Ace:CreateDropdown()
    return AceGUI:Create("Dropdown")
end

-- Creates a tabbed container widget (see CategoryTabs.lua).
function Functions_Ace:CreateTabGroup()
    return AceGUI:Create("TabGroup")
end

-- Creates the addon's own pooled-table container widget - a dedicated
-- registered type (see AceGUIWidget-FlamesDataTable.lua, DataTable.lua)
-- rather than a stock "SimpleGroup", so AceGUI never hands this frame's pool
-- to (or from) any unrelated widget in the addon.
function Functions_Ace:CreateDataTableWidget()
    return AceGUI:Create("FlamesDataTable")
end

-- Releases an AceGUI widget back to its type's pool.
function Functions_Ace:ReleaseWidget(widget)
    AceGUI:Release(widget)
end

-- Registers a plain widget table (frame + methods) as a usable AceGUI
-- widget instance. Used by custom widget-type constructors (see
-- AceGUIWidget-FlamesDataTable.lua) - returns the same widget, now
-- AceGUI-aware.
function Functions_Ace:RegisterAsWidget(widget)
    return AceGUI:RegisterAsWidget(widget)
end

-- Registers a custom AceGUI widget type (see AceGUIWidget-FlamesDataTable.lua).
function Functions_Ace:RegisterWidgetType(widgetType, constructor, version)
    AceGUI:RegisterWidgetType(widgetType, constructor, version)
end

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
