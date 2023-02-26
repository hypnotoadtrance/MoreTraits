require "TimedActions/ISBaseTimedAction"

ISFireplaceLightFromPetrol = ISBaseTimedAction:derive("ISFireplaceLightFromPetrol")

function ISFireplaceLightFromPetrol:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	local playerInv = self.character:getInventory()
	return playerInv:contains(self.petrol) and playerInv:contains(self.lighter) and
			self.lighter:getUsedDelta() > 0 and
			self.petrol:getUsedDelta() > 0 and
			self.fireplace:getObjectIndex() ~= -1 and
			not self.fireplace:isLit() and
			self.fireplace:hasFuel()
end

function ISFireplaceLightFromPetrol:waitToStart()
	self.character:faceThisObject(self.fireplace)
	return self.character:shouldBeTurning()
end

function ISFireplaceLightFromPetrol:update()
	self.petrol:setJobDelta(self:getJobDelta())
	self.character:faceThisObject(self.fireplace)
end

function ISFireplaceLightFromPetrol:start()
	self.petrol:setJobType(campingText.lightCampfire)
	self.petrol:setJobDelta(0.0)
	self.lighter:setJobType(campingText.lightCampfire)
	self.lighter:setJobDelta(0.0)
	self:setActionAnim("Pour")
	-- Don't call setOverrideHandModels() with self.petrol, the right-hand mask
	-- will bork the animation.
	self:setOverrideHandModels(self.petrol:getStaticModel(), nil)
	self.sound = self.character:playSound("FireplaceLight")
end

function ISFireplaceLightFromPetrol:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.petrol:setJobDelta(0.0)
	self.lighter:setJobDelta(0.0)
	ISBaseTimedAction.stop(self)
end

function ISFireplaceLightFromPetrol:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.petrol:getContainer():setDrawDirty(true)
    self.petrol:setJobDelta(0.0)
	self.lighter:setJobDelta(0.0)
    self.lighter:Use()
    self.petrol:Use()
	local fp = self.fireplace
	local args = { x = fp:getX(), y = fp:getY(), z = fp:getZ() }
	sendClientCommand(self.character, 'fireplace', 'light', args)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISFireplaceLightFromPetrol:new(character, fireplace, lighter, petrol, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	-- custom fields
	o.fireplace = fireplace
	o.lighter = lighter
	o.petrol = petrol
	return o
end
