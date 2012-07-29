--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

cFader = {className="cFader"}
require "inc.lib.lib-class"

--*******************************************************
function cFader:create( poImage, piInterval)
	local oGroup, oInstance
	
	oInstance = cClass.createInstance(self)
	
	-- set up the object
	oInstance.image = poImage
	oInstance.interval = piInterval
	oInstance.tween =nil 
	
	oInstance:go(0)
	
	return oInstance
end

--*******************************************************
function cFader:go(piAlpha)
	self.stopped = false
	self.tween = transition.to( self.image, {time=self.interval, alpha=piAlpha, onComplete=self})
end

--*******************************************************
function cFader:onComplete()
	self.tween = nil
	if not self.stopped then
		if self.image.alpha == 0 then
			self:go(1)
		else
			self:go(0)
		end
	end
end

--*******************************************************
function cFader:stop()
	self.stopped = true
	if self.tween then
		transition.cancel(self.tween)
	end
end
