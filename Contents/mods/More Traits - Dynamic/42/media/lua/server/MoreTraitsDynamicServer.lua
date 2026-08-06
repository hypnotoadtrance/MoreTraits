local function getPlayers()
    local players = {}
    local online = getOnlinePlayers and getOnlinePlayers() or nil
    if not online then
        return players
    end

    for i = 0, online:size() - 1 do
        players[#players + 1] = online:get(i)
    end
    return players
end

local function ensureData(player)
    local md = player:getModData()
    md.MoreTraitsDynamic = md.MoreTraitsDynamic or {}
    return md.MoreTraitsDynamic
end


local function evaluateLevelTraits(player, vars)
    if not player or player:isDead() or not vars then return end

    if vars.PackMouseDynamic == true
        and player:hasTrait(ToadTraitsRegistries.packmouse)
        and player:getPerkLevel(Perks.Strength) >= vars.PackMouseDynamicSkill then
        player:getTraits():remove(ToadTraitsRegistries.packmouse)
    end

    if vars.PackMuleDynamic == true
        and not player:hasTrait(ToadTraitsRegistries.packmule)
        and player:getPerkLevel(Perks.Strength) >= vars.PackMuleDynamicSkill then
        player:getTraits():add(ToadTraitsRegistries.packmule)
    end

    if vars.HardyDynamic == true
        and not player:hasTrait(ToadTraitsRegistries.hardy)
        and player:getPerkLevel(Perks.Fitness) >= vars.HardyDynamicSkill then
        player:getTraits():add(ToadTraitsRegistries.hardy)
    end
end

local function onPanicMinute(player)
    if not player or player:isDead() then return end
    local vars = SandboxVars and SandboxVars.MoreTraitsDynamic or nil
    if not vars then return end
    local md = ensureData(player)
    evaluateLevelTraits(player, vars)
    md.FiftyPlusStressAndPanicTime = md.FiftyPlusStressAndPanicTime or 0

    if player:getStats():get(CharacterStat.STRESS) >= 0.5 and player:getStats():get(CharacterStat.PANIC) >= 50 then
        md.FiftyPlusStressAndPanicTime = md.FiftyPlusStressAndPanicTime + 1
    end

    if vars.ParanoiaDynamic == true
        and player:hasTrait(ToadTraitsRegistries.paranoia)
        and md.FiftyPlusStressAndPanicTime >= vars.ParanoiaDynamicHoursLose * 60 then
        md.FiftyPlusStressAndPanicTime = 0
        player:getTraits():remove(ToadTraitsRegistries.paranoia)
    end
end

local function onInjuryTenMinutes(player)
    if not player or player:isDead() then return end
    local vars = SandboxVars and SandboxVars.MoreTraitsDynamic or nil
    if not vars then return end
    local md = ensureData(player)
    md.totalInfectionTime = md.totalInfectionTime or 0

    local hasInfection = false
    for n = 0, player:getBodyDamage():getBodyParts():size() - 1 do
        if player:getBodyDamage():getBodyParts():get(n):getWoundInfectionLevel() ~= 0 then
            hasInfection = true
            break
        end
    end

    if hasInfection then
        md.totalInfectionTime = md.totalInfectionTime + 1 / 6
    end

    if vars.ImmunocompromisedDynamic == true
        and player:hasTrait(ToadTraitsRegistries.immunocompromised)
        and not player:hasTrait(ToadTraitsRegistries.superimmune)
        and md.totalInfectionTime >= vars.ImmunocompromisedDynamicInfectionTime then
        player:getTraits():remove(ToadTraitsRegistries.immunocompromised)
    end

    if vars.SuperImmuneDynamic == true
        and not player:hasTrait(ToadTraitsRegistries.superimmune)
        and not player:hasTrait(ToadTraitsRegistries.immunocompromised)
        and md.totalInfectionTime >= vars.SuperImmuneDynamicInfectionTime then
        player:getTraits():add(ToadTraitsRegistries.superimmune)
    end
end

local function onWeightHour(player)
    if not player or player:isDead() then return end
    local vars = SandboxVars and SandboxVars.MoreTraitsDynamic or nil
    if not vars or vars.IdealWeightDynamic ~= true then return end

    local md = ensureData(player)
    md.WeightMaintainedHours = md.WeightMaintainedHours or 0
    md.WeightNotMaintainedHours = md.WeightNotMaintainedHours or 0

    local weight = player:getNutrition():getWeight()
    if not player:hasTrait(ToadTraitsRegistries.idealweight) then
        if weight >= 78 and weight <= 82 then
            md.WeightMaintainedHours = md.WeightMaintainedHours + 1
        else
            md.WeightNotMaintainedHours = md.WeightNotMaintainedHours + 1
            if md.WeightNotMaintainedHours >= vars.IdealWeightDynamicObtainGracePeriod then
                md.WeightMaintainedHours = 0
                md.WeightNotMaintainedHours = 0
            end
        end

        if md.WeightMaintainedHours >= vars.IdealWeightDynamicTargetDaysToObtain * 24 then
            player:getTraits():add(ToadTraitsRegistries.idealweight)
            md.WeightMaintainedHours = 0
            md.WeightNotMaintainedHours = 0
        end
    else
        if weight >= 78 and weight <= 82 then
            md.WeightMaintainedHours = md.WeightMaintainedHours + 0.0834 * vars.IdealWeightDynamicLoseGracePeriodMultiplier
            if md.WeightMaintainedHours >= vars.IdealWeightDynamicLoseGracePeriodCap then
                md.WeightMaintainedHours = vars.IdealWeightDynamicLoseGracePeriodCap
            end
        elseif weight <= 75 or weight >= 85 then
            md.WeightMaintainedHours = md.WeightMaintainedHours - 1
            if md.WeightMaintainedHours <= 0 then
                player:getTraits():remove(ToadTraitsRegistries.idealweight)
                md.WeightMaintainedHours = 0
                md.WeightNotMaintainedHours = 0
            end
        end
    end
end

local function onLevelPerk(player, perk)
    if not player or not perk then return end
    local vars = SandboxVars and SandboxVars.MoreTraitsDynamic or nil
    if not vars then return end
    evaluateLevelTraits(player, vars)
end

local function forEachPlayer(fn)
    for _, p in ipairs(getPlayers()) do
        fn(p)
    end
end

Events.EveryOneMinute.Add(function() forEachPlayer(onPanicMinute) end)
Events.EveryTenMinutes.Add(function() forEachPlayer(onInjuryTenMinutes) end)
Events.EveryHours.Add(function() forEachPlayer(onWeightHour) end)
Events.LevelPerk.Add(onLevelPerk)
