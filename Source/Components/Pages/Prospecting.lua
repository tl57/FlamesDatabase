Prospecting = {}

-- Build and return the content widget for the "Prospecting" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function Prospecting:Build(parent)
    local scroll = Functions_Ace:CreateScrollFrame()
    scroll:SetLayout("List")

    ProspectingPage:AddHeader(scroll)

    return scroll
end
