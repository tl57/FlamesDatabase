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
		main_container = Functions_Ace:CreateWindow()
		main_container:SetTitle(addonName)
		main_container:SetLayout("Fill")
		main_container:SetWidth(770)
		main_container:SetHeight(450)

		-- Floor the resizable width at the default (AceGUI's own Window
		-- widget defaults to a 240px minimum, which is narrower than
		-- Mining's DataTable). The ScrollFrame only scrolls vertically,
		-- so there's no way to reach content narrower than the window;
		-- keeping width >= 800 avoids the table ever getting clipped.
		if main_container.frame.SetResizeBounds then
			main_container.frame:SetResizeBounds(770, 240)
		else
			main_container.frame:SetMinResize(770, 240)
		end

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

		-- main_container's "Fill" layout only ever positions children[1] -
		-- to stack the global expansion dropdown + separator above the tabs
		-- while still having the tabs fill the remaining height, `shell` is
		-- that single child, with its own layout disabled (SetLayout(nil) -
		-- AceGUI:GetLayout(nil) returns nil, and PerformLayout's safecall on
		-- a nil LayoutFunc is a no-op) so the 3 regions below are positioned
		-- by hand instead of via AceGUI's List/Flow layouts, neither of which
		-- can express "two fixed-height rows, then a widget that fills what's
		-- left". shell itself still gets stretched to the full window by
		-- main_container's own "Fill" layout, so this whole stack stays
		-- resize-safe via the same anchor chain the lone tabs widget relied
		-- on before. shell is never released, so its nil layout can't leak
		-- into an unrelated SimpleGroup recycled from the shared pool.
		local shell = Functions_Ace:CreateGroup()
		main_container:AddChild(shell)
		shell:SetLayout(nil)

		local ROW_SPACING = 12 -- matches GeneralUI:BuildSpacer's existing gap

		local levels, names = Functions_ExpansionState:GetAvailableLevels()
		local headerRow, dropdown = GeneralUI:BuildLabeledDropdownRow(
			"Current Expansion Data:", names, levels, 160)
		dropdown:SetValue(Functions_ExpansionState:GetLevel())
		dropdown:SetCallback("OnValueChanged", function(_, _, level)
			Functions_ExpansionState:SetLevel(level)
		end)
		shell:AddChild(headerRow)
		headerRow.frame:ClearAllPoints()
		headerRow.frame:SetPoint("TOPLEFT", shell.content, "TOPLEFT", 0, 0)

		-- Blank Heading = a pure full-width divider line (its OnAcquire
		-- already sets SetFullWidth/SetHeight(18) with no text).
		local separator = Functions_Ace:CreateHeading()
		shell:AddChild(separator)
		separator.frame:ClearAllPoints()
		separator.frame:SetPoint("TOPLEFT", headerRow.frame, "BOTTOMLEFT", 0, -ROW_SPACING)
		separator.frame:SetPoint("RIGHT", shell.content, "RIGHT", 0, 0)

		-- Tab tree (and everything under it, e.g. Mining's DataTable) is built
		-- once here and reused on subsequent opens via Show/Hide below, instead
		-- of being rebuilt from scratch - and leaked - on every toggle.
		local tabs = CategoryTabs:New({
			parent = shell,
			tabs = {
				{ value = "Professions", text = "Professions" },
				{ value = "Dungeons",    text = "Dungeons" },
			},
		})
		tabs.widget.frame:ClearAllPoints()
		tabs.widget.frame:SetPoint("TOPLEFT", separator.frame, "BOTTOMLEFT", 0, -ROW_SPACING)
		tabs.widget.frame:SetPoint("BOTTOMRIGHT", shell.content, "BOTTOMRIGHT", 0, 0)

		tabs:AddPage("Professions", TabProfessions.Build)
		tabs:AddPage("Dungeons", TabDungeons.Build)
	end
	main_container:Show()

	if debug then print("finished showing mainframe code") end
end
