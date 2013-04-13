--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-class"
require "inc.lib.lib-animate"

cThanks = { 
	className="cThanks",
	bgImage = "images/thanks.png",
	scaleValue=0.8,
	onClosedEvent = "onThanksClosed",
	bgTime=400,
	signTime=400,
	closeText = "tap anywhere to close",
	sound = "audio/traffic/beepbeep.mp3"
}
cLibEvents.instrument(cThanks)
cDebug.instrument(cThanks)

--*******************************************************
function cThanks:show(psMsg, psEvent, poListener)
	local oThanks
	
	oThanks = cThanks:prv__create()
	if psEvent ~= nil then
		oThanks.onClosedEvent = psEvent
		oThanks:addListener(psEvent, poListener)
	end
	oThanks:prv__thank(psMsg)
end

--*******************************************************
function cThanks:prv__create()
	return  cClass.createGroupInstance(self)	
end

--*******************************************************
function cThanks:prv__thank(psMsg)
	self.objects = {}
	self:prv__init()
end

--*******************************************************
function cThanks:prv__init()
	local oSignGrp, oSign, oText, oOverlay, iWidth, oAnim, oCaption
	local iScale
	
	oSignGrp = display.newGroup()

	-- tap event
	self:addEventListener("tap", self)
	
	-- create the gray background
	oOverlay = utility.makeOverlay()
	self:insert(oOverlay)
	self.objects.overlay = oOverlay
	
	-- create the thanks sign
	oSign = display.newImage(self.bgImage)
	utility:FitToScreen(oSign, self.scaleValue)
	oSignGrp:insert(oSign)
	oSign:setReferencePoint(display.CenterReferencePoint)

	-- create the how to close text
	oCaption = display.newText(cThanks.closeText,0,0,native.systemFontBold, 24, cColours:get("white"))
	oCaption:setReferencePoint(display.TopCenterReferencePoint)
	oCaption.x = oSign.x 
	oCaption.y = oSign.y + (oSign.contentHeight/2) + oCaption.height
	oSignGrp:insert(oCaption)
	
	-- add the image to the widget
	self:insert(oSignGrp)
	self.objects.sign= oSignGrp
	oSignGrp:setReferencePoint(display.CenterReferencePoint)
	
	-- set up the animation sequence to bring the warning to the middle of the screen
	oAnim = cAnimator:create()
	oAnim.eventName = "prv__onShow"
	oAnim:addListener("prv__onShow", self )

	oAnim:add( self.objects.overlay, {alpha=0, x=utility.Screen.Centre.x, y= utility.Screen.Centre.y}, {isSetup=true})
	oAnim:add( self.objects.sign, {x=utility.Screen.Centre.x, y= utility.Screen.h + self.objects.sign.contentHeight}, {isSetup=true})
	oAnim:add( self.objects.overlay, {alpha=0.6, width=utility.Screen.w, height=utility.Screen.h, time=self.bgTime}, {wait=true})
	oAnim:add( self.objects.sign, { y=utility.Screen.Centre.y, time=self.signTime}, {wait=true})
	oAnim:add( self.objects.sign, { y=utility.Screen.Centre.y, time=100}, {wait=true, sfx=self.sound})
	
	-- run the anim
	self.inAnim = true
	self:debug(DEBUG__DEBUG, "starting animation");
	oAnim:go()
end

--*******************************************************
function cThanks:tap()
	if not self.inAnim then
		self:prv__close()
	end
	return true
end

--*******************************************************
function cThanks:prv__onClose()
	self:debug(DEBUG__DEBUG, "closed thanks");
	self.inAnim = false
	self:notify({name=self.onClosedEvent})
	self:removeSelf()
end

--*******************************************************
function cThanks:prv__onShow()
	self:debug(DEBUG__DEBUG, "displayed thanks");
	self.inAnim = false
end

--*******************************************************
function cThanks:prv__close()
	local oAnim
	
	self:debug(DEBUG__DEBUG, "closing");
	
	-- set up the animation sequence to bring the warning to the middle of the screen
	oAnim = cAnimator:create()
	oAnim.autopurge = true
	oAnim.eventName = "prv__onClose"
	oAnim:addListener("prv__onClose", self )

	oAnim:add( self.objects.sign, {y=utility.Screen.h + self.objects.sign.contentHeight, time=self.bgTime}, {wait=true})
	oAnim:add( self.objects.overlay, {alpha=0, width=100, height=100, alpha=0, time=self.signTime}, {wait=true})
	
	-- run the anim
	self.inAnim = true
	oAnim:go()
end
