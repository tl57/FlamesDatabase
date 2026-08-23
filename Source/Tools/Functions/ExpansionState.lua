--[[-----------------------------------------------------------------------------
ExpansionState
Shared "currently selected global expansion" - mainframe.lua's one dropdown is
the only writer (SetLevel); Mining/Herbalism/Prospecting each Subscribe while
built and Unsubscribe on release, since CategoryTabs:Render tears down and
rebuilds page content from scratch on every tab switch (at most one of those
pages exists in memory at a time), so there's no page-owned place to keep this
- it has to live above them.
-------------------------------------------------------------------------------]]
Functions_ExpansionState = {}

local currentLevel -- nil until first GetLevel()/SetLevel() call
local listeners = {} -- opaque key -> callback(level)
local cachedLevels, cachedNames -- memoized: the three data tables are static for the session

local function HighestColumnExp(data)
    local highest = LE_EXPANSION_CLASSIC
    for _, col in ipairs((data and data.columns) or {}) do
        if col.exp and col.exp > highest then
            highest = col.exp
        end
    end
    return highest
end

local function HighestRowExpansion(data)
    local highest = LE_EXPANSION_CLASSIC
    for _, row in ipairs((data and data.rows) or {}) do
        if row.expansion and row.expansion > highest then
            highest = row.expansion
        end
    end
    return highest
end

-- Capped to the MINIMUM of what each of Mining/Herbalism/Prospecting can
-- actually render, not the union/max - DataTable:Build filters columns by
-- exact match (col.exp == selectedExpansion), so offering a level higher than
-- what any one of them has data for would silently drop that page's
-- skill-breakpoint columns instead of gracefully capping.
local function ComputeAvailableLevels()
    if cachedLevels then
        return cachedLevels, cachedNames
    end

    local cap = math.min(
        HighestColumnExp(MiningData),
        HighestColumnExp(HerbalismData),
        HighestRowExpansion(ProspectingData)
    )

    local levels, names = {}, {}
    for _, level in ipairs(Functions_General:GetExpansionLevels()) do
        if level <= cap then
            levels[#levels + 1] = level
            names[level] = Functions_General:GetExpansionName(level)
        end
    end
    cachedLevels, cachedNames = levels, names
    return levels, names
end

-- Returns levels (ascending array), names (level -> display name).
function Functions_ExpansionState:GetAvailableLevels()
    return ComputeAvailableLevels()
end

-- Lazily initializes once to the realm's current expansion (clamped into the
-- offered list, falling back to the lowest offered level), then just returns
-- whatever was last set.
function Functions_ExpansionState:GetLevel()
    if currentLevel == nil then
        local levels = ComputeAvailableLevels()
        local realmLevel = Functions_General:GetServerExpansionLevel()
        currentLevel = levels[1]
        for _, level in ipairs(levels) do
            if level == realmLevel then
                currentLevel = level
                break
            end
        end
    end
    return currentLevel
end

-- Sets the global selection and notifies every currently subscribed (i.e.
-- currently alive) page to rebuild in place.
function Functions_ExpansionState:SetLevel(level)
    currentLevel = level
    for _, callback in pairs(listeners) do
        callback(level)
    end
end

function Functions_ExpansionState:Subscribe(key, callback)
    listeners[key] = callback
end

function Functions_ExpansionState:Unsubscribe(key)
    listeners[key] = nil
end
