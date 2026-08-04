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
  },
}

LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, options)
local _, fdatabase_settings_category_id = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName, nil)

-- call options
function ShowOptions()
  if debug then print("opening options") end
	if Settings and Settings.OpenToCategory and fdatabase_settings_category_id then
		local ok = pcall(Settings.OpenToCategory, fdatabase_settings_category_id)
		if ok then
			return
		end
	end
	LibStub("AceConfigDialog-3.0"):Open(addonName)
end