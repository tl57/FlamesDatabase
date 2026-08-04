FlamesDatabaseCharSV = FlamesDatabaseCharSV or {}
local LOC = FLAMES_LOCALIZATION_STRINGS_EN or {}
local addonName = ...

-- create and register minimap button
function InitMinimapButton()
	local LDBIcon = LibStub("LibDBIcon-1.0")
	local LibDataBroker = LibStub("LibDataBroker-1.1", true)

  local minimapButton = LibDataBroker:NewDataObject(addonName, {
    type = "launcher",
    icon = "Interface\\AddOns\\FlamesDatabase\\Images\\inv_misc_note_02.blp",
    OnClick = function(self, button)
      if button == "LeftButton" then
        ShowMainFrame()
      else
        ShowOptions()
      end
    end,
    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine(addonName)
	  tooltip:AddLine(LOC.minimap_btn_left_click)
	  --tooltip:AddLine(Deathlog_L.minimap_btn_ctrl_click)
	  --tooltip:AddLine(Deathlog_L.minimap_btn_shift_click)
	  tooltip:AddLine(LOC.minimap_btn_right_click .. GAMEOPTIONS_MENU)
    end,
  })

  LDBIcon:Register(addonName, minimapButton, FlamesDatabaseCharSV)
  if debug then print("initialized minimap button") end
end