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
	oAnim:add( oObj,  {scale=2, time=500}, {wait=true})						-- transition to scale 2 wait for completion before next step
	oAnim:add( oObj,  {x=200,y=100}, {wait=false})	-- transition to new x,y and wait for everything to complete

	oAnim.wait4All = true											-- waits until all transitions are complete
	oAnim.eventName = "myOnCompleteAnimation"						-- choose the event name to fire when animation ended
	oAnim:addListener("myOnCompleteAnimation", mylistener) 
	oAnim:go( )														-- run the sequence and then invoke callback

parameters to :add function
	1	table	display object or group
	2	table	final state of object
	3	table 	options [wait,isSetup]

--]]

require "inc.lib.lib-events"
require "inc.lib.lib-class"

--########################################################
--#
--########################################################
cAnimatorItem = { className="cAnimatorItem" }

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
	oInstance.mute = false
	oInstance.sndplayer = nil
	return oInstance
end

function cAnimatorItem:purge()
	if self.obj then
		self.obj:removeSelf()
		self.obj = nil
	end
end

--########################################################
--#
--########################################################
cAnimator = {eventName="onComplete", className="cAnimator"}
cLibEvents.instrument(cAnimator)

function cAnimator:create( )
	local oInstance = cClass.createInstance(self)
	
	oInstance.commands = {}
	oInstance.nComplete = 0
	oInstance.step = 0
	oInstance.autopurge = false
	oInstance.wait4All = false
	oInstance.counterEvent = cLibEvents.makeEventClosure( oInstance, "onTransitionCount")
	
	-- return the instance
	return oInstance
end

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++
function cAnimator:add( poObj, paFinalState, poOptions)
	local oCommand, iIndex
	
	if (poOptions==nil) then
		cDebug:throw("no options cAnimator.add called instead of cAnimator:add")
	end
	if (poObj==nil) then
		cDebug:throw("cAnimator - attempt to add empty object")
	end
	if (paFinalState.time) == nil then
		cDebug:printOnce(DEBUG__WARN,"cAnimator:add no time set - using default")
	end
	
	oCommand = cAnimatorItem:create(poObj, paFinalState, poOptions)
	table.insert(self.commands, oCommand )
	iIndex = table.indexOf(self.commands, oCommand)
	oCommand.index = iIndex 
end

--*******************************************************
function cAnimator:stop()
	-- not sure this is a good idea 
	-- as dont want to leave animation in unfinished state
end

--*******************************************************
function cAnimator:go()
	local oItm, sState, sValue
	
	if self == nil then
		cDebug:throw ("called cAnimator.go() instead of cAnimator:go()")
	end
	
	-- dont do anything if no commands
	if #(self.commands) == 0 then 
		cDebug:print(DEBUG__ERROR,"no transitions to animate")
		return
	end
	
	self.step=0
	self.nComplete = 0
	
	-- do each step at a time
	self:prv_doStep(1)
end

--*******************************************************
function cAnimator:stopSounds()
	self.mute = true
	if self.sndplayer then self.sndplayer:stop() end
end

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++
function cAnimator:onComplete(poEvent)
	if self.waitSFX and (not self.SFXEnded)  then
		-- nothing doing wait for sound to complete
	else
		self:prv_doStep(self.step)	
	end
end

--*******************************************************
function cAnimator:onTransitionCount(poEvent)

	if not self.commands then return end
	
	self.nComplete = self.nComplete + 1
	
	if self.wait4All and (self.nComplete >= #(self.commands)) then
		self:prv_notifyComplete()	
		return
	end
end

--*******************************************************
function cAnimator:onSFXEnd(poEvent)
	self.waitSFX = false
	self.SFXEnded = true
	self:onComplete(poEvent)
end

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++
function cAnimator:prv_notifyComplete()
	local oItem

	if self.autopurge then
		cDebug:print(DEBUG__DEBUG,"cAnimator:purging") 
		for _,oItem in pairs(self.commands) do
			oItem:purge()
		end
	end
	self.commands = nil		--clear out memory
	self:notify({ name=self.eventName })
end

--*******************************************************
function cAnimator:prv_doStep(piStep)
	local oItem, fnCallBack, sKey, sValue, oEvent, bNotify
	

	-- if gone past the end of the array we've finished
	if piStep > #(self.commands) then
		if self.wait4Alll then	
			self:onTransitionCount() 
		else
			self:prv_notifyComplete() 
		end
		return
	end
	
	-- get the thing out of the array
	oItem = self.commands[piStep]
	self.step = piStep +1  --next step

	if oItem.isSetup then
		-- *** do the setup if defined
		oItem.obj.isVisible = true
		for  sKey,sValue in pairs(oItem.state) do
			oItem.obj[sKey] = sValue
		end

		self:onComplete(nil)
	elseif oItem.isEvent then
		-- **** or is this an event
		oEvent = {}
		for  sKey,sValue in pairs(oItem.state) do
			oEvent[sKey] = sValue
			cDebug:print(DEBUG__INFO,"Event:",sKey," -> ",sValue) 
		end
		
		cDebug:print(DEBUG__INFO,"dispatching event: ") 
		oItem.obj:notify(oEvent)
		self:onComplete(nil)
	else
		-- *** stream the sound if defined
		if oItem.sfx and (not self.mute) then
			if oItem.waitSFX then
				fnCallBack = function(poEvent) self:onSFXEnd(poEvent) end
				self.waitSFX = true
				self.SFXEnded = false
			else
				fnCallBack = nil
			end
			self.sndplayer = cSoundPlayer:play({oItem.sfx}, fnCallBack )
		end
		
		--do the transition
		if  oItem.wait then
			oItem.state.onComplete = self
		else
			oItem.state.onComplete = self.counterEvent
		end
		transition.to(oItem.obj, oItem.state)

		if not oItem.wait then
			self:onComplete(nil)
		end
	end
end

