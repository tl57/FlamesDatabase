local AceGUI = LibStub("AceGUI-3.0")

Mining = {}

-- Build and return the content widget for the "Mining" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function Mining:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    local charSkillLbl = AceGUI:Create("Label")
    local miningSkill = Functions_Professions:GetProfessionSkillNumber("Mining")
    local charSkill = "Current Mining Skill: "
    if miningSkill then
        charSkill = charSkill .. miningSkill
    else
        charSkill = charSkill .. "N/A"
    end
    charSkillLbl:SetText(charSkill)
    scroll:AddChild(charSkillLbl)

    return scroll
end
