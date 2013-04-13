--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.lib.lib-spritegen"
require "inc.lib.lib-events"
require "inc.lib.lib-class"

cToggleWidget = { group=nil, untoggledImg=nil, toggledImage=nil, paused=false, className="cToggleWidget"}
cLibEvents.instrument(cToggleWidget)
cDebug.instrument(cToggleWidget)

--*******************************************************
function cToggleWidget:create( psSprite)
	local oInstance 
	oInstance  = cClass.createGroupInstance(self)
	oInstance:prv__init_toggle(psSprite, false)
	
	return oInstance 
end

--*******************************************************
function cToggleWidget:createHoriz( psSprite)
	local oInstance 
	oInstance  = cClass.createGroupInstance(self)
	oInstance:prv__init_toggle(psSprite, true)
	
	return oInstance 
end

--*******************************************************
function cToggleWidget:prv__init_toggle( psSprite, pbIsHoriz)
	local oOnImg, oOffImg, oSpriteGen, fnCallback, tmpImage, oImg
	local oImg, iW, iH
	
	-- determine width and height
	oImg = display.newImage(psSprite)
	if pbIsHoriz then
		iW = oImg.width/2
		iH = oImg.height
	else
		iW = oImg.width
		iH = oImg.height/2
	end
	
	oImg:removeSelf()
	oImg = nil
	
	
	oSpriteGen = cSpriteGenerator:create(psSprite, iW, iH,2)
	self.untoggledImg = oSpriteGen:getSprite(1)
	self.toggledImage = oSpriteGen:getSprite(2)
	self.toggledImage.isVisible = false
	
	self.untoggledImg:setReferencePoint(display.TopLeftReferencePoint)
	self.untoggledImg.x=0
	self.untoggledImg.y=0
	self:insert(self.untoggledImg)
	
	self.toggledImage:setReferencePoint(display.TopLeftReferencePoint)
	self.toggledImage.x=0
	self.toggledImage.y=0
	self:insert(self.toggledImage)
	
	self:addEventListener("tap", self)
end

--*******************************************************
function cToggleWidget:tap(poEvent)
	local bToggled
	if self.paused then return end
	
	self:debug(DEBUG__DEBUG, "cToggleWidget:tap");
	
	bToggled = self:getToggled()
	self:toggle(not bToggled)
	return self:notify({ name="onToggle", toggled=not bToggled})
end

--*******************************************************
function cToggleWidget:toggle(pbToggled)
	local bToggled 
	
	bToggled = pbToggled
	if bToggled  == nil then 
		bToggled = not self.toggledImage.isVisible
	end
		
	self:debug(DEBUG__DEBUG, "cToggleWidget:toggling:",tostring(bToggled));
	self.toggledImage.isVisible = bToggled 
	self.untoggledImg.isVisible = not bToggled 
end

--*******************************************************
function cToggleWidget:getToggled()
	return self.toggledImage.isVisible
end

--*******************************************************
function cToggleWidget:pause()
	self.paused = true
end

--*******************************************************
function cToggleWidget:resume()
	self.paused = false
end
