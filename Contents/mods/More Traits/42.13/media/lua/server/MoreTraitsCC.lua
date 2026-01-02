-- Function covers Vagabond, Scrounger, Antique
local function ProcessTraitLoot(player, args, modData, specificContainer)
    local gridSquare = getCell():getGridSquare(args.x, args.y, args.z)
    if not gridSquare then
        return
    end

    local objects = gridSquare:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local container = object:getContainer()

        -- Check if container exists AND (if specificContainer is nil OR matches the type)
        if container and (not specificContainer or container:getType() == specificContainer) then
            for _, itemType in ipairs(args.items) do
                local item = container:AddItem(itemType)
                if item then
                    sendAddItemToContainer(container, item)
                end
            end

            -- Set the specific ModData key (e.g., bVagbondRolled)
            object:getModData()[modData] = true
            object:transmitModData()
            break
        end
    end
end

-- Function covers Incomprehensive
local function ProcessTraitLootRemoval(player, args, modData)
    local gridSquare = getCell():getGridSquare(args.x, args.y, args.z)
    if not gridSquare then
        return
    end

    local objects = gridSquare:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local container = object:getContainer()

        if container then
            for _, itemType in ipairs(args.items) do
                local item = container:FindAndReturn(itemType)
                if item then
                    container:Remove(item)
                    sendRemoveItemFromContainer(container, item)
                end
            end
            object:getModData()[modData] = true
            object:transmitModData()
            break
        end
    end
end

-- Covers Gourmand
local function ProcessGourmand(player, args)
    local gridSquare = getCell():getGridSquare(args.x, args.y, args.z)
    if not gridSquare then
        return
    end

    local objects = gridSquare:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local container = object:getContainer()

        if container then
            for _, itemType in ipairs(args.items) do
                local items = container:getItems()
                for j = 0, items:size() - 1 do
                    local item = items:get(j)
                    if item and item:getFullType() == itemType and (item:isRotten() or not item:isFresh()) then
                        container:Remove(item)
                        sendRemoveItemFromContainer(container, item)

                        local newItem = container:AddItem(itemType)
                        if newItem then
                            sendAddItemToContainer(container, newItem)
                        end
                        break
                    end
                end
            end
            object:getModData().bGourmandRolled = true
            object:transmitModData()
            break
        end
    end
end

local function ProcessGraveRobber(player, args)
    local gridSquare = getCell():getGridSquare(args.x, args.y, args.z)
    if not gridSquare then
        return
    end

    local bodies = gridSquare:getDeadBodys()
    if bodies and not bodies:isEmpty() then
        local targetBody = bodies:get(0)
        local zombInv = targetBody:getContainer()

        for _, itemType in ipairs(args.items) do
            local item = zombInv:AddItem(itemType)
            if item then
                sendAddItemToContainer(zombInv, item)
            end
        end

        targetBody:getModData().bGraveRobberRolled = true
        targetBody:transmitModData()
    end
end

local function UpdateStats(player, args, command)
    local stats = player:getStats()

    if args.panic ~= nil then
        stats:set(CharacterStat.PANIC, args.panic)
    end
    if args.stress ~= nil then
        stats:set(CharacterStat.STRESS, args.stress)
    end
    if args.fatigue ~= nil then
        stats:set(CharacterStat.FATIGUE, args.fatigue)
    end
    if args.pain ~= nil then
        stats:set(CharacterStat.PAIN, args.pain)
    end
    if args.boredom ~= nil then
        stats:set(CharacterStat.BOREDOM, args.boredom)
    end
    if args.unhappiness ~= nil then
        stats:set(CharacterStat.UNHAPPINESS, args.unhappiness)
    end
    if args.zombie_fever ~= nil then
        stats:set(CharacterStat.ZOMBIE_FEVER, args.zombie_fever)
    end
    if args.zombie_infection ~= nil then
        stats:set(CharacterStat.ZOMBIE_INFECTION, args.zombie_infection)
        if args.zombie_infection == 0 and args.clear_wounds then
            local bodyDamage = player:getBodyDamage()
            bodyDamage:setInfected(false)
            bodyDamage:setInfectionMortalityDuration(-1)
            bodyDamage:setInfectionTime(-1)

            local parts = bodyDamage:getBodyParts()
            for i = 0, parts:size() - 1 do
                local b = parts:get(i);
                if b:HasInjury() and b:isInfectedWound() then
                    b:SetInfected(false);
                    b:setInfectedWound(false);
                end
                if args.amputee then
                    b:RestoreToFullHealth();
                end
            end 
        end
    end
    if args.sickness ~= nil then
        stats:set(CharacterStat.SICKNESS, args.sickness)
    end
    if args.anger ~= nil then
        stats:set(CharacterStat.ANGER, args.anger)
    end
    if args.idleness ~= nil then
        stats:set(CharacterStat.IDLENESS, args.idleness)
    end
    if args.poison ~= nil then
        stats:set(CharacterStat.POISON, args.poison)
    end
    if args.endurance ~= nil then
        stats:set(CharacterStat.ENDURANCE, args.endurance)
    end

    -- print("Server: " .. tostring(command) .. " (Update) applied to " .. player:getUsername())
end

local function ProcessBodyPartMechanics(player, args)
    local PartIndexes = {}
    if type(args.bodyParts) == "table" then
        PartIndexes = args.bodyParts
    elseif args.bodyPart ~= nil then
        table.insert(PartIndexes, args.bodyPart)
    end

    for _, index in ipairs(PartIndexes) do
        local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.FromIndex(index))

        if bodyPart then
            if args.partPain ~= nil then
                bodyPart:setAdditionalPain(args.partPain)
            end
            if args.partDamage ~= nil then
                bodyPart:AddDamage(args.partDamage)
            end
            if args.partStiffness ~= nil then
                bodyPart:setStiffness(args.partStiffness)
            end
            if args.partAdd ~= nil then
                bodyPart:AddHealth(args.partHealthAdd)
            end
            if args.partReduce ~= nil then
                bodyPart:ReduceHealth(args.partHealthReduce)
            end
        end
    end
end

local function ProcessUpdateWeight(player, args)
    if not args.weight then
        return
    end
    player:setMaxWeightBase(args.weight)
end

local FastGimpVector = Vector2.new(0, 0)
local function ProcessFastGimp(player, args)
    if not args.xSpeed and args.ySpeed then return end
    FastGimpVector:setX(args.xSpeed)
    FastGimpVector:setY(args.ySpeed)
    player:Move(FastGimpVector)
end

local function ProcessImmunocompromised(player, args)
    if not args.infectionIncrease then
        return
    end
    local parts = player:getBodyDamage():getBodyParts();
    for i = 0, parts:size() - 1 do
        local b = parts:get(i);
        local infectionValue = b:getWoundInfectionLevel()
        if infectionValue >= 10.0 then return end
        if b:isInfectedWound() and b:getAlcoholLevel() <= 0 then
            b:setWoundInfectionLevel(infectionValue + args.infectionIncrease);
        end
    end
end

local function ProcessGlassBody(player, args)
    local bodyDamage = player:getBodyDamage()

    if args.extraDamage ~= nil then
        bodyDamage:ReduceGeneralHealth(args.extraDamage)
    end

    local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(args.partIndex))
    if bodyPart then
        if args.fractureTime > 0 then
            if bodyPart:getFractureTime() <= 0 then
                bodyPart:setFractureTime(args.fractureTime)
            end
        elseif args.doScratch then
            bodyPart:setScratched(true, true)
        end
    end
end

local function ProcessInfectPlayer(player)
    local bodyDamage = player:getBodyDamage()
    bodyDamage:setInfected(true)
end

local function ProcessEvasive(player, args)
    local bodyDamage = player:getBodyDamage()
    local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(args.partIndex))
    
    if not bodyPart then return end;

    if bodyPart:IsInfected() and not args.wasInfectedBefore and args.isInfected then
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

local function ProcessApplyGordanite(player, args)
    local item = player:getInventory():getItemById(args.itemID)
    if item and args.stats then
        local s = args.stats
        item:setMinDamage(s.minDmg)
        item:setMaxDamage(s.maxDmg)
        item:setPushBackMod(s.pushBack)
        item:setDoorDamage(s.doorDmg)
        item:setTreeDamage(s.treeDmg)
        item:setCriticalChance(s.crit)
        item:setSwingTime(s.swing)
        item:setBaseSpeed(s.speed)
        item:setWeaponLength(s.length)
        item:setMinimumSwingTime(s.minSwing)
        item:getModData().MTHasBeenModified = true
    end
end

local function ProcessRevertGordanite(player, args)
    local item = player:getInventory():getItemById(args.itemID)
    if item then
        local moddata = item:getModData()
        if moddata.MTHasBeenModified then
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
            moddata.MTHasBeenModified = false
        end
    end
end

-- local function UpdateXP(player, args, command)
--     local xp = player:getXp()
--     local perk = Perks[args.perk] -- Cannot pass a string value to this function so we convert it back to PerkFactory

--     if args.multiplier then
--         xp:AddXP(perk, args.amount, false, false, false)
--     else
--         xp:AddXPNoMultiplier(perk, args.amount)
--     end
--     print("Server: " .. tostring(command) .. " (Update) applied to " .. player:getUsername())
-- end

-- local function UpdateXPToLevel(player, args, command)
--     local xp = player:getXp()
--     for i = args.currentLevel + 1, args.targetLevel do
--         player:LevelPerk(args.perk)
--         xp:setXPToLevel(args.perk, i)
--     end
--     print("Server: " .. tostring(command) .. " (Update) applied to " .. player:getUsername())
-- end

local function onClientCommands(module, command, player, args)
    if module ~= 'ToadTraits' then
        return
    end

    if command == 'Vagabond' then
        ProcessTraitLoot(player, args, "bVagbondRolled", "bin")
    end

    if command == 'Scrounger' then
        ProcessTraitLoot(player, args, "bScroungerorIncomprehensiveRolled", nil)
    end

    if command == 'Antique' then
        ProcessTraitLoot(player, args, "bAntiqueRolled", nil)
    end

    if command == 'Incomprehensive' then
        ProcessTraitLootRemoval(player, args, "bScroungerorIncomprehensiveRolled")
    end

    if command == 'Gourmand' then
        ProcessGourmand(player, args)
    end

    if command == 'GraveRobber' then
        ProcessGraveRobber(player, args)
    end

    if command == 'UpdateStats' then
        UpdateStats(player, args, command)
    end

    if command == 'BodyPartMechanics' then
        ProcessBodyPartMechanics(player, args)
    end

    if command == 'MT_updateWeight' then
        ProcessUpdateWeight(player, args)
    end

    if command == 'FastGimp' then
        ProcessFastGimp(player, args)
    end

    if command == 'Immunocompromised' then
        ProcessImmunocompromised(player, args)
    end

    if command == 'GlassBody' then
        ProcessGlassBody(player, args)
    end

    if command == 'InfectPlayer' then
        ProcessInfectPlayer(player)
    end

    if command == 'EvasiveDodge' then
        ProcessEvasive(player, args)
    end

    if command == 'ApplyGordanite' then
        ProcessApplyGordanite(player, args)
    end

    if command == 'RevertGordanite' then
        ProcessRevertGordanite(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommands)