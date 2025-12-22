require('NPCs/MainCreationMethods');
require("Items/Distributions");
require("Items/ProceduralDistributions");

if getActivatedMods():contains("MoodleFramework") == true then
    require("MF_ISMoodle");
    MF.createMoodle("MTAlcoholism");
end
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
MT_Config = PZAPI.ModOptions:getOptions("1299328280");
skipxpadd = false;
internalTick = 0;
luckimpact = 1.0;
MTModVersion = 42.13; --REMEMBER TO MANUALLY INCREASE
isMoodleFrameWorkEnabled = getActivatedMods():contains("MoodleFramework");
playerdatatable = {};
playerdatatable[0] = { "MTModVersion", MTModVersion };
playerdatatable[1] = { "secondwinddisabled", false };
playerdatatable[2] = { "secondwindrecoveredfatigue", false };
playerdatatable[3] = { "secondwindcooldown", 0 };
playerdatatable[4] = { "bToadTraitDepressed", false };
playerdatatable[5] = { "indefatigablecooldown", 0 };
playerdatatable[6] = { "indefatigablecuredinfection", false };
playerdatatable[7] = { "indefatigabledisabled", false };
playerdatatable[8] = { "bindefatigable", false };
playerdatatable[9] = { "IndefatigableHasBeenDraggedDown", false };
playerdatatable[10] = { "bSatedDrink", true };
playerdatatable[11] = { "iHoursSinceDrink", 0 };
playerdatatable[12] = { "iTimesCannibal", 0 };
playerdatatable[13] = { "fPreviousHealthFromFoodTimer", 1000 };
playerdatatable[14] = { "bWasInfected", false };
playerdatatable[15] = { "iHardyEndurance", 5 };
playerdatatable[16] = { "iHardyMaxEndurance", 5 };
playerdatatable[17] = { "iHardyInterval", 1000 };
playerdatatable[18] = { "iWithdrawalCooldown", 24 };
playerdatatable[19] = { "iParanoiaCooldown", 10 };
playerdatatable[20] = { "SuperImmuneRecovery", 0 };
playerdatatable[21] = { "SuperImmuneActive", false };
playerdatatable[22] = { "SuperImmuneMinutesPassed", 0 };
playerdatatable[23] = { "SuperImmuneTextSaid", false };
playerdatatable[24] = { "SuperImmuneHealedOnce", false };
playerdatatable[25] = { "SuperImmuneMinutesWellFed", 0 };
playerdatatable[26] = { "SuperImmuneAbsoluteWellFedAmount", 0 };
playerdatatable[27] = { "SuperImmuneInfections", 0 };
playerdatatable[28] = { "SuperImmuneLethal", false };
playerdatatable[29] = { "MotionActive", false };
playerdatatable[30] = { "HasSlept", false };
playerdatatable[31] = { "FatigueWhenSleeping", 0 };
playerdatatable[32] = { "NeckHadPain", false };
playerdatatable[33] = { "ContainerTraitIllegal", false };
playerdatatable[34] = { "ContainerTraitPlayerCurrentPositionX", 0 };
playerdatatable[35] = { "ContainerTraitPlayerCurrentPositionY", 0 };
playerdatatable[36] = { "AlbinoTimeSpentOutside", 0 };
playerdatatable[37] = { "isMTAlcoholismInitialized", false };
playerdatatable[38] = { "iBouncercooldown", 0 };
playerdatatable[39] = { "bisInfected", false };
playerdatatable[40] = { "bisAlbinoOutside", false };
playerdatatable[41] = { "bToadTraitDepressed", false };
playerdatatable[42] = { "bWasJustSprinting", false };
playerdatatable[43] = { "InjuredBodyList", {} };
playerdatatable[44] = { "UnwaveringInjurySpeedChanged", false };
playerdatatable[45] = { "OldCalories", 810 };
playerdatatable[46] = { "IngenuitiveActivated", false };
playerdatatable[47] = { "EvasivePlayerInfected", false };
playerdatatable[48] = { "TraitInjuredBodyList", {} };
playerdatatable[49] = { "fLastHP", 0 };
playerdatatable[50] = { "isSleeping", false };
playerdatatable[51] = { "QuickRestActive", false };
playerdatatable[52] = { "QuickRestEndurance", -1 };
playerdatatable[53] = { "QuickRestFinished", false };

local function GetXPModifier(player, perk)
    local m = 1.0

    -- GymGoer bonus UNIQUEMENT
    if player:hasTrait(ToadTraitsRegistries.gymgoer)
        and (perk == Perks.Fitness or perk == Perks.Strength)
        and player:getCurrentState() == FitnessState.instance() then
            local gymMod = SandboxVars.MoreTraits.GymGoerPercent or 200
            m = m + ((gymMod * 0.01) - 1) * 0.1
    end

    return m
end

-- Fonction AddXP
local function AddXP(player, perk, amount)
    player:getXp():AddXP(perk, amount, false, false, false);
end


local function GameSpeedMultiplier()
    local gamespeed = UIManager.getSpeedControls():getCurrentGameSpeed();
    local multiplier = 1;
    if gamespeed == 2 then
        multiplier = 5;
    elseif gamespeed == 3 then
        multiplier = 20;
    elseif gamespeed == 4 then
        multiplier = 40;
    end
    return multiplier;
end
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
    stats:set(CharacterStat.UNHAPPINESS, 0);
    stats:set(CharacterStat.ENDURANCE, 0);
    stats:set(CharacterStat.BOREDOM, 0);
    stats:set(CharacterStat.STRESS, 0);
end

function ZombPatty_OnCreate(items, result, player)
    local stats = player:getStats();
    local curstress = stats:get(CharacterStat.STRESS)
    local times = player:getModData().iTimesCannibal;
    if times <= 25 then
        stats:set(CharacterStat.STRESS, curstress + 0.2);
        result:setTooltip(getText("UI_cannibal_early"));
    elseif times <= 50 then
        stats:set(CharacterStat.STRESS,curstress + 0.1);
        result:setUnhappyChange(10);
        result:setTooltip(getText("UI_cannibal_familiar"));
    else
        stats:set(CharacterStat.STRESS,curstress - 0.1);
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
    player:getXp():AddXPNoMultiplier(perk, amount);
end

local function InitPlayerData(player)
    local playerdata = player:getModData()
    for i, v in pairs(playerdatatable) do
        if playerdata[v[1]] == nil then
            playerdata[v[1]] = v[2]
        end
    end
end

function initToadTraitsItems(player)
    if isClient() then return end -- We want this to be run directly on the server to avoid desync
    local inv = player:getInventory();

    if player:hasTrait(ToadTraitsRegistries.deprived) then
        player:clearWornItems();
        inv:removeAllItems();
        player:createKeyRing();
        if SandboxVars.MoreTraits.ForgivingDeprived then
            local item = inv:AddItem("Base.Belt2");
            inv:addItemOnServer(item);
        end
        return
    end
    if player:hasTrait(ToadTraitsRegistries.preparedfood) then
        local holder = inv:AddItem("Base.Plasticbag");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.TinOpener", "Base.CannedTomato", "Base.CannedPotato", "Base.CannedCarrots", "Base.CannedBroccoli", "Base.CannedCabbage", "Base.CannedEggplant"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
            end
            player:setSecondaryHandItem(holder);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedammo) then
        local holder = inv:AddItem("Base.PistolCase1");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.Bullets9mmBox", "Base.Bullets45Box", "Base.Bullets44Box", "Base.Bullets38Box", "Base.223Box", "Base.308Box", "Base.556Box", "Base.ShotgunShellsBox"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
            end
            player:setSecondaryHandItem(holder);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedweapon) then
        local items = {"Base.BaseballBat_Can", "Base.HuntingKnife"}
        for _, item in ipairs(items) do
            local i = inv:AddItem(item);
            inv:addItemOnServer(i);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedmedical) then
        local holder = inv:AddItem("Base.FirstAidKit");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.Bandaid", "Base.PillsAntiDep", "Base.Disinfectant", "Base.AlcoholWipes", "Base.PillsBeta", "Base.Pills", "Base.SutureNeedle", "Base.Tissue", "Base.Tweezers"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
                local amount = SandboxVars.MoreTraits.PreparedMedicalBandageAmount or 4
                for i = 1, amount do
                    local item = holderInv:AddItem("Base.Bandage");
                    if item then holderInv:addItemOnServer(item) end
                end
            end
            player:setSecondaryHandItem(holder);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedrepair) then
        local holder = inv:AddItem("Base.Toolbox")
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.Screwdriver", "Base.Saw", "Base.Hammer", "Base.NailsBox"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
                for i = 1, 8 do
                    local item = holderInv:AddItem("Base.Garbagebag");
                    if item then holderInv:addItemOnServer(item) end
                end
            end
            player:setSecondaryHandItem(holder);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcamp) then
        local holder = inv:AddItem("MoreTraits.Bag_SmallHikingBag");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.Matches", "Base.TentGreen_Packed", "Base.BeefJerky", "Base.Pop", "Base.FishingRod", "Base.FishingLine", "Base.FishingTackle", "Base.Battery", "Base.Torch", "Base.WaterBottleFull"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
                for i = 1, 3 do
                    local item = holderInv:AddItem("Base.Stone2")
                    if item then holderInv:addItemOnServer(item) end
                end
            end
            if player:getClothingItem_Back() == nil then player:setClothingItem_Back(holder); end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedpack) then
        local holder = inv:AddItem("Base.Bag_NormalHikingBag")
        inv:addItemOnServer(holder);
        if holder then
            if player:getClothingItem_Back() == nil then player:setClothingItem_Back(holder); end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcar) then
        local holder = inv:AddItem("Base.Bag_JanitorToolbox");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.CarBattery", "Base.Screwdriver", "Base.Wrench", "Base.LugWrench", "Base.TirePump", "Base.Jack"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
            end
            player:setPrimaryHandItem(holder);
        end
        if SandboxVars.MoreTraits.PreparedCarGasToggle then
            local holder2 = inv:AddItem("Base.PetrolCan");
            inv:addItemOnServer(holder2);
            if holder2 then player:setSecondaryHandItem(holder); end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcoordination) then
        local holder = inv:AddItem("Base.Bag_FannyPackFront");
        local watch = inv:AddItem("Base.WristWatch_Right_DigitalBlack");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.MuldraughMap", "Base.RosewoodMap", "Base.RiversideMap", "Base.WestpointMap", "Base.MarchRidgeMap", "Base.Pencil"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
            end
            if not player:getWornItem(holder:getBodyLocation()) then
                player:setWornItem(holder:getBodyLocation(), holder)
            end
        end
        if watch and not player:getWornItem(watch:getBodyLocation()) then
            player:setWornItem(watch:getBodyLocation(), watch)
        end
    end
    if player:hasTrait(ToadTraitsRegistries.drinker) then
        if SandboxVars.MoreTraits.AlcoholicFreeDrink then
            local item = inv:AddItem("Base.WhiskeyFull");
            inv:addItemOnServer(item);
        end
    end
    if player:hasTrait(CharacterTrait.TAILOR) then
        local holder = inv:AddItem("Base.SewingKit");
        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {"Base.Scissors", "Base.Needle"}
                for _, item in ipairs(items) do
                    local i = holderInv:AddItem(item);
                    holderInv:addItemOnServer(i);
                end
                for i = 1, 4 do
                    local item = holderInv:AddItem("Base.Thread")
                    if item then holderInv:addItemOnServer(item) end
                end
            end
        end
    end
    if player:hasTrait(CharacterTrait.SMOKER) and SandboxVars.MoreTraits.SmokerStart then
        local items = {"Base.Cigarettes", "Base.Lighter"}
        for _, item in ipairs(items) do
            local i = inv:AddItem(item);
            inv:addItemOnServer(i);
        end
    end
end

-- Helper function to level up perks safely and grant XP to the next level
local function levelPerkByAmount(player, perk, amount)
    local currentLevel = player:getPerkLevel(perk)
    local targetLevel = math.min(10, currentLevel + amount)
    
    for i = currentLevel + 1, targetLevel do
        player:LevelPerk(perk)
        player:getXp():setXPToLevel(perk, i)
    end
end

function initToadTraitsPerks(player)
    if not player then return end
    local playerdata = player:getModData()
    if not playerdata then return end;
    
    local bodyDamage = player:getBodyDamage()
    local damage = 20
    local bandagestrength = 5
    local splintstrength = 0.9
    local fracturetime = 50
    local scratchtimemod = 20
    local bleedtimemod = 10
    
    if SandboxVars.MoreTraits.LuckImpact then luckimpact = SandboxVars.MoreTraits.LuckImpact * 0.01 end

    InitPlayerData(player)
    
    -- Luck Modifications
    if player:hasTrait(ToadTraitsRegistries.lucky) then
        damage = damage - (5 * luckimpact)
        bandagestrength = bandagestrength + (2 * luckimpact)
        fracturetime = fracturetime - (5 * luckimpact)
        splintstrength = splintstrength + (0.1 * luckimpact)
        scratchtimemod = scratchtimemod - (5 * luckimpact)
        bleedtimemod = bleedtimemod - (2 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        damage = damage + (5 * luckimpact)
        bandagestrength = bandagestrength - (2 * luckimpact)
        fracturetime = fracturetime + (5 * luckimpact)
        splintstrength = splintstrength - (0.1 * luckimpact)
        scratchtimemod = scratchtimemod + (5 * luckimpact)
        bleedtimemod = bleedtimemod + (2 * luckimpact)
    end

    if player:hasTrait(ToadTraitsRegistries.injured) then
        local TraitInjuredBodyList = playerdata.TraitInjuredBodyList
        local iterations = ZombRand(1, 4) + 1
        local doburns = SandboxVars.MoreTraits.InjuredBurns ~= false

        for i = 1, iterations do
            local randompart = ZombRand(0, 16)
            local b = bodyDamage:getBodyPart(BodyPartType.FromIndex(randompart))
            
            if b:HasInjury() then
                -- Try again once if we hit an already injured part
                randompart = ZombRand(0, 16)
                b = bodyDamage:getBodyPart(BodyPartType.FromIndex(randompart))
            end

            if not b:HasInjury() then
                local injury = ZombRand(0, 5)
                b:AddDamage(damage)
                
                if injury <= 1 then -- Scratch
                    b:setScratched(true, true)
                elseif injury == 2 and doburns then -- Burn
                    b:setBurned()
                    b:setBurnTime(ZombRand(50) + damage)
                    b:setNeedBurnWash(false)
                elseif injury == 3 then -- Cut
                    b:setCut(true, true)
                else -- Deep Wound
                    b:setDeepWounded(true)
                    b:setStitched(true)
                end
                
                b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage")
                table.insert(TraitInjuredBodyList, randompart)
            end
        end
        bodyDamage:setInfected(false)
    end

    if player:hasTrait(ToadTraitsRegistries.broke) then
        local leg = bodyDamage:getBodyPart(BodyPartType.LowerLeg_R)
        leg:AddDamage(damage)
        leg:setFractureTime(fracturetime)
        leg:setSplint(true, splintstrength)
        leg:setSplintItem("Base.Splint")
        leg:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage")
        table.insert(playerdata.TraitInjuredBodyList, BodyPartType.ToIndex(BodyPartType.LowerLeg_R))
        bodyDamage:setInfected(false)
    end

    MT_checkWeight(player)

    if player:hasTrait(ToadTraitsRegistries.burned) then
        for i = 0, bodyDamage:getBodyParts():size() - 1 do
            local b = bodyDamage:getBodyParts():get(i)
            b:setBurned()
            b:setBurnTime(ZombRand(10, 100) + damage)
            b:setNeedBurnWash(false)
            b:setBandaged(true, ZombRand(1, 10) + bandagestrength, true, "Base.AlcoholBandage")
            table.insert(playerdata.TraitInjuredBodyList, i)
        end
    end

    if player:hasTrait(ToadTraitsRegistries.ingenuitive) then
        MT_LearnAllRecipes(player)
        playerdata.IngenuitiveActivated = true
    end

    if player:hasTrait(ToadTraitsRegistries.noxpshooter) then
        levelPerkByAmount(player, Perks.Aiming, 2)
    end

    if player:hasTrait(ToadTraitsRegistries.noxptechnician) then
        levelPerkByAmount(player, Perks.Mechanics, 1)
        levelPerkByAmount(player, Perks.Electricity, 2)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpfirstaid) then
        levelPerkByAmount(player, Perks.Doctor, 3)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpaxe) then
        levelPerkByAmount(player, Perks.Axe, 2)
        levelPerkByAmount(player, Perks.Woodwork, 1)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpmaintenance) then
        levelPerkByAmount(player, Perks.Maintenance, 2)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpsneaky) then
        levelPerkByAmount(player, Perks.Sneak, 2)
        levelPerkByAmount(player, Perks.Lightfoot, 1)
    end

    if player:hasTrait(ToadTraitsRegistries.terminator) then
        levelPerkByAmount(player, Perks.Aiming, 3)
        levelPerkByAmount(player, Perks.Reloading, 2)
        levelPerkByAmount(player, Perks.Nimble, 1)
    end
end

function MTPlayerHit(player, _, __)
    if not player or player:isDead() or player:isZombie() then return end
    
    local playerdata = player:getModData()
    if not playerdata then return end;
    
    local list = playerdata.InjuredBodyList
    local bodyDamage = player:getBodyDamage()
    local isInfected = bodyDamage:isInfected()
    
    local triedImmuno = false
    local blockedAnim = false
    local bodyParts = bodyDamage:getBodyParts()
    local bodyPartsSize = bodyParts:size()

    if player:hasTrait(ToadTraitsRegistries.evasive) then
        local currentState = player:getCurrentState()
        local isHitState = currentState == PlayerHitReactionState.instance()
        local isPVPState = currentState == PlayerHitReactionPVPState.instance() and SandboxVars.MoreTraits.EvasiveBlocksPVP
        
        if isHitState or isPVPState then
            for i = 0, bodyPartsSize - 1 do
                local bodyPart = bodyParts:get(i)

                if bodyPart:HasInjury() and not tableContains(list, i) then
                    local dodgeChance = SandboxVars.MoreTraits.EvasiveChance or 0
                    
                    local wasInfectedBefore = playerdata.EvasivePlayerInfected or false
                    if ZombRand(1, 101) <= dodgeChance then
                        if SandboxVars.MoreTraits.EvasiveAnimation then
                            player:setHitReaction("EvasiveBlocked")
                            blockedAnim = true
                        end
                        
                        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_dodgesay"), true, HaloTextHelper.getColorGreen())

                        if bodyPart:IsInfected() and not wasInfectedBefore and isInfected then
                            bodyPart:SetInfected(false)
                            bodyDamage:setInfected(false)
                            bodyDamage:setInfectionMortalityDuration(-1)
                            bodyDamage:setInfectionTime(-1)
                            bodyDamage:setInfectionGrowthRate(0)
                        end
                        
                        -- Heal the injury immediately
                        bodyPart:setBleedingTime(0)
                        bodyPart:setBleeding(false)
                        
                        if bodyPart:scratched() then
                            bodyPart:setScratchTime(0)
                            bodyPart:setScratched(false, false)
                        end
                        
                        if bodyPart:isCut() then
                            bodyPart:setCutTime(0)
                            bodyPart:setCut(false, false)
                        end
                        
                        if bodyPart:bitten() then 
                            bodyPart:RestoreToFullHealth() 
                        end
                    else
                        table.insert(list, i)
                        if bodyPart:IsInfected() and not wasInfectedBefore and isInfected then
                            playerData.EvasivePlayerInfected = true
                        end
                    end
                end
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.immunocompromised) and not triedImmuno then
        if player:getCurrentState() == PlayerHitReactionState.instance() then
            for i = 0, bodyPartsSize - 1 do
                local bodyPart = bodyParts:get(i)
                if bodyPart:HasInjury() and not tableContains(list, i) then
                    table.insert(list, i)
                    local immunoChance = SandboxVars.MoreTraits.ImmunoChance or 0
                    triedImmuno = true 
                    
                    if ZombRand(1, 101) <= immunoChance then 
                        bodyDamage:setInfected(true) 
                    end
                    break
                end
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.unwavering) and not blockedAnim then
        if player:getCurrentState() == PlayerHitReactionState.instance() then
            local reaction = player:getHitReaction()
            if reaction == "Bite" or reaction == "BiteDefended" then
                player:setHitReaction("Unwavering" .. reaction)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unwavering"), true, HaloTextHelper.getColorGreen())
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.glassbody) then
        GlassBody(player, playerData)
    end
end

function ToadTraitButter(player)
    if player:hasTrait(ToadTraitsRegistries.butterfingers) and player:isPlayerMoving() then
        local basechance = 3;
        local chanceinx = SandboxVars.MoreTraits.ButterfingersChance or 2000;

        if player:hasTrait(CharacterTrait.ALL_THUMBS) then basechance = basechance + 1; end
        if player:hasTrait(CharacterTrait.DEXTROUS) then basechance = basechance - 1; end
        if player:hasTrait(ToadTraitsRegistries.packmule) then basechance = basechance - 1; end
        if player:hasTrait(ToadTraitsRegistries.packmouse) then basechance = basechance + 1; end
        if player:hasTrait(ToadTraitsRegistries.lucky) then basechance = basechance - 1 * luckimpact; end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then basechance = basechance + 1 * luckimpact; end

        local weight = player:getInventoryWeight();
        local chancemod =  math.floor(weight / 5);

        if player:isSprinting() then chancemod = chancemod + 10;
        elseif player:IsRunning() then chancemod = chancemod + 5; end

        local totalChance = basechance + chancemod;

        if totalChance >= ZombRand(chanceinx) then
            if player:getSecondaryHandItem() ~= nil or player:getPrimaryHandItem() ~= nil then
                player:dropHandItems();
                HaloTextHelper.addTextWithArrow(player, getText("UI_butterfingers_triggered"), false, HaloTextHelper.getColorRed());
                player:getEmitter():playSound("UIUnEquipItem");
            end
        end
    end
end

function ToadTraitParanoia(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.paranoia) then return end

    if playerdata.iParanoiaCooldown > 0 then playerdata.iParanoiaCooldown = playerdata.iParanoiaCooldown - 1; return end

    if player:isPlayerMoving() then
        local stats = player:getStats();
        local panic = stats:get(CharacterStat.PANIC);
        local stress = stats:get(CharacterStat.STRESS);

        local triggerThreshold = 1 
        triggerThreshold = triggerThreshold + (stress * 2)
        if ZombRand(100) < triggerThreshold then
            local sm = getSoundManager()
            local surprised = sm:PlaySound("ZombieSurprisedPlayer", false, 0)
            if surprised then surprised:setVolume(0.05) end

            stats:set(CharacterStat.PANIC, math.min(panic + 25, 100))
            stats:set(CharacterStat.STRESS, math.min(stress + 0.1, 1.0))

            local breathSound = player:isFemale() and "female_heavybreathpanic" or "male_heavybreathpanic"
            local breath = sm:PlaySound(breathSound, false, 5)
            if breath then breath:setVolume(0.025) end

            playerdata.iParanoiaCooldown = 30
        end
    end
end

function ToadTraitScrounger(_iSInventoryPage, _state, _player)
    local player = _player;
    local playerData = player:getModData();
    local containerObj;
    local container;
    if player:hasTrait(ToadTraitsRegistries.scrounger) then
        local basechance = 20;
        local modifier = 1.3;
        if SandboxVars.MoreTraits.ScroungerChance then
            basechance = SandboxVars.MoreTraits.ScroungerChance;
        end
        if SandboxVars.MoreTraits.ScroungerLootModifier then
            modifier = 1.0 + SandboxVars.MoreTraits.ScroungerLootModifier * 0.01;
        end
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            basechance = basechance + 5 * (luckimpact or 1.0);
            modifier = modifier + 0.1 * (luckimpact or 1.0);
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            basechance = basechance - 5 * (luckimpact or 1.0);
            modifier = modifier - 0.1 * (luckimpact or 1.0);
        end
        for i, v in ipairs(_iSInventoryPage.backpacks) do
            if v.inventory:getParent() then
                containerObj = v.inventory:getParent();
                if not containerObj:getModData().bScroungerorIncomprehensiveRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                    containerObj:getModData().bScroungerorIncomprehensiveRolled = true;
                    containerObj:transmitModData();
                    if playerData.ContainerTraitIllegal == true then
                        playerData.ContainerTraitIllegal = false;
                        return
                    end
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
                                        --Add a Special Case for Cigarettes and Nails since they inherently create 20 when added.
                                        if item:getFullType() == "Base.Cigarettes" or item:getFullType() == "Base.Nails" then
                                            count = math.floor(count / 20);
                                        end
                                        local bchance = 10;
                                        if SandboxVars.MoreTraits.ScroungerItemChance then
                                            bchance = SandboxVars.MoreTraits.ScroungerItemChance;
                                        end
                                        if player:hasTrait(ToadTraitsRegistries.lucky) then
                                            bchance = bchance + 5 * (luckimpact or 1.0);
                                        end
                                        if player:hasTrait(ToadTraitsRegistries.unlucky) then
                                            bchance = bchance - 5 * (luckimpact or 1.0);
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
                                            for iterator = 0, n - 1 do
                                                local addedItem = container:AddItem(item:getFullType());
                                                container:addItemOnServer(addedItem);
                                            end
                                            if MT_Config:getOption("ScroungerAnnounce"):getValue() == true then
                                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrounger") .. " : " .. item:getName(), true, HaloTextHelper.getColorGreen());
                                            end
                                            if MT_Config:getOption("ScroungerHighlight"):getValue() == true then
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
    if MT_Config:getOption("ScroungerHighlight"):getValue() == true then
        local maxTime = MT_Config:getOption("ScroungerHighlightTime"):getValue() * 10;
        local player = _player;
        local playerData = _playerdata;
        if not playerData.scroungerHighlightsTbl then
            playerData.scroungerHighlightsTbl = {}
        end
        local scroungerHighlightsTbl = playerData.scroungerHighlightsTbl;
        if scroungerHighlightsTbl ~= {} then
            if player:hasTrait(ToadTraitsRegistries.scrounger) then
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
    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then
        local basechance = 10;
        if SandboxVars.MoreTraits.IncomprehensiveChance then
            basechance = SandboxVars.MoreTraits.IncomprehensiveChance;
        end
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            basechance = basechance - 5 * (luckimpact or 1.0);
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            basechance = basechance + 5 * (luckimpact or 1.0);
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
                                        if player:hasTrait(ToadTraitsRegistries.lucky) then
                                            bchance = bchance - 5 * (luckimpact or 1.0);
                                        end
                                        if player:hasTrait(ToadTraitsRegistries.unlucky) then
                                            bchance = bchance + 5 * (luckimpact or 1.0);
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
                            if MT_Config:getOption("ScroungerAnnounce"):getValue() == true then
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_incomprehensive") .. " : " .. i:getName(), false, HaloTextHelper.getColorRed());
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ToadTraitAntique(_iSInventoryPage, _state, player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.antique) then return end

    local LootRespawn = SandboxVars.LootRespawn;
    local respawnMap = { [2] = 24, [3] = 168, [4] = 720, [5] = 1440 };
    local HoursForLootRespawn = respawnMap[LootRespawn] or 0;
    local AllowRespawn = LootRespawn ~= 1;
    local basechance = 10;
    local roll = SandboxVars.MoreTraits.AntiqueChance or 1500;

    if player:hasTrait(ToadTraitsRegistries.lucky) then basechance = basechance + (1 * luckimpact) end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then basechance = basechance - (1 * luckimpact) end
    if player:hasTrait(CharacterTrait.DEXTROUS) then basechance = basechance + 1 end
    if player:hasTrait(CharacterTrait.ALL_THUMBS) then basechance = basechance - 1 end
    if player:hasTrait(ToadTraitsRegistries.scrounger) then basechance = basechance + 1 end
    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then basechance = basechance - 1 end
    if basechance < 1 then basechance = 1 end

    local worldAgeHours = GameTime:getInstance():getWorldAgeHours();

    local function attemptLootSpawn(obj, container)
        if playerdata.ContainerTraitIllegal then
            playerdata.ContainerTraitIllegal = false;
            if AllowRespawn then
                obj:getModData().AllowRespawn = false;
                obj:transmitModData();
            end
            return
        end

        local antiqueItemsList = {
            "MoreTraits.AntiqueAxe", "MoreTraits.Thumper", "MoreTraits.ObsidianBlade",
            "MoreTraits.Bag_PackerBag", "MoreTraits.BloodyCrowbar", "MoreTraits.Slugger",
            "MoreTraits.AntiqueJacket", "MoreTraits.AntiqueVest", "MoreTraits.AntiqueBoots",
            "MoreTraits.AntiqueSpear", "MoreTraits.AntiqueHammer", "MoreTraits.AntiqueKatana",
            "MoreTraits.AntiqueMag1", "MoreTraits.AntiqueMag2", "MoreTraits.AntiqueMag3",
        };

        local type = container:getType();
        local isAllowedType = (type == "crate" or type == "metal_shelves");
        local isAnywhere = SandboxVars.MoreTraits.AntiqueAnywhere == true;

        if (isAllowedType or isAnywhere) and ZombRand(roll) <= basechance then
            local randomItem = antiqueItemsList[ZombRand(#antiqueItemsList) + 1];
            local item = container:AddItem(randomItem);
            container:addItemOnServer(item);
            print("Found antique item! " .. tostring(item:getName()));
        end
    end

    for _, v in ipairs(_iSInventoryPage.backpacks) do
        local inv = v.inventory;
        if inv and inv:getParent() then
            local containerObj = inv:getParent();
            local modData = containerObj:getModData();

            if instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                if not modData.bAntiqueRolled then
                    modData.bAntiqueRolled = true;
                    modData.bHoursWhenChecked = worldAgeHours;
                    modData.AllowRespawn = true;
                    containerObj:transmitModData();
                    attemptLootSpawn(containerObj, containerObj:getContainer());
                elseif AllowRespawn and modData.AllowRespawn and modData.bAntiqueRolled then
                    if (modData.bHoursWhenChecked + HoursForLootRespawn) <= worldAgeHours then
                        modData.bHoursWhenChecked = worldAgeHours;
                        containerObj:transmitModData();
                        attemptLootSpawn(containerObj, containerObj:getContainer());
                    end
                end
            end
        end
    end
end

local function ToadTraitVagabond(_iSInventoryPage, _state, player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.vagabond) then return end

    local items = {
        "Base.BreadSlices", "Base.Pizza", "Base.Hotdog", "Base.Corndog",
        "Base.OpenBeans", "Base.CannedChiliOpen", "Base.WatermelonSmashed",
        "Base.DogfoodOpen", "Base.CannedCornedBeefOpen", "Base.CannedBologneseOpen",
        "Base.CannedCarrotsOpen", "Base.CannedCornOpen", "Base.CannedMushroomSoupOpen",
        "Base.CannedPeasOpen", "Base.CannedPotatoOpen", "Base.CannedSardinesOpen",
        "Base.CannedTomatoOpen", "Base.TinnedSoupOpen", "Base.TunaTinOpen",
        "Base.CannedFruitCocktailOpen", "Base.CannedPeachesOpen", "Base.CannedPineappleOpen",
        "Base.MushroomGeneric1", "Base.MushroomGeneric2", "Base.MushroomGeneric3",
        "Base.MushroomGeneric4", "Base.MushroomGeneric5", "Base.MushroomGeneric6",
        "Base.MushroomGeneric7"
    };

    local basechance = SandboxVars.MoreTraits.VagabondChance or 33;

    if player:hasTrait(ToadTraitsRegistries.lucky) then basechance = basechance + (5 * luckimpact) end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then basechance = basechance - (5 * luckimpact) end

    for _, v in ipairs(_iSInventoryPage.backpacks) do
        local inv = v.inventory;
        if inv and inv:getParent() then
            local containerObj = inv:getParent();
            local modData = containerObj:getModData();

            -- Check if container is a "bin" (trash can) and hasn't been rolled for Vagabond yet
            if not modData.bVagbondRolled and instanceof(containerObj, "IsoObject") 
            and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                
                modData.bVagbondRolled = true;
                containerObj:transmitModData();

                if playerdata.ContainerTraitIllegal then
                    playerdata.ContainerTraitIllegal = false;
                    return
                end

                local container = containerObj:getContainer();
                if container:getType() == "bin" then
                    local extra = SandboxVars.MoreTraits.VagabondGuaranteedExtraLoot or 1;
                    local iterations = ZombRand(0, 3) + extra;

                    for i = 1, iterations do
                        if ZombRand(100) <= basechance then
                            local x = ZombRand(#items) + 1;
                            local item = container:AddItem(items[x]);
                            container:addItemOnServer(item);

                            -- Visual feedback
                            if MT_Config:getOption("VagabondAnnounce"):getValue() then
                                HaloTextHelper.addTextWithArrow(
                                    player, getText("UI_trait_vagabond") .. " : " .. item:getName(), 
                                    true, HaloTextHelper.getColorGreen()
                                );
                            end
                        end
                    end
                end
            end
        end
    end
end

function ToadTraitDepressive(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.depressive) then return end
    if playerdata.bToadTraitDepressed then return end

    local basechance = 2

    if player:hasTrait(ToadTraitsRegistries.lucky) then basechance = basechance - (1 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then basechance = basechance + (1 * luckimpact) end

    if player:hasTrait(ToadTraitsRegistries.selfdestructive) then basechance = basechance + 1 end

    if ZombRand(100) < basechance then
        local stats = player:getStats()
        local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS);
        stats:set(CharacterStat.UNHAPPINESS, currentUnhappiness + 25);
        
        playerdata.bToadTraitDepressed = true
        print("Player is experiencing depression.");
    end
end

function CheckDepress(player, playerdata)
    local depressed = playerdata.bToadTraitDepressed;
    if depressed == true then
        local stats = player:getStats()
        local unhappiness = stats:get(CharacterStat.UNHAPPINESS);
        if unhappiness < 25 then playerdata.bToadTraitDepressed = false;
        else stats:set(CharacterStat.UNHAPPINESS, unhappiness + 0.001);
        end
    end
end

function CheckSelfHarm(player)
    if not player:hasTrait(ToadTraitsRegistries.selfdestructive) then return end
    
    local modifier = 3 - (player:hasTrait(ToadTraitsRegistries.depressive) and 1 or 0)
    local stats = player:getStats()
    local unhappiness = stats:get(CharacterStat.UNHAPPINESS);
    local bodyDamage = player:getBodyDamage();
    local bodyParts = bodyDamage:getBodyParts();

    if unhappiness >= 25 then
        if bodyDamage:getOverallBodyHealth() >= (100 - unhappiness / modifier) then
            for i = 0, bodyParts:size() - 1 do
                local b = bodyParts:get(i);
                b:AddDamage(0.001 * GameSpeedMultiplier());
            end
        end
    end
end

function Blissful(player)
    if not player:hasTrait(ToadTraitsRegistries.blissful) then return end
    local stats = player:getStats()
    local unhappiness = stats:get(CharacterStat.UNHAPPINESS);
    local boredom = stats:get(CharacterStat.BOREDOM);
    if unhappiness >= 10 then stats:set(CharacterStat.UNHAPPINESS, unhappiness - 0.01); end
    if boredom >= 10 then stats:set(CharacterStat.BOREDOM, boredom - 0.005); end
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
        if player:hasTrait(ToadTraitsRegistries.specweapons) or player:hasTrait(ToadTraitsRegistries.specfood) or player:hasTrait(ToadTraitsRegistries.specguns) or player:hasTrait(ToadTraitsRegistries.specmove) or player:hasTrait(ToadTraitsRegistries.speccrafting) or player:hasTrait(ToadTraitsRegistries.specaid) then
            if player:hasTrait(ToadTraitsRegistries.specweapons) then
                if perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Maintenance or perk == Perks.SmallBlunt or perk == Perks.Spear then
                    skip = true;
                end
            end
            if player:hasTrait(ToadTraitsRegistries.specfood) then
                if perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.PlantScavenging or perk == Perks.Trapping or perk == Perks.Fishing then
                    skip = true;
                end
            end
            if player:hasTrait(ToadTraitsRegistries.specguns) then
                if perk == Perks.Aiming or perk == Perks.Reloading then
                    skip = true;
                end
            end
            if player:hasTrait(ToadTraitsRegistries.specmove) then
                if perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sprinting or perk == Perks.Sneak then
                    skip = true;
                end
            end
            if player:hasTrait(ToadTraitsRegistries.speccrafting) then
                if perk == Perks.Woodwork or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring then
                    skip = true;
                end
            end
            if player:hasTrait(ToadTraitsRegistries.specaid) then
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
                        AddXP(player, perk, -1 * 0.1);
                    end
                end
            end
        end
    else
        skipxpadd = false;
    end
end
--[[
function Specialization(player, perk, amount)
    -- Ignorer Fitness et Strength (gérés par GymGoer)
    if perk == Perks.Fitness or perk == Perks.Strength then return end

    -- Table des traits de spécialisation et des perks concernés
    local specs = {
        specweapons = {Perks.Axe, Perks.Blunt, Perks.LongBlade, Perks.SmallBlade, Perks.Maintenance, Perks.SmallBlunt, Perks.Spear},
        specfood = {Perks.Cooking, Perks.Farming, Perks.PlantScavenging, Perks.Trapping, Perks.Fishing},
        specguns = {Perks.Aiming, Perks.Reloading},
        specmove = {Perks.Lightfoot, Perks.Nimble, Perks.Sprinting, Perks.Sneak},
        speccrafting = {Perks.Woodwork, Perks.Electricity, Perks.MetalWelding, Perks.Mechanics, Perks.Tailoring},
        specaid = {Perks.Doctor}
    }

    -- Vérifier si le joueur possède au moins un trait "spec*"
    local hasSpec = false
    for trait in pairs(specs) do
        if player:hasTrait(trait) then
            hasSpec = true
            break
        end
    end
    if not hasSpec then return end

    -- Si le perk correspond à une spécialisation du joueur, on ne fait rien
    for trait, perks in pairs(specs) do
        if player:hasTrait(trait) then
            for _, p in ipairs(perks) do
                if perk == p then return end
            end
        end
    end

    -- Appliquer la pénalité d'XP
    local modifier = (SandboxVars.MoreTraits.SpecializationXPPercent or 75) * 0.01
    local xpToRemove = amount - (amount * modifier)
    AddXP(player, perk, -xpToRemove)
end
--]]

function indefatigable(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.indefatigable) then return end
    if SandboxVars.MoreTraits.IndefatigableOneUse and playerdata.indefatigabledisabled then return end

    local triggerHealth = 15
    local bodyDamage = player:getBodyDamage();
    if (bodyDamage:getHealth() < triggerHealth or player:isDeathDragDown()) and not playerdata.bindefatigable then

        if player:isDeathDragDown() then
            print("Player dragged down, indefatigable activated");
            playerdata.IndefatigableHasBeenDraggedDown = true;
            player:setPlayingDeathSound(false);
            player:setDeathDragDown(false);
            player:setHitReaction("EvasiveBlocked");
        end

        if getActivatedMods():contains("MTAddonIndefatigableLol") == true then
            getSoundManager():PlaySound("indefatigabletheme", false, 0):setVolume(0.5);
        end

        print("Healed to full.");
        for i = 0, bodyDamage:getBodyParts():size() - 1 do
            local b = bodyDamage:getBodyParts():get(i);
            if tableContains(playerdata.TraitInjuredBodyList, i) == false then
                b:RestoreToFullHealth();
            else
                b:SetHealth(100);
            end
        end
        bodyDamage:setOverallBodyHealth(100);

        if bodyDamage:IsInfected() then
            if not playerdata.indefatigablecuredinfection or SandboxVars.MoreTraits.IndefatigableOneUse then
                local stats = player:getStats();
                bodyDamage:setInfected(false);
                bodyDamage:setInfectionMortalityDuration(-1);
                bodyDamage:setInfectionTime(-1);
                stats:set(CharacterStat.ZOMBIE_FEVER, 0);
                stats:set(CharacterStat.ZOMBIE_INFECTION, 0);
                playerdata.indefatigablecuredinfection = true;
            end
        end

        playerdata.bindefatigable = true;
        playerdata.indefatigablecooldown = 0;

        local enemies = player:getSpottedList();
        if enemies:size() > 2 then
            for i = 0, enemies:size() - 1 do
                if enemies:get(i):isZombie() and enemies:get(i):DistTo(player) <= 2.5 then
                    enemies:get(i):setStaggerBack(true);
                    enemies:get(i):setKnockedDown(true);
                end
            end
        end
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen());

        if SandboxVars.MoreTraits.IndefatigableOneUse then playerdata.indefatigabledisabled = true end
    end
end

function indefatigablecounter(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.indefatigable) or not playerdata.bindefatigable then return end

    local recharge = (SandboxVars.MoreTraits.IndefatigableRecharge or 7) * 24
    
    local multiplier = 1
    if playerdata.indefatigablecuredinfection then multiplier = multiplier * 2 end
    if playerdata.IndefatigableHasBeenDraggedDown then multiplier = multiplier * 2 end
    
    local totalRequired = recharge * multiplier

    playerdata.indefatigablecooldown = (playerdata.indefatigablecooldown or 0) + 1

    if playerdata.indefatigablecooldown >= totalRequired then
        playerdata.indefatigablecooldown = 0
        playerdata.bindefatigable = false
        playerdata.indefatigablecuredinfection = false
        playerdata.IndefatigableHasBeenDraggedDown = false
        player:Say(getText("UI_trait_indefatigablecooldown"))
    end
end

function badteethtrait(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.badteeth) then return end

    local bodyDamage = player:getBodyDamage()
    local healthTimer = bodyDamage:getHealthFromFoodTimer()

    if healthTimer > 1000 and healthTimer > playerdata.fPreviousHealthFromFoodTimer then
        local head = bodyDamage:getBodyPart(BodyPartType.Head)
        local painIncrease = (healthTimer - playerdata.fPreviousHealthFromFoodTimer) * 0.01
        local newPain = head:getAdditionalPain() + painIncrease
        head:setAdditionalPain(math.min(newPain, 100))
    end

    playerdata.fPreviousHealthFromFoodTimer = healthTimer
end

function hardytrait(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.hardy) then return end

    local stats = player:getStats()
    local currentEndurance = stats:get(CharacterStat.ENDURANCE);
    
    playerdata.iHardyEndurance = playerdata.iHardyEndurance or 0
    playerdata.iHardyMaxEndurance = 5
    
    local regenAmount = 0.05
    if SandboxVars.MoreTraits.HardyEndurance then regenAmount = SandboxVars.MoreTraits.HardyEndurance / 500 end

    if currentEndurance < 0.85 and playerdata.iHardyEndurance >= 1 then
        local newEndurance = math.min(currentEndurance + regenAmount, 1.0)
        stats:set(CharacterStat.ENDURANCE, newEndurance);
        
        playerdata.iHardyEndurance = playerdata.iHardyEndurance - 1
        if MT_Config:getOption("HardyNotifier"):getValue() == true then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardyendurance") .. " : " .. playerdata.iHardyEndurance, false, HaloTextHelper.getColorRed())
        end
    elseif currentEndurance >= 1.0 and playerdata.iHardyEndurance < playerdata.iHardyMaxEndurance then
        stats:set(CharacterStat.ENDURANCE, currentEndurance - regenAmount);
        playerdata.iHardyEndurance = playerdata.iHardyEndurance + 1
        
        if MT_Config:getOption("HardyNotifier"):getValue() == true then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardyendurance") .. " : " .. playerdata.iHardyEndurance, true, HaloTextHelper.getColorGreen())
        else
            HaloTextHelper.addText(player, getText("UI_trait_hardyrest"), "")
        end
    end
end

function drinkerupdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then return end

    local stats = player:getStats()
    local drunkness = stats:get(CharacterStat.INTOXICATION);
    local hoursSinceDrink = playerdata.iHoursSinceDrink or 0
    
    local hoursThreshold = (SandboxVars.MoreTraits.AlcoholicFrequency or 24) * 1.5
    local divider = 5
    
    if hoursThreshold <= 2 then divider = 0.1
    elseif hoursThreshold <= 5 then divider = 0.2
    elseif hoursThreshold <= 10 then divider = 0.5
    elseif hoursThreshold <= 20 then divider = 1
    end

    local withdrawalIntensity = hoursSinceDrink / divider

    if drunkness >= 10 then
        if not playerdata.bSatedDrink then
            playerdata.bSatedDrink = true
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicsatisfied"), true, HaloTextHelper.getColorGreen())
        end
        playerdata.iHoursSinceDrink = 0
        stats:set(CharacterStat.ANGER, 0)
        stats:set(CharacterStat.STRESS, 0)
    end

    if drunkness > 0 then
        if internalTick and internalTick >= 25 then
            stats:set(CharacterStat.FATIGUE, math.max(0, stats:get(CharacterStat.FATIGUE) - 0.01));
        end
    end

    if not playerdata.bSatedDrink then
        if hoursSinceDrink > hoursThreshold then
            local currentPain = stats:get(CharacterStat.PAIN)
            stats:set(CharacterStat.PAIN, (math.min(100, currentPain + (withdrawalIntensity * 0.1))));
        end

        if internalTick == 30 then
            local anger = stats:get(CharacterStat.ANGER)
            local stress = stats:get(CharacterStat.STRESS)

            local angerLimit = 0.05 + (withdrawalIntensity * 0.1) / 3
            local stressLimit = 0.15 + (withdrawalIntensity * 0.1) / 2
            
            if anger < angerLimit then stats:set(CharacterStat.ANGER, anger + 0.01) end
            if stress < stressLimit then stats:stress(CharacterStat.STRESS, stress + 0.01) end
        end
    end
end

function drinkertick(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then return end

    local hourThreshold = SandboxVars.MoreTraits.AlcoholicFrequency or 24

    if player:hasTrait(ToadTraitsRegistries.lucky) then hourThreshold = hourThreshold + (4 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then hourThreshold = hourThreshold - (2 * luckimpact) end

    if player:hasTrait(ToadTraitsRegistries.lightdrinker) then hourThreshold = hourThreshold - 2; end

    playerdata.iHoursSinceDrink = (playerdata.iHoursSinceDrink or 0) + 1

    if playerdata.bSatedDrink then
        if playerdata.iHoursSinceDrink >= hourThreshold then
            local divider = 4
            if hourThreshold <= 2 then divider = 0.1
            elseif hourThreshold <= 5 then divider = 0.2
            elseif hourThreshold <= 10 then divider = 0.5
            elseif hourThreshold <= 20 then divider = 1
            end

            if ZombRand(100) <= (hourThreshold / divider) then
                playerdata.bSatedDrink = false
                print("Player needs alcohol.")
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicneed"), false, HaloTextHelper.getColorRed())
            end
        end
    else
        if MT_Config:getOption("DrinkNotifier"):getValue() == true then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicneed"), false, HaloTextHelper.getColorRed())
        end
    end
end

function drinkerpoison(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then return end

    playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown or 24

    local isSuffering = false
    if isMoodleFrameWorkEnabled then
        if MF.getMoodle("MTAlcoholism"):getValue() <= 0.05 then 
            isSuffering = true 
        end
    else
        local hourThreshold = SandboxVars.MoreTraits.AlcoholicWithdrawal or 72
        if playerdata.iHoursSinceDrink > hourThreshold and not playerdata.bSatedDrink then 
            isSuffering = true 
        end
    end

    if isSuffering and playerdata.iWithdrawalCooldown <= 0 then
        print("Player is suffering from alcohol withdrawal.")
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicwithdrawal"), false, HaloTextHelper.getColorRed())

        if SandboxVars.MoreTraits.NonlethalAlcoholic then
            stats:set(CharacterStat.POISON, 20)
        else
            local hourThreshold = SandboxVars.MoreTraits.AlcoholicWithdrawal or 72
            local divider = 5
            if hourThreshold <= 2 then divider = 0.5
            elseif hourThreshold <= 5 then divider = 0.75
            elseif hourThreshold <= 10 then divider = 1
            elseif hourThreshold <= 20 then divider = 2
            elseif hourThreshold <= 24 then divider = 4
            elseif hourThreshold <= 48 then divider = 5
            end
            
            local poisonLevel = playerdata.iHoursSinceDrink / divider
            stats:set(CharacterStat.POISON, poisonLevel)
        end

        playerdata.iWithdrawalCooldown = ZombRand(12, 24)
    end

    if playerdata.iWithdrawalCooldown > 0 then
        playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown - 1
    end
end

function bouncerupdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.bouncer) then return end

    if playerdata.iBouncercooldown > 0 then playerdata.iBouncercooldown = playerdata.iBouncercooldown - 1 return end

    local chance = SandboxVars.MoreTraits.BouncerEffectiveness or 5
    local cooldown = SandboxVars.MoreTraits.BouncerCooldown or 60
    local distance = SandboxVars.MoreTraits.BouncerDistance or 1.75
    
    if player:hasTrait(ToadTraitsRegistries.lucky) then chance = chance + (luckimpact or 1) end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then chance = chance - (luckimpact or 1) end

    local enemies = player:getSpottedList()
    if enemies:size() < 3 then return end

    local closeEnemyCount = 0
    
    for i = 0, enemies:size() - 1 do
        local enemy = enemies:get(i)
        if enemy:isZombie() and enemy:DistTo(player) <= distance then
            closeEnemyCount = closeEnemyCount + 1
            if closeEnemyCount >= 3 then
                if not enemy:isKnockedDown() and ZombRand(0, 101) <= chance then
                    enemy:setStaggerBack(true)
                    playerdata.iBouncercooldown = cooldown
                    break
                end
            end
        end
    end
end

function martial(actor, target, weapon, damage)
    local player = getPlayer();
    if not player or actor ~= player then return end
    if not player:hasTrait(ToadTraitsRegistries.martial) then return end

    local playerdata = player:getModData();
    if not playerdata then return end 

    local stats = player:getStats();
    local endurance = stats:get(CharacterStat.ENDURANCE);
    local isBareHands = (weapon:getType() == "BareHands");
    
    local allow = true
    if not SandboxVars.MoreTraits.MartialWeapons and player:getPrimaryHandItem() ~= nil then allow = false; end
    
    if isBareHands and allow then
        local scaling = (SandboxVars.MoreTraits.MartialScaling or 100) * 0.01
        local strength = player:getPerkLevel(Perks.Strength)
        local fitness = player:getPerkLevel(Perks.Fitness)
        local blunt = player:getPerkLevel(Perks.SmallBlunt)
        local average = (strength + fitness) * 0.25
        local critchance = (5 + blunt) * scaling

        if player:hasTrait(ToadTraitsRegistries.lucky) then critchance = critchance + 1 * luckimpact end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then critchance = critchance - 1 * luckimpact end

        local damageAdj = 1.0
        if endurance < 0.25 then damageAdj = 0.25 
        elseif endurance < 0.5 then damageAdj = 0.5 
        elseif endurance < 0.75 then damageAdj = 0.75 
        end

        if target:isZombie() and ZombRand(0, 101) <= critchance and not player:hasTrait(ToadTraitsRegistries.mundane) then
            damage = damage * 4
        end

        damage = damage * 0.1 * damageAdj * scaling

        if MT_Config:getOption("MartialDamage"):getValue() then
            HaloTextHelper.addText(player, "Damage: " .. tostring(round(damage, 3)), " ", HaloTextHelper.getColorGreen())
        end

        target:setHealth(target:getHealth() - damage)
        if target:getHealth() <= 0 then target:Kill(player) end

        stats:set(CharacterStat.ENDURANCE, math.max(0, endurance - 0.002))
    end
end

--- Traits for ProBlade, ProBlunt and ProSpear --- 
function promelee(actor, target, weapon, damage)
    local player = getPlayer();
    if not player or actor ~= player then return end
    local hasBladeTrait = player:hasTrait(ToadTraitsRegistries.problade)
    local hasBluntTrait = player:hasTrait(ToadTraitsRegistries.problunt)
    local hasSpearTrait = player:hasTrait(ToadTraitsRegistries.prospear)
    if not hasBladeTrait and not hasBluntTrait and not hasSpearTrait then return end

    local weapondata = weapon:getModData();
    if not weapondata then return end

    local critchance = 5
    local matched = false
    if hasBladeTrait and (weapon:isOfWeaponCategory(WeaponCategory.AXE) or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE) or weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE)) then
        local axe = player:getPerkLevel(Perks.Axe);
        local blade = player:getPerkLevel(Perks.LongBlade);
        local smallBlade = player:getPerkLevel(Perks.SmallBlade);
        critchance = critchance + axe + blade + smallBlade
        matched = true
    elseif hasBluntTrait and (weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLUNT) or weapon:isOfWeaponCategory(WeaponCategory.BLUNT)) then
        local blunt = player:getPerkLevel(Perks.Blunt);
        local smallBlunt = player:getPerkLevel(Perks.SmallBlunt);
        critchance = critchance + blunt + smallBlunt
        matched = true
    elseif hasSpearTrait and (weapon:isOfWeaponCategory(WeaponCategory.SPEAR)) then
        local spear = player:getPerkLevel(Perks.Spear);
        critchance = critchance + spear
        matched = true
    end

    if not matched then return end

    if player:hasTrait(ToadTraitsRegistries.lucky) then critchance = critchance + 1 * luckimpact end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then critchance = critchance - 1 * luckimpact end

    if target:isZombie() and ZombRand(0, 101) <= critchance and not player:hasTrait(ToadTraitsRegistries.mundane) then
        damage = damage * 2;
    end

    local extraDamage = (damage * 1.2) * 0.1;
    target:setHealth(target:getHealth() - extraDamage);
    if target:getHealth() <= 0 then target:Kill(player) end

    if weapondata.iLastWeaponCond == nil then weapondata.iLastWeaponCond = weapon:getCondition(); end

    if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
        if weapon:getCondition() < weapon:getConditionMax() then
            weapon:setCondition(weapon:getCondition() + 1);
        end
    end
    weapondata.iLastWeaponCond = weapon:getCondition();
end

function progun(actor, weapon)
    local player = getPlayer();
    if not player or actor ~= player then return; end
    if not player:hasTrait(ToadTraitsRegistries.progun) then return end

    if not weapon then return end
    local weapondata = weapon:getModData();
    if not weapondata then return end
    
    if not weapon.getMaxAmmo or not weapon.getCurrentAmmoCount then return end
    
    local maxCapacity = weapon:getMaxAmmo();
    local currentCapacity = weapon:getCurrentAmmoCount();
    local aiming = player:getPerkLevel(Perks.Aiming);
    local reloading = player:getPerkLevel(Perks.Reloading);
    local chance = aiming + reloading + 10;
    
    local isFirearm = false;
    if weapon:isRanged() then isFirearm = true;
    elseif weapon.getSubCategory and weapon:getSubCategory() == "Firearm" then isFirearm = true;
    end

    if isFirearm then
        if player:hasTrait(ToadTraitsRegistries.lucky) then chance = chance + 1 * luckimpact end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then chance = chance - 1 * luckimpact end

        if weapondata.iLastWeaponCond == nil then weapondata.iLastWeaponCond = weapon:getCondition(); end
        if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
            if weapon:getCondition() < weapon:getConditionMax() then weapon:setCondition(weapon:getCondition() + 1); end
        end
        weapondata.iLastWeaponCond = weapon:getCondition();
        if SandboxVars.MoreTraits.ProwessGunsAmmoRestore == true and ZombRand(0, 101) <= chance then
            if currentCapacity < maxCapacity and currentCapacity > 0 then
                weapon:setCurrentAmmoCount(currentCapacity + 1);
                if MT_Config:getOption("ProwessGunsAmmo"):getValue() == true then
                    HaloTextHelper.addText(player, getText("UI_progunammo"), "", HaloTextHelper.getColorGreen());
                end
            end
        end
    end
end

function tavernbrawler(actor, target, weapon, damage)
    local player = getPlayer();
    if not player or actor ~= player then return; end
    if not player:hasTrait(ToadTraitsRegistries.tavernbrawler) then return end

    local weapondata = weapon:getModData();
    if not weapondata then return end

    local isImprovisedWeapon = false;
    local whitelist = { "ToolWeapon", "WeaponCrafted", "Cooking", "Household", "FirstAid", "Gardening", "Sports" };
    local displayCategory = weapon:getDisplayCategory() or "";
    if tableContains(whitelist, displayCategory) then isImprovisedWeapon = true;
    elseif weapon:isOfWeaponCategory(WeaponCategory.IMPROVISED) then isImprovisedWeapon = true; 
    end

    local chance = 50;
    local multiplier = 1;
    if isImprovisedWeapon then
        if weapon:isOfWeaponCategory(WeaponCategory.SPEAR) then
            chance = 0;
            multiplier = 0.25;
        end
            
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            chance = chance + (5 * luckimpact);
            multiplier = multiplier + 0.1;
        elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
            chance = chance - (5 * luckimpact);
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

        chance = math.min(95, chance)

        local extraDamage = (damage * multiplier) * 0.1;
        target:setHealth(target:getHealth() - extraDamage);
        if target:getHealth() <= 0 then target:Kill(player) end

        if weapondata.iLastWeaponCond == nil then weapondata.iLastWeaponCond = weapon:getCondition(); end
        if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= chance then
            if weapon:getCondition() < weapon:getConditionMax() then weapon:setCondition(weapon:getCondition() + 1); end
        end
        weapondata.iLastWeaponCond = weapon:getCondition();
    end
end

local UMBRELLA_TYPES = {
    ["UmbrellaRed"] = true, ["UmbrellaBlue"] = true, 
    ["UmbrellaWhite"] = true, ["UmbrellaBlack"] = true
}

function albino(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.albino) then return end

    local bodyDamage = player:getBodyDamage()
    local head = bodyDamage:getBodyPart(BodyPartType.Head)
    local modpain = playerdata.AlbinoTimeSpentOutside or 0
    
    if player:isOutside() then
        local tod = getGameTime():getTimeOfDay()
        if tod > 8 and tod < 17 then
            local stats = player:getStats()
            if stats:get(CharacterStat.PAIN) < 25 and not playerdata.bisAlbinoOutside then
                if MT_Config:getOption("AlbinoAnnounce"):getValue() == true then
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_albino"), false, HaloTextHelper.getColorRed())
                end
                playerdata.bisAlbinoOutside = true
            end

            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()
            local hasUmbrella = (primary and UMBRELLA_TYPES[primary:getType()]) or 
                                (secondary and UMBRELLA_TYPES[secondary:getType()])
            local pain = hasUmbrella and (modpain / 1.5) or modpain
            head:setAdditionalPain(pain)
        else
            if modpain > 0 then
                head:setAdditionalPain(modpain / 2)
            end
        end
    else
        playerdata.bisAlbinoOutside = false
        if modpain > 0 then
            head:setAdditionalPain(modpain / 4)
        end
    end
end

local function AlbinoTimer(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.albino) then return end
    playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside or 0
    
    if player:isOutside() then
        local tod = getGameTime():getTimeOfDay()
        if tod > 8 and tod < 17 then
            if playerdata.AlbinoTimeSpentOutside < 40 then
                local primary = player:getPrimaryHandItem()
                local secondary = player:getSecondaryHandItem()
                local hasUmbrella = (primary and UMBRELLAS[primary:getType()]) or 
                                    (secondary and UMBRELLAS[secondary:getType()])
                local increment = hasUmbrella and 0.5 or 1
                playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside + increment
            end
        elseif playerdata.AlbinoTimeSpentOutside >= 1 then
            playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside - 1
        end
    else
        if playerdata.AlbinoTimeSpentOutside > 0 then
            playerdata.AlbinoTimeSpentOutside = math.max(0, playerdata.AlbinoTimeSpentOutside - 2)
        end
    end
end

function amputee(player, justGotInfected)
    if not player:hasTrait(ToadTraitsRegistries.amputee) then return end
    if getActivatedMods():contains("Amputation") then return end;

    local handitem = player:getSecondaryHandItem();
    if handitem ~= nil and handitem:getType() ~= "BareHands" then 
        player:setSecondaryHandItem(nil);
       -- player:dropHandItems(); 
    end

    local bodyDamage = player:getBodyDamage();
    local parts = {
        bodyDamage:getBodyPart(BodyPartType.UpperArm_L),
        bodyDamage:getBodyPart(BodyPartType.ForeArm_L),
        bodyDamage:getBodyPart(BodyPartType.Hand_L)
    }

    for _, part in ipairs(parts) do
        if part:HasInjury() then
            part:RestoreToFullHealth();

            if justGotInfected then
                local stats = player:getStats();
                bodyDamage:setInfected(false);
                bodyDamage:setInfectionMortalityDuration(-1);
                bodyDamage:setInfectionTime(-1);
                stats:set(CharacterStat.ZOMBIE_FEVER, 0);
                stats:set(CharacterStat.ZOMBIE_INFECTION, 0);
            end
        end
    end
end

function actionhero(actor, target, weapon, damage)
    local player = getPlayer();
    if not player or actor ~= player then return; end
    if not weapon then return end;
    if not player:hasTrait(ToadTraitsRegistries.actionhero) then return; end

    if weapon:getType() == "BareHands" and not player:hasTrait(ToadTraitsRegistries.martial) then return end

    local enemies = player:getSpottedList();
    local critchance = 10;
    local multiplier = 0.1;
    local damage = damage * 0.5;

    if enemies and enemies:size() > 0 then
        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i);
            if enemy:isZombie() then
                local distance = enemy:DistTo(player)
                if distance < 2 then
                    critchance = critchance + 10;
                    multiplier = multiplier + 1.0;
                elseif distance < 5 then
                    critchance = critchance + 5;
                    multiplier = multiplier + 0.4;
                elseif distance < 10 then
                    critchance = critchance + 2;
                    multiplier = multiplier + 0.2;
                end
            end
        end
    end

    local luckmod = (luckimpact or 1.0)
    if player:hasTrait(ToadTraitsRegistries.lucky) then critchance = critchance + 5 * luckmod; end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then critchance = critchance - 5 * luckmod; end

    if target:isZombie() and ZombRand(0, 101) <= critchance and not player:hasTrait(ToadTraitsRegistries.mundane) then
        damage = damage * 5
    end

    local extraDamage = (damage * multiplier) * 0.1;
    target:setHealth(target:getHealth() - extraDamage);
    if target:getHealth() <= 0 then target:Kill(player) end
end

-- function gimp()
--     local player = getPlayer();
--     local playerdata = player:getModData();
--     local modifier = 0.85;
--     if player:hasTrait(ToadTraitsRegistries.gimp) and player:isLocalPlayer() then
--         if playerdata.fToadTraitsPlayerX ~= nil and playerdata.fToadTraitsPlayerY ~= nil then
--             local oldx = playerdata.fToadTraitsPlayerX;
--             local oldy = playerdata.fToadTraitsPlayerY;
--             local newx = player:getX();
--             local newy = player:getY();
--             local xdif = (newx - oldx);
--             local ydif = (newy - oldy);
--             if xdif > 5 or xdif < -5 or ydif > 5 or ydif < -5 then
--                 playerdata.fToadTraitsPlayerX = player:getX();
--                 playerdata.fToadTraitsPlayerY = player:getY();

--                 return
--             end
--             player:setX((oldx + xdif * modifier));
--             player:setY((oldy + ydif * modifier));
--         end
--         playerdata.fToadTraitsPlayerX = player:getX();
--         playerdata.fToadTraitsPlayerY = player:getY();
--     end
-- end

-- function fast()
--     local player = getPlayer();
--     local playerdata = player:getModData();
--     local vector = player:getMoveForwardVec();
--     local length = vector:getLength();
--     local modifier = 2.15;
--     if player:hasTrait(ToadTraitsRegistries.fast) then
--         if playerdata.fToadTraitsPlayerX ~= nil and playerdata.fToadTraitsPlayerY ~= nil then
--             local oldx = playerdata.fToadTraitsPlayerX;
--             local oldy = playerdata.fToadTraitsPlayerY;
--             local newx = player:getX();
--             local newy = player:getY();
--             local xdif = (newx - oldx);
--             local ydif = (newy - oldy);
--             if xdif > 5 or xdif < -5 or ydif > 5 or ydif < -5 then
--                 playerdata.fToadTraitsPlayerX = player:getX();
--                 playerdata.fToadTraitsPlayerY = player:getY();

--                 return
--             end
--             if xdif ~= 0 or xdif ~= 0 or ydif ~= 0 or ydif ~= 0 then
--                 player:setX((oldx + xdif * modifier));
--                 player:setY((oldy + ydif * modifier));
--                 playerdata.fToadTraitsPlayerX = player:getX();
--                 playerdata.fToadTraitsPlayerY = player:getY();
--             end
--         else
--             playerdata.fToadTraitsPlayerX = player:getX();
--             playerdata.fToadTraitsPlayerY = player:getY();
--         end
--     end
-- end

function checkBloodTraits(player)
    local isAnemic = player:hasTrait(ToadTraitsRegistries.anemic)
    local isThick = player:hasTrait(ToadTraitsRegistries.thickblood)
    if not isAnemic or not isThick then return end

    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getNumPartsBleeding() > 0 then
        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            if b:bleeding() and not b:IsBleedingStemmed() then
                local isNeck = (b:getType() == BodyPartType.Neck)
                local adjust = 2
                if isAnemic and isNeck then
                    local adjust = adjust * 0.1
                    b:ReduceHealth(adjust)
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_anemic"), false, HaloTextHelper.getColorRed())
                elseif isThick and isNeck then
                    local adjust = adjust * 0.002
                    b:AddHealth(adjust)
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickblood"), true, HaloTextHelper.getColorGreen())
                end
            end
        end
    end
end

function vehicleCheck(player)
    if getActivatedMods():contains("DrivingSkill") then return end

    if player:isDriving() then
        local vehicle = player:getVehicle();
        local vmd = vehicle:getModData();
        if vmd.fRegulatorSpeed == nil then vmd.bUpdated = nil; end
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
            if player:hasTrait(ToadTraitsRegistries.expertdriver) and vmd.sState ~= "ExpertDriver" then
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
            if player:hasTrait(ToadTraitsRegistries.poordriver) and vmd.sState ~= "PoorDriver" then
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
            if not player:hasTrait(ToadTraitsRegistries.expertdriver) and not player:hasTrait(ToadTraitsRegistries.poordriver) and vmd.sState ~= "Normal" then
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

local function SuperImmuneRecoveryProcess(player, playerdata)
    local SuperImmuneMinutesWellFed = playerdata.SuperImmuneMinutesWellFed;
    local SuperImmuneAbsoluteWellFedAmount = playerdata.SuperImmuneAbsoluteWellFedAmount;
    local MinutesPerDay = 1440;
    if player:hasTrait(ToadTraitsRegistries.superimmune) then
        if playerdata.SuperImmuneActive == true then
            local Illness = player:getBodyDamage():getFakeInfectionLevel();
            local Recovery = playerdata.SuperImmuneRecovery;
            local TimeElapsed = playerdata.SuperImmuneMinutesPassed;
            local maximum = 30;
            if SandboxVars.MoreTraits.SuperImmuneMaxDays then
                maximum = SandboxVars.MoreTraits.SuperImmuneMaxDays
            end
            if Recovery > maximum then
                Recovery = maximum;
            end
            local SpeedrunTime = 1;
            if SandboxVars.MoreTraits.QuickSuperImmune == true then
                SpeedrunTime = 6;
            end
            if Recovery * MinutesPerDay >= TimeElapsed then
                if playerdata.SuperImmuneTextSaid == true then
                    playerdata.SuperImmuneTextSaid = false;
                end
                if TimeElapsed > 360 then
                    if (Recovery * MinutesPerDay) / 2 >= TimeElapsed then
                        Illness = Illness - (((25 - ZombRand(10, 46)) / 600) * SpeedrunTime); --You can decrease illness up to 1.5 or increase it up to 2 per hour
                    else
                        --Once half the required time passes, your immunity system starts gaining victory
                        Illness = Illness - (((25 - ZombRand(5, 36)) / 600) * SpeedrunTime); -- You can decrease illness up to 2 or increase it up to 1 per hour
                    end --The random illness reduction and gain is to simulate your immune system fighting the virus.
                else
                    Illness = Illness + ((ZombRand(100, 501) / 6000) * SpeedrunTime); --Immune system doesn't notice the virus until 6 hours in
                end
                if player:hasTrait(CharacterTrait.FAST_HEALER) then
                    Illness = Illness - ((0.25 / 60) * SpeedrunTime);
                end
                if player:hasTrait(CharacterTrait.SLOW_HEALER) then
                    Illness = Illness + ((0.25 / 60) * SpeedrunTime);
                end
                if Illness < 26 then
                    --Prevent illness from going too low or too high
                    Illness = Illness + (0.166 * SpeedrunTime);
                end
                if Illness > 89 and playerdata.SuperImmuneLethal == false then
                    Illness = Illness - (0.333 * SpeedrunTime);
                end
                playerdata.SuperImmuneMinutesPassed = playerdata.SuperImmuneMinutesPassed + (1 * SpeedrunTime);
                playerdata.SuperImmuneAbsoluteWellFedAmount = SuperImmuneAbsoluteWellFedAmount + SuperImmuneMinutesWellFed;
                Illness = Illness - (playerdata.SuperImmuneMinutesWellFed / 50);
                playerdata.SuperImmuneMinutesWellFed = 0;
                player:getBodyDamage():setFakeInfectionLevel(Illness);
                if playerdata.SuperImmuneAbsoluteWellFedAmount > 60 then
                    playerdata.SuperImmuneMinutesPassed = playerdata.SuperImmuneMinutesPassed + (1 * SpeedrunTime);
                    playerdata.SuperImmuneAbsoluteWellFedAmount = SuperImmuneAbsoluteWellFedAmount - 60;
                end
                if isDebugEnabled() then
                    player:Say("Time to recovery: " .. (Recovery * 1440 - TimeElapsed) .. " minutes, or " .. (Recovery * 24 - math.floor(TimeElapsed / 60)) .. " hours");
                end
            else
                if Illness > 0 or Illness ~= 0 then
                    --Recover from illness completely over-time once recovery time ends.
                    if player:hasTrait(CharacterTrait.FAST_HEALER) then
                        Illness = Illness - (1.5 / 60); --0.7 to 2.5 days
                    elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
                        Illness = Illness - (0.75 / 60); --1.4 to 5 days
                    else
                        Illness = Illness - (1 / 60); --1 to 3.7 days
                    end
                    player:getBodyDamage():setFakeInfectionLevel(Illness);
                    playerdata.SuperImmuneInfections = 0;
                else
                    --Once illness fully recovers
                    if MT_Config:getOption("SuperImmuneAnnounce"):getValue() == true then
                        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fullheal"), true, HaloTextHelper.getColorGreen());
                    end
                    playerdata.SuperImmuneTextSaid = false;
                    playerdata.SuperImmuneActive = false;
                    playerdata.SuperImmuneMinutesPassed = 0;
                    playerdata.SuperImmuneRecovery = 0;
                    playerdata.SuperImmuneHealedOnce = true;
                    playerdata.SuperImmuneAbsoluteWellFedAmount = 0;
                    playerdata.SuperImmuneInfections = 0;
                    playerdata.SuperImmuneLethal = false;
                end
                if MT_Config:getOption("SuperImmuneAnnounce"):getValue() == true and playerdata.SuperImmuneTextSaid == false then
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_superimmunewon"), true, HaloTextHelper.getColorGreen());
                    playerdata.SuperImmuneTextSaid = true;
                end
            end
        end
    end
end

function SuperImmune(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) then return end

    local bodyDamage = player:getBodyDamage();

    if bodyDamage:isInfected() then
        local stats = player:getStats();
        bodyDamage:setInfected(false);
        bodyDamage:setInfectionMortalityDuration(-1);
        bodyDamage:setInfectionTime(-1);
        stats:set(CharacterStat.ZOMBIE_FEVER, 0);
        stats:set(CharacterStat.ZOMBIE_INFECTION, 0);

        local minimum = SandboxVars.MoreTraits.SuperImmuneMinDays or 10;
        local maximum = SandboxVars.MoreTraits.SuperImmuneMaxDays or 30;
        if minimum > maximum then minimum, maximum = maximum, minimum end

        local timeOfRecovery = 0;
        if minimum == maximum + 1 then timeOfRecovery = minimum;
        else timeOfRecovery = ZombRand(minimum, maximum + 1);
        end

        if player:hasTrait(CharacterTrait.FAST_HEALER) then timeOfRecovery = timeOfRecovery - 5; end
        if player:hasTrait(CharacterTrait.SLOW_SLOWER) then timeOfRecovery = timeOfRecovery + 5; end
        if player:hasTrait(ToadTraitsRegistries.lucky) then timeOfRecovery = timeOfRecovery - 2 * luckimpact; end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then timeOfRecovery = timeOfRecovery + 2 * luckimpact; end
        
        timeOfRecovery = math.max(minimum, math.min(maximum, timeOfRecovery))

        if playerdata.SuperImmuneHealedOnce and playerdata.SuperImmuneFirstInfectionBonus then
            --Halve the time needed once it beat the virus once, since immune system
            timeOfRecovery = timeOfRecovery / 2; --will know how to beat it.
        end

        playerdata.SuperImmuneActive = true
        playerdata.SuperImmuneRecovery = (playerdata.SuperImmuneRecovery or 0) + timeOfRecovery

        if SandboxVars.MoreTraits.SuperImmuneWeakness then
            playerdata.SuperImmuneInfections = playerdata.SuperImmuneInfections + 1;
        end
    end

    local parts = bodyDamage:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i);
        if b:HasInjury() and b:isInfectedWound() then
            b:SetInfected(false);
            b:setInfectedWound(false);
        end
    end
end

local function SuperImmuneFakeInfectionHealthLoss(player, playerdata)
    local MaxHealth = 10;
    local Health = player:getBodyDamage():getOverallBodyHealth();
    local Stress = player:getStats():get(CharacterStat.STRESS);
    local Illness = player:getStats():get(CharacterStat.SICKNESS);
    local stop = false;
    if player:hasTrait(ToadTraitsRegistries.superimmune) then
        if playerdata.SuperImmuneActive then
            if player:hasTrait(ToadTraitsRegistries.indefatigable) then
                MaxHealth = 22;
            end
            if SandboxVars.MoreTraits.SuperImmuneWeakness == true then
                local limit = 4;
                if playerdata.SuperImmuneHealedOnce == true then
                    limit = 5;
                end
                if player:hasTrait(CharacterTrait.FAST_HEALER) then
                    limit = limit + 1;
                elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
                    limit = limit - 1;
                end
                if playerdata.SuperImmuneInfections >= limit then
                    MaxHealth = 0;
                    playerdata.SuperImmuneLethal = true;
                else
                    playerdata.SuperImmuneLethal = false;
                end
            end
            if Health >= 100 - Illness and Health > MaxHealth then
                for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                    local b = player:getBodyDamage():getBodyParts():get(i);
                    if Health >= (100 - Illness) * 1.5 then
                        b:AddDamage(0.2 * GameSpeedMultiplier()); --Simulate Max Health Loss
                        stop = true;
                    end
                    if stop == false then
                        if Illness < 25 then
                            b:AddDamage(0.002 * GameSpeedMultiplier());
                        end
                        if Illness > 25 and Illness < 50 then
                            b:AddDamage(0.005 * GameSpeedMultiplier());
                        end
                        if Illness >= 50 then
                            b:AddDamage(0.01 * GameSpeedMultiplier());
                        end
                        if Illness >= 50 and Health > 60 then
                            b:AddDamage(0.1 * GameSpeedMultiplier()); --Rapidly lose health if it is too high, to prevent sleep abuse in order to stay healthy
                        end
                    end
                end
            end
            if Illness > 10 then
                if internalTick >= 25 and Stress <= Illness * 3 then
                    player:getStats():set(CharacterStat.STRESS, Stress + 0.001 * GameSpeedMultiplier());
                end
            end
        end
    end
end

function Immunocompromised(player)
    if not player:hasTrait(ToadTraitsRegistries.immunocompromised) then return end

    local bodyDamage = player:getBodyDamage();
    local parts = bodyDamage:getBodyParts();

    for i = 0, parts:size() - 1 do
        local b = parts:get(i);
        if b:HasInjury() and b:isInfectedWound() and b:getAlcoholLevel() <= 0 then
            b:setWoundInfectionLevel(b:getWoundInfectionLevel() + 0.001);
        end
    end
end

local crossRefMods = {
    ["DracoExpandedTraits"] = "EventHandlers",
}
local loadedModIDs = {}
local activeModIDs = getActivatedMods()
for i = 1, activeModIDs:size() do
    local modID = activeModIDs:get(i - 1)
    if crossRefMods[modID] then
        require(crossRefMods[modID])
        loadedModIDs[modID] = true
    end
end

function MT_checkWeight(player)
    local player = getPlayer();
    if not player then return end;

    local strength = player:getPerkLevel(Perks.Strength);
    local muleBase = SandboxVars.MoreTraits.WeightPackMule or 10;
    local mouseBase = SandboxVars.MoreTraits.WeightPackMouse or 6;
    local defaultBase = SandboxVars.MoreTraits.WeightDefault or 8;
    local global = SandboxVars.MoreTraits.WeightGlobalMod or 0;
    local targetWeight = 0;

    if player:hasTrait(ToadTraitsRegistries.packmule) then targetWeight = muleBase + math.floor(strength / 5);
    elseif player:hasTrait(ToadTraitsRegistries.packmouse) then targetWeight = mouseBase;
    else targetWeight = defaultBase; end

    if getActivatedMods():contains("DracoExpandedTraits") and player:hasTrait(DracoExpandedTraits.Hoarder) then
        player:setMaxWeightBase(math.floor(player:getMaxWeightBase() * 1.25))
    end

    targetWeight = targetWeight + global;

    if targetWeight > 50 then targetWeight = 50; end
    player:setMaxWeightBase(targetWeight)
end

function graveRobber(_zombie)
    local player = getPlayer();
    if not player or not player:hasTrait(ToadTraitsRegistries.graverobber) then return end

    local zombie = _zombie;
    if not zombie then return end;

    local graveRobberLootTable = {
        { chance = 10, items = { "Base.Apple", "Base.Avocado", "Base.Banana", "Base.BellPepper", "Base.BeerCan", "Base.BeefJerky", "Base.Bread", "Base.Broccoli", "Base.Butter", "Base.CandyPackage", "Base.TinnedBeans", "Base.CannedCarrots2", "Base.CannedChili", "Base.CannedCorn", "Base.CannedCornedBeef", "CannedMushroomSoup", "Base.CannedPeas", "Base.CannedPotato2", "Base.CannedSardines", "Base.CannedTomato2", "Base.TunaTin" } },
        { chance = 20, items = { "Base.PillsAntiDep", "Base.AlcoholWipes", "Base.AlcoholedCottonBalls", "Base.Pills", "Base.PillsSleepingTablets", "Base.Tissue", "Base.ToiletPaper", "Base.PillsVitamins", "Base.Bandaid", "Base.Bandage", "Base.CottonBalls", "Base.Splint", "Base.AlcoholBandage", "Base.AlcoholRippedSheets", "Base.SutureNeedle", "Base.Tweezers", "Base.WildGarlicCataplasm", "Base.ComfreyCataplasm", "Base.PlantainCataplasm", "Base.Disinfectant" } },
        { chance = 30, items = { "Base.223Box", "Base.308Box", "Base.Bullets38Box", "Base.Bullets44Box", "Base.Bullets45Box", "Base.556Box", "Base.Bullets9mmBox", "Base.ShotgunShellsBox", "Base.DoubleBarrelShotgun", "Base.Shotgun", "Base.ShotgunSawnoff", "Base.Pistol", "Base.Pistol2", "Base.Pistol3", "Base.AssaultRifle", "Base.AssaultRifle2", "Base.VarmintRifle", "Base.HuntingRifle", "Base.556Clip", "Base.M14Clip", "Base.308Clip", "Base.223Clip", "Base.44Clip", "Base.45Clip", "Base.9mmClip", "Base.Revolver_Short", "Base.Revolver_Long", "Base.Revolver" } },
        { chance = 40, items = { "Base.Aerosolbomb", "Base.Axe", "Base.BaseballBat", "Base.SpearCrafted", "Base.Crowbar", "Base.FlameTrap", "Base.HandAxe", "Base.HuntingKnife", "Base.Katana", "Base.PipeBomb", "Base.Sledgehammer", "Base.Shovel", "Base.SmokeBomb", "Base.WoodAxe", "Base.GardenFork", "Base.WoodenLance", "Base.SpearBreadKnife", "Base.SpearButterKnife", "Base.SpearFork", "Base.SpearLetterOpener", "Base.SpearScalpel", "Base.SpearSpoon", "Base.SpearScissors", "Base.SpearHandFork", "Base.SpearScrewdriver", "Base.SpearHuntingKnife", "Base.SpearMachete", "Base.SpearIcePick", "Base.SpearKnife", "Base.Machete", "Base.GardenHoe" } },
        { chance = 50, items = { "Base.Bag_SurvivorBag", "Base.Bag_BigHikingBag", "Base.Bag_DuffelBag", "Base.Bag_FannyPackFront", "Base.Bag_NormalHikingBag", "Base.Bag_ALICEpack", "Base.Bag_ALICEpack_Army", "Base.Bag_Schoolbag", "Base.SackOnions", "Base.SackPotatoes", "Base.SackCarrots", "Base.SackCabbages" } },
        { chance = 60, items = { "Base.Hat_SPHhelmet", "Base.Jacket_CoatArmy", "Base.Hat_BalaclavaFull", "Base.Hat_BicycleHelmet", "Base.Shoes_BlackBoots", "Base.Hat_CrashHelmet", "Base.HolsterDouble", "Base.Hat_Fireman", "Base.Jacket_Fireman", "Base.Trousers_Fireman", "Base.Hat_FootballHelmet", "Base.Hat_GasMask", "Base.Ghillie_Trousers", "Base.Ghillie_Top", "Base.Gloves_LeatherGloves", "Base.JacketLong_Random", "Base.Shoes_ArmyBoots", "Base.Vest_BulletArmy", "Base.Hat_Army", "Base.Hat_HardHat_Miner", "Base.Hat_NBCmask", "Base.Vest_BulletPolice", "Base.Hat_RiotHelmet", "Base.AmmoStrap_Shells" } },
        { chance = 70, items = { "Base.CarBattery1", "Base.CarBattery2", "Base.CarBattery3", "Base.Extinguisher", "Base.PetrolCan", "Base.ConcretePowder", "Base.PlasterPowder", "Base.BarbedWire", "Base.Log", "Base.SheetMetal", "Base.MotionSensor", "Base.ModernTire1", "Base.ModernTire2", "Base.ModernTire3", "Base.ModernSuspension1", "Base.ModernSuspension2", "Base.ModernSuspension3", "Base.ModernCarMuffler1", "Base.ModernCarMuffler2", "Base.ModernCarMuffler3", "Base.ModernBrake1", "Base.ModernBrake2", "Base.ModernBrake3", "Base.smallSheetMetal", "Base.Speaker", "Base.EngineParts", "Base.LogStacks2", "Base.LogStacks3", "Base.LogStacks4", "Base.NailsBox" } },
        { chance = 80, items = { "Base.ComicBook", "Base.ElectronicsMag4", "Base.HerbalistMag", "Base.MetalworkMag1", "Base.MetalworkMag2", "Base.MetalworkMag3", "Base.MetalworkMag4", "Base.HuntingMag1", "Base.HuntingMag2", "Base.HuntingMag3", "Base.FarmingMag1", "Base.MechanicMag1", "Base.MechanicMag2", "Base.MechanicMag3", "Base.CookingMag1", "Base.CookingMag2", "Base.EngineerMagazine1", "Base.EngineerMagazine2", "Base.ElectronicsMag1", "Base.ElectronicsMag2", "Base.ElectronicsMag3", "Base.ElectronicsMag5", "Base.FishingMag1", "Base.FishingMag2", "Base.Book", "MoreTraits.MedicalMag1", "MoreTraits.MedicalMag2", "MoreTraits.MedicalMag3", "MoreTraits.MedicalMag4", "MoreTraits.AntiqueMag1", "MoreTraits.AntiqueMag2", "MoreTraits.AntiqueMag3" } },
        { chance = 90, items = { "Base.DumbBell", "Base.EggCarton", "Base.HomeAlarm", "Base.HotDog", "Base.HottieZ", "Base.Icecream", "Base.Machete", "Base.Revolver_Long", "Base.MeatPatty", "Base.Milk", "Base.MuttonChop", "Base.Padlock", "Base.PorkChop", "Base.Wine", "Base.Wine2", "Base.Whiskey", "Base.Ham" } },
        { chance = 95, items = { "Base.PropaneTank", "Base.BlowTorch", "Base.Woodglue", "Base.DuctTape", "Base.Rope", "Base.Extinguisher" } },
        { chance = 100, items = { "Base.Spiffo", "Base.SpiffoSuit", "Base.Hat_Spiffo", "Base.SpiffoTail", "Base.Generator" } },
    }

    local sandboxChance = SandboxVars.MoreTraits.GraveRobberChance or 1.0
    local chance = sandboxChance * 10;    
    local luckmod = (luckimpact or 1.0)

    if player:hasTrait(ToadTraitsRegistries.lucky) then chance = chance + (2 * luckmod) end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then chance = chance - (2 * luckmod) end
    if player:hasTrait(ToadTraitsRegistries.scrounger) then chance = chance + 2 end
    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then chance = chance - 2 end
    
    chance = math.max(1, chance)

    if ZombRand(0, 1001) <= chance then
        if MT_Config:getOption("GraveRobberAnnounce"):getValue() == true then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen());
        end

        local inv = zombie:getInventory();
        local extraLoot = SandboxVars.MoreTraits.GraveRobberGuaranteedLoot or 1;
        local itterations = ZombRand(0, 3) + extraLoot
        
        for i = 1, itterations do
            local roll = ZombRand(0, 101);
            for _, entry in ipairs(graveRobberLootTable) do
                if roll <= entry.chance then
                    local selection = entry.items[ZombRand(#entry.items) + 1]
                    local item = inv:AddItem(selection)
                    if item then inv:addItemOnServer(item) end
                    break;
                end
            end
        end
    end
end

function Gourmand(_iSInventoryPage, _state, _player)
    local player = _player;
    local containerObj;
    local container;
    if player:hasTrait(ToadTraitsRegistries.gourmand) then
        local basechance = 33;
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            basechance = basechance + 10 * (luckimpact or 1.0);
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            basechance = basechance - 10 * (luckimpact or 1.0);
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
                                        if MT_Config:getOption("GourmandAnnounce"):getValue() == true then
                                            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gourmand") .. ": " .. newitem:getName(), true, HaloTextHelper.getColorGreen());
                                        end
                                    end
                                elseif item:isFresh() == false then
                                    if ZombRand(100) <= basechance then
                                        local newitem = container:AddItem(item:getFullType());
                                        container:addItemOnServer(newitem);
                                        container:Remove(item);
                                        container:removeItemOnServer(item);
                                        if MT_Config:getOption("GourmandAnnounce"):getValue() == true then
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
    elseif curState == "Gourmand" and player:hasTrait(ToadTraitsRegistries.gourmand) == false or curState == "Ascetic" and player:hasTrait(ToadTraitsRegistries.ascetic) == false then
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

function FoodUpdate(player)
    local plyinv = player:getInventory()
    local items = plyinv:getItems()
    local itemCount = items:size()
    
    local state = "Normal"
    if player:hasTrait(ToadTraitsRegistries.gourmand) then
        state = "Gourmand"
    elseif player:hasTrait(ToadTraitsRegistries.ascetic) then
        state = "Ascetic"
    end

    for i = 0, itemCount - 1 do
        local item = items:get(i)
        if item and item:getCategory() == "Food" then
            setFoodState(item, state, player)
        end
    end
end

function FearfulUpdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.fearful) then return end

    local stats = player:getStats()
    local panic = stats:get(CharacterStat.PANIC)

    if panic > 5 then
        local chance = 3 + (panic / 10);

        if player:hasTrait(CharacterTrait.COWARDLY) then chance = chance + 1 end
        if player:hasTrait(ToadTraitsRegistries.lucky) then chance = chance - (luckimpact or 1.0) end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then chance = chance + (luckimpact or 1.0) end

        if ZombRand(0, 1000) <= chance then
            local text = ""
            local radius = 0
            local volume = 0

            if panic <= 25 then
                text = "UI_fearful_slightpanic"
                radius, volume = 5, 10
            elseif panic <= 50 then
                text = "UI_fearful_panic"
                radius, volume = 10, 15
            elseif panic <= 75 then
                text = "UI_fearful_strongpanic"
                radius, volume = 20, 25
            else
                text = "UI_fearful_extremepanic"
                radius, volume = 25, 50
            end
            player:Say(getText(text))
            addSound(player, player:getX(), player:getY(), player:getZ(), radius, volume)

            if getActivatedMods():contains("ToadTraitsDynamic") then
                playerdata.MTDFearfulCount = (playerdata.MTDFearfulCount or 0) + 1
            end
        end
    end
end

function GymGoer(player, perk, amount)
    local playerData = player:getModData()
    if not playerdata then return end;
    if playerData.GymGoerProcessing then return end

    if player:hasTrait(ToadTraitsRegistries.gymgoer) and (perk == Perks.Fitness or perk == Perks.Strength) and player:getCurrentState() == FitnessState.instance() then
        playerData.GymGoerProcessing = true

        local modifier = SandboxVars.MoreTraits.GymGoerPercent or 200
        local bonusMultiplier = ((modifier * 0.01) - 1) * 0.1
        local bonusAmount = amount * bonusMultiplier

        AddXP(player, perk, bonusAmount)

        playerData.GymGoerProcessing = false
    end
end

function GymGoerUpdate(player, playerdata)
    local trait = player:hasTrait(ToadTraitsRegistries.gymgoer)
    local noExerciseFatigue = SandboxVars.MoreTraits.GymGoerNoExerciseFatigue
    if not (trait and noExerciseFatigue) then return end;

    local bodyDamage = player:getBodyDamage();
    local fitness = player:getFitness();

    if not playerdata.GymGoerStiffnessList then
        playerdata.GymGoerStiffnessList = {0, 0, 0, 0}
    end

    local stiffnessList = playerdata.GymGoerStiffnessList
    local muscleGroups = {
        [1] = { 
            val = fitness:getCurrentExeStiffnessInc("arms"), 
            parts = { BodyPartType.UpperArm_L, BodyPartType.UpperArm_R, BodyPartType.ForeArm_L, BodyPartType.ForeArm_R, BodyPartType.Hand_L, BodyPartType.Hand_R } 
        },
        [2] = { 
            val = fitness:getCurrentExeStiffnessInc("legs"), 
            parts = { BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R, BodyPartType.LowerLeg_L, BodyPartType.LowerLeg_R } 
        },
        [3] = { 
            val = fitness:getCurrentExeStiffnessInc("chest"), 
            parts = { BodyPartType.Torso_Upper } 
        },
        [4] = { 
            val = fitness:getCurrentExeStiffnessInc("abs"), 
            parts = { BodyPartType.Torso_Lower } 
        }
    }

    for i, group in ipairs(muscleGroups) do
        local currentStiffness = group.val
        local recordedStiffness = stiffnessList[i]

        if currentStiffness > recordedStiffness or currentStiffness == 0 then
            stiffnessList[i] = currentStiffness
        elseif currentStiffness < (recordedStiffness / 2) then
            for _, partType in ipairs(group.parts) do
                bodyDamage:getBodyPart(partType):setStiffness(0)
            end
        end
    end
end

function ContainerEvents(_iSInventoryPage, _state)
    local page = _iSInventoryPage;
    local state = _state;
    if state == "end" then
        local player = getPlayer();
        if not player then return end;
        local playerdata = player:getModData();
        if not playerdata then return end;

        ToadTraitIncomprehensive(page, state, player);
        ToadTraitScrounger(page, state, player);
        ToadTraitVagabond(page, state, player, playerdata);
        Gourmand(page, state, player);
        ToadTraitAntique(page, state, player, playerdata);
    end
end

function MT_LearnAllRecipes(player)
    local recipes = getScriptManager():getAllCraftRecipes()
    local ingenuitveLimit = SandboxVars.MoreTraits.IngenuitiveLimit
    
    if ingenuitveLimit then
        local unknownRecipes = {}
        local percentToLearn = (SandboxVars.MoreTraits.IngenuitiveLimitAmount or 50) * 0.01

        for i = 0, recipes:size() - 1 do
            local recipe = recipes:get(i)
            if recipe:needToBeLearn() then
                table.insert(unknownRecipes, recipe:getName())
            end
        end

        local totalUnknown = #unknownRecipes
        if totalUnknown > 0 then
            local targetAmount = math.floor(totalUnknown * percentToLearn)
            local learnedCount = 0
            
            while learnedCount < targetAmount and #unknownRecipes > 0 do
                local randomIndex = ZombRand(1, #unknownRecipes + 1)
                local recipeName = table.remove(unknownRecipes, randomIndex)
                
                player:learnRecipe(recipeName)
                learnedCount = learnedCount + 1
            end
        end
    else
        for i = 0, recipes:size() - 1 do
            local recipe = recipes:get(i)
            if recipe:needToBeLearn() then
                player:learnRecipe(recipe:getName())
            end
        end
    end
end

function UpdateWorkerSpeed(player)
    if not player:hasTimedActions() then return end

    local actions = player:getCharacterActions()
    local action = actions:get(0)
    if not action then return end

    local type = action:getMetaType()
    local delta = action:getJobDelta()
    
    local blacklist = { "ISWalkToTimedAction", "ISPathFindAction", "PlayInstrumentAction", "" }
    if tableContains(blacklist, type) or delta <= 0 or delta >= 0.99 then return end

    local isQuick = player:hasTrait(ToadTraitsRegistries.quickworker)
    local isSlow = player:hasTrait(ToadTraitsRegistries.slowworker)
    if not (isQuick or isSlow) then return end

    local modifier = 0.5
    local multiplier = getGameTime():getMultiplier()
    
    if isQuick and SandboxVars.MoreTraits.QuickWorkerScaler then modifier = modifier * (SandboxVars.MoreTraits.QuickWorkerScaler * 0.01)
    elseif isSlow and SandboxVars.MoreTraits.SlowWorkerScaler then modifier = modifier end

    local luckImpact = (luckimpact or 1.0)
    local traitModiifer = 0

    if player:hasTrait(ToadTraitsRegistries.lucky) and ZombRand(100) <= 10 then traitModiifer = 0.25 * luckImpact
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) and ZombRand(100) <= 10 then traitModiifer = -0.25 * luckImpact end

    if player:hasTrait(CharacterTrait.DEXTROUS) and ZombRand(100) <= 10 then traitModiifer = traitModiifer + 0.25
    elseif player:hasTrait(CharacterTrait.ALL_THUMBS) and ZombRand(100) <= 10 then traitModiifer = traitModiifer - 0.25 end

    if isQuick then modifier = modifier + traitModiifer
    else modifier = modifier + (traitModiifer * - 1) end

    if type == "ISReadABook" then
        if player:hasTrait(CharacterTrait.FAST_READER) then modifier = modifier * (isQuick and 5 or 0.1)
        elseif player:hasTrait(CharacterTrait.SLOW_READER) then modifier = modifier * (isQuick and 1.5 or 0.5)
        else modifier = modifier * (isQuick and 3 or 0.25) end
    end

    modifier = math.max(0, modifier)
    
    if isQuick then
        action:setCurrentTime(action:getCurrentTime() + (modifier * multiplier))
    elseif isSlow then
        local chance = SandboxVars.MoreTraits.SlowWorkerScaler or 15
        if ZombRand(100) <= chance then action:setCurrentTime(action:getCurrentTime() - modifier) end
    end
end

function LeadFoot(player)
    if not player:hasTrait(ToadTraitsRegistries.leadfoot) then return end

    local shoes = player:getClothingItem_Feet();
    if not shoes then return end

    local itemdata = shoes:getModData();
    if not itemData then return end

    if itemdata.origStomp == nil then
        itemdata.origStomp = shoes:getStompPower();
        itemdata.stompState = "Normal";
    end

    if itemdata.stompState ~= "LeadFoot" then
        local newstomp = (itemdata.origStomp * 2) + 1;
        shoes:setStompPower(newstomp);
        itemdata.stompState = "LeadFoot";
    end
end

function GlassBody(player, playerData)
    local bodyDamage = player:getBodyDamage();
    local currenthp = bodyDamage:getOverallBodyHealth();
    local multiplier = getGameTime():getMultiplier();
    local playerData = player:getModData();

    if playerData.glassBodyLastHP == nil then
        playerData.glassBodyLastHP = currenthp;
        playerData.glassBodyInitialized = true;
        return;
    end

    if playerData.glassBodyInitialized == true then
        playerData.glassBodyInitialized = false;
        playerData.glassBodyLastHP = currenthp; -- Update to current HP
        return;
    end

    if player:isAsleep() or multiplier > 4.0 then
        playerData.glassBodyLastHP = currenthp;
        return;
    end

    local lasthp = playerData.glassBodyLastHP;
    
    if currenthp < lasthp then
        local difference = lasthp - currenthp;
        if difference > 50 then
            playerData.glassBodyLastHP = currenthp;
            return;
        end

        local chance = 33;
        local woundstrength = 10;
        
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            chance = chance - (5 * luckimpact);
            woundstrength = woundstrength - (5 * luckimpact);
        elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
            chance = chance + (5 * luckimpact);
            woundstrength = woundstrength + (5 * luckimpact);
        end
        
        chance = math.max(5, math.min(95, chance));
        woundstrength = math.max(5, math.min(25, woundstrength));

        local extraDamageMultiplier = 2;
        bodyDamage:ReduceGeneralHealth(difference * extraDamageMultiplier);
        
        if ZombRand(100) <= chance then
            local partIndex = ZombRand(0, 17);
            local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(partIndex));
            if bodyPart then
                if difference > 0.33 then
                    local fracture = bodyPart:getFractureTime();
                    if not fracture or fracture <= 0 then
                        bodyPart:setFractureTime(ZombRand(20) + woundstrength);
                    end
                elseif difference > 0.1 then
                    bodyPart:setScratched(true, true);
                end
            end
        end
    end
    playerData.glassBodyLastHP = bodyDamage:getOverallBodyHealth();
end

function BatteringRam(player, playerData)
    if not player or not player:hasTrait(ToadTraitsRegistries.batteringram) then return end

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    local bodyParts = {
        BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R, BodyPartType.LowerLeg_L,
        BodyPartType.LowerLeg_R, BodyPartType.Foot_L, BodyPartType.Foot_R
    }
    local isInjured = false
    for _, partType in ipairs(bodyParts) do
        local part = bodyDamage:getBodyPart(partType)
        if part and part:getFractureTime() > 0 then
            isInjured = true
            break
        end
    end

    if player:isSprinting() and not isInjured then
        local enemies = player:getSpottedList()
        local nearbyZombies = false
        
        if enemies then
            for i = 0, enemies:size() - 1 do
                local enemy = enemies:get(i)
                if enemy and enemy:isZombie() and enemy:DistTo(player) <= 2 then
                    nearbyZombies = true; break
                end
            end
        end

        local inTree = player:getCurrentSquare():has(IsoObjectType.tree) or false

        if nearbyZombies and not inTree then
            player:setGhostMode(true)
            playerData.batteringRamActive = true
        else
            player:setGhostMode(false)
            playerData.batteringRamActive = false
        end

        if nearbyZombies and enemies then
            local fitness = math.max(1, player:getPerkLevel(Perks.Fitness))
            local enduranceReduction = (10 / fitness) * 0.01
            local endurance = stats:get(CharacterStat.ENDURANCE)

            for i = 0, enemies:size() - 1 do
                local enemy = enemies:get(i)
                if enemy and enemy:isZombie() then
                    local distance = enemy:DistTo(player)
                    local enemyData = enemy:getModData()
                    local timestamp = getTimestamp()
                    local canBeHit = not enemyData.lastRamTime or (timestamp > enemyData.lastRamTime + 5)

                    if distance <= 1.0 and canBeHit and not enemy:isKnockedDown() then
                        enemy:setKnockedDown(true)
                        enemy:setStaggerBack(true)
                        enemy:setHitReaction("")
                        enemy:setPlayerAttackPosition("FRONT")
                        enemy:setHitForce(2.0)
                        enemy:reportEvent("wasHit")
                        enemyData.lastRamTime = timestamp
                        
                        endurance = math.max(0, endurance - enduranceReduction)
                        stats:set(CharacterStat.ENDURANCE, endurance)

                        if player:hasTrait(ToadTraitsRegistries.martial) and SandboxVars.MoreTraits.BatteringRamMartialCombo then
                            local hasWeapon = player:getPrimaryHandItem() ~= nil
                            if SandboxVars.MoreTraits.MartialWeapons or not hasWeapon then
                                local damageMult = 1.0
                                local finalDamage = 0
                                if endurance < 0.25 then damageMult = 0.25
                                elseif endurance < 0.5 then damageMult = 0.5
                                elseif endurance < 0.75 then damageMult = 0.75 end
                                finalDamage = (ZombRand(10, 61) / 100) * damageMult
                                enemy:setHealth(enemy:getHealth() - finalDamage)
                                if enemy:getHealth() <= 0 then enemy:Kill(player) end
                            end                            
                        end
                    end
                end
            end
        end
    else
        if playerData.batteringRamActive then
            player:setGhostMode(false)
            playerData.batteringRamActive = false
        end
    end
end

local function mundane(actor, target, weapon, damage)
    if not weapon then return end
    local player = getPlayer()
    if not player or actor ~= player then return; end
    local weapondata = weapon:getModData()
    if not weapondata then return end

    if weapondata.origCritChance == nil then weapondata.origCritChance = weapon:getCriticalChance() end

    if player:hasTrait(ToadTraitsRegistries.mundane) then
        weapon:setCriticalChance(1) 
    else
        if weapon:getCriticalChance() ~= weapondata.origCritChance then
            weapon:setCriticalChance(weapondata.origCritChance)
        end
    end
end

function clothingUpdate(_player)
    local player = _player;
    local state = "Normal";
    local wornItems = player:getWornItems();
    local inventory = player:getInventory();
    if player:hasTrait(ToadTraitsRegistries.fitted) then
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

local function FixSpecialization(player, perk)
    if player:getXp():getXP(perk) < 0 then
        player:getXp():setXPToLevel(Perks.perk, player:getPerkLevel(perk));
    end
end

local function NoodleLegs(player)
    if not player or not player:hasTrait(ToadTraitsRegistries.noodlelegs) then return end

    local isRunning = player:isRunning();
    local isSprinting = player:isSprinting();
    if not (isRunning or isSprinting) then return end

    local sprinting = player:getPerkLevel(Perks.Sprinting);
    local nimble = player:getPerkLevel(Perks.Nimble);

    local nimbleChance = 100;
    local tripChance = 500001 + (nimble * 12500) + (sprinting * 12500);

    if player:hasTrait(CharacterTrait.GRACEFUL) then tripChance = tripChance * 1.2; end
    if player:hasTrait(CharacterTrait.CLUMSY) then tripChance = tripChance * 0.8; end
    if player:hasTrait(ToadTraitsRegistries.lucky) then tripChance = tripChance * (1.05 * luckimpact); end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then tripChance = tripChance * (0.95 * luckimpact); end

    if isSprinting then tripChance = tripChance * 0.6; end

    if ZombRand(0, tripChance) <= nimbleChance then
        local side = ZombRand(2) == 0 and "left" or "right"
        player:setBumpFallType("FallForward");
        player:setBumpType(side);
        player:setBumpDone(false);
        player:setBumpFall(true);
        player:reportEvent("wasBumped");
    end
end

local function SecondWind(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.secondwind) or playerdata.secondwinddisabled then return end

    local stats = player:getStats();
    local endurance = stats:get(CharacterStat.ENDURANCE);
    local fatigue = stats:get(CharacterStat.FATIGUE);

    if endurance < 0.5 or fatigue > 0.8 then
        local enemies = player:getSpottedList();
        if enemies:size() < 3 then return end

        local zombiesNearPlayer = 0;
        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i);
            if enemy:isZombie() and enemy:DistTo(player) <= 5 then
                zombiesNearPlayer = zombiesNearPlayer + 1;
            end

            if zombiesNearPlayer > 2 then break end
        end

        if zombiesNearPlayer > 2 then
            stats:set(CharacterStat.ENDURANCE, 1);
            playerdata.iHardyEndurance = 5;

            if fatigue > 0.4 then
                if fatigue > 0.6 then
                    playerdata.secondwindrecoveredfatigue = true;
                end
                stats:set(CharacterStat.FATIGUE, 0.4);
            end
            playerdata.secondwindcooldown = 0;
            playerdata.secondwinddisabled = true;

            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_secondwind"), true, HaloTextHelper.getColorGreen());
        end
    end
end

local function SecondWindRecharge(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.secondwind) or playerdata.secondwinddisabled then return end

    local cooldown = SandboxVars.MoreTraits.SecondWindCooldown or 14;
    local recharge = cooldown * 12;

    if playerdata.secondwindrecoveredfatigue then recharge = recharge * 2; end
    playerdata.secondwindcooldown = (playerdata.secondwindcooldown or 0) + 1;

    if playerdata.secondwindcooldown >= recharge then
        playerdata.secondwindcooldown = 0;
        playerdata.secondwinddisabled = false;
        playerdata.secondwindrecoveredfatigue = false;
        player:Say(getText("UI_trait_secondwindcooldown"));
    end
end

local function MotionSickness(player)
    local playerdata = player:getModData();
    local playerstats = player:getStats();
    local Sickness = playerstats:get(CharacterStat.FOOD_SICKNESS);
    if player:hasTrait(ToadTraitsRegistries.motionsickness) then
        if player:isDriving() == true and Sickness < 90.0 then
            local vehicle = player:getVehicle();
            if not vehicle then
                return
            end
            if playerdata.MotionActive == false then
                playerdata.MotionActive = true;
            end
            local Speed = math.abs(vehicle:getCurrentSpeedKmHour())
            if Speed < 16.0 then
                return
            elseif Speed >= 16.0 and Speed < 31.0 and Sickness < 21.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS, Sickness + 0.005);
            elseif Speed >= 31.0 and Speed < 41.0 and Sickness < 26.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS, Sickness + 0.01);
            elseif Speed >= 41.0 and Speed < 51.0 and Sickness < 38.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.02);
            elseif Speed >= 51.0 and Speed < 56.0 and Sickness < 48.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.03);
            elseif Speed >= 56.0 and Speed < 61.0 and Sickness < 73.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.04);
            elseif Speed >= 61.0 and Speed < 91.0 and Sickness < 80.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.05);
            elseif Speed >= 91.0 then
                playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.1);
            end
        elseif not player:isDriving() and not playerstats:isIsFakeInfected() and Sickness ~= 0 then
            if playerdata.MotionActive == true then
                playerdata.MotionActive = false;
            end
            playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness - 0.1);
        end
    end
end

local function MotionSicknessHealthLoss(player)
    local playerdata = player:getModData();
    local playerstats = player:getStats();
    local MaxHealth = 35.0;
    local Health = player:getBodyDamage():getOverallBodyHealth();
    local Sickness = playerstats:get(CharacterStat.FOOD_SICKNESS);
    if player:hasTrait(ToadTraitsRegistries.motionsickness) and playerdata.MotionActive == true then
        if Health >= 100 - Sickness and Health > MaxHealth then
            for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
                local b = player:getBodyDamage():getBodyParts():get(i);
                if Sickness < 40.0 then
                    return
                elseif Sickness >= 40.0 and Sickness < 50.0 and Health > 90.0 then
                    b:AddDamage(0.001 * GameSpeedMultiplier());
                elseif Sickness >= 50.0 and Sickness < 75.0 and Health > 75.0 then
                    b:AddDamage(0.002 * GameSpeedMultiplier());
                elseif Sickness >= 75.0 then
                    b:AddDamage(0.005 * GameSpeedMultiplier());
                end
            end
        end
    end
end

local function RestfulSleeper(player, playerdata)
    if not (player:hasTrait(ToadTraitsRegistries.restfulsleeper) and not player:isAsleep()) then return end

    local neck = player:getBodyDamage():getBodyPart(BodyPartType.Neck)
    playerdata.HasSlept = true
    playerdata.NeckHadPain = neck:getAdditionalPain() > 0
    playerdata.FatigueWhenSleeping = fatigue

    local stats = player:getStats()
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local reduction = 0.05
    if fatigue >= 0.6 then reduction = 0.2
    elseif fatigue >= 0.2 then reduction = 0.1 end

    stats:set(CharacterStat.FATIGUE, math.max(0, fatigue - reduction))
end

local function RestfulSleeperWakeUp(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.restfulsleeper) then return end

    local stats = player:getStats()
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local isAsleep = player:isAsleep()

    if isAsleep and fatigue <= 0 then
        player:forceAwake()
        playerdata.FatigueWhenSleeping = 0
        return -- Exit after waking up to prevent logic overlap
    end

    if isAsleep then
        playerdata.FatigueWhenSleeping = fatigue
        return
    end

    if playerdata.HasSlept then
        if fatigue > (playerdata.FatigueWhenSleeping or 0) then
            stats:set(CharacterStat.FATIGUE, playerdata.FatigueWhenSleeping)
        end

        playerdata.HasSlept = false
        playerdata.FatigueWhenSleeping = 0

        if not playerdata.NeckHadPain then
            local neck = player:getBodyDamage():getBodyPart(BodyPartType.Neck)
            if neck:getAdditionalPain() > 0 then
                neck:setAdditionalPain(0)
            end
        end
    end
end

local function HungerCheck(player, playerdata)
    if not (player:hasTrait(ToadTraitsRegistries.superimmune) and playerdata.SuperImmuneActive) then return end

    local stats = player:getStats()

    if player:isGodMod() then
        playerdata.SuperImmuneTextSaid = false
        playerdata.SuperImmuneActive = false
        playerdata.SuperImmuneMinutesPassed = 0
        playerdata.SuperImmuneRecovery = 0
        playerdata.SuperImmuneAbsoluteWellFedAmount = 0
        playerdata.SuperImmuneMinutesWellFed = 0
        playerdata.SuperImmuneInfections = 0
        playerdata.SuperImmuneLethal = false
        stats:set(CharacterStat.SICKNESS, 0);
        stats:set(CharacterStat.ZOMBIE_FEVER, 0);
        stats:set(CharacterStat.ZOMBIE_INFECTION, 0);
        return 
    end

    if stats:get(CharacterStat.HUNGER) <= 0 then
        playerdata.SuperImmuneMinutesWellFed = (playerdata.SuperImmuneMinutesWellFed or 0) + 1
    end
end

local function TerminatorGun(player)
    local item = player:getPrimaryHandItem()
    if not item or item:getCategory() ~= "Weapon" or item:getSubCategory() ~= "Firearm" then return end

    local itemdata = item:getModData()
    if not itemdata then return end

    local hasTerminator = player:hasTrait(ToadTraitsRegistries.terminator)
    local hasAntigun = player:hasTrait(ToadTraitsRegistries.antigun)

    if not itemdata.OGrange then
        itemdata.OGrange = item:getMaxRange()
        itemdata.OGaimingtime = item:getAimingTime()
        itemdata.OGjamchance = item:getJamGunChance()
        itemdata.OGmindmg = item:getMinDamage()
        itemdata.OGmaxdmg = item:getMaxDamage()
        itemdata.MTstate = "Normal"
    end

    local playerstate = player:getCurrentState()
    local isAiming = playerstate == PlayerAimState.instance() or playerstate == PlayerStrafeState.instance()

    if isAiming then
        local playerstats = player:getStats()
        local stress = CharacterStat.STRESS
        local panic = CharacterStat.PANIC
        local unhappiness = CharacterStat.UNHAPPINESS

        if hasTerminator then
            playerstats:set(stress, math.max(0, playerstats:get(stress) - 0.01))
            playerstats:set(panic, math.max(0, playerstats:get(panic) - 10))
        elseif hasAntigun then
            playerstats:set(unhappiness, playerstats:get(unhappiness) + 0.6)
        end
    end

    if hasTerminator and itemdata.MTstate ~= "Terminator" then
        item:setAimingTime(itemdata.OGaimingtime * 2)
        item:setMaxRange(itemdata.OGrange + 5)
        item:setJamGunChance(itemdata.OGjamchance / 2)
        item:setMinDamage(itemdata.OGmindmg * 1.25)
        item:setMaxDamage(itemdata.OGmaxdmg * 1.25)
        itemdata.MTstate = "Terminator"

    elseif hasAntigun and itemdata.MTstate ~= "antigun" then
        item:setAimingTime(itemdata.OGaimingtime * 0.8)
        item:setMaxRange(math.max(5, itemdata.OGrange - 5))
        itemdata.MTstate = "antigun"

    elseif not hasTerminator and not hasAntigun and itemdata.MTstate ~= "Normal" then
        -- Reset to original values
        item:setAimingTime(itemdata.OGaimingtime)
        item:setMaxRange(itemdata.OGrange)
        item:setJamGunChance(itemdata.OGjamchance)
        item:setMinDamage(itemdata.OGmindmg)
        item:setMaxDamage(itemdata.OGmaxdmg)
        itemdata.MTstate = "Normal"
    end
end

local function CheckForPlayerBuiltContainer(player, playerdata)
    if player:isPerformingAnAction() == true and player:isPlayerMoving() == false then
        playerdata.ContainerTraitIllegal = true;
        playerdata.ContainerTraitPlayerCurrentPositionX = player:getX();
        playerdata.ContainerTraitPlayerCurrentPositionY = player:getY();
    end
    if playerdata.ContainerTraitIllegal == true and player:getX() ~= playerdata.ContainerTraitPlayerCurrentPositionX and player:getY() ~= playerdata.ContainerTraitPlayerCurrentPositionY then
        playerdata.ContainerTraitIllegal = false;
        playerdata.ContainerTraitPlayerCurrentPositionX = 0;
        playerdata.ContainerTraitPlayerCurrentPositionY = 0;
    end
end

local function antigunxpdecrease(player, perk, amount)
    if player:hasTrait(ToadTraitsRegistries.antigun) and perk == Perks.Aiming then
        AddXP(player, perk, 0 - (amount * 0.25));
    end
end

local function IdealWeight(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.idealweight) then return end

    local nutrition = player:getNutrition()
    local currentCalories = nutrition:getCalories()
    local weight = nutrition:getWeight()
    
    if playerdata.OldCalories == nil then
        playerdata.OldCalories = currentCalories
        return -- Skip the first tick to establish a baseline
    end

    local oldCalories = playerdata.OldCalories

    if currentCalories > oldCalories then
        local caloriesChange = currentCalories - oldCalories

        if weight <= 78 then nutrition:setCalories(currentCalories + (caloriesChange * 0.5))
        elseif weight >= 82 then nutrition:setCalories(currentCalories - (caloriesChange * 0.25)) end
    end

    playerdata.OldCalories = nutrition:getCalories()
end

local function QuickRest(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.quickrest) then return end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local isSitting = player:isSitOnGround()

    if endurance < 1 and isSitting then
        local newEndurance = math.min(1.0, endurance + 0.001)

        stats:set(CharacterStat.ENDURANCE, newEndurance)
        playerdata.QuickRestEndurance = newEndurance
        playerdata.QuickRestActive = true
        return
    end

    if endurance >= 1 or not isSitting then
        if playerdata.QuickRestActive then
            playerdata.QuickRestActive = false
            playerdata.QuickRestEndurance = -1
            playerdata.QuickRestFinished = not isSitting
        end

        if not isSitting then
            playerdata.QuickRestFinished = false
            return
        end
    end
end

local function BurnWardPatient(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.burned) then return end

    if playerdata.MTModVersion < 3 or not SandboxVars.MoreTraits.BurnedFireAversion then return end

    local pX, pY, pZ = player:getX(), player:getY(), player:getZ()
    local distance = SandboxVars.MoreTraits.BurnedDistance or 10
    local closestDist = distance
    local foundFire = false

    local cell = getCell()
    for dy = -distance, distance do
        for dx = -distance, distance do
            if (dx*dx + dy*dy) <= (distance * distance) then
                local square = cell:getGridSquare(pX + dx, pY + dy, pZ)

                if square and square:haveFire() then
                    local d = square:DistTo(pX, pY)
                    if d < closestDist then
                        closestDist = d
                        foundFire = true
                    end
                end
            end
        end
    end

    if foundFire then
        local stats = player:getStats()
        local intensity = 1 - (closestDist / distance)
        local panicGain = math.max(0, SandboxVars.MoreTraits.BurnedPanic * intensity)
        local stressGain = math.max(0, (SandboxVars.MoreTraits.BurnedStress / 1000) * intensity)
        stats:set(CharacterStat.PANIC, panicGain);
        stats:set(CharacterStat.STRESS, stressGain);
    end
end

local function MTOnEquip(_player)
    local player = _player
    local playerdata = player:getModData()
    if player:getPrimaryHandItem() == nil then
        return
    end
    if player:hasTrait(ToadTraitsRegistries.gordanite) then
        local longBluntLvl = player:getPerkLevel(Perks.Blunt);
        local strengthlvl = player:getPerkLevel(Perks.Strength);
        local floatmod = (longBluntLvl + strengthlvl) / 2 * 0.1;
        local item = player:getPrimaryHandItem()
        if item:getType() == "Crowbar" or item:getType() == "BloodyCrowbar" then
            if SandboxVars.MoreTraits.GordaniteEffectiveness then
                local modifier = SandboxVars.MoreTraits.GordaniteEffectiveness * 0.01;
                floatmod = floatmod * modifier;
                longBluntLvl = longBluntLvl * modifier;
                strengthlvl = strengthlvl * modifier;
            end
            local crowbar = item;
            local moddata = crowbar:getModData()
            if moddata.MTHasBeenModified == nil then
                if crowbar:getTreeDamage() > 0 and crowbar:getTreeDamage() ~= 100 then
                    --Reset stats from old gordanite
                    crowbar:setMinDamage(0.6);
                    crowbar:setMaxDamage(1.15);
                    crowbar:setPushBackMod(0.5);
                    crowbar:setDoorDamage(8);
                    crowbar:setCriticalChance(35);
                    crowbar:setSwingTime(3);
                    if getActivatedMods():contains("VorpalWeapons") == false then
                        crowbar:setName(getText("Tooltip_MoreTraits_GordaniteDefault"));
                    end
                    crowbar:setWeaponLength(0.4);
                    crowbar:setMinimumSwingTime(3);
                    crowbar:setTreeDamage(0);
                    crowbar:setBaseSpeed(1);
                end
                moddata.MTHasBeenModified = true
                moddata.MinDamage = crowbar:getMinDamage()
                moddata.MaxDamage = crowbar:getMaxDamage()
                moddata.PushBack = crowbar:getPushBackMod()
                moddata.DoorDamage = crowbar:getDoorDamage()
                moddata.TreeDamage = crowbar:getTreeDamage()
                moddata.CriticalChance = crowbar:getCriticalChance()
                moddata.SwingTime = crowbar:getSwingTime()
                moddata.BaseSpeed = crowbar:getBaseSpeed()
                moddata.MinimumSwing = crowbar:getMinimumSwingTime()
                moddata.NameChanged = false
            end
            crowbar:setMinDamage(moddata.MinDamage + 0.1 + floatmod / 2);
            crowbar:setMaxDamage(moddata.MaxDamage + 0.1 + floatmod / 2);
            crowbar:setPushBackMod(moddata.PushBack + 0.1 + floatmod);
            crowbar:setDoorDamage(moddata.DoorDamage + 7 + strengthlvl + longBluntLvl);
            crowbar:setTreeDamage(moddata.TreeDamage + 15 + strengthlvl + longBluntLvl * 2);
            crowbar:setCriticalChance(moddata.CriticalChance + (strengthlvl + longBluntLvl) / 2);
            crowbar:setSwingTime(moddata.SwingTime - 0.2 - floatmod);
            crowbar:setBaseSpeed(moddata.BaseSpeed + 0.1 + floatmod);
            crowbar:setWeaponLength(0.4 + floatmod / 2);
            crowbar:setMinimumSwingTime(moddata.MinimumSwing - 0.2 - floatmod);
            if moddata.NameChanged == false then
                if getActivatedMods():contains("VorpalWeapons") == false then
                    crowbar:setName(crowbar:getName() .. "+");
                end
                moddata.NameChanged = true
            end
            if crowbar:getType() == "Crowbar" then
                crowbar:setTooltip(getText("Tooltip_MoreTraits_ItemBoost"));
            else
                crowbar:setTooltip(getText("Tooltip_MoreTraits_BloodyItemBoost"));
            end
        end
    else
        local item = player:getPrimaryHandItem()
        if item:getType() == "Crowbar" or item:getType() == "BloodyCrowbar" then
            local crowbar = item;
            local moddata = crowbar:getModData()
            if moddata.MTHasBeenModified == true then
                crowbar:setMinDamage(moddata.MinDamage);
                crowbar:setMaxDamage(moddata.MaxDamage);
                crowbar:setPushBackMod(moddata.PushBack);
                crowbar:setDoorDamage(moddata.DoorDamage);
                crowbar:setCriticalChance(moddata.CriticalChance);
                crowbar:setSwingTime(moddata.SwingTime);
                local newname = string.sub(crowbar:getName(), 0, string.len(crowbar:getName()) - 1)
                if getActivatedMods():contains("VorpalWeapons") == false then
                    crowbar:setName(newname)
                end
                crowbar:setWeaponLength(0.4);
                crowbar:setMinimumSwingTime(moddata.MinimumSwing);
                crowbar:setTreeDamage(moddata.TreeDamage);
                crowbar:setBaseSpeed(moddata.BaseSpeed);
                if crowbar:getType() == "Crowbar" then
                    crowbar:setTooltip(nil);
                else
                    crowbar:setTooltip(getText("Tooltip_MoreTraits_BloodyCrowbar"));
                end
                moddata.NameChanged = false
                moddata.MTHasBeenModified = false
            end
        end
    end
    if playerdata.MTModVersion ~= nil then
        if player:hasTrait(ToadTraitsRegistries.burned) and player:getPrimaryHandItem() ~= nil and playerdata.MTModVersion >= 3 then
            local item = player:getPrimaryHandItem()
            if item:getType() == "FlameTrap" or item:getType() == "FlameTrapTriggered" or item:getType() == "FlameTrapSensorV1" or item:getType() == "FlameTrapSensorV2" or item:getType() == "FlameTrapSensorV3" or item:getType() == "FlameTrapRemote" or item:getType() == "Molotov" then
                player:setPrimaryHandItem(nil)
                HaloTextHelper.addText(player, getText("UI_burnedcannotequip"), "", HaloTextHelper.getColorRed());
            end
        end
    else
        if player:hasTrait(ToadTraitsRegistries.burned) and player:getPrimaryHandItem() ~= nil then
            local item = player:getPrimaryHandItem()
            if item:getType() == "FlameTrap" or item:getType() == "FlameTrapTriggered" or item:getType() == "FlameTrapSensorV1" or item:getType() == "FlameTrapSensorV2" or item:getType() == "FlameTrapSensorV3" or item:getType() == "FlameTrapRemote" or item:getType() == "Molotov" then
                player:setPrimaryHandItem(nil)
                HaloTextHelper.addText(player, getText("UI_burnedcannotequip"), "", HaloTextHelper.getColorRed());
            end
        end
    end

end

function MTAlcoholismMoodle(_player, _playerdata)
    --Experimental MoodleFramework Support
    local player = _player;
    local playerdata = _playerdata;
    if player:hasTrait(ToadTraitsRegistries.drinker) then
        local stats = player:getStats();
        local drunkness = stats:get(CharacterStat.INTOXICATION);
        local anger = stats:get(CharacterStat.ANGER);
        local stress = stats:get(CharacterStat.STRESS);
        local hoursthreshold = 36;
        local divider = 5;
        local mf = MF;
        local Alcoholism = MF.getMoodle("MTAlcoholism"):getValue();
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
        local divcalc = playerdata.iHoursSinceDrink / divider
        if playerdata.isMTAlcoholismInitialized == nil or playerdata.isMTAlcoholismInitialized == false then
            MF.getMoodle("MTAlcoholism"):setValue(0.5);
        end
        if Alcoholism > 1.0 then
            MF.getMoodle("MTAlcoholism"):setValue(1);
        end
        if Alcoholism < 0.0 then
            MF.getMoodle("MTAlcoholism"):setValue(0);
        end
        if Alcoholism >= 0.7 then
            stats:set(CharacterStat.ANGER, 0);
            stats:set(CharacterStat.STRESS,0);
            stats:set(CharacterStat.BOREDOM,0);
            stats:set(CharacterStat.PANIC,0);
            stats:set(CharacterStat.PAIN,0);
            stats:set(CharacterStat.IDLENESS,0);
            stats:set(CharacterStat.UNHAPPINESS,0);
        end
        if internalTick >= 29 then
            if drunkness >= 20 then
                MF.getMoodle("MTAlcoholism"):setChevronCount(3);
                MF.getMoodle("MTAlcoholism"):setChevronIsUp(true);
                MF.getMoodle("MTAlcoholism"):setValue(Alcoholism + 0.004);
                playerdata.iHoursSinceDrink = 0;
            elseif drunkness >= 10 then
                MF.getMoodle("MTAlcoholism"):setChevronCount(2);
                MF.getMoodle("MTAlcoholism"):setChevronIsUp(true);
                MF.getMoodle("MTAlcoholism"):setValue(Alcoholism + 0.003);
                playerdata.iHoursSinceDrink = 0;
            elseif drunkness > 0 then
                stats:set(CharacterStat.FATIGUE, stats:get(CharacterStat.FATIGUE) - 0.001);
                MF.getMoodle("MTAlcoholism"):setValue(Alcoholism + 0.002);
                MF.getMoodle("MTAlcoholism"):setChevronCount(1);
                MF.getMoodle("MTAlcoholism"):setChevronIsUp(true);
                playerdata.iHoursSinceDrink = 0;
            else
                MF.getMoodle("MTAlcoholism"):setChevronCount(0);
                MF.getMoodle("MTAlcoholism"):setChevronIsUp(false);
                if Alcoholism > 0.5 and internalTick >= 30 then
                    MF.getMoodle("MTAlcoholism"):setValue(Alcoholism - 0.0001);
                end
            end
        end
        if internalTick == 30 then
            if Alcoholism <= 0.3 then
                if anger < 0.05 + (divcalc * 0.1) / 2 then
                    stats:set(CharacterStat.ANGER, anger + 0.01);
                end
            end
            if Alcoholism <= 0.2 then
                if stress < 0.15 + (divcalc * 0.1) / 2 then
                    stats:set(CharacterStat.STRESS, stress + 0.01);
                end
            end
        end
    end
end
function MTAlcoholismMoodleTracker(_player, _playerdata)
    --Experimental MoodleFramework Support
    local player = _player;
    local playerdata = _playerdata;
    if player:hasTrait(ToadTraitsRegistries.drinker) then
        local hoursthreshold = 72;
        local Alcoholism = MF.getMoodle("MTAlcoholism"):getValue();
        if SandboxVars.MoreTraits.AlcoholicWithdrawal then
            hoursthreshold = SandboxVars.MoreTraits.AlcoholicWithdrawal;
        end
        playerdata.iHoursSinceDrink = playerdata.iHoursSinceDrink + 1;
        local hours = playerdata.iHoursSinceDrink;
        local percent = (hours / hoursthreshold) * 0.05;
        MF.getMoodle("MTAlcoholism"):setValue(Alcoholism - percent);
    end
end
function MainPlayerUpdate(player)
    if not player then return end;
    local playerdata = player:getModData();
    if not playerdata then return end;

    if internalTick >= 30 then
        amputee(player, (playerdata.bWasInfected ~= player:getBodyDamage():isInfected()
                and player:getBodyDamage():isInfected()));
        playerdata.bWasInfected = player:getBodyDamage():isInfected();
        vehicleCheck(player);
        FoodUpdate(player);
        clothingUpdate(player);
    elseif internalTick == 20 then
        FearfulUpdate(player, playerdata);
    elseif internalTick == 10 then
        SuperImmune(player, playerdata);
        Immunocompromised(player, playerdata);
    end
    MotionSickness(player); -- Unsure if needed now due to Motion Sensitive trait in Vanilla?
    MotionSicknessHealthLoss(player); -- Unsure if needed now due to Motion Sensitive trait in Vanilla?
    SecondWind(player, playerdata);
    indefatigable(player, playerdata);
    checkBloodTraits(player);
    CheckDepress(player, playerdata);
    CheckSelfHarm(player);
    Blissful(player);
    hardytrait(player, playerdata);
    if isMoodleFrameWorkEnabled == false then
        drinkerupdate(player, playerdata);
    else
        MTAlcoholismMoodle(player, playerdata);
    end
    BatteringRam(player, playerdata)
    bouncerupdate(player, playerdata);
    badteethtrait(player, playerdata);
    albino(player, playerdata);
    UpdateWorkerSpeed(player)
    SuperImmuneFakeInfectionHealthLoss(player, playerdata);
    CheckForPlayerBuiltContainer(player, playerdata);
    IdealWeight(player, playerdata);
    QuickRest(player, playerdata);
    internalTick = internalTick + 1;
    if internalTick > 30 then
        --Reset internalTick every 30 ticks
        internalTick = 0;
    end
end

function EveryOneMinute()
    local player = getPlayer();
    if not player then return end;
    local playerdata = player:getModData();
    if not playerdata then return end;

    ToadTraitParanoia(player, playerdata);
    ToadTraitButter(player);
    UnHighlightScrounger(player, playerdata);
    LeadFoot(player);
    GymGoerUpdate(player, playerdata);
    HungerCheck(player, playerdata);
    RestfulSleeperWakeUp(player, playerdata);
    AlbinoTimer(player, playerdata);
    TerminatorGun(player);
    BurnWardPatient(player, playerdata)
    SuperImmuneRecoveryProcess();

    if playerdata.QuickRestFinished == true then
        HaloTextHelper.addText(player, getText("UI_quickrestfullendurance"), "", HaloTextHelper.getColorGreen());
    end
end

function EveryHours()
    local player = getPlayer();
    if not player then return end;
    local playerdata = player:getModData();
    if not playerdata then return end;

    if isMoodleFrameWorkEnabled == false then
        drinkertick(player, playerdata);
    else
        MTAlcoholismMoodleTracker(player, playerdata);
    end

    drinkerpoison(player, playerdata);
    SecondWindRecharge(player, playerdata);
    indefatigablecounter(player, playerdata);
    RestfulSleeper(player, playerdata);
    ToadTraitDepressive(player, playdata);

    if playerdata.UnwaveringInjurySpeedChanged == false and player:hasTrait(ToadTraitsRegistries.unwavering) then
        playerdata.UnwaveringInjurySpeedChanged = true;
        for n = 0, player:getBodyDamage():getBodyParts():size() - 1 do
            local i = player:getBodyDamage():getBodyParts():get(n);
            i:setScratchSpeedModifier(i:getScratchSpeedModifier() + 30);
            i:setCutSpeedModifier(i:getCutSpeedModifier() + 30);
            i:setDeepWoundSpeedModifier(i:getDeepWoundSpeedModifier() + 60);
            i:setBurnSpeedModifier(i:getBurnSpeedModifier() + 60);
        end
    end
    if player:hasTrait(ToadTraitsRegistries.ingenuitive) and playerdata.IngenuitiveActivated == false then
        MT_LearnAllRecipes(player);
        playerdata.IngenuitiveActivated = true;
    end
    for i, v in ipairs(playerdata.InjuredBodyList) do
        local bodypart = player:getBodyDamage():getBodyParts():get(v);
        if bodypart:HasInjury() == false then
            table.remove(playerdata.InjuredBodyList, i, v);
        end
    end
    for i, v in ipairs(playerdata.TraitInjuredBodyList) do
        local bodypart = player:getBodyDamage():getBodyParts():get(v);
        if bodypart:HasInjury() == false then
            table.remove(playerdata.TraitInjuredBodyList, i, v);
        end
    end
end

local function EveryDay()
    local player = getPlayer();
    local playerdata = player:getModData();

end

function OnCreatePlayer(_, player)
    --reset any worn clothing to default state.
    local playerdata = player:getModData();
    local wornItems = player:getWornItems();
    local bodydamage = player:getBodyDamage();
    for i = wornItems:size() - 1, 0, -1 do
        local item = wornItems:getItemByIndex(i);
        if item:IsClothing() then
            local itemdata = item:getModData();
            itemdata.sState = nil;
        end
    end
    InitPlayerData(player);
    MT_Config = PZAPI.ModOptions:getOptions("1299328280");
    print("More Traits - Mod Version On Which Player Was Created: " .. playerdata.MTModVersion)
    if getGameTime():getModData().MTModVersion == nil then
        getGameTime():getModData().MTModVersion = "Before 15 January 2023"
    end
    print("More Traits - Mod Version On Which Save Was Created: " .. getGameTime():getModData().MTModVersion);
    print("More Traits - Current Mod Version: " .. MTModVersion)
end

function OnInitWorld()
    if getGameTime():getModData().MTModVersion == nil then
        getGameTime():getModData().MTModVersion = MTModVersion;
    end
end
--Events.OnPlayerMove.Add(gimp);
--Events.OnPlayerMove.Add(fast);
Events.OnPlayerMove.Add(NoodleLegs);
Events.OnZombieDead.Add(graveRobber);
Events.OnWeaponHitCharacter.Add(promelee);
Events.OnWeaponHitCharacter.Add(actionhero);
Events.OnWeaponHitCharacter.Add(mundane);
Events.OnWeaponHitCharacter.Add(tavernbrawler);
Events.OnWeaponSwing.Add(progun);
Events.OnWeaponHitCharacter.Add(martial);
Events.AddXP.Add(Specialization);
Events.AddXP.Add(GymGoer);
Events.AddXP.Add(antigunxpdecrease);
Events.OnPlayerUpdate.Add(MainPlayerUpdate);
Events.EveryOneMinute.Add(EveryOneMinute);
Events.OnInitWorld.Add(OnInitWorld);
Events.OnPlayerGetDamage.Add(MTPlayerHit)
Events.OnEquipPrimary.Add(MTOnEquip)
if getActivatedMods():contains("DracoExpandedTraits") then
    Events.EveryOneMinute.Add(MT_checkWeight);
else
    Events.EveryTenMinutes.Add(MT_checkWeight);
end
Events.EveryHours.Add(EveryHours);
Events.OnNewGame.Add(initToadTraitsPerks);
Events.OnNewGame.Add(initToadTraitsItems);
Events.OnRefreshInventoryWindowContainers.Add(ContainerEvents);
Events.OnCreatePlayer.Add(OnCreatePlayer);
Events.LevelPerk.Add(FixSpecialization);
Events.EveryDays.Add(EveryDay);
