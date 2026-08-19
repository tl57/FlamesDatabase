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

    local expansion = Functions_General:GetServerExpansionLevel()
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

-- Text colors for a numeric cell, based on (playerSkill - cellValue).
-- .Grey is also exposed directly (rather than kept a private constant) for
-- callers that need the same "no data" grey outside of a diff, e.g.
-- DataTable.lua's BuildRow when a row has no other column with a number.
local SKILL_DIFF_RED    = { 0.90, 0.15, 0.15 }
local SKILL_DIFF_ORANGE = { 0.90, 0.55, 0.15 }
local SKILL_DIFF_YELLOW = { 0.85, 0.85, 0.15 }
local SKILL_DIFF_GREEN  = { 0.35, 0.75, 0.35 }
Functions_Professions.SkillDiffGreyColor = { 0.60, 0.60, 0.60 }

-- diff < 0: red. 0-25: orange. 26-50: yellow. 51-75: green. 100+: grey.
function Functions_Professions:GetSkillDiffColor(diff)
    if diff < 0 then
        return SKILL_DIFF_RED
    elseif diff <= 25 then
        return SKILL_DIFF_ORANGE
    elseif diff <= 50 then
        return SKILL_DIFF_YELLOW
    elseif diff <= 100 then
        return SKILL_DIFF_GREEN
    else
        return self.SkillDiffGreyColor
    end
end