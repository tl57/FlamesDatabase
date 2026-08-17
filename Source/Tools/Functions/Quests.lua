Functions_Quests = {}

-- Colors for the Status column's non-icon statuses (see DataTable.lua's
-- BuildRow) - shared here, rather than kept as private constants in
-- DataTable.lua, so DungeonQuestData.lua's column.info legend can quote the
-- exact same colors instead of a second, driftable copy. "Completed" has no
-- BuildRow use of its own (that status renders as a green checkmark icon,
-- not colored text) - it's included purely so the legend's swatch matches
-- the icon's color.
Functions_Quests.StatusColors = {
    Completed  = { 0.20, 0.80, 0.20 },
    Failed     = { 1.00, 0.55, 0.00 },
    Ineligible = { 0.90, 0.20, 0.20 },
}

-- Icon textures for the Status column's two icon-only statuses (see
-- DataTable.lua's BuildRow) - shared the same way as StatusColors above, so
-- DungeonQuestData.lua's column.info legend can embed (via WoW's |T...|t
-- inline-texture escape) the exact same icons instead of a second, driftable
-- copy of these paths.
Functions_Quests.StatusIcons = {
    Completed  = "Interface\\RaidFrame\\ReadyCheck-Ready",
    NotStarted = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

-- Quest completion is per-character. FlamesDatabaseCharSV is only reliably
-- populated by the client around PLAYER_LOGIN (same reason main.lua defers
-- its own FlamesDatabase.settings init to that event rather than doing it at
-- file-load top-level) - the client replaces the whole FlamesDatabaseCharSV
-- table wholesale once the real saved data loads, which would wipe out a
-- CompletedDungeonQuests field set here at file scope. So
-- CompletedDungeonQuests is (re)ensured lazily on each access instead,
-- against whatever table FlamesDatabaseCharSV currently points to.
local function GetCompletedQuests()
    FlamesDatabaseCharSV = FlamesDatabaseCharSV or {}
    FlamesDatabaseCharSV.CompletedDungeonQuests = FlamesDatabaseCharSV.CompletedDungeonQuests or {}
    return FlamesDatabaseCharSV.CompletedDungeonQuests
end

-- Fast path, no API call: has questID already been recorded as completed?
function Functions_Quests:IsQuestMarkedComplete(questID)
    if not questID then return false end
    for _, id in ipairs(GetCompletedQuests()) do
        if id == questID then
            return true
        end
    end
    return false
end

-- Live API check. A completed quest can never become un-completed, so once
-- this finds questID flagged complete it's recorded into
-- FlamesDatabaseCharSV.CompletedDungeonQuests (de-duplicated) and future
-- calls can resolve it via the fast IsQuestMarkedComplete path instead.
function Functions_Quests:CheckAndSaveQuestCompletion(questID)
    if not questID then return false end
    if not C_QuestLog.IsQuestFlaggedCompleted(questID) then
        return false
    end
    if not self:IsQuestMarkedComplete(questID) then
        table.insert(GetCompletedQuests(), questID)
    end
    return true
end

-- Is questID currently in the character's quest log right now?
function Functions_Quests:IsQuestAccepted(questID)
    if not questID then return false end
    return C_QuestLog.IsOnQuest(questID) == true
end

-- Has questID been failed (e.g. a timed/escort quest that ran out) while
-- still sitting in the character's quest log?
--
-- C_QuestLog.IsFailed only exists from Patch 9.0.1 onward, and Classic Era
-- doesn't have C_QuestLog.GetLogIndexForQuestID either - only the older
-- global GetQuestLogIndexByID (0, not nil, when questID isn't in the log),
-- same "Classic Era uses the global, retail moved it to C_X" split as
-- GetAddOnInfo/C_AddOns.GetAddOnInfo in AddOnAccess.lua. Once we have a log
-- index, GetQuestLogTitle's isComplete return is -1 for a failed quest, +1
-- for a completed one, nil/false otherwise.
function Functions_Quests:IsQuestFailed(questID)
    if not questID then return false end
    local getLogIndex = GetQuestLogIndexByID or (C_QuestLog and C_QuestLog.GetLogIndexForQuestID)
    local index = getLogIndex and getLogIndex(questID)
    if not index or index == 0 then return false end
    local _, _, _, _, _, isComplete = GetQuestLogTitle(index)
    return isComplete == -1
end

-- False if `faction` (a quest row's Faction value - "Alliance", "Horde",
-- "Both", or a class name like "Paladin"/"Warlock"/"Mage") rules out the
-- current character: wrong WoW faction, or a class-restricted quest for a
-- different class. "Both" and any unset value are always eligible.
function Functions_Quests:IsFactionEligible(faction)
    if not faction or faction == "Both" then
        return true
    end
    if faction == "Alliance" or faction == "Horde" then
        return UnitFactionGroup("player") == faction
    end
    -- Anything else is a class-restricted quest - eligible only for that
    -- class. UnitClass's second return is the non-localized class token
    -- (e.g. "PALADIN"), so this doesn't depend on the client's locale.
    local _, playerClass = UnitClass("player")
    return playerClass == faction:upper()
end
