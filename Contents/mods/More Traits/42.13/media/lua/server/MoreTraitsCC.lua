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

local function VagabondCC(module, command, player, args)
    local gridSquare = getCell():getGridSquare(args.x, args.y, args.z)
    if not gridSquare then return end
    
    local objects = gridSquare:getObjects()
    for i=0, objects:size()-1 do
        local object = objects:get(i)
        local container = object:getContainer()
        
        if container and container:getType() == "bin" then
            for _, itemType in ipairs(args.items) do
                local item = container:AddItem(itemType)
                if item then sendAddItemToContainer(container, item) end
            end
            object:getModData().bVagbondRolled = true
            object:transmitModData()
            break
        end
    end
end

local function onClientCommands(module, command, player, args)
    if module ~= 'ToadTraits' then return end

    if command == 'Vagabond' and player:hasTrait(ToadTraitsRegistries.vagabond) then
        VagabondCC(module, command, player, args)
    end

end

Events.OnClientCommand.Add(onClientCommands)