--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

-- adapted from 
-- http://blog.anscamobile.com/2011/09/tutorial-how-to-drag-objects/

require "inc.lib.lib-events"
require "inc.lib.lib-class"
if sprite == nil then require "sprite" end

cDraggable = {delay=50, scrollX = true, scrollY = true, usePhysics = true, dragObj=nil, className="cDraggable"}
cLibEvents.instrument(cDraggable)

function cDraggable:create( poThing)
	-- arcane lua instance creation 
	local 	oInstance = cClass.createInstance(self)

	-- initialise
	oInstance.thing = poThing
	oInstance.removed = false
	oInstance.x1=0
	oInstance.y1=0
	
	poThing:addEventListener( "touch", oInstance )
	
	-- return instance
	return oInstance
end

-- *********************************************************
-- *bug* focus moves to object higher in the zorder
function cDraggable:touch(poEvent)
	local sPhase, oDragObj
	
	sPhase = poEvent.phase 
	oDragObj = cDraggable.dragObj
	
	if sPhase == "began" then
		-- remove from animatons and remember the first place touched
		if self.usePhysics and not self.removed then
			physics.removeBody(self.thing)
			self.removed = true
		end
		self.x1 = self.thing.x    -- store x location of object
		self.y1 = self.thing.y    -- store y location of object
		cDraggable.dragObj = self
		
	elseif sPhase == "moved" then
		-- move the thing
		local x = (poEvent.x - poEvent.xStart) + oDragObj.x1
		local y = (poEvent.y - poEvent.yStart) + oDragObj.y1
		if self.scrollX then  oDragObj.thing.x =x end
		if self.scrollY then  oDragObj.thing.y = y end
	elseif (sPhase == "ended") or (sPhase == "cancelled") then
		if self.usePhysics and self.removed then 
			physics.addBody(self.thing)
			self.removed = false
		end
		cDraggable.oDragObj = nil
	end
	
	-- call table listener
	poEvent.name = "onDrag"
	poEvent.source = self
	return 	self:notify(poEvent)
end
