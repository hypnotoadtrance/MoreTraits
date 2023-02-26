require "TimedActions/ISBaseTimedAction"

ISFireplaceLightFromLiterature = ISBaseTimedAction:derive("ISFireplaceLightFromLiterature")

function ISFireplaceLightFromLiterature:isValid()
	if self.character:HasTrait("burned") and self.character:getModData().MTModVersion >= 3 then
		HaloTextHelper.addText(self.character, getText("UI_burnedstop"), HaloTextHelper.getColorRed());
		return
	end
	return self.fireplace:getObjectIndex() ~= -1  and
		self.character:getInventory():contains(self.lighter) and
		self.character:getInventory():contains(self.item) and
		not self.fireplace:isLit()
end

function ISFireplaceLightFromLiterature:waitToStart()
	self.character:faceThisObject(self.fireplace)
	return self.character:shouldBeTurning()
end

function ISFireplaceLightFromLiterature:update()
	self.character:faceThisObject(self.fireplace)
	self.item:setJobDelta(self:getJobDelta())
	self.lighter:setJobDelta(self:getJobDelta())
end

function ISFireplaceLightFromLiterature:start()
	self.item:setJobType(campingText.lightCampfire)
	self.item:setJobDelta(0.0)
	self.lighter:setJobType(campingText.lightCampfire)
	self.lighter:setJobDelta(0.0)
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")
	self.sound = self.character:playSound("FireplaceLight")
end

function ISFireplaceLightFromLiterature:stop()
	self.character:stopOrTriggerSound(self.sound)
	self.item:setJobDelta(0.0)
	self.lighter:setJobDelta(0.0)
	ISBaseTimedAction.stop(self)
end

function ISFireplaceLightFromLiterature:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.item:getContainer():setDrawDirty(true)
    self.item:setJobDelta(0.0)
	self.lighter:setJobDelta(0.0)
	self.character:getInventory():Remove(self.item)
	self.lighter:Use()
	local fuelAmt = self.fuelAmt * 60
	local fp = self.fireplace
	local args = { x = fp:getX(), y = fp:getY(), z = fp:getZ(), fuelAmt = fuelAmt }
	sendClientCommand(self.character, 'fireplace', 'light', args)

    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISFireplaceLightFromLiterature:new(character, item, lighter, fireplace, fuelAmt, time)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	-- custom fields
	o.fireplace = fireplace
	o.item = item
	o.lighter = lighter
	o.fuelAmt = fuelAmt
	return o
end
