local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...
-- think about focusing a specific frame when having a profession open or in a specific dungeon

function showChangeLogFrame()
    --local changelog = AceGUI:Create("Frame") ---@type AceGUIFrame
    --frame:RegisterEvent("PLAYER_LOGIN")
    --frame:SetScript("OnEvent", function(self, event, ...)
    --changelog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    --changelog:SetSize(400, 400)
    --changelog:SetTitle("todo")
    --changelog:SetCallback("OnClose", function(widget)
        --AceGUI:Release(widget)
        --changelog = nil
    --end)
	-- think about making the frame a singleton
	local main_frame = AceGUI:Create("Frame")
	main_frame:SetTitle(addonName)
	main_frame:SetStatusText("Version ...")
	main_frame:SetLayout("Fill")
	main_frame:SetWidth(500)
	main_frame:SetHeight(450)
	main_frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget); main_frame = nil end)
	local scrollFrame = AceGUI:Create("ScrollFrame") scrollFrame:SetLayout("Flow")
	main_frame:AddChild(scrollFrame)
	scrollFrame:AddChild(AceGUI:Create("Label")) -- etc.


	if debug then print("finished changelog code") end
end