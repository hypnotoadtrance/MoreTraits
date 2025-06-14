require "Foraging/forageDefinitions";
MoreTraitsSkills = {
	incomprehensive = {
		name = "incomprehensive",
		type = "trait",
		visionBonus = -1.0,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["ForestRarities"] = -5,
			["Medical"] = -5,
			["Ammunition"] = -5,
			["JunkWeapons"] = -5,
		},
	},
	scrounger = {
		name = "scrounger",
		type = "trait",
		visionBonus = 1.0,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["ForestRarities"] = 5,
			["Medical"] = 5,
			["Ammunition"] = 5,
			["JunkWeapons"] = 5,
		},
	},
	vagabond = {
		name = "vagabond",
		type = "trait",
		visionBonus = 0.7,
		weatherEffect = 13,
		darknessEffect = 3,
		specialisations = {
			["MedicinalPlants"] = 5,
			["Trash"] = 10,
		},
	},
	wildsman = {
		name = "wildsman",
		type = "trait",
		visionBonus = 0.5,
		weatherEffect = 13,
		darknessEffect = 5,
		specialisations = {
			["Animals"] = 5,
			["Berries"] = 3,
			["Mushrooms"] = 3,
			["MedicinalPlants"] = 3,
		},
	},
	specfood = {
		name = "specfood",
		type = "trait",
		visionBonus = 0.4,
		weatherEffect = 13,
		darknessEffect = 5,
		specialisations = {
			["Animals"] = 5,
			["Berries"] = 5,
			["Mushrooms"] = 5,
			["MedicinalPlants"] = 5,
			["WildPlants"] = 5,
		},
	},
	natural = {
		name = "natural",
		type = "trait",
		visionBonus = 0.2,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["Animals"] = 5,
			["Berries"] = 5,
			["Mushrooms"] = 5,
			["JunkFood"] = 5,
			["MedicinalPlants"] = 3,
			["WildPlants"] = 5,
		},
	},
	specaid = {
		name = "specaid",
		type = "trait",
		visionBonus = 0.2,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["MedicinalPlants"] = 15,
			["WildPlants"] = 5,
			["Crops"] = 5,
			["Berries"] = 5,
			["Mushrooms"] = 5,
		},
	},
	gourmand = {
		name = "gourmand",
		type = "trait",
		visionBonus = 0,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["Animals"] = 3,
			["Berries"] = 3,
			["Mushrooms"] = 3,
			["JunkFood"] = 3,
		},
	},
	gunspecialist = {
		name = "gunspecialist",
		type = "trait",
		visionBonus = 0.5,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["Ammunition"] = 3,
		},
	},
	ingenuitive = {
		name = "ingenuitive",
		type = "trait",
		visionBonus = 0,
		weatherEffect = 0,
		darknessEffect = 0,
		specialisations = {
			["Insects"] = 5,
			["FishBait"] = 5,
		},
	},
};
for skillName, skillDef in pairs(MoreTraitsSkills) do
	--Disable Custom Forage Definitions for More Traits until such time as issue can be resolved.
	--table.insert(forageSkills, skillDef);
end