require "TimedActions/ISBaseTimedAction"
ToadTraits = require("ToadTraits/Registries")

ISLightFromLiterature = ISBaseTimedAction:derive("ISLightFromLiterature");


function ISLightFromLiterature:isValid()
	if self.character:hasTrait(ToadTraitsRegistries.burned) and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end

	self.campfire:updateFromIsoObject()
	if isClient() and self.item and self.lighter then
        return self.campfire:getObject() ~= nil and
            self.character:getInventory():containsID(self.lighter:getID()) and
            self.character:getInventory():containsID(self.item:getID()) and
            not self.campfire.isLit
	else
        return self.campfire:getObject() ~= nil and
            self.character:getInventory():contains(self.lighter) and
            self.character:getInventory():contains(self.item) and
            not self.campfire.isLit
	end
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
    if isClient() and self.item and self.lighter then
        self.lighter = self.character:getInventory():getItemById(self.lighter:getID())
        self.item = self.character:getInventory():getItemById(self.item:getID())
    end
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

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISLightFromLiterature:complete()
	self.lighter:UseAndSync();
    self.character:removeFromHands(self.item)
    self.character:getInventory():Remove(self.item)
    sendRemoveItemFromContainer(self.character:getInventory(), self.item)

	local fuelAmt = self.fuelAmt

	local campfire = SCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y, self.campfire.z)

    if campfire then
        campfire:addFuel(fuelAmt)
        campfire:lightFire()
    end

    return true
end

function ISLightFromLiterature:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 100;
end

function ISLightFromLiterature:new(character, item, lighter, campfire, fuelAmt)
	local o = ISBaseTimedAction.new(self, character)
	o.campfire = campfire;
	o.item = item;
	o.lighter = lighter;
 	o.fuelAmt = fuelAmt;
	o.maxTime = o:getDuration();
	return o;
end
