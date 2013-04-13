--[[
LICENSE

	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/

	Absolutely no warranties or guarantees given or implied - use at your own risk
	Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
Usage
	
example usage: 
	mylistener = {}
	function mylistener:myOnCompleteAnimation(poEvent)
		print "animation finished"
	end 
	
	oAnim = cAnimator:create()										-- creates the object
	oAnim:add( obj1,  {isVisible=false}, {isSetup=true})				-- sets up obj1 to be invisible
	oAnim:add( oObj,  {x=100, y=100, isVisible=true}, {isSetup=true})	-- moves obj1 to x,y and makes visible
	oAnim:add( oObj,  {scale=2, time=500}, {wait=true})					-- wait for previous transitions and then transition to scale 2 
	oAnim:add( oObj,  {x=200,y=100}, {delay=100})						-- delay 100ms before starting
	oAnim:add( obj1,  {isVisible=false}, {sfx="my.mp3", waitSFX=true})	-- play a sound at same time - synchronise

	oAnim.wait4All = true												-- waits until all transitions are complete
	oAnim.eventName = "myOnCompleteAnimation"							-- choose the event name to fire when animation ended
	oAnim:addListener("myOnCompleteAnimation", mylistener) 
	oAnim:go( )															-- run the sequence and then invoke callback

parameters to :add function
	1	table	display object or group
	2	table	final state of object
	3	table 	options [wait,isSetup]

--]]

require "inc.lib.lib-events"
require "inc.lib.lib-class"
require "inc.lib.lib-stack"

--########################################################
--#
--########################################################
cAnimatorItem = { className="cAnimatorItem" , eventName="onTransitionComplete"}
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
function cAnimatorItem:timer(poEvent)
	self:debug(DEBUG__EXTRA_DEBUG, "finised timer : ", self.serialNo)
	self.timerObj  = nil
	self:prv_execute()
end

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
	transition.to(self.obj, self.state)
	
	-- if not waiting for the animation to finish do the next straight away
	if not bWait then self:nextItem() end
end

--*******************************************************
function cAnimatorItem:onComplete(poEvent)
	self:debug(DEBUG__EXTRA_DEBUG, "completed anim: ", self.serialNo)

	self.inTransition = false
	
	-- if sound is taking longer then wait
	if  (self.waitSFX and not self.SFXEnded)  then
		self:debug(DEBUG__EXTRA_DEBUG, "waiting for sound to finish")
	elseif self.wait then 
		self:debug(DEBUG__EXTRA_DEBUG, "going to next item")
		self:nextItem()
	else
		self:debug(DEBUG__EXTRA_DEBUG, "nothing to do")
	end
end

--*******************************************************
function cAnimatorItem:onSfxEnd(poEvent)
	self:debug(DEBUG__EXTRA_DEBUG, "completed sound: ", self.serialNo)
	self.SFXEnded = true
	
	-- if animation  is taking longer wait 
	if self.inTransition then
		self:debug(DEBUG__EXTRA_DEBUG, "waiting for animation")
	elseif self.waitSFX or self.wait then
		self:debug(DEBUG__EXTRA_DEBUG, "going to next item")
		self.waitSFX = false
		self:nextItem()
	else
		self:debug(DEBUG__EXTRA_DEBUG, "nothing to do")
	end
end

--*******************************************************
-- doesnt need to use notify as its slower
function cAnimatorItem:nextItem()
	self.animator:onTransitionComplete({serialNo=self.serialNo })
end



--########################################################
--#
--########################################################
cAnimator = {eventName="onComplete", className="cAnimator"}
cLibEvents.instrument(cAnimator)
cDebug.instrument(cAnimator)

function cAnimator:create( )
	local oInstance = cClass.createInstance(self)
	
	oInstance.commands = cStack:create( cStackModes.filo)
	oInstance.wait4All = false
	oInstance.completed = false
	oInstance.animSerialNo = 0
	oInstance.previousItem=nil
	oInstance.animCounter = 0
	
	-- return the instance
	return oInstance
end

-- ============================================================
-- =
-- ============================================================
function cAnimator:add( poObj, paFinalState, poOptions)
	local oCommand
	
	if (poOptions==nil) then
		self:throw("no options cAnimator.add called instead of cAnimator:add")
	end
	if (poObj==nil) then
		self:throw("cAnimator - attempt to add empty object")
	end
	if (paFinalState.time == nil) then
		self:debugOnce(DEBUG__WARN,"cAnimator:add no time set - using default")
	end
	
	-- increase the serial number
	self.animSerialNo = self.animSerialNo + 1
	
	-- create step object
	oCommand = cAnimatorItem:create(poObj, paFinalState, poOptions)
	oCommand.animator = self
	oCommand.serialNo = self.animSerialNo

	-- add step to stack
	self.commands:push(oCommand )
	return oCommand.serialNo
end

--*******************************************************
function cAnimator:stop()
	-- not sure this is a good idea 
	-- as dont want to leave animation in unfinished state
	-- best to apply all transformations quickly and then stop
end

--*******************************************************
function cAnimator:go()
	local oItm, sState, sValue
	
	if self == nil then
		self:throw ("called cAnimator.go() instead of cAnimator:go()")
	end
	
	-- dont do anything if no commands
	if not self.commands.top  then 
		self:debug(DEBUG__ERROR,"no transitions to animate")
		return
	end
	
	self.step=0
	self.nComplete = 0
	self.completed = false
	self.animSerialNo = 0
	self.animCounter = 0
	
	-- do each step at a time
	self:prv_doNext()
end

-- ============================================================
function cAnimator:prv_notifyComplete()
	if 	self.completed then
		self:throw("Animator completed more than once!!!")
	end

	self.completed = true
	self.commands = nil		--clear out memory
	self:notify({ name=self.eventName })
end

-- ============================================================
-- =
-- ============================================================
function cAnimator:prv_doSetupStep(poItem)
	local sKey, sValue
	
	-- *** do the setup if defined
	poItem.obj.isVisible = true
	for  sKey,sValue in pairs(poItem.state) do
		poItem.obj[sKey] = sValue
	end

	self:prv_doNext()
end

--*******************************************************
function cAnimator:prv_doEventStep(poItem)
	local sKey, sValue, oEvent
	
	oEvent = {}
	for  sKey,sValue in pairs(poItem.state) do
		oEvent[sKey] = sValue
		self:debug(DEBUG__INFO,"Event:",sKey," -> ",sValue) 
	end
	
	self:debug(DEBUG__INFO,"cAnimator dispatching event: ") 
	poItem.obj:notify(oEvent)
	self:prv_doNext()
end

--*******************************************************
function cAnimator:onTransitionComplete(poEvent)
	self:debug(DEBUG__DEBUG, "cAnimator: completed anim serial:", poEvent.serialNo)
	self.animCounter = self.animCounter  - poEvent.serialNo
	self:prv_doNext()
end

--*******************************************************
function cAnimator:prv_doNext()
	local oTopItem

	if 	self.completed then
		self:throw("Animator executing after completed !!!")
	end

	-- check if were waiting for the previous transition
	if self.previousItem and self.previousItem.wait then
		if self.animCounter > 0 then return end
	end
	
	-- take the top item off the stack
	oTopItem = self.commands:pop() 
	self.previousItem = oTopItem
	
	-- if there are no more transitions we've finished
	if (not oTopItem) then
		if self.wait4All and not (self.animCounter == 0) then 
			--do nothing here
		else
			self:debug(DEBUG__DEBUG,"about to notify complete: inflight ", self.nInFlight)
			self:prv_notifyComplete() 
		end
		return
	end
	
	-- wait for last item if wait4all
	if self.wait4All and (self.commands.top == nil) then	
		oTopItem.wait = true
	end
	
	-- do whatever is needed
	if oTopItem.isSetup then
		self:prv_doSetupStep(oTopItem)
	elseif oTopItem.isEvent then
		self:prv_doEventStep(oTopItem)
	else
		self.animCounter = self.animCounter  + oTopItem.serialNo
		oTopItem:execute()
	end
end

