require('NPCs/MainCreationMethods');
require("Items/Distributions");
require("Items/ProceduralDistributions");

--[[
Changelog Notes:
Action Hero wasn't halving damage.
Hardy wasn't accounting for Sprinting.
Typo in Martial Artist
General code optimization pass.
--]]

--Global Variables
skipxpadd = false;
suspendevasive = false;
internalTick = 0;

local function tableContains(t, e)
    for _, value in pairs(t) do
        if value == e then
            return true
        end
    end
    return false
end
local function istable(t)
    local type = type(t)
    return type == 'table'
end
local function tablelength(T)
    local count = 0
    if istable(T) == true then
        for _ in pairs(T) do
            count = count + 1
        end
    else
        count = 1
    end
    return count
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function ZombificationCure_OnCreate(items, result, player)
    local bodyDamage = player:getBodyDamage();
    local stats = player:getStats();
    bodyDamage:setInfectionLevel(0);
    bodyDamage:setInf(false);
    bodyDamage:setInfectionGrowthRate(0);
    bodyDamage:setUnhappynessLevel(0);
    stats:setEndurance(0);
    stats:setBoredom(0);
    stats:setStress(0);
end
function ZombPatty_OnCreate(items, result, player)
    local stats = player:getStats();
    local times = player:getModData().iTimesCannibal;
    if times <= 25 then
        stats:setStress(stats:getStress() + 0.2);
        result:setTooltip("Butchered human flesh.<br>You aren't seriously considering eating this, are you?");
    elseif times <= 50 then
        stats:setStress(stats:getStress() + 0.1);
        result:setUnhappyChange(10);
        result:setTooltip("Butchered human flesh.");
    else
        stats:setStress(stats:getStress() - 0.1);
        result:setTooltip("Butchered human flesh.<br>So scrumptious!");
        result:setUnhappyChange(-10);
        player:getInventory():AddItem("MoreTraits.BloodBox");
    end
    if ZombRand(0, 100) >= 90 then
        if times <= 25 then
            tbl = { "Oh god, how can I do this?", "*Sobs Uncontrollably*", "Am I really this desperate?", "Please, no. I can't do this.", "*Winces in Disgust*", "*Tries hard not to vomit*",
                    "I don't know if I can go through with this.", "*Trembles*", "*Stares in disbelief at what they've done*", "*Frowns*", "*Heaves*" };
            player:Say(tbl[ZombRand(0, tablelength(tbl))]);
        elseif times <= 50 then
            tbl = { "Well if I'm hungry enough to eat a horse...", "*Vaguely recalls playing Rimworld*", "If it's good enough for tribespeople, it's good enough for me.", "You've got to do what you need to survive.", "Well, it IS food...", "At least I waited for the Apocalypse to start practicing." };
            player:Say(tbl[ZombRand(0, tablelength(tbl))]);
        else
            tbl = { "*Cackles Madly*", "*Licks lips with delight*", "Oh...you look like a tasty one.", "Well slap my back and call me Hannibal.", "Mmm.", "*Laugh Meniacally*", "I think you'll make a nice Stew!", "And maybe some blood will spice it up..." };
            player:Say(tbl[ZombRand(0, tablelength(tbl))]);
        end
    end
    result:setRotten(false);
    result:setAge(0);
    result:updateAge();
    player:getModData().iTimesCannibal = times + 1;
end
local function addXPNoMultiplier(_player, _perk, _amount)
    local perk = _perk;
    local amount = _amount;
    local player = _player;
    skipxpadd = true;
    player:getXp():AddXPNoMultiplier(perk, amount);
end

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
    local martial = TraitFactory.addTrait("martial", getText("UI_trait_martial"), 4, getText("UI_trait_martialdesc"), false, false);
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
    local scrounger = TraitFactory.addTrait("scrounger", getText("UI_trait_scrounger"), 5, getText("UI_trait_scroungerdesc"), false, false);
    local antique = TraitFactory.addTrait("antique", getText("UI_trait_antique"), 4, getText("UI_trait_antiquedesc"), false, false);
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
    local gordanite = TraitFactory.addTrait("gordanite", getText("UI_trait_gordanite"), 5, getText("UI_trait_gordanitedesc"), false, false);
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
    local gymgoer = TraitFactory.addTrait("gymgoer", getText("UI_trait_gymgoer"), 5, getText("UI_trait_gymgoerdesc"), false, false);
    gymgoer:addXPBoost(Perks.Strength, 1);
    gymgoer:addXPBoost(Perks.Fitness, 1);
    --===========--
    --Bad Traits--
    --===========--
    local packmouse = TraitFactory.addTrait("packmouse", getText("UI_trait_packmouse"), -7, getText("UI_trait_packmousedesc"), false, false);
    local injured = TraitFactory.addTrait("injured", getText("UI_trait_injured"), -4, getText("UI_trait_injureddesc"), false, false);
    local drinker = TraitFactory.addTrait("drinker", getText("UI_trait_drinker"), -12, getText("UI_trait_drinkerdesc"), false, false);
    local broke = TraitFactory.addTrait("broke", getText("UI_trait_broke"), -8, getText("UI_trait_brokedesc"), false, false);
    local butterfingers = TraitFactory.addTrait("butterfingers", getText("UI_trait_butterfingers"), -10, getText("UI_trait_butterfingersdesc"), false, false);
    local incomprehensive = TraitFactory.addTrait("incomprehensive", getText("UI_trait_incomprehensive"), -10, getText("UI_trait_incomprehensivedesc"), false, false);
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
    --  TraitFactory.setMutualExclusive("gimp", "fast");
    --TraitFactory.setMutualExclusive("blissful", "Brooding");
end

local function initToadTraitsItems(_player)
    local player = _player;
    local inv = player:getInventory();
    local traits = player:getTraits();
    if player:HasTrait("preparedfood") then
        inv:AddItem("Base.TinnedBeans");
        inv:AddItem("Base.CannedMushroomSoup");
        inv:AddItem("Base.TinnedSoup");
        inv:AddItem("Base.TunaTin");
        inv:AddItems("Base.PopBottle", 3);
        inv:AddItem("Base.TinOpener");
        inv:AddItems("Base.CannedTomato", 1);
        inv:AddItems("Base.CannedPotato", 1);
        inv:AddItems("Base.CannedCarrots", 1);
        inv:AddItems("Base.CannedBroccoli", 1);
        inv:AddItems("Base.CannedCabbage", 1);
        inv:AddItems("Base.CannedEggplant", 1);
        inv:AddItem("Base.Plasticbag");
    end
    if player:HasTrait("preparedammo") then
        inv:AddItems("Base.BulletsBox", 3);
        inv:AddItems("Base.ShotgunShellsBox", 2);
    end
    if player:HasTrait("preparedweapon") then
        inv:AddItem("Base.BaseballBatNails");
        inv:AddItem("farming.Shovel");
        inv:AddItem("Base.HuntingKnife");
        inv:AddItem("Base.Screwdriver");
    end
    if player:HasTrait("preparedmedical") then
        inv:AddItem("Base.Bandaid");
        inv:AddItem("Base.PillsAntiDep");
        inv:AddItem("Base.Disinfectant");
        inv:AddItem("Base.AlcoholWipes");
        inv:AddItem("Base.PillsBeta");
        inv:AddItem("Base.Pills");
        inv:AddItems("Base.Bandage", 4);
        inv:AddItem("Base.SutureNeedle");
        inv:AddItem("Base.Tissue");
        inv:AddItem("Base.Tweezers");
        inv:AddItem("Base.FirstAidKit");
    end
    if player:HasTrait("preparedrepair") then
        inv:AddItem("Base.Hammer");
        inv:AddItem("Base.Screwdriver");
        inv:AddItem("Base.Crowbar");
        inv:AddItem("Base.Saw");
        inv:AddItem("Base.NailsBox");
        inv:AddItems("Base.Garbagebag", 8);
    end
    if player:HasTrait("preparedcamp") then
        inv:AddItems("Base.Matches", 2);
        inv:AddItem("camping.CampfireKit");
        inv:AddItem("camping.CampingTentKit");
        inv:AddItem("Base.BucketEmpty");
        inv:AddItems("Base.BeefJerky", 2);
        inv:AddItems("Base.Pop", 1);
        inv:AddItem("Base.FishingRod");
        inv:AddItem("Base.FishingLine");
        inv:AddItem("Base.FishingTackle");
        inv:AddItems("Base.Battery", 4);
        inv:AddItem("Base.Torch");
        inv:AddItem("Base.Bag_NormalHikingBag");
        inv:AddItem("Base.WaterBottleFull");
    end
    if player:HasTrait("preparedpack") then
        inv:AddItem("Base.Bag_BigHikingBag");
    end
    if player:HasTrait("preparedcar") then
        inv:AddItem("Base.PetrolCan");
        inv:AddItem("Base.CarBatteryCharger");
        inv:AddItem("Base.Screwdriver");
        inv:AddItem("Base.Wrench");
        inv:AddItem("Base.LugWrench");
        inv:AddItem("Base.TirePump");
        inv:AddItem("Base.Jack");
    end
    if player:HasTrait("drinker") then
        inv:AddItem("Base.WhiskeyFull");
    end
end

local function initToadTraitsPerks(_player)
    local player = _player;
    local damage = 20;
    local bandagestrength = 5;
    local splintstrength = 0.9;
    local fracturetime = 20;
    local scratchtimemod = 15;
    local bleedtimemod = 5;
    player:getModData().bToadTraitDepressed = false;
    player:getModData().indefatigablecooldown = 0;
    player:getModData().bindefatigable = false;
    player:getModData().bSatedDrink = true;
    player:getModData().iHoursSinceDrink = 0;
    player:getModData().iTimesCannibal = 0;

    if player:HasTrait("Lucky") then
        damage = damage - 10;
        bandagestrength = bandagestrength + 3;
        fracturetime = fracturetime - 10;
        splintstrength = splintstrength + 0.1;
        scratchtimemod = scratchtimemod - 5;
        bleedtimemod = bleedtimemod - 2;
    end
    if player:HasTrait("Unlucky") then
        damage = damage + 10;
        bandagestrength = bandagestrength - 2;
        fracturetime = fracturetime + 5;
        splintstrength = splintstrength - 0.1;
        scratchtimemod = scratchtimemod + 5;
        bleedtimemod = bleedtimemod + 2;
    end

    if player:HasTrait("injured") then
        suspendevasive = true;
        --print("Beginning Injury.");
        local bodydamage = player:getBodyDamage();
        local itterations = ZombRand(1, 4) + 1;
        for i = 0, itterations do
            local randompart = ZombRand(0, 16);
            local b = bodydamage:getBodyPart(BodyPartType.FromIndex(randompart));
            local injury = ZombRand(0, 5);
            local skip = false;
            if b:HasInjury() then
                itterations = itterations + 1;
                skip = true;
            end
            if skip == false then
                if injury <= 1 then
                    b:AddDamage(damage);
                    b:setScratched(true, true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                end
                if injury == 2 then
                    b:AddDamage(damage);
                    b:setBurned();
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                end
                if injury == 3 then
                    b:AddDamage(damage);
                    b:setCut(true, true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                end
                if injury >= 4 then
                    b:AddDamage(damage);
                    b:setDeepWounded(true);
                    b:setStitched(true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                end
            end
        end
        bodydamage:setInfected(false);
    end
    if player:HasTrait("broke") then
        --print("Broke Leg.");
        suspendevasive = true;
        local bodydamage = player:getBodyDamage();
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):AddDamage(damage);
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setFractureTime(fracturetime);
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setSplint(true, splintstrength);
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setSplintItem("Base.Splint");
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
        bodydamage:setInfected(false);
    end
    player:getModData().ToadTraitBodyDamage = nil;
    suspendevasive = false;
    if player:HasTrait("packmule") then
        player:setMaxWeight(30);
        player:setMaxWeightBase(12);

    end
    if player:HasTrait("packmouse") then
        player:setMaxWeight(25);
        player:setMaxWeightBase(8);
    end
end

local function ToadTraitEvasive(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("evasive") then
        local basechance = 33;
        local bMarkForUpdate = false;
        local bodydamage = player:getBodyDamage();
        local modbodydamage = playerdata.ToadTraitBodyDamage;
        if bodydamage:getNumPartsScratched() == nil then
            return
        end ;
        if player:HasTrait("Lucky") then
            basechance = basechance + 5;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 3;
        end
        if modbodydamage == nil then
            modbodydamage = {};
            --Initialize the Body Part Reference Table
            print("Initializing Body Damage");
            for i = 0, bodydamage:getBodyParts():size() - 1 do
                local b = bodydamage:getBodyParts():get(i);
                local temptable = { b:getType(), b:scratched(), b:bitten() };
                table.insert(modbodydamage, temptable);
            end
            playerdata.ToadTraitBodyDamage = modbodydamage;
            print("Body Damage Initialized");
        else
            for n = 0, bodydamage:getBodyParts():size() - 1 do
                local i = bodydamage:getBodyParts():get(n);
                for _, b in pairs(modbodydamage) do
                    if i:getType() == b[1] then
                        if i:scratched() == false and b[2] == true or i:bitten() == false and b[3] == true then
                            bMarkForUpdate = true;
                        end
                        if i:scratched() == true and b[2] == false then
                            print("Scratch Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance then
                                print("Attack Dodged!");
                                i:RestoreToFullHealth();
                                i:setScratched(false);
                                i:SetInfected(false);
                                player:Say("*Dodged*");
                            else
                                bMarkForUpdate = true;
                            end

                        elseif i:bitten() == true and b[3] == false then
                            print("Bite Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance then
                                print("Attack Dodged!");
                                i:RestoreToFullHealth();
                                i:SetBitten(false, false);
                                i:SetInfected(false);
                                player:Say("*Dodged*");
                            else
                                bMarkForUpdate = true;
                            end
                        end
                    end
                end
            end
        end
        if bMarkForUpdate == true then
            modbodydamage = {};
            --Initialize the Body Part Reference Table
            for i = 0, bodydamage:getBodyParts():size() - 1 do
                local b = bodydamage:getBodyParts():get(i);
                local temptable = { b:getType(), b:scratched(), b:bitten() };
                table.insert(modbodydamage, temptable);
            end
            playerdata.ToadTraitBodyDamage = modbodydamage;
        end
    end
end

local function ToadTraitButter()
    local player = getPlayer();
    if player:HasTrait("butterfingers") and player:isPlayerMoving() then
        local basechance = 5;
        if player:HasTrait("AllThumbs") then
            basechance = basechance + 5;
        end
        if player:HasTrait("Dextrous") then
            basechance = basechance - 5;
        end
        if player:HasTrait("Lucky") then
            basechance = basechance - 5;
        end
        if player:HasTrait("packmule") then
            basechance = basechance - 5;
        end
        if player:HasTrait("packmouse") then
            basechance = basechance + 5;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 5;
        end
        local weight = player:getInventoryWeight();
        local chancemod = 0;
        if weight > 0 then
            chancemod = math.floor(weight / 5);
        end
        local chance = (basechance + chancemod);
        if chance >= ZombRand(1000) then
            player:dropHandItems();
        end
    end
end

local function ToadTraitScrounger(_target, _name, _container)
    local player = getPlayer();
    if player:HasTrait("scrounger") then
        local basechance = 30;
        local modifier = 1.2;
        if player:HasTrait("Lucky") then
            basechance = basechance + 10;
            modifier = modifier + 0.1;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 5;
            modifier = modifier - 0.1;
        end
        if ZombRand(100) <= basechance then
            local tempcontainer = {};
            for i = 0, _container:getItems():size() - 1 do
                local item = _container:getItems():get(i);
                if item ~= nil then
                    if tableContains(tempcontainer, item:getFullType()) == false then
                        table.insert(tempcontainer, item:getFullType());
                        local count = _container:getNumberOfItem(item:getFullType());
                        if count == 1 then
                            local bchance = 5;
                            if player:HasTrait("Lucky") then
                                bchance = bchance + 2;
                            end
                            if player:HasTrait("Unlucky") then
                                bchance = bchance - 2;
                            end
                            if item:getCategory() == "Food" then
                                bchance = bchance + 20;
                            end
                            if item:IsDrainable() then
                                bchance = bchance + 10;
                            end
                            if item:IsWeapon() then
                                bchance = bchance + 5;
                            end
                            if ZombRand(100) <= bchance then
                                _container:AddItems(item, 1);
                            end
                        elseif count > 1 and count < 5 then
                            _container:AddItems(item, math.floor(count * modifier));
                        elseif count >= 5 then
                            _container:AddItems(item, math.floor((count * modifier) * 2));
                        end
                    end
                end
            end
        end
    end
end

local function ToadTraitIncomprehensive(_target, _name, _container)
    local player = getPlayer();
    local tempcontainer = {};
    if player:HasTrait("incomprehensive") then
        local basechance = 30;
        if player:HasTrait("Lucky") then
            basechance = basechance - 10;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 5;
        end
        if ZombRand(100) <= basechance then
            for i = 0, _container:getItems():size() - 1 do
                local item = _container:getItems():get(i);
                if item ~= nil then
                    if tableContains(tempcontainer, item) == false then
                        local count = _container:getNumberOfItem(item:getFullType());
                        if count == 1 then
                            local bchance = 5;
                            if player:HasTrait("Lucky") then
                                bchance = bchance - 2;
                            end
                            if player:HasTrait("Unlucky") then
                                bchance = bchance + 2;
                            end
                            if item:IsFood() then
                                bchance = bchance + 20;
                            end
                            if item:IsDrainable() then
                                bchance = bchance + 10;
                            end
                            if item:IsWeapon() then
                                bchance = bchance + 5;
                            end
                            if ZombRand(100) <= bchance then
                                table.insert(tempcontainer, item);
                            end
                        elseif count > 1 and count < 5 then
                            table.insert(tempcontainer, item);
                        elseif count >= 5 then
                            table.insert(tempcontainer, item);
                            table.insert(tempcontainer, item);
                        end
                    end
                end
            end
            if tempcontainer ~= nil then
                for _, i in pairs(tempcontainer) do
                    _container:Remove(i);
                end
            end
        end
    end
end

local function ToadTraitAntique(_target, _name, _container)
    local items = {};
    table.insert(items, "MoreTraits.AntiqueAxe");
    table.insert(items, "MoreTraits.Thumper");
    table.insert(items, "MoreTraits.ObsidianBlade");
    table.insert(items, "MoreTraits.PackerBag");
    table.insert(items, "MoreTraits.BloodyCrowbar");
    table.insert(items, "MoreTraits.AntiqueMag1");
    table.insert(items, "MoreTraits.AntiqueMag2");
    table.insert(items, "MoreTraits.AntiqueMag3");
    table.insert(items, "MoreTraits.Slugger");

    local length = 0
    for k, v in pairs(items) do
        length = length + 1;
    end
    local player = getPlayer();
    if player:HasTrait("antique") then
        local basechance = 5;
        if player:HasTrait("Lucky") then
            basechance = basechance + 2;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 1;
        end
        if player:HasTrait("AllThumbs") then
            basechance = basechance - 1;
        end
        if player:HasTrait("Dextrous") then
            basechance = basechance + 1;
        end
        if player:HasTrait("scrounger") then
            basechance = basechance + 1;
        end
        if player:HasTrait("incomprehensive") then
            basechance = basechance - 1;
        end
        if basechance < 1 then
            basechance = 1;
        end
        if ZombRand(1000) <= basechance then
            local i = ZombRand(length);
            if i == 0 then
                i = 1;
            end
            _container:AddItem(items[i]);
        end
    end
end

local function ToadTraitDepressive()
    local player = getPlayer();
    if player:HasTrait("depressive") then
        local basechance = 5;
        if player:HasTrait("Lucky") then
            basechance = basechance - 2;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 2;
        end
        if player:HasTrait("Brooding") then
            basechance = basechance + 2;
        end
        if ZombRand(100) <= basechance then
            if player:getModData().bToadTraitDepressed == false then
                print("Player is experiencing depression.");
                player:getBodyDamage():setUnhappynessLevel((player:getBodyDamage():getUnhappynessLevel() + 25));
                player:getModData().bToadTraitDepressed = true;
            end
        end
    end
end

local function CheckDepress(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local depressed = playerdata.bToadTraitDepressed;
    if depressed == nil then
        playerdata.bToadTraitDepressed = false;
    else
        if depressed == true then
            if player:getBodyDamage():getUnhappynessLevel() < 25 then
                playerdata.bToadTraitDepressed = false;
            else
                player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + 0.0005);
            end
        end
    end
end

local function CheckSelfHarm(_player)
    local player = _player;
    local modifier = 3;
    if player:HasTrait("depressive") then
        modifier = modifier - 1;
    end
    if player:HasTrait("selfdestructive") then
        if player:getBodyDamage():getUnhappynessLevel() >= 25 then
            if player:getBodyDamage():getOverallBodyHealth() >= (100 - player:getBodyDamage():getUnhappynessLevel() / modifier) then
                for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                    local b = player:getBodyDamage():getBodyParts():get(i);
                    b:AddDamage(0.0005);
                end
            end
        end
    end
end

local function Blissful(_player)
    local player = _player;
    if player:HasTrait("blissful") then
        if player:getBodyDamage():getUnhappynessLevel() >= 10 then
            player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() - 0.01);
        end
        if player:getBodyDamage():getBoredomLevel() >= 10 then
            player:getBodyDamage():setBoredomLevel(player:getBodyDamage():getBoredomLevel() - 0.005);
        end
    end
end

local function Specialization(_player, _perk, _amount)
    local player = _player;
    local perk = _perk;
    local amount = _amount;
    local newamount = 0;
    local skip = false;
    if perk == Perks.Fitness or perk == Perks.Strength then
        skipxpadd = true;
    end
    if skipxpadd == false then
        if player:HasTrait("specweapons") or player:HasTrait("specfood") or player:HasTrait("specguns") or player:HasTrait("specmove") or player:HasTrait("speccrafting") or player:HasTrait("specaid") then
            if player:HasTrait("specweapons") then
                if perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Maintenance or perk == Perks.SmallBlunt then
                    skip = true;
                end
            end
            if player:HasTrait("specfood") then
                if perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.PlantScavenging or perk == Perks.Trapping or perk == Perks.Fishing then
                    skip = true;
                end
            end
            if player:HasTrait("specguns") then
                if perk == Perks.Aiming or perk == Perks.Reloading then
                    skip = true;
                end
            end
            if player:HasTrait("specmove") then
                if perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sprinting or perk == Perks.Sneak then
                    skip = true;
                end
            end
            if player:HasTrait("speccrafting") then
                if perk == Perks.Woodwork or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring then
                    skip = true;
                end
            end
            if player:HasTrait("specaid") then
                if perk == Perks.Doctor then
                    skip = true;
                end
            end
            if skip == false then
                newamount = amount * 0.25;
                local currentxp = player:getXp():getXP(perk);
                local correctamount = currentxp - newamount
                -- print("Current " .. tostring(perk) .. " XP: " .. currentxp);
                --  print("XP Amount (Unmodified): " .. amount);
                -- print("Subtracted Amount: " .. newamount .. " XP");
                player:getXp():AddXP(perk, -1 * amount, false, false);
                --  print("New XP Is: " .. player:getXp():getXP(perk));
                --  print("The player's XP should be: " .. currentxp - newamount);
                while player:getXp():getXP(perk) < correctamount do
                    player:getXp():AddXP(perk, 0.01, false, false);
                    --this is a very terrible way of doing this. But for some reason, some unknown variable within the AddXp function
                    --is fucking up the multiplication.
                    --print("Adjusting XP...");
                    -- print("New XP Is: " .. player:getXp():getXP(perk));
                    --print("The player's XP should be: " .. correctamount);
                end
            end
        end
    else
        skipxpadd = false;
    end
end

local function Gordanite(_player)
    local player = _player;
    if player:HasTrait("gordanite") then
        if player:getPrimaryHandItem() ~= nil then
            if player:getPrimaryHandItem():getDisplayName() == "Crowbar" then
                local crowbar = player:getPrimaryHandItem();
                crowbar:setMinDamage(1.2);
                crowbar:setMaxDamage(1.8);
                crowbar:setPushBackMod(0.8);
                crowbar:setDoorDamage(35);
                crowbar:setTreeDamage(20);
                crowbar:setCriticalChance(50);
                crowbar:setSwingTime(2);
                crowbar:setBaseSpeed(1.5);
                crowbar:setWeaponLength(0.6);
                crowbar:setMinimumSwingTime(1);
                crowbar:setName("Crowbar+");
                crowbar:setTooltip("This item's stats are being boosted by one of your traits.");
            end
        end
    end
    if player:HasItem("Crowbar") == true then
        local skip = false;
        if player:getPrimaryHandItem() ~= null then
            if player:getPrimaryHandItem():getName() == "Crowbar+" or player:getPrimaryHandItem():getDisplayName() == "Crowbar" then
                skip = true;
            end
        end
        if skip == false then
            local inv = player:getInventory();
            for i = 0, inv:getItems():size() - 1 do
                local item = player:getInventory():getItems():get(i);
                if item:getName() == "Crowbar+" then
                    local crowbar = item;
                    crowbar:setMinDamage(0.6);
                    crowbar:setMaxDamage(1.15);
                    crowbar:setPushBackMod(0.5);
                    crowbar:setDoorDamage(8);
                    crowbar:setCriticalChance(35);
                    crowbar:setSwingTime(3);
                    crowbar:setName("Crowbar");
                    crowbar:setWeaponLength(0.4);
                    crowbar:setMinimumSwingTime(3);
                    crowbar:setTreeDamage(0);
                    crowbar:setBaseSpeed(1);
                    crowbar:setTooltip(null);
                    break ;
                end
            end
        end
    end
end

local function indefatigable(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local enemies = player:getSpottedList();
    if player:HasTrait("indefatigable") then
        if player:getBodyDamage():getHealth() < 15 then
            print("Health less than 15.");
            if playerdata.bindefatigable == false then
                print("Healed to full.");
                for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                    local b = player:getBodyDamage():getBodyParts():get(i);
                    b:RestoreToFullHealth();
                end
                playerdata.bindefatigable = true;
                playerdata.indefatigablecooldown = 0;
                if enemies:size() > 2 then
                    for i = 0, enemies:size() - 1 do
                        if enemies:get(i):isZombie() then
                            if enemies:get(i):DistTo(player) <= 1.5 then
                                enemies:get(i):Hit(player:getUseHandWeapon(), player, ZombRand(1, 12), false, 1);
                            end
                        end
                    end
                end
                player:Say("*Indefatigable*");
            end
        end
    end
end

local function indefatigablecounter()
    local player = getPlayer();
    local playerdata = player:getModData();
    if player:HasTrait("indefatigable") then
        if playerdata.bindefatigable == true then
            if playerdata.indefatigablecooldown >= 7 then
                playerdata.indefatigablecooldown = 0;
                playerdata.bindefatigable = false;
                player:Say("*Indefatigable Is No Longer In Cooldown*");
            else
                playerdata.indefatigablecooldown = playerdata.indefatigablecooldown + 1;
            end
        end
    end
end

local function badteethtrait(_player)
    local player = _player;
    if player:HasTrait("badteeth") then
        if player:getBodyDamage():getHealthFromFoodTimer() > 1000 then
            player:getStats():setPain(player:getBodyDamage():getHealthFromFoodTimer() / 90);
        end
    end
end

local function hardytrait(_player)
    local player = _player;
    local stats = player:getStats();
    if player:HasTrait("hardy") then
        local endurance = stats:getEndurance();
        if endurance < 1 and player:IsRunning() == false and player:isForceRun() == false then
            stats:setEndurance(endurance + 0.0001);
        end
    end
end

local function drinkerupdate(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("drinker") then
        local stats = player:getStats();
        local drunkness = stats:getDrunkenness();
        local anger = stats:getAnger();
        local stress = stats:getStress();
        if drunkness >= 10 then
            playerdata.bSatedDrink = true;
            playerdata.iHoursSinceDrink = 0;
            stats:setAnger(anger - 0.01);
            stats:setStress(stress - 0.01);
        end
        if playerdata.bSatedDrink == false then
            if playerdata.iHoursSinceDrink > 48 then
                stats:setPain(playerdata.iHoursSinceDrink / 5);
            end
            stats:setAnger(anger + 0.001);
            stats:setStress(stress + 0.001);
        end
    end
end

local function drinkertick()
    local player = getPlayer();
    local playerdata = player:getModData();
    if player:HasTrait("drinker") then
        local hoursthreshold = 24;
        if player:HasTrait("Lucky") then
            hoursthreshold = hoursthreshold + 4;
        end
        if player:HasTrait("Unlucky") then
            hoursthreshold = hoursthreshold - 2;
        end
        if player:HasTrait("Lightdrinker") then
            hoursthreshold = hoursthreshold - 2;
        end
        playerdata.iHoursSinceDrink = playerdata.iHoursSinceDrink + 1;
        if playerdata.bSatedDrink == true then
            if playerdata.iHoursSinceDrink >= hoursthreshold then
                if ZombRand(100) <= hoursthreshold / 4 then
                    playerdata.bSatedDrink = false;
                    print("Player needs alcohol.");
                    player:Say("I need alcohol.");
                end
            end
        end
    end
end

local function drinkerpoison()
    local player = getPlayer();
    local playerdata = player:getModData();
    if playerdata.iHoursSinceDrink > 72 and playerdata.bSatedDrink == false then
        print("Player is suffering from alcohol withdrawal.");
        player:Say("*Alcohol Withdrawal*");
        player:getBodyDamage():setPoisonLevel((playerdata.iHoursSinceDrink / 5));
    end
end

local function bouncerupdate(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local chance = 5;
    local enemies = player:getSpottedList();
    local enemy = nil;
    local closeenemies = {};
    if player:HasTrait("bouncer") then
        if player:HasTrait("Lucky") then
            chance = chance + 1;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 1;
        end
        if playerdata.iBouncercooldown == nil then
            playerdata.iBouncercooldown = 0;
        end
        if playerdata.iBouncercooldown > 0 then
            playerdata.iBouncercooldown = playerdata.iBouncercooldown - 1;
        end
        if playerdata.iBouncercooldown <= 0 then
            if enemies:size() >= 3 then
                for i = 0, enemies:size() - 1 do
                    enemy = enemies:get(i);
                    if enemy:DistTo(player) <= 2.0 then
                        if enemy:isZombie() then
                            table.insert(closeenemies, i);
                        end
                    end
                end
            end
            if closeenemies ~= nil then
                if tablelength(closeenemies) >= 3 then
                    for i = 1, tablelength(closeenemies) - 1 do
                        enemy = enemies:get(tonumber(closeenemies[i]));
                        if enemy ~= nil then
                            if enemy:isZombie() == true then
                                if ZombRand(0, 101) <= chance and enemy:isProne() == false then
                                    enemy:setStaggerBack(true);
                                    playerdata.iBouncercooldown = 60;
                                    break ;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function martial(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local damage = _damage;
    local critchance = 5;
    if _actor == player and player:HasTrait("martial") then
        if player:HasTrait("Lucky") then
            critchance = critchance + 1;
        end
        if player:HasTrait("Unlucky") then
            critchance = critchance - 1;
        end
        local SmallBluntLvl = player:getPerkLevel(Perks.SmallBlunt);
        local StrengthLvl = player:getPerkLevel(Perks.Strength);
        local Fitnesslvl = player:getPerkLevel(Perks.Fitness);
        local average = (StrengthLvl + Fitnesslvl) / 2;
        local minimumdmg = 0.1 * average + SmallBluntLvl * 0.1;
        local maximumdmg = 0.5 * average + SmallBluntLvl * 0.1;
        critchance = critchance + SmallBluntLvl;

        if _weapon:getName() == "Bare Hands" then
            weapon:setDoorDamage(9 + maximumdmg);
            weapon:setTreeDamage(1 + maximumdmg);
            weapon:getCategories():set(0, "SmallBlunt");
            weapon:setMinDamage(minimumdmg);
            weapon:setMaxDamage(maximumdmg);
            weapon:setCriticalChance(critchance);
            if _target:isZombie() and ZombRand(0, 101) <= critchance then
                damage = damage * 4;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 then
                _target:update();
            end
        end
    end
end

local function problunt(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local playerdata = player:getModData();
    local weapon = _weapon;
    local critchance = player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt) + 5;
    local damage = _damage;
    if _actor == player and player:HasTrait("problunt") then
        if weapon:getCategories():contains("Blunt") or weapon:getCategories():contains("SmallBlunt") then
            if player:HasTrait("Lucky") then
                critchance = critchance + 1;
            end
            if player:HasTrait("Unlucky") then
                critchance = critchance - 1;
            end
            if _target:isZombie() and ZombRand(0, 101) <= critchance then
                damage = damage * 2;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if playerdata.iLastWeaponCond == nil then
                playerdata.iLastWeaponCond = weapon:getCondition();
            end
            if playerdata.iLastWeaponCond > weapon:getCondition() then
                playerdata.iLastWeaponCond = weapon:getCondition();
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1);
                end
            end
        end
    end
end

local function problade(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local playerdata = player:getModData();
    local weapon = _weapon;
    local critchance = player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.SmallBlade) + player:getPerkLevel(Perks.LongBlade);
    local damage = _damage;
    if _actor == player and player:HasTrait("problade") then
        if weapon:getCategories():contains("SmallBlade") or weapon:getCategories():contains("Axe") or weapon:getCategories():contains("LongBlade") then
            if player:HasTrait("Lucky") then
                critchance = critchance + 1;
            end
            if player:HasTrait("Unlucky") then
                critchance = critchance - 1;
            end
            if _target:isZombie() and ZombRand(0, 101) <= critchance then
                damage = damage * 2;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if ZombRand(0, 101) <= 10 then
                if playerdata.iLastWeaponCond == nil then
                    playerdata.iLastWeaponCond = weapon:getCondition();
                end
                if playerdata.iLastWeaponCond > weapon:getCondition() then
                    playerdata.iLastWeaponCond = weapon:getCondition();
                    if weapon:getCondition() < weapon:getConditionMax() then
                        weapon:setCondition(weapon:getCondition() + 1);
                    end
                end
            end
        end
    end
end

local function progun(_actor, _weapon)
    local player = getPlayer();
    local weapon = _weapon;
    local maxCapacity = weapon:getMaxAmmo();
    local currentCapacity = weapon:getCurrentAmmoCount();
    local chance = 10 + player:getPerkLevel(Perks.Firearm) * 5;
    if _actor == player and player:HasTrait("progun") and weapon:getSubCategory() == "Firearm" then
        if player:HasTrait("Lucky") then
            chance = chance + 5;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 5;
        end
        if ZombRand(0, 101) <= 10 then
            if weapon:getCondition() < weapon:getConditionMax() then
                weapon:setCondition(weapon:getCondition() + 1);
            end
        end
        if ZombRand(0, 101) <= chance then
            if currentCapacity < maxCapacity and currentCapacity > 0 then
                weapon:setCurrentAmmoCount(currentCapacity + 1);
            end
        end
    end
end

local function prospear(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local playerdata = player:getModData();
    local weapon = _weapon;
    local critchance = player:getPerkLevel(Perks.Spear) + 5;
    local damage = _damage;
    if _actor == player and player:HasTrait("prospear") then
        if weapon:getCategories():contains("Spear") then
            if player:HasTrait("Lucky") then
                critchance = critchance + 1;
            end
            if player:HasTrait("Unlucky") then
                critchance = critchance - 1;
            end
            if _target:isZombie() and ZombRand(0, 101) <= critchance then
                damage = damage * 2;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if playerdata.iLastWeaponCond == nil then
                playerdata.iLastWeaponCond = weapon:getCondition();
            end
            if playerdata.iLastWeaponCond > weapon:getCondition() then
                playerdata.iLastWeaponCond = weapon:getCondition();
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1);
                end
            end
        end
    end
end
local function albino(_player)
    local player = _player;
    if player:HasTrait("albino") then
        local time = getGameTime();
        if player:isOutside() then
            local tod = time:getTimeOfDay();
            if tod > 10 and tod < 16 then
                local stats = player:getStats();
                local pain = stats:getPain();
                if pain < 25 then
                    stats:setPain(20);
                end
            end
        end
    end
end

local function amputee(_player)
    local player = _player;
    if player:HasTrait("amputee") then
        local handitem = player:getSecondaryHandItem();
        local bodydamage = player:getBodyDamage();
        if handitem ~= nil then
            if handitem:getName() ~= "Bare Hands" then
                player:dropHandItems();
            end
        end
        local UpperArm_L = bodydamage:getBodyPart(BodyPartType.FromString("UpperArm_L"));
        local ForeArm_L = bodydamage:getBodyPart(BodyPartType.FromString("ForeArm_L"));
        local Hand_L = bodydamage:getBodyPart(BodyPartType.FromString("Hand_L"));
        if UpperArm_L:HasInjury() then
            UpperArm_L:SetBitten(false);
            UpperArm_L:setScratched(false);
            UpperArm_L:setDeepWounded(false);
            UpperArm_L:setBleeding(false);
            UpperArm_L:setHaveGlass(false);
            UpperArm_L:SetInfected(false);
        end
        if ForeArm_L:HasInjury() then
            ForeArm_L:SetBitten(false);
            ForeArm_L:setScratched(false);
            ForeArm_L:setDeepWounded(false);
            ForeArm_L:setBleeding(false);
            ForeArm_L:setHaveGlass(false);
            ForeArm_L:SetInfected(false);
        end
        if Hand_L:HasInjury() then
            Hand_L:SetBitten(false);
            Hand_L:setScratched(false);
            Hand_L:setDeepWounded(false);
            Hand_L:setBleeding(false);
            Hand_L:setHaveGlass(false);
            Hand_L:SetInfected(false);
        end
    end
end

local function actionhero(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local critchance = 10;
    local damage = _damage * 0.5;
    local enemies = player:getSpottedList();
    local multiplier = 1;
    if _actor == player and player:HasTrait("actionhero") then
        if player:HasTrait("martial") == false and weapon:getName() == "Bare Hands" then
            return
        end ;

        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i);
            if enemy:isZombie() then
                local distance = enemy:DistTo(player)
                if distance < 10 and distance > 5 then
                    critchance = critchance + 2;
                    multiplier = multiplier + 0.2;
                elseif distance <= 5 and distance >= 2 then
                    critchance = critchance + 5;
                    multiplier = multiplier + 0.4;
                elseif distance < 2 then
                    critchance = critchance + 10;
                    multiplier = multiplier + 1.0;
                end
            end
        end

        if player:HasTrait("Lucky") then
            critchance = critchance + 5;
        end
        if player:HasTrait("Unlucky") then
            critchance = critchance - 5;
        end
        if _target:isZombie() and ZombRand(0, 101) <= critchance then
            damage = damage * 5;
        end
        _target:setHealth(_target:getHealth() - (damage * multiplier) * 0.1);
        if _target:getHealth() <= 0 then
            _target:update();
        end
    end
end

local function gimp()
    local player = getPlayer();
    local playerdata = player:getModData();
    local modifier = 0.85;
    if player:HasTrait("gimp") and player:isLocalPlayer() then
        if playerdata.fToadTraitsPlayerX ~= nil and playerdata.fToadTraitsPlayerY ~= nil then
            local oldx = playerdata.fToadTraitsPlayerX;
            local oldy = playerdata.fToadTraitsPlayerY;
            local newx = player:getX();
            local newy = player:getY();
            local xdif = (newx - oldx);
            local ydif = (newy - oldy);
            if xdif > 5 or xdif < -5 or ydif > 5 or ydif < -5 then
                playerdata.fToadTraitsPlayerX = player:getX();
                playerdata.fToadTraitsPlayerY = player:getY();

                return
            end
            player:setX((oldx + xdif * modifier));
            player:setY((oldy + ydif * modifier));
        end
        playerdata.fToadTraitsPlayerX = player:getX();
        playerdata.fToadTraitsPlayerY = player:getY();
    end
end

local function fast()
    local player = getPlayer();
    local playerdata = player:getModData();
    local vector = player:getPlayerMoveDir();
    local length = vector:getLength();
    local modifier = 2.15;
    if player:HasTrait("fast") and player:isLocalPlayer() then
        if playerdata.fToadTraitsPlayerX ~= nil and playerdata.fToadTraitsPlayerY ~= nil then
            local oldx = playerdata.fToadTraitsPlayerX;
            local oldy = playerdata.fToadTraitsPlayerY;
            local newx = player:getX();
            local newy = player:getY();
            local xdif = (newx - oldx);
            local ydif = (newy - oldy);
            if xdif > 5 or xdif < -5 or ydif > 5 or ydif < -5 then
                playerdata.fToadTraitsPlayerX = player:getX();
                playerdata.fToadTraitsPlayerY = player:getY();

                return
            end
            if xdif ~= 0 or xdif ~= 0 or ydif ~= 0 or ydif ~= 0 then
                player:setX((oldx + xdif * modifier));
                player:setY((oldy + ydif * modifier));
                playerdata.fToadTraitsPlayerX = player:getX();
                playerdata.fToadTraitsPlayerY = player:getY();
            end
        else
            playerdata.fToadTraitsPlayerX = player:getX();
            playerdata.fToadTraitsPlayerY = player:getY();
        end
    end

end
local function anemic(_player)
    local player = _player;
    if player:HasTrait("anemic") then
        local bodydamage = player:getBodyDamage();
        local bleeding = bodydamage:getNumPartsBleeding();
        if bleeding > 0 then
            for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                local b = player:getBodyDamage():getBodyParts():get(i);
                if b:bleeding() and b:IsBleedingStemmed() == false then
                    b:ReduceHealth(0.03);
                end
            end
        end

    end
end
local function thickblood(_player)
    local player = _player;
    if player:HasTrait("thickblood") then
        local bodydamage = player:getBodyDamage();
        local bleeding = bodydamage:getNumPartsBleeding();
        if bleeding > 0 then
            for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                local b = player:getBodyDamage():getBodyParts():get(i);
                if b:bleeding() and b:IsBleedingStemmed() == false then
                    b:AddHealth(0.03);
                end
            end
        end

    end
end

local function vehicleCheck(_player)
    local player = _player;
    if player:isDriving() == true then
        local vehicle = player:getVehicle();
        local vmd = vehicle:getModData();
        if vmd.bUpdated == nil then
            vmd.fBrakingForce = vehicle:getBrakingForce();
            vmd.fMaxSpeed = vehicle:getMaxSpeed();
            vmd.iEngineQuality = vehicle:getEngineQuality();
            vmd.iEngineLoudness = vehicle:getEngineLoudness()
            vmd.iEnginePower = vehicle:getEnginePower();
            vmd.sState = "Normal";
            vmd.bUpdated = true;
        else
            if player:HasTrait("expertdriver") and vmd.sState ~= "ExpertDriver" then
                vehicle:setBrakingForce(vmd.fBrakingForce * 2);
                vehicle:setEngineFeature(vmd.iEngineQuality * 1.5, vmd.iEngineLoudness * 0.25, vmd.iEnginePower * 1.5);
                vehicle:setMaxSpeed(vmd.fMaxSpeed * 1.25);
                vmd.sState = "ExpertDriver";
                print("Vehicle State: " .. vmd.sState);
                vehicle:update();
            end
            if player:HasTrait("poordriver") and vmd.sState ~= "PoorDriver" then
                vehicle:setBrakingForce(vmd.fBrakingForce * 0.5);
                vehicle:setEngineFeature(vmd.iEngineQuality * 0.75, vmd.iEngineLoudness * 1.5, vmd.iEnginePower * 0.75);
                vehicle:setMaxSpeed(vmd.fMaxSpeed * 0.75);
                vmd.sState = "PoorDriver";
                print("Vehicle State: " .. vmd.sState);
                vehicle:update();
            end
            if player:HasTrait("expertdriver") == false and player:HasTrait("poordriver") == false and vmd.sState ~= "Normal" then
                vehicle:setBrakingForce(vmd.fBrakingForce);
                vehicle:setEngineFeature(vmd.iEngineQuality, vmd.iEngineLoudness, vmd.iEnginePower);
                vehicle:setMaxSpeed(vmd.fMaxSpeed);
                vmd.sState = "Normal";
                print("Vehicle State: " .. vmd.sState);
                vehicle:update();
            end

        end

    end
end

local function SuperImmune(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local bodydamage = player:getBodyDamage();
    local chance = 15;
    if player:HasTrait("superimmune") then
        if playerdata.bSuperImmune ~= nil then
            if player:HasTrait("Lucky") then
                chance = chance + 1;
            end
            if player:HasTrait("Unlucky") then
                chance = chance - 1;
            end
            if playerdata.bSuperImmune == true then
                if bodydamage:isInfected() then
                    if ZombRand(0, 101) <= chance then
                        print("Player's Immune system fought-off zombification.");
                        bodydamage:setInfected(false);
                        if ZombRand(0, 101) > chance then
                            print("Do fake infection");
                            bodydamage:setIsFakeInfected(true);
                            bodydamage:setFakeInfectionLevel(0.1);
                        end
                    else
                        print("Immune system failed.");
                        playerdata.bSuperImmune = false;
                    end
                end

            end
        else
            playerdata.bSuperImmune = true;
        end
        if bodydamage:isInfected() == false and playerdata.bSuperImmune == false then
            playerdata.bSuperImmune = true;
        end

        for i = 0, bodydamage:getBodyParts():size() - 1 do
            local b = bodydamage:getBodyParts():get(i);
            if b:HasInjury() then
                if b:isInfectedWound() then
                    b:setInfectedWound(false);
                end
            end

        end

    end
end

local function Immunocompromised(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local bodydamage = player:getBodyDamage();
    local chance = 15;
    if player:HasTrait("immunocompromised") then
        for i = 0, bodydamage:getBodyParts():size() - 1 do
            local b = bodydamage:getBodyParts():get(i);
            if b:HasInjury() then
                if b:isInfectedWound() and b:getAlcoholLevel() <= 0 then
                    b:setWoundInfectionLevel(b:getWoundInfectionLevel() + 0.001);
                end
            end

        end

    end
end

local function checkWeight()
    local player = getPlayer();
    local strength = player:getPerkLevel(Perks.Strength);
    if player:HasTrait("packmule") then
        player:setMaxWeight(30);
        player:setMaxWeightBase(12 + strength / 5);
    elseif player:HasTrait("packmouse") then
        player:setMaxWeight(20);
        player:setMaxWeightBase(8);
    else
        player:setMaxWeight(25);
        player:setMaxWeightBase(10);
    end
end

local function graveRobber(_zombie)
    local player = getPlayer();
    local zombie = _zombie;
    local chance = 3;

    if player:HasTrait("graverobber") then
        if player:HasTrait("Lucky") then
            chance = chance + 1;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 1;
        end
        if player:HasTrait("scrounger") then
            chance = chance + 1;
        end
        if player:HasTrait("incomprehensive") then
            chance = chance - 1;
        end
        if chance <= 0 then
            chance = 1;
        end
        if ZombRand(0, 100) <= chance then
            local inv = zombie:getInventory();
            local itterations = ZombRand(1, chance + 1);
            for i = 0, itterations do
                i = i + 1;
                local roll = ZombRand(0, 100);
                if roll <= 10 then
                    local randomitem = { "Base.Apple", "Base.Avocado", "Base.Banana", "Base.BellPepper", "Base.BeerCan",
                                         "Base.BeefJerky", "Base.Bread", "Base.Broccoli", "Base.Butter", "Base.CandyPackage", "Base.TinnedBeans",
                                         "Base.CannedCarrots2", "Base.CannedChili", "Base.CannedCorn", "Base.CannedCornedBeef", "CannedMushroomSoup",
                                         "Base.CannedPeas", "Base.CannedPotato2", "Base.CannedSardines", "Base.CannedTomato2", "Base.TunaTin" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 20 then
                    local randomitem = { "Base.PillsAntiDep", "Base.AlcoholWipes", "Base.AlcoholedCottonBalls", "Base.Pills", "Base.PillsSleepingTablets",
                                         "Base.Tissue", "Base.ToiletPaper", "Base.PillsVitamins", "Base.Bandaid", "Base.Bandage", "Base.CottonBalls", "Base.Splint", "Base.AlcoholBandage",
                                         "Base.AlcoholRippedSheets", "Base.SutureNeedle", "Base.Tweezers", "Base.WildGarlicCataplasm", "Base.ComfreyCataplasm", "Base.PlantainCataplasm", "Base.Disinfectant" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 30 then
                    local randomitem = { "Base.223Box", "Base.308Box", "Base.Bullets38Box", "Base.Bullets44Box", "Base.Bullets45Box", "Base.556Box", "Base.Bullets9mmBox",
                                         "Base.ShotgunShellsBox", "Base.DoubleBarrelShotgun", "Base.Shotgun", "Base.ShotgunSawnoff", "Base.Pistol", "Base.Pistol2", "Base.Pistol3", "Base.AssaultRifle", "Base.AssaultRifle2",
                                         "Base.VarmintRifle", "Base.HuntingRifle", "Base.556Clip", "Base.M14Clip", "Base.308Clip", "Base.223Clip", "Base.44Clip", "Base.45Clip", "Base.9mmClip", "Base.Revolver_Short", "Base.Revolver_Long",
                                         "Base.Revolver" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 40 then
                    local randomitem = { "Base.Aerosolbomb", "Base.Axe", "Base.BaseballBat", "Base.SpearCrafted", "Base.Crowbar", "Base.FlameTrap", "Base.HandAxe", "Base.HuntingKnife", "Base.Katana",
                                         "Base.PipeBomb", "Base.Sledgehammer", "Base.Shovel", "Base.SmokeBomb", "Base.WoodAxe", "Base.GardenFork", "Base.WoodenLance", "Base.SpearBreadKnife",
                                         "Base.SpearButterKnife", "Base.SpearFork", "Base.SpearLetterOpener", "Base.SpearScalpel", "Base.SpearSpoon", "Base.SpearScissors", "Base.SpearHandFork",
                                         "Base.SpearScrewdriver", "Base.SpearHuntingKnife", "Base.SpearMachete", "Base.SpearIcePick", "Base.SpearKnife", "Base.Machete", "Base.GardenHoe" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 50 then
                    local randomitem = { "Base.Bag_SurvivorBag", "Base.Bag_BigHikingBag", "Base.Bag_DuffelBag", "Base.Bag_FannyPackFront", "Base.Bag_NormalHikingBag", "Base.Bag_ALICEpack", "Base.Bag_ALICEpack_Army",
                                         "Base.Bag_Schoolbag", "Base.SackOnions", "Base.SackPotatoes", "Base.SackCarrots", "Base.SackCabbages" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 60 then
                    local randomitem = { "Base.Hat_SPHhelmet", "Base.Jacket_CoatArmy", "Base.Hat_BalaclavaFull", "Base.Hat_BicycleHelmet", "Base.Shoes_BlackBoots", "Base.Hat_CrashHelmet",
                                         "Base.HolsterDouble", "Base.Hat_Fireman", "Base.Jacket_Fireman", "Base.Trousers_Fireman", "Base.Hat_FootballHelmet", "Base.Hat_GasMask", "Base.Ghillie_Trousers", "Base.Ghillie_Top",
                                         "Base.Gloves_LeatherGloves", "Base.JacketLong_Random", "Base.Shoes_ArmyBoots", "Base.Vest_BulletArmy", "Base.Hat_Army", "Base.Hat_HardHat_Miner", "Base.Hat_NBCmask",
                                         "Base.Vest_BulletPolice", "Base.Hat_RiotHelmet", "Base.AmmoStrap_Shells" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 70 then
                    local randomitem = { "Base.CarBattery1", "Base.CarBattery2", "Base.CarBattery3", "Base.Extinguisher", "Base.PetrolCan", "Base.ConcretePowder", "Base.PlasterPowder", "Base.BarbedWire", "Base.Log",
                                         "Base.SheetMetal", "Base.MotionSensor", "Base.ModernTire1", "Base.ModernTire2", "Base.ModernTire3", "Base.ModernSuspension1", "Base.ModernSuspension2", "Base.ModernSuspension3",
                                         "Base.ModernCarMuffler1", "Base.ModernCarMuffler2", "Base.ModernCarMuffler3", "Base.ModernBrake1", "Base.ModernBrake2", "Base.ModernBrake3", "Base.smallSheetMetal",
                                         "Base.Speaker", "Base.EngineParts", "Base.LogStacks2", "Base.LogStacks3", "Base.LogStacks4", "Base.NailsBox" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 80 then
                    local randomitem = { "Base.ComicBook", "Base.ElectronicsMag4", "Base.HerbalistMag", "Base.MetalworkMag1", "Base.MetalworkMag2", "Base.MetalworkMag3", "Base.MetalworkMag4",
                                         "Base.HuntingMag1", "Base.HuntingMag2", "Base.HuntingMag3", "Base.FarmingMag1", "Base.MechanicMag1", "Base.MechanicMag2", "Base.MechanicMag3",
                                         "Base.CookingMag1", "Base.CookingMag2", "Base.EngineerMagazine1", "Base.EngineerMagazine2", "Base.ElectronicsMag1", "Base.ElectronicsMag2", "Base.ElectronicsMag3", "Base.ElectronicsMag5",
                                         "Base.FishingMag1", "Base.FishingMag2", "Base.Book", "MoreTraits.MedicalMag1", "MoreTraits.MedicalMag2", "MoreTraits.MedicalMag3", "MoreTraits.MedicalMag4", "MoreTraits.AntiqueMag1",
                                         "MoreTraits.AntiqueMag2", "MoreTraits.AntiqueMag3" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 90 then
                    local randomitem = { "Base.DumbBell", "Base.EggCarton", "Base.HomeAlarm", "Base.HotDog", "Base.HottieZ", "Base.Icecream", "Base.Machete", "Base.Revolver_Long",
                                         "Base.MeatPatty", "Base.Milk", "Base.MuttonChop", "Base.Padlock", "Base.PorkChop", "Base.Wine", "Base.Wine2", "Base.WhiskeyFull", "Base.Ham" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 95 then
                    local randomitem = { "Base.PropaneTank", "Base.BlowTorch", "Base.Woodglue", "Base.DuctTape", "Base.Rope", "Base.Extinguisher" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                elseif roll <= 100 then
                    local randomitem = { "Base.Spiffo", "Base.SpiffoSuit", "Base.Hat_Spiffo", "Base.SpiffoTail", "MoreTraits.ZombificationCure", "Base.Generator" };
                    inv:AddItem(randomitem[ZombRand(1, tablelength(randomitem) - 1)]);
                end
            end

        end
    end

end

local function Gourmand(_target, _name, _container)
    local player = getPlayer();
    if player:HasTrait("gourmand") then
        local basechance = 50;
        if player:HasTrait("Lucky") then
            basechance = basechance + 10;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 5;
        end

        for i = 0, _container:getItems():size() - 1 do
            local item = _container:getItems():get(i);
            if item ~= nil then
                if item:getCategory() == "Food" then
                    if item:isRotten() == true then
                        if ZombRand(100) <= basechance then
                            item:setAge(0);
                            item:setRotten(false);
                            item:updateAge();
                            item:update();
                        end
                    elseif item:isFresh() == false then
                        if ZombRand(100) <= basechance then
                            item:setAge(0);
                            item:updateAge();
                            item:update();
                        end
                    end
                end

            end
        end
    end

end
local function setFoodState(food, state)
    --States: "Gourmand", "Normal", "Ascetic"
    local player = getPlayer();
    local itemdata = food:getModData();
    local curUnhappyChange = food:getUnhappyChange();
    local curBoredomChange = food:getBoredomChange();
    local curHungChange = food:getHungChange();
    local curCookTime = food:getMinutesToCook();
    local curBurnTime = food:getMinutesToBurn();
    local curGoodHot = food:isGoodHot();
    local curBadInMicrowave = food:isBadInMicrowave();
    local curBadCold = food:isBadCold();
    local curDangerousUncooked = food:isbDangerousUncooked();
    local curStressChange = food:getStressChange();
    local curThirstChange = food:getThirstChange();
    local curEndChange = food:getEndChange();
    local curFatChange = food:getFatigueChange();
    local curSpices = tostring(food:getSpices());
    local curState = itemdata.sFoodState;
    local curStage = itemdata.iFoodStage;

    if curState ~= nil and curHungChange ~= nil then
        local oldHungChange = itemdata.origHungChange;
        local oldSpices = itemdata.origSpices;
        if curHungChange ~= oldHungChange or curSpices ~= oldSpices then
            --Original Food item has been updated. Recheck it.
            curState = nil;
        end
    end
    if curState == nil then
        --Food has no custom state assigned, therefore it must be in its Normal state

        --Append a comparative offset to happiness and boredom values depending on the state of the food.
        local comparativechange = 0;
        if food:isFrozen() == true then
            comparativechange = comparativechange + 30;
        end
        if food:isRotten() == true then
            comparativechange = comparativechange + 10;
        end
        if food:isFresh() == false then
            comparativechange = comparativechange + 10;
        end
        itemdata.origUnhappyChange = curUnhappyChange - comparativechange;
        itemdata.origBoredomChange = curBoredomChange - comparativechange;
        itemdata.origHungChange = curHungChange;
        itemdata.origCookTime = curCookTime;
        itemdata.origBurnTime = curBurnTime;
        itemdata.origGoodHot = curGoodHot;
        itemdata.origBadInMicrowave = curBadInMicrowave;
        itemdata.origBadCold = curBadCold;
        itemdata.origDangerousUncooked = curDangerousUncooked;
        itemdata.origStressChange = curStressChange;
        itemdata.origThirstChange = curThirstChange;
        itemdata.origEndChange = curEndChange;
        itemdata.origFatChange = curFatChange;
        itemdata.origSpices = curSpices;
        if itemdata.iFoodStage == nil then
            itemdata.iFoodStage = 0;
        end
        itemdata.sFoodState = "Normal";
    elseif curState == "Gourmand" and player:HasTrait("gourmand") == false or curState == "Ascetic" and player:HasTrait("ascetic") == false then
        --Change of State has occurred. Reset to Normal stats first
        state = "Normal";
    end
    if state == "Gourmand" then

        if food:isIsCookable() == true and food:isCooked() == false and curStage == 0 then
            food:setMinutesToCook(itemdata.origCookTime * 0.5);
            food:setMinutesToBurn(itemdata.origBurnTime * 2);
            --Set Food Prep stage to 1.
            itemdata.iFoodStage = 1;
        end

        if food:isCooked() == true and food:isRotten() == false and curStage ~= 2 then
            local food_happy = itemdata.origUnhappyChange;
            local food_bored = itemdata.origBoredomChange;
            local food_hunger = itemdata.origHungChange;
            local food_thirst = itemdata.origThirstChange;
            local food_end = itemdata.origEndChange;
            local food_stress = itemdata.origStressChange;
            local food_fatigue = itemdata.origFatChange;
            if food_happy >= 0 then
                food_happy = 0;
            else
                food_happy = food_happy * 1.5;
            end
            if food_bored >= 0 then
                food_bored = 0;
            else
                food_bored = food_bored * 1.5;
            end
            if food_thirst >= 0 then
                food_thirst = food_thirst * 0.5;
            else
                food_thirst = food_thirst * 1.5;
            end
            if food_end >= 0 then
                food_end = -5;
            else
                food_end = food_end * 1.5;
            end
            if food_stress >= 0 then
                food_stress = -10;
            else
                food_stress = food_stress * 1.5;
            end
            if food_fatigue >= 0 then
                food_fatigue = -5;
            else
                food_fatigue = food_fatigue * 1.5;
            end
            food_hunger = food_hunger * 1.5;
            food:setThirstChange(food_thirst);
            food:setUnhappyChange(food_happy);
            food:setBoredomChange(food_bored);
            food:setHungChange(food_hunger);
            food:setGoodHot(false);
            food:setBadInMicrowave(false);
            food:setBadCold(false);
            food:setAge(0);
            food:updateAge();
            itemdata.iFoodStage = 2;
            food:update();

            --Set Food Prep state to 2 - done.

        end
        itemdata.sFoodState = "Gourmand";
    elseif state == "Normal" then
        food:setUnhappyChange(itemdata.origUnhappyChange);
        food:setBoredomChange(itemdata.origBoredomChange);
        food:setHungChange(itemdata.origHungChange);
        food:setMinutesToCook(itemdata.origCookTime);
        food:setMinutesToBurn(itemdata.origBurnTime);
        food:setBadInMicrowave(itemdata.origBadInMicrowave);
        food:setGoodHot(itemdata.origGoodHot);
        food:setBadCold(itemdata.origBadCold);
        food:setbDangerousUncooked(itemdata.origDangerousUncooked);
        food:setEndChange(itemdata.origEndChange);
        food:setStressChange(itemdata.origStressChange);
        food:setThirstChange(itemdata.origThirstChange);
        food:setFatigueChange(itemdata.origFatChange);
        if itemdata.iFoodStage == nil then
            itemdata.iFoodStage = 0;
        end
        itemdata.sFoodState = "Normal";
    elseif state == "Ascetic" then
        if food:isIsCookable() == true and food:isCooked() == false and curStage == 0 then
            food:setMinutesToCook(itemdata.origCookTime * 1.5);
            food:setMinutesToBurn(itemdata.origBurnTime * 0.5);
            food:setUnhappyChange(0);
            food:setBoredomChange(0);
            food:setGoodHot(false);
            food:setBadCold(false);
            --Set Food Prep stage to 1.
            itemdata.iFoodStage = 1;
        end
        if food:isPackaged() == true then
            local food_happy = itemdata.origUnhappyChange;
            local food_bored = itemdata.origBoredomChange;
            local food_end = itemdata.origEndChange;
            local food_stress = itemdata.origStressChange;
            if food_happy < 0 then
                food:setUnhappyChange(0);
            end
            if food_bored < 0 then
                food:setBoredomChange(0);
            end
            if food_end < 0 then
                food:setEndChange(0);
            end
            if food_stress < 0 then
                food:setStressChange(0);
            end
        end
        if food:isCooked() == true and food:isRotten() == false and curStage ~= 2 then
            local food_happy = itemdata.origUnhappyChange;
            local food_bored = itemdata.origBoredomChange;
            local food_hunger = itemdata.origHungChange;
            local food_thirst = itemdata.origThirstChange;
            local food_end = itemdata.origEndChange;
            local food_stress = itemdata.origStressChange;
            if food_happy >= 0 then
                food_happy = -10;
            else
                food_happy = food_happy * -1;
            end
            if food_bored >= 0 then
                food_bored = -10;
            else
                food_bored = food_bored * -1;
            end
            if food_thirst >= 0 then
                food_thirst = food_thirst * 2;
            else
                food_thirst = -10
            end
            if food_end >= 0 then
                food_end = food_end * 2;
            else
                food_end = 10;
            end
            if food_stress >= 0 then
                food_stress = food_stress * 2;
            else
                food_stress = 10;
            end
            food_hunger = food_hunger * 0.75;
            food:setUnhappyChange(food_happy);
            food:setBoredomChange(food_bored);
            food:setHungChange(food_hunger);
            food:setGoodHot(itemdata.origGoodHot);
            food:setBadInMicrowave(itemdata.origBadInMicrowave);
            food:setBadCold(itemdata.origBadCold);
            food:setEndChange(food_end);
            food:setStressChange(food_stress);
            food:update();
            --Set Food Prep state to 2 - done.
            itemdata.iFoodStage = 2;
        end
        itemdata.sFoodState = "Ascetic";
    end

end
local function FoodUpdate(_player)
    local player = _player;
    local inv = player:getInventory();
    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i);
        if item ~= nil then
            if item:getCategory() == "Food" then
                if player:HasTrait("gourmand") then
                    setFoodState(item, "Gourmand");
                elseif player:HasTrait("ascetic") then
                    setFoodState(item, "Ascetic");
                else
                    setFoodState(item, "Normal");
                end
            end
        end
    end
end
local function FearfulUpdate(_player)
    local player = _player;
    if player:HasTrait("fearful") then
        local stats = player:getStats();
        local panic = stats:getPanic();
        if panic > 5 then
            local chance = 3 + panic / 10;
            if player:HasTrait("Cowardly") then
                chance = chance + 1;
            end
            if player:HasTrait("Lucky") then
                chance = chance - 1;
            end
            if player:HasTrait("Unlucky") then
                chance = chance + 1;
            end
            if ZombRand(0, 1000) <= chance then
                if panic <= 25 then
                    player:Say("*Whimper*");
                    addSound(player, player:getX(), player:getY(), player:getZ(), 5, 10);
                elseif panic <= 50 then
                    player:Say("*Muffled Shriek*");
                    addSound(player, player:getX(), player:getY(), player:getZ(), 10, 15);
                elseif panic <= 75 then
                    player:Say("*Panicked Screech*");
                    addSound(player, player:getX(), player:getY(), player:getZ(), 20, 25);
                elseif panic > 75 then
                    player:Say("*Desperate Screaming*");
                    addSound(player, player:getX(), player:getY(), player:getZ(), 25, 50);
                end
            end
        end
    end
end
local function GymGoer(_player, _perk, _amount)
    local player = _player;
    local perk = _perk;
    local amount = _amount;
    if player:HasTrait("gymgoer") then
        if perk == Perks.Fitness or perk == Perks.Strength then
            amount = amount * 2;
            player:getXp():AddXP(perk, amount, false, false);
        end

    end
end
local function test(_container)
    local container = _container;
    local inv = container:getInventory();
    inv:AddItem("Base.Screwdriver");
end
local function MainPlayerUpdate(_player)
    local player = _player;
    local playerdata = player:getModData();
    if internalTick >= 30 then
        amputee(player);
        vehicleCheck(player);
        FearfulUpdate(player);
        FoodUpdate(player);
        --Reset internalTick every 30 ticks
        internalTick = 0;
    elseif internalTick == 20 then
        Gordanite(player);
    elseif internalTick == 10 then
        SuperImmune(player, playerdata);
        Immunocompromised(player, playerdata);
    end
    indefatigable(player, playerdata);
    anemic(player);
    thickblood(player);
    CheckDepress(player, playerdata);
    CheckSelfHarm(player);
    Blissful(player);
    hardytrait(player);
    drinkerupdate(player, playerdata);
    bouncerupdate(player, playerdata);
    badteethtrait(player);
    albino(player);
    if suspendevasive == false then
        ToadTraitEvasive(player, playerdata);
    end
    internalTick = internalTick + 1;
end
--Events.OnPlayerMove.Add(gimp);
--Events.OnPlayerMove.Add(fast);
Events.OnZombieDead.Add(graveRobber);
Events.OnWeaponHitCharacter.Add(problunt);
Events.OnWeaponHitCharacter.Add(problade);
Events.OnWeaponHitCharacter.Add(prospear);
Events.OnWeaponHitCharacter.Add(actionhero);
Events.OnWeaponSwing.Add(progun);
Events.OnWeaponHitCharacter.Add(martial);
Events.OnDawn.Add(drinkerpoison);
Events.EveryHours.Add(drinkertick);
Events.AddXP.Add(Specialization);
Events.AddXP.Add(GymGoer);
Events.OnDawn.Add(indefatigablecounter);
Events.OnPlayerUpdate.Add(MainPlayerUpdate);
Events.EveryTenMinutes.Add(ToadTraitButter);
--Events.EveryTenMinutes.Add(GourmandUpdate);
Events.EveryTenMinutes.Add(checkWeight);
Events.EveryHours.Add(ToadTraitDepressive);
Events.OnNewGame.Add(initToadTraitsPerks);
Events.OnNewGame.Add(initToadTraitsItems);
Events.OnGameBoot.Add(initToadTraits);
Events.OnFillContainer.Add(Gourmand);
Events.OnFillContainer.Add(ToadTraitScrounger);
Events.OnFillContainer.Add(ToadTraitIncomprehensive);
Events.OnFillContainer.Add(ToadTraitAntique);
