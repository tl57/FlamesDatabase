--[[-----------------------------------------------------------------------------
GeneralUI
Small, generic AceGUI helpers shared across pages/components.
-----------------------------------------------------------------------------]]

GeneralUI = {}

-- Vertical gap between sections. A SimpleGroup rather than a Label: Label
-- recomputes its own height from its FontString's text any time
-- UpdateImageAnchor runs, which clobbers a manually set height. SimpleGroup
-- only auto-resizes via LayoutFinished (summing its children's height),
-- which SetAutoAdjustHeight disables outright, leaving our explicit height
-- alone.
function GeneralUI:BuildSpacer()
    local spacer = Functions_Ace:CreateGroup()
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

    local header = Functions_Ace:CreateInteractiveLabel()
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
            Functions_Ace:ReleaseWidget(contentWidget)
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
-- control instead of beside it. `order`, if given, is passed straight through
-- as Dropdown:SetList's explicit key order (e.g. an ascending array of
-- expansion levels keying into `items`) instead of falling back to SetList's
-- own sort. Returns the label, the dropdown, and the label's measured width
-- (the caller needs it to size the row). `dropdownWidth` defaults to
-- `defaultWidth` if omitted.
function GeneralUI:BuildLabeledDropdown(labelText, items, order, dropdownWidth, defaultWidth)
    local label = Functions_Ace:CreateLabel()
    label:SetFontObject(GameFontHighlightLarge)
    label:SetText(labelText)
    local labelWidth = math.ceil(label.label:GetStringWidth()) + 8
    label:SetWidth(labelWidth)

    local dropdown = Functions_Ace:CreateDropdown()
    dropdown:SetWidth(dropdownWidth or defaultWidth)
    dropdown:SetList(items, order)
    -- The Dropdown widget's selected-text FontString (self.text in
    -- AceGUIWidget-DropDown.lua) inherits UIDropDownMenuTemplate's default
    -- CENTER justify; left-align it to match every other label in this addon.
    dropdown.text:SetJustifyH("LEFT")

    return label, dropdown, labelWidth
end

-- BuildLabeledDropdown's label+dropdown pair, already wrapped in a
-- ready-to-AddChild row group (mirrors the SimpleGroup/"Flow"-layout wrapping
-- GatheringPage.lua/ProspectingPage.lua's old per-page BuildExpansionDropdown
-- copies each did, generalized here so a third copy isn't needed for a
-- window-level dropdown). Caller still wires SetValue/SetCallback on the
-- returned dropdown. Returns the row group and the dropdown.
function GeneralUI:BuildLabeledDropdownRow(labelText, items, order, dropdownWidth)
    local label, dropdown, labelWidth = self:BuildLabeledDropdown(labelText, items, order, dropdownWidth, dropdownWidth)

    local totalWidth = labelWidth + dropdownWidth
    local group = Functions_Ace:CreateGroup()
    group:SetLayout("Flow")
    group:SetWidth(totalWidth)
    -- SimpleGroup's Flow layout reads content.width directly, which SetWidth
    -- only updates asynchronously via the frame's OnSizeChanged - without
    -- this a group recycled from AceGUI's shared SimpleGroup pool can carry
    -- over a stale, narrower width and wrap the dropdown onto its own row
    -- (see the old per-page BuildExpansionDropdown copies' identical line).
    group.content.width = totalWidth
    group:AddChild(label)
    group:AddChild(dropdown)

    return group, dropdown
end

-- Creates a bare Label widget - the common first step before any
-- Label-specific font/text/sizing/wiring callers do themselves afterward.
function GeneralUI:CreateLabel()
    return Functions_Ace:CreateLabel()
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
        Functions_Ace:ReleaseWidget(probe)
    end
    return rowTextHeight
end

-- Returns the next reusable FontString from `content`'s row pool (creating
-- one if needed), reset to a blank state. `content.rowsUsed` must be reset
-- to 0 at the start of a build - the caller then places/fills each returned
-- FontString itself. `content` (a SimpleGroup's own .content frame) is
-- recycled across Functions_Ace:ReleaseWidget/:CreateGroup cycles (e.g. every time a section
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
-- `yOffset`, indented by `xOffset` (defaults to 0), sized to `rowHeight`.
-- Returns yOffset + rowHeight, for the next row.
function GeneralUI:AddDungeonInfoRow(content, text, yOffset, rowHeight, xOffset)
    local fontString = self:AcquireInfoRow(content)
    fontString:ClearAllPoints()
    fontString:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset or 0, -yOffset)
    fontString:SetText(text)
    return yOffset + rowHeight
end

-- Resolves `itemId` asynchronously and, once loaded, turns `cell` into an
-- icon + item-link-aware cell: shows the item's icon (sized/offset by
-- `padding`/`iconTextGap`) to the left of the text, and wires
-- GameTooltip:SetHyperlink on hover and ChatEdit_InsertLink on shift-click.
-- `displayText`, if given, is shown as the cell's text once the item loads
-- instead of the item's own link text (e.g. so a caller's own "Copper"
-- keeps showing instead of switching to the item's real link label). Leave
-- nil to show the raw item link text. `cell` must expose `.icon` (a
-- Texture) and `.text` (a FontString), and support EnableMouse/SetScript
-- (i.e. be a real Frame) - see DataTable.lua's AcquireCell for the pooled
-- cell shape this was written against.
--
-- GetItemInfo/GetItemLink can return nothing on the very first query for an
-- item the client hasn't cached yet, so ContinueOnItemLoad's callback fires
-- immediately if already cached, or once the data arrives otherwise. Cells
-- are commonly pooled/reused across rebuilds, so `cell.pendingItemId` guards
-- against a delayed callback overwriting a cell that's since been recycled
-- for something unrelated - callers that reuse cells should reset
-- `cell.pendingItemId = nil` on reacquire, same as DataTable.lua's
-- AcquireCell.
--
-- An itemId this client's item database doesn't recognize at all (e.g. a
-- TBC-only item shown while running on the Classic Era client) doesn't fail
-- gracefully - ContinueOnItemLoad throws deep inside Blizzard's own async
-- callback system ("table index is nil" in Blizzard_ObjectAPI's
-- GetOrCreateCallbacks) instead of just not calling back. pcall keeps that
-- from surfacing as a visible Lua error; the cell just keeps its plain
-- displayText with no icon/tooltip in that case.
function GeneralUI:WireItemCell(cell, itemId, displayText, padding, iconTextGap)
    cell.pendingItemId = itemId

    local item = Item:CreateFromItemID(itemId)
    if item:IsItemEmpty() then
        return
    end

    pcall(item.ContinueOnItemLoad, item, function()
        if cell.pendingItemId ~= itemId then
            return
        end
        local itemLink = item:GetItemLink()

        cell.icon:SetTexture(item:GetItemIcon())
        cell.icon:SetPoint("LEFT", padding, 0)
        cell.icon:Show()
        cell.text:ClearAllPoints()
        cell.text:SetPoint("LEFT", cell.icon, "RIGHT", iconTextGap, 0)
        cell.text:SetPoint("RIGHT", -padding, 0)
        cell.text:SetText(displayText or itemLink)

        cell:EnableMouse(true)
        cell:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        cell:SetScript("OnMouseUp", function()
            if IsModifiedClick("CHATLINK") then
                ChatEdit_InsertLink(itemLink)
            end
        end)
    end)
end
