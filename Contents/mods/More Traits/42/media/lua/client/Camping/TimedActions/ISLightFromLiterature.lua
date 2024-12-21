
require "TimedActions/ISBaseTimedAction"

ISLightFromLiterature = ISBaseTimedAction:derive("ISLightFromLiterature");

function ISLightFromLiterature:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	self.campfire:updateFromIsoObject()
	return self.campfire:getObject() ~= nil and
		self.character:getInventory():contains(self.lighter) and
		self.character:getInventory():contains(self.item) and
		not self.campfire.isLit
end

function ISLightFromLiterature:waitToStart()
	self.character:faceThisObject(self.campfire:getObject())
	return self.character:shouldBeTurning()
end

function ISLightFromLiterature:update()
	self.item:setJobDelta(self:getJobDelta());
	self.character:faceThisObject(self.campfire:getObject())
end

function ISLightFromLiterature:start()
	self.item:setJobType(campingText.lightCampfire);
	self.item:setJobDelta(0.0);
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")
	self.character:reportEvent("EventLootItem");
	self.sound = self.character:playSound("CampfireLight")
end

function ISLightFromLiterature:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ISLightFromLiterature:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);
	self.character:getInventory():Remove(self.item);
	self.lighter:Use();

	local fuelAmt = self.fuelAmt * 60
	local cf = self.campfire
	local args = { x = cf.x, y = cf.y, z = cf.z, fuelAmt = fuelAmt }
	CCampfireSystem.instance:sendCommand(self.character, 'lightFire', args)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISLightFromLiterature:new(character, item, lighter, campfire, fuelAmt, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.campfire = campfire;
	o.item = item;
	o.lighter = lighter;
	o.fuelAmt = fuelAmt;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	return o;
end
