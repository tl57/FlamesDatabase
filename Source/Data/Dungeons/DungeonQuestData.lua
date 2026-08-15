-- DungeonQuestData
-- Static data for dungeon quest tables.
-- Exposes one global table per dungeon (name, columns, rows), consumed by
-- DungeonQuests.lua via DataTable. Zone id/boss levels/mob level range live
-- separately in DungeonInfoData.lua.

-- Column layout for a dungeon's quest table (see DataTable.lua). Widths sum
-- to comfortably fit the 770px main window (see mainframe.lua) alongside
-- the vertical scrollbar - unlike Mining/Herbalism's DataTable, every
-- column is always shown (no per-expansion filtering), so the sum has to
-- fit on its own without that headroom.
local QuestColumns = {
    { id = "Name",  title = "",    width = 170 },
    { id = "Level", title = "Lvl", width = 31 },
    {
        id = "Faction",
        title = "Faction",
        width = 59,
        valueColors = {
            Horde    = { 0.90, 0.20, 0.20 },
            Alliance = { 0.30, 0.55, 0.95 },
            -- "Both" (and anything else unlisted) stays untinted.
        },
    },
    { id = "NPC",   title = "NPC",   width = 135 },
    {
        id = "Effort",
        title = "Effort",
        --width = 68, -- old width, when using Minimum, Medium and Maximum for the Effort
        width = 59, -- new width, when using Low, Medium, and High for the Effort
        valueBackgrounds = {
            Low    = { 0.20, 0.80, 0.20 },
            Medium = { 0.85, 0.80, 0.10 },
            High   = { 0.90, 0.15, 0.15 },
        },
    },
    {
        id = "Shareable",
        title = "Share?",
        width = 50,
        valueColors = {
            No = { 0.90, 0.20, 0.20 },
            -- "Yes" stays untinted.
        },
    },
    { id = "Chain", title = "Chain", width = 46 },
    { id = "Note",  title = "Note",  width = 450 },
}

RagefireChasmQuests = {
    name    = "Ragefire Chasm",
    columns = QuestColumns,
    rows    = {
        {
            Name        = "Slaying the Beast",
            QuestLinkId = 5761,
            QuestLevel  = 9,
            Level       = 9,
            Faction     = "Horde",
            NPC         = "Neeru Fireblade (Orgrimmar)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "Hidden Enemies",
            QuestLinkId = 5728,
            QuestLevel  = 9,
            Level       = 9,
            Faction     = "Horde",
            NPC         = "Thrall (Orgrimmar)",
            Effort      = "High",
            Shareable   = "Yes",
            Chain       = "Yes",
            Note        = "Requires farming for a Lieutenant's Insignia from mobs in Skull Rock.",
        },
        {
            Name        = "The Power to Destroy",
            QuestLinkId = 5725,
            QuestLevel  = 9,
            Level       = 9,
            Faction     = "Horde",
            NPC         = "Varimathras (Undercity)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "Testing an Enemy's Strength",
            QuestLinkId = 5723,
            QuestLevel  = 9,
            Level       = 9,
            Faction     = "Horde",
            NPC         = "Rahauro (Thunder Bluff)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "Searching for the Lost Satchel",
            QuestLinkId = 5722,
            QuestLevel  = 9,
            Level       = 9,
            Faction     = "Horde",
            NPC         = "Rahauro (Thunder Bluff)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "Returning the Last Satchel",
            QuestLinkId = 5724,
            QuestLevel  = 9,
            Level       = 9,
            Faction     = "Horde",
            NPC         = "Maur Grimtotem (Ragefire Chasm)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = "Yes",
            Note        = "Requires completing the 'Searching for the Lost Satchel' quest.",
        },
    },
}

DeadminesQuests = {
    name    = "The Deadmines",
    columns = QuestColumns,
    rows    = {
        {
            Name        = "Oh Brother. . .",
            QuestLinkId = 167,
            QuestLevel  = 15,
            Level       = 15,
            Faction     = "Alliance",
            NPC         = "Wilder Thistlenettle (Stormwind)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "Collecting Memories",
            QuestLinkId = 168,
            QuestLevel  = 14,
            Level       = 14,
            Faction     = "Alliance",
            NPC         = "Wilder Thistlenettle (Stormwind)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "Underground Assault",
            QuestLinkId = 2040,
            QuestLevel  = 15,
            Level       = 15,
            Faction     = "Alliance",
            NPC         = "Shoni the Shilent (Stormwind)",
            Effort      = "Low",
            Shareable   = "Yes",
            Chain       = nil,
            Note        = nil,
        },
        {
            Name        = "The Defias Brotherhood",
            QuestLinkId = 166,
            QuestLevel  = 14,
            Level       = 14,
            Faction     = "Alliance",
            NPC         = "Gryan Stoutmantle (Sentinel Hill, Westfall)",
            Effort      = "High",
            Shareable   = "Yes",
            Chain       = "Yes",
            Note        = "Requires the 'Defias Brotherhood' pre-quest (long chain. Follow up after the Escort).",
        },
        {
            Name        = "Red Silk Bandanas",
            QuestLinkId = 214,
            QuestLevel  = 14,
            Level       = 14,
            Faction     = "Alliance",
            NPC         = "Scout Riell (Sentinel Hill, Westfall)",
            Effort      = "High",
            Shareable   = "Yes",
            Chain       = "Yes",
            Note        = "Requires the 'Defias Brotherhood' pre-quest (long chain. Follow up after the Escort).",
        },
        {
            Name        = "The Unsent Letter",
            QuestLinkId = 373,
            QuestLevel  = 16,
            Level       = 16,
            Faction     = "Alliance",
            NPC         = nil,
            Effort      = "Low",
            Shareable   = "No",
            Chain       = nil,
            Note        = "Loot Van Cleef's corpse.",
        },
        {
            Name        = "The Test of Righteousness",
            QuestLinkId = 1654,
            QuestLevel  = 20,
            Level       = 20,
            Faction     = "Alliance",
            NPC         = "Jordan Stilwell (Ironforge)",
            Effort      = "Medium",
            Shareable   = "No",
            Chain       = "Yes",
            Note        = "Paladin-only quest. Requires pre-quest of defending Daphne Stilwell",
        },
    },
}
