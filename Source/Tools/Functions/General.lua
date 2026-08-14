Functions_General = {}

-- GetAddOnMetadata moved: Classic Era uses the global GetAddOnMetadata,
-- TBC Anniversary/Retail moved it to C_AddOns.GetAddOnMetadata.
function Functions_General:GetAddonMetadata(addonName, field)
    local getMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
    return getMetadata(addonName, field)
end

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

local EXPANSION_NAMES = {
    [LE_EXPANSION_CLASSIC]                = "Classic",
    [LE_EXPANSION_BURNING_CRUSADE]        = "TBC",
    [LE_EXPANSION_WRATH_OF_THE_LICH_KING] = "WotLK",
    [LE_EXPANSION_CATACLYSM]              = "Cataclysm",
}

-- Display name for one of the levels returned by GetExpansionLevels().
function Functions_General:GetExpansionName(level)
    return EXPANSION_NAMES[level] or ("Expansion " .. tostring(level))
end
