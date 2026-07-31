
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
    local traitDefs = CharacterTraitDefinition.characterTraitDefinitions
    local traitsToRemove = {}

    if isModActivated("1299328280/ToadTraitsDisablePrepared") then
        for _, v in ipairs(preparedTraits) do table.insert(traitsToRemove, v) end
    end

    if isModActivated("1299328280/ToadTraitsDisableSpec") then
        for _, v in ipairs(specializationTraits) do table.insert(traitsToRemove, v) end
    end

    -- Defer to dedicated skill mods when present: these traits are always
    -- registered (see registries.lua) so script loading stays valid, but we hide
    -- our overlapping versions from character creation here.
    if isModActivated("DrivingSkill") then
        table.insert(traitsToRemove, "expertdriver")
    end

    if isModActivated("ScavengingSkill") or isModActivated("ScavengingSkillFixed") then
        table.insert(traitsToRemove, "scrounger")
    end

    if #traitsToRemove == 0 then return end

    local removedEnums = {}
    for _, traitName in ipairs(traitsToRemove) do
        local traitEnum = ToadTraitsRegistries[traitName]

        if traitEnum and traitDefs:containsKey(traitEnum) then
            traitDefs:remove(traitEnum)
            table.insert(removedEnums, traitEnum)
        end
    end

    -- Removing a definition leaves any trait that lists it as mutually exclusive
    -- pointing at a nil definition; vanilla character creation
    -- (CharacterCreationProfession:doTestForMutuallyExclusiveTraits) then calls a
    -- method on that nil and errors. Strip the removed traits from every remaining
    -- definition's mutually-exclusive list to keep those references valid.
    if #removedEnums == 0 then return end

    local allDefs = CharacterTraitDefinition.getTraits()
    for i = 0, allDefs:size() - 1 do
        local mutuallyExclusive = allDefs:get(i):getMutuallyExclusiveTraits()
        for _, removedEnum in ipairs(removedEnums) do
            if mutuallyExclusive:contains(removedEnum) then
                mutuallyExclusive:remove(removedEnum)
            end
        end
    end
end


Events.OnGameBoot.Add(removeTraits)