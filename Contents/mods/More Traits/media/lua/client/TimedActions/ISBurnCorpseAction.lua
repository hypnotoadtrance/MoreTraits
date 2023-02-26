require "TimedActions/ISBaseTimedAction"

ISBurnCorpseAction = ISBaseTimedAction:derive("ISBurnCorpseAction");

function ISBurnCorpseAction:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return false
	end
    if self.corpse:getStaticMovingObjectIndex() < 0 then
        return false
    end
    if not self.lighter then
        self.lighter = self.character:getPrimaryHandItem();
    end
    if not self.petrol then
        self.petrol = self.character:getSecondaryHandItem();
    end
    return self.character:getInventory():contains(self.petrol) and self.character:getInventory():contains(self.lighter);
end

function ISBurnCorpseAction:update()
    self.lighter:setJobDelta(self:getJobDelta());
    self.petrol:setJobDelta(self:getJobDelta());
    
    self.character:faceThisObject(self.corpse);
end

function ISBurnCorpseAction:start()
    self.lighter:setJobType(getText("IGUI_JobType_Burn"));
    self.lighter:setJobDelta(0.0);
    self.petrol:setJobType(getText("IGUI_JobType_Burn"));
    self.petrol:setJobDelta(0.0);
    
    self:setActionAnim(CharacterActionAnims.Pour);
    -- Don't call setOverrideHandModels() with self.petrol, the right-hand mask
    -- will bork the animation.
    self:setOverrideHandModels(self.petrol:getStaticModel(), nil);
end

function ISBurnCorpseAction:stop()
    ISBaseTimedAction.stop(self);
    if self.lighter then
        self.lighter:setJobDelta(0.0);
    end
    if self.petrol then
        self.petrol:setJobDelta(0.0);
    end
end

function ISBurnCorpseAction:perform()
    self.lighter:setJobDelta(0.0);
    self.petrol:setJobDelta(0.0);

    --IsoFireManager.StartFire(getCell(), self.corpse:getSquare(), true, 100, 700);
    self.character:burnCorpse(self.corpse);
--    getCell():getObjectList():add(self.corpse);

    self.petrol:Use();
    self.lighter:Use();

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ISBurnCorpseAction:new (character, corpse, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.corpse = corpse;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    if character:isTimedActionInstant() then
        o.maxTime = 1;
    end
    return o
end
