function MTDLevelPerkMain(player, perk)
	MTDTraitsGainsByLevel(player, perk);
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

function MTDEveryOneMinuteMain()
	MTDTraitGainsByPanic();
end

function MTDEveryTenMinutesMain()
	MTDTraitGainsByInjuries();
end

function MTDEveryTenMinutesMain()
	MTDTraitGainsByInjuries();
end

function MTDEveryHoursMain()
	MTDTraitGainsByWeight();
end

function MTDOnWeaponHitCharacterMain(wielder, target, weapon, damage)
	if wielder == getPlayer() and target:isZombie() then
		-- Leadfoot
		if SandboxVars.MoreTraitsDynamic.LeadFootDynamic == true and not wielder:HasTrait("leadfoot") then
			MTDLeadFootToggle(wielder, target, weapon);
		end
		-- Mundane
		if SandboxVars.MoreTraitsDynamic.MundaneDynamic == true and wielder:HasTrait("mundane") then
			MTDMundane(wielder, damage);
		end
	end
end

function MTDKillsMainExtended(zombie)
	if SandboxVars.MoreTraitsDynamic.LeadFootDynamic == true and not getPlayer():HasTrait("leadfoot") then
		MTDLeadFoot(zombie);
	end
	MTDTraitsGainsByLevel(getPlayer(), "KillCount");
end

function MTDKillsMain(zombie)
	MTDLeadFoot(zombie);
end

function MTDMundane(wielder, damage)
	wielder:getModData().MoreTraitsDynamic = wielder:getModData().MoreTraitsDynamic or {};
	wielder:getModData().MoreTraitsDynamic.TotalDamageDone = wielder:getModData().MoreTraitsDynamic.TotalDamageDone or 0;
	wielder:getModData().MoreTraitsDynamic.TotalDamageDone = wielder:getModData().MoreTraitsDynamic.TotalDamageDone + damage;
	print("Total damage:"..wielder:getModData().MoreTraitsDynamic.TotalDamageDone);
	if wielder:getModData().MoreTraitsDynamic.TotalDamageDone >= SandboxVars.MoreTraitsDynamic.MundaneDynamicDamage then
		wielder:getTraits():remove("mundane");
		HaloTextHelper.addTextWithArrow(wielder, getText("UI_trait_mundane"), false, HaloTextHelper.getColorGreen());
	end
end

function MTDLeadFootToggle(wielder, target, weapon)
	wielder:getModData().MoreTraitsDynamic = wielder:getModData().MoreTraitsDynamic or {};
	wielder:getModData().MoreTraitsDynamic.AllowLeadFootCount = wielder:getModData().MoreTraitsDynamic.AllowLeadFootCount or false;
	if weapon:getName() == "Bare Hands" and target:isProne() then
		wielder:getModData().MoreTraitsDynamic.AllowLeadFootCount = true;
	else
		wielder:getModData().MoreTraitsDynamic.AllowLeadFootCount = false;
	end
end

function MTDTraitsGainsByLevel(player, perk)
	local player = player or getPlayer();
	local killCountisOn = false;
	if getActivatedMods():contains("KillCount") then
		killCountisOn = true;
	end;
	-- Passive
		-- Strength
			-- Pack Mouse / Pack Mule
				if perk == "characterInitialization" or perk == Perks.Strength then
					-- Pack Mouse
					if SandboxVars.MoreTraitsDynamic.PackMouseDynamic == true and player:HasTrait("packmouse") and player:getPerkLevel(Perks.Strength) >= SandboxVars.MoreTraitsDynamic.PackMouseDynamicSkill then
						player:getTraits():remove("packmouse");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_packmouse"), false, HaloTextHelper.getColorGreen());
					end
					-- Pack Mule
					if SandboxVars.MoreTraitsDynamic.PackMuleDynamic == true and not player:HasTrait("packmule") and player:getPerkLevel(Perks.Strength) >= SandboxVars.MoreTraitsDynamic.PackMuleDynamicSkill then
						player:getTraits():add("packmule");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_packmule"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Indefatigable
				if perk == "characterInitialization" or perk == Perks.Strength or perk == Perks.Fitness or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt	or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear then
					if SandboxVars.MoreTraitsDynamic.IndefatigableDynamic == true and not player:HasTrait("indefatigable") and (player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness) + player:getPerkLevel(Perks.Sprinting) + player:getPerkLevel(Perks.Lightfoot) + player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Sneak) + player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt) + player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade) + player:getPerkLevel(Perks.Spear)) >= SandboxVars.MoreTraitsDynamic.IndefatigableDynamicSkill then
						player:getTraits():add("indefatigable");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Second Wind // Gym-Goer
				if perk == "characterInitialization" or perk == Perks.Strength or perk == Perks.Fitness then
					local sumOfLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness);
					-- Gym-Goer
					if SandboxVars.MoreTraitsDynamic.GymGoerDynamic == true and not player:HasTrait("gymgoer") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.GymGoerDynamicSkill then
						player:getTraits():add("gymgoer");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gymgoer"), true, HaloTextHelper.getColorGreen());
					end
					-- Second Wind
					if SandboxVars.MoreTraitsDynamic.SecondWindDynamic == true and not player:HasTrait("secondwind") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.SecondWindDynamicSkill then
						player:getTraits():add("secondwind");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_secondwind"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Fitness
			-- Hardy
				if perk == "characterInitialization" or perk == Perks.Fitness then
					if SandboxVars.MoreTraitsDynamic.HardyDynamic == true and not player:HasTrait("hardy") and player:getPerkLevel(Perks.Fitness) >= SandboxVars.MoreTraitsDynamic.HardyDynamicSkill then
						player:getTraits():add("hardy");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardy"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Noodle Legs / Evasive
				if perk == "characterInitialization" or perk == Perks.Fitness or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak then
					local sumOfLevels = player:getPerkLevel(Perks.Fitness) + player:getPerkLevel(Perks.Sprinting) + player:getPerkLevel(Perks.Lightfoot) + player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Sneak);
					-- Noodle Legs
					if SandboxVars.MoreTraitsDynamic.NoodleLegsDynamic == true and player:HasTrait("noodlelegs") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.NoodleLegsDynamicSkill then
						player:getTraits():remove("noodlelegs");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_noodlelegs"), false, HaloTextHelper.getColorGreen());
					end
					-- Evasive
					if SandboxVars.MoreTraitsDynamic.EvasiveDynamic == true and not player:HasTrait("evasive") and not player:HasTrait("noodlelegs") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.EvasiveDynamicSkill then
						player:getTraits():add("evasive");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_evasive"), true, HaloTextHelper.getColorGreen());
					end
				end
	-- Agility
		-- Sprinting
			-- Olympian
				if perk == "characterInitialization" or perk == Perks.Sprinting or player:getPerkLevel(Perks.Fitness) then
					if SandboxVars.MoreTraitsDynamic.OlympianDynamic == true and not player:HasTrait("olympian") and player:getPerkLevel(Perks.Sprinting) >= SandboxVars.MoreTraitsDynamic.OlympianDynamicSkillSprinting and player:getPerkLevel(Perks.Fitness) >= SandboxVars.MoreTraitsDynamic.OlympianDynamicSkillFitness then
						player:getTraits():add("olympian");
						MTDapplyXPBoost(player, Perks.Sprinting, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_olympian"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Slowpoke // Fast
				if perk == "characterInitialization" or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak then
					local sumOfLevels = player:getPerkLevel(Perks.Sprinting) + player:getPerkLevel(Perks.Lightfoot) + player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Sneak);
					-- Slowpoke
					if SandboxVars.MoreTraitsDynamic.SlowpokeDynamic == true and player:HasTrait("gimp") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.SlowpokeDynamicSkill then
						player:getTraits():remove("gimp");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gimp"), false, HaloTextHelper.getColorGreen());
					end
					-- Fast
					if SandboxVars.MoreTraitsDynamic.FastDynamic == true and not player:HasTrait("fast") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.FastDynamicSkill then
						player:getTraits():add("fast");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fast"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Lightfooted
			-- Swift
				if perk == "characterInitialization" or perk == Perks.Lightfoot then
					if SandboxVars.MoreTraitsDynamic.SwiftDynamic == true and not player:HasTrait("swift") and player:getPerkLevel(Perks.Lightfoot) >= SandboxVars.MoreTraitsDynamic.SwiftDynamicSkill then
						player:getTraits():add("swift");
						MTDapplyXPBoost(player, Perks.Lightfoot, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_swift"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Nimble
			-- Flexible // Well-Fitted
				if perk == "characterInitialization" or perk == Perks.Nimble then
					-- Flexible
					if SandboxVars.MoreTraitsDynamic.FlexibleDynamic == true and not player:HasTrait("flexible") and player:getPerkLevel(Perks.Nimble) >= SandboxVars.MoreTraitsDynamic.FlexibleDynamicSkill then
						player:getTraits():add("flexible");
						MTDapplyXPBoost(player, Perks.Nimble, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_flexible"), true, HaloTextHelper.getColorGreen());
					end
					if SandboxVars.MoreTraitsDynamic.WellFittedDynamic == true and not player:HasTrait("fitted") and player:getPerkLevel(Perks.Nimble) >= SandboxVars.MoreTraitsDynamic.WellFittedDynamicSkill then
						player:getTraits():add("fitted");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_fitted"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Terminator
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Nimble or perk == Perks.Aiming or perk == Perks.Reloading then
					if killCountisOn then
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["Firearm"] ~= nil then
								categoryKills = player:getModData().KillCount.WeaponCategory["Firearm"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.TerminatorDynamic == true and not player:HasTrait("terminator") and (player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)) >= SandboxVars.MoreTraitsDynamic.TerminatorDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.TerminatorDynamicKill then
							player:getTraits():add("terminator");
							HaloTextHelper.addTextWithArrow(player, getText("UI_trait_terminator"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.TerminatorDynamic == true and not player:HasTrait("terminator") and (player:getPerkLevel(Perks.Nimble) + player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)) >= SandboxVars.MoreTraitsDynamic.TerminatorDynamicSkill then
						player:getTraits():add("terminator");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_terminator"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Sneaking
			-- Quiet
				if perk == "characterInitialization" or perk == Perks.Sneak then
					if SandboxVars.MoreTraitsDynamic.QuietDynamic == true and not player:HasTrait("quiet") and player:getPerkLevel(Perks.Sneak) >= SandboxVars.MoreTraitsDynamic.QuietDynamicSkill then
						player:getTraits():add("quiet");
						MTDapplyXPBoost(player, Perks.Sneak, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_quiet"), true, HaloTextHelper.getColorGreen());
					end
				end
	-- Combat
		-- Axe
			-- Tawern Brawler
				if perk == "characterInitialization" or perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear then
					if SandboxVars.MoreTraitsDynamic.TavernBrawlerDynamic == true and not player:HasTrait("tavernbrawler") and (player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt) + player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade) + player:getPerkLevel(Perks.Spear)) >= SandboxVars.MoreTraitsDynamic.TavernBrawlerDynamicSkill then
						player:getTraits():add("tavernbrawler");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tavernbrawler"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Prowess: Blade
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Axe or perk == Perks.LongBlade or perk == Perks.SmallBlade then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil then
							if player:getModData().KillCount.WeaponCategory["Axe"] ~= nil then
								local axeKills = player:getModData().KillCount.WeaponCategory["Axe"].count or 0;
								categoryKills = categoryKills + axeKills;
							end
							if player:getModData().KillCount.WeaponCategory["LongBlade"] ~= nil then
								local longBladeKills = player:getModData().KillCount.WeaponCategory["LongBlade"].count or 0;
								categoryKills = categoryKills + longBladeKills;
							end
							if player:getModData().KillCount.WeaponCategory["SmallBlade"] ~= nil then
								local shortBladeKills = player:getModData().KillCount.WeaponCategory["SmallBlade"].count or 0;
								categoryKills = categoryKills + shortBladeKills;
							end
						end
						if SandboxVars.MoreTraitsDynamic.ProwessBladeDynamic == true and not player:HasTrait("problade") and (player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.LongBlade )+ player:getPerkLevel(Perks.SmallBlade)) >= SandboxVars.MoreTraitsDynamic.ProwessBladeDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.ProwessBladeDynamicKill then
							player:getTraits():add("problade");
							MTDapplyXPBoost(player, Perks.Axe, 1);
							MTDapplyXPBoost(player, Perks.LongBlade, 1);
							MTDapplyXPBoost(player, Perks.SmallBlade, 1);
							HaloTextHelper.addTextWithArrow(player, getText("problade"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.ProwessBladeDynamic == true and not player:HasTrait("problade") and (player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.LongBlade )+ player:getPerkLevel(Perks.SmallBlade)) >= SandboxVars.MoreTraitsDynamic.ProwessBladeDynamicSkill then
						player:getTraits():add("problade");
						MTDapplyXPBoost(player, Perks.Axe, 1);
						MTDapplyXPBoost(player, Perks.LongBlade, 1);
						MTDapplyXPBoost(player, Perks.SmallBlade, 1);
						HaloTextHelper.addTextWithArrow(player, getText("problade"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Long Blunt
			-- Gordanite
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Blunt then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["Blunt"] ~= nil then
							categoryKills = player:getModData().KillCount.WeaponCategory["Blunt"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.GordaniteDynamic == true and not player:HasTrait("gordanite") and player:getPerkLevel(Perks.Blunt) >= SandboxVars.MoreTraitsDynamic.GordaniteDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.GordaniteDynamicKill then
							player:getTraits():add("gordanite");
							MTDapplyXPBoost(player, Perks.Blunt, 1);
							HaloTextHelper.addTextWithArrow(player, getText("gordanite"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.GordaniteDynamic == true and not player:HasTrait("gordanite") and player:getPerkLevel(Perks.Blunt) >= SandboxVars.MoreTraitsDynamic.GordaniteDynamicSkill then
						player:getTraits():add("gordanite");
						MTDapplyXPBoost(player, Perks.Blunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("gordanite"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Thuggish / Prowess: Blunt
				if perk == "characterInitialization" or perk == "KillCount" or perk == "KillCount" or perk == Perks.Blunt or perk == Perks.SmallBlunt then
					local sumOfLevels = player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt);
					-- Thuggish
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil then 
							if player:getModData().KillCount.WeaponCategory["Blunt"] ~= nil then
								local longBluntKills = player:getModData().KillCount.WeaponCategory["Blunt"].count or 0;
								categoryKills = categoryKills + longBluntKills;
							end
							if player:getModData().KillCount.WeaponCategory["SmallBlunt"] ~= nil then
								local shortBluntKills = player:getModData().KillCount.WeaponCategory["SmallBlunt"].count or 0;
								categoryKills = categoryKills + shortBluntKills;
							end
						end
						if SandboxVars.MoreTraitsDynamic.ThuggishDynamic == true and not player:HasTrait("blunttwirl") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.ThuggishDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.ThuggishDynamicKill then
							player:getTraits():add("blunttwirl");
							MTDapplyXPBoost(player, Perks.Blunt, 1);
							MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
							HaloTextHelper.addTextWithArrow(player, getText("blunttwirl"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.ThuggishDynamic == true and not player:HasTrait("blunttwirl") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.ThuggishDynamicSkill then
						player:getTraits():add("blunttwirl");
						MTDapplyXPBoost(player, Perks.Blunt, 1);
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("blunttwirl"), true, HaloTextHelper.getColorGreen());
					end
					-- Prowess: Blunt
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil then
							if player:getModData().KillCount.WeaponCategory["Long Blunt"] ~= nil then
								local longBluntKills = player:getModData().KillCount.WeaponCategory["Long Blunt"].count or 0;
								categoryKills = categoryKills + longBluntKills;
							end
							if player:getModData().KillCount.WeaponCategory["SmallBlunt"] ~= nil then
								local shortBluntKills = player:getModData().KillCount.WeaponCategory["SmallBlunt"].count or 0;
								categoryKills = categoryKills + shortBluntKills;
							end
						end
						if SandboxVars.MoreTraitsDynamic.ProwessBluntDynamic == true and not player:HasTrait("blunttwirl") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.ProwessBluntDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.ProwessBluntDynamicKill then
							player:getTraits():add("problunt");
							MTDapplyXPBoost(player, Perks.Blunt, 1);
							MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
							HaloTextHelper.addTextWithArrow(player, getText("problunt"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.ProwessBluntDynamic == true and not player:HasTrait("problunt") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.ProwessBluntDynamicSkill then
						player:getTraits():add("problunt");
						MTDapplyXPBoost(player, Perks.Blunt, 1);
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("problunt"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Short Blunt
			-- Grunt Worker
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.SmallBlunt or perk == Perks.Woodwork then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["SmallBlunt"] ~= nil then
							categoryKills = player:getModData().KillCount.WeaponCategory["SmallBlunt"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.GruntWorkerDynamic == true and not player:HasTrait("grunt") and player:getPerkLevel(Perks.SmallBlunt) >= SandboxVars.MoreTraitsDynamic.GruntWorkerDynamicSmallBlunt and player:getPerkLevel(Perks.Woodwork) >= SandboxVars.MoreTraitsDynamic.GruntWorkerDynamicWoodwork and categoryKills >= SandboxVars.MoreTraitsDynamic.GruntWorkerDynamicKill then
							player:getTraits():add("grunt");
							MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
							MTDapplyXPBoost(player, Perks.Woodwork, 1);
							HaloTextHelper.addTextWithArrow(player, getText("UI_trait_grunt"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.GruntWorkerDynamic == true and not player:HasTrait("grunt") and player:getPerkLevel(Perks.SmallBlunt) >= SandboxVars.MoreTraitsDynamic.GruntWorkerDynamicSmallBlunt and player:getPerkLevel(Perks.Woodwork) >= SandboxVars.MoreTraitsDynamic.GruntWorkerDynamicWoodwork then
						player:getTraits():add("grunt");
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						MTDapplyXPBoost(player, Perks.Woodwork, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_grunt"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Martial Artist
				if perk == "characterInitialization" or perk == Perks.SmallBlunt or perk == Perks.Fitness then
					if SandboxVars.MoreTraitsDynamic.MartialArtistDynamic == true and not player:HasTrait("martial") and player:getPerkLevel(Perks.SmallBlunt) >= SandboxVars.MoreTraitsDynamic.MartialArtistDynamicSmallBlunt and player:getPerkLevel(Perks.Fitness) >= SandboxVars.MoreTraitsDynamic.MartialArtistDynamicFitness then
						player:getTraits():add("martial");
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_martial"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Bouncer
				if perk == "characterInitialization" or perk == Perks.SmallBlunt or perk == Perks.Strength then
					if SandboxVars.MoreTraitsDynamic.BouncerDynamic == true and not player:HasTrait("bouncer") and player:getPerkLevel(Perks.SmallBlunt) >= SandboxVars.MoreTraitsDynamic.BouncerDynamicSmallBlunt and player:getPerkLevel(Perks.Strength) >= SandboxVars.MoreTraitsDynamic.BouncerDynamicStrength then
						player:getTraits():add("bouncer");
						MTDapplyXPBoost(player, Perks.SmallBlunt, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bouncer"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Long Blade
			-- Practiced Swordsman
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.LongBlade or perk == Perks.SmallBlade then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil then
							if player:getModData().KillCount.WeaponCategory["SmallBlade"] ~= nil then
								local shortBladeKills = player:getModData().KillCount.WeaponCategory["SmallBlade"].count or 0;
								categoryKills = categoryKills + shortBladeKills;
							end
							if player:getModData().KillCount.WeaponCategory["Long Blade"] ~= nil then
								local longBladeKills = player:getModData().KillCount.WeaponCategory["Long Blade"].count or 0;
								categoryKills = categoryKills + longBladeKills;
							end
						end
						if SandboxVars.MoreTraitsDynamic.PracticedSwordsmanDynamic == true and not player:HasTrait("bladetwirl") and (player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade)) >= SandboxVars.MoreTraitsDynamic.PracticedSwordsmanDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.PracticedSwordsmanDynamicKill then
						player:getTraits():add("bladetwirl");
						MTDapplyXPBoost(player, Perks.LongBlade, 1);
						MTDapplyXPBoost(player, Perks.SmallBlade, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bladetwirl"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.PracticedSwordsmanDynamic == true and not player:HasTrait("bladetwirl") and (player:getPerkLevel(Perks.LongBlade) + player:getPerkLevel(Perks.SmallBlade)) >= SandboxVars.MoreTraitsDynamic.PracticedSwordsmanDynamicSkill then
						player:getTraits():add("bladetwirl");
						MTDapplyXPBoost(player, Perks.LongBlade, 1);
						MTDapplyXPBoost(player, Perks.SmallBlade, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_bladetwirl"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Spear
			-- Wildsman
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Spear or perk == Perks.Fishing or perk == Perks.Trapping or perk == Perks.PlantScavenging then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["Spear"] ~= nil then
							categoryKills = player:getModData().KillCount.WeaponCategory["Spear"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.WildsmanDynamic == true and not player:HasTrait("wildsman") and player:getPerkLevel(Perks.Spear) >= 4 and player:getPerkLevel(Perks.Fishing) >= 1 and player:getPerkLevel(Perks.Trapping) >= 1 and player:getPerkLevel(Perks.PlantScavenging) >= 1 and (player:getPerkLevel(Perks.Fishing) + player:getPerkLevel(Perks.Trapping) + player:getPerkLevel(Perks.PlantScavenging)) >= SandboxVars.MoreTraitsDynamic.WildsmanDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.WildsmanDynamicKill then
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
					elseif SandboxVars.MoreTraitsDynamic.WildsmanDynamic == true and not player:HasTrait("wildsman") and player:getPerkLevel(Perks.Spear) >= 4 and player:getPerkLevel(Perks.Fishing) >= 1 and player:getPerkLevel(Perks.Trapping) >= 1 and player:getPerkLevel(Perks.PlantScavenging) >= 1 and (player:getPerkLevel(Perks.Fishing) + player:getPerkLevel(Perks.Trapping) + player:getPerkLevel(Perks.PlantScavenging)) >= SandboxVars.MoreTraitsDynamic.WildsmanDynamicSkill then
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
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Spear  then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["Spear"] ~= nil then
							categoryKills = player:getModData().KillCount.WeaponCategory["Spear"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.ProwessSpearDynamic == true and not player:HasTrait("prospear") and player:getPerkLevel(Perks.Spear) >= SandboxVars.MoreTraitsDynamic.ProwessSpearDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.ProwessSpearDynamicKill then
							player:getTraits():add("prospear");
							MTDapplyXPBoost(player, Perks.Spear, 2);
							HaloTextHelper.addTextWithArrow(player, getText("UI_trait_prospear"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.ProwessSpearDynamic == true and not player:HasTrait("prospear") and player:getPerkLevel(Perks.Spear) >= SandboxVars.MoreTraitsDynamic.ProwessSpearDynamicSkill then
						player:getTraits():add("prospear");
						MTDapplyXPBoost(player, Perks.Spear, 2);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_prospear"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Maintenance
			-- Scrapper
				if perk == "characterInitialization" or perk == Perks.Maintenance or perk == Perks.MetalWelding then
					if SandboxVars.MoreTraitsDynamic.ScrapperDynamic == true and not player:HasTrait("scrapper") and player:getPerkLevel(Perks.Maintenance) >= SandboxVars.MoreTraitsDynamic.ScrapperDynamicMaintenance and player:getPerkLevel(Perks.MetalWelding) >= SandboxVars.MoreTraitsDynamic.ScrapperDynamicMetalWelding then
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
				if perk == "characterInitialization" or perk == Perks.Woodwork or perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.Doctor or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring then
					local sumOfLevels = player:getPerkLevel(Perks.Woodwork) + player:getPerkLevel(Perks.Cooking) + player:getPerkLevel(Perks.Farming) + player:getPerkLevel(Perks.Doctor) + player:getPerkLevel(Perks.Electricity) + player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics) + player:getPerkLevel(Perks.Tailoring)
					if SandboxVars.MoreTraitsDynamic.SlowWorkerDynamic == true and player:HasTrait("slowworker") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.SlowWorkerDynamicSkill then
						player:getTraits():remove("slowworker");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_slowworker"), false, HaloTextHelper.getColorGreen());
					end
					if SandboxVars.MoreTraitsDynamic.FastWorkerDynamic == true and not player:HasTrait("quickworker") and sumOfLevels >= SandboxVars.MoreTraitsDynamic.FastWorkerDynamicSkill then
						player:getTraits():add("quickworker");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_quickworker"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Cooking
			-- Natural Eater
				if perk == "characterInitialization" or perk == Perks.Cooking or  perk == Perks.PlantScavenging then
					if SandboxVars.MoreTraitsDynamic.NaturalEaterDynamic == true and not player:HasTrait("natural") and player:getPerkLevel(Perks.Cooking) >= SandboxVars.MoreTraitsDynamic.NaturalEaterDynamicCooking and player:getPerkLevel(Perks.PlantScavenging) >= SandboxVars.MoreTraitsDynamic.NaturalEaterDynamicForaging then
						player:getTraits():add("natural");
						MTDapplyXPBoost(player, Perks.Cooking, 1);
						MTDapplyXPBoost(player, Perks.PlantScavenging, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_natural"), true, HaloTextHelper.getColorGreen());
					end
				end
			-- Ascetic / Gourmand
				if perk == "characterInitialization" or perk == Perks.Cooking then
					-- Ascetic
						if SandboxVars.MoreTraitsDynamic.AsceticDynamic == true and player:HasTrait("ascetic") and player:getPerkLevel(Perks.Cooking) >= SandboxVars.MoreTraitsDynamic.AsceticDynamicSkill then
						player:getTraits():remove("ascetic");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ascetic"), false, HaloTextHelper.getColorGreen());
					end
					-- Gourmand
					if SandboxVars.MoreTraitsDynamic.GourmandDynamic == true and not player:HasTrait("gourmand") and player:getPerkLevel(Perks.Cooking) >= SandboxVars.MoreTraitsDynamic.GourmandDynamicSkill then
						player:getTraits():add("gourmand");
						MTDapplyXPBoost(player, Perks.Cooking, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_gourmand"), true, HaloTextHelper.getColorGreen());
					end
				end
		-- Electricity
			-- Tinkerer
				if perk == "characterInitialization" or perk == Perks.Electricity or  perk == Perks.Mechanics or perk == Perks.Tailoring then
					if SandboxVars.MoreTraitsDynamic.TinkererDynamic == true and not player:HasTrait("tinkerer") and (player:getPerkLevel(Perks.Electricity) + player:getPerkLevel(Perks.Mechanics) + player:getPerkLevel(Perks.Tailoring)) >= SandboxVars.MoreTraitsDynamic.TinkererDynamicSkill then
						player:getTraits():add("tinkerer");
						MTDapplyXPBoost(player, Perks.Electricity, 1);
						MTDapplyXPBoost(player, Perks.Mechanics, 1);
						MTDapplyXPBoost(player, Perks.Tailoring, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_tinkerer"), true, HaloTextHelper.getColorGreen());
					end
				end
	-- Firearm
		-- Aiming
			-- Anti-Gun Activist
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Aiming then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["Firearm"] ~= nil then
							categoryKills = player:getModData().KillCount.WeaponCategory["Firearm"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.AntiGunActivistDynamic == true and player:HasTrait("antigun") and player:getPerkLevel(Perks.Aiming) >= SandboxVars.MoreTraitsDynamic.AntiGunActivistDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.AntiGunActivistDynamicKill then
							player:getTraits():remove("antigun");
							HaloTextHelper.addTextWithArrow(player, getText("UI_trait_antigun"), false, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.AntiGunActivistDynamic == true and player:HasTrait("antigun") and player:getPerkLevel(Perks.Aiming) >= SandboxVars.MoreTraitsDynamic.AntiGunActivistDynamicSkill then
						player:getTraits():remove("antigun");
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_antigun"), false, HaloTextHelper.getColorGreen());
					end
				end
			-- Prowess Guns
				if perk == "characterInitialization" or perk == "KillCount" or perk == Perks.Aiming or perk == Perks.Reloading then
					if killCountisOn then
						player:getModData().KillCount = player:getModData().KillCount or {};
						local categoryKills = 0;
						if player:getModData().KillCount ~= nil and player:getModData().KillCount.WeaponCategory ~= nil and player:getModData().KillCount.WeaponCategory["Firearm"] ~= nil then
							categoryKills = player:getModData().KillCount.WeaponCategory["Firearm"].count or 0;
						end
						if SandboxVars.MoreTraitsDynamic.ProwessGunsDynamic == true and not player:HasTrait("progun") and player:getPerkLevel(Perks.Aiming) >= SandboxVars.MoreTraitsDynamic.ProwessGunsDynamicAiming and (player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)) >= SandboxVars.MoreTraitsDynamic.ProwessGunsDynamicSkill and categoryKills >= SandboxVars.MoreTraitsDynamic.ProwessGunsDynamicKill then
							player:getTraits():add("progun");
							MTDapplyXPBoost(player, Perks.Aiming, 1);
							MTDapplyXPBoost(player, Perks.Reloading, 1);
							HaloTextHelper.addTextWithArrow(player, getText("UI_trait_progun"), true, HaloTextHelper.getColorGreen());
						end
					elseif SandboxVars.MoreTraitsDynamic.ProwessGunsDynamic == true and not player:HasTrait("progun") and player:getPerkLevel(Perks.Aiming) >= SandboxVars.MoreTraitsDynamic.ProwessGunsDynamicAiming and (player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)) >= SandboxVars.MoreTraitsDynamic.ProwessGunsDynamicSkill then
						player:getTraits():add("progun");
						MTDapplyXPBoost(player, Perks.Aiming, 1);
						MTDapplyXPBoost(player, Perks.Reloading, 1);
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_progun"), true, HaloTextHelper.getColorGreen());
					end
				end
	-- Mod Category
		-- Driving
			if getActivatedMods():contains("DrivingSkill") and ( perk == "characterInitialization" or perk == Perks.Driving ) then
				-- Motionsickness
				if SandboxVars.MoreTraitsDynamic.MotionSickenssDynamic == true and player:HasTrait("motionsickness") and player:getPerkLevel(Perks.Driving) >= SandboxVars.MoreTraitsDynamic.MotionSickenssDynamicSkill then
					player:getTraits():remove("motionsickness");
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_motionsickness"), false, HaloTextHelper.getColorGreen());
				end
			end
		-- Scavenging
			if ( getActivatedMods():contains("ScavengingSkill") or getActivatedMods():contains("ScavengingSkillFixed") ) and ( perk == "characterInitialization" or perk == Perks.Scavenging ) then
				-- Incomprehensive
				if SandboxVars.MoreTraitsDynamic.IncomprehensiveDynamic == true and player:HasTrait("incomprehensive") and player:getPerkLevel(Perks.Scavenging) >= SandboxVars.MoreTraitsDynamic.IncomprehensiveDynamicSkill then
					player:getTraits():remove("incomprehensive");
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_incomprehensive"), false, HaloTextHelper.getColorGreen());
				end
				-- Vagabond
				if SandboxVars.MoreTraitsDynamic.VagabondDynamic == true and not player:HasTrait("vagabond") and player:getPerkLevel(Perks.Scavenging) >= SandboxVars.MoreTraitsDynamic.VagabondDynamicSkill then
					player:getTraits():add("vagabond");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_vagabond"), true, HaloTextHelper.getColorGreen());
				end
				-- Scrounger
				if SandboxVars.MoreTraitsDynamic.ScroungerDynamic == true and not player:HasTrait("scrounger") and player:getPerkLevel(Perks.Scavenging) >= SandboxVars.MoreTraitsDynamic.ScroungerDynamicSkill then
					player:getTraits():add("scrounger");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_scrounger"), true, HaloTextHelper.getColorGreen());
				end
				-- Grave Robber
				if SandboxVars.MoreTraitsDynamic.GraverobberDynamic == true and not player:HasTrait("graverobber") and player:getPerkLevel(Perks.Scavenging) >= SandboxVars.MoreTraitsDynamic.GraverobberDynamicSkill and player:getZombieKills() >= SandboxVars.MoreTraitsDynamic.GraverobberDynamicKill then
					player:getTraits():add("graverobber");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen());
				end
				-- Antique Collector
				if SandboxVars.MoreTraitsDynamic.AntiqueCollectorDynamic == true and not player:HasTrait("antique") and player:getPerkLevel(Perks.Scavenging) >= SandboxVars.MoreTraitsDynamic.AntiqueCollectorDynamicSkill then
					player:getTraits():add("antique");
					MTDapplyXPBoost(player, Perks.Scavenging, 1);
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_antique"), true, HaloTextHelper.getColorGreen());
				end
			end
end

function MTDTraitGainsByWeight()
	local player = getPlayer();
	player:getModData().MoreTraitsDynamic = player:getModData().MoreTraitsDynamic or {};
	player:getModData().MoreTraitsDynamic.WeightMaintainedHours = player:getModData().MoreTraitsDynamic.WeightMaintainedHours or 0;
	player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours = player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours or 0;
	if SandboxVars.MoreTraitsDynamic.IdealWeightDynamic == true then 
		-- Gaining Ideal Weight
		local weight = player:getNutrition():getWeight();
		if not player:HasTrait("idealweight") then
			if weight >= 78 and weight <= 82 then
				player:getModData().MoreTraitsDynamic.WeightMaintainedHours = player:getModData().MoreTraitsDynamic.WeightMaintainedHours + 1;
			else
				player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours = player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours + 1;
				if player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours >= SandboxVars.MoreTraitsDynamic.IdealWeightDynamicObtainGracePeriod then
					player:getModData().MoreTraitsDynamic.WeightMaintainedHours = 0;
					player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours = 0;
				end
			end
			if player:getModData().MoreTraitsDynamic.WeightMaintainedHours >= SandboxVars.MoreTraitsDynamic.IdealWeightDynamicTargetDaysToObtain * 24 then
				player:getTraits():add("idealweight");
				player:getModData().MoreTraitsDynamic.WeightMaintainedHours = 0;
				player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours = 0;
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_idealweight"), true, HaloTextHelper.getColorGreen());
			end
		else
			-- Losing Ideal Weight
			if weight >= 78 and weight <= 82 then
				player:getModData().MoreTraitsDynamic.WeightMaintainedHours = player:getModData().MoreTraitsDynamic.WeightMaintainedHours + 0.0834 * SandboxVars.MoreTraitsDynamic.IdealWeightDynamicLoseGracePeriodMultiplier; -- earning grace hours
				if player:getModData().MoreTraitsDynamic.WeightMaintainedHours >= SandboxVars.MoreTraitsDynamic.IdealWeightDynamicLoseGracePeriodCap then -- grace hours cap
					player:getModData().MoreTraitsDynamic.WeightMaintainedHours = SandboxVars.MoreTraitsDynamic.IdealWeightDynamicLoseGracePeriodCap;
				end
			else
				if weight <= 75 or weight >= 85 then
					player:getModData().MoreTraitsDynamic.WeightMaintainedHours = player:getModData().MoreTraitsDynamic.WeightMaintainedHours - 1;
					if player:getModData().MoreTraitsDynamic.WeightMaintainedHours <= 0 then
						player:getTraits():remove("idealweight");
						player:getModData().MoreTraitsDynamic.WeightMaintainedHours = 0;
						player:getModData().MoreTraitsDynamic.WeightNotMaintainedHours = 0;
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_idealweight"), false, HaloTextHelper.getColorRed());
					end
				end
			end
		end
	end
end

function MTDTraitGainsByPanic()
	local player = getPlayer();
	player:getModData().MoreTraitsDynamic = player:getModData().MoreTraitsDynamic or {};
	player:getModData().MoreTraitsDynamic.FiftyPlusStressAndPanicTime = player:getModData().MoreTraitsDynamic.FiftyPlusStressAndPanicTime
		or 0;
	-- Paranoia
		if player:getStats():getStress() >= 0.5 and player:getStats():getPanic() >= 50 then
			player:getModData().MoreTraitsDynamic.FiftyPlusStressAndPanicTime = player:getModData().MoreTraitsDynamic.FiftyPlusStressAndPanicTime + 1;
		end
		if player:HasTrait("paranoia") and player:getModData().MoreTraitsDynamic.FiftyPlusStressAndPanicTime >=
			SandboxVars.MoreTraitsDynamic.ParanoiaDynamicHoursLose * 60 then
				player:getModData().MoreTraitsDynamic.FiftyPlusStressAndPanicTime = 0
			player:getTraits():remove("paranoia");
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_idealweight"), false, HaloTextHelper.getColorGreen());
		end
end

function MTDTraitGainsByInjuries()
	local player = getPlayer();
	player:getModData().MoreTraitsDynamic = player:getModData().MoreTraitsDynamic or {};
	-- Unwavering
		player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime or 0;
		if SandboxVars.MoreTraitsDynamic.UnwaveringDynamic == true and not player:HasTrait("unwavering") then
			for n = 0, player:getBodyDamage():getBodyParts():size() - 1 do
				local selectedBodyPart = player:getBodyDamage():getBodyParts():get(n);
				local selectedBodyPartType = selectedBodyPart:getType();
				if selectedBodyPart:HasInjury() and ( selectedBodyPartType == BodyPartType.Groin or selectedBodyPartType == BodyPartType.UpperLeg_L or selectedBodyPartType == BodyPartType.UpperLeg_R or selectedBodyPartType == BodyPartType.LowerLeg_L or selectedBodyPartType == BodyPartType.LowerLeg_R or selectedBodyPartType == BodyPartType.Foot_L or selectedBodyPartType == BodyPartType.Foot_R ) then
					local defaultOneHourFraction = 0.167; -- 0.167 every 10 min equals to 1 in 1h
					if selectedBodyPart:getBleedingTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction / 24; -- adds 1 to counter for every 24h of bleeding
						--print(tostring(selectedBodyPartType).." is bleeding. getBleedingTime()="..tostring(selectedBodyPart:getBleedingTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
					if selectedBodyPart:getScratchTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction / 12; -- adds 1 to counter for every 12h of having scratch
						--print(tostring(selectedBodyPartType).." is scratched. getScratchTime()="..tostring(selectedBodyPart:getScratchTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
					if selectedBodyPart:getCutTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction / 6; -- adds 1 to counter for every 6h of having laceration
						--print(tostring(selectedBodyPartType).." is lacerated. getCutTime()="..tostring(selectedBodyPart:getCutTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
					if selectedBodyPart:getBurnTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction / 8; -- adds 1 to counter for every 8h of having burn
						--print(tostring(selectedBodyPartType).." is burned. getBurnTime()="..tostring(selectedBodyPart:getBurnTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
					if selectedBodyPart:getDeepWoundTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction; -- adds 1 to counter for every 1h of having deep wound
						--print(tostring(selectedBodyPartType).." has deep wound. getDeepWoundTime()="..tostring(selectedBodyPart:getDeepWoundTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
					if selectedBodyPart:getStitchTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction / 8; -- adds 1 to counter for every 8h of bleeding
						--print(tostring(selectedBodyPartType).." is stitched. getStitchTime()="..tostring(selectedBodyPart:getStitchTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
					if selectedBodyPart:getFractureTime() ~= 0 then
						player:getModData().MoreTraitsDynamic.InjuredTime = player:getModData().MoreTraitsDynamic.InjuredTime + defaultOneHourFraction / 8; -- adds 1 to counter for every 8h of having fracture
						--print(tostring(selectedBodyPartType).." is fractured. getFractureTime()="..tostring(selectedBodyPart:getFractureTime()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.InjuredTime));
					end
				end
			end
			if player:getModData().MoreTraitsDynamic.InjuredTime >= SandboxVars.MoreTraitsDynamic.UnwaveringDynamicCounter then
				player:getTraits():add("unwavering");
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unwavering"), true, HaloTextHelper.getColorGreen());
			end
		end
	-- Immunocompromised  / Super-Immune
		player:getModData().MoreTraitsDynamic.totalInfectionTime = player:getModData().MoreTraitsDynamic.totalInfectionTime or 0;
		-- Immunocompromised
		if SandboxVars.MoreTraitsDynamic.ImmunocompromisedDynamic == true and player:HasTrait("immunocompromised") and not player:HasTrait("superimmune") then
			for n = 0, player:getBodyDamage():getBodyParts():size() - 1 do
				if player:getBodyDamage():getBodyParts():get(n):getWoundInfectionLevel() ~= 0 then
					player:getModData().MoreTraitsDynamic.totalInfectionTime = player:getModData().MoreTraitsDynamic.totalInfectionTime + 1 / 6; -- counts hours
					--print(tostring(player:getBodyDamage():getBodyParts():get(n):getType()).." is infected. getWoundInfectionLevel()="..tostring(player:getBodyDamage():getBodyParts():get(n):getWoundInfectionLevel()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.totalInfectionTime));
				end
			end
			if player:getModData().MoreTraitsDynamic.totalInfectionTime >= SandboxVars.MoreTraitsDynamic.ImmunocompromisedDynamicInfectionTime then
				player:getTraits():remove("immunocompromised");
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unwavering"), false, HaloTextHelper.getColorGreen());
			end
		end
		-- Super-Immune
		if SandboxVars.MoreTraitsDynamic.SuperImmuneDynamic == true and not player:HasTrait("superimmune") and not player:HasTrait("immunocompromised") then
			for n = 0, player:getBodyDamage():getBodyParts():size() - 1 do
				if player:getBodyDamage():getBodyParts():get(n):getWoundInfectionLevel() ~= 0 then
					player:getModData().MoreTraitsDynamic.totalInfectionTime = player:getModData().MoreTraitsDynamic.totalInfectionTime + 1 / 6; -- counts hours
					--print(tostring(player:getBodyDamage():getBodyParts():get(n):getType()).." is infected. getWoundInfectionLevel()="..tostring(player:getBodyDamage():getBodyParts():get(n):getWoundInfectionLevel()).."; Counter: "..tostring(player:getModData().MoreTraitsDynamic.totalInfectionTime));
				end
			end
			if player:getModData().MoreTraitsDynamic.totalInfectionTime >= SandboxVars.MoreTraitsDynamic.SuperImmuneDynamicInfectionTime then
				player:getTraits():add("superimmune");
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unwavering"), true, HaloTextHelper.getColorGreen());
			end
		end
end

function MTDLeadFoot(zombie)
	local player = getPlayer();
	player:getModData().MoreTraitsDynamic = player:getModData().MoreTraitsDynamic or {};
	player:getModData().MoreTraitsDynamic.AllowLeadFootCount = player:getModData().MoreTraitsDynamic.AllowLeadFootCount or false;
	player:getModData().MoreTraitsDynamic.LeadFootCount = player:getModData().MoreTraitsDynamic.LeadFootCount or 0;
	if player:getModData().MoreTraitsDynamic.AllowLeadFootCount == true then
		if player:DistTo(zombie) <= 1 then
			--print ("Leadfoot Kill");
			getPlayer():getModData().MoreTraitsDynamic.LeadFootCount = getPlayer():getModData().MoreTraitsDynamic.LeadFootCount + 1;
		end
	end
	if player:getModData().MoreTraitsDynamic.LeadFootCount >= SandboxVars.MoreTraitsDynamic.LeadFootDynamicKill then
		if SandboxVars.MoreTraitsDynamic.LeadFootDynamic == true and not player:HasTrait("leadfoot") then
			player:getTraits():add("leadfoot");
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_leadfoot"), true, HaloTextHelper.getColorGreen());
		end
	end
end

function MTDInitializeEvents(player)
	Events.EveryOneMinute.Add(MTDEveryOneMinuteMain);
	Events.EveryTenMinutes.Add(MTDEveryTenMinutesMain);
	Events.EveryHours.Add(MTDEveryHoursMain);

	Events.LevelPerk.Add(MTDLevelPerkMain);
	Events.OnWeaponHitCharacter.Add(MTDOnWeaponHitCharacterMain);
	MTDTraitsGainsByLevel(player, "characterInitialization");
	if getActivatedMods():contains("KillCount") then
		Events.OnZombieDead.Add(MTDKillsMainExtended);
	else
		Events.OnZombieDead.Add(MTDKillsMain);
	end
end

Events.OnGameStart.Add(MTDInitializeEvents)