--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
cFlasher = {className="cFlasher"}
require "inc.lib.lib-class"

--*******************************************************
function cFlasher:create( psOnImage, psOffImage, piInterval)
	local oGroup, oInstance
	
	oInstance = cClass.createInstance(self)

	-- set up the object
	oInstance.timerRunning = false
	oInstance.onImage = nil
	oInstance.offImage = nil
	oInstance.group = nil
	oInstance.interval = piInterval
	oInstance.isOn = false
	oInstance.timer =nil 
	
	-- create a group
	oGroup = display.newGroup()
	oInstance.onImage = display.newImage(psOnImage)
	oInstance.offImage = display.newImage(psOffImage)
	oGroup:insert(oInstance.onImage)
	oGroup:insert(oInstance.offImage)
	
	-- set groups reference point and remember
	oGroup:setReferencePoint(display.CenterReferencePoint)
	oInstance.group = oGroup
	
	-- hide the on image
	oInstance.onImage.isVisible = false
	
	return oInstance
end

--*******************************************************
function cFlasher:moveTo(piX,piY)
	self.group.x = piX
	self.group.y = piY
end

--*******************************************************
function cFlasher:on()
	if self.timerRunning then return end
	self.timerRunning = true
	
	timer.performWithDelay(self.interval, self, 0)	
end

--*******************************************************
function cFlasher:off()
	if self.timer then
		self.timerRunning = false
	end
end

--*******************************************************
function cFlasher:timer(poEvent)
	if self.timerRunning then
		if self.isOn then
			self:setVisibility(false)
			self.isOn  = false
		else
			self:setVisibility(true)
			self.isOn  = true
		end
	else
		timer.cancel( poEvent.source)
		self:setVisibility(false)
	end
end

--*******************************************************
function cFlasher:setVisibility(pbOn)
	if pbOn then
		self.onImage.isVisible = true
		self.offImage.isVisible = false
	else
		self.onImage.isVisible = false
		self.offImage.isVisible = true
	end
end
