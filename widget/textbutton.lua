--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2013 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.widget.decorator"
require "inc.lib.lib-colours"

cTextButton = {
	className="cTextButton", 
	font=native.systemFont, fontSize=12, 
	delay=250, eventName="onTap", 
	cornerRadius=5, borderWidth=3, 
	upColour="lightgray", upBorderColour="white" ,
	downColour="yellow", downBorderColour="white" ,padding=2
}
cLibEvents.instrument(cTextButton)
cDebug.instrument(cTextButton)

--*******************************************************
function cTextButton:create( psText)
	local oInstance, oText, oDecor
	
	oInstance = cClass.createGroupInstance(self)
	oInstance:prv_init(psText)
	
	return oInstance 
end

--*******************************************************
function cTextButton:setFillColour(psColour)
	self.up.rect:setFillColor(cColours.explode(cColours:getRGB(psColour)))
end

--*******************************************************
function cTextButton:prv_init(psText)
	local oText, oDown, oUp
	
	-- create the up and down graphics
	oText = display.newText(psText,0,0,self.fontName, self.fontSize)
	oDown= cWidgetDecorator:create({
			widget=oText,
			cornerRadius=self.cornerRadius, padding=self.padding,
			backColour=cColours:getRGB(self.downColour), 
			borderColour=cColours:getRGB(self.downBorderColour), 
			borderWidth=self.borderWidth
	})
	oDown.isVisible = false
	self:insert(oDown)
	self.down = oDown
	
	oText = display.newText(psText,0,0,self.fontName, self.fontSize)
	oText:setTextColor(0,0,0)
	oUp = cWidgetDecorator:create({
		widget=oText,
		cornerRadius=self.cornerRadius,padding=self.padding,
		backColour=cColours:getRGB(self.upColour), 
		borderColour=cColours:getRGB(self.upBorderColour), 
		borderWidth=self.borderWidth
	})
	self:insert(oUp)
	self.up = oUp
	
	-- create the up and down graphics
	self.inTouch = false
	self.isUp = true
	self:addEventListener("touch", self)
end

--*******************************************************
function cTextButton:touch( poEvent)
	if not (poEvent.phase == "began") then
		return true 
	end
	
	if self.inTouch then 	return true 	end
	if not self.isUp then 	return true 	end
	
	self.up.isVisible = false
	self.down.isVisible = true
	self.inTouch = true
	self.isUp = false
	
	timer.performWithDelay(self.delay, self, 1)	-- 0 means forever
	
	return true
end

--*******************************************************
function cTextButton:timer(poEvent)
	self.up.isVisible = true
	self.down.isVisible = false
	
	self.inTouch = false
	self.isUp = true
	self:notify({name=self.eventName})
end