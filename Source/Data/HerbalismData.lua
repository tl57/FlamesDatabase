-- HerbalismData
-- Static data for the Herbalism profession node/skill table.
-- Exposes global HerbalismData with columns and rows, consumed by Herbalism.lua via DataTable.
-- Row values are placeholders (1) pending real thresholds.

HerbalismData = {
    profession = "Herbalism",
    columns = {
        { id = "Name",              width = 100 },
        { id = "OrangeClassicHerb", width = 37, exp = "Classic", background = "orange", group = "Herb" },
        { id = "YellowClassicHerb", width = 37, exp = "Classic", background = "yellow", group = "Herb" },
        { id = "GreenClassicHerb",  width = 37, exp = "Classic", background = "green",  group = "Herb" },
        { id = "GreyClassicHerb",   width = 37, exp = "Classic", background = "grey",   group = "Herb" },
        { id = "OrangeTBCHerb",     width = 37, exp = "TBC",     background = "orange", group = "Herb" },
        { id = "YellowTBCHerb",     width = 37, exp = "TBC",     background = "yellow", group = "Herb" },
        { id = "GreenTBCHerb",      width = 37, exp = "TBC",     background = "green",  group = "Herb" },
        { id = "GreyTBCHerb",       width = 37, exp = "TBC",     background = "grey",   group = "Herb" },
    },
    rows = {
        {
            Name = "Silverleaf",
            OrangeClassicHerb = 1,
            OrangeTBCHerb = 1,
            YellowClassicHerb = 1,
            YellowTBCHerb = 1,
            GreenClassicHerb = 1,
            GreenTBCHerb = 1,
            GreyClassicHerb = 1,
            GreyTBCHerb = 1,
        },
    },
}
