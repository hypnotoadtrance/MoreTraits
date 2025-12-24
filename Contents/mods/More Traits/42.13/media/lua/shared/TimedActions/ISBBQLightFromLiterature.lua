require "TimedActions/ISBaseTimedAction"
--require "Camping/camping_fuel"

ISBBQLightFromLiterature = ISBaseTimedAction:derive("ISBBQLightFromLiterature")

function ISBBQLightFromLiterature:isValid()
	if self.character:hasTrait(ToadTraitsRegistries.burned) and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end

    if isClient() and self.item and self.lighter then
        return self.bbq:getObjectIndex() ~= -1  and
            self.character:getInventory():containsID(self.lighter:getID()) and
            self.character:getInventory():containsID(self.item:getID()) and
            not self.bbq:isLit()
    else
        return self.bbq:getObjectIndex() ~= -1  and
            self.character:getInventory():contains(self.lighter) and
            self.character:getInventory():contains(self.item) and
            not self.bbq:isLit()
    end
end

function ISBBQLightFromLiterature:waitToStart()
	self.character:faceThisObject(self.bbq)
	return self.character:shouldBeTurning()
end

function ISBBQLightFromLiterature:update()
	self.character:faceThisObject(self.bbq)
	self.item:setJobDelta(self:getJobDelta())
end

function ISBBQLightFromLiterature:start()
    if isClient() and self.item and self.lighter then
        self.item = self.character:getInventory():getItemById(self.item:getID())
        self.lighter = self.character:getInventory():getItemById(self.lighter:getID())
    end
	self.item:setJobType(campingText.lightFromLiterature)
	self.item:setJobDelta(0.0)
	self:setActionAnim("Loot")
	local lootPosition = "Mid"
	if instanceof(self.bbq, 'IsoFireplace') then
        lootPosition = "Low"
    end
	self.character:SetVariable("LootPosition", lootPosition)
	local soundName = "BBQRegularLight"
    local craftBenchSounds = self.bbq:getComponent(ComponentType.CraftBenchSounds)
    if craftBenchSounds ~= nil then
        local soundName2 = craftBenchSounds:getSoundName("LightFire", nil)
        if soundName2 ~= nil and soundName2 ~= "" then
            soundName = soundName2
        end
    end
	self.sound = self.character:playSound(soundName)
end

function ISBBQLightFromLiterature:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.item:setJobDelta(0.0)
	ISBaseTimedAction.stop(self)
end

function ISBBQLightFromLiterature:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.item:getContainer():setDrawDirty(true)
    self.item:setJobDelta(0.0)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISBBQLightFromLiterature:complete()
    self.lighter:UseAndSync();
    self.character:removeFromHands(self.item)
	self.character:getInventory():Remove(self.item)
	sendRemoveItemFromContainer(self.character:getInventory(), self.item);

	if not self.bbq then return end
	if self.fuelAmt then
		self.bbq:addFuel(self.fuelAmt)
	end
	if self.bbq:hasFuel() and not self.bbq:isLit() then
		self.bbq:turnOn()
		self.bbq:sendObjectChange('state')
	end

	return true;
end

function ISBBQLightFromLiterature:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 100
end

function ISBBQLightFromLiterature:new(character, item, lighter, bbq)
	local o = ISBaseTimedAction.new(self, character)
	o.maxTime = o:getDuration()
	-- custom fields
	o.bbq = bbq
	o.item = item
	o.lighter = lighter
-- 	if campingLightFireType[item:getType()] then
-- 		o.fuelAmt = campingLightFireType[item:getType()] * 60
-- 	elseif campingLightFireCategory[item:getCategory()] then
-- 		o.fuelAmt = campingLightFireCategory[item:getCategory()] * 60
-- 	end
    o.fuelAmt = ISCampingMenu.getFuelDurationForItem(item);
	return o
end
