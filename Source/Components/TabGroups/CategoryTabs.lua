local AceGUI = LibStub("AceGUI-3.0")

CategoryTabs = {}
CategoryTabs.__index = CategoryTabs

-- Create a tab group, optionally add it to a parent AceGUI container.
-- options = { parent = <AceGUI container>, tabs = { {value=..., text=...}, ... } }
function CategoryTabs:New(options)
    local widget = AceGUI:Create("TabGroup")
    widget:SetLayout("Fill")
    widget:SetFullHeight(true)
    widget:SetTabs(options.tabs or {})

    local self = setmetatable({
        widget   = widget,
        pages    = {},   -- value -> builder(parent) -> child widget
        current  = nil,
    }, CategoryTabs)

    widget:SetCallback("OnGroupSelected", function(wgt, _, value)
        self:Render(value)
    end)

    if options.parent then
        options.parent:AddChild(widget)
    end

    -- auto-select first tab
    local first = options.tabs and options.tabs[1]
    if first then
        widget:SelectTab(first.value)
    end

    return self
end

-- Register a builder for a tab value
function CategoryTabs:AddPage(value, builder)
    self.pages[value] = builder
    if self.current == nil or self.current == value then
        self:Render(value)
    end
end

-- (Re)build the active tab's content
function CategoryTabs:Render(value)
    local widget = self.widget
    widget:ReleaseChildren()

    local builder = self.pages[value]
    if builder then
        local child = builder(widget)
        if child then
            widget:AddChild(child)
        end
    end
    self.current = value
end

return CategoryTabs