--[[-----------------------------------------------------------------------------
GeneralUI
Small, generic AceGUI helpers shared across pages/components.
-----------------------------------------------------------------------------]]

local AceGUI = LibStub("AceGUI-3.0")

GeneralUI = {}

-- Vertical gap between sections. A SimpleGroup rather than a Label: Label
-- recomputes its own height from its FontString's text any time
-- UpdateImageAnchor runs, which clobbers a manually set height. SimpleGroup
-- only auto-resizes via LayoutFinished (summing its children's height),
-- which SetAutoAdjustHeight disables outright, leaving our explicit height
-- alone.
function GeneralUI:BuildSpacer()
    local spacer = AceGUI:Create("SimpleGroup")
    spacer:SetAutoAdjustHeight(false)
    spacer:SetHeight(12)
    return spacer
end

-- Add a collapsible header ("+ title"/"- title") to `scroll`, collapsed by
-- default, followed by a spacer. Clicking it lazily calls `buildContent()`
-- to build the content widget the first time it's expanded, inserting it
-- between the header and the spacer; collapsing releases and removes it.
-- `buildContent` is only ever called while expanding, so it can stay cheap
-- (or skipped entirely) for sections a user never opens.
function GeneralUI:AddCollapsibleSection(scroll, title, buildContent)
    local expanded = false
    local contentWidget

    local header = AceGUI:Create("InteractiveLabel")
    header:SetFullWidth(true)
    header:SetFontObject(GameFontHighlightLarge)
    header:SetText("+ " .. title)

    local spacer = self:BuildSpacer()

    header:SetCallback("OnClick", function()
        expanded = not expanded
        header:SetText((expanded and "- " or "+ ") .. title)

        if expanded then
            contentWidget = buildContent()
            -- beforeWidget = spacer inserts the content between the header
            -- and the trailing spacer (AddChild triggers DoLayout itself).
            scroll:AddChild(contentWidget, spacer)
        elseif contentWidget then
            -- AceGUI has no RemoveChild - pull the widget out of
            -- scroll.children directly, then release it and reflow.
            for idx, child in ipairs(scroll.children) do
                if child == contentWidget then
                    table.remove(scroll.children, idx)
                    break
                end
            end
            AceGUI:Release(contentWidget)
            contentWidget = nil
            scroll:DoLayout()
        end
    end)

    scroll:AddChild(header)
    scroll:AddChild(spacer)
end

-- Create a Label + Dropdown pair (not yet attached to anything - the caller
-- adds both to its own row once every pair's width is known). A plain Label
-- beside the control (mirrors GatheringPage.lua's BuildExpansionRadioGroup)
-- rather than Dropdown's own SetLabel, which stacks the label above the
-- control instead of beside it. Returns the label, the dropdown, and the
-- label's measured width (the caller needs it to size the row).
-- `dropdownWidth` defaults to `defaultWidth` if omitted.
function GeneralUI:BuildLabeledDropdown(labelText, items, dropdownWidth, defaultWidth)
    local label = AceGUI:Create("Label")
    label:SetFontObject(GameFontHighlightLarge)
    label:SetText(labelText)
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetWidth(dropdownWidth or defaultWidth)
    dropdown:SetList(items)
    -- The Dropdown widget's selected-text FontString (self.text in
    -- AceGUIWidget-DropDown.lua) inherits UIDropDownMenuTemplate's default
    -- CENTER justify; left-align it to match every other label in this addon.
    dropdown.text:SetJustifyH("LEFT")

    return label, dropdown, labelWidth
end
