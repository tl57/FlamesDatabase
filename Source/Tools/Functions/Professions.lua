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

function Functions_Professions:GetProfessionMaxSkillNumber(name)
    if not (GetNumSkillLines and GetSkillLineInfo) then return nil end

    ExpandSkillHeader(0)   -- expand headers so skill lines are visible

    for i = 1, GetNumSkillLines() do
        local skillName, isHeader, _, _, _, _, skillMaxRank = GetSkillLineInfo(i)
        if (skillName and not isHeader and skillName:find(name)) then
            return skillMaxRank
        end
    end
    return nil
end

-- Character level required to train the next profession rank, keyed by the
-- current rank's skill cap (Apprentice=75, Journeyman=150, Expert=225,
-- Artisan=300, Master=375, Grand Master=450). Gathering professions
-- (Mining, Herbalism, Skinning) unlock each rank at a lower character level
-- than crafting/production professions.
local NEXT_RANK_MIN_LEVEL = {
    gathering = {
        [75]  = 10, -- Apprentice -> Journeyman
        [150] = 20, -- Journeyman -> Expert
        [225] = 25, -- Expert -> Artisan
        [300] = 40, -- Artisan -> Master (TBC)
        [375] = 55, -- Master -> Grand Master (WotLK)
        [450] = 75, -- Grand Master -> Illustrious (Cataclysm)
    },
    crafting = {
        [75]  = 10, -- Apprentice -> Journeyman
        [150] = 20, -- Journeyman -> Expert
        [225] = 35, -- Expert -> Artisan
        [300] = 50, -- Artisan -> Master (TBC)
        [375] = 65, -- Master -> Grand Master (WotLK)
        [450] = 75, -- Grand Master -> Illustrious (Cataclysm)
    },
}

function Functions_Professions:GetProfessionShouldGoLearn(currentskill, currentMaxSkill, profession)
    if not currentMaxSkill or not currentskill then
        return false
    end

    local isGathering = profession == "Herbalism" or profession == "Mining" or profession == "Skinning"
    local nextRankLevels = isGathering and NEXT_RANK_MIN_LEVEL.gathering or NEXT_RANK_MIN_LEVEL.crafting

    local characterLevel = UnitLevel("player")
    local nextRankMinLevel = nextRankLevels[currentMaxSkill]
    local meetsLevelRequirement = not nextRankMinLevel or characterLevel >= nextRankMinLevel

    local expansion = GetServerExpansionLevel and GetServerExpansionLevel()
    local expansionSkillCap
    if expansion == LE_EXPANSION_CLASSIC then
        expansionSkillCap = 300
    elseif expansion == LE_EXPANSION_BURNING_CRUSADE then
        expansionSkillCap = 375
    elseif expansion == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
        expansionSkillCap = 450
    elseif expansion == LE_EXPANSION_CATACLYSM then
        expansionSkillCap = 525
    end

    if currentMaxSkill == expansionSkillCap then
        return false
    end

    return currentMaxSkill - currentskill <= 25 and meetsLevelRequirement
end