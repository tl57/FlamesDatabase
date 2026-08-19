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

-- Creates a bare Label widget - the common first step before any
-- Label-specific font/text/sizing/wiring callers do themselves afterward.
function GeneralUI:CreateLabel()
    return AceGUI:Create("Label")
end

-- The single-line pixel height of GameFontHighlight text, measured once (via
-- a probe Label) and cached for every later call - lets callers size rows to
-- match real glyph height instead of guessing at a constant.
local rowTextHeight
function GeneralUI:GetRowTextHeight()
    if not rowTextHeight then
        local probe = self:CreateLabel()
        probe:SetFontObject(GameFontHighlight)
        probe:SetText("Wg")
        rowTextHeight = math.ceil(probe.label:GetStringHeight())
        AceGUI:Release(probe)
    end
    return rowTextHeight
end

-- Returns the next reusable FontString from `content`'s row pool (creating
-- one if needed), reset to a blank state. `content.rowsUsed` must be reset
-- to 0 at the start of a build - the caller then places/fills each returned
-- FontString itself. `content` (a SimpleGroup's own .content frame) is
-- recycled across AceGUI:Release/:Create cycles (e.g. every time a section
-- is collapsed/expanded or its tab is revisited), so creating a fresh
-- FontString on every build (as an earlier version of DungeonInfo.lua did)
-- left old rows permanently attached and unhidden, accumulating one full
-- extra set on every rebuild. Mirrors DataTable.lua's AcquireRow/AcquireCell.
function GeneralUI:AcquireInfoRow(content)
    content.rowPool = content.rowPool or {}
    content.rowsUsed = content.rowsUsed + 1
    local n = content.rowsUsed

    local fontString = content.rowPool[n]
    if not fontString then
        fontString = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fontString:SetJustifyH("LEFT")
        content.rowPool[n] = fontString
    end

    fontString:Show()
    return fontString
end

-- Add a row showing `text` to `content` (a SimpleGroup's .content frame) at
-- `yOffset`, sized to `rowHeight`. Returns yOffset + rowHeight, for the next
-- row.
function GeneralUI:AddDungeonInfoRow(content, text, yOffset, rowHeight)
    local fontString = self:AcquireInfoRow(content)
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    fontString:SetText(text)
    return yOffset + rowHeight
end
