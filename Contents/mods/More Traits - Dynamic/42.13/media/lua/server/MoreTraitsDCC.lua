local function ProcessTraitChange(player, trait, isAddition)
    if not trait then return end
    local traits = player:getCharacterTraits()
    local exactTrait = ToadTraitsRegistries[trait]
    
    if isAddition then
        traits:add(exactTrait)
    else
        traits:remove(exactTrait)
    end
end

local function ProcessXPBoosts(player, perk, boostAmount)
    if not perk and not boostAmount then return end

    player:getXp():setPerkBoost(perk, boostAmount)
end

local function onClientCommands(module, command, player, args)
    if module ~= 'MoreTraitsDynamic' then return end
    if command == 'addTrait' then
        ProcessTraitChange(player, args.trait, true)
    elseif command == 'removeTrait' then
        ProcessTraitChange(player, args.trait, false)
    end

    if command == 'setXpBoosts' then
        ProcessXPBoosts(player, args.perk, args.boostAmount)
    end
end

Events.OnClientCommand.Add(onClientCommands)