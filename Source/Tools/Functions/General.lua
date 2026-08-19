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

-- The highest expansion this addon is built for, based on the ## Interface
-- directive in its own .toc file (game-version compatibility) - not what
-- content/data exists for. Returns nil if the client has no way to read it.
function Functions_General:GetHighestSupportedExpansion(addonName)
    local getInterfaceVersion = GetAddOnInterfaceVersion or (C_AddOns and C_AddOns.GetAddOnInterfaceVersion)
    local interfaceVersion = getInterfaceVersion and getInterfaceVersion(addonName)
    if not interfaceVersion then
        return nil
    end
    -- Interface numbers are <expansion major><minor><patch>, e.g. 11509 = Classic Era,
    -- 40402 = Cataclysm. Expansion major 1 = LE_EXPANSION_CLASSIC (0), hence -1.
    return math.floor(interfaceVersion / 10000) - 1
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

-- Compares two dot-separated version strings numerically (so "0.1.10" > "0.1.9",
-- unlike a plain string comparison). Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal.
function Functions_General:CompareVersions(v1, v2)
    local function toParts(v)
        local parts = {}
        for part in tostring(v):gmatch("%d+") do
            table.insert(parts, tonumber(part))
        end
        return parts
    end

    local p1, p2 = toParts(v1), toParts(v2)
    for i = 1, math.max(#p1, #p2) do
        local a, b = p1[i] or 0, p2[i] or 0
        if a ~= b then
            return a > b and 1 or -1
        end
    end
    return 0
end

-- Wraps `text` in a |cffRRGGBB...|r color escape sequence built from `color`
-- ({r,g,b}, each 0-1 - the same format already used throughout this addon's
-- valueColors/valueBackgrounds/etc.), so static data (e.g. a column's legend
-- tooltip, see DataTable.lua's column.info) can embed colored text without
-- hand-writing hex codes.
function Functions_General:ColorizeText(text, color)
    return ("|cff%02x%02x%02x%s|r"):format(
        math.floor((color[1] or 1) * 255 + 0.5),
        math.floor((color[2] or 1) * 255 + 0.5),
        math.floor((color[3] or 1) * 255 + 0.5),
        text
    )
end

-- Wraps `texturePath` in a |T...|t inline-texture escape sequence (WoW's
-- equivalent of ColorizeText above, but for embedding an icon instead of
-- colored text - e.g. a column's legend tooltip, see DataTable.lua's
-- column.info, showing the actual icon a cell renders instead of a text
-- description of it). `size` defaults to 14 (matches DataTable.lua's own
-- INFO_ICON_SIZE) if omitted.
function Functions_General:InlineIcon(texturePath, size)
    return ("|T%s:%d|t"):format(texturePath, size or 14)
end

-- Returns `entries` (an array of { version = ..., changes = ... } tables,
-- newest first) filtered down to those newer than `sinceVersion`. With no
-- sinceVersion (e.g. corrupted settings), every entry is returned.
function Functions_General:GetEntriesSince(entries, sinceVersion)
    if not sinceVersion then
        return entries
    end

    local filtered = {}
    for _, entry in ipairs(entries) do
        if self:CompareVersions(entry.version, sinceVersion) > 0 then
            table.insert(filtered, entry)
        end
    end
    return filtered
end
