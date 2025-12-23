-- Function covers Vagabond, Scrounger, Antique
local function ProcessTraitLoot(player, args, modData, specificContainer)
    local gridSquare = getCell():getGridSquare(args.x, args.y, args.z)
    if not gridSquare then return end
    
    local objects = gridSquare:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        local container = object:getContainer()
        
        -- Check if container exists AND (if specificContainer is nil OR matches the type)
        if container and (not specificContainer or container:getType() == specificContainer) then
            for _, itemType in ipairs(args.items) do
                local item = container:AddItem(itemType)
                if item then sendAddItemToContainer(container, item) end
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
    if not gridSquare then return end
    
    local objects = gridSquare:getObjects()
    for i=0, objects:size()-1 do
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
    if not gridSquare then return end
    
    local objects = gridSquare:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        local container = object:getContainer()

        if container then
            for _, itemType in ipairs(args.items) do
                local items = container:getItems()
                for j=0, items:size()-1 do
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

local function onClientCommands(module, command, player, args)
    if module ~= 'ToadTraits' then return end

    if command == 'Vagabond' and player:hasTrait(ToadTraitsRegistries.vagabond) then
        ProcessTraitLoot(player, args, "bVagbondRolled", "bin")
    end

    if command == 'Scrounger' and player:hasTrait(ToadTraitsRegistries.scrounger) then
        ProcessTraitLoot(player, args, "bScroungerorIncomprehensiveRolled", nil)
    end

    if command == 'Antique' and player:hasTrait(ToadTraitsRegistries.antique) then
        ProcessTraitLoot(player, args, "bAntiqueRolled", nil)
    end

    if command == 'Incomprehensive' and player:hasTrait(ToadTraitsRegistries.incomprehensive) then
        ProcessTraitLootRemoval(player, args, "bScroungerorIncomprehensiveRolled")
    end

    if command == 'Gourmand' and player:hasTrait(ToadTraitsRegistries.gourmand) then
        ProcessGourmand(player, args)
    end

end

Events.OnClientCommand.Add(onClientCommands)