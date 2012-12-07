--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-utility"
require "inc.lib.lib-class"

cMultiLineText = {
	className="cMultiLineText",
	alignMode={left=1,middle=2,right=3},
	text="",
	defaultFont = native.systemFont,
	defaultFontSize = 16, 
	defaultAlign=1
}

--[[
	USAGE
	=====
	myGroup=cMultiLineText.create({options})
		options must contain
			text, maxWidth
		optional options
			font, fontsize, align, maxHeight, colour
		

	** note that while display.newtext does have multiline capabilities, 
	you cant align the text using that, or get fine control. And as 
	you dont have the source you cant modify it to do what you want.
	with this code - you have the source = you have the flexiblity
--]]

--########################################################
--#
--########################################################
function cMultiLineText.create(paOptions)
	if not paOptions then	error "multiline text must have some properties" end
	if not paOptions.text then	error "multiline text: text mandatory" end
	if not paOptions.maxWidth then	error "multiline text: maxWidth mandatory" end
	-- create an instance and initialise
	local oInstance = cClass.createGroupInstance(cMultiLineText)
	oInstance:prv__Init(paOptions)
	return oInstance 
end

--*******************************************************
function cMultiLineText:prv__Init(paOptions)
	cDebug:print(DEBUG__DEBUG, "cMultiLineText: setting text ", paOptions.text)

	self.font = paOptions.font
	if not utility.isValidFont(self.font) then
		self.font= self.defaultFont
		cDebug:print(DEBUG__WARN, "cMultiLineText: setting default font:", self.font )
	end
	
	self.fontsize = paOptions.fontsize
	if self.fontsize == nil then
		self.fontsize  = self.defaultFontSize
		cDebug:print(DEBUG__WARN, "cMultiLineText: setting default fontsize: ", self.fontsize)
	end
	
	self.align = paOptions.align
	if not self.align  then
		self.align = self.defaultAlign
	end
	
	self.maxWidth = paOptions.maxWidth
	self.maxHeight = paOptions.maxHeight 
	self.textColour = paOptions.colour
	
	self:setText(paOptions.text)
end

--*******************************************************
function cMultiLineText:setText(psText)
	local oText, iY, iIndex, sFragment, sOldText, aStrings
	
	utility.removeChildren(self)
	iY = 0

	-- remember the text
	self.text = psText
	
	-- add the text
	oText = self:prv__insertText(psText, iY)
	if oText.width > self.maxWidth then
		cDebug:print(DEBUG__DEBUG, "-- wrapping")
		oText.text = ""

		aStrings = utility.splitString(psText)
		
		for iIndex=1, #aStrings do
			sFragment = aStrings[iIndex]
			sOldText = oText.text
			oText.text = sOldText..sFragment

			if oText.width > self.maxWidth then
				oText.text = sOldText 
				cDebug:print(DEBUG__DEBUG, " --text: ", oText.text )
				iY = iY + oText.height

				if self.maxHeight then
					if iY + oText.height > self.maxHeight  then
						cDebug:print(DEBUG__DEBUG, " --breaking out of loop height would exceed max")
						break
					end
				end
				
				oText = self:prv__insertText(sFragment, iY)
			end
		end
		cDebug:print(DEBUG__DEBUG, " --text: ", oText.text )
	end
	
	-- align the texts
	self:prv__alignTexts()
end

--*******************************************************
function cMultiLineText:prv__insertText(psText, piY)
	local oText, oColour
	oText = display.newText(psText, 0,piY, self.font , self.fontsize )
	oColour = self.textColour 
	if oColour ~= nil then
		oText:setTextColor(cColours.explode(oColour))
	end
	self:insert(oText )
	return oText
end

--*******************************************************
function cMultiLineText:prv__alignTexts( )
	local iChild, iY, oChild, vRefPoint
	
	if self.align == self.alignMode.right then
		vRefPoint = display.TopRightReferencePoint
	elseif self.align == self.alignMode.middle then
		vRefPoint = display.CenterReferencePoint
	else
		vRefPoint = display.TopLeftReferencePoint
	end

	iY = 0
	
	for iChild=1,self.numChildren do
		oChild = self[iChild]
		oChild:setReferencePoint(vRefPoint)
		oChild.x = 0
		oChild.y = iY
		iY = iY + oChild.height
	end
end