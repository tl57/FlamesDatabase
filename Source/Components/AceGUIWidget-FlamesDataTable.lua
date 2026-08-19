--[[-----------------------------------------------------------------------------
FlamesDataTable (custom AceGUI widget type)
A minimal AceGUI widget - just a frame, no .content/children/layout - that
exists solely to give DataTable.lua's container its own dedicated identity.

AceGUI:Create/:Release pool widgets separately per registered type name (see
AceGUI-3.0.lua's newWidget/objPools). DataTable.lua used to build its
container via Functions_Ace:CreateGroup() and pool its rows/cells as raw
frames directly onto it - "SimpleGroup" is also the type every spacer,
DungeonInfo section, and any future plain AceGUI container in this addon
uses, all sharing ONE pool. That let a single physical frame get handed
between completely unrelated widgets across releases/reacquires - which is
exactly how a DataTable-authored "hide every leftover child" defensive
cleanup once ended up permanently hiding a different widget's own content
frame that happened to land on the same recycled frame afterward.

Registering DataTable's container under its own type name instead removes
that risk structurally: AceGUI will only ever hand this frame to another
DataTable, never to (or from) anything else - no careful coding required to
keep that true. This has no rendering or performance impact of its own;
DataTable.lua's row/cell pooling logic is unchanged, only what creates its
outer frame changes.
-------------------------------------------------------------------------------]]
local Type, Version = "FlamesDataTable", 1

local methods = {
    ["OnAcquire"] = function(self)
        self:SetWidth(300)
        self:SetHeight(100)
    end,

    -- ["OnRelease"] = nil, -- DataTable.lua sets this per-instance itself.
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")

    local widget = {
        frame = frame,
        type  = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end

    return Functions_Ace:RegisterAsWidget(widget)
end

Functions_Ace:RegisterWidgetType(Type, Constructor, Version)
