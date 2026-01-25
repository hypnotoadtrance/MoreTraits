local dynamicDefaults = {
    TotalDamageDone = 0,
    AllowLeadFootCount = false,
    LeadFootCount = 0,
    InjuredTime = 0,
    totalInfectionTime = 0,
    WeightMaintainedHours = 0,
    WeightNotMaintainedHours = 0,
    FiftyPlusStressAndPanicTime = 0,
}

local function InitMoreTraitsDynamic(player, playerdata)
    playerdata.MoreTraitsDynamic = playerdata.MoreTraitsDynamic or {}
    local MTD = playerdata.MoreTraitsDynamic
    
    for key, defaultValue in pairs(dynamicDefaults) do
        if MTD[key] == nil then
            MTD[key] = defaultValue
        end
    end
end

function MTDLevelPerkMain(player, perk)
	if not player then return end
	MTDTraitsGainsByLevel(player, perk);
end

-- TODO MP Support
function MTDapplyXPBoost(player, perk, boostLevel)
    local currentXPBoost = player:getXp():getPerkBoost(perk)
    local newBoost = math.min(currentXPBoost + boostLevel, 3)

    if isClient() and (currentXPBoost + boostLevel > 3) then
        sendClientCommand("MoreTraitsDynamic", "setXpBoosts", { perk = perk, boostAmount = newBoost })
    else
        player:getXp():setPerkBoost(perk, newBoost)
    end
end

function MTDEveryOneMinuteMain()
	MTDTraitGainsByPanic();
end

function MTDEveryTenMinutesMain()
	MTDTraitGainsByInjuries();
end

function MTDEveryHoursMain()
	MTDTraitGainsByWeight();
end

function MTDOnWeaponHitCharacterMain(wielder, target, weapon, damage)
    if not wielder and not target:isZombie() then return end

	-- Leadfoot
    if SandboxVars.MoreTraitsDynamic.LeadFootDynamic and not wielder:hasTrait(ToadTraitsRegistries.leadfoot) then
        MTDLeadFootToggle(wielder, target, weapon);
    end
    -- Mundane
    if SandboxVars.MoreTraitsDynamic.MundaneDynamic and wielder:hasTrait(ToadTraitsRegistries.mundane) then
        MTDMundane(wielder, damage);
    end
end

function MTDKillsMainExtended(zombie)
    local player = getPlayer()
    if not player then return end

	if SandboxVars.MoreTraitsDynamic.LeadFootDynamic and not player:hasTrait(ToadTraitsRegistries.leadfoot) then
		MTDLeadFoot(zombie);
	end

	MTDTraitsGainsByLevel(player, "KillCount");
end

function MTDKillsMain(zombie)
	MTDLeadFoot(zombie);
end

function MTDMundane(wielder, damage)
    local MTD = wielder:getModData().MoreTraitsDynamic
	if not MTD then return end
    
    MTD.TotalDamageDone = MTD.TotalDamageDone + damage

    local threshold = SandboxVars.MoreTraitsDynamic.MundaneDynamicDamage
    if getGameTime():getModData().MTModVersion == 1 then
        threshold = math.floor(threshold / 10)
    end

    if MTD.TotalDamageDone >= threshold then
        if isClient() then
            sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "mundane" })
        else
            wielder:getCharacterTraits():remove(ToadTraitsRegistries.mundane)
        end
        HaloTextHelper.addTextWithArrow(wielder, getText("UI_trait_mundane"), false, HaloTextHelper.getColorGreen())
    end
end

function MTDLeadFootToggle(wielder, target, weapon)
	local MTD = wielder:getModData().MoreTraitsDynamic
	if not MTD then return end

    if (weapon:getType() == "BareHands") and target:isProne() then
        MTD.AllowLeadFootCount = true
    else
        MTD.AllowLeadFootCount = false
    end
end

local indefatigablePerks = {
    Perks.Strength, Perks.Fitness, Perks.Sprinting, Perks.Lightfoot, 
    Perks.Nimble, Perks.Sneak, Perks.Axe, Perks.Blunt, 
    Perks.SmallBlunt, Perks.LongBlade, Perks.SmallBlade, Perks.Spear
}

function MTDTraitsGainsByLevel(player, perk)
    local playerdata = player:getModData()
    if not playerdata then return end

    local traits = player:getCharacterTraits()
    local vars = SandboxVars.MoreTraitsDynamic
    local killCountisOn = getActivatedMods():contains("KillCount")
    local isInit = (perk == "characterInitialization")
    local lvlStrength = player:getPerkLevel(Perks.Strength)
    local lvlFitness = player:getPerkLevel(Perks.Fitness)
    local lvlSprint = player:getPerkLevel(Perks.Sprinting)
    local lvlLightFoot = player:getPerkLevel(Perks.Lightfoot)
    local lvlNimble = player:getPerkLevel(Perks.Nimble)
    local lvlSneak = player:getPerkLevel(Perks.Sneak)
    local lvlAxe = player:getPerkLevel(Perks.Axe)
    local lvlBlunt = player:getPerkLevel(Perks.Blunt)
    local lvlSmallBlunt = player:getPerkLevel(Perks.SmallBlunt)
    local lvlLongBlade = player:getPerkLevel(Perks.LongBlade)
    local lvlSmallBlade = player:getPerkLevel(Perks.SmallBlade)
    local lvlSpear = player:getPerkLevel(Perks.Spear)
    local lvlAim = player:getPerkLevel(Perks.Aiming)
    local lvlReload = player:getPerkLevel(Perks.Reloading)
    local lvlMaintenance = player:getPerkLevel(Perks.Maintenance)
    local lvlCook = player:getPerkLevel(Perks.Cooking)
    local lvlWood = player:getPerkLevel(Perks.Woodwork)
    local lvlElec = player:getPerkLevel(Perks.Electricity)
    local lvlMetal = player:getPerkLevel(Perks.MetalWelding)
    local lvlMech = player:getPerkLevel(Perks.Mechanics)
    local lvlTailor = player:getPerkLevel(Perks.Tailoring)
    local lvlForage = player:getPerkLevel(Perks.PlantScavenging)
    local lvlDoc = player:getPerkLevel(Perks.Doctor)
    local lvlFarm = player:getPerkLevel(Perks.Farming)
    local lvlScav = player:getPerkLevel(Perks.Scavenging)
    local lvlFish = player:getPerkLevel(Perks.Fishing)
    local lvlTrap = player:getPerkLevel(Perks.Trapping)

    local physicalSum = lvlStrength + lvlFitness
    local combatSum = lvlAxe + lvlBlunt + lvlSmallBlunt + lvlLongBlade + lvlSmallBlade + lvlSpear
    local agilitySum = lvlSprint + lvlLightFoot + lvlNimble + lvlSneak
    local survivalSum = physicalSum + agilitySum + combatSum

    -- Helper for Kill Categories
    local function getKills(category)
        if not killCountisOn or not playerdata.KillCount or not playerdata.KillCount.WeaponCategory then return 0 end
        local cat = playerdata.KillCount.WeaponCategory[category]
        return cat and cat.count or 0
    end

    ---------------------------------------------------------------------------
    -- STRENGTH & FITNESS
    ---------------------------------------------------------------------------
    if isInit or perk == Perks.Strength or perk == Perks.Fitness then
        -- Pack Mouse (Remove)
        if vars.PackMouseDynamic and player:hasTrait(ToadTraitsRegistries.packmouse) and lvlStrength >= vars.PackMouseDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "packmouse" })
            else
                traits:remove(ToadTraitsRegistries.packmouse)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_packmouse"), false, HaloTextHelper.getColorGreen())
        end
        -- Pack Mule (Add)
        if vars.PackMuleDynamic and not player:hasTrait(ToadTraitsRegistries.packmule) and lvlStrength >= vars.PackMuleDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "packmule" })
            else
                traits:add(ToadTraitsRegistries.packmule)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_packmule"), true, HaloTextHelper.getColorGreen())
        end
        -- Gym-Goer
        if vars.GymGoerDynamic and not player:hasTrait(ToadTraitsRegistries.gymgoer) and physicalSum >= vars.GymGoerDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "gymgoer" })
            else
                traits:add(ToadTraitsRegistries.gymgoer)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gymgoer"), true, HaloTextHelper.getColorGreen())
        end
        -- Second Wind
        if vars.SecondWindDynamic and not player:hasTrait(ToadTraitsRegistries.secondwind) and physicalSum >= vars.SecondWindDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "secondwind" })
            else
                traits:add(ToadTraitsRegistries.secondwind)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_secondwind"), true, HaloTextHelper.getColorGreen())
        end
        -- Hardy
        if vars.HardyDynamic and not player:hasTrait(ToadTraitsRegistries.hardy) and lvlFitness >= vars.HardyDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "hardy" })
            else
                traits:add(ToadTraitsRegistries.hardy)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardy"), true, HaloTextHelper.getColorGreen())
        end
    end

    ---------------------------------------------------------------------------
    -- INDEFATIGABLE
    ---------------------------------------------------------------------------
    local isRelevantForIndefatigable = isInit
    if not isRelevantForIndefatigable then
        for _, pID in ipairs(indefatigablePerks) do
            if perk == pID then
                isRelevantForIndefatigable = true
                break
            end
        end
    end
    if isRelevantForIndefatigable then
        if vars.IndefatigableDynamic and not player:hasTrait(ToadTraitsRegistries.indefatigable) then
            local totalLevel = 0
            for _, pID in ipairs(indefatigablePerks) do
                totalLevel = totalLevel + player:getPerkLevel(pID)
            end

            if totalLevel >= vars.IndefatigableDynamicSkill then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "indefatigable" })
                else
                    traits:add(ToadTraitsRegistries.indefatigable)
                end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen())
            end
        end
    end

    ---------------------------------------------------------------------------
    -- AGILITY & MOVEMENT
    ---------------------------------------------------------------------------
    if isInit or perk == Perks.Fitness or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak then
        -- Noodle Legs
        local evasiveSum = lvlFitness + agilitySum
        if vars.NoodleLegsDynamic and player:hasTrait(ToadTraitsRegistries.noodlelegs) and evasiveSum >= vars.NoodleLegsDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "noodlelegs" })
            else
                traits:remove(ToadTraitsRegistries.noodlelegs)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_noodlelegs"), false, HaloTextHelper.getColorGreen())
        end
        -- Evasive
        if vars.EvasiveDynamic and not player:hasTrait(ToadTraitsRegistries.evasive) and not player:hasTrait(ToadTraitsRegistries.noodlelegs) and evasiveSum >= vars.EvasiveDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "evasive" })
            else
                traits:add(ToadTraitsRegistries.evasive)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_evasive"), true, HaloTextHelper.getColorGreen())
        end
        -- Slowpoke
        if vars.SlowpokeDynamic and player:hasTrait(ToadTraitsRegistries.gimp) and agilitySum >= vars.SlowpokeDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "gimp" })
            else
                traits:remove(ToadTraitsRegistries.gimp)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slowpoke"), false, HaloTextHelper.getColorGreen())
        end
        -- Fast
        if vars.FastDynamic and not player:hasTrait(ToadTraitsRegistries.fast) and agilitySum >= vars.FastDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "fast" })
            else
                traits:add(ToadTraitsRegistries.fast)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fast"), true, HaloTextHelper.getColorGreen())
        end
        -- Olympian
        if vars.OlympianDynamic and not player:hasTrait(ToadTraitsRegistries.olympian) and lvlSprint >= vars.OlympianDynamicSkillSprinting and lvlFitness >= vars.OlympianDynamicSkillFitness then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "olympian" })
            else
                traits:add(ToadTraitsRegistries.olympian)
            end
			MTDapplyXPBoost(player, Perks.Sprinting, 1);
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_olympian"), true, HaloTextHelper.getColorGreen());
        end
        -- Swift
        if vars.SwiftDynamic and not player:hasTrait(ToadTraitsRegistries.swift) and lvlLightFoot >= vars.SwiftDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "swift" })
            else
                traits:add(ToadTraitsRegistries.swift)
            end
            MTDapplyXPBoost(player, Perks.Lightfoot, 1);
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_swift"), true, HaloTextHelper.getColorGreen())
        end
        -- Flexible
        if vars.FlexibleDynamic and not player:hasTrait(ToadTraitsRegistries.flexible) and lvlNimble >= vars.FlexibleDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "flexible" })
            else
                traits:add(ToadTraitsRegistries.flexible)
            end
            MTDapplyXPBoost(player, Perks.Nimble, 1);
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_flexible"), true, HaloTextHelper.getColorGreen())
        end
        -- Well-Fitted
        if vars.WellFittedDynamic and not player:hasTrait(ToadTraitsRegistries.fitted) and lvlNimble >= vars.WellFittedDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "fitted" })
            else
                traits:add(ToadTraitsRegistries.fitted)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fitted"), true, HaloTextHelper.getColorGreen())
        end
        -- Quiet
        if vars.QuietDynamic and not player:hasTrait(ToadTraitsRegistries.quiet) and lvlSneak >= vars.QuietDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "quiet" })
            else
                traits:add(ToadTraitsRegistries.quiet)
            end
            MTDapplyXPBoost(player, Perks.Sneak, 1);
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_quiet"), true, HaloTextHelper.getColorGreen())
        end
    end

    ---------------------------------------------------------------------------
    -- BLUNT + BLADES
    ---------------------------------------------------------------------------
    if isInit or perk == "KillCount" or perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear or perk == Perks.Fitness or perk == Perks.Strength or perk == Perks.Woodwork then
        -- Shared Blunt Data
        local bluntSkillSum = lvlBlunt + lvlSmallBlunt
        local bluntKills = 0
        if killCountisOn then
            bluntKills = getKills("Blunt") + getKills("SmallBlunt")
        end
        -- Thuggish
        if vars.ThuggishDynamic and not player:hasTrait(ToadTraitsRegistries.blunttwirl) then
            local canGet = bluntSkillSum >= vars.ThuggishDynamicSkill
            if canGet and killCountisOn then
                canGet = bluntKills >= vars.ThuggishDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "blunttwirl" })
                else
                    traits:add(ToadTraitsRegistries.blunttwirl)
                end
                MTDapplyXPBoost(player, Perks.Blunt, 1)
                MTDapplyXPBoost(player, Perks.SmallBlunt, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_blunttwirl"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Prowess: Blunt
        if vars.ProwessBluntDynamic and not player:hasTrait(ToadTraitsRegistries.problunt) then
            local canGet = bluntSkillSum >= vars.ProwessBluntDynamicSkill
            if canGet and killCountisOn then
                canGet = bluntKills >= vars.ProwessBluntDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "problunt" })
                else
                    traits:add(ToadTraitsRegistries.problunt)
                end
                MTDapplyXPBoost(player, Perks.Blunt, 1)
                MTDapplyXPBoost(player, Perks.SmallBlunt, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_problunt"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Gordanite
        if vars.GordaniteDynamic and not player:hasTrait(ToadTraitsRegistries.gordanite) then
            local canGet = lvlBlunt >= vars.GordaniteDynamicSkill
            if canGet and killCountisOn then
                canGet = getKills("Blunt") >= vars.GordaniteDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "gordanite" })
                else
                    traits:add(ToadTraitsRegistries.gordanite)
                end
                MTDapplyXPBoost(player, Perks.Blunt, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gordanite"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Grunt Worker
        if vars.GruntWorkerDynamic and not player:hasTrait(ToadTraitsRegistries.grunt) then
            local canGet = (lvlSmallBlunt >= vars.GruntWorkerDynamicSmallBlunt) and (lvlWood >= vars.GruntWorkerDynamicWoodwork)
            if canGet and killCountisOn then
                canGet = getKills("SmallBlunt") >= vars.GruntWorkerDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "grunt" })
                else
                    traits:add(ToadTraitsRegistries.grunt)
                end
                MTDapplyXPBoost(player, Perks.SmallBlunt, 1)
                MTDapplyXPBoost(player, Perks.Woodwork, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_grunt"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Tavern Brawler
        if vars.TavernBrawlerDynamic and not player:hasTrait(ToadTraitsRegistries.tavernbrawler) and combatSum >= vars.TavernBrawlerDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "tavernbrawler" })
            else
                traits:add(ToadTraitsRegistries.tavernbrawler)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tavernbrawler"), true, HaloTextHelper.getColorGreen())
        end
        -- Martial Artist
        if vars.MartialArtistDynamic and not player:hasTrait(ToadTraitsRegistries.martial) then
            if lvlSmallBlunt >= vars.MartialArtistDynamicSmallBlunt and lvlFitness >= vars.MartialArtistDynamicFitness then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "martial" })
                else
                    traits:add(ToadTraitsRegistries.martial)
                end
                MTDapplyXPBoost(player, Perks.SmallBlunt, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_martial"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Bouncer
        if vars.BouncerDynamic and not player:hasTrait(ToadTraitsRegistries.bouncer) then
            if lvlSmallBlunt >= vars.BouncerDynamicSmallBlunt and lvlStrength >= vars.BouncerDynamicStrength then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "bouncer" })
                else
                    traits:add(ToadTraitsRegistries.bouncer)
                end
                MTDapplyXPBoost(player, Perks.SmallBlunt, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bouncer"), true, HaloTextHelper.getColorGreen())
            end
        end
        ---------------------------------------------------------------------------
        -- BLADES
        ---------------------------------------------------------------------------
        -- 1. Shared Blade Data
        local bladeSkillSum = lvlLongBlade + lvlSmallBlade
        local bladeKills = 0
        if killCountisOn then
            bladeKills = getKills("LongBlade") + getKills("SmallBlade")
        end
        -- Practiced Swordsman
        if vars.PracticedSwordsmanDynamic and not player:hasTrait(ToadTraitsRegistries.bladetwirl) then
            local canGet = bladeSkillSum >= vars.PracticedSwordsmanDynamicSkill
            if canGet and killCountisOn then
                canGet = bladeKills >= vars.PracticedSwordsmanDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "bladetwirl" })
                else
                    traits:add(ToadTraitsRegistries.bladetwirl)
                end
                MTDapplyXPBoost(player, Perks.LongBlade, 1)
                MTDapplyXPBoost(player, Perks.SmallBlade, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bladetwirl"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Prowess: Blade
        if vars.ProwessBladeDynamic and not player:hasTrait(ToadTraitsRegistries.problade) then
            local bladeProwessSkill = lvlAxe + lvlLongBlade + lvlSmallBlade
            local canGet = bladeProwessSkill >= vars.ProwessBladeDynamicSkill
            if canGet and killCountisOn then
                local totalBladeKills = bladeKills + getKills("Axe")
                canGet = totalBladeKills >= vars.ProwessBladeDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "problade" })
                else
                    traits:add(ToadTraitsRegistries.problade)
                end
                MTDapplyXPBoost(player, Perks.Axe, 1)
                MTDapplyXPBoost(player, Perks.LongBlade, 1)
                MTDapplyXPBoost(player, Perks.SmallBlade, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_problade"), true, HaloTextHelper.getColorGreen())
            end
        end
    end

    ---------------------------------------------------------------------------
    -- SURVIVAL & SPEARS
    ---------------------------------------------------------------------------
    if isInit or perk == "KillCount" or perk == Perks.Spear or perk == Perks.Fishing or perk == Perks.Trapping or perk == Perks.PlantScavenging then
        -- Wildsman
        if vars.WildsmanDynamic and not player:hasTrait(ToadTraitsRegistries.wildsman) then
            local skillSum = lvlFish + lvlTrap + lvlForage
            local canGet = (lvlSpear >= 4 and lvlFish >= 1 and lvlTrap >= 1 and lvlForage >= 1 and skillSum >= vars.WildsmanDynamicSkill)
            if canGet and killCountisOn then
                canGet = getKills("Spear") >= vars.WildsmanDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "wildsman" })
                else
                    traits:add(ToadTraitsRegistries.wildsman)
                end
                MTDapplyXPBoost(player, Perks.Spear, 1)
                MTDapplyXPBoost(player, Perks.Fishing, 1)
                MTDapplyXPBoost(player, Perks.Trapping, 1)
                MTDapplyXPBoost(player, Perks.PlantScavenging, 1)
                
                local recipes = player:getKnownRecipes()
                local wildRecipes = {"Make Stick Trap", "Make Snare Trap", "Make Fishing Rod", "Fix Fishing Rod"}
                for _, recipe in ipairs(wildRecipes) do
                    if not recipes:contains(recipe) then recipes:add(recipe) end
                end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_wildsman"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Prowess: Spear
        if vars.ProwessSpearDynamic and not player:hasTrait(ToadTraitsRegistries.prospear) then
            local canGet = lvlSpear >= vars.ProwessSpearDynamicSkill
            if canGet and killCountisOn then
                canGet = getKills("Spear") >= vars.ProwessSpearDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "prospear" })
                else
                    traits:add(ToadTraitsRegistries.prospear)
                end
                MTDapplyXPBoost(player, Perks.Spear, 2)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_prospear"), true, HaloTextHelper.getColorGreen())
            end
        end
    end

    ---------------------------------------------------------------------------
    -- CRAFTING & UTILITY
    ---------------------------------------------------------------------------
    if isInit or perk == Perks.Woodwork or perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.Doctor 
    or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring or perk == Perks.Maintenance then
        
        local craftingSum = lvlWood + lvlCook + lvlFarm + lvlDoc + lvlElec + lvlMetal + lvlMech + lvlTailor

        -- Scrapper
        if vars.ScrapperDynamic and not player:hasTrait(ToadTraitsRegistries.scrapper) then
            if lvlMaintenance >= vars.ScrapperDynamicMaintenance and lvlMetal >= vars.ScrapperDynamicMetalWelding then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "scrapper" })
                else
                    traits:add(ToadTraitsRegistries.scrapper)
                end
                MTDapplyXPBoost(player, Perks.Maintenance, 1)
                MTDapplyXPBoost(player, Perks.MetalWelding, 1)
                local recipes = player:getKnownRecipes()
                if not recipes:contains("Make Metal Pipe") then recipes:add("Make Metal Pipe") end
                if not recipes:contains("Make Metal Sheet") then recipes:add("Make Metal Sheet") end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrapper"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Slow Worker
        if vars.SlowWorkerDynamic and player:hasTrait(ToadTraitsRegistries.slowworker) and craftingSum >= vars.SlowWorkerDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "slowworker" })
            else
                traits:remove(ToadTraitsRegistries.slowworker)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slowworker"), false, HaloTextHelper.getColorGreen())
        end
        -- Fast Worker
        if vars.FastWorkerDynamic and not player:hasTrait(ToadTraitsRegistries.quickworker) and craftingSum >= vars.FastWorkerDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "quickworker" })
            else
                traits:add(ToadTraitsRegistries.quickworker)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_quickworker"), true, HaloTextHelper.getColorGreen())
        end
        -- Natural Eater
        if vars.NaturalEaterDynamic and not player:hasTrait(ToadTraitsRegistries.natural) then
            if lvlCook >= vars.NaturalEaterDynamicCooking and lvlForage >= vars.NaturalEaterDynamicForaging then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "natural" })
                else
                    traits:add(ToadTraitsRegistries.natural)
                end
                MTDapplyXPBoost(player, Perks.Cooking, 1)
                MTDapplyXPBoost(player, Perks.PlantScavenging, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_natural"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Ascetic
        if vars.AsceticDynamic and player:hasTrait(ToadTraitsRegistries.ascetic) and player:getPerkLevel(Perks.Cooking) >= vars.AsceticDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "ascetic" })
            else
                traits:remove(ToadTraitsRegistries.ascetic)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ascetic"), false, HaloTextHelper.getColorGreen());
        end
        -- Gourmand
        if vars.GourmandDynamic and not player:hasTrait(ToadTraitsRegistries.gourmand) and player:getPerkLevel(Perks.Cooking) >= vars.GourmandDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "gourmand" })
            else
                traits:add(ToadTraitsRegistries.gourmand)
            end
            MTDapplyXPBoost(player, Perks.Cooking, 1);
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gourmand"), true, HaloTextHelper.getColorGreen());
        end
        -- Tinkerer
        if vars.TinkererDynamic and not player:hasTrait(ToadTraitsRegistries.tinkerer) then
            if (lvlElec + lvlMech + lvlTailor) >= vars.TinkererDynamicSkill then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "tinkerer" })
                else
                    traits:add(ToadTraitsRegistries.tinkerer)
                end
                MTDapplyXPBoost(player, Perks.Electricity, 1)
                MTDapplyXPBoost(player, Perks.Mechanics, 1)
                MTDapplyXPBoost(player, Perks.Tailoring, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tinkerer"), true, HaloTextHelper.getColorGreen())
            end
        end
    end

    ---------------------------------------------------------------------------
    -- FIREARMS
    ---------------------------------------------------------------------------
    if isInit or perk == "KillCount" or perk == Perks.Aiming or perk == Perks.Reloading then
        local hasAT = getActivatedMods():contains("Advanced_trajectory")
        local gunKills = 0
        if killCountisOn and not hasAT then
            gunKills = getKills("Firearm")
        end
        -- Anti-Gun Activist (Removal)
        if vars.AntiGunActivistDynamic and player:hasTrait(ToadTraitsRegistries.antigun) then
            local canRemove = lvlAim >= vars.AntiGunActivistDynamicSkill
            if canRemove and killCountisOn and not hasAT then
                canRemove = gunKills >= vars.AntiGunActivistDynamicKill
            end
            if canRemove then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "antigun" })
                else
                    traits:remove(ToadTraitsRegistries.antigun)
                end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_antigun"), false, HaloTextHelper.getColorGreen())
            end
        end
        -- Prowess: Guns
        if vars.ProwessGunsDynamic and not player:hasTrait(ToadTraitsRegistries.progun) then
            local canGet = (lvlAim >= vars.ProwessGunsDynamicAiming) and ((lvlAim + lvlReload) >= vars.ProwessGunsDynamicSkill)
            if canGet and killCountisOn and not hasAT then
                canGet = gunKills >= vars.ProwessGunsDynamicKill
            end
            if canGet then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "progun" })
                else
                    traits:add(ToadTraitsRegistries.progun)
                end
                MTDapplyXPBoost(player, Perks.Aiming, 1)
                MTDapplyXPBoost(player, Perks.Reloading, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_progun"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- Terminator
        local gunSkillSum = lvlNimble + lvlAim + lvlReload
        if vars.TerminatorDynamic and not player:hasTrait(ToadTraitsRegistries.terminator) then
            local getTrait = gunSkillSum >= vars.TerminatorDynamicSkill
            if (killCountisOn and not getActivatedMods():contains("Advanced_trajectory")) then
                getTrait = getTrait and (gunKills >= vars.TerminatorDynamicKill)
            end
            
            if getTrait then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "terminator" })
                else
                    traits:add(ToadTraitsRegistries.terminator)
                end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_terminator"), true, HaloTextHelper.getColorGreen())
            end
        end
    end

    ---------------------------------------------------------------------------
    -- SCAVENGING SKILL
    ---------------------------------------------------------------------------
    local hasScavMod = getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed")
    if hasScavMod and (isInit or perk == Perks.Scavenging) then
        -- 1. Incomprehensive
        if vars.IncomprehensiveDynamic and player:hasTrait(ToadTraitsRegistries.incomprehensive) and lvlScav >= vars.IncomprehensiveDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "incomprehensive" })
            else
                traits:remove(ToadTraitsRegistries.incomprehensive)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_incomprehensive"), false, HaloTextHelper.getColorGreen())
        end
        -- 2. Vagabond
        if vars.VagabondDynamic and not player:hasTrait(ToadTraitsRegistries.vagabond) and lvlScav >= vars.VagabondDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "vagabond" })
            else
                traits:add(ToadTraitsRegistries.vagabond)
            end
            MTDapplyXPBoost(player, Perks.Scavenging, 1)
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_vagabond"), true, HaloTextHelper.getColorGreen())
        end
        -- 3. Grave Robber
        if vars.GraverobberDynamic and not player:hasTrait(ToadTraitsRegistries.graverobber) then
            if lvlScav >= vars.GraverobberDynamicSkill and player:getZombieKills() >= vars.GraverobberDynamicKill then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "graverobber" })
                else
                    traits:add(ToadTraitsRegistries.graverobber)
                end
                MTDapplyXPBoost(player, Perks.Scavenging, 1)
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen())
            end
        end
        -- 4. Antique Collector
        if vars.AntiqueCollectorDynamic and not player:hasTrait(ToadTraitsRegistries.antique) and lvlScav >= vars.AntiqueCollectorDynamicSkill then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "antique" })
            else
                traits:add(ToadTraitsRegistries.antique)
            end
            MTDapplyXPBoost(player, Perks.Scavenging, 1)
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_antique"), true, HaloTextHelper.getColorGreen())
        end
    end

end

function MTDTraitGainsByWeight()
    local player = getPlayer()
    if not player then return end

    local vars = SandboxVars.MoreTraitsDynamic
    if not vars.IdealWeightDynamic then return end

    local MTD = player:getModData().MoreTraitsDynamic
	if not MTD then return end
    
    MTD.WeightMaintainedHours = MTD.WeightMaintainedHours or 0
    MTD.WeightNotMaintainedHours = MTD.WeightNotMaintainedHours or 0
    
    local weight = player:getNutrition():getWeight()
    local hasIdeal = player:hasTrait(ToadTraitsRegistries.idealweight)
    local isInIdealRange = (weight >= 78 and weight <= 82)
    local traits = player:getCharacterTraits()

    if not hasIdeal then
        if isInIdealRange then
            MTD.WeightMaintainedHours = MTD.WeightMaintainedHours + 1
        else
            MTD.WeightNotMaintainedHours = MTD.WeightNotMaintainedHours + 1
            if MTD.WeightNotMaintainedHours >= vars.IdealWeightDynamicObtainGracePeriod then
                MTD.WeightMaintainedHours = 0
                MTD.WeightNotMaintainedHours = 0
            end
        end
        if MTD.WeightMaintainedHours >= (vars.IdealWeightDynamicTargetDaysToObtain * 24) then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "idealweight" })
            else
                traits:add(ToadTraitsRegistries.idealweight)
            end
            MTD.WeightMaintainedHours = 0
            MTD.WeightNotMaintainedHours = 0
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_idealweight"), true, HaloTextHelper.getColorGreen())
        end
    else
        if isInIdealRange then
            -- Earn grace hours while in range
            local gain = 0.0834 * vars.IdealWeightDynamicLoseGracePeriodMultiplier
            MTD.WeightMaintainedHours = math.min(MTD.WeightMaintainedHours + gain, vars.IdealWeightDynamicLoseGracePeriodCap)
        else
            -- Only lose progress if weight goes past the "danger" thresholds
            if weight <= 75 or weight >= 85 then
                MTD.WeightMaintainedHours = MTD.WeightMaintainedHours - 1
                
                if MTD.WeightMaintainedHours <= 0 then
                    if isClient() then
                        sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "idealweight" })
                    else
                        traits:remove(ToadTraitsRegistries.idealweight)
                    end
                    MTD.WeightMaintainedHours = 0
                    MTD.WeightNotMaintainedHours = 0
                    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_idealweight"), false, HaloTextHelper.getColorRed())
                end
            end
        end
    end
end

function MTDTraitGainsByPanic()
    local player = getPlayer()
    if not player then return end

    local MTD = player:getModData().MoreTraitsDynamic
    if not MTD then return end

    local vars = SandboxVars.MoreTraitsDynamic
    local stats = player:getStats()
    local stress = stats:get(CharacterStat.STRESS);
    local panic = stats:get(CharacterStat.PANIC);

    MTD.FiftyPlusStressAndPanicTime = MTD.FiftyPlusStressAndPanicTime or 0

    if player:hasTrait(ToadTraitsRegistries.paranoia) then
        if stress >= 0.5 and panic >= 50 then
            MTD.FiftyPlusStressAndPanicTime = MTD.FiftyPlusStressAndPanicTime + 1
        end
        local targetMinutes = vars.ParanoiaDynamicHoursLose * 60
        
        if MTD.FiftyPlusStressAndPanicTime >= targetMinutes then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "paranoia" })
            else
                player:getCharacterTraits():remove(ToadTraitsRegistries.paranoia)
            end
            MTD.FiftyPlusStressAndPanicTime = 0
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_paranoia"), false, HaloTextHelper.getColorGreen())
        end
    else
        if MTD.FiftyPlusStressAndPanicTime ~= 0 then
            MTD.FiftyPlusStressAndPanicTime = 0
        end
    end
end

function MTDTraitGainsByInjuries()
    local player = getPlayer()
    if not player then return end

    local vars = SandboxVars.MoreTraitsDynamic
    local MTD = player:getModData().MoreTraitsDynamic
    if not MTD then return end

    MTD.InjuredTime = MTD.InjuredTime or 0
    MTD.totalInfectionTime = MTD.totalInfectionTime or 0

    local bodyParts = player:getBodyDamage():getBodyParts()
    local bodyPartsSize = bodyParts:size()
    local hasUnwavering = player:hasTrait(ToadTraitsRegistries.unwavering)
    local hasImmunocompromised = player:hasTrait(ToadTraitsRegistries.immunocompromised)
    local hasSuperImmune = player:hasTrait(ToadTraitsRegistries.superimmune)

    for n = 0, bodyPartsSize - 1 do
        local part = bodyParts:get(n)
        local partType = part:getType()

        if vars.UnwaveringDynamic and not hasUnwavering then
            local isLegOrGroin = (
                partType == BodyPartType.Groin or partType == BodyPartType.UpperLeg_L or partType == BodyPartType.UpperLeg_R or 
                partType == BodyPartType.LowerLeg_L or partType == BodyPartType.LowerLeg_R or partType == BodyPartType.Foot_L or partType == BodyPartType.Foot_R
            )
            
            if part:HasInjury() and isLegOrGroin then
                local fraction = 0.167
                if part:getBleedingTime() > 0  then MTD.InjuredTime = MTD.InjuredTime + (fraction / 24) end
                if part:getScratchTime() > 0   then MTD.InjuredTime = MTD.InjuredTime + (fraction / 12) end
                if part:getCutTime() > 0       then MTD.InjuredTime = MTD.InjuredTime + (fraction / 6)  end
                if part:getBurnTime() > 0      then MTD.InjuredTime = MTD.InjuredTime + (fraction / 8)  end
                if part:getDeepWoundTime() > 0 then MTD.InjuredTime = MTD.InjuredTime + fraction        end
                if part:getStitchTime() > 0    then MTD.InjuredTime = MTD.InjuredTime + (fraction / 8)  end
                if part:getFractureTime() > 0  then MTD.InjuredTime = MTD.InjuredTime + (fraction / 8)  end
            end
        end

        if (vars.ImmunocompromisedDynamic or vars.SuperImmuneDynamic) and not hasSuperImmune then
            if part:getWoundInfectionLevel() > 0 then
                MTD.totalInfectionTime = MTD.totalInfectionTime + (1 / 6) -- Increment hours
            end
        end
    end
    
    local traits = player:getCharacterTraits()
    -- Add Unwavering
    if not hasUnwavering and MTD.InjuredTime >= vars.UnwaveringDynamicCounter then
        if isClient() then
            sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "unwavering" })
        else
            traits:add(ToadTraitsRegistries.unwavering)
        end
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unwavering"), true, HaloTextHelper.getColorGreen())
    end
    -- Remove Immunocompromised
    if hasImmunocompromised and vars.ImmunocompromisedDynamic then
        if MTD.totalInfectionTime >= vars.ImmunocompromisedDynamicInfectionTime then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "removeTrait", { trait = "immunocompromised" })
            else
                traits:remove(ToadTraitsRegistries.immunocompromised)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_immunocompromised"), false, HaloTextHelper.getColorGreen())
            -- Optional: Reset counter so Super-Immune starts from 0 after removal
            MTD.totalInfectionTime = 0 
        end
    -- Award Super-Immune (Only if not Immunocompromised)
    elseif not hasSuperImmune and vars.SuperImmuneDynamic then
        if MTD.totalInfectionTime >= vars.SuperImmuneDynamicInfectionTime then
            if isClient() then
                sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "superimmune" })
            else
                traits:add(ToadTraitsRegistries.superimmune)
            end
            HaloTextHelper.addTextWithArrow(player, getText("UI_trait_superimmune"), true, HaloTextHelper.getColorGreen())
        end
    end
end

function MTDLeadFoot(zombie)
    local player = getPlayer()
    if not player or player:hasTrait(ToadTraitsRegistries.leadfoot) then return end

    local MTD = player:getModData().MoreTraitsDynamic
    if not MTD or not SandboxVars.MoreTraitsDynamic.LeadFootDynamic then return end

    if MTD.AllowLeadFootCount then
        if player:DistTo(zombie) <= 1 then
            MTD.LeadFootCount = (MTD.LeadFootCount or 0) + 1
            if MTD.LeadFootCount >= SandboxVars.MoreTraitsDynamic.LeadFootDynamicKill then
                if isClient() then
                    sendClientCommand("MoreTraitsDynamic", "addTrait", { trait = "leadfoot" })
                else
                    player:getCharacterTraits():add(ToadTraitsRegistries.leadfoot)
                end
                HaloTextHelper.addTextWithArrow(player, getText("UI_trait_leadfoot"), true, HaloTextHelper.getColorGreen())
            end
        end
    end
end

function MTDInitializeData(playerindex, player)
    if not player then return end

    local playerdata = player:getModData()
    if not playerdata then return end
    
    InitMoreTraitsDynamic(player, playerdata)
end

function MTDRegisterLogic(playerindex, player)
    if not player then return end

    Events.EveryOneMinute.Add(MTDEveryOneMinuteMain)
    Events.EveryTenMinutes.Add(MTDEveryTenMinutesMain)
    Events.EveryHours.Add(MTDEveryHoursMain)

    Events.LevelPerk.Add(MTDLevelPerkMain)
    Events.OnWeaponHitCharacter.Add(MTDOnWeaponHitCharacterMain)

    MTDTraitsGainsByLevel(player, "characterInitialization")
    
    if getActivatedMods():contains("KillCount") then
        Events.OnZombieDead.Add(MTDKillsMainExtended)
    else
        Events.OnZombieDead.Add(MTDKillsMain)
    end
end

Events.OnCreatePlayer.Add(MTDInitializeData)
Events.OnCreatePlayer.Add(MTDRegisterLogic)