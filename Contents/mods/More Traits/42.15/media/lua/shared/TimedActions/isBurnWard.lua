local function isBurnedAverse(character)
    if not character then return false end
    
    if not SandboxVars.MoreTraits or not SandboxVars.MoreTraits.BurnedFireAversion then
        return false
    end

    if character:hasTrait(ToadTraitsRegistries.burned) then
        if not isServer() then
            HaloTextHelper.addText(character, getText("UI_burnedstop"), "", HaloTextHelper.getColorRed())
        end
        return true
    end
    return false
end

local o_lit_new = ISLightFromLiterature.new
function ISLightFromLiterature:new(character, item, lighter, campfire, fuelAmt)
    local o = o_lit_new(self, character, item, lighter, campfire, fuelAmt)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end

local o_kindle_new = ISLightFromKindle.new
function ISLightFromKindle:new(character, plank, item, campfire)
    local o = o_kindle_new(self, character, plank, item, campfire)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end

local o_petrol_new = ISLightFromPetrol.new
function ISLightFromPetrol:new(character, campfire, lighter, petrol, maxTime)
    local o = o_petrol_new(self, character, campfire, lighter, petrol, maxTime)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end

local o_bbq_kindle_new = ISBBQLightFromKindle.new
function ISBBQLightFromKindle:new(character, plank, item, bbq)
    local o = o_bbq_kindle_new(self, character, plank, item, bbq)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end

local o_bbq_lit_new = ISBBQLightFromLiterature.new
function ISBBQLightFromLiterature:new(character, item, lighter, bbq)
    local o = o_bbq_lit_new(self, character, item, lighter, bbq)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end

local o_bbq_petrol_new = ISBBQLightFromPetrol.new
function ISBBQLightFromPetrol:new(character, bbq, lighter, petrol)
    local o = o_bbq_petrol_new(self, character, bbq, lighter, petrol)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end

local o_burnCorpse_new = ISBurnCorpseAction.new
function ISBurnCorpseAction:new(character, corpse, lighter, petrol)
    local o = o_burnCorpse_new(self, character, corpse, lighter, petrol)
    
    if isBurnedAverse(character) then
        function o:isValid()
            return false 
        end
    end

    return o
end