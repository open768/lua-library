--[[
LICENSE

	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/

	Absolutely no warranties or guarantees given or implied - use at your own risk
	Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.lib.lib-events"
require "inc.lib.lib-class"

--########################################################
--#
--########################################################
cAnimatorItem = { className="cAnimatorItem" }
cLibEvents.instrument(cAnimatorItem)
cDebug.instrument(cAnimatorItem)

--*******************************************************
function cAnimatorItem:create(poObj, paFinalState, poOptions)
	local oInstance = cClass.createInstance(self)
	
	oInstance.obj=poObj
	oInstance.state=paFinalState
	oInstance.wait=poOptions.wait
	oInstance.waitSFX=poOptions.waitSFX
	oInstance.isSetup=poOptions.isSetup
	oInstance.isEvent=poOptions.isEvent
	oInstance.delay=poOptions.delay
	if oInstance.delay == nil then oInstance.delay = 0 end
	oInstance.sfx=poOptions.sfx
	oInstance.sndplayer = nil
	oInstance.animator = nil
	oInstance.inTransition = false
	oInstance.serialNo=-1
	oInstance.timerObj = nil
	oInstance.tranHandle = nil
	return oInstance
end

--*******************************************************
function cAnimatorItem:execute()
	if self.inTransition then
		self:throw("- allready executing")
	end
	self.inTransition = true
	
	if self.delay > 0 then
		self.timerObj = timer.performWithDelay(self.delay, self)
	else
		self:prv_execute()
	end
end

--*******************************************************
function cAnimatorItem:stop()
	self:debug(DEBUG__DEBUG, "stopping ",self.serialNo)
	if self.sndplayer then 		self.sndplayer:stop() 	end
	if self.tranHandle then 	transition.cancel(self.tranHandle) 	end
	self:toFinalState()
end

--*******************************************************
function cAnimatorItem:toFinalState()
	local sKey,sValue
	-- set the state to the end state
	for  sKey,sValue in pairs(self.state) do
		self.obj[sKey] = sValue
	end
end

--*******************************************************
--* PRIVATES
--*******************************************************
function cAnimatorItem:prv_execute()
	local bWait = self.wait
	
	self:debug(DEBUG__EXTRA_DEBUG, "executing anim: ", self.serialNo)
	
	-- *** stream the sound if defined - will always do the transition
	if self.sfx then
		self.sndplayer = cSoundPlayer:create({self.sfx})
		if self.waitSFX then
			self.sndplayer.eventName = "onSfxEnd"
			self.sndplayer:addListener("onSfxEnd", self) 
			self.waitSFX = true
			self.SFXEnded = false
			bWait= true
		end
		self:debug(DEBUG__DEBUG, "playing sound")
		self.sndplayer:play()
	end
	
	-- do the animation
	self.state.onComplete = self
	self.tranHandle = transition.to(self.obj, self.state)
	
	-- if not waiting for the animation to finish do the next straight away
	if not bWait then self:prv_nextItem() end
end

--*******************************************************
-- doesnt need to use notify as its slower
function cAnimatorItem:prv_nextItem()
	self.animator:onTransitionComplete({item=self})
end

--*******************************************************
--*  EVENTS
--*******************************************************
function cAnimatorItem:timer(poEvent)
	self:debug(DEBUG__EXTRA_DEBUG, "finised timer : ", self.serialNo)
	self.timerObj  = nil
	self:prv_execute()
end

--*******************************************************
function cAnimatorItem:onComplete(poEvent)

	self:debug(DEBUG__EXTRA_DEBUG, "completed anim: ", self.serialNo)
	self.inTransition = false
	self.tranHandle = nil
	
	-- if sound is taking longer then wait
	if  (self.waitSFX and not self.SFXEnded)  then
		self:debug(DEBUG__EXTRA_DEBUG, "waiting for sound to finish")
	elseif self.wait then 
		self:debug(DEBUG__EXTRA_DEBUG, "going to next item")
		self:prv_nextItem()
	else
		self:debug(DEBUG__EXTRA_DEBUG, "nothing to do")
	end
end

--*******************************************************
function cAnimatorItem:onSfxEnd(poEvent)
	self:debug(DEBUG__EXTRA_DEBUG, "completed sound: ", self.serialNo)
	self.SFXEnded = true
	self.sndplayer = nil
	
	-- if animation  is taking longer wait 
	if self.inTransition then
		self:debug(DEBUG__EXTRA_DEBUG, "waiting for animation")
	elseif self.waitSFX or self.wait then
		self:debug(DEBUG__EXTRA_DEBUG, "going to next item")
		self.waitSFX = false
		self:prv_nextItem()
	else
		self:debug(DEBUG__EXTRA_DEBUG, "nothing to do")
	end
end
