local AceGUI = LibStub("AceGUI-3.0")

Mining = {}

-- Build and return the content widget for the "Mining" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function Mining:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    local charSkillLbl = AceGUI:Create("Label")
    charSkillLbl:SetFullWidth(true)
    charSkillLbl:SetFontObject(GameFontHighlightLarge)
    local miningSkill = Functions_Professions:GetProfessionSkillNumber("Mining")
    local maxMiningSkill = Functions_Professions:GetProfessionMaxSkillNumber("Mining")

    local charSkill = "Current Mining Skill: "
    if miningSkill then
        charSkill = charSkill .. miningSkill .. "/".. maxMiningSkill

        local shouldGoTrain = Functions_Professions:GetProfessionShouldGoLearn(miningSkill, maxMiningSkill, "Mining")
        if (shouldGoTrain) then
            charSkill = charSkill .. " You should go train soon!"
            charSkillLbl:SetColor(1, 0, 0)
        else
            charSkillLbl:SetColor()
        end
    else
        charSkill = charSkill .. "N/A"
        charSkillLbl:SetColor()
    end
    charSkillLbl:SetText(charSkill)
    scroll:AddChild(charSkillLbl)

    -- Spacer so the table doesn't sit flush against the label above it.
    local spacer = AceGUI:Create("Label")
    spacer:SetFullWidth(true)
    spacer:SetHeight(12)
    scroll:AddChild(spacer)

    -- Node/skill table (data from MiningData.lua)
    local table = DataTable:Build(parent, MiningData)
    scroll:AddChild(table)

    return scroll
end
