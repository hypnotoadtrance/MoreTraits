function MTDLevelPerkMain(player, perk, perkLevel, addBuffer)

	-- CALL TO OTHER METHODS THAT RUNS BASED ON THE LevelPerk EVENT
	if getActivatedMods():contains("ToadTraitsDynamic") then
		MTDtraitsGainsByLevel(player, perk, perkLevel);
	end   
 end
 
 function MTDapplyXPBoost(player, perk, boostLevel)
    local currentXPBoost = player:getXp():getPerkBoost(perk);
    local newBoost = currentXPBoost + boostLevel;
    if newBoost > 3 then
        player:getXp():setPerkBoost(perk, 3);
    else
        player:getXp():setPerkBoost(perk, newBoost);
    end
end

Events.LevelPerk.Add(MTDLevelPerkMain);

function MTDtraitsGainsByLevel(player, perk, perkLevel)


-- Passive
	-- Strength
		-- (Defined here) Lead Foot: Strength 6
		-- (Defined here) Pack Mouse: Strength 7
		-- (Defined here) Pack Mule: Strength 9
		-- (Defined here) Indefatigable: SUM All Passives, All Agility, All Combat without Maintenance) 100+
		-- (Defined here) Gym-Goer: SUM (Passives), 14+
		-- (Defined here) Second Wind: SUM(Passives), 18+
	-- Fitness
		-- (Defined here) Hardy: Fitness 7
		-- (Defined here) Noodle Legs: SUM(Fitness, Sprint, Lightfooted, Nimble, Sneaking) 30+
		-- (Defined here) Evasive: SUM(Fitness, Sprint, Lightfooted, Nimble, Sneaking) 40+
-- Agility
	-- Sprint
		-- (Defined here) Olympian: Sprint 5, Fitness 6
		-- (Defined here) Slowpoke: SUM(Agility) 20+
		-- (Defined here) Fast: SUM(Agility) 30+
	-- Lightfooted
		-- (Defined here) Swift: Lightfooted 4
	-- Nimble
		-- (Defined here) Flexible: Nimble 4
		-- (Defined here) Well-Fitted: Nimble 8
		-- (Defined here) Terminator: SUM (Firearms, Nimble) 28+
	-- Sneaking
		-- (Defined here) Quiet: Sneaking 4
-- Combat
	-- Axe
		-- (Defined here) Tavern Brawler: SUM (All Combat except Maintenance) 12+
		-- (Defined here) Prowess Blade: SUM(Axe, Long Blade, Short Blade) 24+
	-- Longblunt
		-- (Defined here) Gordanite: Long Blunt 6
		-- (Defined here) Thuggish: SUM(Long Blunt, Short Blunt) 10+
		-- (Defined here) Prowess Blunt: SUM(Long Blunt, Short Blunt) 16+
	-- Shortblunt
		-- (Defined here) Grunt Worker: Short Blunt 4, Carpentry 5
		-- (Defined here) Martial Artist: Short Blunt 6, Fitness 6
		-- (Defined here) Bouncer: Short Blunt 7, Strength 7
		-- Thuggish: SUM(Long Blunt, Short Blunt) 10+
		-- Prowess Blunt: SUM(Long Blunt, Short Blunt) 16+
	-- Longblade
		-- (Defined here) Practiced Swordsman: SUM(Long Blade Short Blade) 10+
		-- Prowess Blade: SUM(Axe, Long Blade, Short Blade) 24+
	-- Shortblade
		-- Practiced Swordsman: SUM(Long Blade Short Blade) 10+
		-- Prowess Blade: SUM(Axe, Long Blade, Short Blade) 24+
	-- Spear
		-- (Defined here) Wildsman: Spear 4, SUM(Fishing, Trapping, Foraging) 8+ with at least 1 lvl in each
		-- (Defined here) Prowess Spear: Spear 8
	-- Maintenance
		-- (Defined here) Scrapper: Maintenance 5, Metalworking 5
-- Crafting
	-- Carpentry
		-- (Defined here) Slow Worker: SUM(All crafting) 30+
		-- (Defined here) Fast worker: SUM(All crafting) 60+
		-- Grunt Worker: Short Blunt 4, Carpentry 5
	-- Cooking
		-- (Defined here) Natural Eater: Cooking 2, Foraging 5
		-- (Defined here) Ascetic: Cooking 5
		-- (Defined here) Gourmand: Cooking 9
	-- Farming
	-- Firstaid
	-- Electricity
		-- (Defined here) Tinkerer: SUM(Electricity, Mechanics, Tailoring) 12+
	-- Metalworking
		-- Scrapper: Maintenance 5, Metalworking 5
	-- Mechanics
		-- Tinkerer: SUM(Electrical, Mechanics, Tailoring) 12+
	-- Tailoring
		-- Tinkerer: SUM(Electrical, Mechanics, Tailoring) 12+
-- Firearm
	-- Aiming
		-- (Defined here) Prowess Guns: SUM(Aiming, Reloading) 16+
	-- Reloading
		-- Prowess Guns: SUM(Aiming, Reloading) 16+
-- Survivalist
	-- Fishing
		-- Wildsman: Spear 4, SUM(Fishing, Trapping, Foraging) 8+ with at least 1 lvl in each
	-- Trapping
		-- Wildsman: Spear 4, SUM(Fishing, Trapping, Foraging) 8+ with at least 1 lvl in each
	-- Foraging
		-- Wildsman: Spear 4, SUM(Fishing, Trapping, Foraging) 8+ with at least 1 lvl in each
		-- Natural Eater: Cooking 2, Foraging 5
-- Mod Category
	-- Driving
		-- (Defined here) Motion Sickenss: Driving 5
		-- (Defined here) Student Driver: Driving 3 // disabled when Driving Skill is enabled
		-- (Defined here) Expert Driver: Driving 8 // disabled when Driving Skill is enabled
	-- Scavenging
		-- (Defined here) Incomprehensive: Scavenging 4 
		-- (Defined here) Vagabond: Scavenging 5 
		-- (Defined here) Scrounger: Scavenging 6
		-- (Defined here) Graverobber: Scavenging 7 
		-- (Defined here) Antique Collector: Scavenging 9

	-- Passive
		-- Strength
			-- Pack Mouse / Lead Foot / Pack Mule
				if perk == Perks.Strength then
					-- Lead Foot
					if SandboxVars.MoreTraitsDynamic.LeadFootDynamic == true and not player:HasTrait("leadfoot") and player:getPerkLevel(Perks.Strength) >= 6 then
						player:getTraits():add("leadfoot");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_leadfoot"), true, HaloTextHelper.getColorGreen());
					end
					-- Pack Mouse
					if SandboxVars.MoreTraitsDynamic.PackMouseDynamic == true and player:HasTrait("packmouse") and player:getPerkLevel(Perks.Strength) >= 7 then
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_packmouse"), false, HaloTextHelper.getColorGreen());
					end
					-- Pack Mule
					if SandboxVars.MoreTraitsDynamic.PackMuleDynamic == true and not player:HasTrait("packmule") and player:getPerkLevel(Perks.Strength) >= 9 then
						player:getTraits():add("packmule");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_packmule"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Indefatigable
				if perk == Perks.Strength or perk == Perks.Fitness or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt	or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear then
					if SandboxVars.MoreTraitsDynamic.IndefatigableDynamic == true and not player:HasTrait("indefatigable") and (player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness) + player:getPerkLevel(Perks.Sprinting) + player:getPerkLevel(Perks.Lightfoot) + player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Sneak) + player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt) + player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade) + player:getPerkLevel(Perks.Spear)) >= 110 then
						player:getTraits():add("indefatigable");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Second Wind // Gym-Goer
				if perk == Perks.Strength or perk == Perks.Fitness then
					local sumOfLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness)
					-- Gym-Goer
					if SandboxVars.MoreTraitsDynamic.GymGoerDynamic == true and not player:HasTrait("gymgoer") and sumOfLevels >= 14 then
						player:getTraits():add("gymgoer");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gymgoer"), true, HaloTextHelper.getColorGreen());
					end
					-- Second Wind
					if SandboxVars.MoreTraitsDynamic.SecondWindDynamic == true and not player:HasTrait("secondwind") and sumOfLevels >= 18 then
						player:getTraits():add("secondwind");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_secondwind"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Fitness
			-- Hardy
				if perk == Perks.Fitness then
					if SandboxVars.MoreTraitsDynamic.HardyDynamic == true and not player:HasTrait("hardy") and player:getPerkLevel(Perks.Fitness) >= 7 then
						player:getTraits():add("hardy");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardy"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Noodle Legs / Evasive
				if perk == Perks.Fitness or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak then
					local sumOfLevels = player:getPerkLevel(Perks.Fitness) + player:getPerkLevel(Perks.Sprinting) + player:getPerkLevel(Perks.Lightfoot) + player:getPerkLevel(Perks.Nimble)
					-- Noodle Legs
					if SandboxVars.MoreTraitsDynamic.NoodleLegsDynamic == true and player:HasTrait("noodlelegs") and sumOfLevels >= 30 then
						player:getTraits():remove("noodlelegs");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_noodlelegs"), false, HaloTextHelper.getColorGreen());
					end
					-- Evasive
					if SandboxVars.MoreTraitsDynamic.EvasiveDynamic == true and not player:HasTrait("evasive") and sumOfLevels >= 40 then
						player:getTraits():add("evasive");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_evasive"), true, HaloTextHelper.getColorGreen());
					end
				end
	-- Agility
		-- Sprinting
			-- Olympian
				if perk == Perks.Sprinting or perk == Perks.Fitness then
					if SandboxVars.MoreTraitsDynamic.OlympianDynamic == true and not player:HasTrait("olympian") and player:getPerkLevel(Perks.Sprinting) >= 5 and player:getPerkLevel(Perks.Fitness) >= 6 then
						player:getTraits():add("olympian");
						MTDapplyXPBoost(player, Perks.Sprinting, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_olympian"), true, HaloTextHelper.getColorGreen());
					end							
				end
			-- Slowpoke // Fast
				if perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak then
					local sumOfLevels = player:getPerkLevel(Perks.Sprinting) + player:getPerkLevel(Perks.Lightfoot) + player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Sneak)
					-- Slowpoke
					if SandboxVars.MoreTraitsDynamic.SlowpokeDynamic == true and player:HasTrait("gimp") and sumOfLevels >= 20 then
						player:getTraits():remove("gimp");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gimp"), false, HaloTextHelper.getColorGreen());
					end							
					-- Fast
					if SandboxVars.MoreTraitsDynamic.FastDynamic == true and not player:HasTrait("fast") and sumOfLevels >= 30 then
						player:getTraits():add("fast");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fast"), true, HaloTextHelper.getColorGreen());
					end							
				end
		-- Lightfooted
			-- Swift
				if perk == Perks.Lightfoot then
					if SandboxVars.MoreTraitsDynamic.SwiftDynamic == true and not player:HasTrait("swift") and player:getPerkLevel(Perks.Lightfoot) >= 4 then
						player:getTraits():add("swift");
						MTDapplyXPBoost(player, Perks.Lightfoot, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_swift"), true, HaloTextHelper.getColorGreen());
					end							
				end
		-- Nimble
			-- Flexible // Well-Fitted
				if perk == Perks.Nimble then
					-- Flexible
					if SandboxVars.MoreTraitsDynamic.FlexibleDynamic == true and not player:HasTrait("flexible") and player:getPerkLevel(Perks.Nimble) >= 4 then
						player:getTraits():add("flexible");
						MTDapplyXPBoost(player, Perks.Nimble, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_flexible"), true, HaloTextHelper.getColorGreen());
					end		
					if SandboxVars.MoreTraitsDynamic.WellFittedDynamic == true and not player:HasTrait("fitted") and player:getPerkLevel(Perks.Nimble) >= 8 then
						player:getTraits():add("fitted");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fitted"), true, HaloTextHelper.getColorGreen());
					end	
				end
			-- Terminator
				if perk == Perks.Nimble or perk == Perks.Aiming or perk == Perks.Reloading then
					if SandboxVars.MoreTraitsDynamic.TerminatorDynamic == true and not player:HasTrait("terminator") and (player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)) >= 28 then
						player:getTraits():add("terminator");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_terminator"), true, HaloTextHelper.getColorGreen());
					end		
				end
		-- Sneaking
			-- Quiet
				if perk == Perks.Sneak then
					if SandboxVars.MoreTraitsDynamic.QuietDynamic == true and not player:HasTrait("quiet") and player:getPerkLevel(Perks.Sneak) >= 4 then
						player:getTraits():add("quiet");
						MTDapplyXPBoost(player, Perks.Sneak, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_quiet"), true, HaloTextHelper.getColorGreen());
					end						
				end
	-- Combat
		-- Axe
			-- Tawern Brawler
				if perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt	or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear then
					if SandboxVars.MoreTraitsDynamic.TavernBrawlerDynamic == true and not player:HasTrait("tavernbrawler") and (player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt) + player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade) + player:getPerkLevel(Perks.Spear)) >= 12 then
						player:getTraits():add("tavernbrawler");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tavernbrawler"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Prowess: Blade
				if perk == Perks.Axe or perk == Perks.LongBlade or perk == Perks.SmallBlade then
					if SandboxVars.MoreTraitsDynamic.ProwessBladeDynamic == true and not player:HasTrait("problade") and (player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.LongBlade )+ player:getPerkLevel(Perks.SmallBlade)) >= 24 then
						player:getTraits():add("problade");
						MTDapplyXPBoost(player, Perks.Axe, 1);
						MTDapplyXPBoost(player, Perks.LongBlade, 1);
						MTDapplyXPBoost(player, Perks.SmallBlade, 1);
						HaloTextHelper.addTextWithArrow(player, getText("problade"), true, HaloTextHelper.getColorGreen());
					end						
				end
		-- Long Blunt
			-- Gordanite
				if perk == Perks.Blunt then
					if SandboxVars.MoreTraitsDynamic.GordaniteDynamic == true and not player:HasTrait("gordanite") and player:getPerkLevel(Perks.Blunt) >= 6 then
						player:getTraits():add("gordanite");
						MTDapplyXPBoost(player, Perks.Blunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("gordanite"), true, HaloTextHelper.getColorGreen());
					end						
				end
			-- Thuggish / Prowess: Blunt
				if perk == Perks.Blunt or perk == Perks.SmallBlunt then
					local sumOfLevels = player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt)
					-- Thuggish
					if SandboxVars.MoreTraitsDynamic.ThuggishDynamic == true and not player:HasTrait("blunttwirl") and sumOfLevels >= 10 then
						player:getTraits():add("blunttwirl");
						MTDapplyXPBoost(player, Perks.Blunt, 1);
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("blunttwirl"), true, HaloTextHelper.getColorGreen());
					end	
					-- Prowess: Blunt
					if SandboxVars.MoreTraitsDynamic.ProwessBluntDynamic == true and not player:HasTrait("problunt") and sumOfLevels >= 16 then
						player:getTraits():add("problunt");
						MTDapplyXPBoost(player, Perks.Blunt, 1);
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("problunt"), true, HaloTextHelper.getColorGreen());
					end						
				end

		-- Short Blunt
			-- Grunt Worker
				if perk == Perks.SmallBlunt or perk == Perks.Woodwork then
					if SandboxVars.MoreTraitsDynamic.GruntWorkerDynamic == true and not player:HasTrait("grunt") and player:getPerkLevel(Perks.SmallBlunt) >= 4 and player:getPerkLevel(Perks.Woodwork) >= 5 then
						player:getTraits():add("grunt");
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						MTDapplyXPBoost(player, Perks.Woodwork, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_grunt"), true, HaloTextHelper.getColorGreen());
					end					
				end
			-- Martial Artist
				if perk == Perks.SmallBlunt or perk == Perks.Fitness then
					if SandboxVars.MoreTraitsDynamic.MartialArtistDynamic == true and not player:HasTrait("martial") and player:getPerkLevel(Perks.SmallBlunt) >= 6 and player:getPerkLevel(Perks.Fitness) >= 6 then
						player:getTraits():add("martial");
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_martial"), true, HaloTextHelper.getColorGreen());
					end					
				end
			-- Bouncer
				if perk == Perks.SmallBlunt or perk == Perks.Strength then
					if SandboxVars.MoreTraitsDynamic.BouncerDynamic == true and not player:HasTrait("bouncer") and player:getPerkLevel(Perks.SmallBlunt) >= 7 and player:getPerkLevel(Perks.Strength) >= 7 then
						player:getTraits():add("bouncer");
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bouncer"), true, HaloTextHelper.getColorGreen());
					end						
				end
		-- Long Blade
			-- Practiced Swordsman
				if perk == Perks.LongBlade or perk == Perks.SmallBlade then
					if SandboxVars.MoreTraitsDynamic.PracticedSwordsmanDynamic == true and not player:HasTrait("bladetwirl") and (player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade)) >= 10 then
						player:getTraits():add("bladetwirl");
						MTDapplyXPBoost(player, Perks.LongBlade, 1);
						MTDapplyXPBoost(player, Perks.SmallBlade, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bladetwirl"), true, HaloTextHelper.getColorGreen());
					end					
				end
		-- Spear
			-- Wildsman
				if perk == Perks.Spear or perk == Perks.Fishing or perk == Perks.Trapping or perk == Perks.PlantScavenging then
					if SandboxVars.MoreTraitsDynamic.WildsmanDynamic == true and not player:HasTrait("wildsman") and player:getPerkLevel(Perks.Spear) >= 4 and player:getPerkLevel(Perks.Fishing) >= 1 and player:getPerkLevel(Perks.Trapping) >= 1 and player:getPerkLevel(Perks.PlantScavenging) >= 1 and (player:getPerkLevel(Perks.Fishing) + player:getPerkLevel(Perks.Trapping) + player:getPerkLevel(Perks.PlantScavenging)) >= 8 then
						player:getTraits():add("wildsman");
						MTDapplyXPBoost(player, Perks.Spear, 1);
						MTDapplyXPBoost(player, Perks.Fishing, 1);
						MTDapplyXPBoost(player, Perks.Trapping, 1);
						MTDapplyXPBoost(player, Perks.PlantScavenging, 1);
						local playerRecipes = player:getKnownRecipes();
						if not playerRecipes:contains("Make Stick Trap") then
							playerRecipes:add("Make Stick Trap");
						end
						if not playerRecipes:contains("Make Snare Trap") then
							playerRecipes:add("Make Snare Trap");
						end
						if not playerRecipes:contains("Make Fishing Rod") then
							playerRecipes:add("Make Fishing Rod");
						end
						if not playerRecipes:contains("Fix Fishing Rod") then
							playerRecipes:add("Fix Fishing Rod");
						end
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_wildsman"), true, HaloTextHelper.getColorGreen());
					end					
				end
			-- Prowess: Spear
				if perk == Perks.Spear  then
					if SandboxVars.MoreTraitsDynamic.ProwessSpearDynamic == true and not player:HasTrait("prospear") and player:getPerkLevel(Perks.Spear) >= 8 then
						player:getTraits():add("prospear");
						MTDapplyXPBoost(player, Perks.Spear, 2);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_prospear"), true, HaloTextHelper.getColorGreen());
					end					
				end
		-- Maintenance
			-- Scrapper
				if perk == Perks.Maintenance or perk == Perks.MetalWelding then
					if SandboxVars.MoreTraitsDynamic.ScrapperDynamic == true and not player:HasTrait("scrapper") and player:getPerkLevel(Perks.Maintenance) >= 5 and player:getPerkLevel(Perks.MetalWelding) >= 5 then
						player:getTraits():add("scrapper");
						MTDapplyXPBoost(player, Perks.Maintenance, 1);
						MTDapplyXPBoost(player, Perks.MetalWelding, 1);
						local playerRecipes = player:getKnownRecipes();
						if not playerRecipes:contains("Make Metal Pipe") then
							playerRecipes:add("Make Metal Pipe");
						end
						if not playerRecipes:contains("Make Metal Pipe") then
							playerRecipes:add("Make Metal Sheet");
						end
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrapper"), true, HaloTextHelper.getColorGreen());
					end					
				end
	-- Crafting
		-- Carpentry
			-- Slow/Fast Worker
				if perk == Perks.Woodwork or perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.Doctor or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring then
					local sumOfLevels = player:getPerkLevel(Perks.Woodwork) + player:getPerkLevel(Perks.Cooking) + player:getPerkLevel(Perks.Farming) + player:getPerkLevel(Perks.Doctor) + player:getPerkLevel(Perks.Electricity) + player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics) + player:getPerkLevel(Perks.Tailoring)
					if SandboxVars.MoreTraitsDynamic.SlowWorkerDynamic == true and player:HasTrait("slowworker") and sumOfLevels >= 30 then
						player:getTraits():remove("slowworker");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slowworker"), false, HaloTextHelper.getColorGreen());
					end					
					if SandboxVars.MoreTraitsDynamic.FastWorkerDynamic == true and not player:HasTrait("quickworker") and sumOfLevels >= 60 then
						player:getTraits():add("quickworker");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_quickworker"), true, HaloTextHelper.getColorGreen());
					end					
				end
		-- Cooking
			-- Natural Eater
				if perk == Perks.Cooking or  perk == Perks.PlantScavenging then
					if SandboxVars.MoreTraitsDynamic.NaturalEaterDynamic == true and not player:HasTrait("natural") and player:getPerkLevel(Perks.Cooking) >= 2 and player:getPerkLevel(Perks.PlantScavenging) >= 4 then
						player:getTraits():add("natural");
						MTDapplyXPBoost(player, Perks.Cooking, 1);
						MTDapplyXPBoost(player, Perks.PlantScavenging, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_natural"), true, HaloTextHelper.getColorGreen());
					end					
				end
			-- Ascetic / Gourmand
				if perk == Perks.Cooking then
					-- Ascetic
						if SandboxVars.MoreTraitsDynamic.AsceticDynamic == true and player:HasTrait("ascetic") and player:getPerkLevel(Perks.Cooking) >= 5 then
						player:getTraits():remove("ascetic");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ascetic"), false, HaloTextHelper.getColorGreen());
					end		
					-- Gourmand
					if SandboxVars.MoreTraitsDynamic.GourmandDynamic == true and not player:HasTrait("gourmand") and player:getPerkLevel(Perks.Cooking) >= 9 then
						player:getTraits():add("gourmand");
						MTDapplyXPBoost(player, Perks.Cooking, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gourmand"), true, HaloTextHelper.getColorGreen());
					end					
				end
		-- Electricity
			-- Tinkerer
				if perk == Perks.Electricity or  perk == Perks.Mechanics or perk == Perks.Tailoring then
					if SandboxVars.MoreTraitsDynamic.TinkererDynamic == true and not player:HasTrait("tinkerer") and (player:getPerkLevel(Perks.Electricity) + player:getPerkLevel(Perks.Mechanics) + player:getPerkLevel(Perks.Tailoring)) >= 12 then
						player:getTraits():add("tinkerer");
						MTDapplyXPBoost(player, Perks.Electricity, 1);
						MTDapplyXPBoost(player, Perks.Mechanics, 1);
						MTDapplyXPBoost(player, Perks.Tailoring, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tinkerer"), true, HaloTextHelper.getColorGreen());
					end					
				end
	-- Firearm
		-- Aiming
			-- Prowess Guns
				if perk == Perks.Aiming or perk == Perks.Reloading then
					if SandboxVars.MoreTraitsDynamic.ProwessGunsDynamic == true and not player:HasTrait("prospear") and (player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)) >= 16 then
						player:getTraits():add("progun");
						MTDapplyXPBoost(player, Perks.Aiming, 1);
						MTDapplyXPBoost(player, Perks.Reloading, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_progun"), true, HaloTextHelper.getColorGreen());
					end					
				end
	
	-- Mod Category
		-- Driving
			if getActivatedMods():contains("DrivingSkill") and perk == Perks.Driving then
				-- Student Driver // disabled when Driving Skill is enabled
				-- if SandboxVars.MoreTraitsDynamic.StudentDriverDynamic == true and player:HasTrait("poordriver") and player:getPerkLevel(Perks.Driving) >= 3 then
					-- player:getTraits():remove("poordriver");
					-- HaloTextHelper.addTextWithArrow(player, getText("UI_trait_poordriver"), false, HaloTextHelper.getColorGreen());
				-- end
				-- Motionsickness
				if SandboxVars.MoreTraitsDynamic.MotionSickenssDynamic == true and player:HasTrait("motionsickness") and player:getPerkLevel(Perks.Driving) >= 5 then
					player:getTraits():remove("motionsickness");
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_motionsickness"), false, HaloTextHelper.getColorGreen());
				end						
				-- Expert Driver // disabled when Driving Skill is enabled
				-- if SandboxVars.MoreTraitsDynamic.ExpertDriverDynamic == true and not player:HasTrait("UI_trait_expertdriver") and player:getPerkLevel(Perks.Driving) >= 8 then
					-- player:getTraits():add("expertdriver");
					-- HaloTextHelper.addTextWithArrow(player, getText("UI_trait_expertdriver"), true, HaloTextHelper.getColorGreen());
				-- end						
			end
		-- Scavenging
			if getActivatedMods():contains("ScavengingSkill") and perk == Perks.Scavenging then
				-- Incomprehensive
				if SandboxVars.MoreTraitsDynamic.IncomprehensiveDynamic == true and player:HasTrait("incomprehensive") and player:getPerkLevel(Perks.Scavenging) >= 4 then
					player:getTraits():remove("incomprehensive");
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_incomprehensive"), false, HaloTextHelper.getColorGreen());
				end	
				-- Vagabond
				if SandboxVars.MoreTraitsDynamic.VagabondDynamic == true and not player:HasTrait("vagabond") and player:getPerkLevel(Perks.Scavenging) >= 5 then
					player:getTraits():add("vagabond");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_vagabond"), true, HaloTextHelper.getColorGreen());
				end	
				-- Scrounger
				if SandboxVars.MoreTraitsDynamic.ScroungerDynamic == true and not player:HasTrait("scrounger") and player:getPerkLevel(Perks.Scavenging) >= 6 then
					player:getTraits():add("scrounger");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrounger"), true, HaloTextHelper.getColorGreen());
				end	
				-- Grave Robber
				if SandboxVars.MoreTraitsDynamic.GraverobberDynamic == true and not player:HasTrait("graverobber") and player:getPerkLevel(Perks.Scavenging) >= 7 then
					player:getTraits():add("graverobber");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen());
				end		
				-- Antique Collector
				if SandboxVars.MoreTraitsDynamic.AntiqueCollectorDynamic == true and not player:HasTrait("antique") and player:getPerkLevel(Perks.Scavenging) >= 9 then
					player:getTraits():add("antique");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_antique"), true, HaloTextHelper.getColorGreen());
				end	
			end
end
	
	
