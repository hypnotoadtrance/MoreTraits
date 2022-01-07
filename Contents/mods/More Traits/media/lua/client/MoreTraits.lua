require('NPCs/MainCreationMethods');
require("Items/Distributions");
require("Items/ProceduralDistributions");
--[[
TODO Update scrounger, incomprehensive, and graveRobber
We need a method of Tagging containers, rolling for loot, and then inserting said rolled loot into container mod data.
Then we need a method to iterate through nearby containers for each player and compare their traits to the moddata in
the container. Then insert/remove loot on a per-player,per-container basis.
At present, I'm stuck on iterating through nearby containers. I don't know how to do it.
TODO Figure out what is causing stat synchronization issues
When playing in Singleplayer, traits like Blissful work just fine. But in Multiplayer, subtracting stats doesn't
seem to work properly. This also effects Hardy, Alcoholic (removing stress when drinking alcohol doesn't work in MP)
TODO Code optimization
This is constantly ongoing. Whenever I see something that can be written more efficiently, I try to rewrite where i can.
TODO Reimplement Fast and Slow traits
Ever since the animations update, the previous calculations stopped working, and despite hours wracking my brain,
I have been unable to find a workaround.
--]]
--Global Variables
skipxpadd = false;
suspendevasive = false;
internalTick = 0;
luckimpact = 1.0;

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
local function round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
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
        result:setTooltip(getText("UI_cannibal_early"));
    elseif times <= 50 then
        stats:setStress(stats:getStress() + 0.1);
        result:setUnhappyChange(10);
        result:setTooltip(getText("UI_cannibal_familiar"));
    else
        stats:setStress(stats:getStress() - 0.1);
        result:setTooltip(getText("UI_cannibal_comfortable"));
        result:setUnhappyChange(-10);
        player:getInventory():AddItem("MoreTraits.BloodBox");
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

local function initToadTraitsItems(_player)
    local player = _player;
    local inv = player:getInventory();
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
        if SandboxVars.MoreTraits.PreparedMedicalBandageAmount then
            inv:AddItems("Base.Bandage", SandboxVars.MoreTraits.PreparedMedicalBandageAmount);
        else
            inv:AddItems("Base.Bandage", 4);
        end
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
        if SandboxVars.MoreTraits.PreparedCarGasToggle == true then
            inv:AddItem("Base.PetrolCan");
        end
        inv:AddItem("Base.CarBatteryCharger");
        inv:AddItem("Base.Screwdriver");
        inv:AddItem("Base.Wrench");
        inv:AddItem("Base.LugWrench");
        inv:AddItem("Base.TirePump");
        inv:AddItem("Base.Jack");
    end
    if player:HasTrait("drinker") then
        if SandboxVars.MoreTraits.AlcoholicFreeDrink == true then
            inv:AddItem("Base.WhiskeyFull");
        end
    end
    if player:HasTrait("Tailor") then
        inv:AddItem("Base.Scissors");
        inv:AddItem("Base.Needle");
        inv:AddItem("Base.SewingKit");
        inv:AddItems("Base.Thread", 4);
    end
end

local function initToadTraitsPerks(_player)
    local player = _player;
    local damage = 25;
    local bandagestrength = 5;
    local splintstrength = 0.9;
    local fracturetime = 50;
    local scratchtimemod = 20;
    local bleedtimemod = 10;
    if SandboxVars.MoreTraits.LuckImpact then
        luckimpact = SandboxVars.MoreTraits.LuckImpact * 0.01;
    end
    player:getModData().bToadTraitDepressed = false;
    player:getModData().indefatigablecooldown = 0;
    player:getModData().bindefatigable = false;
    player:getModData().bSatedDrink = true;
    player:getModData().iHoursSinceDrink = 0;
    player:getModData().iTimesCannibal = 0;

    if player:HasTrait("Lucky") then
        damage = damage - 5 * luckimpact;
        bandagestrength = bandagestrength + 2 * luckimpact;
        fracturetime = fracturetime - 5 * luckimpact;
        splintstrength = splintstrength + 0.1 * luckimpact;
        scratchtimemod = scratchtimemod - 5 * luckimpact;
        bleedtimemod = bleedtimemod - 2 * luckimpact;
    end
    if player:HasTrait("Unlucky") then
        damage = damage + 5 * luckimpact;
        bandagestrength = bandagestrength - 2 * luckimpact;
        fracturetime = fracturetime + 5 * luckimpact;
        splintstrength = splintstrength - 0.1 * luckimpact;
        scratchtimemod = scratchtimemod + 5 * luckimpact;
        bleedtimemod = bleedtimemod + 2 * luckimpact;
    end

    if player:HasTrait("injured") then
        suspendevasive = true;
        --print("Beginning Injury.");
        local bodydamage = player:getBodyDamage();
        local itterations = ZombRand(1, 4) + 1;
        local doburns = true;
        if SandboxVars.MoreTraits.InjuredBurns == false then
            doburns = false;
        end
        for i = 0, itterations do
            local randompart = ZombRand(0, 16);
            local b = bodydamage:getBodyPart(BodyPartType.FromIndex(randompart));
            local injury = ZombRand(0, 5);
            local skip = false;
            if b:HasInjury() then
                itterations = itterations - 1;
                skip = true;
            end
            if skip == false then
                if injury <= 1 then
                    b:AddDamage(damage);
                    b:setScratched(true, true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                elseif injury == 2 then
                    if doburns == true then
                        b:AddDamage(damage);
                        b:setBurned();
                        b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                    else
                        itterations = itterations - 1;
                    end
                elseif injury == 3 then
                    b:AddDamage(damage);
                    b:setCut(true, true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                elseif injury >= 4 then
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
    checkWeight();
end

local function ToadTraitEvasive(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("evasive") then
        local basechance = 33;
        local bMarkForUpdate = false;
        local bodydamage = player:getBodyDamage();
        local modbodydamage = playerdata.ToadTraitBodyDamage;
        local lastinfected = playerdata.bisInfected;
        if bodydamage:getNumPartsScratched() == nil then
            return ;
        end ;
        if lastinfected == null then
            playerdata.bisInfected = bodydamage:IsInfected();
            lastinfected = playerdata.bisInfected;
        end
        if SandboxVars.MoreTraits.EvasiveChance then
            basechance = SandboxVars.MoreTraits.EvasiveChance;
        end
        if player:HasTrait("Lucky") then
            basechance = basechance + 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 3 * luckimpact;
        end
        if modbodydamage == nil then
            modbodydamage = {};
            --Initialize the Body Part Reference Table
            print("Initializing Body Damage");
            for i = 0, bodydamage:getBodyParts():size() - 1 do
                local b = bodydamage:getBodyParts():get(i);
                local temptable = { b:getType(), b:scratched(), b:bitten(), b:isCut() };
                table.insert(modbodydamage, temptable);
            end
            playerdata.ToadTraitBodyDamage = modbodydamage;
            print("Body Damage Initialized");
        else
            for n = 0, bodydamage:getBodyParts():size() - 1 do
                local i = bodydamage:getBodyParts():get(n);
                for _, b in pairs(modbodydamage) do
                    if i:getType() == b[1] then
                        if i:scratched() == false and b[2] == true or i:bitten() == false and b[3] == true or i:isCut() == false and b[4] == true then
                            bMarkForUpdate = true;
                        end
                        if i:scratched() == true and b[2] == false then
                            print("Scratch Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance then
                                i:RestoreToFullHealth();
                                i:setScratched(false, false);
                                i:SetInfected(false);
                                if lastinfected == false and bodydamage:IsInfected() == true then
                                    bodydamage:setInfected(false);
                                    print("Infection from Dodged Attack Removed");
                                end
                                player:Say(getText("UI_trait_dodgesay"));
                            else
                                bMarkForUpdate = true;
                            end
                        elseif i:bitten() == true and b[3] == false then
                            print("Bite Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance then
                                i:RestoreToFullHealth();
                                i:SetBitten(false, false);
                                i:SetInfected(false);
                                if lastinfected == false and bodydamage:IsInfected() == true then
                                    bodydamage:setInfected(false);
                                    print("Infection from Dodged Attack Removed");
                                end
                                player:Say(getText("UI_trait_dodgesay"));
                            else
                                bMarkForUpdate = true;
                            end
                        elseif i:isCut() == true and b[4] == false then
                            print("Laceration Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance then
                                i:RestoreToFullHealth();
                                i:setCut(false, false);
                                i:SetInfected(false);
                                if lastinfected == false and bodydamage:IsInfected() == true then
                                    bodydamage:setInfected(false);
                                    print("Infection from Dodged Attack Removed");
                                end
                                player:Say(getText("UI_trait_dodgesay"));
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
                local temptable = { b:getType(), b:scratched(), b:bitten(), b:isCut() };
                table.insert(modbodydamage, temptable);
            end
            playerdata.ToadTraitBodyDamage = modbodydamage;
            playerdata.bisInfected = bodydamage:IsInfected();
        end
    end
end

local function ToadTraitButter()
    local player = getPlayer();
    if player:HasTrait("butterfingers") and player:isPlayerMoving() then
        local basechance = 5;
        if player:HasTrait("AllThumbs") then
            basechance = basechance + 1;
        end
        if player:HasTrait("Dextrous") then
            basechance = basechance - 1;
        end
        if player:HasTrait("Lucky") then
            basechance = basechance - 1 * luckimpact;
        end
        if player:HasTrait("packmule") then
            basechance = basechance - 1;
        end
        if player:HasTrait("packmouse") then
            basechance = basechance + 1;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 1 * luckimpact;
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
            basechance = basechance + 10 * luckimpact;
            modifier = modifier + 0.1 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 5 * luckimpact;
            modifier = modifier - 0.1 * luckimpact;
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
                                bchance = bchance + 2 * luckimpact;
                            end
                            if player:HasTrait("Unlucky") then
                                bchance = bchance - 2 * luckimpact;
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
            basechance = basechance - 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 5 * luckimpact;
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
                                bchance = bchance - 2 * luckimpact;
                            end
                            if player:HasTrait("Unlucky") then
                                bchance = bchance + 2 * luckimpact;
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
    table.insert(items, "MoreTraits.Slugger");
    table.insert(items, "MoreTraits.AntiqueJacket");
    table.insert(items, "MoreTraits.AntiqueVest");
    table.insert(items, "MoreTraits.AntiqueBoots");
    table.insert(items, "MoreTraits.AntiqueMag1");
    table.insert(items, "MoreTraits.AntiqueMag2");
    table.insert(items, "MoreTraits.AntiqueMag3");

    local length = 0
    for k, v in pairs(items) do
        length = length + 1;
    end
    local player = getPlayer();
    if player:HasTrait("antique") then
        local basechance = 5;
        if player:HasTrait("Lucky") then
            basechance = basechance + 2 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 1 * luckimpact;
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
            basechance = basechance - 2 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 2 * luckimpact;
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
                player:getBodyDamage():setUnhappynessLevel(player:getBodyDamage():getUnhappynessLevel() + 0.001);
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
                    b:AddDamage(0.001);
                end
            end
        end
    end
end

local function Blissful(_player)
    local player = _player;
    local bodydamage = player:getBodyDamage();
    local unhappiness = bodydamage:getUnhappynessLevel();
    local boredom = bodydamage:getBoredomLevel();
    if player:HasTrait("blissful") then
        if unhappiness >= 10 then
            bodydamage:setUnhappynessLevel(unhappiness - 0.01);
        end
        if boredom >= 10 then
            bodydamage:setBoredomLevel(boredom - 0.005);
        end
    end
end

local function Specialization(_player, _perk, _amount)
    local player = _player;
    local perk = _perk;
    local amount = _amount;
    local newamount = 0;
    local skip = false;
    local modifier = 75;
    local perklvl = player:getPerkLevel(_perk);
    if SandboxVars.MoreTraits.SpecializationXPPercent then
        modifier = SandboxVars.MoreTraits.SpecializationXPPercent;
    end
    --shift decimal over two places for calculation purposes.
    modifier = modifier * 0.01;
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
            newamount = amount * modifier;
            local currentxp = player:getXp():getXP(perk);
            local correctamount = currentxp - newamount
            local testxp = currentxp - amount;
            --Check if the newxp amount would give the player a negative level.
            --Lua doesn't support Switch Case statements so here's a massive If/then list. -_-
            if skip == false then
                if perklvl == 1 and testxp <= 75 then
                    skip = true;
                elseif perklvl == 2 and testxp <= 150 then
                    skip = true;
                elseif perklvl == 3 and testxp <= 300 then
                    skip = true;
                elseif perklvl == 4 and testxp <= 750 then
                    skip = true;
                elseif perklvl == 5 and testxp <= 1500 then
                    skip = true;
                elseif perklvl == 6 and testxp <= 3000 then
                    skip = true;
                elseif perklvl == 7 and testxp <= 4500 then
                    skip = true;
                elseif perklvl == 8 and testxp <= 6000 then
                    skip = true;
                elseif perklvl == 9 and testxp <= 7500 then
                    skip = true;
                elseif perklvl == 10 and testxp <= 9000 then
                    skip = true;
                end
            end
            if skip == false then
                player:getXp():AddXP(perk, -1 * amount, false, false);
                while player:getXp():getXP(perk) < correctamount do
                    player:getXp():AddXP(perk, 0.01, false, false);
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
        local longBluntLvl = player:getPerkLevel(Perks.Blunt);
        local strengthlvl = player:getPerkLevel(Perks.Strength);
        local floatmod = (longBluntLvl + strengthlvl) / 2 * 0.1;
        if player:getPrimaryHandItem() ~= nil then
            if player:getPrimaryHandItem():getType() == "Crowbar" then
                if SandboxVars.MoreTraits.GordaniteEffectiveness then
                    local modifier = SandboxVars.MoreTraits.GordaniteEffectiveness * 0.01;
                    floatmod = floatmod * modifier;
                    longBluntLvl = longBluntLvl * modifier;
                    strengthlvl = strengthlvl * modifier;
                end
                local crowbar = player:getPrimaryHandItem();
                crowbar:setMinDamage(0.7 + floatmod / 2);
                crowbar:setMaxDamage(1.25 + floatmod / 2);
                crowbar:setPushBackMod(0.6 + floatmod);
                crowbar:setDoorDamage(15 + strengthlvl + longBluntLvl);
                crowbar:setTreeDamage(15 + strengthlvl + longBluntLvl * 2);
                crowbar:setCriticalChance(35 + (strengthlvl + longBluntLvl) / 2);
                crowbar:setSwingTime(2.8 - floatmod);
                crowbar:setBaseSpeed(1.1 + floatmod);
                crowbar:setWeaponLength(0.4 + floatmod / 2);
                crowbar:setMinimumSwingTime(1.7 - floatmod);
                crowbar:setName(getText("Tooltip_MoreTraits_GordaniteBoost"));
                crowbar:setTooltip(getText("Tooltip_MoreTraits_ItemBoost"));
            end
        end
    end
    if player:HasItem("Crowbar") == true then
        local skip = false;
        if player:getPrimaryHandItem() ~= null then
            if player:getPrimaryHandItem():getName() == getText("Tooltip_MoreTraits_GordaniteBoost") or player:getPrimaryHandItem():getType() == "Crowbar" then
                skip = true;
            end
        end
        if skip == false then
            local inv = player:getInventory();
            for i = 0, inv:getItems():size() - 1 do
                local item = player:getInventory():getItems():get(i);
                if item:getName() == getText("Tooltip_MoreTraits_GordaniteBoost") then
                    local crowbar = item;
                    crowbar:setMinDamage(0.6);
                    crowbar:setMaxDamage(1.15);
                    crowbar:setPushBackMod(0.5);
                    crowbar:setDoorDamage(8);
                    crowbar:setCriticalChance(35);
                    crowbar:setSwingTime(3);
                    crowbar:setName(getText("Tooltip_MoreTraits_GordaniteDefault"));
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
                            if enemies:get(i):DistTo(player) <= 2.5 then
                                enemies:get(i):setStaggerBack(true);
                            end
                        end
                    end
                end
                player:Say(getText("UI_trait_indefatigable"));
            end
        end
    end
end

local function indefatigablecounter()
    local player = getPlayer();
    local playerdata = player:getModData();
    local recharge = 7 * 24;
    if player:HasTrait("indefatigable") then
        if SandboxVars.MoreTraits.IndefatigableRecharge then
            recharge = SandboxVars.MoreTraits.IndefatigableRecharge * 24;
        end
        if playerdata.bindefatigable == true then
            if playerdata.indefatigablecooldown >= recharge then
                playerdata.indefatigablecooldown = 0;
                playerdata.bindefatigable = false;
                player:Say(getText("UI_trait_indefatigablecooldown"));
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
        local regenerationrate = 0.001;
        if SandboxVars.MoreTraits.HardyRegeneration then
            regenerationrate = regenerationrate * (SandboxVars.MoreTraits.HardyRegeneration * 0.01);
        end
        if endurance < 1 and player:IsRunning() == false and player:isSprinting() == false then
            stats:setEndurance(endurance + regenerationrate);
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
        local hoursthreshold = 36;
        local divider = 5;
        if SandboxVars.MoreTraits.AlcoholicFrequency then
            hoursthreshold = SandboxVars.MoreTraits.AlcoholicFrequency * 1.5;
        end
        if hoursthreshold <= 2 then
            divider = 0.1;
        elseif hoursthreshold <= 5 then
            divider = 0.2;
        elseif hoursthreshold <= 10 then
            divider = 0.5;
        elseif hoursthreshold <= 20 then
            divider = 1;
        end
        if drunkness >= 10 then
            if playerdata.bSatedDrink == false then
                playerdata.bSatedDrink = true;
                player:Say(getText("UI_trait_alcoholicsatisfied"));
            end
            playerdata.iHoursSinceDrink = 0;
            stats:setAnger(0);
            stats:setStress(0);
        end
        if playerdata.bSatedDrink == false then
            if playerdata.iHoursSinceDrink > hoursthreshold then
                stats:setPain(playerdata.iHoursSinceDrink / divider);
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
        local divider = 4;
        if SandboxVars.MoreTraits.AlcoholicFrequency then
            hoursthreshold = SandboxVars.MoreTraits.AlcoholicFrequency;
        end
        if hoursthreshold <= 2 then
            divider = 0.1;
        elseif hoursthreshold <= 5 then
            divider = 0.2;
        elseif hoursthreshold <= 10 then
            divider = 0.5;
        elseif hoursthreshold <= 20 then
            divider = 1;
        end
        if player:HasTrait("Lucky") then
            hoursthreshold = hoursthreshold + 4 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            hoursthreshold = hoursthreshold - 2 * luckimpact;
        end
        if player:HasTrait("Lightdrinker") then
            hoursthreshold = hoursthreshold - 2;
        end
        playerdata.iHoursSinceDrink = playerdata.iHoursSinceDrink + 1;
        if playerdata.bSatedDrink == true then
            if playerdata.iHoursSinceDrink >= hoursthreshold then
                if ZombRand(100) <= hoursthreshold / divider then
                    playerdata.bSatedDrink = false;
                    print("Player needs alcohol.");
                    player:Say(getText("UI_trait_alcoholicneed"));
                end
            end
        end
    end
end

local function drinkerpoison()
    local player = getPlayer();
    local playerdata = player:getModData();
    local hoursthreshold = 72;
    local divider = 5;
    local cooldown = 0;

    if player:HasTrait("drinker") then
        if playerdata.iWithdrawalCooldown == null then
            playerdata.iWithdrawalCooldown = 24;
        end
        cooldown = playerdata.iWithdrawalCooldown;
        if SandboxVars.MoreTraits.AlcoholicWithdrawal then
            hoursthreshold = SandboxVars.MoreTraits.AlcoholicWithdrawal;
        end
        if hoursthreshold <= 2 then
            divider = 0.5;
        elseif hoursthreshold <= 5 then
            divider = 0.75;
        elseif hoursthreshold <= 10 then
            divider = 1;
        elseif hoursthreshold <= 20 then
            divider = 2;
        elseif hoursthreshold <= 24 then
            divider = 4;
        elseif hoursthreshold <= 48 then
            divider = 5;
        end
        if playerdata.iHoursSinceDrink > hoursthreshold and playerdata.bSatedDrink == false and cooldown <= 0 then
            print("Player is suffering from alcohol withdrawal.");
            player:Say(getText("UI_trait_alcoholicwithdrawal"));
            player:getBodyDamage():setPoisonLevel((playerdata.iHoursSinceDrink / divider));
            playerdata.iWithdrawalCooldown = ZombRand(12, 24);
        end
        playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown - 1;
    end
end

local function bouncerupdate(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local chance = 5;
    local cooldown = 60;
    local enemies = player:getSpottedList();
    local enemy = nil;
    local closeenemies = {};
    if player:HasTrait("bouncer") then
        if SandboxVars.MoreTraits.BouncerEffectiveness then
            chance = SandboxVars.MoreTraits.BouncerEffectiveness;
        end
        if SandboxVars.MoreTraits.BouncerCooldown then
            cooldown = SandboxVars.MoreTraits.BouncerCooldown;
        end
        if player:HasTrait("Lucky") then
            chance = chance + 1 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 1 * luckimpact;
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
                                    playerdata.iBouncercooldown = cooldown;
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
            critchance = critchance + 1 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            critchance = critchance - 1 * luckimpact;
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
                critchance = critchance + 1 * luckimpact;
            end
            if player:HasTrait("Unlucky") then
                critchance = critchance - 1 * luckimpact;
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
                critchance = critchance + 1 * luckimpact;
            end
            if player:HasTrait("Unlucky") then
                critchance = critchance - 1 * luckimpact;
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
            chance = chance + 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 5 * luckimpact;
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
                critchance = critchance + 1 * luckimpact;
            end
            if player:HasTrait("Unlucky") then
                critchance = critchance - 1 * luckimpact;
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
            critchance = critchance + 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            critchance = critchance - 5 * luckimpact;
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
                    local adjust = 0.002;
                    if b:getType() == BodyPartType.Neck then
                        adjust = adjust * 5;
                    end
                    b:ReduceHealth(adjust);
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
                    local adjust = 0.002;
                    if b:getType() == BodyPartType.Neck then
                        adjust = adjust * 5;
                    end
                    b:AddHealth(adjust);
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
    if SandboxVars.MoreTraits.SuperImmunePercent then
        chance = SandboxVars.MoreTraits.SuperImmunePercent;
    end
    if player:HasTrait("superimmune") then
        if playerdata.bSuperImmune ~= nil then
            if player:HasTrait("Lucky") then
                chance = chance + 1 * luckimpact;
            end
            if player:HasTrait("Unlucky") then
                chance = chance - 1 * luckimpact;
            end
            if playerdata.bSuperImmune == true then
                if bodydamage:IsInfected() then
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
        if bodydamage:IsInfected() == false and playerdata.bSuperImmune == false then
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

function checkWeight()
    local player = getPlayer();
    local strength = player:getPerkLevel(Perks.Strength);
    local mule = 10;
    local mouse = 6;
    local default = 8;
    local globalmod = 0;
    if SandboxVars.MoreTraits.WeightPackMule then
        mule = SandboxVars.MoreTraits.WeightPackMule;
    end
    if SandboxVars.MoreTraits.WeightPackMouse then
        mouse = SandboxVars.MoreTraits.WeightPackMouse;
    end
    if SandboxVars.MoreTraits.WeightDefault then
        default = SandboxVars.MoreTraits.WeightDefault;
    end
    if SandboxVars.MoreTraits.WeightGlobalMod then
        globalmod = SandboxVars.MoreTraits.WeightGlobalMod;
    end
    if player:HasTrait("packmule") then
        if player:getMaxWeightBase() ~= mule + strength / 5 + globalmod then
            player:setMaxWeight(mule + strength + globalmod);
            player:setMaxWeightBase(mule + strength / 5 + globalmod);
        end
    elseif player:HasTrait("packmouse") then
        if player:getMaxWeightBase() ~= mouse + globalmod then
            player:setMaxWeight(mouse + globalmod);
            player:setMaxWeightBase(mouse + globalmod);
        end
    else
        if player:getMaxWeightBase() ~= default + globalmod then
            player:setMaxWeight(default + globalmod);
            player:setMaxWeightBase(default + globalmod);
        end
    end
end

local function graveRobber(_zombie)
    local player = getPlayer();
    local zombie = _zombie;
    local chance = 3;
    local extraloot = 1;
    if SandboxVars.MoreTraits.GraveRobberChance then
        chance = SandboxVars.MoreTraits.GraveRobberChance;
    end
    if SandboxVars.MoreTraits.GraveRobberGuaranteedLoot then
        extraloot = SandboxVars.MoreTraits.GraveRobberGuaranteedLoot;
    end
    if player:HasTrait("graverobber") then
        if player:HasTrait("Lucky") then
            chance = chance + 1 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 1 * luckimpact;
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
            local itterations = ZombRand(0, 3);
            itterations = itterations + extraloot;
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
            basechance = basechance + 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 5 * luckimpact;
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
                chance = chance - 1 * luckimpact;
            end
            if player:HasTrait("Unlucky") then
                chance = chance + 1 * luckimpact;
            end
            if ZombRand(0, 1000) <= chance then
                if panic <= 25 then
                    player:Say(getText("UI_fearful_slightpanic"));
                    addSound(player, player:getX(), player:getY(), player:getZ(), 5, 10);
                elseif panic <= 50 then
                    player:Say(getText("UI_fearful_panic"));
                    addSound(player, player:getX(), player:getY(), player:getZ(), 10, 15);
                elseif panic <= 75 then
                    player:Say(getText("UI_fearful_strongpanic"));
                    addSound(player, player:getX(), player:getY(), player:getZ(), 20, 25);
                elseif panic > 75 then
                    player:Say(getText("UI_fearful_extremepanic"));
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
    local modifier = 200;
    if SandboxVars.MoreTraits.GymGoerPercent then
        modifier = SandboxVars.MoreTraits.GymGoerPercent;
    end
    --Shift decimal over two places.
    modifier = modifier * 0.01;
    if player:HasTrait("gymgoer") and player:getCurrentState() == FitnessState.instance() then
        if perk == Perks.Fitness or perk == Perks.Strength then
            amount = amount * (modifier - 1);
            player:getXp():AddXP(perk, amount, false, false);
        end
    end
end

local function MainPlayerUpdate(_player)
    local player = _player;
    local playerdata = player:getModData();
    if internalTick >= 30 then
        amputee(player);
        vehicleCheck(player);
        FoodUpdate(player);
        Gordanite(player);
        --Reset internalTick every 30 ticks
        internalTick = 0;
    elseif internalTick == 20 then
        FearfulUpdate(player);
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
Events.EveryHours.Add(drinkerpoison);
Events.EveryHours.Add(drinkertick);
Events.AddXP.Add(Specialization);
Events.AddXP.Add(GymGoer);
Events.EveryHours.Add(indefatigablecounter);
Events.OnPlayerUpdate.Add(MainPlayerUpdate);
Events.EveryOneMinute.Add(ToadTraitButter);
Events.EveryTenMinutes.Add(checkWeight);
Events.EveryHours.Add(ToadTraitDepressive);
Events.OnNewGame.Add(initToadTraitsPerks);
Events.OnNewGame.Add(initToadTraitsItems);
Events.OnFillContainer.Add(Gourmand);
Events.OnFillContainer.Add(ToadTraitScrounger);
Events.OnFillContainer.Add(ToadTraitIncomprehensive);
Events.OnFillContainer.Add(ToadTraitAntique);