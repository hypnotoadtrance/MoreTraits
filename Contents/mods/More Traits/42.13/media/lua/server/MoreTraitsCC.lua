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
            object:getModData()[modDataKey] = true
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

    if args.panic then
        stats:set(CharacterStat.PANIC, args.panic)
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
    if args.boredom then
        stats:set(CharacterStat.BOREDOM, args.boredom)
    end
    if args.unhappiness then
        stats:set(CharacterStat.UNHAPPINESS, args.unhappiness)
    end
    if args.zombie_fever then
        stats:set(CharacterStat.ZOMBIE_FEVER, args.zombie_fever)
    end
    if args.zombie_infection then
        stats:set(CharacterStat.ZOMBIE_INFECTION, args.zombie_infection)
    end
    if args.sickness then
        stats:set(CharacterStat.SICKNESS, args.sickness)
    end
    if args.anger then
        stats:set(CharacterStat.ANGER, args.anger)
    end
    if args.idleness then
        stats:set(CharacterStat.IDLENESS, args.idleness)
    end
    if args.poison then
        stats:set(CharacterStat.POISON, args.poison)
    end

    print("Server: " .. tostring(command) .. " (Update) applied to " .. player:getUsername())
end
local function UpdateXP(player, args, command)
    local xp = player:getXp()
    if args.multiplier then
        xp:AddXP(perk, amount, false, false, false)
    else
        xp:AddXPNoMultiplier(args.perk, args.amount)
    end
    print("Server: " .. tostring(command) .. " (Update) applied to " .. player:getUsername())
end
local function UpdateXPToLevel(player, args, command)
    local xp = player:getXp()
    for i = args.currentLevel + 1, args.targetLevel do
        player:LevelPerk(args.perk)
        xp:setXPToLevel(args.perk, i)
    end
    print("Server: " .. tostring(command) .. " (Update) applied to " .. player:getUsername())
end
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
    if command == 'UpdateXP' then
        UpdateXP(player, args, command)
    end
    if command == 'UpdateXPToLevel' then
        UpdateXPToLevel(player, args, command)

    end
end

Events.OnClientCommand.Add(onClientCommands)