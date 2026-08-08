local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...
-- load account-wide saved variables
FlamesDatabase = FlamesDatabase or {}
-- get current addon version
local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
-- debug variable
debug = true
print("FlamesDatabase loaded!")

-- changelog frame
local function ShowChangeLog()
    if debug then print("showing changelog") end
    showChangeLogFrame()
    if debug then print("finished showing changelog") end
    FlamesDatabase.settings.changelogVersion = version
    FlamesDatabase.settings.shownChangeLog = true
    FlamesDatabase.settings.shownNewInstall = true
    FlamesDatabase.settings.changelogVersion = version
end

local function ShowNewInstall()
    FlamesDatabase.settings.shownNewInstall = true
    if debug then print("showing new install dialog") end
end

-- keep saved variables check inside an initialize method
-- (and call it after the addon has initialized, because 
-- otherwise the saved vars are null)
local function Initialize()
    if not FlamesDatabase then
        FlamesDatabase = {}
        if debug then print("created new vars file") end
    end
    
    if not FlamesDatabase.settings then
        FlamesDatabase.settings = {
            changelogVersion = version,
            showChangeLog = true,
            showNewInstall = true,
            shownChangeLog = false,
            shownNewInstall = false
        }
        if debug then print("inited new vars") end
    end
    
    if FlamesDatabase.settings.changelogVersion ~= version and FlamesDatabase.settings.showChangeLog then
        ShowChangeLog()
        if debug then print("show changelog dialog") end
    elseif FlamesDatabase.settings.showNewInstall and not FlamesDatabase.settings.shownNewInstall then
        ShowNewInstall()
    end
end

function OnEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize() -- Call the init function here
        InitMinimapButton() -- Initialize the minimap button
        if debug then print("debugging") end
    end
end

function ShowMainFrame()
    if debug then print("showing main frame") end
    showMainFrame()
    if debug then print("finish showing main frame") end
end
------------------------------------------------------------
-- MAIN UI FRAME
------------------------------------------------------------
print("creating event")
local invis_frame = CreateFrame("Frame")
invis_frame:RegisterEvent("PLAYER_LOGIN")
invis_frame:SetScript("OnEvent", OnEvent)
print("registered event")
