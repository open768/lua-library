--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2013 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

takes as a parameter and array of buttons
	{
		{text="", width=10, gap=5}
		...
	}

--]]

require "inc.widget.textbutton"
require "inc.lib.lib-colours"

--########################################################
--# CLASS
--########################################################
cTextButtonBar = {
	className="cTextButtonBar", 
	eventName="onPressText",
	
	font=native.systemFont, fontSize=30, 
	eventName="onTap"
}
cLibEvents.instrument(cTextButtonBar)
cDebug.instrument(cTextButtonBar)

--*******************************************************
function cTextButtonBar:create( paButtons)
	local oInstance, oText, oDecor
	
	oInstance = cClass.createGroupInstance(self)
	oInstance.buttons = {}
	oInstance:prv_init(paButtons)
	
	return oInstance 
end

function cTextButtonBar:get(psButton)
	local oButton
	oButton = self.buttons[psButton:lower()]
	if not oButton then self:throw("no such button:", psButton)	end
	return oButton
end

--########################################################
--# PRIVATE
--########################################################
function cTextButtonBar:prv_init( paData)
	local i, oInput, oButton, sLabel
	local x,y
	
	cTextButton.fontSize = self.fontSize
	x=0; 	y=0
	
	for i=1, #paData do
		oInput = paData[i]
		sLabel = oInput.label:lower()
		
		cTextButton.FixedWidth = oInput.width
		oButton= cTextButton:create(sLabel)
		oButton.eventName = "onTap"
		oButton.action = oInput.action
		oButton:addListener("onTap", self)
		
		if oInput.gap then 	x = x+oInput.gap end
		if oInput.bgColour then oButton:setFillColour(oInput.bgColour) end
		if oInput.textColour then oButton:setTextColour(oInput.textColour) end
		
		oButton.x = x
		oButton.y = y
		
		self:insert(oButton)
		self.buttons[sLabel] = oButton
		
		x = x+oButton.width
	end
end

--########################################################
--# EVENTS
--########################################################
function cTextButtonBar:onTap(poEvent)
	self:debug(DEBUG__DEBUG, "event ",  poEvent.obj.label)
	self:notify({name=self.eventName, label=poEvent.obj.label, action=poEvent.obj.action})
end

--*******************************************************
--*******************************************************
function cTextButtonBar:onTextButtonClick( paLabels)
end