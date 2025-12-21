require "TimedActions/ISBaseTimedAction"

ISBBQLightFromPetrol = ISBaseTimedAction:derive("ISBBQLightFromPetrol")

function ISBBQLightFromPetrol:isValid()
	if self.character:hasTrait(ToadTraitsRegistries.burned) and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	
	local playerInv = self.character:getInventory()
	return playerInv:contains(self.petrol) and playerInv:contains(self.lighter) and
			self.lighter:getCurrentUsesFloat() > 0 and
			self.petrol:getCurrentUsesFloat() > 0 and
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

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISBBQLightFromPetrol:complete()
	self.petrol:getFluidContainer():adjustAmount(self.petrol:getFluidContainer():getAmount() - ZomboidGlobals.LightFromPetrolAmount);
	self.lighter:UseAndSync()

	if not self.bbq then return end
	if self.bbq:hasFuel() and not self.bbq:isLit() then
		self.bbq:turnOn()
		self.bbq:sendObjectChange('state')
	end

	return true;
end

function ISBBQLightFromPetrol:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 20
end

function ISBBQLightFromPetrol:new(character, bbq, lighter, petrol)
	local o = ISBaseTimedAction.new(self, character)
	o.maxTime = o:getDuration();
	-- custom fields
	o.bbq = bbq
	o.lighter = lighter
	o.petrol = petrol
	return o
end
