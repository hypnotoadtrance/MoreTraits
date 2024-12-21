
require "TimedActions/ISBaseTimedAction"

ISLightFromKindle = ISBaseTimedAction:derive("ISLightFromKindle");

function ISLightFromKindle:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	self.campfire:updateFromIsoObject()
	return self.campfire:getObject() ~= nil and self.item ~= nil and
			self.character:getInventory():contains(self.item) and
			self.character:getInventory():contains(self.plank) and
			not self.campfire.isLit and
			self.character:getStats():getEndurance() > 0
end

function ISLightFromKindle:waitToStart()
	self.character:faceThisObject(self.campfire:getObject())
	return self.character:shouldBeTurning()
end

function ISLightFromKindle:update()
	self.item:setJobDelta(self:getJobDelta());
	self.plank:setJobDelta(self:getJobDelta());
	self.character:faceThisObject(self.campfire:getObject())
	-- every tick we lower the endurance of the player, he also have a chance to light the fire or broke the kindle
	local endurance = self.character:getStats():getEndurance() - 0.0001 * getGameTime():getMultiplier()
	self.character:getStats():setEndurance(endurance);
	if self:getJobDelta() < 0.2 then return end
	local randNumber = 300;
	local randBrokeNumber = 300;
	if self.isOutdoorsMan then
		randNumber = 150;
		randBrokeNumber = 450;
	end
	if ZombRand(randNumber) == 0 then
		local cf = self.campfire
		local args = { x = cf.x, y = cf.y, z = cf.z }
		CCampfireSystem.instance:sendCommand(self.character, 'lightFire', args)
	else
		-- fail ? Maybe the wood kit will broke...
		if ZombRand(randBrokeNumber) == 0 then
--~ 			self.character:Say("I broke my kindling...");
			self.character:getInventory():Remove(self.item);
			self.character:getEmitter():playSound("BreakWoodItem")
--			self.item = self.character:getInventory():FindAndReturn("WoodenStick");
		end
	end
end

function ISLightFromKindle:start()
	self.item:setJobType(campingText.lightCampfire);
	self.item:setJobDelta(0.0);
	self.sound = self.character:playSound("CampfireLight")
end

function ISLightFromKindle:stop()
	self.character:stopOrTriggerSound(self.sound)
	if self.item then
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ISLightFromKindle:perform()
	self.character:stopOrTriggerSound(self.sound)
	if self.item then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISLightFromKindle:new(character, plank, stickOrBranch, campfire, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
    o.item = stickOrBranch;
    o.plank = plank;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.campfire = campfire;
	-- if you are a outdoorsman (ranger) you can light the fire faster
	o.isOutdoorsMan = character:HasTrait("Outdoorsman");
	o.maxTime = time;
    o.caloriesModifier = 8;
	return o;
end
