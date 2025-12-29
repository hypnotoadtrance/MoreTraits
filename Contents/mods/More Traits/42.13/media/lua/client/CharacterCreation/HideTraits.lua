
--[[
HideTraits
@Author: FallenTemplar
@version 42.13
@description Hides traits from the character creation screen to avoid breaking the menu by disabling the registries instead when mods are active.
]]

local function isModActivated(modName) return getActivatedMods():contains(modName) end


local preparedTraits = {
    "preparedfood", "preparedammo", "preparedmedical", "preparedrepair",
    "preparedcamp", "preparedweapon", "preparedpack", "preparedcar",
    "preparedcoordination"
}

local specializationTraits = {
    "specweapons", "speccrafting", "specfood",
    "specguns", "specmove", "specaid"
}

local function removeTraits()
    if isModActivated("\\1299328280/ToadTraitsDisablePrepared") == false and isModActivated("\\1299328280/ToadTraitsDisableSpec") == false then return end
    
    local traitDefs = CharacterTraitDefinition.characterTraitDefinitions
    local traitsToRemove = {}

    if isModActivated("\\1299328280/ToadTraitsDisablePrepared") then
        for _, v in ipairs(preparedTraits) do table.insert(traitsToRemove, v) end
    end

    if isModActivated("\\1299328280/ToadTraitsDisableSpec") then
        for _, v in ipairs(specializationTraits) do table.insert(traitsToRemove, v) end
    end

    for _, traitName in ipairs(traitsToRemove) do
        local traitEnum = ToadTraitsRegistries[traitName]
    
        if traitEnum and traitDefs:containsKey(traitEnum) then
            traitDefs:remove(traitEnum)
        end
    end
end


Events.OnGameBoot.Add(removeTraits)