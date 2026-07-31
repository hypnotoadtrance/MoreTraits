require "Foraging/forageDefinitions";

local ToadTraits = {
    incomprehensive = {
        name = "ToadTraits:incomprehensive",
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
        testFuncs = {},
    },
    scrounger = {
        name = "ToadTraits:scrounger",
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
        testFuncs = {},
    },
    vagabond = {
        name = "ToadTraits:vagabond",
        type = "trait",
        visionBonus = 0.7,
        weatherEffect = 13,
        darknessEffect = 3,
        specialisations = {
            ["MedicinalPlants"] = 5,
            ["Trash"] = 10,
        },
        testFuncs = {},
    },
    wildsman = {
        name = "ToadTraits:wildsman",
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
        testFuncs = {},
    },
    specfood = {
        name = "ToadTraits:specfood",
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
        testFuncs = {},
    },
    natural = {
        name = "ToadTraits:natural",
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
        testFuncs = {},
    },
    specaid = {
        name = "ToadTraits:specaid",
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
        testFuncs = {},
    },
    gourmand = {
        name = "ToadTraits:gourmand",
        type = "trait",
        visionBonus = 0,
        weatherEffect = 0,
        darknessEffect = 0,
        specialisations = {
            ["Animals"] = 3,
            ["Berries"] = 3,
            ["Mushrooms"] = 25,
            ["JunkFood"] = 3,
        },
        testFuncs = {},
    },
    gunspecialist = {
        name = "ToadTraits:gunspecialist",
        type = "trait",
        visionBonus = 0.5,
        weatherEffect = 0,
        darknessEffect = 0,
        specialisations = {
            ["Ammunition"] = 3,
        },
        testFuncs = {},
    },
    ingenuitive = {
        name = "ToadTraits:ingenuitive",
        type = "trait",
        visionBonus = 0,
        weatherEffect = 0,
        darknessEffect = 0,
        specialisations = {
            ["Insects"] = 5,
            ["FishBait"] = 5,
        },
        testFuncs = {},
    },
};

local function onPreAddSkillDefs(forageSystem)
    for _, def in pairs(ToadTraits) do
        forageSystem.addSkillDef(def);
    end
end

Events.preAddSkillDefs.Add(onPreAddSkillDefs);