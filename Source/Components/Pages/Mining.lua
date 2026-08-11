local AceGUI = LibStub("AceGUI-3.0")

Mining = {}

-- Build and return the content widget for the "Mining" page.
-- Returns the AceGUI widget (so the page builder can return it directly).
function Mining:Build(parent)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")

    local charSkillLbl = AceGUI:Create("Label")
    charSkillLbl:SetFullWidth(true)
    local miningSkill = Functions_Professions:GetProfessionSkillNumber("Mining")
    local maxMiningSkill = Functions_Professions:GetProfessionMaxSkillNumber("Mining")

    local charSkill = "Current Mining Skill: "
    if miningSkill then
        charSkill = charSkill .. miningSkill .. "/".. maxMiningSkill
        
        local shouldGoTrain = Functions_Professions:GetProfessionShouldGoLearn(miningSkill, maxMiningSkill, "Mining")
        if (shouldGoTrain) then
            charSkill = charSkill .. " You should go train soon!"
        end
    else
        charSkill = charSkill .. "N/A"
    end
    charSkillLbl:SetText(charSkill)
    scroll:AddChild(charSkillLbl)

    -- Node/skill table (data from MiningData.lua)
    local table = DataTable:Build(parent, MiningData)
    scroll:AddChild(table)

    return scroll
end
