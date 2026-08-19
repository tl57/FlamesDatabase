local addonName = ...

local changelog_frame = nil -- singleton: created once

function showChangeLogFrame()
	if changelog_frame then
		if changelog_frame.frame:IsShown() then
			changelog_frame.frame:Hide()
		else
			changelog_frame:Show()
		end
		return
	end

	local currentVersion = Functions_General:GetAddonMetadata(addonName, "Version")
	-- FlamesDatabase.settings.changelogVersion still holds the version the user
	-- was on before this update at this point - main.lua only overwrites it
	-- with currentVersion after showChangeLogFrame() returns.
	local sinceVersion = FlamesDatabase.settings and FlamesDatabase.settings.changelogVersion
	local entries = Functions_General:GetEntriesSince(ChangelogData, sinceVersion)

	changelog_frame = Functions_Ace:CreateDialog() ---@type AceGUIFrame
	changelog_frame:SetTitle(addonName)
	changelog_frame:SetStatusText("Version " .. currentVersion)
	changelog_frame:SetLayout("Fill")
	changelog_frame:SetWidth(500)
	changelog_frame:SetHeight(450)
	changelog_frame:SetCallback("OnClose", function(widget)
		Functions_Ace:ReleaseWidget(widget)
		changelog_frame = nil
	end)

	local scrollFrame = Functions_Ace:CreateScrollFrame() ---@type AceGUIScrollFrame
	scrollFrame:SetLayout("Flow")
	changelog_frame:AddChild(scrollFrame)

	if #entries == 0 then
		local label = Functions_Ace:CreateLabel() ---@type AceGUILabel
		label:SetText("No changes to show.")
		label:SetFullWidth(true)
		scrollFrame:AddChild(label)
	end

	for _, entry in ipairs(entries) do
		local versionHeading = Functions_Ace:CreateHeading() ---@type AceGUIHeading
		versionHeading:SetText("Version " .. entry.version)
		versionHeading:SetFullWidth(true)
		scrollFrame:AddChild(versionHeading)

		for _, change in ipairs(entry.changes) do
			local line = Functions_Ace:CreateLabel() ---@type AceGUILabel
			line:SetText("[" .. change.category .. "] " .. change.text)
			line:SetFullWidth(true)
			scrollFrame:AddChild(line)
		end
	end

	if debug then print("finished changelog code") end
end
