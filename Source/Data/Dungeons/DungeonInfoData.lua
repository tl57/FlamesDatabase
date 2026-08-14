-- DungeonInfoData
-- Static dungeon metadata: zone id, bosses (name + level, in encounter
-- order), mob level range.
-- Exposes one global table per dungeon, named <Dungeon>Info.

RagefireChasmInfo = {
    name        = "Ragefire Chasm",
    zoneid      = 2437,
    bosses = {
        { name = "Oggleflint",             level = 16 },
        { name = "Taragaman the Hungerer", level = 16 },
        { name = "Jergosh the Invoker",    level = 16 },
        { name = "Bazzalan",               level = 16 },
    },
    minMobLevel = 13,
    maxMobLevel = 16,
}

DeadminesInfo = {
    name        = "The Deadmines",
    zoneid      = 1581,
    bosses = {
        { name = "Rhahk'Zor",           level = 19 },
        { name = "Sneed's Shredder",    level = 20 },
        { name = "Gilnid",              level = 20 },
        { name = "Mr. Smite",           level = 20 },
        { name = "Cookie",              level = 20 },
        { name = "Captain Greenskin",   level = 20 },
        { name = "Edwin VanCleef",      level = 21 },
    },
    minMobLevel = 16,
    maxMobLevel = 20,
}
