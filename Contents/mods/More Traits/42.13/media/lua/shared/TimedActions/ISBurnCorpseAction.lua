require "TimedActions/ISBaseTimedAction"

ISBurnCorpseAction = ISBaseTimedAction:derive("ISBurnCorpseAction");

function ISBurnCorpseAction:isValid()
    if self.character:hasTrait(ToadTraitsRegistries.burned) and self.character:getModData().MTModVersion >= 3 and SandboxVars.MoreTraits.BurnedFireAversion == true then
        HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
        return false
    end

    if self.corpse:getStaticMovingObjectIndex() < 0 or
            not self.lighter or not self.petrol or
            not self.character:isPrimaryHandItem(self.lighter) or
            not self.character:isSecondaryHandItem(self.petrol) or
            self.petrol:getFluidContainer():getAmount() < ZomboidGlobals.BurnCorpsePetrolAmount then
        return false
    end
    if isClient() then
        return self.character:getInventory():containsID(self.petrol:getID()) and self.character:getInventory():containsID(self.lighter:getID());
    else
        return self.character:getInventory():contains(self.petrol) and self.character:getInventory():contains(self.lighter);
    end
end

function ISBurnCorpseAction:update()
    self.lighter:setJobDelta(self:getJobDelta());
    self.petrol:setJobDelta(self:getJobDelta());
    
    self.character:faceThisObject(self.corpse);
end

function ISBurnCorpseAction:start()
    if isClient() and self.lighter and self.petrol then
        self.lighter = self.character:getInventory():getItemById(self.lighter:getID())
        self.petrol = self.character:getInventory():getItemById(self.petrol:getID())
    end
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

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function ISBurnCorpseAction:complete()
    self.character:burnCorpse(self.corpse);
    self.petrol:getFluidContainer():adjustAmount(self.petrol:getFluidContainer():getAmount() - ZomboidGlobals.BurnCorpsePetrolAmount);
    self.lighter:UseAndSync();

    return true;
end

function ISBurnCorpseAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 110
end

function ISBurnCorpseAction:new (character, corpse, lighter, petrol)
    local o = ISBaseTimedAction.new(self, character)
    o.corpse = corpse;
    o.maxTime = o:getDuration();
    o.lighter = lighter
    o.petrol = petrol
    return o
end
