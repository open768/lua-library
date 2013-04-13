--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "sprite"
require "inc.lib.lib-draggable"
require "inc.lib.lib-utility"
require "inc.lib.lib-spritegen"
require "inc.lib.lib-events"
require "inc.lib.lib-class"

--#####################################################################
--# generic sprite manager
--#####################################################################
cSpriteTumber = { 
	className = "cSpriteTumber",
	creationInterval = 100,
	spriteSize = nil,
	timerRunning = false,
	stopping = false, 
	timerID = nil
}
cLibEvents.instrument(cSpriteTumber)
cDebug.instrument(cSpriteTumber)

--*******************************************************
function cSpriteTumber:create( psFile, piW, piH, piMaxSpriteFrames, piMaxSprites)
	local i, oSheet, oSet
	local oInstance = cClass.createGroupInstance(self)
	
	-- build the Instance
	oInstance.STmaxSprites =  piMaxSprites
	oInstance.howMany = 0
	oInstance.timerRunning = false
	oInstance.playanother = false
	oInstance.oSpriteGen = cSpriteGenerator:create(psFile, piW, piH, piMaxSpriteFrames)
	
	--trigger the animation
	oInstance:go()
	
	-- return the instance
	return oInstance
end

--*******************************************************
function cSpriteTumber:pause()
	self.stopping = true
	if self.timerID then
		timer.cancel( self.timerID ) 
	end
	self:notify({name="onPause"})
end

--*******************************************************
function cSpriteTumber:resume()
	self.stopping = false
	self:go()
end

--*******************************************************
function cSpriteTumber:go()
	local iDelay
	
	if not self:canCreate() then return end
	if self.timerRunning then return end
	self.timerRunning  = true
	
	-- waits for a random period of time before creating an object
	iDelay = math.random(cSpriteTumber.creationInterval)
	self.timerID  = timer.performWithDelay(iDelay, self,1)	
end

--*******************************************************
function cSpriteTumber:timer(poEvent)
	self:createSprite()
	self.timerRunning  = false
	if not self.stopping then 
		self:go() -- delayed loop
	end
end

--*******************************************************
function cSpriteTumber:canCreate()
	local bResult
	
	if self.stopping then
		return false
	end
	
	bResult = (self.howMany < self.STmaxSprites)
	return bResult
end

--*******************************************************
function cSpriteTumber:removeSprite(poEvent)
	if self.howMany > 0 then
		self.howMany = self.howMany -1
	end
	self:go()
end

--*******************************************************
function cSpriteTumber:createSprite()
	local oSprite, oSprite
	
	if not self:canCreate() then return end
	
	-- reduce the count of the number of available sprites
	self.howMany = self.howMany + 1
	
	-- create a random graphic from the spritesheet
	oSprite = self.oSpriteGen:getRandomSprite()
	self:insert(oSprite )
	
	oSprite = cTumblingSprite:create( oSprite)
	oSprite.parent = self
	oSprite:addListener("removeSprite", self)
	oSprite:addListener("onDrag", self)
	oSprite:addListener("onTap", self)
end

--*******************************************************
function cSpriteTumber:onDrag(poEvent)
	poEvent.name = "onDrag" --change event name
	self:notify(poEvent)
	return true
end
--*******************************************************
function cSpriteTumber:onTap(poEvent)
	poEvent.name = "onTapped"
	self:notify(poEvent)
	return true
end

--#####################################################################
--# ROADSIGN OBJ
--# needs to be an object to have an event listener
--#####################################################################
cTumblingSprite={	
	maxAngularVelocity=100,
	maxNudge=300,
	className="cTumblingSprite"
}
cLibEvents.instrument(cTumblingSprite)

function cTumblingSprite:create( poSprite)
	local oDraggable
	local oInstance = cClass.createInstance(self)
	
	-- set instance properties
	oInstance.sprite = poSprite 
	oInstance.inEnterFrame = false
	oInstance.inDrag = false
	

	-- put at a random place on the screen
	poSprite.x = math.random(utility.Screen.w)
	poSprite.y = math.random(utility.Screen.h)
		
	-- give it a random twist
	poSprite.rotation = math.random(1,359)
	
	-- add it to the physics world
	physics.addBody(poSprite)
	
	-- give it a random spin
	poSprite.angularVelocity = math.random(1,self.maxAngularVelocity)
	
	-- and a random push
	poSprite:setLinearVelocity(
		math.random(1,self.maxNudge) - (self.maxNudge/ 2) ,
		math.random(1,self.maxNudge) - (self.maxNudge/ 2)
	)
	
	-- make it draggable
	oDraggable = cDraggable:create(poSprite)
	oDraggable:addListener("onDrag", oInstance)
	poSprite:addEventListener("tap", oInstance)
	
	-- set a trigger to detect when the graphic falls off the screen
	Runtime:addEventListener( "enterFrame", oInstance )	
	
	-- return the instance
	return oInstance
end

--*******************************************************
function cTumblingSprite:tap(poEvent) 
	poEvent.name = "onTap"
	bResult = self:notify(poEvent)
	return bResult
end
--*******************************************************
function cTumblingSprite:onDrag(poEvent) 
	local bResult
	
	-- mutex
	if self.inDrag then return end
	self.inDrag = true
	
	-- bubble the event to the listener
	bResult = self:notify(poEvent)

	-- clear mutex
	self.inDrag = false
	
	return bResult
	
end

--*******************************************************
function cTumblingSprite:enterFrame(event) 
	local bResult
	
	if self.parent.stopping then
		self:debug(DEBUG__EXTRA_DEBUG, "killing tumbling sprite")
		Runtime:removeEventListener( "enterFrame", self )	
	end
	
	-- set the MUTEX
	if self.inEnterFrame then 
		return
	end
	self.inEnterFrame =true
	
	
	-- if the object is entirely outside the screen
	if utility:isOffScreen(self.sprite) then
		-- -- remove the listener
		Runtime:removeEventListener( "enterFrame", self )	
		-- -- delayed delete
		timer.performWithDelay(0, self,1)
	end
	
	-- clear the mutex
	self.inEnterFrame =false
end 

--*******************************************************
--* only kicked when object is off screen
--*******************************************************
function cTumblingSprite:timer()
	if self.parent.stopping then return end

	-- delete it from graphics
	if self.sprite then
		physics.removeBody(self.sprite)
		self.sprite:removeSelf()
		self.sprite = nil
	end
	
	-- and spawn another
	bResult = self:notify({name="removeSprite"})
end