local function isBurnedActions()
    local fireActions = {
        ISLightFromKindle, ISLightFromLiterature, ISLightFromPetrol, 
        ISBBQLightFromKindle, ISBBQLightFromLiterature, ISBBQLightFromPetrol, 
        ISBurnCorpseAction,
    }

    local function isBurnedAverse(character)
        if not character then return false end
        -- Ensure ToadTraitsRegistries is loaded; if not, use the string "burned"
        local trait = (ToadTraitsRegistries and ToadTraitsRegistries.burned) or "burned"
        if character:hasTrait(trait) and SandboxVars.MoreTraits.BurnedFireAversion then
            return true
        end
        return false
    end

    for _, action in ipairs(fireActions) do
        -- Only patch if the action table actually exists
        if action and action.new then
            local original_new = action.new
            
            action.new = function(self, character, ...)
                local o = original_new(self, character, ...)
                if not o then return nil end -- Safety for failed constructors
                
                o.sound = 0
                
                local original_start = o.start
                o.start = function(instance)
                    if isBurnedAverse(instance.character) then
                        HaloTextHelper.addText(instance.character, getText("UI_burnedstop"), "", HaloTextHelper.getColorRed())
                        instance:forceStop()
                        return
                    end

                    if original_start then
                        original_start(instance)
                    end
                end
                
                return o
            end
        end
    end
end

Events.OnGameStart.Add(isBurnedActions)