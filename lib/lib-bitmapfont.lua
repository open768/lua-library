--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-class"

cBitmapFont = {
	charMapping = nil,  -- the names of the fonts om the spritedata and indexes
	spriteSheet = nil,  -- holds the loaded spritesheet
	spriteSets = nil,	-- holds spriteset for each char
	charSpacing=5,
	spaceWidth=5,
	maxHeight = -1,
	spaceWidthFactor = 0.5,
	debug=false
}

--paCharMapping is an array of chars
-- {A={ ref=spritename, dx_pre=pixels, dy_post=val, dy=val}, ... }


--*******************************************************
function cBitmapFont:create(psSpriteFile, poSpriteData, paCharMapping)
	local oInstance = cClass.createInstance("cBitmapFont", cBitmapFont)
	
	if (psSpriteFile==nil) then error("no sprite file") end
	if (poSpriteData==nil) then error("no sprite data") end
	if (paCharMapping==nil) then error("no character mapping") end
	
	oInstance:init(psSpriteFile, poSpriteData, paCharMapping)
	return oInstance 
end

--*******************************************************
function cBitmapFont:init(psSpriteFile, poSpriteData, paCharMapping)
	local oSheet, oSpriteData, aFrames, iRow, oRow, iTotalCharWidth
	
	-- load the spritesheet
	oSpriteData = poSpriteData.getSpriteSheetData() 
	if (oSpriteData  == nil) then error ("no Spritesheetdata") end
	
	oSheet = sprite.newSpriteSheetFromData( psSpriteFile, oSpriteData )
	if (oSheet == nil) then error("bad spritesheet") end
	self.spriteSheet = oSheet

	-- build a spriteset for each character
	self.spriteSets = {}
	aFrames = oSpriteData.frames
	iTotalCharWidth = 0
	for iRow=1,#aFrames do
		oRow = aFrames[iRow]
		self.spriteSets[oRow.name] =  sprite.newSpriteSet(oSheet,iRow,1)
		self.maxHeight = math.max(self.maxHeight, oRow.spriteSourceSize.height)
		iTotalCharWidth = iTotalCharWidth + oRow.spriteSourceSize.width
	end
	self.spaceWidth = (iTotalCharWidth/#aFrames) * self.spaceWidthFactor
	
	-- build the mapping
	self:checkValidMapping(paCharMapping)
	self.charMapping = paCharMapping
end

--*******************************************************
function cBitmapFont:checkValidMapping(paCharMapping)
	local oRow, sKey, oValue
	
	if type(paCharMapping) ~= "table" then error("not a table") end
	
	for sKey,oValue in pairs(paCharMapping) do
		if sKey == nil then error ("bad mapping - key missing") end
		if oValue == nil then error ("bad mapping - mapping missing for "..sKey) end
		
		if oValue.ref == nil then error ("bad mapping - ref missing for "..sKey) end
		if oValue.dx_pre == nil then error ("bad mapping - dx_pre missing for "..sKey) end
		if oValue.dx_post == nil then error ("bad mapping - dx_post missing for "..sKey) end
		if oValue.dy == nil then error ("bad mapping - dy missing for "..sKey) end
	end
end

--*******************************************************
function cBitmapFont:newText(psString)
	local oGroup
	local iX, iLen, iIndex, cCh, oSprite, oMap
	
	if type(psString) ~= 'string' then error ("not a string") end
	
	-- set up the parent group
	oGroup = display.newGroup()
	iX = 0
	iLen = psString:len()
	
	-- work through the string
	for iIndex=1, iLen,1 do
		cCh = psString:sub(iIndex,iIndex)
		if cCh == " " then
			iX = iX + self.spaceWidth
		else
			oMap,oSprite = self:_pGetSprite(cCh )
			if oMap and oSprite then
				iX = iX + oMap.dx_pre
				
				oSprite:setReferencePoint(display.TopLeftReferencePoint)
				oSprite.x = iX
				oSprite.y = oMap.dy
				oGroup:insert(oSprite )
				
				iX = iX + oSprite.contentWidth + oMap.dx_post + self.charSpacing
			end
		end
	end
	
	-- in debug mode draw a red box around the characters
	if self.debug then
		local oGraphic = display.newRect(0,0,iX,self.maxHeight)
		oGraphic:setFillColor(255,255,255,0)
		oGraphic.strokeWidth = 4
		oGraphic:setStrokeColor(255, 0, 0)
		oGroup:insert(oGraphic)
	end
	
	-- return the group
	oGroup.width = iX
	oGroup:setReferencePoint(display.CenterReferencePoint)
	return oGroup
end

--*******************************************************
function cBitmapFont:_pGetSprite(pcChar)
	local oMap, oSet, oSprite
	
	-- -- get the mapping
	oMap = self.charMapping[pcChar]
	if oMap == nil then
		print ("Char "..pcChar.." mapping is not defined")
		return nil
	end
	
	-- -- find the spriteset
	oSet = self.spriteSets[oMap.ref]
	if oSet == nil then 
		print ("no sprite with ref ".. oMap.ref)
		return nil
	end
	
	return oMap, sprite.newSprite(oSet)
end



