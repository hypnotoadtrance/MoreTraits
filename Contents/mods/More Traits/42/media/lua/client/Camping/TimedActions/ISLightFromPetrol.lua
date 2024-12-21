
require "TimedActions/ISBaseTimedAction"

ISLightFromPetrol = ISBaseTimedAction:derive("ISLightFromPetrol");

function ISLightFromPetrol:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	self.campfire:updateFromIsoObject()
	local playerInv = self.character:getInventory()
	return playerInv:contains(self.petrol) and playerInv:contains(self.lighter) and
			self.lighter:getUsedDelta() > 0 and
			self.petrol:getUsedDelta() > 0 and
			self.campfire:getObject() ~= nil and
			not self.campfire.isLit and
			self.campfire.fuelAmt > 0
end

function ISLightFromPetrol:waitToStart()
	self.character:faceThisObject(self.campfire:getObject())
	return self.character:shouldBeTurning()
end

function ISLightFromPetrol:update()
	self.petrol:setJobDelta(self:getJobDelta());
	self.character:faceThisObject(self.campfire:getObject())
end

function ISLightFromPetrol:start()
	self.petrol:setJobType(campingText.lightCampfire);
	self.petrol:setJobDelta(0.0);
	self:setActionAnim(CharacterActionAnims.Pour)
	-- Don't call setOverrideHandModels() with self.petrol, the right-hand mask
	-- will bork the animation.
	self:setOverrideHandModels(self.petrol:getStaticModel(), nil)
end

function ISLightFromPetrol:stop()
	ISBaseTimedAction.stop(self);
    self.petrol:setJobDelta(0.0);
end

function ISLightFromPetrol:perform()
	self.petrol:getContainer():setDrawDirty(true);
    self.petrol:setJobDelta(0.0);
	self.petrol:Use()
	self.lighter:Use()

	local cf = self.campfire
	local args = { x = cf.x, y = cf.y, z = cf.z }
	CCampfireSystem.instance:sendCommand(self.character, 'lightFire', args)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISLightFromPetrol:new(character, campfire, lighter, petrol, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = time;
	-- custom fields
	o.campfire = campfire
	o.lighter = lighter
	o.petrol = petrol
	return o;
end
