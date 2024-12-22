--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISFireplaceLightFromKindle = ISBaseTimedAction:derive("ISFireplaceLightFromKindle");

function ISFireplaceLightFromKindle:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	if isClient() and self.item and self.plank then
		return self.fireplace:getObjectIndex() ~= -1 and self.item ~= nil and
				self.character:getInventory():containsID(self.item:getID()) and
				self.character:getInventory():containsID(self.plank:getID()) and
				not self.fireplace:isLit() and
				self.character:getStats():getEndurance() > 0
	else
		return self.fireplace:getObjectIndex() ~= -1 and self.item ~= nil and
				self.character:getInventory():contains(self.item) and
				self.character:getInventory():contains(self.plank) and
				not self.fireplace:isLit() and
				self.character:getStats():getEndurance() > 0
	end
end

function ISFireplaceLightFromKindle:waitToStart()
	self.character:faceThisObject(self.fireplace)
	return self.character:shouldBeTurning()
end

function ISFireplaceLightFromKindle:update()
	self.character:faceThisObject(self.fireplace)
	self.item:setJobDelta(self:getJobDelta());
	self.plank:setJobDelta(self:getJobDelta());

	if not isClient() then
		self:updateKindling();
	end
end

function ISFireplaceLightFromKindle:updateKindling()
	-- every tick we lower the endurance of the player, he also have a chance to light the fire or broke the kindle
	local endurance = self.character:getStats():getEndurance() - 0.0001 * getGameTime():getMultiplier()
	self.character:getStats():setEndurance(endurance);
	if not isServer() then
		if self:getJobDelta() < 0.2 then return end
	else
		if self.netAction:getProgress() < 0.2 then return end
	end
	local randNumber = 30;
	local randBrokeNumber = 30;
	if self.isOutdoorsMan then
		randNumber = 15;
		randBrokeNumber = 45;
	end
	if ZombRand(randNumber) == 0 then
		if self.fireplace then
			self.fireplace:setLit(true)
			self.fireplace:sendObjectChange('state')
		end
		if isServer() then
			self.netAction:forceComplete()
		else
			self:forceComplete()
		end
	else
		-- fail ? Maybe the wood kit will broke...
		if ZombRand(randBrokeNumber) == 0 then
			self.character:getInventory():Remove(self.item);
			sendRemoveItemFromContainer(self.character:getInventory(),self.item)
			if isServer() then
				sendPlaySound("BreakWoodItem", false, self.character)
				self.item = nil
				self.netAction:forceComplete()
			else
				self.character:getEmitter():playSound("BreakWoodItem")
				self:forceComplete()
			end
		end
	end
end

function ISFireplaceLightFromKindle:start()
	if isClient() and self.item and self.plank then
		self.item = self.character:getInventory():getItemById(self.item:getID())
		self.plank = self.character:getInventory():getItemById(self.plank:getID())
	end
	self.item:setJobType(campingText.lightCampfire)
	self.item:setJobDelta(0.0);
	self.plank:setJobType(campingText.lightCampfire);
	self.plank:setJobDelta(0.0);
	self.sound = self.character:playSound("FireplaceLight")
end

function ISFireplaceLightFromKindle:stop()
	self.character:stopOrTriggerSound(self.sound)
	if self.item then
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ISFireplaceLightFromKindle:perform()
	self.character:stopOrTriggerSound(self.sound)
	if self.item and self.item:getContainer() then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);

	if self.fireplace and not self.fireplace.isLit then
		local item = self.character:getInventory():FindAndReturn("WoodenStick");
		if not item then
			item = self.character:getInventory():FindAndReturn("WoodenStick2");
		end
		if not item then
			item = self.character:getInventory():FindAndReturn("TreeBranch");
		end
		if not item then
			item = self.character:getInventory():FindAndReturn("TreeBranch2");
		end
		if item then
			ISTimedActionQueue.add(ISLightFromKindle:new(self.character, self.plank, item, self.fireplace));
		end
	end

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISFireplaceLightFromKindle:complete()

	return true;
end

function ISFireplaceLightFromKindle:animEvent(event, parameter)
	if isServer() then
		if event == 'CheckLit' then
			self:updateKindling();
		end
	end
end

function ISFireplaceLightFromKindle:serverStart()
	emulateAnimEvent(self.netAction, 100, "CheckLit", nil)
end

function ISFireplaceLightFromKindle:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 1500
end

function ISFireplaceLightFromKindle:new(character, plank, item, fireplace)
	local o = ISBaseTimedAction.new(self, character);
	o.item = item;
	o.plank = plank;
	o.fireplace = fireplace;
	-- if you are a outdoorsman (ranger) you can light the fire faster
	o.isOutdoorsMan = character:HasTrait("Outdoorsman");
	o.maxTime = o:getDuration();
	return o;
end
