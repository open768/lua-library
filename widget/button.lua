--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.widget.toggle"
require "inc.lib.lib-class"
require ("inc.lib.lib-debug")

cButtonWidget = { delay=150,  eventName = "onPress" }

--*******************************************************
function cButtonWidget:createHoriz( psSprite)
	local oInstance = cToggleWidget:createHoriz(psSprite)
	cClass.addParent(oInstance, cButtonWidget)
	oInstance:addListener("onToggle", oInstance)
	return oInstance 
end

--*******************************************************
function cButtonWidget:create( psSprite)
	local oInstance = cToggleWidget:create(psSprite)
	cClass.addParent(oInstance, cButtonWidget)
	oInstance:addListener("onToggle", oInstance)
	return oInstance 
end

--*******************************************************
function cButtonWidget:onToggle(poEvent)
	cDebug:print(DEBUG__DEBUG, "cButtonWidget:onToggle");
	if poEvent.toggled then
		cDebug:print(DEBUG__EXTRA_DEBUG, "cButtonWidget: timer started");
		timer.performWithDelay(self.delay, self,1)
	end
	return true
end

--*******************************************************
function cButtonWidget:timer(poEvent)
	cDebug:print(DEBUG__EXTRA_DEBUG, "cButtonWidget: timer fired");
	self:toggle(false)
	-- #bug# perform notify after button has returned state
	self:notify({ name=self.eventName, state=poEvent.state, target=self})
end

