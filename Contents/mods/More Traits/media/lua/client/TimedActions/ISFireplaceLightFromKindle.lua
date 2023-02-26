require "TimedActions/ISBaseTimedAction"

ISFireplaceLightFromKindle = ISBaseTimedAction:derive("ISFireplaceLightFromKindle");

function ISFireplaceLightFromKindle:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	return self.fireplace:getObjectIndex() ~= -1 and self.item ~= nil and
			self.character:getInventory():contains(self.item) and
			self.character:getInventory():contains(self.plank) and
			not self.fireplace:isLit() and
			self.character:getStats():getEndurance() > 0
end

function ISFireplaceLightFromKindle:waitToStart()
	self.character:faceThisObject(self.fireplace)
	return self.character:shouldBeTurning()
end

function ISFireplaceLightFromKindle:update()
	self.character:faceThisObject(self.fireplace)
	self.item:setJobDelta(self:getJobDelta());
	self.plank:setJobDelta(self:getJobDelta());
	-- every tick we lower the endurance of the player, he also have a chance to light the fire or broke the kindle
	self.character:getStats():setEndurance(self.character:getStats():getEndurance() - 0.0001 * getGameTime():getMultiplier());
	if self:getJobDelta() < 0.2 then return end
	local randNumber = 300;
	local randBrokeNumber = 300;
	if self.isOutdoorsMan then
		randNumber = 150;
		randBrokeNumber = 450;
	end
	if ZombRand(randNumber) == 0 then
		local fp = self.fireplace
		local args = { x = fp:getX(), y = fp:getY(), z = fp:getZ() }
		sendClientCommand(self.character, 'fireplace', 'light', args)
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

function ISFireplaceLightFromKindle:start()
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
	if self.item then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISFireplaceLightFromKindle:new(character, plank, stickOrBranch, fireplace, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.item = stickOrBranch;
	o.plank = plank;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.fireplace = fireplace;
	-- if you are a outdoorsman (ranger) you can light the fire faster
	o.isOutdoorsMan = character:HasTrait("Outdoorsman");
	o.maxTime = time;
	return o;
end
