require('NPCs/MainCreationMethods');
require("Items/Distributions");
require("Items/ProceduralDistributions");
--[[
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
MTVersion = getCore():getGameVersion();
BodyDamagedFromTrait = {};

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
    local bodyParts = bodyDamage:getBodyParts();
    for i = bodyParts:size() - 1, 0, -1 do
        local bodyPart = bodyParts:get(i);
        if bodyPart:IsInfected() then
            bodyPart:RestoreToFullHealth();
        end
    end
    bodyDamage:setInfected(false);
    bodyDamage:setInfectionMortalityDuration(-1);
    bodyDamage:setInfectionTime(-1);
    bodyDamage:setInfectionLevel(0);
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

function initToadTraitsItems(_player)
    local player = _player;
    local inv = player:getInventory();
    if player:HasTrait("preparedfood") then
        inv:addItemOnServer(inv:AddItem("Base.Plasticbag"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.Plasticbag" then
                    player:setSecondaryHandItem(bag);
                    local baginv = bag:getInventory();
                    local addeditems = baginv:AddItems("Base.PopBottle", 3);
                    for i = 0, addeditems:size() - 1 do
                        local item = baginv:getItems():get(i);
                        baginv:addItemOnServer(item);
                    end
                    baginv:addItemOnServer(baginv:AddItem("Base.TinOpener"));
                    baginv:addItemOnServer(baginv:AddItem("Base.CannedTomato"));
                    baginv:addItemOnServer(baginv:AddItem("Base.CannedPotato"));
                    baginv:addItemOnServer(baginv:AddItem("Base.CannedCarrots"));
                    baginv:addItemOnServer(baginv:AddItem("Base.CannedBroccoli"));
                    baginv:addItemOnServer(baginv:AddItem("Base.CannedCabbage"));
                    baginv:addItemOnServer(baginv:AddItem("Base.CannedEggplant"));
                    break ;
                end
            end
        end
    end
    if player:HasTrait("preparedammo") then
        inv:addItemOnServer(inv:AddItems("Base.Bullets9mmBox", 3));
        inv:addItemOnServer(inv:AddItems("Base.ShotgunShellsBox", 2));
    end
    if player:HasTrait("preparedweapon") then
        inv:addItemOnServer(inv:AddItem("Base.BaseballBatNails"));
        inv:addItemOnServer(inv:AddItem("Base.HuntingKnife"));
    end
    if player:HasTrait("preparedmedical") then
        inv:addItemOnServer(inv:AddItem("Base.FirstAidKit"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.FirstAidKit" then
                    player:setSecondaryHandItem(bag);
                    local baginv = bag:getInventory();
                    baginv:addItemOnServer(baginv:AddItem("Base.Bandaid"));
                    baginv:addItemOnServer(baginv:AddItem("Base.PillsAntiDep"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Disinfectant"));
                    baginv:addItemOnServer(baginv:AddItem("Base.AlcoholWipes"));
                    baginv:addItemOnServer(baginv:AddItem("Base.PillsBeta"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Pills"));
                    if SandboxVars.MoreTraits.PreparedMedicalBandageAmount then
                        local addeditems = baginv:AddItems("Base.Bandage", SandboxVars.MoreTraits.PreparedMedicalBandageAmount);
                        for i = 0, addeditems:size() - 1 do
                            local item = baginv:getItems():get(i);
                            baginv:addItemOnServer(item);
                        end
                    else
                        local addeditems = baginv:AddItems("Base.Bandage", 4);
                        for i = 0, addeditems:size() - 1 do
                            local item = baginv:getItems():get(i);
                            baginv:addItemOnServer(item);
                        end
                    end
                    baginv:addItemOnServer(baginv:AddItem("Base.SutureNeedle"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Tissue"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Tweezers"));
                    break ;
                end
            end
        end
    end
    if player:HasTrait("preparedrepair") then
        inv:addItemOnServer(inv:AddItem("Base.Toolbox"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.Toolbox" then
                    player:setSecondaryHandItem(bag);
                    local baginv = bag:getInventory();
                    baginv:addItemOnServer(baginv:AddItem("Base.Hammer"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Screwdriver"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Saw"));
                    baginv:addItemOnServer(baginv:AddItem("Base.NailsBox"));
                    local addeditems = baginv:AddItems("Base.Garbagebag", 8);
                    for i = 0, addeditems:size() - 1 do
                        local item = baginv:getItems():get(i);
                        baginv:addItemOnServer(item);
                    end
                    break ;
                end
            end
        end
    end
    if player:HasTrait("preparedcamp") then
        inv:addItemOnServer(inv:AddItem("MoreTraits.Bag_SmallHikingBag"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "MoreTraits.Bag_SmallHikingBag" then
                    if player:getClothingItem_Back() == nil then
                        player:setClothingItem_Back(bag);
                    end
                    local baginv = bag:getInventory();
                    baginv:addItemOnServer(baginv:AddItem("Base.Matches"));
                    baginv:addItemOnServer(baginv:AddItem("camping.CampfireKit"));
                    baginv:addItemOnServer(baginv:AddItem("camping.CampingTentKit"));
                    baginv:addItemOnServer(baginv:AddItem("Base.BeefJerky"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Pop"));
                    baginv:addItemOnServer(baginv:AddItem("Base.FishingRod"));
                    baginv:addItemOnServer(baginv:AddItem("Base.FishingLine"));
                    baginv:addItemOnServer(baginv:AddItem("Base.FishingTackle"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Battery"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Torch"));
                    baginv:addItemOnServer(baginv:AddItem("Base.WaterBottleFull"));
                    break ;
                end
            end
        end
    end
    if player:HasTrait("preparedpack") then
        inv:addItemOnServer(inv:AddItem("Base.Bag_NormalHikingBag"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.Bag_NormalHikingBag" then
                    if player:getClothingItem_Back() == nil then
                        player:setClothingItem_Back(bag);
                    end
                    break ;
                end
            end
        end
    end

    if player:HasTrait("preparedcar") then
        inv:AddItem("Base.Bag_JanitorToolbox");
        if SandboxVars.MoreTraits.PreparedCarGasToggle == true then
            inv:addItemOnServer(inv:AddItem("Base.PetrolCan"));
        end

        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.Bag_JanitorToolbox" then
                    player:setPrimaryHandItem(bag);
                    local baginv = bag:getInventory();
                    baginv:addItemOnServer(baginv:AddItem("Base.CarBatteryCharger"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Screwdriver"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Wrench"));
                    baginv:addItemOnServer(baginv:AddItem("Base.LugWrench"));
                    baginv:addItemOnServer(baginv:AddItem("Base.TirePump"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Jack"));
                end
                if bag:getFullType() == "Base.PetrolCan" then
                    player:setSecondaryHandItem(bag);
                end
            end
        end
    end

    if player:HasTrait("preparedcoordination") then
        inv:addItemOnServer(inv:AddItem("Base.Bag_FannyPackFront"));
        inv:addItemOnServer(inv:AddItem("Base.WristWatch_Right_DigitalBlack"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.Bag_FannyPackFront" then
                    player:setWornItem("FannyPackFront", bag);
                    local baginv = bag:getInventory();
                    baginv:addItemOnServer(baginv:AddItem("Base.MuldraughMap"));
                    baginv:addItemOnServer(baginv:AddItem("Base.RosewoodMap"));
                    baginv:addItemOnServer(baginv:AddItem("Base.RiversideMap"));
                    baginv:addItemOnServer(baginv:AddItem("Base.WestpointMap"));
                    baginv:addItemOnServer(baginv:AddItem("Base.MarchRidgeMap"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Pencil"));
                    break ;
                end
            end
        end
    end

    if player:HasTrait("drinker") then
        if SandboxVars.MoreTraits.AlcoholicFreeDrink == true then
            inv:addItemOnServer(inv:AddItem("Base.WhiskeyFull"));
        end
    end
    if player:HasTrait("Tailor") then
        inv:addItemOnServer(inv:AddItem("Base.SewingKit"));
        for i = 0, inv:getItems():size() - 1 do
            local bag = inv:getItems():get(i);
            if bag ~= nil then
                if bag:getFullType() == "Base.SewingKit" then
                    local baginv = bag:getInventory();
                    baginv:addItemOnServer(baginv:AddItem("Base.Scissors"));
                    baginv:addItemOnServer(baginv:AddItem("Base.Needle"));
                    local addeditems = baginv:AddItems("Base.Thread", 4);
                    for i = 0, addeditems:size() - 1 do
                        local item = baginv:getItems():get(i);
                        baginv:addItemOnServer(item);
                    end
                    break ;
                end
            end
        end
    end
    if player:HasTrait("Smoker") then
        if SandboxVars.MoreTraits.SmokerStart == true then
            inv:addItemOnServer(inv:AddItem("Base.Cigarettes"));
            inv:addItemOnServer(inv:AddItem("Base.Lighter"));
        end
    end
    if player:HasTrait("deprived") then
        player:clearWornItems();
        inv:removeAllItems();
        player:createKeyRing();
        if SandboxVars.MoreTraits.ForgivingDeprived == true then
            inv:addItemOnServer(inv:AddItem("Base.Belt2"));
        end
    end
end

function initToadTraitsPerks(_player)
    local player = _player;
    local playerdata = player:getModData();
    local damage = 20;
    local bandagestrength = 5;
    local splintstrength = 0.9;
    local fracturetime = 50;
    local scratchtimemod = 20;
    local bleedtimemod = 10;
    if SandboxVars.MoreTraits.LuckImpact then
        luckimpact = SandboxVars.MoreTraits.LuckImpact * 0.01;
    end
    playerdata.secondwinddisabled = false;
    playerdata.secondwindcooldown = 0;
    playerdata.bToadTraitDepressed = false;
    playerdata.indefatigablecooldown = 0;
    playerdata.bindefatigable = false;
    playerdata.bSatedDrink = true;
    playerdata.iHoursSinceDrink = 0;
    playerdata.iTimesCannibal = 0;
    playerdata.fPreviousHealthFromFoodTimer = 1000;
    playerdata.bWasInfected = false;
    playerdata.iHardyInterval = 10;
    playerdata.iWithdrawalCooldown = 24;
    playerdata.iParanoiaCooldown = 10;

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
                    table.insert(BodyDamagedFromTrait, b);
                elseif injury == 2 then
                    if doburns == true then
                        b:AddDamage(damage);
                        b:setBurned();
                        b:setBurnTime(ZombRand(50) + damage);
                        b:setNeedBurnWash(false);
                        b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                        table.insert(BodyDamagedFromTrait, b);
                    else
                        itterations = itterations - 1;
                    end
                elseif injury == 3 then
                    b:AddDamage(damage);
                    b:setCut(true, true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                    table.insert(BodyDamagedFromTrait, b);
                elseif injury >= 4 then
                    b:AddDamage(damage);
                    b:setDeepWounded(true);
                    b:setStitched(true);
                    b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
                    table.insert(BodyDamagedFromTrait, b);
                end
            end
        end
        bodydamage:setInfected(false);
        bodydamage:setInfectionLevel(0);
    end
    if player:HasTrait("broke") then
        suspendevasive = true;
        local bodydamage = player:getBodyDamage();
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):AddDamage(damage);
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setFractureTime(fracturetime);
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setSplint(true, splintstrength);
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setSplintItem("Base.Splint");
        bodydamage:getBodyPart(BodyPartType.LowerLeg_R):setBandaged(true, bandagestrength, true, "Base.AlcoholBandage");
        bodydamage:setInfected(false);
        bodydamage:setInfectionLevel(0);
        table.insert(BodyDamagedFromTrait, bodydamage:getBodyPart(BodyPartType.LowerLeg_R));
    end
    if player:HasTrait("burned") then
        local bodydamage = player:getBodyDamage();
        for i = 0, bodydamage:getBodyParts():size() - 1 do
            local b = bodydamage:getBodyParts():get(i);
            b:setBurned();
            b:setBurnTime(ZombRand(10, 100) + damage);
            b:setNeedBurnWash(false);
            b:setBandaged(true, ZombRand(1, 10) + bandagestrength, true, "Base.AlcoholBandage");
            table.insert(BodyDamagedFromTrait, b); --i forgor to add in the thing for burned, but i think this should work fine
        end
    end
    playerdata.ToadTraitBodyDamage = nil;
    suspendevasive = false;
    player:getBodyDamage():Update();
    playerdata.fLastHP = nil;
    checkWeight();
    if player:HasTrait("ingenuitive") then
        LearnAllRecipes(player);
    end
end

function ToadTraitEvasive(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("evasive") then
        local basechance = 33;
        local bMarkForUpdate = false;
        local bodydamage = player:getBodyDamage();
        local modbodydamage = playerdata.ToadTraitBodyDamage;
        local lastinfected = playerdata.bisInfected;
        local enemies = player:getSpottedList();
        local nearbyzombies = false;
        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i);
            if enemy:isZombie() then
                local distance = enemy:DistTo(player)
                if distance <= 3 then
                    nearbyzombies = true;
                end
            end
        end
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
                            if ZombRand(100) <= basechance and nearbyzombies == true then
                                i:RestoreToFullHealth();
                                i:setScratched(false, false);
                                i:SetInfected(false);
                                if lastinfected == false and bodydamage:IsInfected() == true then
                                    bodydamage:setInfected(false);
                                    bodydamage:setInfectionLevel(0);
                                    print("Infection from Dodged Attack Removed");
                                end
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_dodgesay"), true, HaloTextHelper.getColorGreen());
                            else
                                bMarkForUpdate = true;
                            end
                        elseif i:bitten() == true and b[3] == false then
                            print("Bite Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance and nearbyzombies == true then
                                i:RestoreToFullHealth();
                                i:SetBitten(false, false);
                                i:SetInfected(false);
                                if lastinfected == false and bodydamage:IsInfected() == true then
                                    bodydamage:setInfected(false);
                                    bodydamage:setInfectionLevel(0);
                                    print("Infection from Dodged Attack Removed");
                                end
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_dodgesay"), true, HaloTextHelper.getColorGreen());
                            else
                                bMarkForUpdate = true;
                            end
                        elseif i:isCut() == true and b[4] == false then
                            print("Laceration Detected On: " .. tostring(i:getType()));
                            if ZombRand(100) <= basechance and nearbyzombies == true then
                                i:RestoreToFullHealth();
                                i:setCut(false, false);
                                i:SetInfected(false);
                                if lastinfected == false and bodydamage:IsInfected() == true then
                                    bodydamage:setInfected(false);
                                    bodydamage:setInfectionLevel(0);
                                    print("Infection from Dodged Attack Removed");
                                end
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_dodgesay"), true, HaloTextHelper.getColorGreen());
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

function ToadTraitButter(_player)
    local player = _player;
    if player:HasTrait("butterfingers") and player:isPlayerMoving() then
        local basechance = 3;
        local chanceinx = 2000;
        if SandboxVars.MoreTraits.ButterfingersChance then
            chanceinx = SandboxVars.MoreTraits.ButterfingersChance;
        end
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
        if player:isSprinting() == true then
            chancemod = chancemod + 10;
        elseif player:IsRunning() == true then
            chancemod = chancemod + 5;
        end
        local chance = (basechance + chancemod);
        if chance >= ZombRand(chanceinx) then
            if player:getSecondaryHandItem() ~= nil or player:getPrimaryHandItem() ~= nil then
                player:dropHandItems();
                HaloTextHelper.addTextWithArrow(player, getText("UI_butterfingers_triggered"), false, HaloTextHelper.getColorRed());
            end
        end
    end
end

function ToadTraitParanoia(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("paranoia") then
        if playerdata.iParanoiaCooldown == nil then
            playerdata.iParanoiaCooldown = 0;
        end
        if playerdata.iParanoiaCooldown <= 0 then
            if player:isPlayerMoving() == true then
                local basechance = 1;
                local randNum = ZombRand(100) + 1;
                local stats = player:getStats();
                local panic = stats:getPanic();
                local stress = stats:getStress();
                randNum = randNum - (randNum * stats:getStress());
                if randNum <= basechance then
                    getSoundManager():PlaySound("ZombieSurprisedPlayer", false, 0):setVolume(0.05);
                    panic = panic + 25;
                    stress = stress + 0.1;
                    stats:setPanic(panic);
                    stats:setStress(stress);
                    playerdata.iParanoiaCooldown = 30;
                    if player:isFemale() then
                        getSoundManager():PlaySound("female_heavybreathpanic", false, 5):setVolume(0.025);
                    else
                        getSoundManager():PlaySound("male_heavybreathpanic", false, 5):setVolume(0.025);
                    end
                end
            end
        else
            playerdata.iParanoiaCooldown = playerdata.iParanoiaCooldown - 1;
        end
    end
end

function ToadTraitScrounger(_iSInventoryPage, _state, _player)
    local player = _player;
    local playerData = player:getModData();
    local containerObj;
    local container;
    if player:HasTrait("scrounger") then
        local basechance = 20;
        local modifier = 1.3;
        if SandboxVars.MoreTraits.ScroungerChance then
            basechance = SandboxVars.MoreTraits.ScroungerChance;
        end
        if SandboxVars.MoreTraits.ScroungerLootModifier then
            modifier = 1.0 + SandboxVars.MoreTraits.ScroungerLootModifier * 0.01;
        end
        if player:HasTrait("Lucky") then
            basechance = basechance + 5 * luckimpact;
            modifier = modifier + 0.1 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 5 * luckimpact;
            modifier = modifier - 0.1 * luckimpact;
        end
        for i, v in ipairs(_iSInventoryPage.backpacks) do
            if v.inventory:getParent() then
                containerObj = v.inventory:getParent();
                if not containerObj:getModData().bScroungerorIncomprehensiveRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                    containerObj:getModData().bScroungerorIncomprehensiveRolled = true;
                    containerObj:transmitModData();
                    if ZombRand(100) <= basechance then
                        local tempcontainer = {};
                        container = containerObj:getContainer();
                        if container:getItems() then
                            for i = 0, container:getItems():size() - 1 do
                                local item = container:getItems():get(i);
                                if item ~= nil then
                                    if tableContains(tempcontainer, item:getFullType()) == false then
                                        table.insert(tempcontainer, item:getFullType());
                                        local count = container:getNumberOfItem(item:getFullType());
                                        local n = 1;
                                        local rolled = false;
                                        --Add a Special Case for Cigarettes since they inherently create 20 when added.
                                        if item:getFullType() == "Base.Cigarettes" then
                                            count = math.floor(count / 20);
                                        end
                                        local bchance = 10;
                                        if SandboxVars.MoreTraits.ScroungerItemChance then
                                            bchance = SandboxVars.MoreTraits.ScroungerItemChance;
                                        end
                                        if player:HasTrait("Lucky") then
                                            bchance = bchance + 5 * luckimpact;
                                        end
                                        if player:HasTrait("Unlucky") then
                                            bchance = bchance - 5 * luckimpact;
                                        end
                                        if item:getCategory() == "Food" then
                                            bchance = bchance + 10;
                                        end
                                        if item:IsDrainable() then
                                            bchance = bchance + 10;
                                        end
                                        if item:IsWeapon() then
                                            bchance = bchance + 5;
                                        end
                                        if count == 1 then
                                            if ZombRand(100) <= bchance then
                                                rolled = true;
                                            end
                                        elseif count > 1 and count < 5 then
                                            n = math.floor(count * modifier);
                                            rolled = true;
                                        elseif count >= 5 then
                                            n = math.floor((count * modifier) * 2)
                                            rolled = true;
                                        end
                                        if rolled then
                                            local addeditems = container:AddItems(item:getFullType(), n);
                                            for i = 0, addeditems:size() - 1 do
                                                local item = container:getItems():get(i);
                                                container:addItemOnServer(item);
                                            end
                                            if MoreTraits.settings.ScroungerAnnounce == true then
                                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrounger") .. " : " .. item:getName(), true, HaloTextHelper.getColorGreen());
                                            end
                                            if MoreTraits.settings.ScroungerHighlight == true then
                                                if not playerData.scroungerHighlightsTbl then
                                                    playerData.scroungerHighlightsTbl = {}
                                                end
                                                playerData.scroungerHighlightsTbl[containerObj] = 0;
                                                containerObj:setHighlighted(true, false);
                                                containerObj:setHighlightColor(0.5, 1, 0.4, 1);
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function UnHighlightScrounger(_player, _playerdata)
    if MoreTraits.settings.ScroungerHighlight == true then
        local maxTime = MoreTraits.settings.ScroungerHighlightTime;
        local player = _player;
        local playerData = _playerdata;
        if not playerData.scroungerHighlightsTbl then
            playerData.scroungerHighlightsTbl = {}
        end
        local scroungerHighlightsTbl = playerData.scroungerHighlightsTbl;
        if scroungerHighlightsTbl ~= {} then
            if player:HasTrait("scrounger") then
                for containerObj, timer in pairs(scroungerHighlightsTbl) do
                    if timer >= maxTime then
                        containerObj:setHighlighted(false);
                        -- print("container removed from table!");
                        scroungerHighlightsTbl[containerObj] = nil;
                    else
                        scroungerHighlightsTbl[containerObj] = timer + 1;
                    end
                end
            end
        end
    end
end

function ToadTraitIncomprehensive(_iSInventoryPage, _state, _player)
    local player = _player;
    local containerObj;
    local container;
    if player:HasTrait("incomprehensive") then
        local basechance = 10;
        if SandboxVars.MoreTraits.IncomprehensiveChance then
            basechance = SandboxVars.MoreTraits.IncomprehensiveChance;
        end
        if player:HasTrait("Lucky") then
            basechance = basechance - 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 5 * luckimpact;
        end
        for i, v in ipairs(_iSInventoryPage.backpacks) do
            local tempcontainer = {};
            if v.inventory:getParent() then
                containerObj = v.inventory:getParent();
                if not containerObj:getModData().bScroungerorIncomprehensiveRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                    containerObj:getModData().bScroungerorIncomprehensiveRolled = true;
                    containerObj:transmitModData();
                    container = containerObj:getContainer();
                    if ZombRand(100) <= basechance then
                        for i = 0, container:getItems():size() - 1 do
                            local item = container:getItems():get(i);
                            if item ~= nil then
                                if tableContains(tempcontainer, item) == false then
                                    local count = container:getNumberOfItem(item:getFullType());
                                    --Add a Special Case for Cigarettes since they inherently create 20 when added.
                                    if item:getFullType() == "Base.Cigarettes" then
                                        count = math.floor(count / 20);
                                    end
                                    if count == 1 then
                                        local bchance = 5;
                                        if player:HasTrait("Lucky") then
                                            bchance = bchance - 5 * luckimpact;
                                        end
                                        if player:HasTrait("Unlucky") then
                                            bchance = bchance + 5 * luckimpact;
                                        end
                                        if item:IsFood() then
                                            bchance = bchance + 10;
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
                    end
                    if tempcontainer ~= {} then
                        for _, i in pairs(tempcontainer) do
                            container:Remove(i);
                            container:removeItemOnServer(i);
                            if MoreTraits.settings.ScroungerAnnounce == true then
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_incomprehensive") .. " : " .. i:getName(), false, HaloTextHelper.getColorRed());
                            end
                        end
                    end
                end
            end
        end
    end
end

function ToadTraitAntique(_iSInventoryPage, _state, _player)
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
    table.insert(items, "MoreTraits.AntiqueSpear");
    table.insert(items, "MoreTraits.AntiqueHammer");
    table.insert(items, "MoreTraits.AntiqueKatana");

    local length = 0
    for k, v in pairs(items) do
        length = length + 1;
    end
    local player = _player;
    local containerObj;
    local container;
    if player:HasTrait("antique") then
        local basechance = 10;
        local roll = 1000;
        if player:HasTrait("Lucky") then
            basechance = basechance + 1 * luckimpact;
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
        if SandboxVars.MoreTraits.AntiqueChance then
            roll = SandboxVars.MoreTraits.AntiqueChance;
        end
        for j, v in ipairs(_iSInventoryPage.backpacks) do
            if v.inventory:getParent() then
                containerObj = v.inventory:getParent();
                if not containerObj:getModData().bAntiqueRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                    containerObj:getModData().bAntiqueRolled = true;
                    containerObj:transmitModData();
                    container = containerObj:getContainer();
                    if ZombRand(roll) <= basechance then
                        local i = ZombRand(length);
                        if i == 0 then
                            i = 1;
                        end
                        container:addItemOnServer(container:AddItem(items[i]));
                    end
                end
            end
        end
    end
end

function ToadTraitVagabond(_iSInventoryPage, _state, _player)
    local items = {};
    table.insert(items, "Base.BreadSlices");
    table.insert(items, "Base.Pizza");
    table.insert(items, "Base.Hotdog");
    table.insert(items, "Base.Corndog");
    table.insert(items, "Base.OpenBeans");
    table.insert(items, "Base.CannedChiliOpen");
    table.insert(items, "Base.WatermelonSmashed");
    table.insert(items, "Base.DogfoodOpen");
    table.insert(items, "Base.CannedCornedBeefOpen");
    table.insert(items, "Base.CannedBologneseOpen");
    table.insert(items, "Base.CannedCarrotsOpen");
    table.insert(items, "Base.CannedCornOpen");
    table.insert(items, "Base.CannedMushroomSoupOpen");
    table.insert(items, "Base.CannedPeasOpen");
    table.insert(items, "Base.CannedPotatoOpen");
    table.insert(items, "Base.CannedSardinesOpen");
    table.insert(items, "Base.CannedTomatoOpen");
    table.insert(items, "Base.TinnedSoupOpen");
    table.insert(items, "Base.TunaTinOpen");
    table.insert(items, "Base.CannedFruitCocktailOpen");
    table.insert(items, "Base.CannedPeachesOpen");
    table.insert(items, "Base.CannedPineappleOpen");
    table.insert(items, "Base.MushroomGeneric1");
    table.insert(items, "Base.MushroomGeneric2");
    table.insert(items, "Base.MushroomGeneric3");
    table.insert(items, "Base.MushroomGeneric4");
    table.insert(items, "Base.MushroomGeneric5");
    table.insert(items, "Base.MushroomGeneric6");
    table.insert(items, "Base.MushroomGeneric7");

    local length = 0
    for k, v in pairs(items) do
        length = length + 1;
    end
    local player = _player;
    local containerObj;
    local container;
    if player:HasTrait("vagabond") then
        local basechance = 33;
        if SandboxVars.MoreTraits.VagabondChance then
            basechance = SandboxVars.MoreTraits.VagabondChance;
        end
        if player:HasTrait("Lucky") then
            basechance = basechance + 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 5 * luckimpact;
        end
        for i, v in ipairs(_iSInventoryPage.backpacks) do
            if v.inventory:getParent() then
                containerObj = v.inventory:getParent();
                if not containerObj:getModData().bVagbondRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                    containerObj:getModData().bVagbondRolled = true;
                    containerObj:transmitModData();
                    container = containerObj:getContainer();
                    if container:getType() == ("bin") then
                        local extra = 1;
                        if SandboxVars.MoreTraits.VagabondGuaranteedExtraLoot then
                            extra = SandboxVars.MoreTraits.VagabondGuaranteedExtraLoot;
                        end
                        local itterations = ZombRand(0, 2) + extra;
                        for itt = 0, itterations do
                            itt = itt + 1;
                            local x = ZombRand(length);
                            if x == 0 then
                                x = 1;
                            end
                            if ZombRand(100) <= basechance then
                                container:addItemOnServer(container:AddItem(items[x]));
                                if MoreTraits.settings.VagabondAnnounce == true then
                                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_vagabond") .. " : " .. item:getName(), true, HaloTextHelper.getColorGreen());
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function ToadTraitDepressive()
    local player = getPlayer();
    if player:HasTrait("depressive") then
        local basechance = 2;
        if player:HasTrait("Lucky") then
            basechance = basechance - 1 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance + 1 * luckimpact;
        end
        if player:HasTrait("Brooding") then
            basechance = basechance + 1;
        end
        if player:HasTrait("selfdestructive") then
            basechance = basechance + 1;
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

function CheckDepress(_player, _playerdata)
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

function CheckSelfHarm(_player)
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

function Blissful(_player)
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

function Specialization(_player, _perk, _amount)
    local player = _player;
    local perk = _perk;
    local amount = _amount;
    local newamount = 0;
    local skip = false;
    local modifier = 75;
    local perklvl = player:getPerkLevel(_perk);
    local perkxpmod = 1;
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
                if perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Maintenance or perk == Perks.SmallBlunt or perk == Perks.Spear then
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
                if perklvl == 0 and testxp <= 0 then
                    skip = true;
                elseif perklvl == 1 and testxp <= 75 then
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
                local xpforlevel = perk:getXpForLevel(perklvl) + 50;
                while player:getXp():getXP(perk) > correctamount do
                    local curxp = player:getXp():getXP(perk);
                    if xpforlevel >= curxp then
                        break ;
                    else
                        if MTVersion:getMajor() >= 41 and MTVersion:getMinor() >= 66 then
                            player:getXp():AddXP(perk, -1 * 0.1, false, false, false);
                        else
                            player:getXp():AddXP(perk, -1 * 0.1, false, false);
                        end
                    end
                end
            end
        end
    else
        skipxpadd = false;
    end
end

function Gordanite(_player)
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

function indefatigable(_player, _playerdata)
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
                    if tableContains(BodyDamagedFromTrait, b) == false then
                        b:RestoreToFullHealth();
                    end
                end
                player:getBodyDamage():setOverallBodyHealth(100);
                playerdata.bindefatigable = true;
                playerdata.indefatigablecooldown = 0;
                if enemies:size() > 2 then
                    for i = 0, enemies:size() - 1 do
                        if enemies:get(i):isZombie() then
                            if enemies:get(i):DistTo(player) <= 2.5 then
                                enemies:get(i):setStaggerBack(true);
				enemies:get(i):setKnockedDown(true);
                            end
                        end
                    end
                end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen());
                --player:Say(getText("UI_trait_indefatigable"));
            end
        end
    end
end

function indefatigablecounter()
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

function badteethtrait(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local healthtimer = player:getBodyDamage():getHealthFromFoodTimer();
    if player:HasTrait("badteeth") then
        if healthtimer > 1000 then
            if playerdata.fPreviousHealthFromFoodTimer == nil then
                playerdata.fPreviousHealthFromFoodTimer = 1000;
            end
            if healthtimer > playerdata.fPreviousHealthFromFoodTimer then
                local Head = player:getBodyDamage():getBodyPart(BodyPartType.FromString("Head"));
                local pain = (healthtimer - playerdata.fPreviousHealthFromFoodTimer) * 0.01;
                Head:setAdditionalPain(Head:getAdditionalPain() + pain);
                if Head:getAdditionalPain() >= 100 then
                    Head:setAdditionalPain(100);
                end
            end
            playerdata.fPreviousHealthFromFoodTimer = healthtimer;
        end
    end
end

function hardytrait(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local stats = player:getStats();
    if player:HasTrait("hardy") then
        local endurance = stats:getEndurance();
        local regenerationrate = 0.01;
        if playerdata.iHardyInterval == nil then
            playerdata.iHardyInterval = 0;
        end
        local interval = playerdata.iHardyInterval;
        if SandboxVars.MoreTraits.HardyRegeneration then
            regenerationrate = regenerationrate * (SandboxVars.MoreTraits.HardyRegeneration * 0.01);
        end
        if interval <= 0 then
            stats:setEndurance(endurance + regenerationrate);
            playerdata.iHardyInterval = 1000;
        else
            if player:isSprinting() == true then
                playerdata.iHardyInterval = interval - 2;
            elseif player:IsRunning() == true then
                playerdata.iHardyInterval = interval - 5;
            elseif player:getCurrentState() == FitnessState.instance() then
                playerdata.iHardyInterval = interval - 10;
            elseif player:isSitOnGround() == true then
                playerdata.iHardyInterval = interval - 50;
            else
                playerdata.iHardyInterval = interval - 20;
            end
        end
    end
end

function drinkerupdate(_player, _playerdata)
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
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicsatisfied"), true, HaloTextHelper.getColorGreen());
            end
            playerdata.iHoursSinceDrink = 0;
            stats:setAnger(0);
            stats:setStress(0);
        end
        if drunkness > 0 then
            if internalTick >= 25 then
                stats:setFatigue(stats:getFatigue() - 0.001);
            end
        end
        if playerdata.bSatedDrink == false then
            if playerdata.iHoursSinceDrink > hoursthreshold then
                stats:setPain(playerdata.iHoursSinceDrink / divider);
            end
            if internalTick >= 29 then
                stats:setAnger(anger + 0.001);
                stats:setStress(stress + 0.001);
            end
        end
    end
end

function drinkertick()
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
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicneed"), false, HaloTextHelper.getColorRed());
                end
            end
        end
    end
end

function drinkerpoison()
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
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicwithdrawal"), false, HaloTextHelper.getColorRed());
            if SandboxVars.MoreTraits.NonlethalAlcoholic == true then
                player:getBodyDamage():setPoisonLevel(20);
            else
                player:getBodyDamage():setPoisonLevel((playerdata.iHoursSinceDrink / divider));
            end
            playerdata.iWithdrawalCooldown = ZombRand(12, 24);
        end
        playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown - 1;
    end
end

function bouncerupdate(_player, _playerdata)
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
                                if ZombRand(0, 101) <= chance and enemy:isKnockedDown() == false then
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

function martial(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local playerdata = player:getModData();
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
        local scaling = 1.0;
        if SandboxVars.MoreTraits.MartialScaling then
            scaling = SandboxVars.MoreTraits.MartialScaling * 0.01;
        end
        local SmallBluntLvl = player:getPerkLevel(Perks.SmallBlunt);
        local StrengthLvl = player:getPerkLevel(Perks.Strength);
        local Fitnesslvl = player:getPerkLevel(Perks.Fitness);
        local average = ((StrengthLvl + Fitnesslvl) * 0.25);
        local minimumdmg = (0.1 * average + SmallBluntLvl * 0.1) * scaling;
        local maximumdmg = (0.25 * average + SmallBluntLvl * 0.1) * scaling;
        critchance = (critchance + SmallBluntLvl) * scaling;
        local allow = true;
        if SandboxVars.MoreTraits.MartialWeapons == false then
            if player:getPrimaryHandItem() ~= nil then
                allow = false;
            end
        end
        if weapon:getType() == "BareHands" and allow == true then
            if playerdata.itemWeaponBareHands == nil then
                playerdata.itemWeaponBareHands = weapon;
            end
            playerdata.itemWeaponBareHands:setDoorDamage(9 + maximumdmg);
            playerdata.itemWeaponBareHands:setTreeDamage(1 + maximumdmg);
            playerdata.itemWeaponBareHands:getCategories():set(0, "SmallBlunt");
            playerdata.itemWeaponBareHands:setMinDamage(minimumdmg);
            playerdata.itemWeaponBareHands:setMaxDamage(maximumdmg);
            playerdata.itemWeaponBareHands:setCriticalChance(critchance);
            if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
                damage = damage * 4;
            end
            damage = damage * 0.1;
            if MoreTraits.settings.MartialDamage == true then
                HaloTextHelper.addText(player, "Damage: " .. tostring(round(damage, 3)), HaloTextHelper.getColorGreen());
            end
            _target:setHealth(_target:getHealth() - damage);
            if _target:getHealth() <= 0 then
                _target:update();
            end
        else
            if playerdata.itemWeaponBareHands ~= nil then
                playerdata.itemWeaponBareHands:setDoorDamage(1);
                playerdata.itemWeaponBareHands:setTreeDamage(1);
                playerdata.itemWeaponBareHands:getCategories():set(0, "SmallBlunt");
                playerdata.itemWeaponBareHands:setMinDamage(0.1);
                playerdata.itemWeaponBareHands:setMaxDamage(0.2);
                playerdata.itemWeaponBareHands:setCriticalChance(1);
            end
        end
    end
end

function problunt(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
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
            if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
                damage = damage * 2;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if weapondata.iLastWeaponCond == nil then
                weapondata.iLastWeaponCond = weapon:getCondition();
            end
            if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1);
                end
            end
            weapondata.iLastWeaponCond = weapon:getCondition();
        end
    end
end

function problade(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
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
            if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
                damage = damage * 2;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if weapondata.iLastWeaponCond == nil then
                weapondata.iLastWeaponCond = weapon:getCondition();
            end
            if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1);
                end
            end
            weapondata.iLastWeaponCond = weapon:getCondition();
        end
    end
end

function progun(_actor, _weapon)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
    local maxCapacity = weapon:getMaxAmmo();
    local currentCapacity = weapon:getCurrentAmmoCount();
    local chance = 10 + player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading);
    if _actor == player and player:HasTrait("progun") and weapon:getSubCategory() == "Firearm" then
        if player:HasTrait("Lucky") then
            chance = chance + 5 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 5 * luckimpact;
        end

        if weapondata.iLastWeaponCond == nil then
            weapondata.iLastWeaponCond = weapon:getCondition();
        end
        if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
            if weapon:getCondition() < weapon:getConditionMax() then
                weapon:setCondition(weapon:getCondition() + 1);
            end
        end
        weapondata.iLastWeaponCond = weapon:getCondition();
        if ZombRand(0, 101) <= chance then
            if currentCapacity < maxCapacity and currentCapacity > 0 then
                weapon:setCurrentAmmoCount(currentCapacity + 1);
            end
        end
    end
end

function prospear(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
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
            if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
                damage = damage * 2;
            end
            _target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if weapondata.iLastWeaponCond == nil then
                weapondata.iLastWeaponCond = weapon:getCondition();
            end
            if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1);
                end
            end
            weapondata.iLastWeaponCond = weapon:getCondition();
        end
    end
end

function tavernbrawler(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
    local chance = 50;
    local whitelist = { "ToolWeapon", "WeaponCrafted", "Cooking", "Household", "FirstAid", "Gardening", "Sports" };
    local damage = _damage;
    local multiplier = 1;
    if _actor == player and player:HasTrait("tavernbrawler") then
        if tableContains(whitelist, weapon:getDisplayCategory()) == true or weapon:getCategories():contains("Improvised") then
            if weapon:getCategories():contains("Spear") then
                chance = 0;
                multiplier = 0.25;
            end
            if player:HasTrait("Lucky") then
                chance = chance + 5 * luckimpact;
                multiplier = multiplier + 0.1;
            end
            if player:HasTrait("Unlucky") then
                chance = chance - 5 * luckimpact;
                multiplier = multiplier - 0.1;
            end
            if weapon:getConditionLowerChance() <= 2 then
                chance = chance + 25;
                multiplier = multiplier + 0.5;
            end
            if weapon:getConditionMax() <= 5 then
                chance = chance + 25;
                multiplier = multiplier + 0.5;
            end
            if chance >= 100 then
                chance = 95;
            end
            _target:setHealth(_target:getHealth() - (damage * multiplier) * 0.1);
            if _target:getHealth() <= 0 and _target:isAlive() then
                _target:update();
            end
            if weapondata.iLastWeaponCond == nil then
                weapondata.iLastWeaponCond = weapon:getCondition();
            end
            if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= chance then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1);
                end
            end
            weapondata.iLastWeaponCond = weapon:getCondition();
        end
    end
end

function albino(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("albino") then
        local time = getGameTime();
        if playerdata.bisAlbinoOutside == nil then
            playerdata.bisAlbinoOutside = false;
        end
        if player:isOutside() then
            local tod = time:getTimeOfDay();
            if tod > 10 and tod < 16 then
                local stats = player:getStats();
                local pain = stats:getPain();
                if pain < 25 then
                    if playerdata.bisAlbinoOutside == false then
                        if MoreTraits.settings.AlbinoAnnounce == true then
                            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_albino"), false, HaloTextHelper.getColorRed());
                        end
                        playerdata.bisAlbinoOutside = true;
                    end
                    stats:setPain(20);
                end
            end
        else
            playerdata.bisAlbinoOutside = false;
        end
    end
end

function amputee(_player, justGotInfected)
    local player = _player;
    local bodydamage = player:getBodyDamage();
    if player:HasTrait("amputee") then
        if getActivatedMods():contains("Amputation") == true then
            --Failsafe just in case Amputee shares its name with the trait from Amputation mod.
            return ;
        end
        local handitem = player:getSecondaryHandItem();
        local bodydamage = player:getBodyDamage();
        if handitem ~= nil then
            if handitem:getType() ~= "BareHands" then
                player:dropHandItems();
            end
        end
        local UpperArm_L = bodydamage:getBodyPart(BodyPartType.FromString("UpperArm_L"));
        local ForeArm_L = bodydamage:getBodyPart(BodyPartType.FromString("ForeArm_L"));
        local Hand_L = bodydamage:getBodyPart(BodyPartType.FromString("Hand_L"));
        if UpperArm_L:HasInjury() then
            UpperArm_L:RestoreToFullHealth();
            if justGotInfected then
                bodydamage:setInfected(false);
                bodydamage:setInfectionMortalityDuration(-1);
                bodydamage:setInfectionTime(-1);
                bodydamage:setInfectionLevel(0);
            end
        end
        if ForeArm_L:HasInjury() then
            ForeArm_L:RestoreToFullHealth();
            if justGotInfected then
                bodydamage:setInfected(false);
                bodydamage:setInfectionMortalityDuration(-1);
                bodydamage:setInfectionTime(-1);
                bodydamage:setInfectionLevel(0);
            end
        end
        if Hand_L:HasInjury() then
            Hand_L:RestoreToFullHealth();
            if justGotInfected then
                bodydamage:setInfected(false);
                bodydamage:setInfectionMortalityDuration(-1);
                bodydamage:setInfectionTime(-1);
                bodydamage:setInfectionLevel(0);
            end
        end
    end
end

function actionhero(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local critchance = 10;
    local damage = _damage * 0.5;
    local enemies = player:getSpottedList();
    local multiplier = 0.1;
    if _actor == player and player:HasTrait("actionhero") then
        if player:HasTrait("martial") == false and weapon:getType() == "BareHands" then
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
        if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
            damage = damage * 5;
        end
        _target:setHealth(_target:getHealth() - (damage * multiplier) * 0.1);
        if _target:getHealth() <= 0 then
            _target:update();
        end
    end
end

function gimp()
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

function fast()
    local player = getPlayer();
    local playerdata = player:getModData();
    local vector = player:getMoveForwardVec();
    local length = vector:getLength();
    local modifier = 2.15;
    if player:HasTrait("fast") then
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
function anemic(_player)
    local player = _player;
    if player:HasTrait("anemic") then
        local bodydamage = player:getBodyDamage();
        local bleeding = bodydamage:getNumPartsBleeding();
        if bleeding > 0 then
            for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                local b = player:getBodyDamage():getBodyParts():get(i);
                if b:bleeding() and b:IsBleedingStemmed() == false then
                    local adjust = 0.1;
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_anemic"), false, HaloTextHelper.getColorRed());
                    if b:getType() == BodyPartType.Neck then
                        adjust = adjust * 2;
                    end
                    b:ReduceHealth(adjust);
                end
            end
        end

    end
end
function thickblood(_player)
    local player = _player;
    if player:HasTrait("thickblood") then
        local bodydamage = player:getBodyDamage();
        local bleeding = bodydamage:getNumPartsBleeding();
        if bleeding > 0 then
            for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                local b = player:getBodyDamage():getBodyParts():get(i);
                if b:bleeding() and b:IsBleedingStemmed() == false then
                    local adjust = 0.002;
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickblood"), true, HaloTextHelper.getColorGreen());
                    if b:getType() == BodyPartType.Neck then
                        adjust = adjust * 2;
                    end
                    b:AddHealth(adjust);
                end
            end
        end

    end
end

function vehicleCheck(_player)
    local player = _player;
    if getActivatedMods():contains("DrivingSkill") == true then
        --skip processing if Driving Skill mod is installed.
        return ;
    end
    if player:isDriving() == true then
        local vehicle = player:getVehicle();
        local vmd = vehicle:getModData();
        if vmd.fRegulatorSpeed == nil then
            vmd.bUpdated = nil;
        end
        if vmd.bUpdated == nil then
            vmd.fBrakingForce = vehicle:getBrakingForce();
            vmd.fMaxSpeed = vehicle:getMaxSpeed();
            vmd.iEngineQuality = vehicle:getEngineQuality();
            vmd.iEngineLoudness = vehicle:getEngineLoudness()
            vmd.iEnginePower = vehicle:getEnginePower();
            vmd.iMass = vehicle:getMass();
            vmd.iInitialMass = vehicle:getInitialMass();
            vmd.fOffRoadEfficiency = vehicle:getScript():getOffroadEfficiency();
            vmd.fRegulatorSpeed = vehicle:getRegulatorSpeed();
            vmd.sState = "Normal";
            vmd.bUpdated = true;
        else
            if player:HasTrait("expertdriver") and vmd.sState ~= "ExpertDriver" then
                vehicle:setBrakingForce(vmd.fBrakingForce * 2);
                vehicle:setEngineFeature(vmd.iEngineQuality * 2, vmd.iEngineLoudness * 0.25, vmd.iEnginePower * 3);
                vehicle:setMaxSpeed(vmd.fMaxSpeed * 1.25);
                vehicle:setMass(vmd.iMass * 0.5);
                vehicle:setInitialMass(vmd.iInitialMass * 0.5);
                vehicle:updateTotalMass();
                vehicle:getScript():setOffroadEfficiency(vmd.fOffRoadEfficiency * 2);
                vehicle:setRegulatorSpeed(vmd.fRegulatorSpeed * 2);
                vmd.sState = "ExpertDriver";
                print("Vehicle State: " .. vmd.sState);
                vehicle:update();
            end
            if player:HasTrait("poordriver") and vmd.sState ~= "PoorDriver" then
                vehicle:setBrakingForce(vmd.fBrakingForce * 0.5);
                vehicle:setEngineFeature(vmd.iEngineQuality * 0.5, vmd.iEngineLoudness * 1.5, vmd.iEnginePower * 0.66);
                vehicle:setMaxSpeed(vmd.fMaxSpeed * 0.75);
                vehicle:setMass(vmd.iMass * 1.33);
                vehicle:setInitialMass(vmd.iInitialMass * 1.33);
                vehicle:updateTotalMass();
                vehicle:getScript():setOffroadEfficiency(vmd.fOffRoadEfficiency * 0.5);
                vehicle:setRegulatorSpeed(vmd.fRegulatorSpeed * 0.66);
                vmd.sState = "PoorDriver";
                print("Vehicle State: " .. vmd.sState);
                vehicle:update();
            end
            if player:HasTrait("expertdriver") == false and player:HasTrait("poordriver") == false and vmd.sState ~= "Normal" then
                vehicle:setBrakingForce(vmd.fBrakingForce);
                vehicle:setEngineFeature(vmd.iEngineQuality, vmd.iEngineLoudness, vmd.iEnginePower);
                vehicle:setMaxSpeed(vmd.fMaxSpeed);
                vehicle:setMass(vmd.iMass);
                vehicle:setInitialMass(vmd.iInitialMass);
                vehicle:updateTotalMass();
                vehicle:getScript():setOffroadEfficiency(vmd.fOffRoadEfficiency);
                vehicle:setRegulatorSpeed(vmd.fRegulatorSpeed);
                vmd.sState = "Normal";
                print("Vehicle State: " .. vmd.sState);
                vehicle:update();
            end

        end

    end
end

function SuperImmune(_player, _playerdata)
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
                        bodydamage:setInfectionMortalityDuration(-1);
                        bodydamage:setInfectionTime(-1);
                        bodydamage:setInfectionLevel(0);
                        if MoreTraits.settings.SuperImmuneAnnounce == true then
                            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_superimmune"), true, HaloTextHelper.getColorGreen());
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
                    b:SetInfected(false);
                    b:setInfectedWound(false);
                end
            end
        end
    end
end

function Immunocompromised(_player, _playerdata)
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
    local muleMaxWeightbonus = math.floor(mule + strength / 5 + globalmod);
    local mouseMaxWeightbonus = math.floor(mouse + globalmod);
    local defaultMaxWeightbonus = math.floor(default + globalmod);
    if player:HasTrait("packmule") then
        player:setMaxWeightBase(muleMaxWeightbonus);
    elseif player:HasTrait("packmouse") then
        player:setMaxWeightBase(mouseMaxWeightbonus);
    else
        player:setMaxWeightBase(defaultMaxWeightbonus)
        ;
    end
end

function graveRobber(_zombie)
    local player = getPlayer();
    local zombie = _zombie;
    local chance = 10;
    local extraloot = 1;
    if SandboxVars.MoreTraits.GraveRobberChance then
        chance = SandboxVars.MoreTraits.GraveRobberChance;
    end
    if SandboxVars.MoreTraits.GraveRobberGuaranteedLoot then
        extraloot = SandboxVars.MoreTraits.GraveRobberGuaranteedLoot;
    end
    if player:HasTrait("graverobber") and zombie:DistTo(player) <= 12 then
        if player:HasTrait("Lucky") then
            chance = chance + 2 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            chance = chance - 2 * luckimpact;
        end
        if player:HasTrait("scrounger") then
            chance = chance + 2;
        end
        if player:HasTrait("incomprehensive") then
            chance = chance - 2;
        end
        if chance <= 0 then
            chance = 1;
        end
        if ZombRand(0, 1001) <= chance then
            if MoreTraits.settings.GraveRobberAnnounce == true then
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen());
            end
            local inv = zombie:getInventory();
            local itterations = ZombRand(0, 3);
            itterations = itterations + extraloot;
            for i = 0, itterations do
                i = i + 1;
                local roll = ZombRand(0, 101);
                if roll <= 10 then
                    local randomitem = { "Base.Apple", "Base.Avocado", "Base.Banana", "Base.BellPepper", "Base.BeerCan",
                                         "Base.BeefJerky", "Base.Bread", "Base.Broccoli", "Base.Butter", "Base.CandyPackage", "Base.TinnedBeans",
                                         "Base.CannedCarrots2", "Base.CannedChili", "Base.CannedCorn", "Base.CannedCornedBeef", "CannedMushroomSoup",
                                         "Base.CannedPeas", "Base.CannedPotato2", "Base.CannedSardines", "Base.CannedTomato2", "Base.TunaTin" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 20 then
                    local randomitem = { "Base.PillsAntiDep", "Base.AlcoholWipes", "Base.AlcoholedCottonBalls", "Base.Pills", "Base.PillsSleepingTablets",
                                         "Base.Tissue", "Base.ToiletPaper", "Base.PillsVitamins", "Base.Bandaid", "Base.Bandage", "Base.CottonBalls", "Base.Splint", "Base.AlcoholBandage",
                                         "Base.AlcoholRippedSheets", "Base.SutureNeedle", "Base.Tweezers", "Base.WildGarlicCataplasm", "Base.ComfreyCataplasm", "Base.PlantainCataplasm", "Base.Disinfectant" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 30 then
                    local randomitem = { "Base.223Box", "Base.308Box", "Base.Bullets38Box", "Base.Bullets44Box", "Base.Bullets45Box", "Base.556Box", "Base.Bullets9mmBox",
                                         "Base.ShotgunShellsBox", "Base.DoubleBarrelShotgun", "Base.Shotgun", "Base.ShotgunSawnoff", "Base.Pistol", "Base.Pistol2", "Base.Pistol3", "Base.AssaultRifle", "Base.AssaultRifle2",
                                         "Base.VarmintRifle", "Base.HuntingRifle", "Base.556Clip", "Base.M14Clip", "Base.308Clip", "Base.223Clip", "Base.44Clip", "Base.45Clip", "Base.9mmClip", "Base.Revolver_Short", "Base.Revolver_Long",
                                         "Base.Revolver" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 40 then
                    local randomitem = { "Base.Aerosolbomb", "Base.Axe", "Base.BaseballBat", "Base.SpearCrafted", "Base.Crowbar", "Base.FlameTrap", "Base.HandAxe", "Base.HuntingKnife", "Base.Katana",
                                         "Base.PipeBomb", "Base.Sledgehammer", "Base.Shovel", "Base.SmokeBomb", "Base.WoodAxe", "Base.GardenFork", "Base.WoodenLance", "Base.SpearBreadKnife",
                                         "Base.SpearButterKnife", "Base.SpearFork", "Base.SpearLetterOpener", "Base.SpearScalpel", "Base.SpearSpoon", "Base.SpearScissors", "Base.SpearHandFork",
                                         "Base.SpearScrewdriver", "Base.SpearHuntingKnife", "Base.SpearMachete", "Base.SpearIcePick", "Base.SpearKnife", "Base.Machete", "Base.GardenHoe" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 50 then
                    local randomitem = { "Base.Bag_SurvivorBag", "Base.Bag_BigHikingBag", "Base.Bag_DuffelBag", "Base.Bag_FannyPackFront", "Base.Bag_NormalHikingBag", "Base.Bag_ALICEpack", "Base.Bag_ALICEpack_Army",
                                         "Base.Bag_Schoolbag", "Base.SackOnions", "Base.SackPotatoes", "Base.SackCarrots", "Base.SackCabbages" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 60 then
                    local randomitem = { "Base.Hat_SPHhelmet", "Base.Jacket_CoatArmy", "Base.Hat_BalaclavaFull", "Base.Hat_BicycleHelmet", "Base.Shoes_BlackBoots", "Base.Hat_CrashHelmet",
                                         "Base.HolsterDouble", "Base.Hat_Fireman", "Base.Jacket_Fireman", "Base.Trousers_Fireman", "Base.Hat_FootballHelmet", "Base.Hat_GasMask", "Base.Ghillie_Trousers", "Base.Ghillie_Top",
                                         "Base.Gloves_LeatherGloves", "Base.JacketLong_Random", "Base.Shoes_ArmyBoots", "Base.Vest_BulletArmy", "Base.Hat_Army", "Base.Hat_HardHat_Miner", "Base.Hat_NBCmask",
                                         "Base.Vest_BulletPolice", "Base.Hat_RiotHelmet", "Base.AmmoStrap_Shells" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 70 then
                    local randomitem = { "Base.CarBattery1", "Base.CarBattery2", "Base.CarBattery3", "Base.Extinguisher", "Base.PetrolCan", "Base.ConcretePowder", "Base.PlasterPowder", "Base.BarbedWire", "Base.Log",
                                         "Base.SheetMetal", "Base.MotionSensor", "Base.ModernTire1", "Base.ModernTire2", "Base.ModernTire3", "Base.ModernSuspension1", "Base.ModernSuspension2", "Base.ModernSuspension3",
                                         "Base.ModernCarMuffler1", "Base.ModernCarMuffler2", "Base.ModernCarMuffler3", "Base.ModernBrake1", "Base.ModernBrake2", "Base.ModernBrake3", "Base.smallSheetMetal",
                                         "Base.Speaker", "Base.EngineParts", "Base.LogStacks2", "Base.LogStacks3", "Base.LogStacks4", "Base.NailsBox" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 80 then
                    local randomitem = { "Base.ComicBook", "Base.ElectronicsMag4", "Base.HerbalistMag", "Base.MetalworkMag1", "Base.MetalworkMag2", "Base.MetalworkMag3", "Base.MetalworkMag4",
                                         "Base.HuntingMag1", "Base.HuntingMag2", "Base.HuntingMag3", "Base.FarmingMag1", "Base.MechanicMag1", "Base.MechanicMag2", "Base.MechanicMag3",
                                         "Base.CookingMag1", "Base.CookingMag2", "Base.EngineerMagazine1", "Base.EngineerMagazine2", "Base.ElectronicsMag1", "Base.ElectronicsMag2", "Base.ElectronicsMag3", "Base.ElectronicsMag5",
                                         "Base.FishingMag1", "Base.FishingMag2", "Base.Book", "MoreTraits.MedicalMag1", "MoreTraits.MedicalMag2", "MoreTraits.MedicalMag3", "MoreTraits.MedicalMag4", "MoreTraits.AntiqueMag1",
                                         "MoreTraits.AntiqueMag2", "MoreTraits.AntiqueMag3" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 90 then
                    local randomitem = { "Base.DumbBell", "Base.EggCarton", "Base.HomeAlarm", "Base.HotDog", "Base.HottieZ", "Base.Icecream", "Base.Machete", "Base.Revolver_Long",
                                         "Base.MeatPatty", "Base.Milk", "Base.MuttonChop", "Base.Padlock", "Base.PorkChop", "Base.Wine", "Base.Wine2", "Base.WhiskeyFull", "Base.Ham" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 95 then
                    local randomitem = { "Base.PropaneTank", "Base.BlowTorch", "Base.Woodglue", "Base.DuctTape", "Base.Rope", "Base.Extinguisher" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                elseif roll <= 100 then
                    local randomitem = { "Base.Spiffo", "Base.SpiffoSuit", "Base.Hat_Spiffo", "Base.SpiffoTail", "Base.Generator" };
                    inv:addItemOnServer(inv:AddItem(randomitem[ZombRand(tablelength(randomitem))]));
                end
            end

        end
    end

end

function Gourmand(_iSInventoryPage, _state, _player)
    local player = _player;
    local containerObj;
    local container;
    if player:HasTrait("gourmand") then
        local basechance = 33;
        if player:HasTrait("Lucky") then
            basechance = basechance + 10 * luckimpact;
        end
        if player:HasTrait("Unlucky") then
            basechance = basechance - 10 * luckimpact;
        end
        for i, v in ipairs(_iSInventoryPage.backpacks) do
            if v.inventory:getParent() then
                containerObj = v.inventory:getParent();
                if not containerObj:getModData().bGourmandRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                    containerObj:getModData().bGourmandRolled = true;
                    containerObj:transmitModData();
                    container = containerObj:getContainer();
                    for l = 0, container:getItems():size() - 1 do
                        local item = container:getItems():get(l);
                        if item ~= nil then
                            if item:getCategory() == "Food" then
                                if item:isRotten() == true then
                                    if ZombRand(100) <= basechance then
                                        local newitem = container:AddItem(item:getFullType());
                                        container:addItemOnServer(newitem)
                                        container:Remove(item);
                                        container:removeItemOnServer(item);
                                        if MoreTraits.settings.GourmandAnnounce == true then
                                            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gourmand") .. ": " .. newitem:getName(), true, HaloTextHelper.getColorGreen());
                                        end
                                    end
                                elseif item:isFresh() == false then
                                    if ZombRand(100) <= basechance then
                                        local newitem = container:AddItem(item:getFullType());
                                        container:addItemOnServer(newitem);
                                        container:Remove(item);
                                        container:removeItemOnServer(item);
                                        if MoreTraits.settings.GourmandAnnounce == true then
                                            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gourmand") .. ": " .. newitem:getName(), true, HaloTextHelper.getColorGreen());
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
function setFoodState(food, state)
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
            local cookTime = itemdata.origCookTime;
            food:setMinutesToCook(cookTime * 1.5);
            food:setMinutesToBurn((cookTime * 1.5) + ((itemdata.origBurnTime - cookTime) * 0.5));
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
function FoodUpdate(_player)
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
function FearfulUpdate(_player)
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
function GymGoer(_player, _perk, _amount)
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
            if MTVersion:getMajor() >= 41 and MTVersion:getMinor() >= 66 then
                player:getXp():AddXP(perk, amount, false, false, false);
            else
                player:getXp():AddXP(perk, amount, false, false);
            end
        end
    end
end
function GymGoerUpdate(_player)
    local player = _player;
    if player:HasTrait("gymgoer") then
        local bodydamage = player:getBodyDamage();
        for i = 0, bodydamage:getBodyParts():size() - 1 do
            local b = bodydamage:getBodyParts():get(i);
            local stiffness = b:getStiffness();
            if stiffness > 0 then
                b:setStiffness(0);
            end
        end
    end
end
function ContainerEvents(_iSInventoryPage, _state)
    local page = _iSInventoryPage;
    local state = _state;
    if state == "end" then
        local player = getPlayer();
        ToadTraitIncomprehensive(page, state, player);
        ToadTraitScrounger(page, state, player);
        ToadTraitVagabond(page, state, player);
        Gourmand(page, state, player);
        ToadTraitAntique(page, state, player);
    end
end
function LearnAllRecipes(_player)
    local player = _player;
    local recipes = getScriptManager():getAllRecipes();
    if SandboxVars.MoreTraits.IngenuitiveLimit == true then
        local percenttolearn = 0.5;
        local unknownrecipes = {};
        if SandboxVars.MoreTraits.IngenuitiveLimitAmount then
            percenttolearn = SandboxVars.MoreTraits.IngenuitiveLimitAmount * 0.01;
        end
        for i = recipes:size() - 1, 0, -1 do
            local recipe = recipes:get(i);
            if recipe:needToBeLearn() == true then
                if player:isRecipeKnown(recipe) == false then
                    table.insert(unknownrecipes, recipe:getOriginalname());
                end
            end
        end
        if tablelength(unknownrecipes) > 1 then
            local amntunknown = tablelength(unknownrecipes) - 1;
            local newamnt = amntunknown * percenttolearn;
            local amntlearned = 0;
            repeat
                for i = tablelength(unknownrecipes) - 1, 0, -1 do
                    if ZombRand(0, 100) <= 5 then
                        player:learnRecipe(unknownrecipes[i]);
                        amntlearned = amntlearned + 1;
                    end
                end
            until (amntlearned >= newamnt)
        end
    else
        for i = recipes:size() - 1, 0, -1 do
            local recipe = recipes:get(i);
            if recipe:needToBeLearn() == true then
                if player:isRecipeKnown(recipe) == false then
                    player:learnRecipe(recipe:getOriginalname());
                end
            end
        end
    end
end
function QuickWorker(_player)
    local player = _player;
    if player:HasTrait("quickworker") then
        if player:hasTimedActions() == true then
            local actions = player:getCharacterActions();
            local blacklist = { "ISWalkToTimedAction", "ISPathFindAction", "" }
            local action = actions:get(0);
            local type = action:getMetaType();
            local delta = action:getJobDelta();
            --Don't modify the action if it is in the Blacklist or if it has not yet started (is valid)
            if tableContains(blacklist, type) == false and delta > 0 then
                local modifier = 0.5;
                if SandboxVars.MoreTraits.QuickWorkerScaler then
                    modifier = modifier * (SandboxVars.MoreTraits.QuickWorkerScaler * 0.01);
                end
                if player:HasTrait("Lucky") and ZombRand(100) <= 10 then
                    modifier = modifier + 0.25 * luckimpact;
                elseif player:HasTrait("Unlucky") and ZombRand(100) <= 10 then
                    modifier = modifier - 0.25 * luckimpact;
                end
                if player:HasTrait("Dextrous") and ZombRand(100) <= 10 then
                    modifier = modifier + 0.25;
                elseif player:HasTrait("AllThumbs") and ZombRand(100) <= 10 then
                    modifier = modifier - 0.25;
                end
                if type == "ISReadABook" then
                    if player:HasTrait("FastReader") then
                        modifier = modifier * 5;
                    elseif player:HasTrait("SlowReader") then
                        modifier = modifier * 1.5;
                    else
                        modifier = modifier * 3;
                    end
                end
                if modifier < 0 then
                    modifier = 0;
                end
                if delta < 0.99 - (modifier * 0.01) then
                    --Don't overshoot it.
                    action:setCurrentTime(action:getCurrentTime() + modifier);
                end
            end
        end
    end
end
function SlowWorker(_player)
    local player = _player;
    if player:HasTrait("slowworker") then
        if player:hasTimedActions() == true then
            local actions = player:getCharacterActions();
            local blacklist = { "ISWalkToTimedAction", "ISPathFindAction", "" }
            local action = actions:get(0);
            local type = action:getMetaType();
            local delta = action:getJobDelta();
            --Don't modify the action if it is in the Blacklist or if it has not yet started (is valid)
            if tableContains(blacklist, type) == false and delta > 0 then
                local modifier = 0.5;
                local chance = 15;
                if SandboxVars.MoreTraits.SlowWorkerScaler then
                    chance = SandboxVars.MoreTraits.SlowWorkerScaler;
                end
                if player:HasTrait("Lucky") and ZombRand(100) <= 10 then
                    modifier = modifier - 0.5 * luckimpact;
                elseif player:HasTrait("Unlucky") and ZombRand(100) <= 10 then
                    modifier = modifier + 0.5 * luckimpact;
                end
                if player:HasTrait("Dextrous") and ZombRand(100) <= 10 then
                    modifier = modifier - 0.5;
                elseif player:HasTrait("AllThumbs") and ZombRand(100) <= 10 then
                    modifier = modifier + 0.5;
                end
                if type == "ISReadABook" then
                    if player:HasTrait("FastReader") then
                        modifier = modifier * 0.1;
                    elseif player:HasTrait("SlowReader") then
                        modifier = modifier * 0.5;
                    else
                        modifier = modifier * 0.25;
                    end
                end
                if modifier < 0 then
                    modifier = 0;
                end
                if delta < 0.99 - (modifier * 0.01) and ZombRand(100) <= chance then
                    --Don't overshoot it.
                    action:setCurrentTime(action:getCurrentTime() - modifier);
                end
            end
        end
    end
end
function LeadFoot(_player)
    local player = _player;
    local shoes = player:getClothingItem_Feet();
    local itemdata = nil;
    if shoes ~= nil then
        itemdata = shoes:getModData();
        local origstomp = itemdata.origStomp;
        if origstomp == nil then
            origstomp = shoes:getStompPower();
            itemdata.origStomp = origstomp;
            itemdata.stompState = "Normal";
        end
        if player:HasTrait("leadfoot") then
            if itemdata.stompState ~= "LeadFoot" then
                local newstomp = origstomp * 2 + 1;
                shoes:setStompPower(newstomp);
                itemdata.stompState = "LeadFoot";
            end
        else
            if shoes:getStompPower() ~= origstomp then
                shoes:setStompPower(origstomp);
                itemdata.stompState = "Normal";
            end
        end
    end
end
function GlassBody(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    local bodydamage = player:getBodyDamage();
    if player:HasTrait("glassbody") then
        if player:isAsleep() then
            --Don't wound the player in their sleep.
            playerdata.fLastHP = 0;
            return ;
        end
        if playerdata.fLastHP == nil then
            --Initialize the hp.
            playerdata.fLastHP = bodydamage:getOverallBodyHealth();
            return ;
        end
        local lasthp = playerdata.fLastHP;
        local currenthp = bodydamage:getOverallBodyHealth();
        local multiplier = getGameTime():getMultiplier();
        --Don't check if the multiplier is too high (prevent from injuring so many times)
        if currenthp < lasthp and multiplier <= 4.0 then
            local chance = 33;
            local woundstrength = 10;
            if player:HasTrait("Lucky") then
                chance = chance - 5 * luckimpact;
                woundstrength = woundstrength - 5 * luckimpact;
            elseif player:HasTrait("Unlucky") then
                chance = chance + 5 * luckimpact;
                woundstrength = woundstrength + 5 * luckimpact;
            end
            local difference = lasthp - currenthp;
            --Divide the difference by the number of body parts, since ReduceGeneralHealth applies to each part.
            difference = difference * 2 / bodydamage:getBodyParts():size();
            bodydamage:ReduceGeneralHealth(difference);
            if difference > 0.33 and ZombRand(100) <= chance then
                local randompart = ZombRand(0, 16);
                local b = bodydamage:getBodyPart(BodyPartType.FromIndex(randompart));
                b:setFractureTime(ZombRand(20) + woundstrength);
            elseif difference > 0.1 and ZombRand(100) <= chance then
                local randompart = ZombRand(0, 16);
                local b = bodydamage:getBodyPart(BodyPartType.FromIndex(randompart));
                b:setScratched(true, true);
            end
        end
        playerdata.fLastHP = bodydamage:getOverallBodyHealth();
    end
end
function BatteringRam()
    local player = getPlayer();
    if player:HasTrait("batteringram") then
        local playerdata = player:getModData();
        local Fitnesslvl = player:getPerkLevel(Perks.Fitness);
        if Fitnesslvl == 0 then
            Fitnesslvl = 1;
        end
        local endurancereduction = (10 / Fitnesslvl) * 0.01;
        local stats = player:getStats();
        local endurance = stats:getEndurance();
        local inTree = player:getCurrentSquare():Has(IsoObjectType.tree);
        if playerdata.bWasJustSprinting == nil then
            playerdata.bWasJustSprinting = false;
        end
        if player:isSprinting() then
            local bodydamage = player:getBodyDamage();
            if bodydamage:getBodyPart(BodyPartType.UpperLeg_L):getFractureTime() > 1 or bodydamage:getBodyPart(BodyPartType.UpperLeg_R):getFractureTime() > 1 or bodydamage:getBodyPart(BodyPartType.LowerLeg_L):getFractureTime() > 1 or bodydamage:getBodyPart(BodyPartType.LowerLeg_R):getFractureTime() > 1 or bodydamage:getBodyPart(BodyPartType.Foot_L):getFractureTime() > 1 or bodydamage:getBodyPart(BodyPartType.Foot_R):getFractureTime() > 1 then
                return ;
            end
            playerdata.bWasJustSprinting = true;
            local nearbyzombies = false;
            local enemies = player:getSpottedList();
            for i = 0, enemies:size() - 1 do
                local enemy = enemies:get(i);
                if enemy:isZombie() then
                    local distance = enemy:DistTo(player)
                    if distance <= 2 then
                        nearbyzombies = true;
                        break ;
                    end
                end
            end
            if inTree == false and nearbyzombies == true then
                player:setGhostMode(true);
            else
                player:setGhostMode(false);
            end
            for i = 0, enemies:size() - 1 do
                local enemy = enemies:get(i);
                if enemy:isZombie() then
                    local distance = enemy:DistTo(player)
                    if distance <= 1.0 and enemy:isKnockedDown() == false then
                        enemy:setKnockedDown(true);
                        enemy:setStaggerBack(true);
                        enemy:setHitReaction("");
                        enemy:setPlayerAttackPosition("FRONT");
                        enemy:setHitForce(2.0);
                        enemy:reportEvent("wasHit");
                        stats:setEndurance(endurance - endurancereduction);
                    end
                end
            end
            if internalTick >= 25 then
                addSound(player, player:getX(), player:getY(), player:getZ(), 20, 25);
            end
        else
            if playerdata.bWasJustSprinting == true then
                player:setGhostMode(false);
                addSound(player, player:getX(), player:getY(), player:getZ(), 20, 25);
                playerdata.bWasJustSprinting = false;
            end
        end
    end
end
function BatteringRamUpdate(_player, _playerdata)
    local player = _player;
    local playerdata = _playerdata;
    if player:HasTrait("batteringram") then
        if playerdata.bWasJustSprinting == nil then
            playerdata.bWasJustSprinting = false;
        end
        if playerdata.bWasJustSprinting == true then
            player:setGhostMode(false);
            addSound(player, player:getX(), player:getY(), player:getZ(), 20, 25);
            playerdata.bWasJustSprinting = false;
        end
    end
end
function mundane(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
    if _actor == player then
        if weapondata.origCritChance == nil then
            weapondata.origCritChance = weapon:getCriticalChance();
        end
        if player:HasTrait("mundane") then
            weapon:setCriticalChance(1);
        else
            if weapon:getCriticalChance() < weapondata.origCritChance then
                weapon:setCriticalChance(weapondata.origCritChance);
            end
        end
    end
end
function clothingUpdate(_player)
    local player = _player;
    local state = "Normal";
    local wornItems = player:getWornItems();
    local inventory = player:getInventory();
    if player:HasTrait("fitted") then
        state = "Fitted";
    end
    if wornItems ~= nil and wornItems:size() > 1 then
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i);
            if item:IsClothing() then
                --Don't reduce weight of unequipped clothing.
                local itemdata = item:getModData();
                if itemdata.sState ~= nil and itemdata.sState ~= "Normal" and wornItems:contains(item) == false then
                    item:setRunSpeedModifier(itemdata.iOrigRunSpeedMod);
                    item:setCombatSpeedModifier(itemdata.iOrigCombatSpeedMod);
                    item:setActualWeight(itemdata.iOrigWeight);
                    itemdata.sState = "Normal";
                end
            end
        end
        for i = wornItems:size() - 1, 0, -1 do
            local item = wornItems:getItemByIndex(i);
            if item:IsClothing() then
                local itemdata = item:getModData();
                if itemdata.sState == nil then
                    --first time checking item. Initialize it.
                    itemdata.sState = "Normal";
                    itemdata.iOrigRunSpeedMod = item:getRunSpeedModifier();
                    itemdata.iOrigCombatSpeedMod = item:getCombatSpeedModifier();
                    itemdata.iOrigWeight = item:getActualWeight();
                end
                if state ~= itemdata.sState then
                    --update state
                    if itemdata.iOrigRunSpeedMod ~= nil and itemdata.iOrigRunSpeedMod < 1 then
                        if state == "Fitted" then
                            item:setRunSpeedModifier(1.0);
                        else
                            item:setRunSpeedModifier(itemdata.iOrigRunSpeedMod);
                        end
                    end
                    if itemdata.iOrigCombatSpeedMod ~= nil and itemdata.iOrigCombatSpeedMod < 1 then
                        if state == "Fitted" then
                            item:setCombatSpeedModifier(1.0);
                        else
                            item:setCombatSpeedModifier(itemdata.iOrigCombatSpeedMod);
                        end
                    end
                    if itemdata.iOrigWeight ~= nil then
                        if state == "Fitted" then
                            item:setActualWeight(itemdata.iOrigWeight * 0.5);
                        else
                            item:setActualWeight(itemdata.iOrigWeight);
                        end
                    end
                    itemdata.sState = state;
                    player:setWornItems(wornItems);
                end
            end
        end
    end
end

local function CheckInjuredHeal()
    if #BodyDamagedFromTrait > 0 then
        for i, v in ipairs(BodyDamagedFromTrait) do
            if v:HasInjury() == false then
                table.remove(BodyDamagedFromTrait, i, v);
                i = i - 1;
            end
        end
    end
end

local function NoodleLegs(_player, _playerdata)
	if _player:HasTrait("noodlelegs") then
	local CurrentLocation = _player:getCurrentSquare();
	local SprintingLvl = _player:getPerkLevel(Perks.Sprinting);
	local NimbleLvl = _player:getPerkLevel(Perks.Nimble);
	local N_Chance = 10;
	N_Chance = N_Chance - ((NimbleLvl+SprintingLvl)/4); --Decreases odds by .25 for every level in nimble or sprinting, for a total of -5 with nimble and sprinting at lvl 10
	if _player:HasTrait("Graceful") then
		N_Chance = N_Chance - 2;
		end	
	if _player:HasTrait("Clumsy") then
		N_Chance = N_Chance + 2;
		end
	if _player:HasTrait("Lucky") then
		N_Chance = N_Chance - 1 * luckimpact;
		end
	if _player:HasTrait("Unlucky") then
		N_Chance = N_Chance + 1 * luckimpact;
		end
	if _player:IsRunning() == true and _player:isMoving() == true then
		local Roll = ZombRand(0, 101);
			if Roll <= N_Chance then
		local type = nil;
		local random = ZombRand(2);

        if random == 0 then
            type = "left"
        else
            type = "right"
        end
			_player:setBumpFallType("FallForward");
			_player:setBumpType(type);
			_player:setBumpDone(false);
			_player:setBumpFall(true);
			_player:reportEvent("wasBumped");
			end
		end
	if _player:isSprinting() == true and _player:isMoving() == true then
		N_Chance = N_Chance * 2;
		local Roll = ZombRand(0, 101);
			if Roll <= N_Chance then
		local type = nil;
		local random = ZombRand(2);

        if random == 0 then
            type = "left"
        else
            type = "right"
        end
			_player:setBumpFallType("FallForward");
			_player:setBumpType(type);
			_player:setBumpDone(false);
			_player:setBumpFall(true);
			_player:reportEvent("wasBumped");
			end
		end	
	end 
end

local function SecondWind(player)
	local zombiesnearplayer = 0;
	local playerdata = player:getModData();
	local enemies = player:getSpottedList();
	local playerstats = player:getStats();
	if player:HasTrait("secondwind") then
		if playerstats:getEndurance() < 0.5 or playerstats:getFatigue() > 0.8 then
			if playerdata.secondwinddisabled == false then
			if enemies:size() > 2 then
                    for i = 0, enemies:size() - 1 do
                        if enemies:get(i):isZombie() then
                            if enemies:get(i):DistTo(player) <= 5 then
				zombiesnearplayer = zombiesnearplayer + 1;
                            end
                        end
                    end
	if zombiesnearplayer > 2 then
		playerstats:setEndurance(1);
		if playerstats:getFatigue() > 0.5 then
			playerstats:setFatigue(0.5);
		end
		playerdata.secondwindcooldown = 0;
		secondwinddisabled = true;
		HaloTextHelper.addTextWithArrow(player, getText("UI_trait_secondwind"), true, HaloTextHelper.getColorGreen());
		end
            end
	 end	
      end
   end
end

local function SecondWindRecharge()
	local player = getPlayer();
    local playerdata = player:getModData();
    local recharge = 14 * 24;
	if player:HasTrait("secondwind") then
		if playerdata.secondwinddisabled == true then
            if playerdata.secondwindcooldown >= recharge then
                playerdata.secondwindcooldown = 0;
                playerdata.secondwinddisabled = false;
                player:Say(getText("UI_trait_secondwindcooldown"));
            else
                playerdata.secondwindcooldown = playerdata.secondwindcooldown + 1;
	    end
        end
    end
end

local function MotionSickness(player)
	local playerstats = player:getBodyDamage();
	local Sickness = playerstats:getFakeInfectionLevel();
	if player:HasTrait("motionsickness") then
	if player:isDriving() == true and Sickness < 98 then
		local vehicle = player:getVehicle()
		if not vehicle then return end 
		if vehicle:getCurrentSpeedKmHour() > 0 and vehicle:getCurrentSpeedKmHour() < 15 then
		playerstats:setFakeInfectionLevel(Sickness + 0.01);
		end
		if vehicle:getCurrentSpeedKmHour() >= 15 and vehicle:getCurrentSpeedKmHour() < 30 then
		playerstats:setFakeInfectionLevel(Sickness + 0.05);
		end
		if vehicle:getCurrentSpeedKmHour() >= 30 and vehicle:getCurrentSpeedKmHour() < 45 then
		playerstats:setFakeInfectionLevel(Sickness + 0.1);
		end
		if vehicle:getCurrentSpeedKmHour() >= 45 and vehicle:getCurrentSpeedKmHour() < 60 then
		playerstats:setFakeInfectionLevel(Sickness + 0.2);
		end
		if vehicle:getCurrentSpeedKmHour() >= 60 and vehicle:getCurrentSpeedKmHour() < 90 then
		playerstats:setFakeInfectionLevel(Sickness + 0.5);
		end
		if vehicle:getCurrentSpeedKmHour() >= 90 then
		playerstats:setFakeInfectionLevel(Sickness + 1);
		end
		
		--This section is for reversed driving, because positive values are when you drive forward, and negative when you drive back--
		
		if vehicle:getCurrentSpeedKmHour() < 0 and vehicle:getCurrentSpeedKmHour() > -15 then
		playerstats:setFakeInfectionLevel(Sickness + 0.01);
		end
		if vehicle:getCurrentSpeedKmHour() <= -15 and vehicle:getCurrentSpeedKmHour() > -30 then
		playerstats:setFakeInfectionLevel(Sickness + 0.05);
		end
		if vehicle:getCurrentSpeedKmHour() <= -30 and vehicle:getCurrentSpeedKmHour() > -45 then
		playerstats:setFakeInfectionLevel(sickness + 0.1);
		end
		if vehicle:getCurrentSpeedKmHour() <= -45 and vehicle:getCurrentSpeedKmHour() > -60 then
		playerstats:setFakeInfectionLevel(Sickness + 0.2);
		end
		if vehicle:getCurrentSpeedKmHour() <= -60 and vehicle:getCurrentSpeedKmHour() > -90 then
		playerstats:setFakeInfectionLevel(Sickness + 0.5);
		end
		if vehicle:getCurrentSpeedKmHour() <= -90 then
		playerstats:setFakeInfectionLevel(Sickness + 1);
		end
	end
	if not player:isDriving() and not playerstats:IsFakeInfected() and Sickness ~= 0 then
		playerstats:setFakeInfectionLevel(Sickness - 0.1);
	end
	end
end


function MainPlayerUpdate(_player)
    local player = _player;
    local playerdata = player:getModData();
    if internalTick >= 30 then
        amputee(player, (playerdata.bWasInfected ~= player:getBodyDamage():isInfected()
                and player:getBodyDamage():isInfected()));
        playerdata.bWasInfected = player:getBodyDamage():isInfected();
        vehicleCheck(player);
        FoodUpdate(player);
        Gordanite(player);
        BatteringRamUpdate(player, playerdata);
        clothingUpdate(player)
        --Reset internalTick every 30 ticks
        internalTick = 0;
    elseif internalTick == 20 then
        FearfulUpdate(player);
    elseif internalTick == 10 then
        SuperImmune(player, playerdata);
        Immunocompromised(player, playerdata);
    end
    MotionSickness(player);
    SecondWind(player);
    indefatigable(player, playerdata);
    anemic(player);
    thickblood(player);
    CheckDepress(player, playerdata);
    CheckSelfHarm(player);
    Blissful(player);
    hardytrait(player, playerdata);
    drinkerupdate(player, playerdata);
    bouncerupdate(player, playerdata);
    badteethtrait(player, playerdata);
    albino(player, playerdata);
    QuickWorker(player);
    SlowWorker(player);
    if suspendevasive == false then
        ToadTraitEvasive(player, playerdata);
        GlassBody(player, playerdata);
    end
    internalTick = internalTick + 1;
end

function EveryOneMinute()
    local player = getPlayer();
    local playerdata = player:getModData();
    ToadTraitParanoia(player, playerdata);
    ToadTraitButter(player);
    UnHighlightScrounger(player, playerdata);
    LeadFoot(player);
    GymGoerUpdate(player);
    NoodleLegs(player, playerData);
end
function OnLoad()
    --reset any worn clothing to default state.
    local player = getPlayer();
    local playerdata = player:getModData();
    local wornItems = player:getWornItems();
    for i = wornItems:size() - 1, 0, -1 do
        local item = wornItems:getItemByIndex(i);
        if item:IsClothing() then
            local itemdata = item:getModData();
            itemdata.sState = nil;
        end
    end
    --reset evasive on game load
    playerdata.ToadTraitBodyDamage = nil;
    suspendevasive = false;
    player:getBodyDamage():Update();
end
--Events.OnPlayerMove.Add(gimp);
--Events.OnPlayerMove.Add(fast);
Events.OnPlayerMove.Add(BatteringRam);
Events.OnZombieDead.Add(graveRobber);
Events.OnWeaponHitCharacter.Add(problunt);
Events.OnWeaponHitCharacter.Add(problade);
Events.OnWeaponHitCharacter.Add(prospear);
Events.OnWeaponHitCharacter.Add(actionhero);
Events.OnWeaponHitCharacter.Add(mundane);
Events.OnWeaponHitCharacter.Add(tavernbrawler);
Events.OnWeaponSwing.Add(progun);
Events.OnWeaponHitCharacter.Add(martial);
Events.EveryHours.Add(drinkerpoison);
Events.EveryHours.Add(drinkertick);
Events.AddXP.Add(Specialization);
Events.AddXP.Add(GymGoer);
Events.EveryHours.Add(SecondWindRecharge);
Events.EveryHours.Add(indefatigablecounter);
Events.EveryHours.Add(CheckInjuredHeal);
Events.OnPlayerUpdate.Add(MainPlayerUpdate);
Events.EveryOneMinute.Add(EveryOneMinute);
Events.EveryTenMinutes.Add(checkWeight);
Events.EveryHours.Add(ToadTraitDepressive);
Events.OnNewGame.Add(initToadTraitsPerks);
Events.OnNewGame.Add(initToadTraitsItems);
Events.OnRefreshInventoryWindowContainers.Add(ContainerEvents);
Events.OnLoad.Add(OnLoad);
