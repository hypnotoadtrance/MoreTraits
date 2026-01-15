-- require('NPCs/MainCreationMethods');
-- require("Items/Distributions");
-- require("Items/ProceduralDistributions");

--[[
TODO Figure out what is causing stat synchronization issues
When playing in Singleplayer, traits like Blissful work just fine. But in Multiplayer, subtracting stats doesn't
seem to work properly. This also effects Hardy, Alcoholic (removing stress when drinking alcohol doesn't work in MP)
TODO Code optimization
This is constantly ongoing. Whenever I see something that can be written more efficiently, I try to rewrite where i can.
--]]

if getActivatedMods():contains("MoodleFramework") == true then
    require("MF_ISMoodle");
    MF.createMoodle("MTAlcoholism");
end

--Global Variables
if not isServer() then
    if PZAPI and PZAPI.ModOptions then
        MT_Config = PZAPI.ModOptions:getOptions("1299328280")
    end
end
skipxpadd = false;
internalTick = 0;
luckimpact = 1.0;
MTModVersion = 42.13; --REMEMBER TO MANUALLY INCREASE
isMoodleFrameWorkEnabled = getActivatedMods():contains("MoodleFramework");

local playerDefaultData = {
    MTModVersion = MTModVersion,
    secondwinddisabled = false,
    secondwindrecoveredfatigue = false,
    secondwindcooldown = 0,
    bToadTraitDepressed = false,
    indefatigablecooldown = 0,
    indefatigablecuredinfection = false,
    indefatigabledisabled = false,
    bindefatigable = false,
    IndefatigableHasBeenDraggedDown = false,
    bSatedDrink = true,
    iHoursSinceDrink = 0,
    iTimesCannibal = 0,
    fPreviousHealthFromFoodTimer = 1000,
    bWasInfected = false,
    iHardyEndurance = 5,
    iHardyMaxEndurance = 5,
    iHardyInterval = 1000,
    iWithdrawalCooldown = 24,
    iParanoiaCooldown = 10,
    SuperImmuneRecovery = 0,
    SuperImmuneActive = false,
    SuperImmuneMinutesPassed = 0,
    SuperImmuneTextSaid = false,
    SuperImmuneHealedOnce = false,
    SuperImmuneMinutesWellFed = 0,
    SuperImmuneAbsoluteWellFedAmount = 0,
    SuperImmuneInfections = 0,
    SuperImmuneLethal = false,
    MotionActive = false,
    HasSlept = false,
    FatigueWhenSleeping = 0,
    NeckHadPain = false,
    ContainerTraitIllegal = false,
    ContainerTraitPlayerCurrentPositionX = 0,
    ContainerTraitPlayerCurrentPositionY = 0,
    AlbinoTimeSpentOutside = 0,
    isMTAlcoholismInitialized = false,
    iBouncercooldown = 0,
    bisInfected = false,
    bisAlbinoOutside = false,
    bWasJustSprinting = false,
    InjuredBodyList = {},
    UnwaveringInjurySpeedChanged = false,
    OldCalories = 810,
    IngenuitiveActivated = false,
    EvasivePlayerInfected = false,
    TraitInjuredBodyList = {},
    isSleeping = false,
    QuickRestActive = false,
    QuickRestEndurance = -1,
    QuickRestFinished = false,
    AntiGunProcessing = false,
}

local function InitPlayerData(player, playerdata)
    for key, defaultValue in pairs(playerDefaultData) do
        if playerdata[key] == nil then
            playerdata[key] = defaultValue
        end
    end
end

-- local function GetXPModifier(player, perk)
--     if not player then return 1.0 end
--     if not player:hasTrait(ToadTraitsRegistries.gymgoer) then return 1.0 end

--     if perk == Perks.Fitness or perk == Perks.Strength then
--         local m = 1.0
--         if player:getCurrentState() == FitnessState.instance() then
--             local gymMod = SandboxVars.MoreTraits.GymGoerPercent or 200
--             m = m + ((gymMod * 0.01) - 1) * 0.1
--         end
--         return m
--     end

--     return 1.0
-- end

local function MT_AddXP(player, perk, amount, xpBoost)
    -- Arguments: perk, amount, xpBoost
    player:getXp():AddXP(perk, amount, xpBoost or false, false, false)
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
        stats:set(CharacterStat.STRESS, curstress + 0.1);
        result:setUnhappyChange(10);
        result:setTooltip(getText("UI_cannibal_familiar"));
    else
        stats:set(CharacterStat.STRESS, curstress - 0.1);
        result:setTooltip(getText("UI_cannibal_comfortable"));
        result:setUnhappyChange(-10);
        player:getInventory():AddItem("MoreTraits.BloodBox");
    end
    result:setRotten(false);
    result:setAge(0);
    result:updateAge();
    player:getModData().iTimesCannibal = times + 1;
end

local function initToadTraitsItems(player)
    if isClient() then
        return
    end
    local inv = player:getInventory();

    if player:hasTrait(ToadTraitsRegistries.deprived) then
        player:clearWornItems();
        inv:removeAllItems();
        player:createKeyRing();
        if SandboxVars.MoreTraits.ForgivingDeprived then
            inv:AddItem("Base.Belt2");
        end
        return
    end

    if player:hasTrait(ToadTraitsRegistries.preparedfood) then
        local holder = inv:AddItem("Base.Plasticbag");

        if holder then
            local holderInv = holder:getItemContainer()
            local items = { "Base.TinOpener", "Base.CannedTomato", "Base.CannedPotato", "Base.CannedCarrots", "Base.CannedBroccoli", "Base.CannedCabbage", "Base.CannedEggplant" }
            for _, item in ipairs(items) do
                holderInv:AddItem(item);
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedammo) then
        local holder = inv:AddItem("Base.PistolCase1");

        if holder then
            local holderInv = holder:getItemContainer()
            local items = { "Base.Bullets9mmBox", "Base.Bullets45Box", "Base.Bullets44Box", "Base.Bullets38Box", "Base.223Box", "Base.308Box", "Base.556Box", "Base.ShotgunShellsBox" }
            for _, item in ipairs(items) do
                holderInv:AddItem(item);
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedweapon) then
        local items = { "Base.BaseballBat_Can", "Base.HuntingKnife" }
        for _, item in ipairs(items) do
            inv:AddItem(item);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedmedical) then
        local holder = inv:AddItem("Base.FirstAidKit");

        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = { "Base.Bandaid", "Base.PillsAntiDep", "Base.Disinfectant", "Base.AlcoholWipes", "Base.PillsBeta", "Base.Pills", "Base.SutureNeedle", "Base.Tissue", "Base.Tweezers" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item);
                end
                local amount = SandboxVars.MoreTraits.PreparedMedicalBandageAmount or 4
                for i = 1, amount do
                    holderInv:AddItem("Base.Bandage");
                end
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedrepair) then
        local holder = inv:AddItem("Base.Toolbox");

        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = { "Base.Screwdriver", "Base.Saw", "Base.Hammer", "Base.NailsBox" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item);
                end
                for i = 1, 8 do
                    holderInv:AddItem("Base.Garbagebag");
                end
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcamp) then
        local holder = inv:AddItem("MoreTraits.Bag_SmallHikingBag");

        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = { "Base.Matches", "Base.TentGreen_Packed", "Base.BeefJerky", "Base.Pop", "Base.FishingRod", "Base.FishingLine", "Base.FishingTackle", "Base.Battery", "Base.Torch", "Base.WaterBottleFull" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item);
                end
                for i = 1, 3 do
                    holderInv:AddItem("Base.Stone2");
                end
            end
            if player:getClothingItem_Back() == nil then
                player:setClothingItem_Back(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedpack) then
        local holder = inv:AddItem("Base.Bag_NormalHikingBag")
        if holder and player:getClothingItem_Back() == nil then
            player:setClothingItem_Back(holder);
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcar) then
        local holder = inv:AddItem("Base.Bag_JanitorToolbox");

        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = { "Base.CarBattery1", "Base.Screwdriver", "Base.Wrench", "Base.LugWrench", "Base.TirePump", "Base.Jack" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item);
                end
            end
            if not player:getPrimaryHandItem() then
                player:setPrimaryHandItem(holder)
            end
        end
        if SandboxVars.MoreTraits.PreparedCarGasToggle then
            local gas = inv:AddItem("Base.PetrolCan");
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(gas)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcoordination) then
        local holder = inv:AddItem("Base.Bag_FannyPackFront");

        local watch = inv:AddItem("Base.WristWatch_Right_DigitalBlack")

        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = {
                    "Base.MuldraughMap", "Base.RosewoodMap", "Base.RiversideMap", "Base.WestpointMap", "Base.MarchRidgeMap",
                    "Base.LouisvilleMap1", "Base.LouisvilleMap2", "Base.LouisvilleMap3", "Base.LouisvilleMap4", "Base.LouisvilleMap5",
                    "Base.LouisvilleMap6", "Base.LouisvilleMap7", "Base.LouisvilleMap8", "Base.LouisvilleMap9", "Base.Pencil", "Base.Eraser"
                }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item);
                end
            end
            if holder and not player:getWornItem(holder:getBodyLocation()) then
                player:setWornItem(holder:getBodyLocation(), holder)
            end
        end
        if watch and not player:getWornItem(watch:getBodyLocation()) then
            player:setWornItem(watch:getBodyLocation(), watch)
        end
    end

    if player:hasTrait(ToadTraitsRegistries.drinker) and SandboxVars.MoreTraits.AlcoholicFreeDrink then
        inv:AddItem("Base.Whiskey");
    end

    if player:hasTrait(CharacterTrait.TAILOR) then
        local holder = inv:AddItem("Base.SewingKit");

        if holder then
            local holderInv = holder:getItemContainer();
            if holderInv then
                local items = { "Base.Scissors", "Base.Needle" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item);
                end
                for i = 1, 4 do
                    holderInv:AddItem("Base.Thread");
                end
            end
        end
    end

    if player:hasTrait(CharacterTrait.SMOKER) and SandboxVars.MoreTraits.SmokerStart then
        local items = { "Base.CigarettePack", "Base.Lighter" }
        for _, item in ipairs(items) do
            inv:AddItem(item);
        end
    end
end

local function MT_LearnAllRecipes(player)
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

local function initToadTraitsPerks(player, playerdata)
    local bodyDamage = player:getBodyDamage()
    local damage = 20
    local bandagestrength = 5
    local splintstrength = 0.9
    local fracturetime = 50
    local scratchtimemod = 20
    local bleedtimemod = 10

    if SandboxVars.MoreTraits.LuckImpact then
        luckimpact = SandboxVars.MoreTraits.LuckImpact * 0.01
    end

    InitPlayerData(player, playerdata)

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

                if injury <= 1 then
                    -- Scratch
                    b:setScratched(true, true)
                elseif injury == 2 and doburns then
                    -- Burn
                    b:setBurned()
                    b:setBurnTime(ZombRand(50) + damage)
                    b:setNeedBurnWash(false)
                elseif injury == 3 then
                    -- Cut
                    b:setCut(true, true)
                else
                    -- Deep Wound
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

local function GlassBody(player, playerData)
    local bodyDamage = player:getBodyDamage();
    local currenthp = bodyDamage:getOverallBodyHealth();
    local multiplier = getGameTime():getMultiplier();

    if playerData.glassBodyLastHP == nil then
        playerData.glassBodyLastHP = currenthp;
        playerData.glassBodyInitialized = true;
        return ;
    end

    if playerData.glassBodyInitialized == true then
        playerData.glassBodyInitialized = false;
        playerData.glassBodyLastHP = currenthp; -- Update to current HP
        return ;
    end

    if player:isAsleep() or multiplier > 4.0 then
        playerData.glassBodyLastHP = currenthp;
        return ;
    end

    local lasthp = playerData.glassBodyLastHP;

    if currenthp < lasthp then
        local difference = lasthp - currenthp;
        if difference > 50 then
            playerData.glassBodyLastHP = currenthp;
            return ;
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

        local damage = difference * 2;
        local fractureTime = 0;
        local scratched = false;
        local targetBodyPart = -1;

        if ZombRand(100) <= chance then
            targetBodyPart = ZombRand(0, 17);
            if difference > 0.33 then
                fractureTime = ZombRand(20) + woundstrength;
            elseif difference > 0.1 then
                scratched = true;
            end
        end

        if targetBodyPart == -1 then return end

        if isClient() then
            local args = {
                damage = damage, partIndex = targetBodyPart,
                fractureTime = fractureTime, scratched = scratched
            }
            sendClientCommand(player, 'ToadTraits', 'GlassBody', args)
        else
            bodyDamage:ReduceGeneralHealth(damage);
            local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(targetBodyPart));
            if fractureTime > 0 then
                if bodyPart:getFractureTime() <= 0 then
                    bodyPart:setFractureTime(fractureTime)
                end
            end
            if scratched then bodyPart:setScratched(true, true) end
        end
    end
    playerData.glassBodyLastHP = bodyDamage:getOverallBodyHealth();
end

local function MTPlayerHit(player, _, __)
    if not player or player:isDead() or player:isZombie() then
        return
    end

    local playerdata = player:getModData()
    if not playerdata then
        return
    end ;

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

                        if isClient() then
                            local args = {
                                bodyPart = bodyPart, wasInfectedBefore = wasInfectedBefore,
                                isInfected = isInfected
                            }
                            sendClientCommand(player, 'ToadTraits', 'EvasiveDodge', args)
                        else
                            if bodyPart:IsInfected() and not wasInfectedBefore and isInfected then
                                bodyPart:SetInfected(false)
                                bodyDamage:setInfected(false)
                                bodyDamage:setInfectionMortalityDuration(-1)
                                bodyDamage:setInfectionTime(-1)
                                bodyDamage:setInfectionGrowthRate(0)
                            end

                            if bodyPart:bleeding() then
                                bodyPart:setBleedingTime(0)
                                bodyPart:setBleeding(false)
                            end

                            if bodyPart:scratched() then
                                bodyPart:setScratchTime(0)
                                bodyPart:setScratched(false, false)
                            end

                            if bodyPart:isCut() then
                                bodyPart:setCutTime(0)
                                bodyPart:setCut(false, false)
                            end

                            if bodyPart:bitten() then
                                bodyPart:setBitten(false, false)
                                bodyPart:setHealth(100.0)
                            end
                        end
                    else
                        table.insert(list, i)
                        if bodyPart:IsInfected() and not wasInfectedBefore and isInfected then
                            playerdata.EvasivePlayerInfected = true
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
                    
                    local immunoChance = SandboxVars.MoreTraits.ImmunoChance or 25
                    if bodyDamage:isInfected() then return end

                    if ZombRand(1, 101) <= immunoChance then
                        if isClient() then
                            sendClientCommand(player, 'ToadTraits', 'InfectPlayer', {})
                        else
                            bodyDamage:setInfected(true)
                        end
                        triedImmuno = true
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
        GlassBody(player, playerdata)
    end
end

local function ToadTraitButter(player)
    if player:hasTrait(ToadTraitsRegistries.butterfingers) and player:isPlayerMoving() then
        local basechance = 3;
        local chanceinx = SandboxVars.MoreTraits.ButterfingersChance or 2000;

        if player:hasTrait(CharacterTrait.ALL_THUMBS) then
            basechance = basechance + 1;
        end
        if player:hasTrait(CharacterTrait.DEXTROUS) then
            basechance = basechance - 1;
        end
        if player:hasTrait(ToadTraitsRegistries.packmule) then
            basechance = basechance - 1;
        end
        if player:hasTrait(ToadTraitsRegistries.packmouse) then
            basechance = basechance + 1;
        end
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            basechance = basechance - 1 * luckimpact;
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            basechance = basechance + 1 * luckimpact;
        end

        local weight = player:getInventoryWeight();
        local chancemod = math.floor(weight / 5);

        if player:isSprinting() then
            chancemod = chancemod + 10;
        elseif player:IsRunning() then
            chancemod = chancemod + 5;
        end

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

local function ToadTraitParanoia(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.paranoia) then
        return
    end

    if playerdata.iParanoiaCooldown > 0 then
        playerdata.iParanoiaCooldown = playerdata.iParanoiaCooldown - 1;
        return
    end

    if player:isPlayerMoving() then
        local stats = player:getStats();
        local panic = stats:get(CharacterStat.PANIC);
        local stress = stats:get(CharacterStat.STRESS);

        local triggerThreshold = 1
        triggerThreshold = triggerThreshold + (stress * 2)

        if ZombRand(100) < triggerThreshold then
            local sm = getSoundManager()
            local surprised = sm:PlaySound("ZombieSurprisedPlayer", false, 0)
            if surprised then
                surprised:setVolume(0.05)
            end

            local newPanic = math.min(panic + 25, 100)
            local newStress = math.min(stress + 0.1, 1.0)

            if isClient() then
                local args = { panic = newPanic, stress = newStress }
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
            else
                stats:set(CharacterStat.PANIC, newPanic)
                stats:set(CharacterStat.STRESS, newStress)
            end

            if not isServer() then
                local breathSound = player:isFemale() and "female_heavybreathpanic" or "male_heavybreathpanic"
                local breath = sm:PlaySound(breathSound, false, 5)
                if breath then
                    breath:setVolume(0.025)
                end
            end

            playerdata.iParanoiaCooldown = 30
        end
    end
end

local function ToadTraitScrounger(page, player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.scrounger) then
        return
    end

    local modifier = 1.0 + (SandboxVars.MoreTraits.ScroungerLootModifier or 30) * 0.01
    local baseChance = SandboxVars.MoreTraits.ScroungerItemChance or 10

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        modifier = modifier + (0.1 * luckimpact)
        baseChance = baseChance + (5 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        modifier = modifier - (0.1 * luckimpact)
        baseChance = baseChance - (5 * luckimpact)
    end

    for _, v in ipairs(page.backpacks) do
        local inventory = v.inventory
        local containerObj = inventory:getParent()

        if containerObj and inventory:getType() ~= "floor" then
            local modData = containerObj:getModData()

            if not modData.bScroungerorIncomprehensiveRolled and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") then
                modData.bScroungerorIncomprehensiveRolled = true
                containerObj:transmitModData()

                if playerdata.ContainerTraitIllegal then
                    playerdata.ContainerTraitIllegal = false
                    return
                end

                if ZombRand(100) <= baseChance then
                    local items = inventory:getItems()
                    if not items or items:isEmpty() then
                        return
                    end

                    local processedItems = {}
                    local itemsToSpawn = {} -- List of strings to send to server

                    for i = 0, items:size() - 1 do
                        local item = items:get(i)
                        local fullType = item:getFullType()

                        if not processedItems[fullType] then
                            processedItems[fullType] = true
                            local count = inventory:getNumberOfItem(fullType)

                            if fullType == "Base.CigaretteSingle" or fullType == "Base.Nails" then
                                count = math.floor(count / 20)
                            end

                            local currentItemChance = baseChance
                            if item:getCategory() == "Food" or item:IsDrainable() then
                                currentItemChance = currentItemChance + 10
                            elseif item:IsWeapon() then
                                currentItemChance = currentItemChance + 5
                            end

                            local n = 0
                            if count == 1 then
                                if ZombRand(100) <= currentItemChance then
                                    n = 1
                                end
                            elseif count > 1 and count < 5 then
                                n = math.floor(count * modifier)
                            elseif count >= 5 then
                                n = math.floor((count * modifier) * 2)
                            end

                            if n > 0 then
                                for j = 1, n do
                                    if isClient() then
                                        table.insert(itemsToSpawn, fullType)
                                    else
                                        inventory:AddItem(fullType)
                                    end
                                end

                                if not isServer() and MT_Config and MT_Config:getOption("ScroungerAnnounce"):getValue() then
                                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrounger") .. ": " .. item:getName(), true, HaloTextHelper.getColorGreen())
                                end
                            end
                        end
                    end

                    if isClient() and #itemsToSpawn > 0 then
                        local args = { x = containerObj:getX(), y = containerObj:getY(), z = containerObj:getZ(), items = itemsToSpawn }
                        sendClientCommand(player, 'ToadTraits', 'Scrounger', args)
                    end
                end
            end
        end
    end
end

local function UnHighlightScrounger(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.scrounger) then
        return
    end

    local highlight = false
    local highlightTime = 1

    if not isServer() and MT_Config then
        highlight = MT_Config:getOption("ScroungerHighlight"):getValue()
        highlightTime = MT_Config:getOption("ScroungerHighlightTime"):getValue()
    end

    if not isServer() and not highlight then
        return
    end

    playerdata.scroungerHighlightsTbl = playerdata.scroungerHighlightsTbl or {}
    local highlights = playerdata.scroungerHighlightsTbl
    local maxTime = highlightTime * 10

    local remove = {}
    for containerObj, timer in pairs(highlights) do
        if timer >= maxTime then
            containerObj:setHighlighted(false)
            table.insert(remove, containerObj)
        else
            highlights[containerObj] = timer + 1
        end
    end
end

local function ToadTraitIncomprehensive(page, player)
    if not player:hasTrait(ToadTraitsRegistries.incomprehensive) then
        return
    end

    local baseChance = SandboxVars.MoreTraits.IncomprehensiveChance or 10

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        baseChance = baseChance - (5 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        baseChance = baseChance + (5 * luckimpact)
    end

    for _, v in ipairs(page.backpacks) do
        local inventory = v.inventory
        local containerObj = inventory:getParent()

        if containerObj and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") then
            local modData = containerObj:getModData()

            if not modData.bScroungerorIncomprehensiveRolled and containerObj:getContainer() then
                modData.bScroungerorIncomprehensiveRolled = true
                containerObj:transmitModData()

                if ZombRand(100) <= baseChance then
                    local container = containerObj:getContainer()
                    local items = container:getItems()
                    local processedItems = {}
                    local itemsToRemove = {}

                    for i = 0, items:size() - 1 do
                        local item = items:get(i)
                        if item then
                            local fullType = item:getFullType()

                            if not processedItems[fullType] then
                                processedItems[fullType] = true

                                local count = container:getNumberOfItem(fullType)
                                if fullType == "Base.CigaretteSingle" or fullType == "Base.Nails" then
                                    count = math.floor(count / 20)
                                end

                                local removeCount = 0
                                if count == 1 then
                                    local bChance = 5
                                    if player:hasTrait(ToadTraitsRegistries.lucky) then
                                        bChance = bChance - (5 * luckimpact)
                                    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
                                        bChance = bChance + (5 * luckimpact)
                                    end

                                    if item:IsFood() or item:IsDrainable() then
                                        bChance = bChance + 10
                                    end
                                    if item:IsWeapon() then
                                        bChance = bChance + 5
                                    end

                                    if ZombRand(100) <= bChance then
                                        removeCount = 1
                                    end
                                elseif count > 1 then
                                    removeCount = 1
                                    if count >= 5 then
                                        removeCount = 2
                                    end
                                end

                                if removeCount > 0 then
                                    for j = 1, removeCount do
                                        table.insert(itemsToRemove, fullType)
                                    end

                                    if not isServer() and MT_Config and MT_Config:getOption("ScroungerAnnounce"):getValue() then
                                        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_incomprehensive") .. " : " .. item:getName(), false, HaloTextHelper.getColorRed())
                                    end
                                end
                            end
                        end
                    end

                    if #itemsToRemove > 0 then
                        if isClient() then
                            local args = { x = containerObj:getX(), y = containerObj:getY(), z = containerObj:getZ(), items = itemsToRemove }
                            sendClientCommand(player, 'ToadTraits', 'Incomprehensive', args)
                        else
                            for _, type in ipairs(itemsToRemove) do
                                local itemObj = container:FindAndReturn(type)
                                if itemObj then
                                    container:Remove(itemObj)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ToadTraitAntique(page, player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.antique) then
        return
    end

    local LootRespawn = SandboxVars.LootRespawn;
    local respawnMap = { [2] = 24, [3] = 168, [4] = 720, [5] = 1440 };
    local HoursForLootRespawn = respawnMap[LootRespawn] or 0;
    local AllowRespawn = LootRespawn ~= 1;

    local baseChance = 10;
    local roll = SandboxVars.MoreTraits.AntiqueChance or 1500;

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        baseChance = baseChance + (1 * luckimpact)
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        baseChance = baseChance - (1 * luckimpact)
    end
    if player:hasTrait(CharacterTrait.DEXTROUS) then
        baseChance = baseChance + 1
    end
    if player:hasTrait(CharacterTrait.ALL_THUMBS) then
        baseChance = baseChance - 1
    end
    if player:hasTrait(ToadTraitsRegistries.scrounger) then
        baseChance = baseChance + 1
    end
    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then
        baseChance = baseChance - 1
    end
    if baseChance < 1 then
        baseChance = 1
    end

    local worldAgeHours = GameTime:getInstance():getWorldAgeHours();

    for _, v in ipairs(page.backpacks) do
        local inv = v.inventory;
        if inv and inv:getParent() then
            local containerObj = inv:getParent();
            local modData = containerObj:getModData();

            if instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then
                local shouldRoll = false

                if not modData.bAntiqueRolled then
                    modData.bAntiqueRolled = true;
                    modData.bHoursWhenChecked = worldAgeHours;
                    modData.AllowRespawn = true;
                    containerObj:transmitModData();
                    shouldRoll = true
                elseif AllowRespawn and modData.AllowRespawn and modData.bAntiqueRolled then
                    if (modData.bHoursWhenChecked + HoursForLootRespawn) <= worldAgeHours then
                        modData.bHoursWhenChecked = worldAgeHours;
                        containerObj:transmitModData();
                        shouldRoll = true
                    end
                end

                if shouldRoll then
                    if playerdata.ContainerTraitIllegal then
                        playerdata.ContainerTraitIllegal = false;
                        if AllowRespawn then
                            modData.AllowRespawn = false;
                            containerObj:transmitModData();
                        end
                        return
                    end

                    local container = containerObj:getContainer()
                    local type = container:getType();
                    local isAllowedType = (type == "crate" or type == "metal_shelves");
                    local isAnywhere = SandboxVars.MoreTraits.AntiqueAnywhere == true;

                    if (isAllowedType or isAnywhere) and ZombRand(roll) <= baseChance then
                        local antiqueItemsList = {
                            "MoreTraits.AntiqueAxe", "MoreTraits.Thumper", "MoreTraits.ObsidianBlade",
                            "MoreTraits.Bag_PackerBag", "MoreTraits.BloodyCrowbar", "MoreTraits.Slugger",
                            "MoreTraits.AntiqueJacket", "MoreTraits.AntiqueVest", "MoreTraits.AntiqueBoots",
                            "MoreTraits.AntiqueSpear", "MoreTraits.AntiqueHammer", "MoreTraits.AntiqueKatana",
                            "MoreTraits.AntiqueMag1", "MoreTraits.AntiqueMag2", "MoreTraits.AntiqueMag3",
                        };

                        local itemType = antiqueItemsList[ZombRand(#antiqueItemsList) + 1];
                        if isClient() then
                            local args = { x = containerObj:getX(), y = containerObj:getY(), z = containerObj:getZ(), items = { itemType } }
                            sendClientCommand(player, 'ToadTraits', 'Antique', args)
                        else
                            container:AddItem(itemType)
                        end
                    end
                end
            end
        end
    end
end

local function ToadTraitVagabond(page, player)
    if not player:hasTrait(ToadTraitsRegistries.vagabond) then
        return
    end

    local baseChance = SandboxVars.MoreTraits.VagabondChance or 33
    if player:hasTrait(ToadTraitsRegistries.lucky) then
        baseChance = baseChance + (5 * luckimpact)
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        baseChance = baseChance - (5 * luckimpact)
    end

    for _, v in ipairs(page.backpacks) do
        local inv = v.inventory
        if inv and inv:getParent() then
            local containerObj = inv:getParent()
            local modData = containerObj:getModData()

            if not modData.bVagbondRolled and instanceof(containerObj, "IsoObject")
                    and not instanceof(containerObj, "IsoDeadBody") and containerObj:getContainer() then

                local container = containerObj:getContainer()
                if container:getType() == "bin" then
                    modData.bVagbondRolled = true
                    containerObj:transmitModData()

                    local extra = SandboxVars.MoreTraits.VagabondGuaranteedExtraLoot or 1
                    local iterations = ZombRand(0, 3) + extra
                    local itemsFound = {} -- To track items for the Server Command

                    local vagabondItems = {
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
                    }

                    for i = 1, iterations do
                        if ZombRand(100) <= baseChance then
                            local itemType = vagabondItems[ZombRand(#vagabondItems) + 1]
                            local itemName = getScriptManager():getItem(itemType):getDisplayName()

                            if isClient() then
                                table.insert(itemsFound, itemType)
                            else
                                container:AddItem(itemType) -- SP: Add it directly to the container
                            end

                            if itemName and MT_Config and MT_Config:getOption("VagabondAnnounce"):getValue() then
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_vagabond") .. " : " .. itemName, true, HaloTextHelper.getColorGreen())
                            end
                        end
                    end

                    -- We're informing the server of the items
                    if isClient() and #itemsFound > 0 then
                        local args = { x = containerObj:getX(), y = containerObj:getY(), z = containerObj:getZ(), items = itemsFound }
                        sendClientCommand(player, 'ToadTraits', 'Vagabond', args)
                    end
                end
            end
        end
    end
end

local function ToadTraitDepressive(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.depressive) then
        return
    end
    if playerdata.bToadTraitDepressed then
        return
    end

    local baseChance = 2

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        baseChance = baseChance - (1 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        baseChance = baseChance + (1 * luckimpact)
    end

    if player:hasTrait(ToadTraitsRegistries.selfdestructive) then
        baseChance = baseChance + 1
    end

    if ZombRand(100) < baseChance then
        local stats = player:getStats()
        local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS);
        local newUnhappiness = math.min(100, currentUnhappiness + 25)

        if isClient() then
            local args = { unhappiness = newUnhappiness }
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
        else
            stats:set(CharacterStat.UNHAPPINESS, newUnhappiness);
        end

        playerdata.bToadTraitDepressed = true
        print("Player is experiencing depression.");
    end
end

local function CheckDepress(player, playerdata)
    local depressed = playerdata.bToadTraitDepressed;
    if depressed then
        local stats = player:getStats()
        local unhappiness = stats:get(CharacterStat.UNHAPPINESS);
        if unhappiness < 25 then
            playerdata.bToadTraitDepressed = false;
        else
            local newUnhappiness = math.max(0, unhappiness - 0.01);
            if isClient() then
                local args = { unhappiness = newUnhappiness }
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
            else
                stats:set(CharacterStat.UNHAPPINESS, newUnhappiness);
            end
        end
    end
end

local function CheckSelfHarm(player)
    if not player:hasTrait(ToadTraitsRegistries.selfdestructive) then
        return
    end

    local stats = player:getStats()
    local unhappiness = stats:get(CharacterStat.UNHAPPINESS);
    local bodyDamage = player:getBodyDamage()
    local modifier = 3 - (player:hasTrait(ToadTraitsRegistries.depressive) and 1 or 0)
    local healthCap = 100 - (unhappiness / modifier)

    if unhappiness >= 25 and bodyDamage:getOverallBodyHealth() > healthCap then
        local damageAmount = 0.15
        local partIndexes = {}
        local parts = bodyDamage:getBodyParts()
        local partsSize = parts:size()

        for i = 0, partsSize - 1 do
            table.insert(partIndexes, i)
            if not isClient() then
                parts:get(i):AddDamage(damageAmount)
            end
        end

        if isClient() then
            local args = { bodyParts = partIndexes, partDamage = damageAmount }
            sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', args)
        end
    end
end

local function Blissful(player)
    if not player:hasTrait(ToadTraitsRegistries.blissful) then
        return
    end

    local stats = player:getStats()
    local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
    local boredom = stats:get(CharacterStat.BOREDOM)

    local args = {}
    local updateStats = false

    if unhappiness >= 0 then
        args.unhappiness = unhappiness - 0.01
        updateStats = true
    end

    if boredom >= 0 then
        args.boredom = boredom - 0.005
        updateStats = true
    end

    if updateStats then
        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
        else
            if args.unhappiness then
                stats:set(CharacterStat.UNHAPPINESS, args.unhappiness)
            end
            if args.boredom then
                stats:set(CharacterStat.BOREDOM, args.boredom)
            end
        end
    end
end

-- function Specialization(_player, _perk, _amount)
--     local player = _player;
--     local perk = _perk;
--     local amount = _amount;
--     local newamount = 0;
--     local skip = false;
--     local modifier = 75;
--     local perklvl = player:getPerkLevel(_perk);
--     local perkxpmod = 1;
--     if SandboxVars.MoreTraits.SpecializationXPPercent then
--         modifier = SandboxVars.MoreTraits.SpecializationXPPercent;
--     end
--     --shift decimal over two places for calculation purposes.
--     modifier = modifier * 0.01;
--     if perk == Perks.Fitness or perk == Perks.Strength then
--         skipxpadd = true;
--     end
--     if skipxpadd == false then
--         if player:hasTrait(ToadTraitsRegistries.specweapons) or player:hasTrait(ToadTraitsRegistries.specfood) or player:hasTrait(ToadTraitsRegistries.specguns) or player:hasTrait(ToadTraitsRegistries.specmove) or player:hasTrait(ToadTraitsRegistries.speccrafting) or player:hasTrait(ToadTraitsRegistries.specaid) then
--             if player:hasTrait(ToadTraitsRegistries.specweapons) then
--                 if perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Maintenance or perk == Perks.SmallBlunt or perk == Perks.Spear then
--                     skip = true;
--                 end
--             end
--             if player:hasTrait(ToadTraitsRegistries.specfood) then
--                 if perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.PlantScavenging or perk == Perks.Trapping or perk == Perks.Fishing then
--                     skip = true;
--                 end
--             end
--             if player:hasTrait(ToadTraitsRegistries.specguns) then
--                 if perk == Perks.Aiming or perk == Perks.Reloading then
--                     skip = true;
--                 end
--             end
--             if player:hasTrait(ToadTraitsRegistries.specmove) then
--                 if perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sprinting or perk == Perks.Sneak then
--                     skip = true;
--                 end
--             end
--             if player:hasTrait(ToadTraitsRegistries.speccrafting) then
--                 if perk == Perks.Woodwork or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring then
--                     skip = true;
--                 end
--             end
--             if player:hasTrait(ToadTraitsRegistries.specaid) then
--                 if perk == Perks.Doctor then
--                     skip = true;
--                 end
--             end
--             newamount = amount * modifier;
--             local currentxp = player:getXp():getXP(perk);
--             local correctamount = currentxp - newamount
--             local testxp = currentxp - amount;
--             --Check if the newxp amount would give the player a negative level.
--             --Lua doesn't support Switch Case statements so here's a massive If/then list. -_-
--             if skip == false then
--                 if perklvl == 0 and testxp <= 0 then
--                     skip = true;
--                 elseif perklvl == 1 and testxp <= 75 then
--                     skip = true;
--                 elseif perklvl == 2 and testxp <= 150 then
--                     skip = true;
--                 elseif perklvl == 3 and testxp <= 300 then
--                     skip = true;
--                 elseif perklvl == 4 and testxp <= 750 then
--                     skip = true;
--                 elseif perklvl == 5 and testxp <= 1500 then
--                     skip = true;
--                 elseif perklvl == 6 and testxp <= 3000 then
--                     skip = true;
--                 elseif perklvl == 7 and testxp <= 4500 then
--                     skip = true;
--                 elseif perklvl == 8 and testxp <= 6000 then
--                     skip = true;
--                 elseif perklvl == 9 and testxp <= 7500 then
--                     skip = true;
--                 elseif perklvl == 10 and testxp <= 9000 then
--                     skip = true;
--                 end
--             end
--             if skip == false then
--                 local xpforlevel = perk:getXpForLevel(perklvl) + 50;
--                 while player:getXp():getXP(perk) > correctamount do
--                     local curxp = player:getXp():getXP(perk);
--                     if xpforlevel >= curxp then
--                         break ;
--                     else
--                         AddXP(player, perk, -1 * 0.1);
--                     end
--                 end
--             end
--         end
--     else
--         skipxpadd = false;
--     end
-- end

local function Specialization(player, perk, amount)
    if skipxpadd or amount <= 0 then return end
    if perk == Perks.Fitness or perk == Perks.Strength then return end
    if player:getPerkLevel(perk) >= 10 then return end

    local specs = {
        [ToadTraitsRegistries.specweapons] = {
            Perks.Axe, Perks.Blunt, Perks.LongBlade, Perks.SmallBlade,
            Perks.Maintenance, Perks.SmallBlunt, Perks.Spear
        },
        [ToadTraitsRegistries.specfood] = {
            Perks.Cooking, Perks.Farming, Perks.PlantScavenging, Perks.Trapping,
            Perks.Fishing, Perks.Foraging, Perks.Tracking, Perks.Husbandry, Perks.Butchering
        },
        [ToadTraitsRegistries.specguns] = {
            Perks.Aiming, Perks.Reloading
        },
        [ToadTraitsRegistries.specmove] = {
            Perks.Lightfoot, Perks.Nimble, Perks.Sprinting, Perks.Sneak
        },
        [ToadTraitsRegistries.speccrafting] = {
            Perks.Blacksmith, Perks.Woodwork, Perks.Carving, Perks.Electricity, Perks.MetalWelding,
            Perks.Mechanics, Perks.Tailoring, Perks.Glassmaking, Perks.Masonry, Perks.Pottery,
            Perks.FlintKnapping
        },
        [ToadTraitsRegistries.specaid] = {
            Perks.Doctor
        }
    }

    local hasSpec = false
    for trait in pairs(specs) do
        if player:hasTrait(trait) then
            hasSpec = true
            break
        end
    end
    if not hasSpec then return end

    -- Exit if they are specialized in this perk (granting full XP)
    for trait, perks in pairs(specs) do
        if player:hasTrait(trait) then 
            for _, p in ipairs(perks) do
                if perk == p then return end
            end
        end
    end

    -- Otherwise they should only be getting 25% of the actual XP earned.
    local modifier = math.max(0, (SandboxVars.MoreTraits.SpecializationXPPercent or 75) * 0.01)
    -- local xpToRemove = amount - (amount * modifier) -- This grants them 75% of the XP they would normally get
    local xpToRemove = amount * modifier -- This actually grants them 25% of the XP they would normally get

    skipxpadd = true
    MT_AddXP(player, perk, -xpToRemove)
    skipxpadd = false
end

local function indefatigable(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.indefatigable) then
        return
    end

    if playerdata.bindefatigable or (SandboxVars.MoreTraits.IndefatigableOneUse and playerdata.indefatigabledisabled) then
        return
    end

    local bodyDamage = player:getBodyDamage()
    local zombies = getCell():getZombieList()
    local triggerHealth = isClient() and 25 or 15
    local shouldTrigger = false

    -- It's difficult to restore the player during a dragdown in MP.
    -- Instead it's easier to knockdown the zombies before that happens
    -- This should give them time to escape
    if isClient() then
        local nearbyZombies = 0
        if zombies then
            for i = 0, zombies:size() - 1 do
                local z = zombies:get(i)
                if z:DistTo(player) <= 1.5 then
                    nearbyZombies = nearbyZombies + 1
                end
            end
        end
        if nearbyZombies >= 4 then
            shouldTrigger = true
        end
    end

    if not shouldTrigger then
        if bodyDamage:getHealth() < triggerHealth or (not isClient() and player:isDeathDragDown()) then
            shouldTrigger = true
        end
    end

    if not shouldTrigger then return end

    if getActivatedMods():contains("MTAddonIndefatigableLol") then
        getSoundManager():PlaySound("indefatigabletheme", false, 0):setVolume(0.5);
    end

    if zombies and zombies:size() >= 3 then
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            if zombie:DistTo(player) <= 3.0 then
                zombie:setStaggerBack(true)
                zombie:setKnockedDown(true)
            end
        end
    end

    if not isClient() and player:isDeathDragDown() then
        print("Player dragged down, indefatigable activated");
        playerdata.IndefatigableHasBeenDraggedDown = true;
        player:setPlayingDeathSound(false);
        player:setDeathDragDown(false);
        player:setHitReaction("EvasiveBlocked");
    end

    print("Healed to full.");
    local partIndexes = {}
    local bodyParts = bodyDamage:getBodyParts()
    for i = 0, bodyParts:size() - 1 do
        table.insert(partIndexes, i)
        local b = bodyParts:get(i);
        if tableContains(playerdata.TraitInjuredBodyList, i) == false then
            b:RestoreToFullHealth();
        else
            b:SetHealth(100);
        end
    end
    bodyDamage:setOverallBodyHealth(100);

    if isClient() then
        local args = { bodyParts = partIndexes, indefatigable = true, skipRestoreList = playerdata.TraitInjuredBodyList }
        sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', args)
    end
    
    if bodyDamage:IsInfected() then
        if not playerdata.indefatigablecuredinfection or SandboxVars.MoreTraits.IndefatigableOneUse then
            if isClient() then
                local args = { zombie_fever = 0, zombie_infection = 0, panic = 0, clear_wounds = true }
                print(args)
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
            else
                local stats = player:getStats();
                bodyDamage:setInfected(false);
                bodyDamage:setInfectionMortalityDuration(-1);
                bodyDamage:setInfectionTime(-1);
                stats:set(CharacterStat.PANIC, 0)
                stats:set(CharacterStat.ZOMBIE_FEVER, 0);
                stats:set(CharacterStat.ZOMBIE_INFECTION, 0);
            end
            playerdata.indefatigablecuredinfection = true;
        end
    end

    playerdata.bindefatigable = true;
    playerdata.indefatigablecooldown = 0;

    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen());

    if SandboxVars.MoreTraits.IndefatigableOneUse then
        playerdata.indefatigabledisabled = true
    end
end

local function indefatigablecounter(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.indefatigable) or not playerdata.bindefatigable then
        return
    end

    local recharge = (SandboxVars.MoreTraits.IndefatigableRecharge or 7) * 24

    local multiplier = 1
    if playerdata.indefatigablecuredinfection then
        multiplier = multiplier * 2
    end
    if playerdata.IndefatigableHasBeenDraggedDown then
        multiplier = multiplier * 2
    end

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

local function badteethtrait(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.badteeth) then return end
    local bodyDamage = player:getBodyDamage()
    local healthTimer = bodyDamage:getHealthFromFoodTimer()

    -- MP Performance Optimization: Added in a delay to prevent spam on the serverside
    if isClient() then
        local currentTime = getTimestampMs()
        playerdata.lastBadTeethUpdate = playerdata.lastBadTeethUpdate or 0
        
        if currentTime < playerdata.lastBadTeethUpdate + 1000 then 
            playerdata.fPreviousHealthFromFoodTimer = healthTimer
            return 
        end
        playerdata.lastBadTeethUpdate = currentTime
    end

    playerdata.fBadTeethLastSentPain = playerdata.fBadTeethLastSentPain or 0
    
    if healthTimer > 1000 and healthTimer > playerdata.fPreviousHealthFromFoodTimer then
        local painIncrease = (healthTimer - playerdata.fPreviousHealthFromFoodTimer) * 0.01
        local head = bodyDamage:getBodyPart(BodyPartType.Head)
        local newPain = math.min(head:getAdditionalPain() + painIncrease, 100)

        if isClient() then
            if math.abs(newPain - playerdata.fBadTeethLastSentPain) >= 1 then
                local headPart = BodyPartType.ToIndex(BodyPartType.Head)
                sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', { bodyPart = headPart, partPain = newPain })
                playerdata.fBadTeethLastSentPain = newPain
            end
        else
            head:setAdditionalPain(newPain)
        end
    end
    playerdata.fPreviousHealthFromFoodTimer = healthTimer
end

local function hardytrait(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.hardy) then
        return
    end

    -- Added in delay to do a check every second to avoid spam
    local currentTime = getTimestampMs()
    playerdata.lastHardyUpdate = playerdata.lastHardyUpdate or 0
    if currentTime < playerdata.lastHardyUpdate + 1000 then
        return
    end
    playerdata.lastHardyUpdate = currentTime

    local stats = player:getStats()
    local currentEndurance = stats:get(CharacterStat.ENDURANCE)
    local regenAmount = 0.05
    if SandboxVars.MoreTraits.HardyEndurance then
        regenAmount = SandboxVars.MoreTraits.HardyEndurance / 500
    end

    local args = {}
    local updateStats = false

    if currentEndurance < 0.85 and playerdata.iHardyEndurance >= 1 then
        args.endurance = math.min(currentEndurance + regenAmount, 1.0)
        playerdata.iHardyEndurance = playerdata.iHardyEndurance - 1
        updateStats = true
        
        if not isServer() and MT_Config and MT_Config:getOption("HardyNotifier"):getValue() then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardyendurance") .. " : " .. playerdata.iHardyEndurance, false, HaloTextHelper.getColorRed())
        end

    elseif currentEndurance >= 1.0 and playerdata.iHardyEndurance < playerdata.iHardyMaxEndurance then
        args.endurance = currentEndurance - regenAmount
        playerdata.iHardyEndurance = playerdata.iHardyEndurance + 1
        updateStats = true

        if not isServer() and MT_Config and MT_Config:getOption("HardyNotifier"):getValue() then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardyendurance") .. " : " .. playerdata.iHardyEndurance, true, HaloTextHelper.getColorGreen())
        end
    end

    if updateStats then
        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
        else
            stats:set(CharacterStat.ENDURANCE, args.endurance)
        end
    end
end

local function drinkerupdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

    local stats = player:getStats()
    local drunkness = stats:get(CharacterStat.INTOXICATION)
    local hoursSinceDrink = playerdata.iHoursSinceDrink or 0
    local hoursThreshold = (SandboxVars.MoreTraits.AlcoholicFrequency or 24) * 1.5
    local divider = 5

    if hoursThreshold <= 2 then
        divider = 0.1
    elseif hoursThreshold <= 5 then
        divider = 0.2
    elseif hoursThreshold <= 10 then
        divider = 0.5
    elseif hoursThreshold <= 20 then
        divider = 1
    end

    local withdrawalIntensity = hoursSinceDrink / divider
    local args = {}
    local updateStats = false

    if drunkness >= 10 then
        if not playerdata.bSatedDrink then
            playerdata.bSatedDrink = true
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicsatisfied"), true, HaloTextHelper.getColorGreen())
        end
        playerdata.iHoursSinceDrink = 0
        args.anger = 0
        args.stress = 0
        updateStats = true
    end

    if drunkness > 0 then
        if internalTick and internalTick >= 25 then
            args.fatigue = math.max(0, stats:get(CharacterStat.FATIGUE) - 0.01)
            updateStats = true
        end
    end

    if not playerdata.bSatedDrink then
        if hoursSinceDrink > hoursThreshold then
            local currentPain = stats:get(CharacterStat.PAIN)
            args.pain = math.min(100, currentPain + (withdrawalIntensity * 0.1))
            updateStats = true
        end

        if internalTick == 30 then
            local anger = stats:get(CharacterStat.ANGER)
            local stress = stats:get(CharacterStat.STRESS)
            local angerLimit = 0.05 + (withdrawalIntensity * 0.1) / 3
            local stressLimit = 0.15 + (withdrawalIntensity * 0.1) / 2

            if anger < angerLimit then
                args.anger = anger + 0.01
                updateStats = true
            end
            if stress < stressLimit then
                args.stress = stress + 0.01
                updateStats = true
            end
        end
    end

    if updateStats then
        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
        else
            if args.anger then
                stats:set(CharacterStat.ANGER, args.anger)
            end
            if args.stress then
                stats:set(CharacterStat.STRESS, args.stress)
            end
            if args.fatigue then
                stats:set(CharacterStat.FATIGUE, args.fatigue)
            end
            if args.pain then
                stats:set(CharacterStat.PAIN, args.pain)
            end
        end
    end
end

local function drinkertick(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

    local hourThreshold = SandboxVars.MoreTraits.AlcoholicFrequency or 24

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        hourThreshold = hourThreshold + (4 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        hourThreshold = hourThreshold - (2 * luckimpact)
    end

    if player:hasTrait(ToadTraitsRegistries.lightdrinker) then
        hourThreshold = hourThreshold - 2;
    end

    playerdata.iHoursSinceDrink = (playerdata.iHoursSinceDrink or 0) + 1

    if playerdata.bSatedDrink then
        if playerdata.iHoursSinceDrink >= hourThreshold then
            local divider = 4
            if hourThreshold <= 2 then
                divider = 0.1
            elseif hourThreshold <= 5 then
                divider = 0.2
            elseif hourThreshold <= 10 then
                divider = 0.5
            elseif hourThreshold <= 20 then
                divider = 1
            end

            if ZombRand(100) <= (hourThreshold / divider) then
                playerdata.bSatedDrink = false
                print("Player needs alcohol.")
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicneed"), false, HaloTextHelper.getColorRed())
            end
        end
    else
        if not isServer() and MT_Config and MT_Config:getOption("DrinkNotifier"):getValue() then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_alcoholicneed"), false, HaloTextHelper.getColorRed())
        end
    end
end

local function drinkerpoison(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

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

        local poisonLevel = 0
        if SandboxVars.MoreTraits.NonlethalAlcoholic then
            poisonLevel = 20
        else
            local hourThreshold = SandboxVars.MoreTraits.AlcoholicWithdrawal or 72
            local divider = 5
            if hourThreshold <= 2 then
                divider = 0.5
            elseif hourThreshold <= 5 then
                divider = 0.75
            elseif hourThreshold <= 10 then
                divider = 1
            elseif hourThreshold <= 20 then
                divider = 2
            elseif hourThreshold <= 24 then
                divider = 4
            elseif hourThreshold <= 48 then
                divider = 5
            end

            poisonLevel = math.min(100, playerdata.iHoursSinceDrink / divider)
        end

        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', { poison = poisonLevel })
        else
            local stats = player:getStats()
            stats:set(CharacterStat.POISON, poisonLevel)
        end

        playerdata.iWithdrawalCooldown = ZombRand(12, 24)
    end

    if playerdata.iWithdrawalCooldown > 0 then
        playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown - 1
    end
end

local function bouncerupdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.bouncer) then
        return
    end

    if playerdata.iBouncercooldown > 0 then
        playerdata.iBouncercooldown = playerdata.iBouncercooldown - 1
        return
    end

    local chance = SandboxVars.MoreTraits.BouncerEffectiveness or 5
    local cooldown = SandboxVars.MoreTraits.BouncerCooldown or 60
    local distance = SandboxVars.MoreTraits.BouncerDistance or 1.75

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        chance = chance + (luckimpact or 1)
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        chance = chance - (luckimpact or 1)
    end

    local enemies = player:getSpottedList()
    if enemies:size() < 3 then
        return
    end

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

local function unwavering(actor, target, weapon, damage)
    if not actor or not target or not weapon then return end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.unwavering) then return end
    
    if weapon:getType() == "BareHands" and not player:hasTrait(ToadTraitsRegistries.martial) then 
        return 
    end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local pain = stats:get(CharacterStat.PAIN)

    local extraDamageMult = 0
    local maxBoost = SandboxVars.MoreTraits.UnwaveringDamageBoost or 2.0
    local bonus = maxBoost - 1.0

    if endurance <= 0.25 or fatigue >= 0.8 or pain >= 75 then
        extraDamageMult = maxBoost -- Default 2.0
    elseif endurance <= 0.50 or fatigue >= 0.7 or pain >= 50 then
        extraDamageMult = 1.0 + (bonus * 0.5) -- Default 1.5
    elseif endurance <= 0.75 or fatigue >= 0.6 or pain >= 20 then
        extraDamageMult = 1.0 + (bonus * 0.25) -- Default 1.25
    end

    if extraDamageMult <= 0 then return end

    local extraDamage = damage * extraDamageMult
    local targetData = target:getModData()
    if not targetData then
        return
    end
    target:setHealth(target:getHealth() - extraDamage)
    if target:getHealth() <= 0 then
        if not targetData.TraitKillProcessed then
            targetData.TraitKillProcessed = true
            target:Kill(player)
            player:setZombieKills(player:getZombieKills() + 1)
        end
    end
end

local function martial(actor, target, weapon, damage)
    if not actor or not target or not weapon then return end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.martial) then
        return
    end

    local playerdata = player:getModData();
    if not playerdata then
        return
    end

    local stats = player:getStats();
    local endurance = stats:get(CharacterStat.ENDURANCE);
    local isBareHands = (weapon:getType() == "BareHands");

    local allow = true
    if not SandboxVars.MoreTraits.MartialWeapons and player:getPrimaryHandItem() ~= nil then
        allow = false;
    end

    if isBareHands and allow then
        local scaling = (SandboxVars.MoreTraits.MartialScaling or 100) * 0.01
        local blunt = player:getPerkLevel(Perks.SmallBlunt)
        local critchance = (5 + blunt) * scaling

        if player:hasTrait(ToadTraitsRegistries.lucky) then
            critchance = critchance + 1 * luckimpact
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            critchance = critchance - 1 * luckimpact
        end

        local damageAdj = 1.0
        if endurance < 0.25 then
            damageAdj = 0.25
        elseif endurance < 0.5 then
            damageAdj = 0.5
        elseif endurance < 0.75 then
            damageAdj = 0.75
        end

        local martialDamage = damage
        if target:isZombie() and ZombRand(0, 101) <= critchance and not player:hasTrait(ToadTraitsRegistries.mundane) then
            martialDamage = martialDamage * 4
        end

        martialDamage = martialDamage * 0.1 * damageAdj * scaling

        if not isServer() and MT_Config and MT_Config:getOption("MartialDamage"):getValue() then
            HaloTextHelper.addText(player, "Damage: " .. tostring(round(martialDamage, 3)), " ", HaloTextHelper.getColorGreen())
        end

        local targetData = target:getModData();
        if not targetData then
            return
        end

        target:setHealth(target:getHealth() - martialDamage)
        if target:getHealth() <= 0 then
            if not targetData.TraitKillProcessed then
                targetData.TraitKillProcessed = true
                target:Kill(player)
                player:setZombieKills(player:getZombieKills() + 1)
            end
        end

        local newEndurance = math.max(0, endurance - 0.002)
        if isClient() then
            local args = { endurance = newEndurance }
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
        else
            stats:set(CharacterStat.ENDURANCE, newEndurance)
        end
        MT_AddXP(player, Perks.SmallBlunt, martialDamage * 2 * blunt)
    end
end

local function actionhero(actor, target, weapon, damage)
    if not weapon then
        return
    end
    if not actor then
        return 
    end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.actionhero) then
        return ;
    end

    if weapon:getType() == "BareHands" and not player:hasTrait(ToadTraitsRegistries.martial) then
        return
    end

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

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        critchance = critchance + 5 * luckimpact;
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        critchance = critchance - 5 * luckimpact;
    end

    if target:isZombie() and ZombRand(0, 101) <= critchance and not player:hasTrait(ToadTraitsRegistries.mundane) then
        damage = damage * 5
    end

    local extraDamage = (damage * multiplier) * 0.1;
    local targetData = target:getModData();
    if not targetData then
        return
    end
    target:setHealth(target:getHealth() - extraDamage)
    if target:getHealth() <= 0 then
        if not targetData.TraitKillProcessed then
            targetData.TraitKillProcessed = true
            target:Kill(player)
            player:setZombieKills(player:getZombieKills() + 1)
        end
    end
end

-- Melee Traits (ProBlade, ProBlunt, ProSpear, Tavern Brawler)
local function MT_MeleeTraits(actor, target, weapon, damage)
    if not actor or not target or not weapon or not target:isZombie() then return end
    
    local player = actor
    local weaponData = weapon:getModData()
    local totalDamage = 0
    
    if weaponData.iLastWeaponCond == nil then
        weaponData.iLastWeaponCond = weapon:getCondition()
    end

    local hasBlade = player:hasTrait(ToadTraitsRegistries.problade)
    local hasBlunt = player:hasTrait(ToadTraitsRegistries.problunt)
    local hasSpear = player:hasTrait(ToadTraitsRegistries.prospear)

    if (hasBlade or hasBlunt or hasSpear) and not player:hasTrait(ToadTraitsRegistries.mundane) then
        local hasTrait = false
        local critchance = 5
        
        -- Logic for category matching
        if hasBlade and (weapon:isOfWeaponCategory(WeaponCategory.AXE) or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE) or weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE)) then
            critchance = critchance + player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade)
            hasTrait = true
        elseif hasBlunt and (weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLUNT) or weapon:isOfWeaponCategory(WeaponCategory.BLUNT)) then
            critchance = critchance + player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt)
            hasTrait = true
        elseif hasSpear and weapon:isOfWeaponCategory(WeaponCategory.SPEAR) then
            critchance = critchance + player:getPerkLevel(Perks.Spear)
            hasTrait = true
        end

        if hasTrait then
            if player:hasTrait(ToadTraitsRegistries.lucky) then critchance = critchance + (1 * (luckimpact or 1)) end
            if player:hasTrait(ToadTraitsRegistries.unlucky) then critchance = critchance - (1 * (luckimpact or 1)) end

            local currentDamage = damage
            if ZombRand(0, 101) <= critchance then
                currentDamage = currentDamage * 2
            end
            
            totalDamage = totalDamage + ((currentDamage * 1.2) * 0.1)

            if weaponData.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1)
                end
            end
        end
    end

    -- Tavern Brawler
    if player:hasTrait(ToadTraitsRegistries.tavernbrawler) then
        local isImprovised = false
        local whitelist = { "ToolWeapon", "WeaponCrafted", "CookingWeapon", "HouseholdWeapon", "FirstAidWeapon", "GardeningWeapon", "SportsWeapon", "MaterialWeapon", "JunkWeapon", "InstrumentWeapon", "BrokenWeapon", "VehicleMaintenanceWeapon" }
        
        if weapon:isOfWeaponCategory(WeaponCategory.IMPROVISED) or tableContains(whitelist, weapon:getDisplayCategory() or "") then
            isImprovised = true
        end

        if isImprovised then
            local multiplier = 1
            local repairChance = 50
            
            if weapon:isOfWeaponCategory(WeaponCategory.SPEAR) then
                repairChance = 0
                multiplier = 0.25
            end

            if player:hasTrait(ToadTraitsRegistries.lucky) then 
                repairChance = repairChance + (5 * (luckimpact or 1))
                multiplier = multiplier + 0.1
            elseif player:hasTrait(ToadTraitsRegistries.unlucky) then 
                repairChance = repairChance - (5 * (luckimpact or 1))
                multiplier = multiplier - 0.1
            end

            if weapon:getConditionLowerChance() <= 2 then
                repairChance = repairChance + 25
                multiplier = multiplier + 0.5
            end

            totalDamage = totalDamage + ((damage * multiplier) * 0.1)

            if weaponData.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= math.min(95, repairChance) then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1)
                end
            end
        end
    end

    if totalDamage > 0 then
        local targetData = target:getModData();
        if not targetData then
            return
        end
        target:setHealth(target:getHealth() - totalDamage)
        if target:getHealth() <= 0 then
            if not targetData.TraitKillProcessed then
                targetData.TraitKillProcessed = true
                target:Kill(player)
                player:setZombieKills(player:getZombieKills() + 1)
            end
        end
    end

    weaponData.iLastWeaponCond = weapon:getCondition()
end

local function progun(actor, weapon)
    if not actor or not weapon then return end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.progun) then
        return
    end

    if not weapon then
        return
    end
    local weapondata = weapon:getModData();
    if not weapondata then
        return
    end

    local aiming = player:getPerkLevel(Perks.Aiming);
    local reloading = player:getPerkLevel(Perks.Reloading);
    local chance = aiming + reloading + 10;

    local isFirearm = false;
    if weapon:isRanged() then
        isFirearm = true;
    elseif weapon.getSubCategory and weapon:getSubCategory() == "Firearm" then
        isFirearm = true;
    end

    if isFirearm then
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            chance = chance + 1 * luckimpact
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            chance = chance - 1 * luckimpact
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

        if not weapon.getMaxAmmo or not weapon.getCurrentAmmoCount then
            return
        end

        local currentCapacity = weapon:getCurrentAmmoCount();
        local maxCapacity = weapon:getMaxAmmo();
        if SandboxVars.MoreTraits.ProwessGunsAmmoRestore and ZombRand(0, 101) <= chance then
            if currentCapacity < maxCapacity and currentCapacity > 0 then
                if isClient() then
                    sendClientCommand(player, 'ToadTraits', 'ProwessGuns', { weaponID = weapon:getID() })
                else
                    weapon:setCurrentAmmoCount(currentCapacity + 1);
                end

                if not isServer() and MT_Config and MT_Config:getOption("ProwessGunsAmmo"):getValue() then
                    HaloTextHelper.addText(player, getText("UI_progunammo"), "", HaloTextHelper.getColorGreen());
                end
            end
        end
    end
end

local UMBRELLA_TYPES = {
    ["UmbrellaRed"] = true, ["UmbrellaBlue"] = true,
    ["UmbrellaWhite"] = true, ["UmbrellaBlack"] = true
}

local function albino(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.albino) then
        return
    end

    local bodyDamage = player:getBodyDamage()
    local head = bodyDamage:getBodyPart(BodyPartType.Head)
    local modpain = playerdata.AlbinoTimeSpentOutside or 0

    if isClient() then
        local currentTime = getTimestampMs()
        playerdata.lastAlbinoUpdate = playerdata.lastAlbinoUpdate or 0
        if currentTime < playerdata.lastAlbinoUpdate + 1000 then return end
        playerdata.lastAlbinoUpdate = currentTime
    end

    local finalPain = 0
    if player:isOutside() then
        local tod = getGameTime():getTimeOfDay()
        if tod > 8 and tod < 17 then
            local stats = player:getStats()
            if stats:get(CharacterStat.PAIN) < 25 and not playerdata.bisAlbinoOutside then
                if not isServer() and MT_Config and MT_Config:getOption("AlbinoAnnounce"):getValue() then
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_albino"), false, HaloTextHelper.getColorRed())
                end
                playerdata.bisAlbinoOutside = true
            end

            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()
            local hasUmbrella = (primary and UMBRELLA_TYPES[primary:getType()]) or
                                (secondary and UMBRELLA_TYPES[secondary:getType()])
            finalPain = hasUmbrella and (modpain / 1.5) or modpain
        else
            if modpain > 0 then finalPain = modpain / 2 end
        end
    else
        playerdata.bisAlbinoOutside = false
        if modpain > 0 then finalPain = modpain / 4 end
    end

    if isClient() then
        playerdata.fAlbinoLastSentPain = playerdata.fAlbinoLastSentPain or 0
        if math.abs(finalPain - playerdata.fAlbinoLastSentPain) >= 1 then
            local headPart = BodyPartType.ToIndex(BodyPartType.Head)
            sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', { bodyPart = headPart, partPain = finalPain })
            playerdata.fAlbinoLastSentPain = finalPain
        end
    else
        head:setAdditionalPain(finalPain)
    end
end

local function AlbinoTimer(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.albino) then
        return
    end
    playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside or 0

    if player:isOutside() then
        local tod = getGameTime():getTimeOfDay()
        if tod > 8 and tod < 17 then
            if playerdata.AlbinoTimeSpentOutside < 40 then
                local primary = player:getPrimaryHandItem()
                local secondary = player:getSecondaryHandItem()
                local hasUmbrella = (primary and UMBRELLA_TYPES[primary:getType()]) or
                        (secondary and UMBRELLA_TYPES[secondary:getType()])
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

local function OnEquipSecondary(player, item)
    if item == nil then return end

    if player:hasTrait(ToadTraitsRegistries.amputee) or getActivatedMods():contains("Amputation") then
        if item and item ~= nil then
            player:setSecondaryHandItem(nil);
            HaloTextHelper.addText(player, getText("UI_trait_amputee_missingarm"), HaloTextHelper.getColorRed());
        end
    end
end

local function amputee(player, justGotInfected)
    if not player:hasTrait(ToadTraitsRegistries.amputee) or getActivatedMods():contains("Amputation") then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if not justGotInfected and bodyDamage:getOverallBodyHealth() >= 100 then
        return
    end

    local parts = {
        BodyPartType.UpperArm_L,
        BodyPartType.ForeArm_L,
        BodyPartType.Hand_L
    }

    local needToHeal = false
    for _, partType in ipairs(parts) do
        local part = bodyDamage:getBodyPart(partType)
        if part:HasInjury() then
            needToHeal = true
            if not isClient() then
                part:RestoreToFullHealth()
            end
        end
    end

    if needToHeal or justGotInfected then
        if isClient() then
            local args = { zombie_fever = 0, zombie_infection = 0,
                clear_wounds = true, amputee = true
            }
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
        else
            if justGotInfected then
                local stats = player:getStats()
                bodyDamage:setInfected(false)
                bodyDamage:setInfectionMortalityDuration(-1)
                bodyDamage:setInfectionTime(-1)
                stats:set(CharacterStat.ZOMBIE_FEVER, 0)
                stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
            end
        end
    end
end

-- This is going to need some proper testing to determine what should be acceptable values for both traits as well as the actual cost to these traits
-- As well as if this is actually updating for other MP clients
-- OnPlayerMove doesn't seem to work for this in MP so we're moving this to OnPlayerUpdate (Build 42.13.1). This may change in the future
local FastGimpVector = Vector2.new(0, 0)
local function MT_FastGimpTraits(player)
    if not player:hasTrait(ToadTraitsRegistries.fast) and not player:hasTrait(ToadTraitsRegistries.gimp) then 
        return 
    end
    if not player:isPlayerMoving() then return end  

    local modifier  = 0

    if player:hasTrait(ToadTraitsRegistries.fast) then
        if player:isSprinting() then
            modifier = SandboxVars.MoreTraits.FastSprint or 0.75
        elseif player:isRunning() then
            modifier = SandboxVars.MoreTraits.FastRunning or 0.5
        elseif player:isWalking() then
            modifier = SandboxVars.MoreTraits.FastWalking or 0.25
        end
    elseif player:hasTrait(ToadTraitsRegistries.gimp) then
        if player:isSprinting() then
            modifier = SandboxVars.MoreTraits.GimpSprint or -0.25
        elseif player:isRunning() then
            modifier = SandboxVars.MoreTraits.GimpRunning or -0.5
        elseif player:isWalking() then
            modifier = SandboxVars.MoreTraits.GimpWalking or -0.75
        end
    end

    if modifier == 0 then return end

    player:getDeferredMovement(FastGimpVector)

    local x = FastGimpVector:getX()
    local y = FastGimpVector:getY()

    FastGimpVector:setX(x * modifier)
    FastGimpVector:setY(y * modifier)

    if isClient() and internalTick % 10 == 0 then
        sendClientCommand(player, 'ToadTraits', 'FastGimp', { xSpeed = x, ySpeed = y })
    end
    
    player:Move(FastGimpVector)
end

local function checkBloodTraits(player)
    local isAnemic = player:hasTrait(ToadTraitsRegistries.anemic)
    local isThick = player:hasTrait(ToadTraitsRegistries.thickblood)
    if not isAnemic and not isThick then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getNumPartsBleeding() <= 0 then return end

    local parts = bodyDamage:getBodyParts()
    local anemicParts = {}
    local thickParts = {}

    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:bleeding() and not b:IsBleedingStemmed() then
            local isNeck = (b:getType() == BodyPartType.Neck)
            local isHead = (b:getType() == BodyPartType.Head)

            if isAnemic then
                local adjust = 0.4
                if isNeck or isHead then adjust = adjust * 2 end
                table.insert(anemicParts, {part = i, amount = adjust})
            elseif isThick then
                local adjust = 0.15
                if isNeck or isHead then adjust = adjust * 2 end
                table.insert(thickParts, {part = i, amount = adjust})
            end
        end
    end

    if #anemicParts > 0 then
        if isClient() then
            for _, data in ipairs(anemicParts) do
                sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', { bodyPart = data.part, partHealthReduce = data.amount })
            end
        else
            for _, data in ipairs(anemicParts) do
                parts:get(data.part):ReduceHealth(data.amount)
            end
        end
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_anemic"), false, HaloTextHelper.getColorRed())
    end
    if #thickParts > 0 then
        if isClient() then
            for _, data in ipairs(thickParts) do
                sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', { bodyPart = data.part, partHealthAdd = data.amount })
            end
        else
            for _, data in ipairs(thickParts) do
                parts:get(data.part):AddHealth(data.amount)
            end
        end
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickblood"), true, HaloTextHelper.getColorGreen())
    end
end

local function vehicleCheck(player)
    if getActivatedMods():contains("DrivingSkill") then
        return
    end

    if player:isDriving() then
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

local function SuperImmune(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) then
        return
    end

    local stats = player:getStats();
    local zombieInfection = stats:get(CharacterStat.ZOMBIE_INFECTION);
    local bodyDamage = player:getBodyDamage();

    if zombieInfection <= 0 then
        return
    end

    if isClient() then
        local args = { zombie_fever = 100, zombie_infection = 0, clear_wounds = true }
        sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
    else
        -- We set the Fever here to 100 for the Health Loss and simulate fighting the infection
        stats:set(CharacterStat.ZOMBIE_FEVER, 100);
        stats:set(CharacterStat.ZOMBIE_INFECTION, 0);
        bodyDamage:setInfected(false);
        bodyDamage:setInfectionMortalityDuration(-1);
        bodyDamage:setInfectionTime(-1);

        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i);
            if b:HasInjury() and b:isInfectedWound() then
                b:SetInfected(false);
                b:setInfectedWound(false);
            end
        end
    end

    local minimum = SandboxVars.MoreTraits.SuperImmuneMinDays or 10;
    local maximum = SandboxVars.MoreTraits.SuperImmuneMaxDays or 30;
    if minimum > maximum then
        minimum, maximum = maximum, minimum
    end

    local timeOfRecovery = 0;
    if minimum == maximum + 1 then
        timeOfRecovery = minimum;
    else
        timeOfRecovery = ZombRand(minimum, maximum + 1);
    end

    if player:hasTrait(CharacterTrait.FAST_HEALER) then
        timeOfRecovery = timeOfRecovery - 5;
    end
    if player:hasTrait(CharacterTrait.SLOW_HEALER) then
        timeOfRecovery = timeOfRecovery + 5;
    end
    if player:hasTrait(ToadTraitsRegistries.lucky) then
        timeOfRecovery = timeOfRecovery - 2 * luckimpact;
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        timeOfRecovery = timeOfRecovery + 2 * luckimpact;
    end

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

local function SuperImmuneRecoveryProcess(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) or not playerdata.SuperImmuneActive then
        return
    end

    local recoveryDays = math.min(playerdata.SuperImmuneRecovery or 10, SandboxVars.MoreTraits.SuperImmuneMaxDays or 30)
    local minutesPerDay = 1440
    local maxRecoveryMinutes = recoveryDays * minutesPerDay
    local timeElapsed = playerdata.SuperImmuneMinutesPassed or 0
    local speedRun = playerdata.QuickSuperImmune and 6 or 1

    local stats = player:getStats()
    local illness = stats:get(CharacterStat.ZOMBIE_FEVER)
    local startIllness = illness -- Store to check if we need to sync later

    if timeElapsed < maxRecoveryMinutes then
        playerdata.SuperImmuneTextSaid = false

        local illnessChange = 0
        if timeElapsed <= 360 then
            illnessChange = ZombRand(100, 501) / 6000
        else
            local isLateStage = timeElapsed >= (maxRecoveryMinutes / 2)
            local low = isLateStage and 5 or 10
            local high = isLateStage and 36 or 46
            illnessChange = (25 - ZombRand(low, high)) / 600
        end

        illness = illness - (illnessChange * speedRun)

        local healValue = 0
        if player:hasTrait(CharacterTrait.FAST_HEALER) then healValue = -0.25 / 60
        elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then healValue = 0.25 / 60 end

        illness = illness + (healValue * speedRun)

        if illness < 26 then illness = illness + (0.166 * speedRun) end

        if illness > 89 and not playerdata.SuperImmuneLethal then 
            illness = illness - (0.333 * speedRun) 
        end

        illness = illness - (playerdata.SuperImmuneMinutesWellFed / 50)
        playerdata.SuperImmuneAbsoluteWellFedAmount = (playerdata.SuperImmuneAbsoluteWellFedAmount or 0) + playerdata.SuperImmuneMinutesWellFed
        playerdata.SuperImmuneMinutesWellFed = 0
        
        local totalTime = speedRun
        if playerdata.SuperImmuneAbsoluteWellFedAmount > 60 then
            totalTime = totalTime + speedRun
            playerdata.SuperImmuneAbsoluteWellFedAmount = playerdata.SuperImmuneAbsoluteWellFedAmount - 60
        end
        playerdata.SuperImmuneMinutesPassed = timeElapsed + totalTime

        -- Lets make sure their infection doesn't drop too far down whilst recovering
        if illness < 15 then
            illness = 50
            if isClient() then
                local args = { zombie_fever = illness }
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
            else
                stats:set(CharacterStat.ZOMBIE_FEVER, illness);
            end
        end

        if isDebugEnabled() and not isServer() then
            player:Say("Mins to recovery: " .. (maxRecoveryMinutes - playerdata.SuperImmuneMinutesPassed))
        end
    else
        if illness > 0 then
            if not playerdata.SuperImmuneFeverNotified and not isServer() and MT_Config and MT_Config:getOption("SuperImmuneAnnounce"):getValue() then
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_superimmune_feverbreak"), true, HaloTextHelper.getColorGreen())
                playerdata.SuperImmuneFeverNotified = true
            end

            -- Once they've beaten the infection, we want to clear the ZOMBIE_FEVER
            local breakInfectionMultiplier = 1.0
            if player:hasTrait(CharacterTrait.FAST_HEALER) then
                breakInfectionMultiplier = 1.5
            elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
                breakInfectionMultiplier = 0.5
            end
            
            illness = math.max(0, illness - (breakInfectionMultiplier * speedRun))

            playerdata.SuperImmuneInfections = 0
        else
            if not isServer() and MT_Config:getOption("SuperImmuneAnnounce"):getValue() then
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_superimmune_fullheal"), true, HaloTextHelper.getColorGreen())
            end

            playerdata.SuperImmuneActive = false
            playerdata.SuperImmuneMinutesPassed = 0
            playerdata.SuperImmuneRecovery = 0
            playerdata.SuperImmuneHealedOnce = true
            playerdata.SuperImmuneAbsoluteWellFedAmount = 0
            playerdata.SuperImmuneInfections = 0
            playerdata.SuperImmuneLethal = false
            playerdata.SuperImmuneTextSaid = false
            playerdata.SuperImmuneFeverNotified = false
        end

        if illness == 0 and not playerdata.SuperImmuneTextSaid and not isServer() and MT_Config and MT_Config:getOption("SuperImmuneAnnounce"):getValue() then
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_superimmunewon"), true, HaloTextHelper.getColorGreen())
            playerdata.SuperImmuneTextSaid = true
        end
    end

    if illness ~= startIllness then
        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', { zombie_fever = illness })
        else
            stats:set(CharacterStat.ZOMBIE_FEVER, illness)
        end
        
    end
end

local function SuperImmuneFakeInfectionHealthLoss(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) then
        return
    end
    if not playerdata.SuperImmuneActive then
        return
    end

    local maxHealth = isClient() and 20 or 15;
    if player:hasTrait(ToadTraitsRegistries.indefatigable) then
        maxHealth = isClient() and 30 or 25;
    end

    local stats = player:getStats();
    local illness = stats:get(CharacterStat.ZOMBIE_FEVER);
    if SandboxVars.MoreTraits.SuperImmuneWeakness then
        local limit = 4;

        if playerdata.SuperImmuneHealedOnce then
            limit = 5;
        end

        if player:hasTrait(CharacterTrait.FAST_HEALER) then
            limit = limit + 1;
        elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
            limit = limit - 1;
        end

        if playerdata.SuperImmuneInfections >= limit then
            maxHealth = 0;
            illness = 100; -- Force them to die
            playerdata.SuperImmuneLethal = true;
        else
            playerdata.SuperImmuneLethal = false;
        end
    end

    local bodyDamage = player:getBodyDamage();
    local currentHealth = bodyDamage:getOverallBodyHealth();
    local targetHealth = math.max(maxHealth, 100 - illness) -- Prevent it dropping below maxHealth unless Lethal

    if currentHealth >= targetHealth or currentHealth > maxHealth then
        local parts = bodyDamage:getBodyParts()
        -- Increased damage amounts because this only fires once per in-game minute
        local damageAmount = 1.0;

        if illness >= 50 then
            damageAmount = 3.0
        elseif illness >= 25 then
            damageAmount = 1.5
        end

        -- If the infection is lethal, they should take more damage and die
        if playerdata.SuperImmuneLethal then
            damageAmount = damageAmount + 10.0
        end

        --Rapidly lose health if it is too high, to prevent sleep abuse in order to stay healthy
        if illness >= 50 and currentHealth > maxHealth + 5 then
            damageAmount = damageAmount + 5.0
        end

        local randomBodyPart = parts:get(ZombRand(0, parts:size() - 1))

        if isClient() then
            local bodyPartIndex = BodyPartType.ToIndex(randomBodyPart:getType())
            local args = { bodyPart = bodyPartIndex, partDamage = damageAmount }
            sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', args)
        else
            randomBodyPart:AddDamage(damageAmount)
        end
    end

    if illness >= 10 then
        local stress = stats:get(CharacterStat.STRESS);
        if stress <= (illness / 100) then
            local newStress = math.min(1.0, stress + 0.01)
            if isClient() then
                local args = { stress = newStress }
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
            else
                stats:set(CharacterStat.STRESS, newStress)
            end
        end
    end
end

local function Immunocompromised(player)
    if not player:hasTrait(ToadTraitsRegistries.immunocompromised) then
        return
    end

    local bodyDamage = player:getBodyDamage();
    if not bodyDamage:HasInjury() then return end -- Early exit if there is no actual injuries

    local infectionIncrease = 0.05

    if isClient() then
        sendClientCommand(player, 'ToadTraits', 'Immunocompromised', { infectionIncrease = infectionIncrease })
    else
        local parts = bodyDamage:getBodyParts();
        for i = 0, parts:size() - 1 do
            local b = parts:get(i);
            local infectionValue = b:getWoundInfectionLevel()
            if infectionValue >= 10.0 then return end
            if b:isInfectedWound() and b:getAlcoholLevel() <= 0 then
                b:setWoundInfectionLevel(infectionValue + infectionIncrease);
            end
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

local function MT_checkWeight(player)
    --[[
        VANILLA WEIGHT CALCULATION REFERENCE
        Source Logic: UpdateStrength() / getWeightMod() / getMaxWeightDelta()

        FORMULA:
        ((Base 8 * StrengthMod) - MoodlePenalties) * TraitMod = Final Capacity

        STRENGTH (getWeightMod):
        Lvl 0: 0.8
        Lvl 1: 0.9  | Lvl 2: 1.07 | Lvl 3: 1.24 | Lvl 4: 1.41 | Lvl 5: 1.58
        Lvl 6: 1.75 | Lvl 7: 1.92 | Lvl 8: 2.09 | Lvl 9: 2.26 | Lvl 10: 2.5

        TRAIT (getMaxWeightDelta):
        Weak: 0.75 | Feeble: 0.90 | Normal: 1.00 | Stout: 1.25 | Strong: 1.50

        VANILLA VALUES
        -------------------------------------------------------
        Level 0  : (8 * 0.8)  * 1.0 = 6.4  -> [ 6 ]
        Level 1  : (8 * 0.9)  * 1.0 = 7.2  -> [ 7 ]
        Level 2  : (8 * 1.07) * 1.0 = 8.5  -> [ 8 ]
        Level 3  : (8 * 1.24) * 1.0 = 9.9  -> [ 9 ]
        Level 4  : (8 * 1.41) * 1.0 = 11.2 -> [ 11 ]
        Level 5  : (8 * 1.58) * 1.0 = 12.6 -> [ 12 ]
        Level 6  : (8 * 1.75) * 1.0 = 14.0 -> [ 14 ]
        Level 7  : (8 * 1.92) * 1.0 = 15.3 -> [ 15 ]
        Level 8  : (8 * 2.09) * 1.0 = 16.7 -> [ 16 ]
        Level 9  : (8 * 2.26) * 1.0 = 18.0 -> [ 18 ]
        Level 10 : (8 * 2.5)  * 1.0 = 20.0 -> [ 20 ]
        -------------------------------------------------------
    ]]

    local targetWeight = 0;
    targetWeight = targetWeight + (SandboxVars.MoreTraits.WeightGlobalMod or 0);

    if player:hasTrait(ToadTraitsRegistries.packmule) then
        local strength = player:getPerkLevel(Perks.Strength);
        targetWeight = (SandboxVars.MoreTraits.WeightPackMule or 10) + math.floor(strength / 5)
    elseif player:hasTrait(ToadTraitsRegistries.packmouse) then
        targetWeight = SandboxVars.MoreTraits.WeightPackMouse or 6
    else
        targetWeight = SandboxVars.MoreTraits.WeightDefault or 8
    end

    if targetWeight > 50 then targetWeight = 50; end

    if getActivatedMods():contains("DracoExpandedTraits") and player:hasTrait(DracoExpandedTraits.Hoarder) then
        targetWeight = math.floor(targetWeight * 1.25)
    end

    -- We want the Server to handle the weight correction for MP
    if player:getMaxWeightBase() ~= targetWeight then
        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'MT_updateWeight', { weight = targetWeight })
        end
        player:setMaxWeightBase(targetWeight)
    end
end

local function graveRobber(page, player)
    if not player or not player:hasTrait(ToadTraitsRegistries.graverobber) then
        return
    end

    for _, v in ipairs(page.backpacks) do
        local inv = v.inventory
        if inv and inv:getParent() then
            local containerObj = inv:getParent()

            -- 1. Check if the object is a corpse
            if instanceof(containerObj, "IsoDeadBody") then
                local modData = containerObj:getModData()

                -- 2. Only run if this corpse hasn't been processed yet
                if not modData.bGraveRobberRolled then
                    modData.bGraveRobberRolled = true
                    containerObj:transmitModData()

                    -- 3. Probability & Loot Logic
                    local sandboxChance = SandboxVars.MoreTraits.GraveRobberChance or 1.0
                    local chance = sandboxChance * 10;

                    if player:hasTrait(ToadTraitsRegistries.lucky) then
                        chance = chance + (2 * luckimpact)
                    end
                    if player:hasTrait(ToadTraitsRegistries.unlucky) then
                        chance = chance - (2 * luckimpact)
                    end
                    if player:hasTrait(ToadTraitsRegistries.scrounger) then
                        chance = chance + 2
                    end
                    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then
                        chance = chance - 2
                    end

                    chance = math.max(1, chance)

                    if ZombRand(0, 1001) <= chance then
                        local itemsFound = {}
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

                        local extra = SandboxVars.MoreTraits.GraveRobberGuaranteedLoot or 1
                        local iterations = ZombRand(0, 3) + extra

                        for i = 1, iterations do
                            local roll = ZombRand(0, 101)
                            for _, entry in ipairs(graveRobberLootTable) do
                                if roll <= entry.chance then
                                    local itemType = entry.items[ZombRand(#entry.items) + 1]
                                    table.insert(itemsFound, itemType)
                                    break
                                end
                            end
                        end

                        if #itemsFound > 0 then
                            if not isServer() and MT_Config and MT_Config:getOption("GraveRobberAnnounce"):getValue() then
                                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen());
                            end

                            if isClient() then
                                local args = {
                                    x = math.floor(containerObj:getX()), y = math.floor(containerObj:getY()),
                                    z = math.floor(containerObj:getZ()), items = itemsFound
                                }
                                sendClientCommand(player, 'ToadTraits', 'GraveRobber', args)
                            else
                                local bodyInv = containerObj:getContainer()
                                for _, itemType in ipairs(itemsFound) do
                                    bodyInv:AddItem(itemType)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function Gourmand(page, player)
    if not player:hasTrait(ToadTraitsRegistries.gourmand) then
        return
    end

    local baseChance = 33

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        baseChance = baseChance + (10 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        baseChance = baseChance - (10 * luckimpact)
    end

    for _, v in ipairs(page.backpacks) do
        local inventory = v.inventory
        local containerObj = inventory:getParent()

        if containerObj and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") then
            local modData = containerObj:getModData()

            if not modData.bGourmandRolled and containerObj:getContainer() then
                modData.bGourmandRolled = true
                containerObj:transmitModData()

                local container = containerObj:getContainer()
                local items = container:getItems()
                local itemsToSwap = {}

                for l = 0, items:size() - 1 do
                    local item = items:get(l)
                    if item and item:getCategory() == "Food" and (item:isRotten() or not item:isFresh()) then
                        if ZombRand(100) < baseChance then
                            table.insert(itemsToSwap, item:getFullType())

                            if not isServer() and MT_Config and MT_Config:getOption("GourmandAnnounce"):getValue() then
                                local text = getText("UI_trait_gourmand") .. ": " .. item:getName()
                                HaloTextHelper.addTextWithArrow(player, text, true, HaloTextHelper.getColorGreen())
                            end
                        end
                    end
                end

                if #itemsToSwap > 0 then
                    if isClient() then
                        local args = { x = containerObj:getX(), y = containerObj:getY(), z = containerObj:getZ(), items = itemsToSwap }
                        sendClientCommand(player, 'ToadTraits', 'Gourmand', args)
                    else
                        for _, fullType in ipairs(itemsToSwap) do
                            local oldItem = container:FindAndReturn(fullType)
                            if oldItem then
                                container:Remove(oldItem)
                                container:AddItem(fullType)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function setFoodState(food, state, player)
    --States: "Gourmand", "Normal", "Ascetic"
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

local function FoodUpdate(player)
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

local function FearfulUpdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.fearful) then
        return
    end

    local stats = player:getStats()
    local panic = stats:get(CharacterStat.PANIC)

    if panic > 5 then
        local chance = 3 + (panic / 10);

        if player:hasTrait(CharacterTrait.COWARDLY) then
            chance = chance + 1
        end
        if player:hasTrait(ToadTraitsRegistries.lucky) then
            chance = chance - luckimpact
        end
        if player:hasTrait(ToadTraitsRegistries.unlucky) then
            chance = chance + luckimpact
        end

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

-- TODO Check MP
local function GymGoer(player, perk, amount)
    if amount <= 0 or not player:hasTrait(ToadTraitsRegistries.gymgoer) then
        return
    end

    local playerdata = player:getModData()
    if not playerdata or playerdata.GymGoerProcessing then
        return
    end

    local isFitnessState = (FitnessState and player:getCurrentState() == FitnessState.instance())
    local isPerks = (perk == Perks.Fitness or perk == Perks.Strength)
    
    if not (isPerks and isFitnessState) then
        return
    end

    playerdata.GymGoerProcessing = true

    local modifier = (SandboxVars.MoreTraits.GymGoerPercent or 200)
    local bonusMultiplier = ((modifier * 0.01) - 1) * 0.1 
    
    if bonusMultiplier > 0 then
        MT_AddXP(player, perk, amount * bonusMultiplier)
    end

    playerdata.GymGoerProcessing = false
end

-- TODO Check MP
local function GymGoerUpdate(player, playerdata)
    if not (player:hasTrait(ToadTraitsRegistries.gymgoer) and SandboxVars.MoreTraits.GymGoerNoExerciseFatigue) then
        return
    end

    local fitness = player:getFitness()
    if not playerdata.GymGoerStiffnessList then
        playerdata.GymGoerStiffnessList = {
            fitness:getCurrentExeStiffnessInc("arms"),
            fitness:getCurrentExeStiffnessInc("legs"),
            fitness:getCurrentExeStiffnessInc("chest"),
            fitness:getCurrentExeStiffnessInc("abs")
        }
    end

    local muscleGroups = {
        { name = "arms", parts = { BodyPartType.UpperArm_L, BodyPartType.UpperArm_R, BodyPartType.ForeArm_L, BodyPartType.ForeArm_R, BodyPartType.Hand_L, BodyPartType.Hand_R } },
        { name = "legs", parts = { BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R, BodyPartType.LowerLeg_L, BodyPartType.LowerLeg_R } },
        { name = "chest", parts = { BodyPartType.Torso_Upper } },
        { name = "abs", parts = { BodyPartType.Torso_Lower } }
    }

    local stiffnessList = playerdata.GymGoerStiffnessList
    for i, group in ipairs(muscleGroups) do
        local currentStiffness = fitness:getCurrentExeStiffnessInc(group.name)
        local recordedPeak = stiffnessList[i]

        if recordedPeak > 0 and (currentStiffness == 0 or currentStiffness < (recordedPeak / 2)) then
            if isClient() then
                local bodyParts = {}
                for _, partType in ipairs(group.parts) do
                    table.insert(bodyParts, partType:getIndex())
                end
                sendClientCommand(player, 'ToadTraits', 'ProcessBodyPartMechanics', { bodyParts = bodyParts, partStiffness = 0, muscleGroup = group.name })
            else
                for _, partType in ipairs(group.parts) do
                    local part = player:getBodyDamage():getBodyPart(partType)
                    if not part then return end
                    part:setStiffness(0)
                    fitness:removeStiffnessValue(BodyPartType.ToString(partType))
                end
            end
            stiffnessList[i] = 0
        elseif currentStiffness > recordedPeak then
            stiffnessList[i] = currentStiffness
        end
    end
end

local function ContainerEvents (iSInventoryPage, state)
    local page = iSInventoryPage
    if state == "end" then
        local player = getPlayer();
        if not player then
            return
        end ;
        local playerdata = player:getModData();
        if not playerdata then
            return
        end ;

        ToadTraitIncomprehensive(page, player);
        ToadTraitScrounger(page, player, playerdata);
        ToadTraitVagabond(page, player);
        Gourmand(page, player);
        ToadTraitAntique(page, player, playerdata);
        graveRobber(page, player)
    end
end

-- Currently doesn't behave properly in MP (Disabled in MP)
-- Moved to TimedActions instead (Keeping existing code in case Build 42 allows it to work in MP)
-- local function UpdateWorkerSpeed(player)
    -- if not player:hasTimedActions() then
    --     return
    -- end

    -- local isQuick = player:hasTrait(ToadTraitsRegistries.quickworker)
    -- local isSlow = player:hasTrait(ToadTraitsRegistries.slowworker)
    -- if not (isQuick or isSlow) then
    --     return
    -- end

    -- local actions = player:getCharacterActions()
    -- local action = actions:get(0)
    -- if not action then
    --     return
    -- end

    -- local type = action:getMetaType()
    -- local delta = action:getJobDelta()

    -- local blacklist = { "ISWalkToTimedAction", "ISPathFindAction", "PlayInstrumentAction", "" }
    -- if tableContains(blacklist, type) or delta <= 0 or delta >= 0.99 then
    --     return
    -- end

    -- local modifier = 0.5
    -- local multiplier = getGameTime():getMultiplier()

    -- if isQuick and SandboxVars.MoreTraits.QuickWorkerScaler then
    --     modifier = modifier * (SandboxVars.MoreTraits.QuickWorkerScaler * 0.01)
    -- elseif isSlow and SandboxVars.MoreTraits.SlowWorkerScaler then
    --     modifier = modifier
    -- end

    -- local traitModiifer = 0

    -- if player:hasTrait(ToadTraitsRegistries.lucky) and ZombRand(100) <= 10 then
    --     traitModiifer = 0.25 * luckimpact
    -- elseif player:hasTrait(ToadTraitsRegistries.unlucky) and ZombRand(100) <= 10 then
    --     traitModiifer = -0.25 * luckimpact
    -- end

    -- if player:hasTrait(CharacterTrait.DEXTROUS) and ZombRand(100) <= 10 then
    --     traitModiifer = traitModiifer + 0.25
    -- elseif player:hasTrait(CharacterTrait.ALL_THUMBS) and ZombRand(100) <= 10 then
    --     traitModiifer = traitModiifer - 0.25
    -- end

    -- if isQuick then
    --     modifier = modifier + traitModiifer
    -- else
    --     modifier = modifier + (traitModiifer * -1)
    -- end

    -- if type == "ISReadABook" then
    --     if player:hasTrait(CharacterTrait.FAST_READER) then
    --         modifier = modifier * (isQuick and 5 or 0.1)
    --     elseif player:hasTrait(CharacterTrait.SLOW_READER) then
    --         modifier = modifier * (isQuick and 1.5 or 0.5)
    --     else
    --         modifier = modifier * (isQuick and 3 or 0.25)
    --     end
    -- end

    -- modifier = math.max(0, modifier)

    -- if isQuick then
    --     action:setCurrentTime(action:getCurrentTime() + (modifier * multiplier))
    -- elseif isSlow then
    --     local chance = SandboxVars.MoreTraits.SlowWorkerScaler or 15
    --     if ZombRand(100) <= chance then
    --         action:setCurrentTime(action:getCurrentTime() - modifier)
    --     end
    -- end
-- end

local function LeadFoot(player)
    if not player:hasTrait(ToadTraitsRegistries.leadfoot) then
        return
    end

    local shoes = player:getClothingItem_Feet();
    if not shoes then
        return
    end

    local itemdata = shoes:getModData();
    if not itemdata then
        return
    end

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

local function BatteringRam(player, playerData)
    if not player or not player:hasTrait(ToadTraitsRegistries.batteringram) then
        return
    end

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
                    nearbyZombies = true;
                    break
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
                                if endurance < 0.25 then
                                    damageMult = 0.25
                                elseif endurance < 0.5 then
                                    damageMult = 0.5
                                elseif endurance < 0.75 then
                                    damageMult = 0.75
                                end
                                finalDamage = (ZombRand(10, 61) / 100) * damageMult
                                enemy:setHealth(enemy:getHealth() - finalDamage)
                                if enemy:getHealth() <= 0 then
                                    enemy:Kill(player)
                                end
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
    if not weapon then
        return
    end
    if not actor then
        return
    end
    local player = actor
    local weapondata = weapon:getModData()
    if not weapondata then
        return
    end

    if weapondata.origCritChance == nil then
        weapondata.origCritChance = weapon:getCriticalChance()
    end

    if player:hasTrait(ToadTraitsRegistries.mundane) then
        weapon:setCriticalChance(1)
    else
        if weapon:getCriticalChance() ~= weapondata.origCritChance then
            weapon:setCriticalChance(weapondata.origCritChance)
        end
    end
end

-- TODO Check MP
local function clothingUpdate(_player)
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
    if not player or not player:hasTrait(ToadTraitsRegistries.noodlelegs) then
        return
    end

    if not player:isPlayerMoving() then
        return
    end

    local isRunning = player:isRunning();
    local isSprinting = player:isSprinting();
    if not (isRunning or isSprinting) then
        return
    end

    local sprinting = player:getPerkLevel(Perks.Sprinting);
    local nimble = player:getPerkLevel(Perks.Nimble);
    local tripChance = 500001 + (nimble * 12500) + (sprinting * 12500);

    if player:hasTrait(CharacterTrait.GRACEFUL) then
        tripChance = tripChance * 1.2;
    end
    if player:hasTrait(CharacterTrait.CLUMSY) then
        tripChance = tripChance * 0.8;
    end
    if player:hasTrait(ToadTraitsRegistries.lucky) then
        tripChance = tripChance * (1.05 * luckimpact);
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        tripChance = tripChance * (0.95 * luckimpact);
    end

    if isSprinting then
        tripChance = tripChance * 0.6;
    end

    if ZombRand(0, tripChance) <= 100 then
        local side = ZombRand(2) == 0 and "left" or "right"
        player:setBumpFallType("FallForward");
        player:setBumpType(side);
        player:setBumpDone(false);
        player:setBumpFall(true);
        player:reportEvent("wasBumped");
    end
end

local function SecondWind(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.secondwind) or playerdata.secondwinddisabled then
        return
    end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local fatigue = stats:get(CharacterStat.FATIGUE)

    if endurance < 0.5 or fatigue > 0.8 then
        local enemies = player:getSpottedList()
        if enemies:size() < 3 then
            return
        end

        local zombiesNearPlayer = 0
        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i)
            if enemy:isZombie() and enemy:DistTo(player) <= 5 then
                zombiesNearPlayer = zombiesNearPlayer + 1
            end
            if zombiesNearPlayer > 2 then
                break
            end
        end

        if zombiesNearPlayer > 2 then
            local args = { endurance = 1.0 }

            if fatigue > 0.4 then
                args.fatigue = 0.4
                if fatigue > 0.6 then
                    playerdata.secondwindrecoveredfatigue = true
                end
            end

            if isClient() then
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args)
            else
                stats:set(CharacterStat.ENDURANCE, args.endurance)
                if args.fatigue then
                    stats:set(CharacterStat.FATIGUE, args.fatigue)
                end
            end

            playerdata.iHardyEndurance = 5
            playerdata.secondwindcooldown = 0
            playerdata.secondwinddisabled = true
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_secondwind"), true, HaloTextHelper.getColorGreen())
        end
    end
end

local function SecondWindRecharge(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.secondwind) or playerdata.secondwinddisabled then
        return
    end

    local cooldown = SandboxVars.MoreTraits.SecondWindCooldown or 14;
    local recharge = cooldown * 12;

    if playerdata.secondwindrecoveredfatigue then
        recharge = recharge * 2;
    end
    playerdata.secondwindcooldown = (playerdata.secondwindcooldown or 0) + 1;

    if playerdata.secondwindcooldown >= recharge then
        playerdata.secondwindcooldown = 0;
        playerdata.secondwinddisabled = false;
        playerdata.secondwindrecoveredfatigue = false;
        player:Say(getText("UI_trait_secondwindcooldown"));
    end
end

-- -- Unsure if needed due to new Motion Sensitive Trait
-- local function MotionSickness(player)
--     local playerdata = player:getModData();
--     local playerstats = player:getStats();
--     local Sickness = playerstats:get(CharacterStat.FOOD_SICKNESS);
--     if player:hasTrait(ToadTraitsRegistries.motionsickness) then
--         if player:isDriving() == true and Sickness < 90.0 then
--             local vehicle = player:getVehicle();
--             if not vehicle then
--                 return
--             end
--             if playerdata.MotionActive == false then
--                 playerdata.MotionActive = true;
--             end
--             local Speed = math.abs(vehicle:getCurrentSpeedKmHour())
--             if Speed < 16.0 then
--                 return
--             elseif Speed >= 16.0 and Speed < 31.0 and Sickness < 21.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS, Sickness + 0.005);
--             elseif Speed >= 31.0 and Speed < 41.0 and Sickness < 26.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS, Sickness + 0.01);
--             elseif Speed >= 41.0 and Speed < 51.0 and Sickness < 38.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.02);
--             elseif Speed >= 51.0 and Speed < 56.0 and Sickness < 48.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.03);
--             elseif Speed >= 56.0 and Speed < 61.0 and Sickness < 73.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.04);
--             elseif Speed >= 61.0 and Speed < 91.0 and Sickness < 80.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.05);
--             elseif Speed >= 91.0 then
--                 playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness + 0.1);
--             end
--         elseif not player:isDriving() and not playerstats:isIsFakeInfected() and Sickness ~= 0 then
--             if playerdata.MotionActive == true then
--                 playerdata.MotionActive = false;
--             end
--             playerstats:set(CharacterStat.FOOD_SICKNESS,Sickness - 0.1);
--         end
--     end
-- end

-- -- Unsure if needed due to new Motion Sensitive Trait
-- local function MotionSicknessHealthLoss(player)
--     local playerdata = player:getModData();
--     local playerstats = player:getStats();
--     local MaxHealth = 35.0;
--     local Health = player:getBodyDamage():getOverallBodyHealth();
--     local Sickness = playerstats:get(CharacterStat.FOOD_SICKNESS);
--     if player:hasTrait(ToadTraitsRegistries.motionsickness) and playerdata.MotionActive == true then
--         if Health >= 100 - Sickness and Health > MaxHealth then
--             for i = 0, player:getBodyDamage():getBodyParts():size() - 1 do
--                 local b = player:getBodyDamage():getBodyParts():get(i);
--                 if Sickness < 40.0 then
--                     return
--                 elseif Sickness >= 40.0 and Sickness < 50.0 and Health > 90.0 then
--                     b:AddDamage(0.001 * GameSpeedMultiplier());
--                 elseif Sickness >= 50.0 and Sickness < 75.0 and Health > 75.0 then
--                     b:AddDamage(0.002 * GameSpeedMultiplier());
--                 elseif Sickness >= 75.0 then
--                     b:AddDamage(0.005 * GameSpeedMultiplier());
--                 end
--             end
--         end
--     end
-- end

local function RestfulSleeper(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.restfulsleeper) or not player:isAsleep() then
        return
    end

    local stats = player:getStats()
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local neck = player:getBodyDamage():getBodyPart(BodyPartType.Neck)

    playerdata.HasSlept = true
    playerdata.NeckHadPain = neck:getAdditionalPain() > 0
    playerdata.FatigueWhenSleeping = fatigue

    local reduction = 0.05
    if fatigue >= 0.6 then
        reduction = 0.2
    elseif fatigue >= 0.2 then
        reduction = 0.1
    end
    local newFatigue = math.max(0, fatigue - reduction)

    if isClient() then
        local args = { fatigue = newFatigue }
        sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
    else
        stats:set(CharacterStat.FATIGUE, newFatigue)
    end
end

local function RestfulSleeperWakeUp(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.restfulsleeper) then
        return
    end

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
            if isClient() then
                local args = { fatigue = playerdata.FatigueWhenSleeping }
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
            else
                stats:set(CharacterStat.FATIGUE, playerdata.FatigueWhenSleeping)
            end

        end

        playerdata.HasSlept = false
        playerdata.FatigueWhenSleeping = 0

        if not playerdata.NeckHadPain then
            local neck = player:getBodyDamage():getBodyPart(BodyPartType.Neck)
            if neck:getAdditionalPain() > 0 then
                if isClient() then
                    local neckPart = BodyPartType.ToIndex(BodyPartType.Neck)
                    sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', { bodyPart = neckPart, partPain = 0 })
                else
                    neck:setAdditionalPain(0)
                end
            end
        end
    end
end

local function HungerCheck(player, playerdata)
    if not (player:hasTrait(ToadTraitsRegistries.superimmune) and playerdata.SuperImmuneActive) then
        return
    end

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
        if isClient() then
            local args = { zombie_fever = 0, zombie_infection = 0 }
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
        else
            stats:set(CharacterStat.ZOMBIE_FEVER, 0);
            stats:set(CharacterStat.ZOMBIE_INFECTION, 0);
        end
        return
    end

    if stats:get(CharacterStat.HUNGER) <= 0 then
        playerdata.SuperImmuneMinutesWellFed = (playerdata.SuperImmuneMinutesWellFed or 0) + 1
    end
end

local function TerminatorGun(player)
    local item = player:getPrimaryHandItem()
    if not item or item:getCategory() ~= "Weapon" or item:getSubCategory() ~= "Firearm" then
        return
    end

    local itemdata = item:getModData()
    if not itemdata then
        return
    end

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
        local stats = player:getStats()
        local stress = stats:get(CharacterStat.STRESS)
        local panic = stats:get(CharacterStat.PANIC)
        local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
        local args = {}
        local updateStats = false

        if hasTerminator then
            args.stress = math.max(0, stress - 0.01)
            args.panic = math.max(0, panic - 10)
            updateStats = true
        elseif hasAntigun then
            args.unhappiness = math.min(100, unhappiness + 0.6)
            updateStats = true
        end

        if updateStats then
            if isClient() then
                sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
            else
                if args.panic then
                    stats:set(CharacterStat.PANIC, args.panic)
                end
                if args.stress then
                    stats:set(CharacterStat.STRESS, args.stress)
                end
                if args.unhappiness then
                    stats:set(CharacterStat.UNHAPPINESS, args.unhappiness)
                end
            end
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
    if amount <= 0 then return end
    if perk ~= Perks.Aiming then return end
    if not player:hasTrait(ToadTraitsRegistries.antigun) then return end

    local playerdata = player:getModData()
    if not playerdata then return end
    if playerdata.AntiGunProcessing then return end

    playerdata.AntiGunProcessing = true
    local penaltyAmount = amount * 0.25
    MT_AddXP(player, perk, -penaltyAmount)
    playerdata.AntiGunProcessing = false
end

local function IdealWeight(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.idealweight) then
        return
    end

    local nutrition = player:getNutrition()
    local currentCalories = nutrition:getCalories()
    local weight = nutrition:getWeight()

    if playerdata.OldCalories == nil then
        playerdata.OldCalories = currentCalories
        return
    end

    local oldCalories = playerdata.OldCalories

    if currentCalories > oldCalories then
        local caloriesChange = currentCalories - oldCalories

        if weight <= 78 then
            nutrition:setCalories(currentCalories + (caloriesChange * 0.5))
        elseif weight >= 82 then
            nutrition:setCalories(currentCalories - (caloriesChange * 0.25))
        end
    end

    playerdata.OldCalories = nutrition:getCalories()
end

local function QuickRest(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.quickrest) then return end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local isSittingGround = player:isSitOnGround()
    local isRestingFurniture = player:isResting() or player:isSittingOnFurniture()

    if endurance < 1 and (isSittingGround or isRestingFurniture) then
        local enduranceGain = 0.055 
        
        if isRestingFurniture then
            enduranceGain = 0.12
        end

        local fatigue = stats:get(CharacterStat.FATIGUE)
        local multiplier = 1.0 - (fatigue * 0.8)
        local finalGain = enduranceGain * multiplier
        local newEndurance = math.min(1.0, endurance + finalGain)

        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', { endurance = newEndurance })
        end
        stats:set(CharacterStat.ENDURANCE, newEndurance)

        playerdata.QuickRestActive = true
        return
    end

    if playerdata.QuickRestActive then
        if endurance >= 1 or (not isSittingGround and not isRestingFurniture) then
            if endurance >= 1 and (isSittingGround or isRestingFurniture) then
                HaloTextHelper.addText(player, getText("UI_quickrestfullendurance"), "", HaloTextHelper.getColorGreen())
            end
            playerdata.QuickRestActive = false
        end
    end
end

local function BurnWardPatient(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.burned) then
        return
    end

    if playerdata.MTModVersion < 3 or not SandboxVars.MoreTraits.BurnedFireAversion then
        return
    end

    local pX, pY, pZ = player:getX(), player:getY(), player:getZ()
    local distance = SandboxVars.MoreTraits.BurnedDistance or 10
    local closestDist = distance
    local foundFire = false

    local cell = getCell()
    for dy = -distance, distance do
        for dx = -distance, distance do
            if (dx * dx + dy * dy) <= (distance * distance) then
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

        if isClient() then
            local args = { panic = panicGain, stress = stressGain }
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
        else
            stats:set(CharacterStat.PANIC, panicGain);
            stats:set(CharacterStat.STRESS, stressGain);
        end
    end
end

local function handleGordanite(player, item, itemType)
    local moddata = item:getModData()
    if not moddata then return end

    if player:hasTrait(ToadTraitsRegistries.gordanite) then
        if not moddata.MTHasBeenModified then
            moddata.MinDamage = item:getMinDamage()
            moddata.MaxDamage = item:getMaxDamage()
            moddata.PushBack = item:getPushBackMod()
            moddata.DoorDamage = item:getDoorDamage()
            moddata.TreeDamage = item:getTreeDamage()
            moddata.CriticalChance = item:getCriticalChance()
            moddata.SwingTime = item:getSwingTime()
            moddata.BaseSpeed = item:getBaseSpeed()
            moddata.MinimumSwing = item:getMinimumSwingTime()
            moddata.MTHasBeenModified = true
            
            if not getActivatedMods():contains("VorpalWeapons") then
                item:setName(item:getName() .. "+")
            end
        end

        local longBluntLvl = player:getPerkLevel(Perks.Blunt)
        local strengthlvl = player:getPerkLevel(Perks.Strength)
        local floatmod = (longBluntLvl + strengthlvl) / 2 * 0.1

        local modifier = (SandboxVars.MoreTraits.GordaniteEffectiveness or 100) * 0.01
        floatmod = floatmod * modifier
        longBluntLvl = longBluntLvl * modifier
        strengthlvl = strengthlvl * modifier

        local stats = {
            minDmg = moddata.MinDamage + 0.1 + floatmod / 2,
            maxDmg = moddata.MaxDamage + 0.1 + floatmod / 2,
            pushBack = moddata.PushBack + 0.1 + floatmod,
            doorDmg = moddata.DoorDamage + 7 + strengthlvl + longBluntLvl,
            treeDmg = moddata.TreeDamage + 15 + strengthlvl + longBluntLvl * 2,
            crit = moddata.CriticalChance + (strengthlvl + longBluntLvl) / 2,
            swing = moddata.SwingTime - 0.2 - floatmod,
            speed = moddata.BaseSpeed + 0.1 + floatmod,
            length = 0.4 + floatmod / 2,
            minSwing = moddata.MinimumSwing - 0.2 - floatmod
        }
        item:setMinDamage(stats.minDmg)
        item:setMaxDamage(stats.maxDmg)
        item:setPushBackMod(stats.pushBack)
        item:setDoorDamage(stats.doorDmg)
        item:setTreeDamage(stats.treeDmg)
        item:setCriticalChance(stats.crit)
        item:setSwingTime(stats.swing)
        item:setBaseSpeed(stats.speed)
        item:setWeaponLength(stats.length)
        item:setMinimumSwingTime(stats.minSwing)
        
        local tooltipKey = (itemType == "Crowbar" or itemType == "CrowbarForged") and "Tooltip_MoreTraits_ItemBoost" or "Tooltip_MoreTraits_BloodyItemBoost"
        item:setTooltip(getText(tooltipKey))

        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'ApplyGordanite', { itemID = item:getID(), stats = stats })
        end

    elseif moddata.MTHasBeenModified then
        item:setMinDamage(moddata.MinDamage)
        item:setMaxDamage(moddata.MaxDamage)
        item:setPushBackMod(moddata.PushBack)
        item:setDoorDamage(moddata.DoorDamage)
        item:setTreeDamage(moddata.TreeDamage)
        item:setCriticalChance(moddata.CriticalChance)
        item:setSwingTime(moddata.SwingTime)
        item:setBaseSpeed(moddata.BaseSpeed)
        item:setWeaponLength(0.4)
        item:setMinimumSwingTime(moddata.MinimumSwing)

        if not getActivatedMods():contains("VorpalWeapons") then
            local name = item:getName()
            if string.sub(name, -1) == "+" then
                item:setName(string.sub(name, 1, -2))
            end
        end

        local tooltip = (itemType == "BloodyCrowbar") and getText("Tooltip_MoreTraits_BloodyCrowbar") or nil
        item:setTooltip(tooltip)
        
        moddata.MTHasBeenModified = false

        if isClient() then
            sendClientCommand(player, 'ToadTraits', 'RevertGordanite', { itemID = item:getID() })
        end
    end
end

local function OnEquipPrimary(player, item)
    if not player or not item then return end

    local isAmputee = player:hasTrait(ToadTraitsRegistries.amputee) or getActivatedMods():contains("Amputation")
    if isAmputee and (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) then
        player:setPrimaryHandItem(nil)
        HaloTextHelper.addText(player, getText("UI_trait_amputee_missingarm"), "",  HaloTextHelper.getColorRed())
        return
    end

    local itemType = item:getType()
    if player:hasTrait(ToadTraitsRegistries.burned) then
        local fireItems = {
            FlameTrap = true, FlameTrapTriggered = true, FlameTrapSensorV1 = true, FlameTrapSensorV2 = true,
            FlameTrapSensorV3 = true, FlameTrapRemote = true, Molotov = true
        }
        if fireItems[itemType] then
            player:setPrimaryHandItem(nil)
            HaloTextHelper.addText(player, getText("UI_burnedcannotequip"), "", HaloTextHelper.getColorRed())
            return
        end
    end

    local crowbars = {
        ["Crowbar"] = true,
        ["CrowbarForged"] = true,
        ["BloodyCrowbar"] = true
    }

    local isCrowbar = crowbars[itemType]
    if isCrowbar then
        handleGordanite(player, item, itemType)
    end
end

local function MTAlcoholismMoodle(player, playerdata)
    --Experimental MoodleFramework Support
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

    local moodle = MF.getMoodle("MTAlcoholism")
    local alcoholism = moodle:getValue()

    if playerdata.isMTAlcoholismInitialized == nil then
        moodle:setValue(0.5)
        playerdata.isMTAlcoholismInitialized = true
        alcoholism = 0.5
    end

    local hoursThreshold = 36
    if SandboxVars.MoreTraits and SandboxVars.MoreTraits.AlcoholicFrequency then
        hoursThreshold = SandboxVars.MoreTraits.AlcoholicFrequency * 1.5
    end

    local divider = 5
    if hoursThreshold <= 2 then
        divider = 0.1
    elseif hoursThreshold <= 5 then
        divider = 0.2
    elseif hoursThreshold <= 10 then
        divider = 0.5
    elseif hoursThreshold <= 20 then
        divider = 1
    end

    local stats = player:getStats()
    if alcoholism >= 0.7 then
        if isClient() then
            local args = { anger = 0, stress = 0, boredom = 0, panic = 0, pain = 0, idleness = 0, unhappiness = 0 }
            sendClientCommand(player, 'ToadTraits', 'UpdateStats', args) -- Tell the Server to set our stats
        else
            stats:set(CharacterStat.ANGER, 0)
            stats:set(CharacterStat.STRESS, 0)
            stats:set(CharacterStat.BOREDOM, 0)
            stats:set(CharacterStat.PANIC, 0)
            stats:set(CharacterStat.PAIN, 0)
            stats:set(CharacterStat.IDLENESS, 0)
            stats:set(CharacterStat.UNHAPPINESS, 0)
        end
    end

    if internalTick >= 29 then
        local drunkness = stats:get(CharacterStat.INTOXICATION)
        local newValue = alcoholism

        if drunkness >= 20 then
            moodle:setChevronCount(3)
            moodle:setChevronIsUp(true)
            newValue = alcoholism + 0.004
            playerdata.iHoursSinceDrink = 0
        elseif drunkness >= 10 then
            moodle:setChevronCount(2)
            moodle:setChevronIsUp(true)
            newValue = alcoholism + 0.003
            playerdata.iHoursSinceDrink = 0
        elseif drunkness > 0 then
            stats:set(CharacterStat.FATIGUE, stats:get(CharacterStat.FATIGUE) - 0.001)
            moodle:setChevronCount(1)
            moodle:setChevronIsUp(true)
            newValue = alcoholism + 0.002
            playerdata.iHoursSinceDrink = 0
        else
            moodle:setChevronCount(0)
            moodle:setChevronIsUp(false)
            -- Passive decay if not drinking and above baseline
            if alcoholism > 0.5 and internalTick >= 30 then
                newValue = alcoholism - 0.0001
            end
        end
        moodle:setValue(math.max(0, math.min(1, newValue)))
    end

    if internalTick == 30 then
        local divCalc = (playerdata.iHoursSinceDrink or 0) / divider

        if alcoholism <= 0.3 then
            local currentAnger = stats:get(CharacterStat.ANGER)
            if currentAnger < 0.05 + (divCalc * 0.1) / 2 then
                stats:set(CharacterStat.ANGER, currentAnger + 0.01)
            end
        end

        if alcoholism <= 0.2 then
            local currentStress = stats:get(CharacterStat.STRESS)
            if currentStress < 0.15 + (divCalc * 0.1) / 2 then
                stats:set(CharacterStat.STRESS, currentStress + 0.01)
            end
        end
    end
end

local function MTAlcoholismMoodleTracker(player, playerdata)
    --Experimental MoodleFramework Support
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end
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

local function updateUnwavering(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.unwavering) then return end
    if playerdata.UnwaveringInjurySpeedChanged then return end

    local bodyDamage = player:getBodyDamage()
    local parts = bodyDamage:getBodyParts()
    local partIndexes = {}
    
    local stats = {
        scratch = 30,
        cut = 30,
        deep = 60,
        burn = 60
    }

    for i = 0, parts:size() - 1 do
        table.insert(partIndexes, i)
        
        local part = parts:get(i)
        -- Apply locally (Client and Singleplayer)
        part:setScratchSpeedModifier(part:getScratchSpeedModifier() + stats.scratch)
        part:setCutSpeedModifier(part:getCutSpeedModifier() + stats.cut)
        part:setDeepWoundSpeedModifier(part:getDeepWoundSpeedModifier() + stats.deep)
        part:setBurnSpeedModifier(part:getBurnSpeedModifier() + stats.burn)
    end

    if isClient() then
        -- Send the list of IDs and the stat table to the server
        local args = { bodyParts = partIndexes, unwaveringStats = stats }
        sendClientCommand(player, 'ToadTraits', 'BodyPartMechanics', args)
    end

    playerdata.UnwaveringInjurySpeedChanged = true
end

local function OnPlayerUpdate(player)
    if not player then
        return
    end ;
    local playerdata = player:getModData();
    if not playerdata then
        return
    end ;

    if internalTick >= 30 then
        local bodyDamage = player:getBodyDamage();
        local isInfected = bodyDamage:isInfected();
        local justGotInfected = (not playerdata.bWasInfected and isInfected);

        amputee(player, justGotInfected);
        playerdata.bWasInfected = isInfected;
        vehicleCheck(player);
        FoodUpdate(player);
        clothingUpdate(player);
    elseif internalTick == 20 then
        FearfulUpdate(player, playerdata);
    elseif internalTick == 10 then
        SuperImmune(player, playerdata);
    end
    -- MotionSickness(player); -- Unsure if needed now due to Motion Sensitive trait in Vanilla?
    -- MotionSicknessHealthLoss(player); -- Unsure if needed now due to Motion Sensitive trait in Vanilla?
    SecondWind(player, playerdata);
    indefatigable(player, playerdata);
    CheckDepress(player, playerdata);
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
    -- UpdateWorkerSpeed(player)
    CheckForPlayerBuiltContainer(player, playerdata);
    IdealWeight(player, playerdata);
    MT_FastGimpTraits(player)
    NoodleLegs(player)
    internalTick = internalTick + 1;
    if internalTick > 30 then
        --Reset internalTick every 30 ticks
        internalTick = 0;
    end
end

local function OnWeaponHitCharacter(actor, target, weapon, damage)
    MT_MeleeTraits(actor, target, weapon, damage)
    actionhero(actor, target, weapon, damage)
    mundane(actor, target, weapon, damage)
    unwavering(actor, target, weapon, damage)
    martial(actor, target, weapon, damage)
end

local function EveryOneMinute()
    local player = getPlayer();
    if not player then
        return
    end ;
    local playerdata = player:getModData();
    if not playerdata then
        return
    end ;

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
    SuperImmuneRecoveryProcess(player, playerdata);
    SuperImmuneFakeInfectionHealthLoss(player, playerdata);
    Immunocompromised(player);
    CheckSelfHarm(player);
    checkBloodTraits(player);
    QuickRest(player, playerdata);
    
    if getActivatedMods():contains("DracoExpandedTraits") then
        MT_checkWeight(player)
    end
end

local function EveryTenMinutes()
    local player = getPlayer();
    if not player then
        return
    end ;
    if not getActivatedMods():contains("DracoExpandedTraits") then
        MT_checkWeight(player)
    end
end

local function EveryHours()
    local player = getPlayer();
    if not player then
        return
    end
    local playerdata = player:getModData();
    if not playerdata then
        return
    end ;

    if not isMoodleFrameWorkEnabled then
        drinkertick(player, playerdata);
    else
        MTAlcoholismMoodleTracker(player, playerdata);
    end

    drinkerpoison(player, playerdata);
    SecondWindRecharge(player, playerdata);
    indefatigablecounter(player, playerdata);
    RestfulSleeper(player, playerdata);
    ToadTraitDepressive(player, playerdata);
    updateUnwavering(player, playerdata);

    if player:hasTrait(ToadTraitsRegistries.ingenuitive) and not playerdata.IngenuitiveActivated then
        MT_LearnAllRecipes(player)
        playerdata.IngenuitiveActivated = true
    end

    local bodyParts = player:getBodyDamage():getBodyParts()

    if playerdata.InjuredBodyList then
        for i = #playerdata.InjuredBodyList, 1, -1 do
            local partIdx = playerdata.InjuredBodyList[i]
            if not bodyParts:get(partIdx):HasInjury() then
                table.remove(playerdata.InjuredBodyList, i)
            end
        end
    end

    if playerdata.TraitInjuredBodyList then
        for i = #playerdata.TraitInjuredBodyList, 1, -1 do
            local partIdx = playerdata.TraitInjuredBodyList[i]
            if not bodyParts:get(partIdx):HasInjury() then
                table.remove(playerdata.TraitInjuredBodyList, i)
            end
        end
    end
end

local function OnCreatePlayer(playerindex, player)
    if not player then
        return
    end
    local playerdata = player:getModData();
    if not playerdata then
        return
    end

    --reset any worn clothing to default state.
    local wornItems = player:getWornItems();
    for i = wornItems:size() - 1, 0, -1 do
        local item = wornItems:getItemByIndex(i);
        if item:IsClothing() then
            local itemdata = item:getModData();
            itemdata.sState = nil;
        end
    end
    InitPlayerData(player, playerdata);
    if not isServer() then
        MT_Config = PZAPI.ModOptions:getOptions("1299328280");
    end
    print("More Traits - Mod Version On Which Player Was Created: " .. playerdata.MTModVersion)
    if getGameTime():getModData().MTModVersion == nil then
        getGameTime():getModData().MTModVersion = "Before 15 January 2023"
    end
    print("More Traits - Mod Version On Which Save Was Created: " .. getGameTime():getModData().MTModVersion);
    print("More Traits - Current Mod Version: " .. MTModVersion)
end

local function OnInitWorld()
    if getGameTime():getModData().MTModVersion == nil then
        getGameTime():getModData().MTModVersion = MTModVersion;
    end
end

local function onNewGame(player)
    if not player then
        return
    end
    local playerdata = player:getModData();
    if not playerdata then
        return
    end

    initToadTraitsItems(player);
    initToadTraitsPerks(player, playerdata);
end

Events.OnEquipPrimary.Add(OnEquipPrimary)
Events.OnEquipSecondary.Add(OnEquipSecondary); 
Events.OnWeaponHitCharacter.Add(OnWeaponHitCharacter);
Events.OnWeaponSwing.Add(progun);
Events.AddXP.Add(Specialization);
Events.AddXP.Add(GymGoer);
Events.AddXP.Add(antigunxpdecrease);
Events.OnPlayerUpdate.Add(OnPlayerUpdate);
Events.EveryOneMinute.Add(EveryOneMinute);
Events.EveryTenMinutes.Add(EveryTenMinutes);
Events.EveryHours.Add(EveryHours);
Events.OnInitWorld.Add(OnInitWorld);
Events.OnNewGame.Add(onNewGame);
Events.OnCreatePlayer.Add(OnCreatePlayer);
Events.OnPlayerGetDamage.Add(MTPlayerHit)
Events.OnRefreshInventoryWindowContainers.Add(ContainerEvents);
Events.LevelPerk.Add(FixSpecialization);