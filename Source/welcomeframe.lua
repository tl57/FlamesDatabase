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

	welcome_frame = AceGUI:Create("Frame") ---@type AceGUIFrame
	welcome_frame:SetTitle(addonName)
	local currentVersion = Functions_General:GetAddonMetadata(addonName, "Version")
	welcome_frame:SetStatusText("Version " .. currentVersion)
	welcome_frame:SetLayout("Fill")
	welcome_frame:SetWidth(500)
	welcome_frame:SetHeight(450)
	welcome_frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		welcome_frame = nil
	end)

	local scrollFrame = AceGUI:Create("ScrollFrame") ---@type AceGUIScrollFrame
	scrollFrame:SetLayout("Flow")
	welcome_frame:AddChild(scrollFrame)

	local title = AceGUI:Create("Label") ---@type AceGUILabel
	title:SetText("Welcome to FlamesDatabase!")
	title:SetFontObject(GameFontHighlightHuge)
	title:SetJustifyH("CENTER")
	title:SetFullWidth(true)
	scrollFrame:AddChild(title)

	local description = AceGUI:Create("Label") ---@type AceGUILabel
	description:SetText("FlamesDatabase provides with a lot of information that is only available out of the game, such as Mining and Herbalism skill levels and zones, or Dungeon information. Much of this information is separated by expansion.")
	description:SetFontObject(GameFontHighlight)
	description:SetFullWidth(true)
	scrollFrame:AddChild(description)

	scrollFrame:AddChild(GeneralUI:BuildSpacer())

	local featuresHeader = AceGUI:Create("Label") ---@type AceGUILabel
	featuresHeader:SetText("List of Features")
	featuresHeader:SetFontObject(GameFontHighlightLarge)
	featuresHeader:SetFullWidth(true)
	scrollFrame:AddChild(featuresHeader)

	local placeholderFeatures = {
		"Mining skill levels, zones and item links.",
		"Herbalism skill levels, zones and item links.",
		"Dungeon information, including NPC information, quest information and links.",
		"Filter visible Dungeon Quest information.",
		"Open the main window with /fdb",
	}
	for _, text in ipairs(placeholderFeatures) do
		local line = AceGUI:Create("Label") ---@type AceGUILabel
		line:SetText(text)
		line:SetFontObject(GameFontHighlight)
		line:SetFullWidth(true)
		scrollFrame:AddChild(line)
	end

	-- AceGUI's "Fill"/"List" layouts don't support "scroll area fills the rest,
	-- one row stays pinned to the bottom" - only the last-added child gets laid
	-- out under Fill. So this row bypasses AceGUI's layout system and anchors
	-- straight to the Frame's native content region instead, which keeps it
	-- glued to the bottom of the window regardless of scroll content or resizing.
	-- keybinds.tga is 752x104 natively - scale to the content width instead of
	-- a fixed size, keeping that aspect ratio so the whole image renders
	-- uncropped and undistorted regardless of window width.
	local keybindsImage = welcome_frame.frame:CreateTexture(nil, "OVERLAY")
	keybindsImage:SetTexture("Interface\\AddOns\\FlamesDatabase\\Images\\keybinds.tga")
	keybindsImage:SetTexCoord(0, 1, 0, 1)
	local imageWidth = welcome_frame.content:GetWidth() or 466
	local imageHeight = imageWidth * (104 / 752)
	keybindsImage:SetSize(imageWidth, imageHeight)
	keybindsImage:SetPoint("BOTTOMLEFT", welcome_frame.content, "BOTTOMLEFT", 4, 4)

	local footer = welcome_frame.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	footer:SetPoint("BOTTOMLEFT", keybindsImage, "TOPLEFT", 0, 4)
	footer:SetText("Tip: you can configure a keybind to quickly open the main window!")
	footer:SetTextColor(1, 1, 1)

	if debug then print("finished welcome frame code") end
end