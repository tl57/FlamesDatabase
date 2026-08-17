FlamesDatabase = FlamesDatabase or {}
local addonName = ...
local options = {
  name = addonName,
  type = "group",
  args = {
    header = {
      order = 1,
      type = "header",
      name = addonName,
    },
    showChangeLog = {
      order = 2,
      type = "toggle",
      name = "Show Changelog after an update",
      desc = "Automatically show the changelog window when the addon updates to a new version.",
      get = function(info) return FlamesDatabase.settings.showChangeLog end,
      set = function(info, value) FlamesDatabase.settings.showChangeLog = value end,
    },
  },
}

local fdatabase_settings_category_id

-- register the Blizzard options panel entry
-- (deferred until PLAYER_LOGIN; calling AddToBlizOptions this early during addon load
-- can hit the Settings API before it's fully initialized)
function InitializeOptions()
  Functions_Ace:RegisterOptionsTable(addonName, options)
  local _, categoryID = Functions_Ace:AddToBlizOptions(addonName, addonName, nil)
  fdatabase_settings_category_id = categoryID
end

-- call options
function ShowOptions()
  if debug then print("opening options") end
	if Functions_Ace:OpenToCategory(fdatabase_settings_category_id) then
		return
	end
	Functions_Ace:OpenStandalone(addonName)
end