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
