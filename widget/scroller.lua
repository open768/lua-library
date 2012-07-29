--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-colours"
require "inc.lib.lib-utility"
require "inc.lib.lib-draggable"
require "inc.lib.lib-class"

cScroller = {
	className = "cScroller",
	orientation = {l=1,c=2,r=3},
	speed = 33, -- milliseconds
	dy = 10, -- pixels
	blankHeight=20,
	scrollDirection = "y",
	maxMove=10,
	stopping = false
}

--#############################################################
--#
--#############################################################
function cScroller:create( piTopMargin, piBottomMargin, psMarginColor, piSpeed, piDy)
	local oScr = utility.Screen
	local oInstance = cClass.createGroupInstance(self)

	-- set instance properties
	oInstance.topMargin = piTopMargin
	oInstance.botMargin = piBottomMargin
	oInstance.botMarginY = oScr.y+oScr.h-piBottomMargin
	oInstance.itemGroupHeight = oScr.h - piTopMargin - piBottomMargin
	oInstance.speed = piSpeed
	oInstance.dy = piDy
	oInstance.enabled = true
	
	oInstance.offScreen = {}
	oInstance.onScreen = {}
	oInstance.timerID = nil
	oInstance.autoScroll = true

	-- create the groups
	oInstance:_createGroups(psMarginColor)
	
	return oInstance
end

--*******************************************************
function cScroller:_createGroups( psMarginColor)
	local oTopRegion, oBotRegion, oScr, oMask, oItemGrp
	local oColour, oDraggable
	
	oScr = utility.Screen
	oColour = cColours:getRGB(psMarginColor)

	--create regions 
	oTopRegion = display.newRect(0,0, oScr.w, self.topMargin)
	oTopRegion:setFillColor(oColour.r, oColour.g, oColour.b)
	
	oBotRegion = display.newRect(0,0, oScr.w, self.botMargin)
	oBotRegion:setFillColor(oColour.r, oColour.g, oColour.b)
	oBotRegion:setReferencePoint(display.BottomLeftReferencePoint)
	oBotRegion.x = oScr.x
	oBotRegion.y = oScr.y + oScr.h

	self.onTopGroup = display.newGroup()
	self.onTopGroup:insert(oTopRegion)
	self.onTopGroup:insert(oBotRegion)
	
	-- where the items will go
	self.oContentGroup = display.newGroup()
	self.oContentGroup.x = 0
	self.oContentGroup.y = self.topMargin
	self.oContentGroup.width = oScr.w
	self.oContentGroup.height= self.itemGroupHeight
	
	--make the group draggable ( but handle the drag ourselves)
	oDraggable = cDraggable:create(self.oContentGroup)
	oDraggable.scrollX = false
	oDraggable.scrollY = false
	oDraggable.usePhysics = false
	oDraggable:addListener( "onDrag", self )
	
	--build groups
	self:insert(self.oContentGroup) -- used for content
	self:insert(self.onTopGroup)	-- used for mask (a fudge until masking works)
end

--#############################################################
--#
--#############################################################
function cScroller:onDrag(poEvent)
	local dy
	local sPhase = poEvent.phase
	
	if not self.enabled then return end

	if poEvent.phase  == "began" then
		self.Y1 = poEvent.y
	elseif poEvent.phase == "moved" then
		self:stop_timer()
		dy = self.Y1 - poEvent.y
		if dy >0 then
			self:moveUp(dy)
		elseif dy<0 then 
			self:moveDown(-dy)
		end
		self.Y1 = poEvent.y
	elseif 	(sPhase == "ended") or (sPhase == "cancelled") then
		if self.autoScroll then self:start() end
	end
	
	return true
end

--#############################################################
--#
--#############################################################
function cScroller:insert_item(poObj,piOrientation, psURL)
	self:do_insert(poObj,piOrientation, psURL)
	if (self.blankHeight>0) then
		self:insert_blank(self.blankHeight)
	end
end

--*******************************************************
function cScroller:insert_blank(piSize)
	local oRect
	
	--and insert a blank
	oRect = display.newRect(0,0,piSize, piSize)
	oRect:setFillColor(255,255,255,0) -- invisible spacer
	self:do_insert(oRect,self.orientation.c)
end

--*******************************************************
function cScroller:do_insert(poObj,piOrientation, psURL)
	local oScr = utility.Screen
	
	-- create callback if web link given
	if psURL then
		local fnCallback = 
			function(poEvent) 
				system.openURL(psURL) 
				return true
			end
		poObj:addEventListener("tap", fnCallback)
	end
	
	-- add item to list of offscreen items
	table.insert(self.offScreen, poObj)
	
	-- add item to display group 
	self.oContentGroup:insert(poObj)
	
	--position item
	if (piOrientation==cScroller.orientation.l) then
		poObj:setReferencePoint(display.TopLeftReferencePoint)
		poObj.x = oScr.x
	elseif(piOrientation==cScroller.orientation.r) then
		poObj:setReferencePoint(display.TopRightReferencePoint)
		poObj.x = oScr.x + oScr.w
	else
		poObj:setReferencePoint(display.TopLeftReferencePoint)
		poObj.x = oScr.Centre.x - poObj.contentWidth/2
	end
	
	--place in the bottom margin and make invisible
	--poObj.y = self.botMarginY
	poObj.y = self.itemGroupHeight
	poObj.isVisible = false
end 

--#############################################################
--#
--#############################################################
function cScroller:start()
	if not self.enabled then return end
	if not self.autoScroll then return end
	if self.timerID then 	return 	end
	self.stopping = false
	
	if #(self.offScreen)==0 and #(self.onScreen)==0 then
		error ("no objects to scroll")
	else
		self.timerID  = timer.performWithDelay(self.speed, self,0)
	end
end

--*******************************************************
function cScroller:stop()
	self.stopping = true
	self:stop_timer()
end

--*******************************************************
function cScroller:stop_timer()
	if self.timerID then
		timer.cancel(self.timerID)
		self.timerID = nil
	end
end

--*******************************************************
function cScroller:timer(poEvent)
	if self.stopping  then  return end
	self:_moveUp(self.dy)
end

--#############################################################
--#
--#############################################################
function cScroller:moveDown(piDy)
	while piDy > 0 do
		if self.stopping  then  return end
		
		self:_moveDown(math.min(piDy,self.maxMove ))
		piDy  = piDy - self.maxMove 
	end
end

--*******************************************************
function cScroller:_moveDown( piDy)
	local oObj, oTopObj, oNewObj, i, iTopIndex, iBotIndex, bGetObj
	
	-- add an object to the top of the onscreen objects if necc
	iTopIndex = #(self.onScreen);
	if iBottomIndex == 0 then
		bGetObj = true
	else
		oTopObj = self.onScreen [1]
		bGetObj  = (oTopObj.y > 0)
	end
	
	if bGetObj  then
		iBotIndex = #(self.offScreen)
		oNewObj= table.remove(self.offScreen,iBotIndex)
		oNewObj.y = -oNewObj.contentHeight
		table.insert(self.onScreen, 1, oNewObj)
		oNewObj.isVisible = true
	end
	
	-- move the onscreen objects down
	for i = #(self.onScreen),1,-1 do
		oObj = self.onScreen[i]
		oObj.y = oObj.y + piDy
		if (oObj.y  > self.itemGroupHeight ) then
			table.remove(self.onScreen, i)
			table.insert(self.offScreen, 1, oObj)
			oObj.isVisible = false
		end
	end
end

--*******************************************************
function cScroller:moveUp(piDy)
	while piDy > 0 do
		if self.stopping  then  return end
		self:_moveUp(math.min(piDy,self.maxMove ))
		piDy  = piDy - self.maxMove 
	end
end

--*******************************************************
function cScroller:_moveUp( piDy)
	local oObj, oBotObj, oNewObj, i, iBottomIndex, bGetObj
	
	-- add an object to the bottom of the onscreen objects if necc
	iBottomIndex = #(self.onScreen);
	if iBottomIndex == 0 then
		bGetObj = true
	else
		oBotObj = self.onScreen [iBottomIndex]
		bGetObj  = ((oBotObj.y + oBotObj.contentHeight) < self.itemGroupHeight )
	end
	
	if bGetObj  then
		oNewObj= table.remove(self.offScreen,1)
		oNewObj.y = self.itemGroupHeight
		table.insert(self.onScreen, oNewObj)
		oNewObj.isVisible = true
	end
	
	-- move the onscreen objects up
	for i = #(self.onScreen),1,-1 do

		oObj = self.onScreen[i]
		oObj.y = oObj.y - piDy
		if oObj.y + oObj.contentHeight  < 0 then
			table.remove(self.onScreen, i)
			table.insert(self.offScreen, oObj)
			oObj.isVisible = false
		end
	end
	
end