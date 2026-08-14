local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...

local welcome_frame = nil -- singleton: created once

function showWelcomeFrame()
	if welcome_frame then
		if welcome_frame.frame:IsShown() then
			welcome_frame.frame:Hide()
		else
			welcome_frame:Show()
		end
		return
	end

end