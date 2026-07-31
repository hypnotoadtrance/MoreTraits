local function gameMode()
	if not isClient() and not isServer() then
		return "SP"
	elseif isClient() then
		return "MP_Client"
	end
	return "MP_Server"
end

local gameMode = gameMode()

-- This should be ran only if it's SP or if it's a server process
if gameMode == "MP_Client" then
	print("MoreTraits_UCWF | Detected " .. gameMode .. " environment, skipping the file")
	return
else
	print("MoreTraits_UCWF | Detected " .. gameMode .. " environment, loading the file")
end

require("UnifiedCarryWeightFramework")
UnifiedCarryWeightFramework.registerMaxModifier({
	id = "ToadTraits.Sandbox.WeightGlobalMod",

	resolve = function(ctx)
		return {
			add = SandboxVars.MoreTraits.WeightGlobalMod or 0,
		}
	end,
})

UnifiedCarryWeightFramework.registerBaseModifier({
	id = "ToadTraits.BaseWeightAdjustmentBasedOnTrait",

	resolve = function(ctx)
		local player = ctx.player
		local bonus = 0
		if player:hasTrait(ToadTraitsRegistries.packmule) then
			local strength = player:getPerkLevel(Perks.Strength)
			bonus = (SandboxVars.MoreTraits.WeightPackMule or 10) - 8 + math.floor(strength / 5)
		elseif player:hasTrait(ToadTraitsRegistries.packmouse) then
			bonus = (SandboxVars.MoreTraits.WeightPackMouse or 6) - 8
		else
			bonus = (SandboxVars.MoreTraits.WeightDefault or 8) - 8
		end
		return {
			add = bonus,
		}
	end,
})
