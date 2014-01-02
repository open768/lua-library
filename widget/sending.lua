--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-class"

cSending = { 
	className="cSending",
	speechImg = "images/speech.png",
	dotImg = "images/dot.png",
	bgTime=400,
	signTime=200,
	textRatio = 0.8,
	dots = 6, 
	dotgap = 10
}
cLibEvents.instrument(cSending)

--*******************************************************
function cSending:create()
	local oInstance 
	
	oInstance  = cClass.createGroupInstance(self)	
	oInstance.objects = {}
	oInstance:prv_init()
	return oInstance 
end

--*******************************************************
function cSending:prv_init()
	local oSignGrp, oOverlay, oBubble, oText, oBubbleGrp, oDotGrp, iScale, iDot, oDot, iDotX
	
	-- tap event
	self:addEventListener("tap", self)
	
	-- create the gray background
	oOverlay = utility.makeOverlay()
	self:insert(oOverlay)
	
	-- create the bubble
	oBubble = display.newImage(self.speechImg)
	utility.scaleWidth(oBubble,0.8)
	oBubble:setReferencePoint(display.CenterReferencePoint)

	-- create the text
	oText = TextCandy.CreateText({	fontName = "chrome", text= "SENDING", charSpacing=-7})
	iScale = oBubble.contentWidth * self.textRatio / oText.width
	oText:setReferencePoint(display.CenterReferencePoint)
	oText:scale(iScale, iScale)
	oText.x = oBubble.x
	oText.y = oBubble.y - (oText.height/2)
	
	-- create the dots
	oDotGrp = display.newGroup()
	self.objects.dots = oDotGrp 
	iDotX = 0
	for iDot = 1, self.dots do 
		oDot = display.newImage(self.dotImg)
		oDot.x = iDotX
		oDotGrp:insert(oDot)
		iDotX = iDotX + oDot.width + self.dotgap
	end
	oText:setReferencePoint(display.BottomRightReferencePoint)
	oDotGrp:setReferencePoint(display.TopRightReferencePoint)
	oDotGrp.x = oText.x
	oDotGrp.y = oText.y + oDotGrp.height
	
	-- create the bubble group
	oBubbleGrp = display.newGroup()
	oBubbleGrp:insert(oBubble)
	oBubbleGrp:insert(oText)
	oBubbleGrp:insert(oDotGrp)
	self:insert(oBubbleGrp)
	
	-- set up the animation sequence to bring the bubble group to the middle of the screen
	oBubbleGrp:setReferencePoint(display.CenterReferencePoint)
	oAnim = cAnimator:create("sending")
	oAnim:add( oOverlay, {alpha=0, x=utility.Screen.Centre.x, y= utility.Screen.Centre.y}, {isSetup=true})
	oAnim:add( oBubbleGrp, {x=utility.Screen.Centre.x, y= utility.Screen.h + oBubbleGrp.contentHeight}, {isSetup=true})
	oAnim:add( oOverlay, {alpha=0.6, width=utility.Screen.w, height=utility.Screen.h, time=self.bgTime}, {wait=true})
	oAnim:add( oBubbleGrp, { y=utility.Screen.Centre.y, time=self.signTime}, {wait=true})
	oAnim:go()
end

--*******************************************************
-- cause taps to be ignored
function cSending:tap()
	return true
end

--*******************************************************
--* remove one of the dots
function cSending:removeDot()
	local iKids
	
	iKids = self.objects.dots.numChildren 
	if iKids >0 then
		self.objects.dots[iKids]:removeSelf()
	end
end
