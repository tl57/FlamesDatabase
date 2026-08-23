--https://wowwiki-archive.fandom.com/wiki/Prospecting

ProspectingData = {
	profession = "Prospecting",
	columns = {
		{ colName = "Name",          id = "colName",    autoWidth = true, mergeRepeats = true },
		{ colName = "Skill",         id = "skill",      width = 39, mergeRepeats = true },
		{ colName = "%",             id = "%_Common_1", width = 39, },
		{ colName = "Common Loot",   id = "Common_1",   width = 380, },
		{ colName = "%",             id = "%_Uncommon", width = 40, },
		{ colName = "Uncommon Loot", id = "Uncommon",   width = 280, },
	},
	rows = {
		{
			expansion  = LE_EXPANSION_CLASSIC,
			oreName    = "Copper Ore",
			oreLink    = 2770,
			skillReq   = 20,
			commonGems = {
				{
					chance = "50",
					gems = {
						{
							name = "Malachite",
							itemLink = 774,
						},
						{
							name = "Tigerseye",
							itemLink = 818,
						}
					},
				},
			},
			extraGems  = {
				{
					chance = "10",
					gems = {
						{
							name = "Shadowgem",
							itemLink = 1210,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_CLASSIC,
			oreName    = "Tin Ore",
			oreLink    = 2771,
			skillReq   = 50,
			commonGems = {
				{
					chance = "37.5",
					gems = {
						{
							name = "Shadowgem",
							itemLink = 1210,
						},
						{
							name = "Moss Agate",
							itemLink = 1206,
						},
						{
							name = "Lesser Moonstone",
							itemLink = 1705,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "3.33",
					gems = {
						{
							name = "Jade",
							itemLink = 1529,
						},
						{
							name = "Citrine",
							itemLink = 3864,
						},
						{
							name = "Aquamarine",
							itemLink = 7909,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_CLASSIC,
			oreName    = "Iron Ore",
			oreLink    = 2772,
			skillReq   = 125,
			commonGems = {
				{
					chance = "30",
					gems = {
						{
							name = "Jade",
							itemLink = 1529,
						},
						{
							name = "Citrine",
							itemLink = 3864,
						},
						{
							name = "Lesser Moonstone",
							itemLink = 1705,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "5",
					gems = {
						{
							name = "Aquamarine",
							itemLink = 7909,
						},
						{
							name = "Star Ruby",
							itemLink = 7910,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_CLASSIC,
			oreName    = "Mithril Ore",
			oreLink    = 3858,
			skillReq   = 175,
			commonGems = {
				{
					chance = "30",
					gems = {
						{
							name = "Citrine",
							itemLink = 3864,
						},
						{
							name = "Aquamarine",
							itemLink = 7909,
						},
						{
							name = "Star Ruby",
							itemLink = 7910,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "2.5",
					gems = {
						{
							name = "Blue Sapphire",
							itemLink = 12361,
						},
						{
							name = "Huge Emerald",
							itemLink = 12364,
						},
						{
							name = "Large Opal",
							itemLink = 12799,
						},
						{
							name = "Azerothian Diamond",
							itemLink = 12800,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_CLASSIC,
			oreName    = "Thorium Ore",
			oreLink    = 10620,
			skillReq   = 250,
			commonGems = {
				{
					chance = "30",
					gems = {
						{
							name = "Star Ruby",
							itemLink = 7910,
						},
					},
				},
				{
					chance = "16",
					gems = {
						{
							name = "Blue Sapphire",
							itemLink = 12361,
						},
						{
							name = "Huge Emerald",
							itemLink = 12364,
						},
						{
							name = "Large Opal",
							itemLink = 12799,
						},
						{
							name = "Azerothian Diamond",
							itemLink = 12800,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "1.66",
					gems = {
						{
							name = "Blood Garnet",
							itemLink = 23077,
						},
						{
							name = "Deep Peridot",
							itemLink = 23079,
						},
						{
							name = "Flame Spessarite",
							itemLink = 21929,
						},
						{
							name = "Shadow Draenite",
							itemLink = 23107,
						},
						{
							name = "Golden Draenite",
							itemLink = 23112,
						},
						{
							name = "Azure Moonstone",
							itemLink = 23117,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_BURNING_CRUSADE,
			oreName    = "Fel Iron Ore",
			oreLink    = 23424,
			skillReq   = 275,
			commonGems = {
				{
					chance = "17",
					gems = {
						{
							name = "Blood Garnet",
							itemLink = 23077,
						},
						{
							name = "Deep Peridot",
							itemLink = 23079,
						},
						{
							name = "Flame Spessarite",
							itemLink = 21929,
						},
						{
							name = "Shadow Draenite",
							itemLink = 23107,
						},
						{
							name = "Golden Draenite",
							itemLink = 23112,
						},
						{
							name = "Azure Moonstone",
							itemLink = 23117,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "1",
					gems = {
						{
							name = "Living Ruby",
							itemLink = 23436,
						},
						{
							name = "Noble Topaz",
							itemLink = 23439,
						},
						{
							name = "Dawnstone",
							itemLink = 23440,
						},
						{
							name = "Talasite",
							itemLink = 23437,
						},
						{
							name = "Star of Elune",
							itemLink = 23438,
						},
						{
							name = "Nightseye",
							itemLink = 23441,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_BURNING_CRUSADE,
			oreName    = "Adamantite Ore",
			oreLink    = 23425,
			skillReq   = 325,
			commonGems = {
				{
					chance = "65",
					gems = {
						{
							name = "Adamantite Powder",
							itemLink = 24243,
						},
					},
				},
				{
					chance = "19",
					gems = {
						{
							name = "Blood Garnet",
							itemLink = 23077,
						},
						{
							name = "Deep Peridot",
							itemLink = 23079,
						},
						{
							name = "Flame Spessarite",
							itemLink = 21929,
						},
						{
							name = "Shadow Draenite",
							itemLink = 23107,
						},
						{
							name = "Golden Draenite",
							itemLink = 23112,
						},
						{
							name = "Azure Moonstone",
							itemLink = 23117,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "3",
					gems = {
						{
							name = "Living Ruby",
							itemLink = 23436,
						},
						{
							name = "Noble Topaz",
							itemLink = 23439,
						},
						{
							name = "Dawnstone",
							itemLink = 23440,
						},
						{
							name = "Talasite",
							itemLink = 23437,
						},
						{
							name = "Star of Elune",
							itemLink = 23438,
						},
						{
							name = "Nightseye",
							itemLink = 23441,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
			oreName    = "Cobalt Ore",
			oreLink    = 36909,
			skillReq   = 350,
			commonGems = {
				{
					chance = "25",
					gems = {
						{
							name = "Chalcedony",
							itemLink = 36923,
						},
						{
							name = "Dark Jade",
							itemLink = 36932,
						},
						{
							name = "Bloodstone",
							itemLink = 36917,
						},
						{
							name = "Sun Crystal",
							itemLink = 36920,
						},
						{
							name = "Shadow Crystal",
							itemLink = 36926,
						},
						{
							name = "Huge Citrine",
							itemLink = 36929,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "1.3",
					gems = {
						{
							name = "Forest Emerald",
							itemLink = 36933,
						},
						{
							name = "Scarlet Ruby",
							itemLink = 36918,
						},
						{
							name = "Twilight Opal",
							itemLink = 36927,
						},
						{
							name = "Autumn's Glow",
							itemLink = 36921,
						},
						{
							name = "Sky Sapphire",
							itemLink = 36924,
						},
						{
							name = "Monarch Topaz",
							itemLink = 36930,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
			oreName    = "Saronite Ore",
			oreLink    = 36912,
			skillReq   = 400,
			commonGems = {
				{
					chance = "18",
					gems = {
						{
							name = "Chalcedony",
							itemLink = 36923,
						},
						{
							name = "Dark Jade",
							itemLink = 36932,
						},
						{
							name = "Bloodstone",
							itemLink = 36917,
						},
						{
							name = "Sun Crystal",
							itemLink = 36920,
						},
						{
							name = "Shadow Crystal",
							itemLink = 36926,
						},
						{
							name = "Huge Citrine",
							itemLink = 36929,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "4",
					gems = {
						{
							name = "Forest Emerald",
							itemLink = 36933,
						},
						{
							name = "Scarlet Ruby",
							itemLink = 36918,
						},
						{
							name = "Twilight Opal",
							itemLink = 36927,
						},
						{
							name = "Autumn's Glow",
							itemLink = 36921,
						},
						{
							name = "Sky Sapphire",
							itemLink = 36924,
						},
						{
							name = "Monarch Topaz",
							itemLink = 36930,
						},
					},
				},
			},
		},
		{
			expansion  = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
			oreName    = "Titanium Ore",
			oreLink    = 36910,
			skillReq   = 450,
			commonGems = {
				{
					chance = "65",
					gems = {
						{
							name = "Titanium Powder",
							itemLink = 46849,
						},
					},
				},
				{
					chance = "25",
					gems = {
						{
							name = "Chalcedony",
							itemLink = 36923,
						},
						{
							name = "Dark Jade",
							itemLink = 36932,
						},
						{
							name = "Bloodstone",
							itemLink = 36917,
						},
						{
							name = "Sun Crystal",
							itemLink = 36920,
						},
						{
							name = "Shadow Crystal",
							itemLink = 36926,
						},
						{
							name = "Huge Citrine",
							itemLink = 36929,
						},
					},
				},
				{
					chance = "4",
					gems = {
						{
							name = "Forest Emerald",
							itemLink = 36933,
						},
						{
							name = "Scarlet Ruby",
							itemLink = 36918,
						},
						{
							name = "Twilight Opal",
							itemLink = 36927,
						},
						{
							name = "Autumn's Glow",
							itemLink = 36921,
						},
						{
							name = "Sky Sapphire",
							itemLink = 36924,
						},
						{
							name = "Monarch Topaz",
							itemLink = 36930,
						},
					},
				},
			},
			extraGems  = {
				{
					chance = "5",
					gems = {
						{
							name = "Cardinal Ruby",
							itemLink = 36919,
						},
						{
							name = "Ametrine",
							itemLink = 36931,
						},
						{
							name = "King's Amber",
							itemLink = 36922,
						},
						{
							name = "Eye of Zul",
							itemLink = 36934,
						},
						{
							name = "Majestic Zircon",
							itemLink = 36925,
						},
						{
							name = "Dreadstone",
							itemLink = 36928,
						},
					},
				},
			},
		},
	}
}
