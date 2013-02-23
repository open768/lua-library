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
	oAnim:add( oObj,  {scale=2, time=500}, {wait=true})					-- transition to scale 2 wait for completion before next step
	oAnim:add( oObj,  {x=200,y=100}, {wait=false})						-- wait after transition
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

--*******************************************************
function cAnimatorItem:create(poObj, paFinalState, poOptions)
	local oInstance = cClass.createInstance(self)
	
	oInstance.obj=poObj
	oInstance.state=paFinalState
	oInstance.wait=poOptions.wait
	oInstance.waitSFX=poOptions.waitSFX
	oInstance.isSetup=poOptions.isSetup
	oInstance.isEvent=poOptions.isEvent
	oInstance.sfx=poOptions.sfx
	oInstance.sndplayer = nil
	oInstance.animator = nil
	oInstance.inTransition = false
	oInstance.serialNo=-1
	return oInstance
end

--*******************************************************
function cAnimatorItem:execute()
	local fnCallBack = nil
	local bWait = self.wait
	
	if self.inTransition then
		cDebug:throw("cAnimatorItem - allready executing")
	end
	self.inTransition = true
	cDebug:print(DEBUG__DEBUG, "executing anim: ", self.serialNo)
	
	-- *** stream the sound if defined - will always do the transition
	if self.sfx then
		if self.waitSFX then
			fnCallBack = function(poEvent) self:onSFXEnd(poEvent) end
			self.waitSFX = true
			self.SFXEnded = false
			bWait= true
		end
		cDebug:print(DEBUG__DEBUG, "playing sound")
		self.sndplayer = cSoundPlayer:play({self.sfx}, fnCallBack )
	end
	
	-- do the animation
	self.state.onComplete = self
	transition.to(self.obj, self.state)

	-- if not waiting for the animation to finish do the next straight away
	if not bWait then self:nextItem() end
end

--*******************************************************
function cAnimatorItem:onSfxEnd(poEvent)
	self.waitSFX = false
	self.SFXEnded = true
	
	-- nextitem event will have fired if the wait flag wasnt set
	if not self.wait then
		return
	end
	
	-- if animation  is taking longer wait 
	if not self.inTransition then		
		self:nextItem()
	end
end

--*******************************************************
function cAnimatorItem:onComplete(poEvent)
	cDebug:print(DEBUG__DEBUG, "completed anim: ", self.serialNo)

	self.inTransition = false
	
	-- nextitem event will have fired if the wait flag wasnt set
	if not self.wait then
		return
	end
	
	-- if sound is taking longer then wait
	if not (self.waitSFX and (not self.SFXEnded))  then
		self:nextItem()
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

function cAnimator:create( )
	local oInstance = cClass.createInstance(self)
	
	oInstance.commands = cStack:create( cStackModes.filo)
	oInstance.wait4All = false
	oInstance.completed = false
	oInstance.animSerialNo = 0
	
	-- return the instance
	return oInstance
end

-- ============================================================
-- =
-- ============================================================
function cAnimator:add( poObj, paFinalState, poOptions)
	local oCommand
	
	if (poOptions==nil) then
		cDebug:throw("no options cAnimator.add called instead of cAnimator:add")
	end
	if (poObj==nil) then
		cDebug:throw("cAnimator - attempt to add empty object")
	end
	if (paFinalState.time) == nil then
		cDebug:printOnce(DEBUG__WARN,"cAnimator:add no time set - using default")
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
		cDebug:throw ("called cAnimator.go() instead of cAnimator:go()")
	end
	
	-- dont do anything if no commands
	if not self.commands.top  then 
		cDebug:print(DEBUG__ERROR,"no transitions to animate")
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
		cDebug:throw("Animator completed more than once!!!")
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
		cDebug:print(DEBUG__INFO,"Event:",sKey," -> ",sValue) 
	end
	
	cDebug:print(DEBUG__INFO,"cAnimator dispatching event: ") 
	poItem.obj:notify(oEvent)
	self:prv_doNext()
end

--*******************************************************
function cAnimator:onTransitionComplete(poEvent)
	cDebug:print(DEBUG__DEBUG, "cAnimator: completed anim serial:", poEvent.serialNo)
	self.animCounter = self.animCounter  - poEvent.serialNo
	self:prv_doNext()
end

--*******************************************************
function cAnimator:prv_doNext()
	local oTopItem

	if 	self.completed then
		cDebug:throw("Animator executing after completed !!!")
	end

	-- take the top item off the stack
	oTopItem = self.commands:pop() 
	
	-- if there are no more transitions we've finished
	if (not oTopItem) then
		if self.wait4All and not (self.animCounter == 0) then 
			--do nothing here
		else
			cDebug:print(DEBUG__DEBUG,"about to notify complete: inflight ", self.nInFlight)
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

