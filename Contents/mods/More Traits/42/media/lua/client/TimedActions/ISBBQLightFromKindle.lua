--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISBBQLightFromKindle = ISBaseTimedAction:derive("ISBBQLightFromKindle");

function ISBBQLightFromKindle:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	if isClient() and self.item then
		return self.bbq:getObjectIndex() ~= -1 and self.item ~= nil and
				self.character:getInventory():containsID(self.item:getID()) and
				self.character:getInventory():containsID(self.plank:getID()) and
				not self.bbq:isLit() and
				self.character:getStats():getEndurance() > 0
	else
		return self.bbq:getObjectIndex() ~= -1 and self.item ~= nil and
				self.character:getInventory():contains(self.item) and
				self.character:getInventory():contains(self.plank) and
				not self.bbq:isLit() and
				self.character:getStats():getEndurance() > 0
	end
end

function ISBBQLightFromKindle:waitToStart()
	self.character:faceThisObject(self.bbq)
	return self.character:shouldBeTurning()
end

function ISBBQLightFromKindle:update()
	self.character:faceThisObject(self.bbq)
	self.item:setJobDelta(self:getJobDelta());
	self.plank:setJobDelta(self:getJobDelta());
	-- every tick we lower the endurance of the player, he also have a chance to light the fire or broke the kindle
	self.character:getStats():setEndurance(self.character:getStats():getEndurance() - 0.0001 * getGameTime():getMultiplier());
	if not isClient() then
		if self:getJobDelta() < 0.2 then return end
		local randNumber = 300;
		local randBrokeNumber = 300;
		if self.isOutdoorsMan then
			randNumber = 150;
			randBrokeNumber = 450;
		end
		if ZombRand(randNumber) == 0 then
			if self.bbq:hasFuel() and not self.bbq:isLit() then
				self.bbq:setLit(true)
			end
		else
			-- fail ? Maybe the wood kit will broke...
			if ZombRand(randBrokeNumber) == 0 then
				--~ 			self.character:Say("I broke my kindling...");
				self.character:getInventory():Remove(self.item);
				self.character:playSound("BreakWoodItem")
				--			self.item = self.character:getInventory():FindAndReturn("WoodenStick");
			end
		end
	end
end

function ISBBQLightFromKindle:start()
	if isClient() and self.item and self.plank then
		self.item = self.character:getInventory():getItemById(self.item:getID())
		self.plank = self.character:getInventory():getItemById(self.plank:getID())
	end
	self.item:setJobType(campingText.lightCampfire)
	self.item:setJobDelta(0.0);
	self.plank:setJobType(campingText.lightCampfire);
	self.plank:setJobDelta(0.0);
	self.sound = self.character:playSound("BBQRegularLight")
end

function ISBBQLightFromKindle:stop()
	self.character:stopOrTriggerSound(self.sound)
	if self.item then
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ISBBQLightFromKindle:perform()
	self.character:stopOrTriggerSound(self.sound)
	if self.item then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISBBQLightFromKindle:complete()
	return true;
end

function ISBBQLightFromKindle:animEvent(event, parameter)
	if isServer() then
		if event == 'CheckLit' then
			if self.netAction:getProgress() < 0.2 then return end
			local randNumber = 30;
			local randBrokeNumber = 30;
			if self.isOutdoorsMan then
				randNumber = 15;
				randBrokeNumber = 45;
			end
			if ZombRand(randNumber) == 0 then
				if self.bbq:hasFuel() and not self.bbq:isLit() then
					self.bbq:setLit(true)
					self.bbq:sendObjectChange('state')
					self.netAction:forceComplete()
				end
			else
				-- fail ? Maybe the wood kit will broke...
				if ZombRand(randBrokeNumber) == 0 then
					self.character:getInventory():Remove(self.item);
					sendRemoveItemFromContainer(self.character:getInventory(), self.item);
					self.netAction:forceComplete()
				end
			end
		end
	end
end

function ISBBQLightFromKindle:serverStart()
	emulateAnimEvent(self.netAction, 100, "CheckLit", nil)
end

function ISBBQLightFromKindle:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 1500
end

function ISBBQLightFromKindle:new(character, plank, item, bbq)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item;
	o.plank = plank;
	o.bbq = bbq;
	-- if you are a outdoorsman (ranger) you can light the fire faster
	o.isOutdoorsMan = character:HasTrait("Outdoorsman");
	o.maxTime = o:getDuration();
	return o;
end
