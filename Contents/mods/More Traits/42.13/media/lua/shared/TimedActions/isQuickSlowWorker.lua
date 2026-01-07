local function MT_QuickSlowTraitCheck(self, baseTime, timedAction)
    if not self.character then return baseTime end
    if baseTime <= 1 then return baseTime end
    if self.character:isTimedActionInstant() then return 1 end

    local isQuick = self.character:hasTrait(ToadTraitsRegistries.quickworker)
    local isSlow = self.character:hasTrait(ToadTraitsRegistries.slowworker)

    if not isQuick and not isSlow then
        return baseTime
    end

    local modifier = 0

    if isQuick then
        modifier = (SandboxVars.MoreTraits.QuickWorkerScaler or 50) * 0.01
    elseif isSlow then
        modifier = (SandboxVars.MoreTraits.SlowWorkerScaler or 50) * 0.01
    end

    if timedAction and timedAction == "ISReadABook" then
        if self.character:hasTrait(CharacterTrait.FAST_READER) then
            modifier = modifier * (isQuick and 5 or 0.1)
        elseif self.character:hasTrait(CharacterTrait.SLOW_READER) then
            modifier = modifier * (isQuick and 1.5 or 0.5)
        else
            modifier = modifier * (isQuick and 3 or 0.25)
        end
    end

    local bonus = 0
    if ZombRand(100) <= 10 then
        if self.character:hasTrait(ToadTraitsRegistries.lucky) then 
            bonus = bonus + (0.25 * (luckimpact or 1)) 
        end
        if self.character:hasTrait(CharacterTrait.DEXTROUS) then 
            bonus = bonus + 0.25 
        end
        if self.character:hasTrait(ToadTraitsRegistries.unlucky) then 
            bonus = bonus - (0.25 * (luckimpact or 1)) 
        end
        if self.character:hasTrait(CharacterTrait.ALL_THUMBS) then 
            bonus = bonus - 0.25 
        end
    end

    if isQuick then
        local finalReduction = math.max(0, modifier + bonus)
        baseTime = baseTime - (baseTime * finalReduction)
    elseif isSlow then
        local finalPenalty = math.max(0, modifier - bonus)
        baseTime = baseTime + (baseTime * finalPenalty)
    end

    -- Never want to drop below 1 frame, unlikely to happen but better to guard.
    return math.max(1, baseTime)
end

-- Shared Functions
local function isSplint()
    require "TimedActions/ISSplint"
    if not _G["ISSplint"] then return end

    local o_ISSplint_new = ISSplint.new
    ISSplint.new = function(self, character, otherPlayer, rippedSheet, plank, bodyPart, doIt)
        local o = o_ISSplint_new(self, character, otherPlayer, rippedSheet, plank, bodyPart, doIt)
        o.maxTime = o:getDuration()
        return o
    end

    ISSplint.getDuration = function(self)
        local baseTime = 140 - (self.character:getPerkLevel(Perks.Doctor) * 4)
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isCutHair()
    require "TimedActions/ISCutHair"
    if not _G["ISCutHair"] then return end

    local o_ISCutHair_new = ISCutHair.new
    ISCutHair.new = function(self, character, hairStyle, item, maxTime)
        local o = o_ISCutHair_new(self, character, hairStyle, item, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISCutHair.getDuration = function(self)
        local baseTime = self.maxTime
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isShovelAction()
    require "Farming/TimedActions/ISShovelAction"
    if not _G["ISShovelAction"] then return end

    local o_ISShovelAction_new = ISShovelAction.new
    ISShovelAction.new = function(self, character, item, plant, maxTime)
        local o = o_ISShovelAction_new(self, character, item, plant, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISShovelAction.getDuration = function(self)
        local baseTime = self.maxTime
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isLightFromPetrol()
    require "Camping/TimedActions/ISLightFromPetrol"
    if not _G["ISLightFromPetrol"] then return end

    local o_ISLightFromPetrol_new = ISLightFromPetrol.new
    ISLightFromPetrol.new = function(self, character, campfire, lighter, petrol, maxTime)
        local o = o_ISLightFromPetrol_new(self, character, campfire, lighter, petrol, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISLightFromPetrol.getDuration = function(self)
        local baseTime = self.maxTime
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isRemoveCampfireAction()
    require "Camping/TimedActions/ISRemoveCampfireAction"
    if not _G["ISRemoveCampfireAction"] then return end

    local o_ISRemoveCampfireAction_new = ISRemoveCampfireAction.new
    ISRemoveCampfireAction.new = function(self, character, campfire, maxTime)
        local o = o_ISRemoveCampfireAction_new(self, character, campfire, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISRemoveCampfireAction.getDuration = function(self)
        local baseTime = self.maxTime
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isFluidTransferAction()
    require "Fluids/ISFluidTransferAction"
    if not _G["ISFluidTransferAction"] then return end

    local o_ISFluidTransferAction_new = ISFluidTransferAction.new
    ISFluidTransferAction.new = function(self, character, sourceContainer, sourceFluidObject, targetContainer, targetFluidObject, amount)
        local o = o_ISFluidTransferAction_new(self, character, sourceContainer, sourceFluidObject, targetContainer, targetFluidObject, amount)
        if o then
            o.maxTime = o:getDuration()
        end
        return o
    end

    ISFluidTransferAction.getDuration = function(self)
        local baseTime = self.maxTime
        
        if not baseTime or baseTime == 0 then
            local amount = self.amount or 0
            baseTime = amount * ISFluidUtil.getTransferActionTimePerLiter()
            
            if baseTime < ISFluidUtil.getMinTransferActionTime() then
                baseTime = ISFluidUtil.getMinTransferActionTime()
            end
        end

        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isDrinkFluidAction()
    require "TimedActions/ISDrinkFluidAction"
    if not _G["ISDrinkFluidAction"] then return end

    local o_ISDrinkFluidAction_new = ISDrinkFluidAction.new
    ISDrinkFluidAction.new = function(self, character, item, percentage)
        local o = o_ISDrinkFluidAction_new(self, character, item, percentage)
        if o then
            o.maxTime = o:getDuration()
        end
        return o
    end

    ISDrinkFluidAction.getDuration = function(self)
        local baseTime = self.maxTime or 232
        if baseTime == 0 then baseTime = 232 end
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

-- local function isDryMyself()
--     require "TimedActions/ISDryMyself"
--     if not _G["ISDryMyself"] then return end

--     local o_ISDryMyself_new = ISDryMyself.new
--     ISDryMyself.new = function(self, character, item)
--         local o = o_ISDryMyself_new(self, character, item)
--         if o then
--             o.maxTime = o:getDuration()
--             o.timer = o.maxTime / 20
--         end
--         return o
--     end

--     ISDryMyself.getDuration = function(self)
--         local useLeft = 1
--         if self.item and self.item.getCurrentUsesFloat then
--             useLeft = math.ceil(self.item:getCurrentUsesFloat() * 10)
--         end
--         local baseTime = (useLeft * 20) + 20
--         return MT_QuickSlowTraitCheck(self, baseTime)
--     end
-- end

local function isPickAxeGroundCoverItem()
    require "TimedActions/ISPickAxeGroundCoverItem"
    if not _G["ISPickAxeGroundCoverItem"] then return end

    local o_new = ISPickAxeGroundCoverItem.new
    ISPickAxeGroundCoverItem.new = function(self, character, item)
        local o = o_new(self, character, item)
        if o then
            o.maxTime = o:getDuration()
        end
        return o
    end

    ISPickAxeGroundCoverItem.getDuration = function(self)
        local strength = self.character:getPerkLevel(Perks.Strength)
        local baseTime = 300 - (strength * 10)
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isWringClothing()
    require "TimedActions/ISWringClothing"
    if not _G["ISWringClothing"] then return end

    local o_new = ISWringClothing.new
    ISWringClothing.new = function(self, character, item)
        local o = o_new(self, character, item)
        if o then
            o.maxTime = o:getDuration()
        end
        return o
    end

    ISWringClothing.getDuration = function(self)
        local baseTime = 10
        if self.item and self.item.getWetness then
            baseTime = math.ceil(self.item:getWetness() * 5)
        end
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function IsFertilizeAction()
    require "Farming/TimedActions/ISFertilizeAction"
    if not _G["ISFertilizeAction"] then return end

    local o_ISFertilizeAction_new = ISFertilizeAction.new
    ISFertilizeAction.new = function(self, character, item, plant, maxTime)
        local o = o_ISFertilizeAction_new(self, character, item, plant, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISFertilizeAction.getDuration = function(self)
        local baseTime = self.maxTime;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isWaterPlantAction()
    require "Farming/TimedActions/ISWaterPlantAction"

    local o_ISWaterPlantAction_new = ISWaterPlantAction.new
    ISWaterPlantAction.new = function(self, character, item, uses, sq, maxTime)
        local o = o_ISWaterPlantAction_new(self, character, item, uses, sq, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISWaterPlantAction.getDuration = function(self)
        local baseTime = self.maxTime;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isCurePlantAction()
    require "Farming/TimedActions/ISCurePlantAction"
    if not _G["ISCurePlantAction"] then return end

    local o_ISCurePlantAction_new = ISCurePlantAction.new
    ISCurePlantAction.new = function(self, character, item, uses, plant, maxTime, cure)
        local o = o_ISCurePlantAction_new(self, character, item, uses, plant, maxTime, cure)
        o.maxTime = o:getDuration()
        return o
    end

    ISCurePlantAction.getDuration = function(self)
        local baseTime = self.maxTime;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isHarvestPlantAction()
    require "Farming/TimedActions/ISHarvestPlantAction"
    if not _G["ISHarvestPlantAction"] then return end

    local o_ISHarvestPlantAction_new = ISHarvestPlantAction.new
    ISHarvestPlantAction.new = function(self, character, item, uses, plant, maxTime, cure)
        local o = o_ISHarvestPlantAction_new(self, character, item, uses, plant, maxTime, cure)
        o.maxTime = o:getDuration()
        return o
    end

    ISHarvestPlantAction.getDuration = function(self)
        local baseTime = self.maxTime;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isInstallVehiclePart()
    require "Vehicles/TimedActions/ISInstallVehiclePart"
    if not _G["ISInstallVehiclePart"] then return end

    local o_ISInstallVehiclePart_new = ISInstallVehiclePart.new
    ISInstallVehiclePart.new = function(self, character, part, item, maxTime)
        local o = o_ISInstallVehiclePart_new(self, character, part, item, maxTime)
        o.maxTime = o:getDuration()
        return o
    end

    ISInstallVehiclePart.getDuration = function(self)
        local baseTime = self.maxTime;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isEmptyWaterInTrough()
    require "FeedingTrough/TimedActions/ISEmptyWaterInTrough"
    if not _G["ISEmptyWaterInTrough"] then return end

    local o_ISEmptyWaterInTrough_new = ISEmptyWaterInTrough.new
    ISEmptyWaterInTrough.new = function(self, character, objectTo)
        local o = o_ISEmptyWaterInTrough_new(self, character, objectTo)
        if o then
            o.maxTime = o:getDuration()
        end
        return o
    end

    ISEmptyWaterInTrough.getDuration = function(self)       
        local baseTime = 100
        if self.objectTo and self.objectTo.getWater then
            baseTime = self.objectTo:getWater() * 4
        end
        
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

-- ClientSide Functions
local function isReadWorldMap()
    require "TimedActions/ISReadWorldMap"
    if not _G["ISReadWorldMap"] then return end
    local o_ISReadWorldMap_new = ISReadWorldMap.new
    ISReadWorldMap.new = function(self, character, centerX, centerY, zoom)
        local o = o_ISReadWorldMap_new(self, character, centerX, centerY, zoom)
        o.maxTime = o:getDuration()
        return o
    end

    ISReadWorldMap.getDuration = function(self)
        local baseTime = 50;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isAttachTrailerToVehicle()
    require "Vehicles/TimedActions/ISAttachTrailerToVehicle"
    if not _G["ISAttachTrailerToVehicle"] then return end
    local o_ISAttachTrailerToVehicle_new = ISAttachTrailerToVehicle.new
    ISAttachTrailerToVehicle.new = function(self, character, vehicleA, vehicleB, attachmentA, attachmentB)
        local o = o_ISAttachTrailerToVehicle_new(self, character, vehicleA, vehicleB, attachmentA, attachmentB)
        o.maxTime = o:getDuration()
        return o
    end

    ISAttachTrailerToVehicle.getDuration = function(self)
        local baseTime = 100;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isDetachTrailerFromVehicle()
    require "Vehicles/TimedActions/ISDetachTrailerFromVehicle"
    if not _G["ISDetachTrailerFromVehicle"] then return end
    local o_ISDetachTrailerFromVehicle_new = ISDetachTrailerFromVehicle.new
    ISDetachTrailerFromVehicle.new = function(self, character, vehicle, attachment)
        local o = o_ISDetachTrailerFromVehicle_new(self, character, vehicle, attachment)
        o.maxTime = o:getDuration()
        return o
    end

    ISDetachTrailerFromVehicle.getDuration = function(self)
        local baseTime = 100;
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isOpenMechanicsUIAction()
    require "Vehicles/TimedActions/ISOpenMechanicsUIAction"
    if not _G["ISOpenMechanicsUIAction"] then return end

    local o_ISOpenMechanicsUIAction_new = ISOpenMechanicsUIAction.new
    ISOpenMechanicsUIAction.new = function(self, character, vehicle, usedHood)
        local o = o_ISOpenMechanicsUIAction_new(self, character, vehicle, usedHood)
        if o then
            o.maxTime = o:getDuration()
        end
        return o
    end

    ISOpenMechanicsUIAction.getDuration = function(self)
        local cheat = getCore():getDebug() and getDebugOptions():getBoolean("Cheat.Vehicle.MechanicsAnywhere")
        if (self.vehicle:getScript() and self.vehicle:getScript():getWheelCount() == 0) or 
           (ISVehicleMechanics.cheat or cheat) then
            return 1
        end

        local mechLevel = self.character:getPerkLevel(Perks.Mechanics)
        local baseTime = 200 - (mechLevel * (200 / 15))
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isMedicalCheckAction()
    require "TimedActions/ISMedicalCheckAction"
    if not _G["ISMedicalCheckAction"] then return end
    local o_ISMedicalCheckAction_new = ISMedicalCheckAction.new
    ISMedicalCheckAction.new = function(self, character, otherPlayer)
        local o = o_ISMedicalCheckAction_new(self, character, otherPlayer)
        o.maxTime = o:getDuration()
        return o
    end

    ISMedicalCheckAction.getDuration = function(self)
        local baseTime = 150 - (self.character:getPerkLevel(Perks.Doctor) * 2.5);
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end

local function isBuildAction()
    require "BuildingObjects/TimedActions/ISBuildAction"
    if not _G["ISBuildAction"] then return end
    local o_ISBuildAction_new = ISBuildAction.new
    ISBuildAction.new = function(self, character, item, x, y, z, north, spriteName, time)
        local o = o_ISBuildAction_new(self, character, item, x, y, z, north, spriteName, time)
        o.maxTime = o:getDuration()
        return o
    end

    ISBuildAction.getDuration = function(self)
        local baseTime = self.time;
        if self.character:hasTrait(CharacterTrait.HANDY) then
            baseTime = self.time - 50;
        end
        return MT_QuickSlowTraitCheck(self, baseTime)
    end
end
local function isInventoryTransferAction()
    require "TimedActions/ISInventoryTransferAction"
    if not _G["ISInventoryTransferAction"] then return end
    local o_ISInventoryTransferAction_new = ISInventoryTransferAction.new
    function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
        local o = o_ISInventoryTransferAction_new(self, character, item, srcContainer, destContainer, time)
        if o.maxTime == -1 and o.queueList and o.queueList[1] then
            o.maxTime = o.queueList[1].time
        end
        o.maxTime = MT_QuickSlowTraitCheck(o, o.maxTime)
        if o.queueList and o.queueList[1] then
            o.queueList[1].time = o.maxTime
        end
        return o
    end
end

-- Should iterate through all the Timed Actions and apply `MT_QuickSlowTraitCheck` bonuses
local function isWorker()
    for _, timedAction in pairs(_G) do
        
        if type(timedAction) == "table" and timedAction.getDuration then
            
            local original_getDuration = timedAction.getDuration
            
            timedAction.getDuration = function(self)
                local duration = original_getDuration(self)
                
                return MT_QuickSlowTraitCheck(self, duration, timedAction)
            end
        end
    end
end

-- These are the timed actions we've manually had to override and apply a duration to allow MP adjustments
local function injectShared()
    isSplint()
    IsFertilizeAction()
    isWaterPlantAction()
    isCurePlantAction()
    isHarvestPlantAction()
    isInstallVehiclePart()
    isCutHair()
    isShovelAction()
    isLightFromPetrol()
    isRemoveCampfireAction()
    isFluidTransferAction()
    isDrinkFluidAction()
    -- isDryMyself()
    isPickAxeGroundCoverItem()
    isWringClothing()
    isEmptyWaterInTrough()
end

local function injectClient()
    isReadWorldMap()
    isAttachTrailerToVehicle()
    isDetachTrailerFromVehicle()
    isOpenMechanicsUIAction()
    isMedicalCheckAction()
    isBuildAction() -- SP Only
    isInventoryTransferAction() -- SP Only
end

Events.OnGameBoot.Add(isWorker)
Events.OnGameBoot.Add(injectShared)

if isClient() or not isServer() then
    Events.OnMainMenuEnter.Add(injectClient)
end