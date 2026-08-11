local AceGUI = LibStub("AceGUI-3.0")
local addonName = ...
local main_container = nil -- singleton: created once
-- think about focusing a specific frame when having a profession open or in a specific dungeon

function toggleMainFrame()
	-- think about making the frame a singleton
	if (main_container and main_container.frame:IsShown()) then
		main_container.frame:Hide()
		if debug then print("hidden mainframe") end
		return
	end

	if (not main_container) then
		main_container = AceGUI:Create("Window")
		main_container:SetTitle(addonName)
		main_container:SetLayout("Fill")
		main_container:SetWidth(800)
		main_container:SetHeight(450)

		--[[
		-- Full black background covering the content area
		local bg = main_container.frame:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(main_container.content)
		bg:SetColorTexture(0, 0, 0, 1)
		]]

		-- two different ways to close the widget
		-- none of them are required due to the OnKeyDown register a bit down the code.
		-- (Otherwise it will throw an exception - "double window.hide()")
		--main_container:SetCallback("OnClose", function(widget) AceGUI:Release(widget); main_container = nil end)
		--main_container:SetCallback("OnClose", function(widget)
		--	widget.Hide()
		--end)

		-- ESC to close via OnKeyDown (needs keyboard enabled)
		main_container.frame:EnableKeyboard(true)
		main_container.frame:SetPropagateKeyboardInput(true)
		main_container.frame:SetScript("OnKeyDown", function(self, key)
			if key == "ESCAPE" then self:Hide() end
		end)

		-- Tab tree (and everything under it, e.g. Mining's DataTable) is built
		-- once here and reused on subsequent opens via Show/Hide below, instead
		-- of being rebuilt from scratch - and leaked - on every toggle.
		local tabs = CategoryTabs:New({
			parent = main_container,
			tabs = {
				{ value = "Professions", text = "Professions" },
				{ value = "spells",      text = "Spells" },
				{ value = "items",       text = "Items" },
			},
		})
		tabs:AddPage("Professions", TabProfessions.Build)
	end
	main_container:Show()

	if debug then print("finished showing mainframe code") end
end
