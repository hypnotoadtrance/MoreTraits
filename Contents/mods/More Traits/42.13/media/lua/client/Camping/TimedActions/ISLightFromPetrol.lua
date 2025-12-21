--***********************************************************
--**                    ROBERT JOHNSON                     **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISLightFromPetrol = ISBaseTimedAction:derive("ISLightFromPetrol");

function ISLightFromPetrol:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	self.campfire:updateFromIsoObject()
	local playerInv = self.character:getInventory()
	return self.campfire:getObject() ~= nil and	self.campfire.fuelAmt > 0
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

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISLightFromPetrol:complete()
	self.petrol:getFluidContainer():adjustAmount(self.petrol:getFluidContainer():getAmount() - ZomboidGlobals.LightFromPetrolAmount);
	self.lighter:UseAndSync()

	local campfire = SCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y, self.campfire.z)
	if campfire then
		campfire:lightFire()
	end

	return true
end

function ISLightFromPetrol:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return self.maxTime;
end

function ISLightFromPetrol:new(character, campfire, lighter, petrol, maxTime)
	local o = ISBaseTimedAction.new(self, character)
	o.maxTime = maxTime;
	-- custom fields
	o.campfire = campfire
	o.lighter = lighter
	o.petrol = petrol
	return o;
end
