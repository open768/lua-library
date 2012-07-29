--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.lib.lib-spritegen"
require "inc.lib.lib-events"
require "inc.lib.lib-class"

cToggleWidget = { group=nil, untoggledImg=nil, toggledImage=nil, paused=false}
cLibEvents:instrument(cToggleWidget)

--*******************************************************
function cToggleWidget:create( psSprite, piWidth, piHeight)
	local oInstance 
	oInstance  = cClass.createGroupInstance("cToggleWidget", cToggleWidget)
	oInstance:init_toggle(psSprite, piWidth, piHeight)
	
	return oInstance 
end

--*******************************************************
function cToggleWidget:init_toggle( psSprite, piWidth, piHeight)
	local oOnImg, oOffImg, oSpriteGen, fnCallback
	
	if piWidth==nil then
		oSpriteGen = cSpriteGenerator:create(psSprite.img, psSprite.w, psSprite.h,2)
	else
		oSpriteGen = cSpriteGenerator:create(psSprite, piWidth, piHeight,2)
	end
	self.untoggledImg = oSpriteGen:getSprite(1)
	self.toggledImage = oSpriteGen:getSprite(2)
	self.toggledImage.isVisible = false
	
	self:insert(self.untoggledImg)
	self:insert(self.toggledImage)
	
	self:addEventListener("tap", self)
end

--*******************************************************
function cToggleWidget:tap(poEvent)
	local bToggled
	if self.paused then return end
	
	cDebug:print(DEBUG__DEBUG, "cToggleWidget:tap");
	
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
		
	cDebug:print(DEBUG__DEBUG, "cToggleWidget:toggling:",tostring(bToggled));
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
