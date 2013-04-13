--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-class"
require "inc.lib.lib-animate"
require "inc.widget.multilinetext"

cWarning = { 
	className="cWarning",
	bgImage = "images/emptysign.jpg",
	border = 0.1,
	fontsize=32, 
	scaleValue=1.7,
	onClosedEvent = "onWarningClosed",
	bgTime=400,
	signTime=400,
	closeText = "tap anywhere to close",
	sound = "audio/traffic/caroops.mp3"
}
cLibEvents.instrument(cWarning)
cDebug.instrument(cWarning)

--*******************************************************
function cWarning:show(psMsg, psEvent, poListener)
	local oWarning
	
	self:debug(DEBUG__DEBUG, "showing warning: ", psMsg)

	oWarning = cWarning:prv_create()
	if psEvent ~= nil then
		oWarning.onClosedEvent = psEvent
		oWarning:addListener(psEvent, poListener)
	end
	oWarning:prv__warn(psMsg)
end

--*******************************************************
function cWarning:prv_create()
	return  cClass.createGroupInstance(self)	
end

--*******************************************************
function cWarning:prv__warn(psText)
	self.objects = {}
	self:prv__init(psText)
end

--*******************************************************
function cWarning:prv__init(psText)
	local oSignGrp, oSign, oText, oOverlay, iWidth, oAnim, oCaption
	
	oSignGrp = display.newGroup()

	-- tap event
	self:addEventListener("tap", self)
	
	-- create the gray background
	oOverlay = utility.makeOverlay()
	self:insert(oOverlay)
	self.objects.overlay = oOverlay
	
	-- create the warning sign
	oSign = display.newImage(self.bgImage)
	oSign:scale(self.scaleValue, self.scaleValue)
	oSignGrp:insert(oSign)
	oSign:setReferencePoint(display.CenterReferencePoint)
	
	-- create the white text
	iWidth = oSign.contentWidth * (1 - 2 * self.border)
	oText = cMultiLineText.create({text=psText, maxWidth=iWidth, colour=cColours:getRGB("white"), fontsize=self.fontsize})
	oSignGrp:insert(oText)
	oText:setReferencePoint(display.CenterReferencePoint)
	oText.x = oSign.x
	oText.y = oSign.y
	
	-- create the how to close text
	oCaption = display.newText(cWarning.closeText,0,0,native.systemFontBold, 24, cColours:get("white"))
	oCaption:setReferencePoint(display.TopCenterReferencePoint)
	oCaption.x = oSign.x 
	oCaption.y = oSign.y + (oSign.contentHeight/2) + oCaption.height
	oSignGrp:insert(oCaption)
	
	-- add the warning to the widget
	self:insert(oSignGrp)
	self.objects.sign= oSignGrp
	oSignGrp:setReferencePoint(display.CenterReferencePoint)
	
	-- set up the animation sequence to bring the warning to the middle of the screen
	oAnim = cAnimator:create()
	oAnim.eventName = "prv__onShow"
	oAnim:addListener("prv__onShow", self )

	oAnim:add( self.objects.overlay, {alpha=0, x=utility.Screen.Centre.x, y= utility.Screen.Centre.y}, {isSetup=true})
	oAnim:add( self.objects.sign, {x=utility.Screen.Centre.x, y= utility.Screen.h + self.objects.sign.contentHeight}, {isSetup=true})
	oAnim:add( self.objects.overlay, {alpha=0.6, width=utility.Screen.w, height=utility.Screen.h, time=self.bgTime}, {wait=true, sfx=self.sound})
	oAnim:add( self.objects.sign, { y=utility.Screen.Centre.y, time=self.signTime}, {wait=true})
	
	-- run the anim
	self.inAnim = true
	self:debug(DEBUG__DEBUG, "starting animation");
	oAnim:go()
end

--*******************************************************
function cWarning:tap()
	if not self.inAnim then
		self:prv__close()
	end
	return true
end

--*******************************************************
function cWarning:prv__onClose()
	self:debug(DEBUG__DEBUG, "closed warning");
	self.inAnim = false
	self:notify({name=self.onClosedEvent})
	self:removeSelf()
end

--*******************************************************
function cWarning:prv__onShow()
	self:debug(DEBUG__DEBUG, "displayed warning");
	self.inAnim = false
end

--*******************************************************
function cWarning:prv__close()
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
