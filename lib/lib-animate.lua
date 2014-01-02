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
require "inc.lib.animator-item"

--########################################################
--#
--########################################################
cAnimator = {eventName="onComplete", className="cAnimator", stopped = false}
cLibEvents.instrument(cAnimator)
cDebug.instrument(cAnimator)

function cAnimator:create( psAnimName)
	if not psAnimName then self:throw("needs a name") end
	local oInstance = cClass.createInstance(self)
	
	oInstance.commands = cStack:create( cStackModes.filo)
	oInstance.runningCommands = {}
	
	oInstance.finishedCommands = cStack:create( cStackModes.filo)
	oInstance.wait4All = false
	oInstance.completed = false
	oInstance.animSerialNo = 0
	oInstance.previousItem=nil
	oInstance.animCounter = 0
	oInstance.animName = psAnimName
	
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
		self:throw("attempt to add empty object")
	end
	if (paFinalState.time == nil) then
		self:debugOnce(DEBUG__WARN,"no time set - using default")
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
	local i, oItem
	self:debug(DEBUG__DEBUG, "stopping animator")
	
	self.stopped = true
	-- stop all running transitions
	for i =1, table.maxn(self.runningCommands) do
		oItem = self.runningCommands[i]
		if oItem then		
			oItem:stop()
			self.runningCommands[i] = nil
		end
	end

	-- apply all remaining transformations quickly
end

--*******************************************************
function cAnimator:go()
	local oItm, sState, sValue
	
	if self == nil then
		self:throw ("called .go() instead of :go()")
	end
	
	-- dont do anything if no commands
	if not self.commands.top  then 
		self:debug(DEBUG__ERROR,"no transitions to animate")
		return
	end
	
	self:debug(DEBUG__DEBUG,"Go: ", self.animName)
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
		self:throw("completed more than once!!!")
	end
	self:debug(DEBUG__DEBUG,"completed: ", self.animName)

	self.completed = true
	self.commands = nil		--clear out memory
	self:notify({ name=self.eventName })
end

-- ============================================================
-- =
-- ============================================================
function cAnimator:prv_doSetupStep(poItem)
	poItem:toFinalState()
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
	
	self:debug(DEBUG__INFO,"dispatching event: ") 
	poItem.obj:notify(oEvent)
	self:prv_doNext()
end

--*******************************************************
function cAnimator:onTransitionComplete(poEvent)
	local iSerial
	
	iSerial = poEvent.item.serialNo
	self:debug(DEBUG__DEBUG, "completed anim serial:", iSerial)
	self.animCounter = self.animCounter  - iSerial
	self.runningCommands[iSerial] = nil
	self:prv_doNext()
end

--*******************************************************
function cAnimator:prv_doNext()
	local oTopItem

	if self.stopped then
		return
	end 
	
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
		self.runningCommands[oTopItem.serialNo] = oTopItem
		oTopItem:execute()
	end
end

