--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
local json = require ("json")
local lfs = require "lfs"
local msBreakChars ='({[ -%:;,.]})'

-- **********************************************************
-- * UTILITY CLASS 
-- **********************************************************
globals = {}
utility = {
	ZoneWidth = 20,
	GravityStrength = 10,
	OrientationGravity = {
		portrait = {x=0,y=-1},
		portraitUpsideDown = {x=0,y=1},
		landscapeLeft= {x=1,y=0},
		landscapeRight = {x=-1,y=0}
	},
	Screen={x=0,y=0,w=0,h=0,Centre={x=0,y=0}}
}
local moEffects ={
	"fade",	"zoomOutIn","zoomOutInFade","zoomInOut","zoomInOutFade","flip",
	"flipFadeOutIn","zoomOutInRotate","zoomOutInFadeRotate","zoomInOutRotate",
	"zoomInOutFadeRotate","fromRight","fromLeft","fromTop","fromBottom",
	"slideLeft","slideRight","slideDown","slideUp","crossFade"}

-- ####################################################
-- # utility class methods
-- ####################################################
function utility:init() 
	-- see 
	-- http://developer.anscamobile.com/code/
	-- calculating-actual-boundaries-your-application-and-device-screen-size#comment-81516
	
	self.Screen.x= display.screenOriginX
	self.Screen.y= display.screenOriginY
	self.Screen.w= display.viewableContentWidth - (2* display.screenOriginX)
	self.Screen.h= display.viewableContentHeight - (2* display.screenOriginY)
	
	self.Screen.Centre.x= self.Screen.x + self.Screen.w/2
	self.Screen.Centre.y= self.Screen.y + self.Screen.h/2
	
	return self.Screen
end

-- **********************************************************
function utility.randomGotoEffect()
	local iRnd = math.random(#moEffects)
	return moEffects[iRnd]
end

-- **********************************************************
-- make a zone 
-- cant make a concave shape as this confuses the physics engine
-- so has to be broken into a group
function utility:makeScreenZone( piDelta, pbIsPhysics, pfnEventHandler)
	local i, oGroup
	local x1,y1,x2,y2, iWidth
	local iAngle
	
	cDebug:print(DEBUG__INFO, "making screen zone" )
	
	-- corners of the zone 
	x1=self.Screen.x+piDelta
	y1=self.Screen.y+piDelta
	x2 = x1+ self.Screen.w - (2*piDelta) 
	y2 = y1+ self.Screen.h - (2*piDelta) 
	aZone = { 
		{x=x1,y=y1}, {x=x2,y=y1}, 
		{x=x2,y=y2}, {x=x1,y=y2}
	}
	
	-- construct graphical object
	oGroup = display.newGroup()

	-- working along each edge of the zone
	iAngle = 270
	for i=1,4 do
		local aRect = {}
		local oP1,oP2,iw,ih,iAmount 
		local oRect
		
		-- find corners of each rectangle
		oP1 = aZone[i]
		if i<4 then
			oP2 = aZone[i+1]
		else
			oP2 = aZone[1]
		end
		iw = oP2.x - oP1.x + self.ZoneWidth * math.cos (math.rad(iAngle))
		ih = oP2.y - oP1.y + self.ZoneWidth * math.sin (math.rad(iAngle))
		
		-- create graphics object
		oRect = utility.NewRect(oP1.x, oP1.y, iw,ih)
		oRect:setFillColor( 255, 0,0)	
		oGroup:insert(oRect)
		
		if pbIsPhysics then
			physics.addBody( oRect, "static" )
		end
		
		--set callback for collision ( table listener)
		--oRect:addEventListener(  "collision", pfnEventHandler  ) 
		if pfnEventHandler then
			oRect.collision = pfnEventHandler    
			oRect:addEventListener(  "collision", oRect ) 
		end

		-- get ready for next boundary
		iAngle = iAngle + 90
	end
		
	-- return the group
	return oGroup
end

-- **********************************************************
function utility:makeACross(piSize, piWidth)
	local oLine
	local cx,cy = self.Screen.Centre.x, self.Screen.Centre.y
	
	oLine = display.newLine(cx-piSize, cy+piSize, cx+piSize, cy-piSize)
	oLine:setColor(255,0,0,255)
	oLine.width = piWidth
	
	oLine = display.newLine(cx-piSize, cy-piSize, cx+piSize, cy+piSize)
	oLine:setColor(255,0,0,255)
	oLine.width = piWidth

end

-- **********************************************************
--bug in box2d when rectangle has negative width or height, causes colliion to stop
function utility.NewRect(piX, piY, piW, piH)
	local x,y,w,h
	
	x,y,w,h = piX, piY, piW, piH
	
	if w<0 then 
		x = x+w
		w = -w 
	end
	
	if h<0 then
		y = y+h
		h = -h
	end
	
	return display.newRect(x,y,w,h)
end

-- **********************************************************
-- only checks square rectangles, ignores rotation
-- doesnt use objects for speed
-- **********************************************************
function utility:isOffScreen(poObj)
	local zX1,zY1,zX2,zY2
	
	-- zone of screen area
	zX1 = self.Screen.x-poObj.width
	zY1 = self.Screen.y-poObj.height
	zX2 = self.Screen.x + self.Screen.w 
	zY2 = self.Screen.y + self.Screen.h 
	
	-- logic
	return not utility.pointInRect(poObj.x, poObj.y, zX1,zY1, zX2,zY2)
end

-- **********************************************************
function utility:FitToScreen(poObj, piScale)
	local iScale
	
	if not piScale then piScale=1.0 end
	
	-- scale to display
	iScale = math.min(
		self.Screen.w * piScale/ poObj.contentWidth,
		self.Screen.h * piScale/ poObj.contentHeight)
		
	if iScale >1 then
		poObj:scale(iScale, iScale)
	end
end

-- **********************************************************
function utility:ScaleToScreen(poObj, piScale)
	local iScale
	
	if not piScale then piScale=1.0 end
	
	-- scale to display
	iScale = math.max(
		self.Screen.w * piScale/ poObj.contentWidth,
		self.Screen.h * piScale/ poObj.contentHeight)
		
	if iScale >1 then
		poObj:scale(iScale, iScale)
	end
end

-- **********************************************************
function utility:moveToScreenCentre(poObj)

	poObj:setReferencePoint(display.CenterReferencePoint)
	poObj.x = self.Screen.Centre.x 
	poObj.y = self.Screen.Centre.y 
	
end

-- **********************************************************
-- only checks square rectangles, ignores rotation
-- doesnt use objects for speed
-- **********************************************************
function utility.pointInRect(pix,piy, pix1,piy1, pix2, piy2)
	return ((pix>pix1) and (pix<pix2) and (piy>piy1) and (piy<piy2))
end

-- *********************************************************
-- adapted from 
-- http://blog.anscamobile.com/2011/08/tutorial-exploring-json-usage-in-corona/
 function utility.loadJson ( psfilename, psFolder )
	local sPath, sData, oFile, oJson
	
	-- set default base dir if none specified
	if not psFolder then psFolder = system.ResourceDirectory; end

	-- create a file path for corona i/o
	sPath = system.pathForFile( psfilename, psFolder )

	-- io.open opens a file at path. returns nil if no file found
	local oFile = io.open( sPath, "r" )
	if oFile then
	   -- read all contents of file into a string
	   sData = oFile:read( "*a" )
	   io.close( oFile )	-- close the file after using it
	   
	   -- convert to json 
	   oJson = json.decode(sData)
	end

	return oJson
end

-- *********************************************************
-- adapted from 
 function utility.writeJson ( poData, psfilename, psFolder)
	local sPath, sData, oFile, oJson
	
	-- set default base dir if none specified
	if not psFolder then psFolder = system.DocumentsDirectory; end
	
	-- create a file path for corona i/o
	sPath = system.pathForFile( psfilename, psFolder )

	-- io.open opens a file at path. returns nil if no file found
	local oFile = io.open( sPath, "w" )
	if oFile then
	   -- convert to jSON
	   sData = json.encode(poData)
	   oFile:write( sData )
	   io.close( oFile )	-- close the file after using it
	else
		error ("couldnt write file "..psfilename)
	end
end



-- *********************************************************
function utility.isSimulator()
	return (system.getInfo("environment") == "simulator")
end

-- *********************************************************
function utility:captureStdout(psfilename)
	-- adapted from http://developer.anscamobile.com/reference/index/iooutput
	local oHandle = io.output()    -- save current file handle
	local path = system.pathForFile( psfilename, system.DocumentsDirectory  )
	io.output( path )
	oHandle:close()
end

--*******************************************************
function utility:getRandomItem(paArray)
	return paArray[math.random( #paArray)]
end

--*******************************************************
function utility.getAngle(piX, piY)
	local iRadians, iDegrees

	iRadians = math.atan2( piX, piY)
    iDegrees = (iRadians * 180 / math.pi)  + 180
	if iDegrees > 360 then iDegrees = iDegrees - 360 end
	
	return iDegrees 
end

--*******************************************************
function utility.extract(psStr, psStart, psEnd)
	local aStart, aEnd, sExtract
	local aStart = {}
	local aEnd={}
	
	aStart[1],aStart[2] = psStr:find(psStart) 
	aEnd[1],aEnd[2] = psStr:find(psEnd) 
	return psStr:sub( aStart[2]+1, aEnd[1]-1)
end

--*******************************************************
function utility.getSpriteSets(psImageFile, poSpriteData)
	local oSpriteData, oSheet, aFrames, aSpriteSets, iItem, oItem
	
	-- basic validation
	if (psImageFile==nil) then error("no image file") end
	if (poSpriteData==nil) then error("no sprite data") end

	-- get the spritesheet
	oSpriteData = poSpriteData.getSpriteSheetData() 
	if (oSpriteData  == nil) then error ("no Spritesheetdata") end
	
	oSheet = sprite.newSpriteSheetFromData( psImageFile, oSpriteData )
	if (oSheet == nil) then error("bad spritesheet") end
	
	-- build the spritesets
	aFrames = oSpriteData.frames
	aSpriteSets = {}
	for iItem=1,#aFrames do
		oItem = aFrames[iItem]
		aSpriteSets[oItem.name] =  sprite.newSpriteSet(oSheet,iItem,1)
	end
	
	return aSpriteSets
end

--*******************************************************
function utility.isValidFont(psFontName)
	local sPath,bOK = false
	
	if psFontName then 
		if utility.isNativeFont(self.options.font) then
			bOK = true
		else
			--does the file exist
			sPath = system.pathForFile(psFontName, system.ResourceDirectory)
			if utility.fileExists(sPath) then
				bOK = true
			else
				cDebug:print(DEBUG__ERROR, "font doesnt exist:",  psFontName)
			end
		end
	else
		cDebug:print(DEBUG__WARN, "isValidFont: no font name supplied:")
	end
	
	return bOk
end

--*******************************************************
function utility.fileExists(psFilename)
	return (lfs.attributes(psFilename, "dev") ~= nil)
end 

--*******************************************************
function utility.removeChildren(poGroup)
	while poGroup.numChildren >0 do
		poGroup[1]:removeSelf()
	end
end

--*******************************************************
function utility.splitString(psString)
	local aStrings = {}
	cDebug:print(DEBUG__EXTRA_DEBUG, " splitting text: ", psString)
	utility.prv__splitString(aStrings,psString)
	return aStrings
end

--*******************************************************
function utility.prv__splitString(paArray, psString)
	local iPos, sL, sR
	
	iPos = psString:find("[%s;:,-%.]")
	if iPos == nil then
		table.insert(paArray, psString)
	else
		sL = psString:sub(1,iPos)
		sR = psString:sub(iPos+1)
		cDebug:print(DEBUG__EXTRA_DEBUG, " -- ", "LHS=", sL, " RHS=", sR)

		table.insert(paArray, sL)
		utility.prv__splitString(paArray, sR)
	end
end

--*******************************************************
function utility.var( pvValue, pvDefault)
	if pvValue==nil then
		return pvDefault
	else
		return pvValue
	end
end

-- ####################################################
-- # global event listeners
-- ####################################################
--adds rotation based on orientation
local function onRotation( poEvent )
	local aVector
	
	aVector = utility.OrientationGravity[poEvent.type]
    physics.setGravity( utility.GravityStrength * aVector.x, -utility.GravityStrength * aVector.y )
end
--TODO check device has capabilities
Runtime:addEventListener( "orientation", onRotation )

--*******************************************************
--adds rotation based on accelerometer
local function onAccelerometer( poEvent )
   physics.setGravity( utility.GravityStrength * poEvent.xGravity, -utility.GravityStrength * poEvent.yGravity )
end
--TODO check device has capabilities
if not utility.isSimulator() then
	Runtime:addEventListener( "accelerometer", onAccelerometer )
end

-- ####################################################
-- # globals class methods
-- ####################################################
function globals:set(psKey, poThing)
	self[psKey] = poThing
end

function globals:get(psKey)
	return self[psKey]
end

-- ####################################################
-- # initialise
-- ####################################################
utility:init()