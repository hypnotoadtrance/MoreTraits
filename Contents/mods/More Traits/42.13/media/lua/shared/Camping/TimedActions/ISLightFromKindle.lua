require "TimedActions/ISBaseTimedAction"

ISLightFromKindle = ISBaseTimedAction:derive("ISLightFromKindle");

function ISLightFromKindle:isValid()
	if self.character:hasTrait(ToadTraitsRegistries.burned) and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end

	self.campfire:updateFromIsoObject()
	if isClient() and self.item and self.plank then
        return self.campfire:getObject() ~= nil
	else
        return self.campfire:getObject() ~= nil
	end
end

function ISLightFromKindle:waitToStart()
	self.character:faceThisObject(self.campfire:getObject())
	return self.character:shouldBeTurning()
end

function ISLightFromKindle:update()
    self.item:setJobDelta(self:getJobDelta());
    self.plank:setJobDelta(self:getJobDelta());
	self.character:faceThisObject(self.campfire:getObject())
	if not isClient() then
        self:updateKindling();
    end
end

function ISLightFromKindle:updateKindling()
	-- every tick we lower the endurance of the player, he also have a chance to light the fire or broke the kindle
	self.character:getStats():remove(CharacterStat.ENDURANCE, 0.0001 * getGameTime():getMultiplier());
	if not isServer() then
	    if self:getJobDelta() < 0.2 then return end
	else
	    if self.netAction:getProgress() < 0.2 then return end
	end
	local randNumber = 300;
	local randBrokeNumber = 300;
	if self.isOutdoorsMan then
		randNumber = 150;
		randBrokeNumber = 450;
	end
	if ZombRand(randNumber) == 0 then
        if isServer() then
            local campfire = SCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y, self.campfire.z)
            if campfire then
                campfire:lightFire()
            end
            self.netAction:forceComplete()
        else
            local campfire = SCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y, self.campfire.z)
            if campfire then
                campfire:lightFire()
            end
            self:forceComplete()
        end
	else
		-- fail ? Maybe the wood kit will broke...
		if ZombRand(randBrokeNumber) == 0 then
--~ 			self.character:Say("I broke my kindling...");
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

--			self.item = self.character:getInventory():FindAndReturn("WoodenStick");
		end
	end
end

function ISLightFromKindle:start()
    if isClient() and self.item and self.plank then
        self.item = self.character:getInventory():getItemById(self.item:getID())
        self.plank = self.character:getInventory():getItemById(self.plank:getID())
    end
	self.item:setJobType(campingText.lightCampfire);
	self.item:setJobDelta(0.0);
	self:setActionAnim("LightFire_KnotchedPlank")
    self:setOverrideHandModels("TreeBranchCrafting");
end

function ISLightFromKindle:stop()
	self:stopSound()
	if self.item then
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);

	ISBaseTimedAction.stop(self);
end

function ISLightFromKindle:perform()
	self:stopSound()
	if self.item and self.item:getContainer() then
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);
	end
	self.plank:setJobDelta(0.0);

	local campfire = CCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y, self.campfire.z)
    if campfire and not campfire.isLit then
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
            ISTimedActionQueue.add(ISLightFromKindle:new(self.character, self.plank, item, self.campfire));
        end
    end

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ISLightFromKindle:complete()

	return true
end

function ISLightFromKindle:animEvent(event, parameter)
	if isServer() then
		if event == 'KindlingUpdate' then
			self:updateKindling()
		end
    else
        if event == 'PlayNotchedPlankSound' then
            self.character:playSound(parameter or "MakeFireNotchedPlank")
        end
	end
end

function ISLightFromKindle:serverStart()
	emulateAnimEvent(self.netAction, 100, "KindlingUpdate", nil)
end

function ISLightFromKindle:getDuration()
    if self.character:isTimedActionInstant() then
        return 1;
    end
    return 1500;
end

function ISLightFromKindle:stopSound()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound)
	end
    self.character:getEmitter():stopOrTriggerSoundByName("MakeFireNotchedPlank")
end

function ISLightFromKindle:new(character, plank, item, campfire)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item;
    o.plank = plank;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.campfire = campfire;
	-- if you are a outdoorsman (ranger) you can light the fire faster
	o.isOutdoorsMan = character:hasTrait(CharacterTrait.OUTDOORSMAN);
	o.maxTime = o:getDuration();
    o.caloriesModifier = 8;
	return o;
end
