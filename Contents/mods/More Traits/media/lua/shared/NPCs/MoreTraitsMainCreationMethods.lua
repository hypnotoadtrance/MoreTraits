require('NPCs/MainCreationMethods');

local function initToadTraits()
    local gunspecialist = TraitFactory.addTrait("gunspecialist", getText("UI_trait_gunspecialist"), 8, getText("UI_trait_gunspecialistdesc"), false, false);
    gunspecialist:addXPBoost(Perks.Aiming, 2);
    gunspecialist:addXPBoost(Perks.Reloading, 2);
    local preparedfood = TraitFactory.addTrait("preparedfood", getText("UI_trait_preparedfood"), 1, getText("UI_trait_preparedfooddesc"), false, false);
    local preparedammo = TraitFactory.addTrait("preparedammo", getText("UI_trait_preparedammo"), 1, getText("UI_trait_preparedammodesc"), false, false);
    local preparedmedical = TraitFactory.addTrait("preparedmedical", getText("UI_trait_preparedmedical"), 1, getText("UI_trait_preparedmedicaldesc"), false, false);
    local preparedrepair = TraitFactory.addTrait("preparedrepair", getText("UI_trait_preparedrepair"), 1, getText("UI_trait_preparedrepairdesc"), false, false);
    local preparedcamp = TraitFactory.addTrait("preparedcamp", getText("UI_trait_preparedcamp"), 1, getText("UI_trait_preparedcampdesc"), false, false);
    local preparedweapon = TraitFactory.addTrait("preparedweapon", getText("UI_trait_preparedweapon"), 1, getText("UI_trait_preparedweapondesc"), false, false);
    local preparedpack = TraitFactory.addTrait("preparedpack", getText("UI_trait_preparedpack"), 1, getText("UI_trait_preparedpackdesc"), false, false);
    local swift = TraitFactory.addTrait("swift", getText("UI_trait_swift"), 2, getText("UI_trait_swiftdesc"), false, false);
    swift:addXPBoost(Perks.Lightfoot, 1);
    local generator = TraitFactory.addTrait("generator", getText("UI_trait_generator"), 2, getText("UI_trait_generatordesc"), false, false);
    generator:getFreeRecipes():add("Generator");
    local ingenuitive = TraitFactory.addTrait("ingenuitive", getText("UI_trait_ingenuitive"), 6, getText("UI_trait_ingenuitivedesc"), false, false);
    ingenuitive:getFreeRecipes():add("Generator");
    ingenuitive:getFreeRecipes():add("Make Mildew Cure");
    ingenuitive:getFreeRecipes():add("Make Flies Cure");
    ingenuitive:getFreeRecipes():add("Make Cake Batter");
    ingenuitive:getFreeRecipes():add("Make Pie Dough");
    ingenuitive:getFreeRecipes():add("Make Bread Dough");
    ingenuitive:getFreeRecipes():add("Herbalist");
    ingenuitive:getFreeRecipes():add("Make Stick Trap");
    ingenuitive:getFreeRecipes():add("Make Snare Trap");
    ingenuitive:getFreeRecipes():add("Make Wooden Cage Trap");
    ingenuitive:getFreeRecipes():add("Make Trap Box");
    ingenuitive:getFreeRecipes():add("Make Cage Trap");
    ingenuitive:getFreeRecipes():add("Basic Mechanics");
    ingenuitive:getFreeRecipes():add("Intermediate Mechanics");
    ingenuitive:getFreeRecipes():add("Advanced Mechanics")
    ingenuitive:getFreeRecipes():add("Make Fishing Rod");
    ingenuitive:getFreeRecipes():add("Fix Fishing Rod");
    ingenuitive:getFreeRecipes():add("Get Wire Back");
    ingenuitive:getFreeRecipes():add("Make Fishing Net");
    ingenuitive:getFreeRecipes():add("Make Remote Controller V1");
    ingenuitive:getFreeRecipes():add("Make Remote Controller V2");
    ingenuitive:getFreeRecipes():add("Make Remote Controller V3");
    ingenuitive:getFreeRecipes():add("Make Remote Trigger");
    ingenuitive:getFreeRecipes():add("Make Timer");
    ingenuitive:getFreeRecipes():add("Craft Makeshift Radio");
    ingenuitive:getFreeRecipes():add("Craft Makeshift HAM Radio");
    ingenuitive:getFreeRecipes():add("Craft Makeshift Walkie Talkie");
    ingenuitive:getFreeRecipes():add("Make Aerosol bomb");
    ingenuitive:getFreeRecipes():add("Make Flame bomb");
    ingenuitive:getFreeRecipes():add("Make Pipe bomb");
    ingenuitive:getFreeRecipes():add("Make Noise generator");
    ingenuitive:getFreeRecipes():add("Make Smoke Bomb");
    ingenuitive:getFreeRecipes():add("Make Metal Walls");
    ingenuitive:getFreeRecipes():add("Make Metal Fences");
    ingenuitive:getFreeRecipes():add("Make Metal Containers");
    ingenuitive:getFreeRecipes():add("Make Metal Sheet");
    ingenuitive:getFreeRecipes():add("Make Small Metal Sheet");
    ingenuitive:getFreeRecipes():add("Make Metal Roof");
    local olympian = TraitFactory.addTrait("olympian", getText("UI_trait_olympian"), 6, getText("UI_trait_olympiandesc"), false, false);
    olympian:addXPBoost(Perks.Sprinting, 1);
    olympian:addXPBoost(Perks.Fitness, 1);
    local bouncer = TraitFactory.addTrait("bouncer", getText("UI_trait_bouncer"), 5, getText("UI_trait_bouncerdesc"), false, false);
    bouncer:addXPBoost(Perks.Strength, 1);
    bouncer:addXPBoost(Perks.SmallBlunt, 1);
    local martial = TraitFactory.addTrait("martial", getText("UI_trait_martial"), 5, getText("UI_trait_martialdesc"), false, false);
    martial:addXPBoost(Perks.Fitness, 1);
    martial:addXPBoost(Perks.SmallBlunt, 1);
    local flexible = TraitFactory.addTrait("flexible", getText("UI_trait_flexible"), 2, getText("UI_trait_flexibledesc"), false, false);
    flexible:addXPBoost(Perks.Nimble, 1);
    local grunt = TraitFactory.addTrait("grunt", getText("UI_trait_grunt"), 4, getText("UI_trait_gruntdesc"), false, false);
    grunt:addXPBoost(Perks.Woodwork, 1);
    grunt:addXPBoost(Perks.SmallBlunt, 1);
    local quiet = TraitFactory.addTrait("quiet", getText("UI_trait_quiet"), 3, getText("UI_trait_quietdesc"), false, false);
    quiet:addXPBoost(Perks.Sneak, 1);
    local tinkerer = TraitFactory.addTrait("tinkerer", getText("UI_trait_tinkerer"), 6, getText("UI_trait_tinkererdesc"), false, false);
    tinkerer:addXPBoost(Perks.Electricity, 1);
    tinkerer:addXPBoost(Perks.Mechanics, 1);
    tinkerer:addXPBoost(Perks.Tailoring, 1);
    local preparedcar = TraitFactory.addTrait("preparedcar", getText("UI_trait_preparedcar"), 1, getText("UI_trait_preparedcardesc"), false, false);
    local scrapper = TraitFactory.addTrait("scrapper", getText("UI_trait_scrapper"), 3, getText("UI_trait_scrapperdesc"), false, false);
    scrapper:addXPBoost(Perks.MetalWelding, 1);
    scrapper:addXPBoost(Perks.Maintenance, 1);
    scrapper:getFreeRecipes():add("Make Metal Pipe");
    scrapper:getFreeRecipes():add("Make Metal Sheet");
    local wildsman = TraitFactory.addTrait("wildsman", getText("UI_trait_wildsman"), 8, getText("UI_trait_wildsmandesc"), false, false);
    wildsman:addXPBoost(Perks.Fishing, 1);
    wildsman:addXPBoost(Perks.Trapping, 1);
    wildsman:addXPBoost(Perks.PlantScavenging, 1);
    wildsman:addXPBoost(Perks.Spear, 1);
    wildsman:getFreeRecipes():add("Make Stick Trap");
    wildsman:getFreeRecipes():add("Make Snare Trap");
    wildsman:getFreeRecipes():add("Make Fishing Rod");
    wildsman:getFreeRecipes():add("Fix Fishing Rod");
    local natural = TraitFactory.addTrait("natural", getText("UI_trait_natural"), 5, getText("UI_trait_naturaldesc"), false, false);
    natural:addXPBoost(Perks.Cooking, 1);
    natural:addXPBoost(Perks.PlantScavenging, 1);
    local bladetwirl = TraitFactory.addTrait("bladetwirl", getText("UI_trait_bladetwirl"), 5, getText("UI_trait_bladetwirldesc"), false, false);
    bladetwirl:addXPBoost(Perks.LongBlade, 1);
    bladetwirl:addXPBoost(Perks.SmallBlade, 1);
    local blunttwirl = TraitFactory.addTrait("blunttwirl", getText("UI_trait_blunttwirl"), 5, getText("UI_trait_blunttwirldesc"), false, false);
    blunttwirl:addXPBoost(Perks.SmallBlunt, 1);
    blunttwirl:addXPBoost(Perks.Blunt, 1);
    local scrounger = TraitFactory.addTrait("scrounger", getText("UI_trait_scrounger"), 5, getText("UI_trait_scroungerdesc"), false, true);
    local antique = TraitFactory.addTrait("antique", getText("UI_trait_antique"), 4, getText("UI_trait_antiquedesc"), false, true);
    local evasive = TraitFactory.addTrait("evasive", getText("UI_trait_evasive"), 8, getText("UI_trait_evasivedesc"), false, false);
    evasive:addXPBoost(Perks.Nimble, 1);
    local blissful = TraitFactory.addTrait("blissful", getText("UI_trait_blissful"), 2, getText("UI_trait_blissfuldesc"), false, false);
    local specweapons = TraitFactory.addTrait("specweapons", getText("UI_trait_specweapons"), 12, getText("UI_trait_specweaponsdesc"), false, false);
    specweapons:addXPBoost(Perks.Axe, 2);
    specweapons:addXPBoost(Perks.Spear, 2);
    specweapons:addXPBoost(Perks.SmallBlunt, 2);
    specweapons:addXPBoost(Perks.Blunt, 2);
    specweapons:addXPBoost(Perks.LongBlade, 2);
    specweapons:addXPBoost(Perks.SmallBlade, 2);
    specweapons:addXPBoost(Perks.Maintenance, 2);
    local speccrafting = TraitFactory.addTrait("speccrafting", getText("UI_trait_speccrafting"), 12, getText("UI_trait_speccraftingdesc"), false, false);
    speccrafting:addXPBoost(Perks.Woodwork, 2);
    speccrafting:addXPBoost(Perks.Electricity, 2);
    speccrafting:addXPBoost(Perks.MetalWelding, 2);
    speccrafting:addXPBoost(Perks.Mechanics, 2);
    speccrafting:addXPBoost(Perks.Tailoring, 2);
    local specfood = TraitFactory.addTrait("specfood", getText("UI_trait_specfood"), 12, getText("UI_trait_specfooddesc"), false, false);
    specfood:addXPBoost(Perks.Cooking, 2);
    specfood:addXPBoost(Perks.Trapping, 2);
    specfood:addXPBoost(Perks.PlantScavenging, 2);
    specfood:addXPBoost(Perks.Farming, 2);
    specfood:addXPBoost(Perks.Fishing, 2);
    local specguns = TraitFactory.addTrait("specguns", getText("UI_trait_specguns"), 12, getText("UI_trait_specgunsdesc"), false, false);
    specguns:addXPBoost(Perks.Aiming, 4);
    specguns:addXPBoost(Perks.Reloading, 4);
    local specmove = TraitFactory.addTrait("specmove", getText("UI_trait_specmove"), 12, getText("UI_trait_specmovedesc"), false, false);
    specmove:addXPBoost(Perks.Lightfoot, 2);
    specmove:addXPBoost(Perks.Sprinting, 2);
    specmove:addXPBoost(Perks.Sneak, 2);
    specmove:addXPBoost(Perks.Nimble, 2);
    local specaid = TraitFactory.addTrait("specaid", getText("UI_trait_specaid"), 12, getText("UI_trait_specaiddesc"), false, false);
    specaid:addXPBoost(Perks.Doctor, 8);
    specaid:getFreeRecipes():add("Improvise Bandage");
    specaid:getFreeRecipes():add("Improvise Suture");
    specaid:getFreeRecipes():add("Improvise Splint");
    specaid:getFreeRecipes():add("Improvise Suture Holder");
    specaid:getFreeRecipes():add("Improvise Disinfectant");
    specaid:getFreeRecipes():add("Improvise Painkillers");
    specaid:getFreeRecipes():add("Improvise Antibiotics");
    specaid:getFreeRecipes():add("Improvise Antidepressants");
    specaid:getFreeRecipes():add("Improvise Betablockers");
    specaid:getFreeRecipes():add("Improvise Sleeping Pills");
    specaid:getFreeRecipes():add("Improvise Zombification Cure");
    local gordanite = TraitFactory.addTrait("gordanite", getText("UI_trait_gordanite"), 6, getText("UI_trait_gordanitedesc"), false, false);
    gordanite:addXPBoost(Perks.Blunt, 1);
    local indefatigable = TraitFactory.addTrait("indefatigable", getText("UI_trait_indefatigable"), 10, getText("UI_trait_indefatigabledesc"), false, false);
    local hardy = TraitFactory.addTrait("hardy", getText("UI_trait_hardy"), 6, getText("UI_trait_hardydesc"), false, false);
    hardy:addXPBoost(Perks.Strength, 1);
    local bluntperk = TraitFactory.addTrait("problunt", getText("UI_trait_problunt"), 7, getText("UI_trait_probluntdesc"), false, false);
    bluntperk:addXPBoost(Perks.SmallBlunt, 1);
    bluntperk:addXPBoost(Perks.Blunt, 1);
    local bladeperk = TraitFactory.addTrait("problade", getText("UI_trait_problade"), 7, getText("UI_trait_probladedesc"), false, false);
    bladeperk:addXPBoost(Perks.SmallBlade, 1);
    bladeperk:addXPBoost(Perks.LongBlade, 1);
    bladeperk:addXPBoost(Perks.Axe, 1);
    local gunperk = TraitFactory.addTrait("progun", getText("UI_trait_progun"), 7, getText("UI_trait_progundesc"), false, false);
    gunperk:addXPBoost(Perks.Aiming, 1);
    gunperk:addXPBoost(Perks.Reloading, 1);
    local actionhero = TraitFactory.addTrait("actionhero", getText("UI_trait_actionhero"), 8, getText("UI_trait_actionherodesc"), false, false);
    -- local fast = TraitFactory.addTrait("fast", getText("UI_trait_fast"), 6, getText("UI_trait_fastdesc"), false, false);
    local spearperk = TraitFactory.addTrait("prospear", getText("UI_trait_prospear"), 7, getText("UI_trait_prospeardesc"), false, false);
    spearperk:addXPBoost(Perks.Spear, 2);
    local thickblood = TraitFactory.addTrait("thickblood", getText("UI_trait_thickblood"), 4, getText("UI_trait_thickblooddesc"), false, false);
    local expertdriver = TraitFactory.addTrait("expertdriver", getText("UI_trait_expertdriver"), 5, getText("UI_trait_expertdriverdesc"), false, false);
    local superimmune = TraitFactory.addTrait("superimmune", getText("UI_trait_superimmune"), 10, getText("UI_trait_superimmunedesc"), false, false);
    local packmule = TraitFactory.addTrait("packmule", getText("UI_trait_packmule"), 7, getText("UI_trait_packmuledesc"), false, false);
    local graverobber = TraitFactory.addTrait("graverobber", getText("UI_trait_graverobber"), 7, getText("UI_trait_graverobberdesc"), false, false);
    local gourmand = TraitFactory.addTrait("gourmand", getText("UI_trait_gourmand"), 4, getText("UI_trait_gourmanddesc"), false, false);
    gourmand:addXPBoost(Perks.Cooking, 1);
    local gymgoer = TraitFactory.addTrait("gymgoer", getText("UI_trait_gymgoer"), 5, getText("UI_trait_gymgoerdesc"), false, false);
    gymgoer:addXPBoost(Perks.Strength, 1);
    gymgoer:addXPBoost(Perks.Fitness, 1);
	local vagabond = TraitFactory.addTrait("vagabond", getText("UI_trait_vagabond"), 2, getText("UI_trait_vagabonddesc"), false, false);
    --===========--
    --Bad Traits--
    --===========--
    local packmouse = TraitFactory.addTrait("packmouse", getText("UI_trait_packmouse"), -7, getText("UI_trait_packmousedesc"), false, false);
    local injured = TraitFactory.addTrait("injured", getText("UI_trait_injured"), -4, getText("UI_trait_injureddesc"), false, false);
    local drinker = TraitFactory.addTrait("drinker", getText("UI_trait_drinker"), -12, getText("UI_trait_drinkerdesc"), false, false);
    local broke = TraitFactory.addTrait("broke", getText("UI_trait_broke"), -8, getText("UI_trait_brokedesc"), false, false);
    local butterfingers = TraitFactory.addTrait("butterfingers", getText("UI_trait_butterfingers"), -10, getText("UI_trait_butterfingersdesc"), false, false);
    local incomprehensive = TraitFactory.addTrait("incomprehensive", getText("UI_trait_incomprehensive"), -10, getText("UI_trait_incomprehensivedesc"), false, true);
    local depressive = TraitFactory.addTrait("depressive", getText("UI_trait_depressive"), -4, getText("UI_trait_depressivedesc"), false, false);
    local selfdestructive = TraitFactory.addTrait("selfdestructive", getText("UI_trait_selfdestructive"), -4, getText("UI_trait_selfdestructivedesc"), false, false);
    local badteeth = TraitFactory.addTrait("badteeth", getText("UI_trait_badteeth"), -2, getText("UI_trait_badteethdesc"), false, false);
    local albino = TraitFactory.addTrait("albino", getText("UI_trait_albino"), -5, getText("UI_trait_albinodesc"), false, false);
    local amputee = TraitFactory.addTrait("amputee", getText("UI_trait_amputee"), -16, getText("UI_trait_amputeedesc"), false, false);
    local poordriver = TraitFactory.addTrait("poordriver", getText("UI_trait_poordriver"), -5, getText("UI_trait_poordriverdesc"), false, false);
    --  local gimp = TraitFactory.addTrait("gimp", getText("UI_trait_gimp"), -8, getText("UI_trait_gimpdesc"), false, false);
    local anemic = TraitFactory.addTrait("anemic", getText("UI_trait_anemic"), -4, getText("UI_trait_anemicdesc"), false, false);
    local immunocompromised = TraitFactory.addTrait("immunocompromised", getText("UI_trait_immunocompromised"), -10, getText("UI_trait_immunocompromiseddesc"), false, false);
    local ascetic = TraitFactory.addTrait("ascetic", getText("UI_trait_ascetic"), -4, getText("UI_trait_asceticdesc"), false, false);
    local fearful = TraitFactory.addTrait("fearful", getText("UI_trait_fearful"), -7, getText("UI_trait_fearfuldesc"), false, false);
    --Exclusives
    TraitFactory.setMutualExclusive("preparedfood", "preparedammo");
    TraitFactory.setMutualExclusive("preparedfood", "preparedrepair");
    TraitFactory.setMutualExclusive("preparedfood", "preparedmedical");
    TraitFactory.setMutualExclusive("preparedfood", "preparedcamp");
    TraitFactory.setMutualExclusive("preparedfood", "preparedweapon");
    TraitFactory.setMutualExclusive("preparedammo", "preparedrepair");
    TraitFactory.setMutualExclusive("preparedammo", "preparedmedical");
    TraitFactory.setMutualExclusive("preparedammo", "preparedcamp");
    TraitFactory.setMutualExclusive("preparedrepair", "preparedmedical");
    TraitFactory.setMutualExclusive("preparedrepair", "preparedweapon");
    TraitFactory.setMutualExclusive("preparedmedical", "preparedcamp");
    TraitFactory.setMutualExclusive("preparedmedical", "preparedweapon");
    TraitFactory.setMutualExclusive("preparedcamp", "preparedrepair");
    TraitFactory.setMutualExclusive("preparedweapon", "preparedammo");
    TraitFactory.setMutualExclusive("preparedweapon", "preparedcamp");
    TraitFactory.setMutualExclusive("preparedpack", "preparedammo");
    TraitFactory.setMutualExclusive("preparedpack", "preparedrepair");
    TraitFactory.setMutualExclusive("preparedpack", "preparedmedical");
    TraitFactory.setMutualExclusive("preparedpack", "preparedcamp");
    TraitFactory.setMutualExclusive("preparedpack", "preparedfood");
    TraitFactory.setMutualExclusive("preparedpack", "preparedweapon");
    TraitFactory.setMutualExclusive("preparedcar", "preparedweapon");
    TraitFactory.setMutualExclusive("preparedcar", "preparedfood");
    TraitFactory.setMutualExclusive("preparedcar", "preparedammo");
    TraitFactory.setMutualExclusive("preparedcar", "preparedrepair");
    TraitFactory.setMutualExclusive("preparedcar", "preparedmedical");
    TraitFactory.setMutualExclusive("preparedcar", "preparedcamp");
    TraitFactory.setMutualExclusive("preparedcar", "preparedpack");
    TraitFactory.setMutualExclusive("quiet", "Clumsy");
    TraitFactory.setMutualExclusive("flexible", "Obese");
    TraitFactory.setMutualExclusive("olympian", "Unfit");
    TraitFactory.setMutualExclusive("scrounger", "incomprehensive");
    TraitFactory.setMutualExclusive("olympian", "Jogger");
    TraitFactory.setMutualExclusive("blissful", "depressive");
    TraitFactory.setMutualExclusive("blissful", "selfdestructive");
    TraitFactory.setMutualExclusive("specweapons", "speccrafting");
    TraitFactory.setMutualExclusive("specweapons", "specfood");
    TraitFactory.setMutualExclusive("specweapons", "specguns");
    TraitFactory.setMutualExclusive("specweapons", "specmove");
    TraitFactory.setMutualExclusive("specweapons", "specaid");
    TraitFactory.setMutualExclusive("speccrafting", "specfood");
    TraitFactory.setMutualExclusive("speccrafting", "specguns");
    TraitFactory.setMutualExclusive("speccrafting", "specmove");
    TraitFactory.setMutualExclusive("specaid", "specmove");
    TraitFactory.setMutualExclusive("speccrafting", "specaid");
    TraitFactory.setMutualExclusive("specfood", "specguns");
    TraitFactory.setMutualExclusive("specfood", "specmove");
    TraitFactory.setMutualExclusive("specguns", "specmove");
    TraitFactory.setMutualExclusive("specguns", "specaid");
    TraitFactory.setMutualExclusive("specfood", "specaid");
    TraitFactory.setMutualExclusive("problunt", "problade");
    TraitFactory.setMutualExclusive("problunt", "progun");
    TraitFactory.setMutualExclusive("problade", "progun");
    TraitFactory.setMutualExclusive("prospear", "progun");
    TraitFactory.setMutualExclusive("prospear", "problunt");
    TraitFactory.setMutualExclusive("prospear", "problade");
    TraitFactory.setMutualExclusive("actionhero", "bouncer");
    TraitFactory.setMutualExclusive("thickblood", "anemic");
    TraitFactory.setMutualExclusive("generator", "ingenuitive");
    TraitFactory.setMutualExclusive("expertdriver", "poordriver");
    TraitFactory.setMutualExclusive("Resilient", "superimmune");
    TraitFactory.setMutualExclusive("Resilient", "immunocompromised");
    TraitFactory.setMutualExclusive("superimmune", "immunocompromised");
    TraitFactory.setMutualExclusive("ProneToIllness", "superimmune");
    TraitFactory.setMutualExclusive("ProneToIllness", "immunocompromised");
    TraitFactory.setMutualExclusive("packmule", "packmouse");
    TraitFactory.setMutualExclusive("gourmand", "ascetic");
    TraitFactory.setMutualExclusive("fearful", "Desensitized");
    TraitFactory.setMutualExclusive("fearful", "Brave");
    TraitFactory.setMutualExclusive("blissful", "Smoker");
    --TraitFactory.setMutualExclusive("gimp", "fast");
    --TraitFactory.setMutualExclusive("blissful", "Brooding");
end

Events.OnGameBoot.Add(initToadTraits);
