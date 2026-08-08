local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...
-- think about focusing a specific frame when having a profession open or in a specific dungeon

function showMainFrame()
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

-- The status bar button is NOT stored on the AceGUI Frame widget (only its
	-- child fontstring `statustext` is). The bar is that fontstring's parent.
	main_frame.statustext:GetParent():Hide()   -- hides the status bar

	if debug then print("finished mainframe code") end
end