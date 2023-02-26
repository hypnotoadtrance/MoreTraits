require "TimedActions/ISBaseTimedAction"

ISBBQLightFromPetrol = ISBaseTimedAction:derive("ISBBQLightFromPetrol")

function ISBBQLightFromPetrol:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	local playerInv = self.character:getInventory()
	return playerInv:contains(self.petrol) and playerInv:contains(self.lighter) and
			self.lighter:getUsedDelta() > 0 and
			self.petrol:getUsedDelta() > 0 and
			self.bbq:getObjectIndex() ~= -1 and
			not self.bbq:isLit() and
			self.bbq:hasFuel()
end

function ISBBQLightFromPetrol:waitToStart()
	self.character:faceThisObject(self.bbq)
	return self.character:shouldBeTurning()
end

function ISBBQLightFromPetrol:update()
	self.character:faceThisObject(self.bbq)
	self.petrol:setJobDelta(self:getJobDelta())
end

function ISBBQLightFromPetrol:start()
	self.petrol:setJobType(campingText.lightCampfire)
	self.petrol:setJobDelta(0.0)
	self:setActionAnim(CharacterActionAnims.Pour)
--	self:setAnimVariable("FoodType", "Kettle");
	-- Don't call setOverrideHandModels() with self.petrol, the right-hand mask
	-- will bork the animation.
	self:setOverrideHandModels(self.petrol:getStaticModel(), nil)
	self.sound = self.character:playSound("BBQRegularLight")
end

function ISBBQLightFromPetrol:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.petrol:setJobDelta(0.0)
	ISBaseTimedAction.stop(self)
end

function ISBBQLightFromPetrol:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.petrol:getContainer():setDrawDirty(true)
    self.petrol:setJobDelta(0.0)
    self.lighter:Use()
    self.petrol:Use()
	local bbq = self.bbq
	local args = { x = bbq:getX(), y = bbq:getY(), z = bbq:getZ() }
	sendClientCommand(self.character, 'bbq', 'light', args)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISBBQLightFromPetrol:new(character, bbq, lighter, petrol, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	-- custom fields
	o.bbq = bbq
	o.lighter = lighter
	o.petrol = petrol
	return o
end
