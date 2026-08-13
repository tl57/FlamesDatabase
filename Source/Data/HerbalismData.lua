-- HerbalismData
-- Static data for the Herbalism profession node/skill table.
-- Exposes global HerbalismData with columns and rows, consumed by Herbalism.lua via DataTable.
-- Row values are placeholders (1) pending real thresholds.

HerbalismData = {
    profession = "Herbalism",
    columns = {
        { id = "Name",              width = 142 },
        { id = "OrangeClassicHerb", width = 37,  group = "Herb", exp = LE_EXPANSION_CLASSIC,         background = "orange" },
        { id = "YellowClassicHerb", width = 37,  group = "Herb", exp = LE_EXPANSION_CLASSIC,         background = "yellow" },
        { id = "GreenClassicHerb",  width = 37,  group = "Herb", exp = LE_EXPANSION_CLASSIC,         background = "green" },
        { id = "GreyClassicHerb",   width = 37,  group = "Herb", exp = LE_EXPANSION_CLASSIC,         background = "grey" },
        { id = "OrangeTBCHerb",     width = 37,  group = "Herb", exp = LE_EXPANSION_BURNING_CRUSADE, background = "orange" },
        { id = "YellowTBCHerb",     width = 37,  group = "Herb", exp = LE_EXPANSION_BURNING_CRUSADE, background = "yellow" },
        { id = "GreenTBCHerb",      width = 37,  group = "Herb", exp = LE_EXPANSION_BURNING_CRUSADE, background = "green" },
        { id = "GreyTBCHerb",       width = 37,  group = "Herb", exp = LE_EXPANSION_BURNING_CRUSADE, background = "grey" },
        { id = "Info",              width = 380, group = "Info" },
        --{ id = "ItemLinkId",        width = 149, group = "Link" },
    },
    rows = {
        {
            Name = "Peacebloom",
            ItemLinkId = 2447,
            OrangeClassicHerb = 1,
            YellowClassicHerb = 25,
            GreenClassicHerb = 50,
            GreyClassicHerb = 100,
            Info = "Barrens, Tirisfal, Dun Morough, Elwynn (open field)"
        },
        {
            Name = "Silverleaf",
            ItemLinkId = 765,
            OrangeClassicHerb = 1,
            YellowClassicHerb = 25,
            GreenClassicHerb = 50,
            GreyClassicHerb = 100,
            Info = "Durotar, Barrens, Loch Modan, Darkshore (woods, near trees)"
        },
        {
            Name = "Earthroot",
            ItemLinkId = 2449,
            OrangeClassicHerb = 15,
            YellowClassicHerb = 40,
            GreenClassicHerb = 65,
            GreyClassicHerb = 115,
            Info = "Barrens, Tirisfal, Dun Morough (rocky outcroppings)"
        },
        {
            Name = "Mageroyal",
            ItemLinkId = 785,
            OrangeClassicHerb = 50,
            YellowClassicHerb = 75,
            GreenClassicHerb = 100,
            GreyClassicHerb = 150,
            Info = "Barrens, Ashenvale, Darkshore, Westfall (mostly open field)"
        },
        {
            Name = "Briarthorn",
            ItemLinkId = 2450,
            OrangeClassicHerb = 70,
            YellowClassicHerb = 95,
            GreenClassicHerb = nil,
            GreyClassicHerb = 120,
            Info = "Duskwood, Barrens, Ashenvale, Silverpine (forest, near trees)"
        },
        {
            Name = "Swiftthistle",
            ItemLinkId = 2452,
            OrangeClassicHerb = nil,
            YellowClassicHerb = nil,
            GreenClassicHerb = nil,
            GreyClassicHerb = nil,
            Info = "Found mostly with Briarthorn, sometimes with Mageroyal"
        },
        {
            Name = "Stranglekelp",
            ItemLinkId = 3820,
            OrangeClassicHerb = 85,
            YellowClassicHerb = 110,
            GreenClassicHerb = 135,
            GreyClassicHerb = 185,
            Info = "Ashenvale, Darkshore, Barrens, Wetlands, Westfall (underwater)"
        },
        {
            Name = "Bruiseweed",
            ItemLinkId = 2453,
            OrangeClassicHerb = 100,
            YellowClassicHerb = 125,
            GreenClassicHerb = 150,
            GreyClassicHerb = 200,
            Info = "Stonetalon, Hillsbrad, Barrens (near obstacles)"
        },
        {
            Name = "Wild Steelbloom",
            ItemLinkId = 3355,
            OrangeClassicHerb = 115,
            YellowClassicHerb = 140,
            GreenClassicHerb = 165,
            GreyClassicHerb = 215,
            Info = "Arathi, Stonetalon, Wetlands (rocky outcroppings)"
        },
        {
            Name = "Grave Moss",
            ItemLinkId = 3369,
            OrangeClassicHerb = 120,
            YellowClassicHerb = 150,
            GreenClassicHerb = 170,
            GreyClassicHerb = 220,
            Info = "Duskwood, Desolace, Wetlands (all graveyards)"
        },
        {
            Name = "Kingsblood",
            ItemLinkId = 3356,
            OrangeClassicHerb = 125,
            YellowClassicHerb = 155,
            GreenClassicHerb = 175,
            GreyClassicHerb = 225,
            Info = "STV, Hillsbrad Foothills, Barrens, Wetlands (open field)"
        },
        {
            Name = "Liferoot",
            ItemLinkId = 3357,
            OrangeClassicHerb = 150,
            YellowClassicHerb = 175,
            GreenClassicHerb = 200,
            GreyClassicHerb = 250,
            Info = "STV, Wetlands, Arathi, Alterac (around rivers and ponds)"
        },
        {
            Name = "Fadeleaf",
            ItemLinkId = 3818,
            OrangeClassicHerb = 160,
            YellowClassicHerb = 185,
            GreenClassicHerb = 210,
            GreyClassicHerb = 260,
            Info = "Arathi, Swamp, Alterac, STV (clumps of shrubs and bushes)"
        },
        {
            Name = "Goldthorn",
            ItemLinkId = 3821,
            OrangeClassicHerb = 170,
            YellowClassicHerb = 195,
            GreenClassicHerb = 220,
            GreyClassicHerb = 270,
            Info = "STV, Arathi, Swamp (on rocks and hills)"
        },
        {
            Name = "Khadgar's Whisker",
            ItemLinkId = 3358,
            OrangeClassicHerb = 185,
            YellowClassicHerb = 210,
            GreenClassicHerb = 235,
            GreyClassicHerb = 285,
            Info = "STV, Arathi, Swamp, Hinterlands (under shrubs, base of trees)"
        },
        {
            Name = "Wintersbite",
            ItemLinkId = 3819,
            OrangeClassicHerb = 195,
            YellowClassicHerb = 225,
            GreenClassicHerb = 245,
            GreyClassicHerb = 295,
            Info = "only on Alterac Mountains"
        },
        {
            Name = "Firebloom",
            ItemLinkId = 4625,
            OrangeClassicHerb = 205,
            YellowClassicHerb = 225,
            GreenClassicHerb = 255,
            GreyClassicHerb = 305,
            Info = "Tanaris, Blasted Lands, Searing Gorge, Badlands (deserts)"
        },
        {
            Name = "Purple Lotus",
            ItemLinkId = 8831,
            OrangeClassicHerb = 210,
            YellowClassicHerb = 235,
            GreenClassicHerb = 260,
            GreyClassicHerb = 310,
            Info = "Azshara, Hinterlands, Tanaris (near high level ruins)"
        },
        {
            Name = "Wildvine",
            ItemLinkId = 8153,
            OrangeClassicHerb = nil,
            YellowClassicHerb = nil,
            GreenClassicHerb = nil,
            GreyClassicHerb = nil,
            Info = "found only with Purple Lotus"
        },
        {
            Name = "Arthas' Tears",
            ItemLinkId = 8836,
            OrangeClassicHerb = 220,
            YellowClassicHerb = 250,
            GreenClassicHerb = 270,
            GreyClassicHerb = 320,
            Info = "WPL, EPL, Felwood (open fields)"
        },
        {
            Name = "Sungrass",
            ItemLinkId = 8838,
            OrangeClassicHerb = 230,
            YellowClassicHerb = 255,
            GreenClassicHerb = 280,
            GreyClassicHerb = 330,
            Info = "Azshara, Hinterlands, Blasted Lands, EPL (open fields)"
        },
        {
            Name = "Blindweed",
            ItemLinkId = 8839,
            OrangeClassicHerb = 235,
            YellowClassicHerb = 260,
            GreenClassicHerb = 285,
            GreyClassicHerb = 335,
            Info = "Swamp, Un'goro (along rivers and some ponds)"
        },
        {
            Name = "Ghost Mushroom",
            ItemLinkId = 8845,
            OrangeClassicHerb = 245,
            YellowClassicHerb = 270,
            GreenClassicHerb = 295,
            GreyClassicHerb = 345,
            Info = "The Hinterlands, Desolace/Maraudon (only in caves)"
        },
        {
            Name = "Gromsblood",
            ItemLinkId = 8846,
            OrangeClassicHerb = 250,
            YellowClassicHerb = 275,
            GreenClassicHerb = 300,
            GreyClassicHerb = 350,
            Info = "Felwood, Desolace, Blasted Lands (near demon habitation)"
        },
        {
            Name = "Golden Sansam",
            ItemLinkId = 13464,
            OrangeClassicHerb = 260,
            YellowClassicHerb = 280,
            GreenClassicHerb = 310,
            GreyClassicHerb = 360,
            Info = "Un'goro, Azshara, EPL, Burning Steppes (open fields)"
        },
        {
            Name = "Dreamfoil",
            ItemLinkId = 13463,
            OrangeClassicHerb = 270,
            YellowClassicHerb = 295,
            GreenClassicHerb = 320,
            GreyClassicHerb = 370,
            Info = "Un'goro, Azshara, EPL, Burning Steppes (open fields)"
        },
        {
            Name = "Mountain Silversage",
            ItemLinkId = 13465,
            OrangeClassicHerb = 280,
            YellowClassicHerb = 305,
            GreenClassicHerb = 330,
            GreyClassicHerb = 380,
            Info = "Winterspring, Un'goro, Azshara, Burning Steppes (rocky outcroppings)"
        },
        {
            Name = "Plaguebloom",
            ItemLinkId = 13466,
            OrangeClassicHerb = 285,
            YellowClassicHerb = 310,
            GreenClassicHerb = 335,
            GreyClassicHerb = 385,
            Info = "EPL, WPL, Felwood (open fields, on plagued land)"
        },
        {
            Name = "Icecap",
            ItemLinkId = 13467,
            OrangeClassicHerb = 290,
            YellowClassicHerb = 315,
            GreenClassicHerb = 340,
            GreyClassicHerb = 390,
            Info = "Winterspring"
        },
        {
            Name = "Black Lotus",
            ItemLinkId = 13468,
            OrangeClassicHerb = 300,
            YellowClassicHerb = 340,
            GreenClassicHerb = 375,
            GreyClassicHerb = 400,
            Info = "Burning Steppes, Winterspring, EPL, Silithus (near elites)"
        },
        {
            Name = "Bloodvine",
            ItemLinkId = 19726,
            OrangeClassicHerb = 300,
            YellowClassicHerb = 340,
            GreenClassicHerb = 375,
            GreyClassicHerb = 400,
            Info = "Only in Zul'Gurub (requires Blood Scythe)"
        },
    },
}
