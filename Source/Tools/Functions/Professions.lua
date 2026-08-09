Functions_Professions = {}

function Functions_Professions:GetProfessionSkillNumber(name)
    if not (GetNumSkillLines and GetSkillLineInfo) then return nil end

    ExpandSkillHeader(0)   -- expand headers so skill lines are visible

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        if (skillName and not isHeader and skillName:find(name)) then
            return skillRank
        end
    end
    return nil
end