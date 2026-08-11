Functions_General = {}

-- returns a single integer representing the expansion level
-- 0 = Classic
-- 1 = TBC
-- 2 = LK
-- 3 = Cata
function Functions_General:GetServerExpansionLevel()
    return GetServerExpansionLevel and GetServerExpansionLevel()
end

-- The expansion levels this addon knows how to handle (matches the
-- expansionSkillCap cases in Functions_Professions:GetProfessionShouldGoLearn),
-- lowest to highest.
function Functions_General:GetExpansionLevels()
    return {
        LE_EXPANSION_CLASSIC,
        LE_EXPANSION_BURNING_CRUSADE,
        LE_EXPANSION_WRATH_OF_THE_LICH_KING,
        LE_EXPANSION_CATACLYSM,
    }
end
