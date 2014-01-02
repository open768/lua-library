--module(..., package.seeall)

if sprite == nil then require "sprite" end
if string == nil then require "string" end


--[[
----------------------------------------------------------------
TEXT CANDY FOR CORONA SDK
----------------------------------------------------------------
PRODUCT  :		TEXT CANDY EFFECTS ENGINE
VERSION  :		1.0.09
AUTHOR   :		MIKE DOGAN / X-PRESSIVE.COM
WEB SITE :		http:www.x-pressive.com
SUPPORT  :		info@x-pressive.com
PUBLISHER:		X-PRESSIVE.COM
COPYRIGHT:		(C)2011 MIKE DOGAN GAMES & ENTERTAINMENT

----------------------------------------------------------------

PLEASE NOTE:
A LOT OF HARD AND HONEST WORK HAS BEEN SPENT
INTO THIS PROJECT AND WE'RE STILL WORKING HARD
TO IMPROVE IT FURTHER.
IF YOU DID NOT PURCHASE THIS SOURCE LEGALLY,
PLEASE ASK YOURSELF IF YOU DID THE RIGHT THING AND
GET A LEGAL COPY (YOU'LL BE ABLE TO RECEIVE
ALL FUTURE UPDATES FOR FREE THEN) TO HELP
US CONTINUING OUR WORK. THE PRICE IS REALLY
FAIR. THANKS FOR YOUR SUPPORT AND APPRECIATION.

FOR FEEDBACK & SUPPORT, PLEASE CONTACT:
SUPPORT@X-PRESSIVE.COM


NB: MODIFIED BY SV to for individual character offsets- lines tagged

]]--

-- OBJECT TO HOLD LOCAL VARIABLES AND FUNCTIONS
local V = {}

----------------------------------------------------------------
-- MAY BE CHANGED: 
----------------------------------------------------------------
V.debug       = false		-- ENABLE / DISABLE CONSOLE MESSAGES
V.newLineChar = "|"		-- NEW LINE CHAR -USE THIS TO FORCE LINE BREAKS IN TEXTS



----------------------------------------------------------------
-- DO NOT CHANGE ANYTHING BELOW! 
----------------------------------------------------------------

V.Rnd  	  	= math.random
V.Ceil 	  	= math.ceil
V.Floor	  	= math.floor
V.Sin	  	= math.sin
V.Cos	  	= math.cos
V.Rad	  	= math.rad
V.Mod	  	= math.mod
V.PI 	  	= 4*math.atan(1)
V.GetTimer	= system.getTimer

V.Charsets      = {}
V.ObjectList    = {}

V.DEFORM_SHAKE      = 0
V.DEFORM_WAVE_Y     = 1
V.DEFORM_WAVE_SCALE = 2
V.DEFORM_MIRROR     = 3
V.DEFORM_ZIGZAG     = 4
V.DEFORM_SQUEEZE    = 5
V.DEFORM_CIRCLE     = 6

-- PRIVATE FUNCTIONS
local PAnimate
local PSetWrappedTextData
local PApplyProperties
local PDrawChars
local PDoDeform
local PStartInOutTransition
local PStopInOutTransition
local PRemoveInOutTransition
local PScrollbarTouched
local PMarquee

if V.debug then print(); print(); print("--> TEXT FX SYSTEM READY."); end

----------------------------------------------------------------
-- ENABLE / DISABLE DEBUG
----------------------------------------------------------------
local EnableDebug = function (state)
	V.debug = state == true and true or false
end
V.EnableDebug = EnableDebug

----------------------------------------------------------------
-- SET CHAR OFFSET
----------------------------------------------------------------
local SetCharYOffset  = function (fontName, char, offY)
	local Charset = V.Charsets[fontName] ; if Charset == nil then print("!!! TextFX.SetCharOffset(): CHARSET '"..fontName.."' NOT FOUND."); return end
	local Char    = Charset.Chars[string.byte(char)]; if Char    == nil then print("!!! TextFX.SetCharOffset(): CHAR '"..char.."' NOT INCLUDED IN CHARSET '"..fontName.."'!"); return end
	if offY ~= nil then Char.offY = offY end
end
V.SetCharYOffset = SetCharYOffset

----------------------------------------------------------------
-- LOAD A CHARSET
----------------------------------------------------------------
local AddCharset = function (name, dataFile, imageFile, charOrder, spaceWidth, charSpacing, lineSpacing)
	local Data
	local isBMF = false
	local oCharSet --SV added
	
	-- DATAFILE IS A FILE NAME? LOAD!
	if type(dataFile) == "string" then
		if string.sub(dataFile,string.len(dataFile)-3) == ".lua" then dataFile = string.sub(dataFile,1,string.len(dataFile)-4) end
		Data     = require(dataFile).getSpriteSheetData()
		if Data  == nil then print("!!! TextFX.AddCharset(): Could not find data file "..dataFile..".lua"); return end
	-- IS BMF FONT?
	elseif type(dataFile) == "table" then
		Data  = dataFile
		isBMF = true
	else
		print("!!! TextFX.AddCharset(): Could not load data file ("..dataFile..")"); return
	end
		
	if imageFile == "" then imageFile = dataFile..".png" end
	if string.sub(imageFile,string.len(imageFile)-3) ~= ".png" then imageFile = imageFile..".png" end

	local Sheet = sprite.newSpriteSheetFromData( imageFile, Data )
	   if Sheet == nil then print("!!! TextFX.AddCharset(): Could not find image file "..imageFile.."."); return end

	local Set   = sprite.newSpriteSet(Sheet, 1, string.len(charOrder))

	charOrder = string.gsub (charOrder, " ", "")-- REMOVE SPACES

	oCharSet = {}
	
	oCharSet.name        = name
	oCharSet.isVector    = false
	oCharSet.dataFile    = dataFile
	oCharSet.imageFile   = imageFile
	oCharSet.Data        = Data
	oCharSet.Sheet       = Sheet
	oCharSet.Set         = Set
	oCharSet.charString  = charOrder
	oCharSet.numChars    = string.len(charOrder)
	oCharSet.Chars       = {}
	oCharSet.lineHeight	 = 0
	oCharSet.spaceWidth	 = spaceWidth
	oCharSet.charSpacing = charSpacing
	oCharSet.lineSpacing = lineSpacing
	oCharSet.scale       = 1.0

	-- THE CHARS
	local c, n, i, frame
	for i = 1, string.len(charOrder) do
		c = string.sub (charOrder,i,i)
		n = string.byte(c)
		oCharSet.Chars[n]         = {}
		oCharSet.Chars[n].frame   = i
		oCharSet.Chars[n].offY    = 0
		oCharSet.Chars[n].offX    = 0  --SV Added
		oCharSet.Chars[n].postOffX    = 0  --SV Added
		oCharSet.Chars[n].width   = oCharSet.Data.frames[i].spriteSourceSize.width
		oCharSet.Chars[n].height  = oCharSet.Data.frames[i].spriteSourceSize.height
		oCharSet.Chars[n].imgName = oCharSet.Data.frames[i].name

		-- GET HEIGHT OF TALLEST CHAR
		if oCharSet.Chars[n].height > oCharSet.lineHeight then oCharSet.lineHeight = oCharSet.Chars[n].height end
	end

	-- SPACE CHAR DATA
	oCharSet.Chars[32] = {}
	oCharSet.Chars[32].frame  = 0
	oCharSet.Chars[32].offY   = 0
	oCharSet.Chars[32].offX    = 0  --SV Added
	oCharSet.Chars[32].postOffX    = 0  --SV Added
	oCharSet.Chars[32].width  = spaceWidth
	oCharSet.Chars[32].height = oCharSet.lineHeight

	-- NEW LINE CHAR DATA
	oCharSet.Chars[13] = {}
	oCharSet.Chars[13].frame  = 0
	oCharSet.Chars[13].offY   = 0
	oCharSet.Chars[13].offX    = 0  --SV Added
	oCharSet.Chars[13].postOffX    = 0  --SV Added
	oCharSet.Chars[13].width  = 0
	oCharSet.Chars[13].height = 0

	-- save the charset
	V.Charsets[name] = oCharSet 
	
	if V.debug then print ("--> TextFX.AddCharset(): ADDED CHARSET '"..name.."' ("..oCharSet.numChars.." CHARS)") end
end
V.AddCharset = AddCharset

----------------------------------------------------------------
-- SET individual char pre x offset 
-- entire function 
-- SV Added
----------------------------------------------------------------
local SetCharXOffset  = function (fontName, char, preOffX, postOffX)
	local Charset = V.Charsets[fontName] ; 
	
	if Charset == nil then print("!!! TextFX.SetCharOffset(): CHARSET '"..fontName.."' NOT FOUND."); return end
	local Char = Charset.Chars[string.byte(char)]; 
	if Char  == nil then print("!!! TextFX.SetCharOffset(): CHAR '"..char.."' NOT INCLUDED IN CHARSET '"..fontName.."'!"); return end
	
	if preOffX ~= nil then Char.offX = preOffX end
	if postOffX ~= nil then Char.postOffX = postOffX end
end
V.SetCharXOffset = SetCharXOffset

----------------------------------------------------------------
-- ADD A VECTOR FONT
----------------------------------------------------------------
local AddVectorFont = function (fontName, charOrder, fontSize, charSpacing, lineSpacing)

	local Temp

	V.Charsets[fontName] = {}
	V.Charsets[fontName].name        = fontName
	V.Charsets[fontName].charString	 = charOrder
	V.Charsets[fontName].numChars    = string.len(charOrder)
	V.Charsets[fontName].Chars       = {}
	V.Charsets[fontName].lineHeight	 = 0
	V.Charsets[fontName].charSpacing = charSpacing
	V.Charsets[fontName].lineSpacing = lineSpacing
	V.Charsets[fontName].scale       = 1.0
	--
	V.Charsets[fontName].isVector    = true
	V.Charsets[fontName].fontSize    = fontSize
	
	-- THE CHARS
	local c, n, i
	for i = 1, string.len(charOrder) do
		c = string.sub (charOrder,i,i)
		n = string.byte(c)
		
		Temp = display.newText( c, 0, 0, fontName, fontSize )
		V.Charsets[fontName].Chars[n] = {}
		V.Charsets[fontName].Chars[n].frame   = 0
		V.Charsets[fontName].Chars[n].offY 	  = 0
		V.Charsets[fontName].Chars[n].width   = Temp.width
		V.Charsets[fontName].Chars[n].height  = Temp.height
		V.Charsets[fontName].Chars[n].imgName = ""
		Temp:removeSelf()
		-- GET HEIGHT OF TALLEST CHAR
		if V.Charsets[fontName].Chars[n].height > V.Charsets[fontName].lineHeight then V.Charsets[fontName].lineHeight = V.Charsets[fontName].Chars[n].height end
	end

	-- SPACE CHAR DATA
	Temp = display.newText( "..", 0, 0, fontName, fontSize )
	V.Charsets[fontName].Chars[32]        = {}
	V.Charsets[fontName].Chars[32].frame  = 0
	V.Charsets[fontName].Chars[32].offY   = 0
	V.Charsets[fontName].Chars[32].width  = Temp.width
	V.Charsets[fontName].Chars[32].height = V.Charsets[fontName].lineHeight
	V.Charsets[fontName].spaceWidth	      = Temp.width
	Temp:removeSelf()

	-- NEW LINE CHAR DATA
	V.Charsets[fontName].Chars[13] = {}
	V.Charsets[fontName].Chars[13].frame  = 0
	V.Charsets[fontName].Chars[13].offY   = 0
	V.Charsets[fontName].Chars[13].width  = 0
	V.Charsets[fontName].Chars[13].height = 0

	if V.debug then print ("--> TextFX.AddVectorFont(): ADDED VECTOR FONT '"..fontName.."'") end
end
V.AddVectorFont = AddVectorFont


----------------------------------------------------------------
-- ADD A LOADED BMF FONT
----------------------------------------------------------------
local AddCharsetFromBMF = function( name, dataFile, charOrder )

	local function extract( s, p ) return string.match( s, p ), string.gsub( s, p, '', 1 ) end
	
	local Font  = 
		{
		Sheet        = {}, 
		info         = {}, 
		chars        = {}, 
		kernings     = {} 
		}
		
	local readline = io.lines( system.pathForFile( dataFile, system.ResourceDirectory ) )
	
	for line in readline do
		local t = {}
		local tag
		tag, line = extract( line, '^%s*([%a_]+)%s*' )
		while string.len( line ) > 0 do
			local k, v
			k, line = extract( line, '^([%a_]+)=' )
			if not k then break end
			v, line = extract( line, '^"([^"]*)"%s*' )
			if not v then v, line = extract( line, '^([^%s]*)%s*' ) end
			if not v then break end
			t[ k ] = v
		end

		if tag == 'info' or tag == 'common' then
			for k, v in pairs( t ) do Font.info[ k ] = v end
		elseif tag == 'page' then
			Font.Sheet = 
				{ 
				file   = t.file, 
				frames = {} 
				}
		elseif tag == 'char' then
			t.letter = string.char( t.id )
			Font.chars[ t.letter ] = {}
			for k, v in pairs( t ) do Font.chars[ t.letter ][ k ] = v end
		elseif( tag == 'kerning' ) then
			Font.kernings[ string.char( t.first ) .. string.char( t.second ) ] = 0 + t.amount
		end
	end

	-- GENERATE THE SPRITE SHEET DATA
	local c, i, Char
	for i = 1, string.len(charOrder) do
		c = string.sub (charOrder,i,i)
		Char = Font.chars[c]
		if 0 + Char.width > 0 and 0 + Char.height > 0 then
			Font.Sheet.frames[i] = 
				{
				textureRect = 
					{ 
					x      = 0  + Char.x, 
					y      = 0  + Char.y, 
					width  = -1 + Char.width, 
					height = -1 + Char.height 
					},
				spriteSourceSize = 
					{ 
					width  = 0 + Char.width, 
					height = 0 + Char.height 
					},
				spriteColorRect = 
					{ 
					x      = 0, 
					y      = 0, 
					width  = -1 + Char.width, 
					height = -1 + Char.height 
					},
				spriteTrimmed = true
				}
		end
	end
	
	AddCharset (name, Font.Sheet, Font.Sheet.file, charOrder, Font.chars[' '].xadvance, 0, Font.info.lineHeight )

	for i = 1, string.len(charOrder) do
		c = string.sub (charOrder,i,i)
		V.SetCharYOffset( name, c, Font.chars[c].yoffset )
	end
	
end
V.AddCharsetFromBMF = AddCharsetFromBMF

----------------------------------------------------------------
-- SCALE A CHARSET
----------------------------------------------------------------
local ScaleCharset = function (fontName, scale)
	local Charset = V.Charsets[fontName]
	if Charset == nil then print("!!! TextFX.ScaleCharset(): CHARSET '"..fontName.."' NOT FOUND."); return end
	
	Charset.lineHeight		= 0
	Charset.scale			= scale
	Charset.Chars[32].width = Charset.spaceWidth  * scale
	
	local c, n, i
	-- BITMAP FONT?
	if Charset.isVector ~= true then
		for i = 1, string.len(Charset.charString) do
			c = string.sub   (Charset.charString,i,i)
			n = string.byte  (c)
			Charset.Chars[n].width 	= Charset.Data.frames[i].spriteSourceSize.width  * scale
			Charset.Chars[n].height = Charset.Data.frames[i].spriteSourceSize.height * scale
			-- GET HEIGHT OF TALLEST CHAR
			if Charset.Chars[n].height > Charset.lineHeight then Charset.lineHeight = Charset.Chars[n].height end
		end
	-- VECTOR FONT?
	else
		local Temp
		for i = 1, string.len(Charset.charString) do
			c = string.sub   (Charset.charString,i,i)
			n = string.byte  (c)
			Temp = display.newText( c, 0, 0, Charset.name, Charset.fontSize * scale )
			Charset.Chars[n].width 	= Temp.width
			Charset.Chars[n].height = Temp.height
			Temp:removeSelf()
			-- GET HEIGHT OF TALLEST CHAR
			if Charset.Chars[n].height > Charset.lineHeight then Charset.lineHeight = Charset.Chars[n].height end
		end
	end
	
	-- REDRAW TEXTS
	c = 0
	for i = 1, #V.ObjectList do 
		if V.ObjectList[i].fontName == fontName then c = c + 1; V.PDrawChars(V.ObjectList[i]) end
	end

	if V.debug then print ("--> TextFX.ScaleCharset(): CHARSET SCALED. "..c.." TEXT OBJECTS AFFECTED.\n\n") end
end
V.ScaleCharset = ScaleCharset


----------------------------------------------------------------
-- REMOVE A CHARSET (ALSO DELETES ALL TEXTS USING IT)
----------------------------------------------------------------
local RemoveCharset = function (fontName)
	 if V.Charsets[fontName] == nil then print("!!! TextFX.RemoveCharset(): CHARSET '"..fontName.."' NOT FOUND."); return end

	if V.debug then print ("\n\n--> TextFX.RemoveCharset(): REMOVING CHARSET '"..fontName.."'...") end

	local i, Object

	-- REMOVE THIS CHARSET (OR ALL, IF NO NAME SPECIFIED)
	for i = #V.ObjectList, 1, -1 do
		if fontName == V.ObjectList[i].fontName then V.DeleteText(V.ObjectList[i]) end
	end
	
	-- UNLOAD FONT	
	V.Charsets[fontName].Chars 	= nil
	V.Charsets[fontName].Data 	= nil
	V.Charsets[fontName].Set   	= nil
	if V.Charsets[fontName].Sheet then V.Charsets[fontName].Sheet:dispose() end
	V.Charsets[fontName].dataFile   = nil
	V.Charsets[fontName].imageFile  = nil
	V.Charsets[fontName]		 	= nil

	if V.debug then print ("--> TextFX.RemoveCharset(): CHARSET DELETED.\n\n") end
end
V.RemoveCharset = RemoveCharset


----------------------------------------------------------------
-- REMOVE ALL
----------------------------------------------------------------
local CleanUp = function ()
	-- REMOVES ALL CHARSETS, EFFECTS, TEXTS ETC.
	local pName, pValue
	for pName,pValue in pairs(V.Charsets) do V.RemoveCharset(pName) end				
	collectgarbage("collect")
end
V.CleanUp = CleanUp


----------------------------------------------------------------
-- CREATE A TEXT OBJECT
----------------------------------------------------------------
local CreateText = function (Properties)

	local Charset = V.Charsets[Properties.fontName]; if Charset == nil then print("!!! TextFX.CreateText(): CHARSET "..fontName.." NOT FOUND."); return end

	local i, name, value
	
	-- CREATE GROUP
	local Group  = display.newGroup()
	Group.name   = "FXText"
	table.insert (V.ObjectList, Group)

	-- CREATE GROUP TO HOLD BACKGROUND
	local Tmp = display.newGroup()
	Group:insert(1, Tmp)

	-- CREATE GROUP TO HOLD CHARS
	local Tmp = display.newGroup()
	Group:insert(2, Tmp)

	-- CREATE ORIGIN SYMBOL
	local Img	= display.newCircle(0,0,8)
	Img:setFillColor(255,255,0)
	Img.name	= "Origin"
	Group:insert(3, Img)



	-- DEFINE METHODS
	
	-- SET TEXT ------------------------------------------------
	function Group:setText (txt, wrapWidth)
		-- STOP MARQUEE ANIMATION, IF ONE
		self:stopMarquee()
		
		if wrapWidth ~= nil then self.wrapWidth = wrapWidth end
		if txt == self.text then return end
		self.text    = txt
		V.PDrawChars (self) 
	end

	-- GET TEXT ------------------------------------------------
	function Group:getText 	  	() 		return self.text end

	-- QUICK-UPDATE TEXT
	-- ONLY CHANGES THE CHAR'S ANIM FRAMES
	-- SPECIFIED TEXT MUST MATCH THE NUMBER OF EXISTING CHARS!
	function Group:updateChars(txt)
		if string.len(txt) ~= self[2].numChildren then self:setText(txt) end
		local i,c,Char
		local Charset = V.Charsets[Group.fontName]; if Charset == nil then print("!!! Text:updateChars(): CHARSET "..self.fontName.." NOT FOUND."); return end
		for i = 1, self[2].numChildren do
			c = string.sub (txt,i,i)
			if Charset.isVector then
				if Group.shadowOffX ~= 0 or Group.shadowOffY ~= 0 then
					self[2][i][1].text = c
					self[2][i][2].text = c
				else
					self[2][i].text    = c
				end
			else
				Char = Charset.Chars[ c:byte() ]
				self[2][i].currentFrame = Char.frame
			end
		end
	end
	
	-- GET NUMBER OF LINES -------------------------------------
	function Group:getNumLines	() 		return #self.wrappedLines end
	
	-- GET TEXT OF A LINE --------------------------------------
	function Group:getLine	   	(num) 	return self.wrappedLines[num] end
	
	-- GET WIDTH OF A LINE -------------------------------------
	function Group:getLineWidth	(num) 	return self.lineWidths  [num] end

	-- GET CURRENT START LINE ----------------------------------
	function Group:getScroll	() 	return self.startLine end

	-- SET FONT ------------------------------------------------
	function Group:changeFont	(fontName) 	
		local CS = V.Charsets[fontName]; if CS == nil then print("!!! TextFX:setCharset(): CHARSET "..fontName.." NOT FOUND."); return end
		self.fontName = fontName 
		if CS.charSpacing ~= nil then self.charSpacing = CS.charSpacing end
		if CS.lineSpacing ~= nil then self.lineSpacing = CS.lineSpacing end
		if CS.fontSize    ~= nil then self.fontSize	   = CS.fontSize    end
		V.PDrawChars (self) 
	end

	-- SET CURRENT START LINE ----------------------------------
	function Group:setScroll (num) 	
		self.startLine = V.Ceil(num)
		V.PDrawChars (self)
		if Group.Scrollbar ~= nil then
			self.ScrollButton.y = (self.startLine  / self.maxScroll) * (self.Scrollbar.height - self.ScrollButton.height)
			if self.startLine == 1 then self.ScrollButton.y = 0 end
		end
	end

	-- SCROLL UP / DOWN ----------------------------------------
	function Group:scroll (value) 
		self.startLine = self.startLine + V.Ceil(value)
		V.PDrawChars (self)
		if Group.Scrollbar ~= nil then
			self.ScrollButton.y = (self.startLine  / self.maxScroll) * (self.Scrollbar.height - self.ScrollButton.height)
			if self.startLine == 1 then self.ScrollButton.y = 0 end
		end
	end

	-- GET MAX SCROLL ------------------------------------------
	function Group:getMaxScroll	() 	return self.maxScroll end

	-- GET WIDTH OF A LINE -------------------------------------
	function Group:getLineWidth	(num) 	return self.lineWidths  [num] end

	-- SET TEXT ORIGIN -----------------------------------------
	function Group:setOrigin (originX, originY)
		self.originX = string.upper(originX)
		self.originY = string.upper(originY)
		V.PDrawChars (self)
	end

	-- SET TEXT FLOW -------------------------------------------
	function Group:setTextFlow (textFlow)
		self.textFlow = string.upper(textFlow)
		V.PDrawChars (self)
	end

	-- APPLY PROPERTIES ----------------------------------------
	function Group:setProperties(Properties)
		V.PApplyProperties (self, Properties)
		V.PDrawChars       (self)
	end

	-- APPLY PROPERTY ------------------------------------------
	function Group:setProperty(name, value)
		self[name]   = value
		V.PDrawChars (self)
	end

	-- GET PROPERTY --------------------------------------------
	function Group:getProperty(name)
		return self[name]
	end
	
	-- SET COLOR -----------------------------------------------
	function Group:setColor(R,G,B,A)
		if self.Color == nil then self.Color = {} end
		self.Color[1] = R ~= nil and R or 255
		self.Color[2] = G ~= nil and G or 255
		self.Color[3] = B ~= nil and B or 255
		self.Color[4] = A ~= nil and A or 255
		local i
		local n = self[2].numChildren
		for i = 1, n do 
			if Group.shadowOffX ~= 0 or Group.shadowOffY ~= 0 then
				if V.Charsets[self.fontName].isVector == true then
					self[2][i][2]:setTextColor( self.Color[1],self.Color[2],self.Color[3],self.Color[4] ) 
				elseif self[2][i][2].isEmptyLine ~= true then
					self[2][i][2]:setFillColor( self.Color[1],self.Color[2],self.Color[3], self.Color[4] )
				end
			else
				if V.Charsets[self.fontName].isVector == true then
					self[2][i]:setTextColor( self.Color[1],self.Color[2],self.Color[3],self.Color[4] ) 
				elseif self[2][i].isEmptyLine ~= true then
					self[2][i]:setFillColor( self.Color[1],self.Color[2],self.Color[3], self.Color[4] )
				end
			end
		end
		if V.debug then print ("--> FXText:setColor(): CHANGED COLOR.") end
	end

	-- VECTOR FONT: SET FONT SIZE ------------------------------
	function Group:setFontSize(fontSize)
		self.fontSize = fontSize
		if V.Charsets[self.fontName].isVector == true then
			-- UPDATE SPACE WIDTH
			Temp = display.newText( " ", 0, 0, self.fontName, fontSize )
			V.Charsets[self.fontName].Chars[32].width = Temp.width
			V.Charsets[self.fontName].spaceWidth      = Temp.width
			Temp:removeSelf()
		end
		V.PDrawChars (self)
	end

	-- VECTOR FONT: ADD DROP SHADOW ----------------------------
	function Group:addDropShadow ( offX, offY, alpha )
		if offX ~= self.shadowOffX or offY ~= self.shadowOffY or alpha ~= self.shadowAlpha then
			self.shadowOffX  = offX  ~= nil and offX or 0
			self.shadowOffY  = offY  ~= nil and offY or 0
			self.shadowAlpha = alpha ~= nil and alpha or 0
			V.PDrawChars    (self) 
			if V.debug then print ("--> FXText:addDropShadow(): SHADOW ADDED.") end
		end
	end

	-- START / STOP MARQUEE ------------------------------------
	function Group:startMarquee(charsToShow, speed, startOffset)
		self:stopMarquee()
		self.originX  		= "LEFT"
		self.startLine 		= 1
		self.linesToShow 	= 1
		self.wrapWidth 		= 0
		self.marqueeSpeed	= speed
		
		self.marqueeText	= ""
		for i = 1, string.len(self.text) do if string.sub(self.text,i,i) ~= V.newLineChar then self.marqueeText = self.marqueeText..string.sub(self.text,i,i) end end
		self.text 			= string.sub(self.marqueeText,1,charsToShow)
		self:removeDeform()
		self:removeAnimation()
		self:removeInOutTransition()
		self.nextCharPos	= charsToShow + 1; if self.nextCharPos > string.len(self.marqueeText) then self.nextCharPos = 1 end
		
		if startOffset ~= nil then self[2].x = startOffset end

		if string.sub (self.text,1,1) == " " then 
			self.charW = V.Charsets[self.fontName].spaceWidth 
		elseif self.shadowOffX ~= 0 or self.shadowOffY ~= 0 then
			self.charW = self[2][1][1].width 
		else 
			self.charW = self[2][1].width 
		end

		self.endX = -(self.charW + self.charSpacing) * V.Charsets[self.fontName].scale

		self.MarqueeTimer        = timer.performWithDelay(1, V.PMarquee, 0 )
		self.MarqueeTimer.Target = self
		if V.debug then print ("--> FXText:startMarquee(): MARQUEE STARTED.") end
	end

	function Group:stopMarquee()
		if self.MarqueeTimer ~= nil then 
			self[2].x = 0
			self[2].y = 0
			timer.cancel(self.MarqueeTimer)
			self.MarqueeTimer.Target = nil
			self.MarqueeTimer 		 = nil
		end
	end

	-- SET VISIBLE LINES ---------------------------------------
	function Group:setVisibleLines(startLine, linesToShow)
		if startLine < 1 then startLine = 1 end
		self.startLine   = startLine
		self.linesToShow = linesToShow
		V.PDrawChars    (self)
	end

	-- ADD / REMOVE BACKGROUND ---------------------------------
	function Group:addBackground ( Img, marginX, marginY, alpha, offX, offY )
		self:removeBackground()
		self[1]:insert(Img)
		Img.isBackground= true
		Img.xReference  = -Img.width  / 2
		Img.yReference  = -Img.height / 2
		Img.alpha       = alpha       ~= nil and alpha   or 1.0
		Img.marginX     = marginX     ~= nil and marginX or 0
		Img.marginY     = marginY     ~= nil and marginY or 0
		Img.offX        = offX 	      ~= nil and offX	or 0
		Img.offY        = offY 	      ~= nil and offY	or 0
		V.PDrawChars (self) 
		if V.debug then print ("--> FXText:addBackground(): BACKGROUND ADDED.") end
	end

	function Group:removeBackground ()
		while self[1].numChildren > 0 do self[1][1]:removeSelf() end 
	end

	-- APPLY DEFORMATION ---------------------------------------
	function Group:applyDeform(Properties)
		if Properties.type == nil then print("!!! FXText:applyDeform(): INVALID TYPE (nil)."); return end
		self.DeformEffect  = nil
		self.DeformEffect  = {}
		for name, value in pairs(Properties) do self.DeformEffect[name] = value end
		V.PDrawChars (self)
		if V.debug then print ("--> FXText:applyDeform(): APPLIED DEFORMATION (TYPE: "..Properties.type..").") end
	end
	
	-- REMOVE DEFORMATION --------------------------------------
	function Group:removeDeform()
		self.DeformEffect  = nil
		V.PDrawChars (self)
		if V.debug then print ("--> FXText:removeDeform(): REMOVED DEFORMATION.") end
	end
	
	-- APPLY A TRANSITION TO ALL CHARS -------------------------
	function Group:applyInOutTransition(Properties)
		if Properties == nil then print("!!! FXText:applyInOutTransition(): INVALID TYPE (nil)."); return end
		V.PRemoveInOutTransition(self)

		self.InOutEffect = {}
		for name, value in pairs(Properties) do self.InOutEffect[name] = value end
		
		-- COMPLETE LISTENER?	
		if self.InOutEffect.CompleteListener ~= nil then Runtime:addEventListener( "transitionComplete", self.InOutEffect.CompleteListener ) end
		-- START NOW?
		if self.InOutEffect.startNow then V.PStartInOutTransition(self) end

		if V.debug then print ("--> FXText:applyTransition(): APPLIED IN-OUT TRANSITION.") end
	end

	function Group:startInOutTransition()
		V.PStartInOutTransition(self)
		if V.debug then print ("--> FXText:startInOutTransition(): STARTED IN-OUT TRANSITION.") end
	end

	-- REMOVE IN-OUT TRANSITION? -------------------------------
	function Group:stopInOutTransition()
		V.PStopInOutTransition(self)
		if V.debug then print ("--> FXText:stopInOutTransition(): STOPPED IN-OUT TRANSITION.") end
	end

	function Group:removeInOutTransition()
		V.PRemoveInOutTransition(self)
		if V.debug then print ("--> FXText:removeInOutTransition(): REMOVED IN-OUT TRANSITION.") end
	end

	-- CHECK IF A TRANSITION IS RUNNING ------------------------
	function Group:transitionActive()
		if self[2] == nil then return false end
		if self.TransIn or self.TransOut or self[2][self[2].numChildren].TransIn or self[2][self[2].numChildren].TransOut or self[2][1].TransIn or self[2][1].TransOut then return true else return false end
	end

	-- APPLY ANIMATED EFFECT -----------------------------------
	function Group:applyAnimation(Properties)
		if Properties.interval == nil then Properties.interval = 1 end
		self:stopAnimation ()
		self.AnimEffect  = {}
		for name, value in pairs(Properties) do self.AnimEffect[name] = value end
		if self.AnimEffect.startNow then self:startAnimation() end
		if V.debug then print ("--> FXText:applyAnimation(): STARTED ANIMATION.") end
	end
	
	-- START ANIMATED EFFECT -----------------------------------
	function Group:startAnimation()
		if self.AnimEffect == nil then print("!!! FXText:startAnimation(): NO ANIMATION DEFINED. USE applyAnimation() FIRST."); return end
		self:stopAnimation ()

		if self.AnimEffect.charWise 	== true then
			for i = 1, self[2].numChildren do
				if self.AnimEffect.startAlpha ~= nil then Group[2][i].alpha = self.AnimEffect.startAlpha end
				self[2][i].origAlpha  	= self[2][i].alpha
				self[2][i].origXScale 	= self[2][i].xScale
				self[2][i].origYScale 	= self[2][i].yScale
				self[2][i].origRot		= self[2][i].rotation
				self[2][i].origX		= self[2][i].x
				self[2][i].origY		= self[2][i].y
			end
		else
			self.origAlpha1	= self.alpha
			if self.AnimEffect.startAlpha ~= nil then self.alpha = self.AnimEffect.startAlpha end
			self.origAlpha 	= self.alpha
			self.origXScale	= self.xScale
			self.origYScale	= self.yScale
			self.origRot	= self.rotation
			self.origX		= self.x
			self.origY		= self.y
		end

		self.AnimTimer		  	  = timer.performWithDelay(1, V.PAnimate, 0 )
		self.AnimTimer.Target 	  = self
		if V.debug then print ("--> FXText:startAnimation(): STARTED ANIMATION.") end
	end
	
	-- REMOVE ANIMATED EFFECT ----------------------------------
	function Group:stopAnimation()
		if self.AnimTimer ~= nil then 
			timer.cancel(self.AnimTimer)
			self.AnimTimer.Target = nil
			self.AnimTimer 		  = nil

			if self.AnimEffect.charWise == true then
				for i = 1, self[2].numChildren do
					self[2][i].alpha 	= self[2][i].origAlpha 
					self[2][i].xScale 	= self[2][i].origXScale
					self[2][i].yScale 	= self[2][i].origYScale
					self[2][i].rotation = self[2][i].origRot	
					self[2][i].x 		= self[2][i].origX		
					self[2][i].y 		= self[2][i].origY		
				end
			else
				self.alpha 		= self.origAlpha1
				self.xScale 	= self.origXScale
				self.yScale 	= self.origYScale
				self.rotation 	= self.origRot
				self.x 			= self.origX	
				self.y 			= self.origY
			end

			if V.debug then print ("--> FXText:stopAnimation(): STOPPED ANIMATION.") end
		end
	end

	function Group:removeAnimation()
		self:stopAnimation()
		if self.AnimEffect ~= nil then
			for name, value in pairs(self.AnimEffect) do self.AnimEffect[name] = nil end
			self.AnimEffect = nil
			if V.debug then print ("--> FXText:removeAnimation(): REMOVED ANIMATION.") end
		end
	end

	-- ADD SCROLLBAR -------------------------------------------
	function Group:addScrollbar( Properties )

		if Properties.Button 		== nil then print ("!!! FXText:addScrollbar(): NO SCROLLBUTTON IMAGE SPECIFIED."); return end
		if Properties.autoHide		== nil then Properties.autoHide 	= true end
		if Properties.scaleButton	== nil then Properties.scaleButton 	= true end
		if Properties.xOffset		== nil then Properties.xOffset	 	= 20 end
		if Properties.startLine		~= nil then self.startLine 			= Properties.startLine end
		if Properties.linesToShow	~= nil then self.linesToShow		= Properties.linesToShow end
		self:removeScrollbar()
	
		local Group 	 = display.newGroup()
			  Group.name = "Scrollbar"
		
		self:insert(4, Group)

		-- SCROLLBAR FRAME
		if Properties.FrameTop then
			Group:insert(Properties.FrameTop)
			Properties.FrameTop.yReference	= -Properties.FrameTop.height/ 2
			Properties.FrameTop.x = 0
			Properties.FrameTop.y = 0
		end

		if Properties.Frame then
			Group:insert(Properties.Frame)
			Properties.Frame.yReference	= -Properties.Frame.height/ 2
		end

		if Properties.FrameBottom then
			Group:insert(Properties.FrameBottom)
			Properties.FrameBottom.yReference	= Properties.FrameBottom.height/ 2
		end

		-- SCROLLBUTTON
		ButtonGroup 	 = display.newGroup()
		ButtonGroup.name = "Scrollbutton"
		Group:insert(ButtonGroup)
		
		if Properties.ButtonTop then
			ButtonGroup:insert(Properties.ButtonTop)
			Properties.ButtonTop.yReference	= -Properties.ButtonTop.height/ 2
			Properties.ButtonTop.x = 0
			Properties.ButtonTop.y = 0
		end
		
		ButtonGroup:insert(Properties.Button)
		Properties.Button.oHeight	 = Properties.Button.height
		Properties.Button.yReference =-Properties.Button.height/ 2

		if Properties.ButtonBottom then
			ButtonGroup:insert(Properties.ButtonBottom)
			Properties.ButtonBottom.yReference	= -Properties.ButtonBottom.height/ 2
		end
		
		ButtonGroup:addEventListener( "touch", V.PScrollbarTouched )

		self.Scrollbar    = Group
		self.ScrollButton = ButtonGroup
		for name, value in pairs(Properties) do self.Scrollbar[name] = value end
		V.PDrawChars (self)

		if V.debug then print ("--> TextFX.addScrollbar(): SCROLLBAR ADDED.") end
	end

	-- REMOVE SCROLLBAR ----------------------------------------
	function Group:removeScrollbar( )
		if self.Scrollbar 	   ~= nil then
			self.ScrollButton:removeEventListener( "touch", V.PScrollbarTouched )
			for name, value in pairs(Properties) do self.Scrollbar[name] = nil end
			self.Scrollbar:removeSelf()
			self.Scrollbar    = nil
			self.ScrollButton = nil
			V.PDrawChars (self)
		if V.debug then print ("--> TextFX.removeScrollbar(): SCROLLBAR REMOVED.") end
		end
	end

	-- HIDE SCROLLBAR ------------------------------------------
	function Group:hideScrollbar( ) if self.Scrollbar ~= nil then self.Scrollbar.isVisible = false end end

	-- SHOW SCROLLBAR ------------------------------------------
	function Group:showScrollbar( ) if self.Scrollbar ~= nil then self.Scrollbar.isVisible = true end end

	-- DELETE SELF ---------------------------------------------
	function Group:delete() V.DeleteText(self) end


	-- DRAW THE CHARS
	V.PApplyProperties (Group, Properties)
	V.PDrawChars       (Group)
	
	-- PUT INSIDE A GROUP?
	if Properties.parentGroup ~= nil then Properties.parentGroup:insert(Group) end

	if V.debug then print ("--> TextFX.CreateText(): TEXT CREATED.") end

	return Group
end
V.CreateText = CreateText


----------------------------------------------------------------
-- PRIVATE: SCROLLBAR FUNCTIONALITY
----------------------------------------------------------------
local PScrollbarTouched = function(event)

	local Obj  		  = event.target
	local Text 		  = Obj.parent.parent
	local linesToShow = Text.linesToShow ~= 0 and Text.linesToShow or #Text.wrappedLines
	local scroll, line, oldLine

	-- CAN'T SCROLL? RETURN!
	if (#Text.wrappedLines <= Text.linesToShow) or (Text.linesToShow == 0) then return true end

	-- START DRAG?
	if event.phase == "began" then
		Obj.offY = event.y - Obj.y
		Obj.drag = true
		display.getCurrentStage():setFocus( Obj )

	-- DRAGGING?
	elseif Obj.drag == true then
		if event.phase == "moved" then
			y = event.y - Obj.offY
			if y < 0 then y = 0 elseif y > Obj.parent.height - Obj.height then y = Obj.parent.height - Obj.height end
			Obj.y = y
			
			oldLine = Text.startLine
			scroll  = Obj.y / (Obj.parent.height - Obj.height) -- 0.0 - 1.0
			line    = V.Floor(scroll * Text.maxScroll)
			if line < 1 then line = 1 elseif line > Text.maxScroll then line = Text.maxScroll end
			if line ~= oldLine then Text:setVisibleLines(line, linesToShow) end
			
		-- END DRAG?
		elseif event.phase == "ended" or event.phase == "cancelled" then
			display.getCurrentStage():setFocus( nil )
			Obj.drag = false
		end
	end

	return true
end
V.PScrollbarTouched = PScrollbarTouched


----------------------------------------------------------------
-- DELETE A TEXT OBJECT
----------------------------------------------------------------
local DeleteText = function (Group)
	if Group.name ~= "FXText" then print("!!! TextFX.DeleteText(): THIS IS NOT A TEXT FX OBJECT."); return end
	local i

	-- STOP MARQUEE
	Group:stopMarquee()

	-- REMOVE SCROLLBAR
	Group:removeScrollbar()

	-- REMOVE ANIMATIONS
	Group:removeAnimation()

	-- REMOVE BACKGROUND
	Group:removeBackground()

	-- REMOVE IN-OUT TRANSITION
	V.PRemoveInOutTransition(Group)
	
	-- DELETE CHARS
	while Group[2].numChildren > 0 do Group[2][1]:removeSelf() end
	
	-- REMOVE FROM LIST
	for i, Object in ipairs(V.ObjectList) do
		if Object == Group then table.remove(V.ObjectList, i); break end
	end				
	-- CLEAN UP
	Group.wrappedLines 			= nil
	Group.lineWidths   			= nil
	Group.DeformEffect			= nil
	Group.setText 				= nil
	Group.getText 				= nil
	Group.getNumLines 			= nil
	Group.getLine				= nil
	Group.getLineWidth			= nil
	Group.setOrigin				= nil
	Group.setTexFlow			= nil
	Group.setProperties			= nil
	Group.setProperty			= nil
	Group.applyDeform   		= nil
	Group.removeDeform  		= nil
	Group.stopInOutTransition	= nil
	Group.startInOutTransition	= nil
	Group.applyInOutTransition	= nil
	Group.removeInOutTransition	= nil
	Group.startAnimation		= nil
	Group.stopAnimation			= nil
	Group.startMarquee			= nil
	Group.stopMarquee			= nil
	Group.setScroll				= nil
	Group.getScroll				= nil
	Group.scroll				= nil
	Group.addBackground			= nil
	Group.removeBackground		= nil
	Group.setColor				= nil
	Group.delete				= nil
	Group:removeSelf()
	Group = nil
	if V.debug then print ("--> TextFX.DeleteText(): TEXT DELETED. REMAINING TEXTS: "..#V.ObjectList) end
end
V.DeleteText = DeleteText


----------------------------------------------------------------
-- DELETE ALL TEXT OBJECTS
----------------------------------------------------------------
local DeleteTexts = function ()

	if V.debug then print ("\n\n--> TextFX.DeleteTexts(): DELETING ALL TEXTS...") end
	while(#V.ObjectList) > 0 do V.DeleteText(V.ObjectList[1]) end
	if V.debug then print ("--> TextFX.DeleteTexts(): DONE.\n\n") end

end
V.DeleteTexts = DeleteTexts


----------------------------------------------------------------
-- CALCUALTE WIDTH OF A TEXT LINE
----------------------------------------------------------------
local GetLineWidth = function (fontName, txt, charSpacing)
	local Charset = V.Charsets[fontName]; if Charset == nil then print("!!! TextFX.GetLineWidth(): CHARSET "..fontName.." NOT FOUND."); return end
	local i, c, Char
	local l = string.len(txt)
	local w = 0

	if charSpacing == nil then charSpacing = 0 end

	-- LOOP TEXT
	for i = 1, l do
		c    = string.sub (txt,i,i)
		Char = Charset.Chars[ string.byte(c) ]
		if Char == nil then 
			print("!!! TextFX.GetLineWidth(): CHAR '"..c.."' NOT INCLUDED IN CHARSET '"..fontName.."'!")
		elseif c ~= V.newLineChar then
			w = w + Char.width; if i < string.len(txt) then w = w + charSpacing end
		else 
			break
		end
	end
	return w
end
V.GetLineWidth = GetLineWidth








----------------------------------------------------------------
-- PRIVATE FUNCTIONS
----------------------------------------------------------------





----------------------------------------------------------------
-- PRIVATE: START AN APPLIED IN-OUT TRANSITION
----------------------------------------------------------------
local PStartInOutTransition = function(Group)
	local Trans, c, delayStep
	local duration = 0

	if Group.InOutEffect ~= nil then
		if Group.InOutEffect.restoreOnComplete == true then
			Group.origVisible= Group.isVisible
			Group.origAlpha  = Group.alpha
			Group.origXScale = Group.xScale
			Group.origYScale = Group.yScale
			Group.origRot	 = Group.rotation
			Group.origX		 = Group.x
			Group.origY		 = Group.y
		end
	end

	V.PStopInOutTransition(Group)
	

	----------------
	-- IN-TRANSITION
	----------------
	if Group.InOutEffect.AnimateFrom ~= nil then
		Trans = Group.InOutEffect.AnimateFrom

		if Group.InOutEffect.inMode == "RANDOM" then
			Trans.delay 	= Group.InOutEffect.inDelay + V.Ceil(V.Rnd()* ((Group[2].numChildren) * Group.InOutEffect.inCharDelay) - Group.InOutEffect.inCharDelay )
			delayStep		= 0
		elseif Group.InOutEffect.inMode == "LEFT_RIGHT" then
			Trans.delay 	= Group.InOutEffect.inDelay
			delayStep		= Group.InOutEffect.inCharDelay
		elseif Group.InOutEffect.inMode == "RIGHT_LEFT" then
			Trans.delay 	= Group.InOutEffect.inDelay + ((Group[2].numChildren) * Group.InOutEffect.inCharDelay) - Group.InOutEffect.inCharDelay
			delayStep		=-Group.InOutEffect.inCharDelay
		else -- "ALL"
			Trans.delay 	= Group.InOutEffect.inDelay
		end

		if Group.InOutEffect.inMode == "ALL" then
				Group.isVisible = not Group.InOutEffect.hideCharsBefore
				Trans.onStart   = function() Group.isVisible = true; if Group.InOutEffect.InSound ~= nil then audio.play( Group.InOutEffect.InSound, { channel = 0, loop = 0 } ) end end
				Trans.onComplete= function() Group.TransIn = nil end
				Group.TransIn	= transition.from (Group, Trans )
				duration 		= Group.InOutEffect.inDelay + Trans.time
		else
			for c = 1, Group[2].numChildren do
				Group[2][c].isVisible 	= not Group.InOutEffect.hideCharsBefore
				Trans.onStart     	= function() Group[2][c].isVisible = true; if Group.InOutEffect.InSound ~= nil then audio.play( Group.InOutEffect.InSound, { channel = 0, loop = 0 } ) end end
				Trans.onComplete	= function() Group[2][c].TransIn   = nil end
				Group[2][c].TransIn	= transition.from (Group[2][c], Trans )

				if Group.InOutEffect.inMode == "RANDOM" then
					Trans.delay = Group.InOutEffect.inDelay + V.Ceil(V.Rnd()* ((Group[2].numChildren) * Group.InOutEffect.inCharDelay) - Group.InOutEffect.inCharDelay )
				else
					Trans.delay = Trans.delay + delayStep
				end
			end
			duration = Group.InOutEffect.inDelay + (Group[2].numChildren)*Group.InOutEffect.inCharDelay + Trans.time
		end
	end

	-----------------
	-- OUT-TRANSITION
	-----------------
	if Group.InOutEffect.AnimateTo ~= nil then
		Trans = Group.InOutEffect.AnimateTo

		if Group.InOutEffect.outMode == "RANDOM" then
			Trans.delay 	= duration + Group.InOutEffect.outDelay + (Group[2].numChildren * Group.InOutEffect.outCharDelay + Trans.time) 
			delayStep		= 0
		elseif Group.InOutEffect.outMode == "LEFT_RIGHT" then
			Trans.delay 	= duration + Group.InOutEffect.outDelay
			delayStep		= Group.InOutEffect.outCharDelay
		elseif Group.InOutEffect.outMode == "RIGHT_LEFT" then
			Trans.delay 	= duration + Group.InOutEffect.outDelay + ((Group[2].numChildren) * Group.InOutEffect.outCharDelay) - Group.InOutEffect.outCharDelay
			delayStep		=-Group.InOutEffect.outCharDelay
		else -- "ALL"
			Trans.delay 	= duration + Group.InOutEffect.outDelay
		end

		if Group.InOutEffect.outMode == "ALL" then
			Trans.onStart 	 = function() if Group.InOutEffect.OutSound ~= nil then audio.play( Group.InOutEffect.OutSound, { channel = 0, loop = 0 } ) end end
			Trans.onComplete = function() Group.TransOut = nil; Group.isVisible = not Group.InOutEffect.hideCharsAfter end
			Group.TransOut   = transition.to (Group, Trans )
			duration 		 = Trans.delay + Trans.time --Group.InOutEffect.outDelay + Trans.time
		else
			for c = 1, Group[2].numChildren do
				Trans.onStart 	  = function() if Group.InOutEffect.OutSound ~= nil then audio.play( Group.InOutEffect.OutSound, { channel = 0, loop = 0 } ) end end
				Trans.onComplete  = function() Group[2][c].TransOut = nil; Group[2][c].isVisible = not Group.InOutEffect.hideCharsAfter end
				Group[2][c].TransOut = transition.to (Group[2][c], Trans )

				if Group.InOutEffect.outMode == "RANDOM" then
					Trans.delay = duration + Group.InOutEffect.outDelay + V.Ceil(V.Rnd()* ((Group[2].numChildren) * Group.InOutEffect.outCharDelay) - Group.InOutEffect.outCharDelay )
				else
					Trans.delay = Trans.delay + delayStep
				end
			end
			duration = duration + Group.InOutEffect.outDelay + (Group[2].numChildren)*Group.InOutEffect.outCharDelay + Trans.time
		end
	end

	-----------------------------------------
	-- AUTO-REMOVE / LOOP / COMPLETE LISTENER
	-----------------------------------------
	if Group.InOutEffect.autoRemoveText == true then 
		Group.InOutTimer = timer.performWithDelay(duration, function() if Group.InOutEffect.CompleteListener ~= nil then local event = { name = "transitionComplete", target = Group } Runtime:dispatchEvent(event) end Group:delete() end ) 
	elseif Group.InOutEffect.loop == true then 
		Group.InOutTimer = timer.performWithDelay(duration, function() if Group.InOutEffect.CompleteListener ~= nil then local event = { name = "transitionComplete", target = Group } Runtime:dispatchEvent(event) end V.PDrawChars(Group); if Group.InOutEffect.restartOnChange == false then V.PStartInOutTransition(Group) end end )
	else
		Group.InOutTimer = timer.performWithDelay(duration, function() if Group.InOutEffect.CompleteListener ~= nil then local event = { name = "transitionComplete", target = Group } Runtime:dispatchEvent(event) end end )
	end
end
V.PStartInOutTransition = PStartInOutTransition


----------------------------------------------------------------
-- PRIVATE: STOP AN APPLIED IN-OUT TRANSITION
----------------------------------------------------------------
local PStopInOutTransition = function(Group)

	local name, value

	-- IF TRANSITION STILL RUNNING, SET OBJECT TO TRANSITION END VALUES
	if Group.TransIn  ~= nil then 
		transition.cancel(Group.TransIn );
		if Group.TransIn._keysFinish ~= nil then
			for name,value in pairs(Group.TransIn._keysFinish) do Group[name] = value end
		end
		Group.TransIn = nil
	end

	if Group.TransOut  ~= nil then 
		transition.cancel(Group.TransOut );
		if Group.TransOut._keysFinish ~= nil then
			for name,value in pairs(Group.TransOut._keysFinish) do Group[name] = value end
		end
		Group.TransOut = nil
	end

	if Group.InOutEffect ~= nil then
		if Group.InOutEffect.restoreOnComplete == true then
			if Group.origVisible~= nil then Group.isVisible = Group.origVisible end
			if Group.origAlpha  ~= nil then Group.alpha		= Group.origAlpha  end
			if Group.origXScale ~= nil then Group.xScale	= Group.origXScale end
			if Group.origYScale ~= nil then Group.yScale	= Group.origYScale end
			if Group.origRot	~= nil then Group.rotation	= Group.origRot	   end
			if Group.origX		~= nil then Group.x			= Group.origX	   end
			if Group.origY		~= nil then Group.y			= Group.origY	   end
		end
	end
	
	-- NO NEED TO SET CHARS TO TRANSITION END VALUES (THEY'RE DELETED ON REDRAW ANYWAY)
	local i
	for i = 1, Group[2].numChildren do 
		if Group[2][i].TransIn  ~= nil then transition.cancel(Group[2][i].TransIn ); Group[2][i].TransIn  = nil end
		if Group[2][i].TransOut ~= nil then transition.cancel(Group[2][i].TransOut); Group[2][i].TransOut = nil end
	end

	if Group.InOutTimer ~= nil then timer.cancel(Group.InOutTimer); Group.InOutTimer = nil end
end
V.PStopInOutTransition = PStopInOutTransition


----------------------------------------------------------------
-- PRIVATE: DELETE AN APPLIED IN-OUT TRANSITION
----------------------------------------------------------------
local PRemoveInOutTransition = function(Group)
	V.PStopInOutTransition(Group)

	local name, value

	if Group.InOutEffect ~= nil then
		if Group.InOutEffect.CompleteListener ~= nil then
			Runtime:removeEventListener("transitionComplete", Group.InOutEffect.CompleteListener)
		end

		for name, value in pairs(Group.InOutEffect) do Group.InOutEffect[name] = nil end
		Group.InOutEffect = nil
	end
end
V.PRemoveInOutTransition = PRemoveInOutTransition


----------------------------------------------------------------
-- PRIVATE: VERIFY PROPERTIES, APPLY THEM TO TEXT OBJECT
----------------------------------------------------------------
local PApplyProperties = function(Group, Properties)

	local oldText = Group.text

	local Charset = V.Charsets[Properties.fontName]
	if Charset.charSpacing ~= nil then Group.charSpacing = Charset.charSpacing end
	if Charset.lineSpacing ~= nil then Group.lineSpacing = Charset.lineSpacing end

	-- SET PROPERTIES
	if Properties.fontName 		~= nil then Group.fontName    = Properties.fontName end
	if Properties.text     		~= nil then Group.text        = Properties.text end
	if Properties.originX  		~= nil then Group.originX     = string.upper(Properties.originX) end
	if Properties.originY  		~= nil then Group.originY     = string.upper(Properties.originY) end
	if Properties.textFlow 		~= nil then Group.textFlow    = string.upper(Properties.textFlow) end
	if Properties.wrapWidth		~= nil then Group.wrapWidth   = Properties.wrapWidth end
	if Properties.charSpacing 	~= nil then Group.charSpacing = Properties.charSpacing end
	if Properties.lineSpacing	~= nil then Group.lineSpacing = Properties.lineSpacing end
	if Properties.showOrigin	~= nil then Group.showOrigin  = Properties.showOrigin end
	if Properties.x 		~= nil then Group.x           = Properties.x end
	if Properties.y 		~= nil then Group.y           = Properties.y end
	if Properties.startLine		~= nil then Group.startLine   = Properties.startLine end
	if Properties.linesToShow	~= nil then Group.linesToShow = Properties.linesToShow end
	if Properties.Color		~= nil then Group.Color       = Properties.Color end
	if Properties.fontSize		~= nil then Group.fontSize    = Properties.fontSize end
	if Properties.shadowOffX	~= nil then Group.shadowOffX  = Properties.shadowOffX end
	if Properties.shadowOffY	~= nil then Group.shadowOffY  = Properties.shadowOffY end
	if Properties.shadowAlpha	~= nil then Group.shadowAlpha = Properties.shadowAlpha end
	if Properties.fixedWidth	~= nil then Group.fixedWidth  = Properties.fixedWidth end
	if Properties.fixedHeight	~= nil then Group.fixedHeight = Properties.fixedHeight end

	if Properties.charBaseLine	~= nil then 
		if Properties.charBaseLine == "TOP" then 
			Group.charBaseLine = 1
		elseif Properties.charBaseLine == "BOTTOM" then 
			Group.charBaseLine = -1 
		else
			Group.charBaseLine = 0 
		end
	end

	-- DEFAULTS
	if Group.text         == nil then Group.text         = "" end
	if Group.originX      == nil then Group.originX      = "CENTER" end
	if Group.originY      == nil then Group.originY      = "CENTER"	 end
	if Group.textFlow     == nil then Group.textFlow     = "LEFT" end	
	if Group.wrapWidth    == nil then Group.wrapWidth    = 0	 end
	if Group.showOrigin   == nil then Group.showOrigin   = false	 end
	if Group.startLine    == nil then Group.startLine    = 1	 end
	if Group.linesToShow  == nil then Group.linesToShow  = 0	 end
	if Group.fontSize     == nil then Group.fontSize     = V.Charsets[Group.fontName].fontSize end
	if Group.shadowOffX   == nil then Group.shadowOffX   = 0 end
	if Group.shadowOffY   == nil then Group.shadowOffY   = 0 end
	if Group.shadowAlpha  == nil then Group.shadowAlpha  = 128 end
	if Group.charSpacing  == nil then Group.charSpacing  = 0	 end
	if Group.lineSpacing  == nil then Group.lineSpacing  = 0	 end
	if Group.charBaseLine == nil then Group.charBaseLine = 0 end
	if Group.fixedWidth   == nil then Group.fixedWidth   = 0 end
	if Group.fixedHeight  == nil then Group.fixedHeight   = 0 end
	if Group.Color        ~= nil and Group.Color[4] == nil then Group.Color[4] = 255 end
end
V.PApplyProperties = PApplyProperties


----------------------------------------------------------------
-- PRIVATE: DRAW THE CHARS OF A TEXT OBJECT
----------------------------------------------------------------
local PDrawChars = function(Group)
	
	if Group.name ~= "FXText" then print("!!! TextFX._DrawChars(): THIS IS NOT A TEXT FX OBJECT."); return end
	
	local Charset = V.Charsets[Group.fontName]; if Charset == nil then print("!!! TextFX._DrawChars(): CHARSET "..Group.fontName.." NOT FOUND."); return end
	local c, n, i, j, Img, len, x, y, w,h, yy, Char, Temp, spaceBefore
	local ox = 0
	local oy = 0

	-- REMOVE ANIMATIONS
	Group:stopAnimation()

	-- STOP IN-OUT TRANSITION
	V.PStopInOutTransition (Group)

	-- DELETE CHARS
	while Group[2].numChildren > 0 do Group[2][1]:removeSelf() end

	-- WRAP TEXT LINES
	V.PSetWrappedTextData (Group)

	-- ORIGIN
	    if Group.originX == "CENTER" then ox = -Group.maxLineWidth*.5 
	elseif Group.originX == "RIGHT"  then ox = -Group.maxLineWidth end
	    if Group.originY == "CENTER" then oy = -Group.totalHeight*.5
	elseif Group.originY == "BOTTOM" then oy = -Group.totalHeight end

	--Img = display.newRect(Group, 0,oy,10,Group.totalHeight)

	-- LOOP LINES, CREATE CHARS
	local linesDrawn = 0
	for j = Group.startLine, Group.endLine do
		len 		= string.len( Group.wrappedLines[j] )
		linesDrawn 	= linesDrawn + 1
		y   		= oy + (linesDrawn-1) * (Charset.lineHeight + Group.lineSpacing)
		x   		= ox
		
		-- TEXT FLOW
		    if Group.textFlow == "CENTER" then x = x + (Group.maxLineWidth - Group.lineWidths[j]) * .5 
		elseif Group.textFlow == "RIGHT"  then x = x + (Group.maxLineWidth - Group.lineWidths[j]) end

		-- EMPTY LINE? - CREATE PLACEHOLDER
		if Group.wrappedLines[j] == "" then 
			Img   = display.newRect(0,0,4,Charset.Chars[32].height)
			Img:setFillColor  (0,0,0,0)
			Img:setStrokeColor(0,0,0,0)
			Img.yReference = -Charset.Chars[32].offY
			Img.xScale     = Charset.scale
			Img.yScale     = Charset.scale
			Img.x          = x + 2
			Img.y          = y + (Group.charBaseLine * Charset.Chars[32].height*.5)
			Img.isEmptyLine= true
			if Group.charBaseLine == 0 then Img.y = Img.y + Charset.lineHeight*.5 elseif Group.charBaseLine ==-1 then Img.y = Img.y + Charset.lineHeight* 1 end
			Group[2]:insert(Img)
		end

		for i = 1, len do
			c    = string.sub (Group.wrappedLines[j],i,i)
			n    = string.byte(c)
			Char = Charset.Chars[n]

			if Char == nil then print("!!! TextFX._DrawChars(): CHAR '"..c.."' NOT INCLUDED IN CHARSET '"..Group.fontName.."'!")
			else
				-- IS NEW LINE
				if n ~= 32 then
					if Charset.isVector then
						if Group.shadowOffX ~= 0 or Group.shadowOffY ~= 0 then
							yy   = -Char.height*.5
							Img  = display.newGroup()
							Temp = display.newText( c, Group.shadowOffX, yy + Group.shadowOffY, Charset.name, Group.fontSize * Charset.scale )
							--Temp = display.newRetinaText( c, Group.shadowOffX, yy + Group.shadowOffY, Charset.name, Group.fontSize * Charset.scale )
							Temp:setTextColor( 0,0,0, Group.shadowAlpha )
							Img:insert(Temp)
							Temp = display.newText( c, 0, yy, Charset.name, Group.fontSize * Charset.scale )
							--Temp = display.newRetinaText( c, 0, yy, Charset.name, Group.fontSize * Charset.scale )
							-- APPLY COLOR
							if Group.Color ~= nil then Temp:setTextColor( Group.Color[1],Group.Color[2],Group.Color[3],Group.Color[4] ) end
							Img:insert(Temp)
						else
							Img = display.newText( c, 0, 0, Charset.name, Group.fontSize * Charset.scale )
							--Img = display.newRetinaText( c, 0, 0, Charset.name, Group.fontSize * Charset.scale )
							-- APPLY COLOR
							if Group.Color ~= nil then Img:setTextColor( Group.Color[1],Group.Color[2],Group.Color[3],Group.Color[4] ) end
						end
					else
						Img = sprite.newSprite(Charset.Set)
						Img.currentFrame = Char.frame
					        -- APPLY COLOR
					        if Group.Color ~= nil then Img:setFillColor(Group.Color[1], Group.Color[2], Group.Color[3], Group.Color[4]) end
					end
					Img.name        = "FXChar"
					Img.index       = i
					Img.char        = c
					Img.charNum     = n
					Img.spaceBefore = spaceBefore
					Img.yReference  = -Char.offY
					Img.xScale      = Charset.scale
					Img.yScale      = Charset.scale
					--Img.x           = x + (Char.width*.5)
					Img.x           = x + (Char.width*.5) + Char.offX  --SV added
					Img.y           = y + (Group.charBaseLine * Char.height*.5) 

				    if Group.charBaseLine == 0 then 
						Img.y = Img.y + Charset.lineHeight*.5 
					elseif Group.charBaseLine ==-1 then 
						Img.y = Img.y + Charset.lineHeight* 1 
					end

					Group[2]:insert(Img)
					spaceBefore 	 = false
				else
					spaceBefore 	 = true
				end
				-- x = x + Char.width + Group.charSpacing 
				x = x + Char.width + Group.charSpacing + Char.postOffX  -- SV added
			end
		end -- /LOOP THIS LINE
	
	end -- /LOOP LINES
	
    -- HIDE / SHOW ORIGIN
    Group[3].isVisible	= Group.showOrigin == true and true or false
    
    -- ADJUST BACKGROUND
    if Group[1][1] ~= nil then
    	local BG = Group[1][1]
		x, y = Group[2]:contentToLocal(Group[2].contentBounds.xMin - BG.marginX, Group[2].contentBounds.yMin - BG.marginY)
		BG.x = x + BG.offX
		BG.y = y + BG.offY

		if Group.fixedHeight > 0 then
			BG.yScale = (Group.fixedHeight + BG.marginY*2) / BG.height
		else
			BG.yScale = (Group[2].height + BG.marginY*2) / BG.height
		end

		if Group.fixedWidth > 0 then
			BG.xScale = (Group.fixedWidth + BG.marginX*2) / BG.width
		else
			if Group.Scrollbar ~= nil then
				BG.xScale = (Group.maxLineWidth + BG.marginX + Group.Scrollbar.width + Group.Scrollbar.xOffset) / BG.width
			else
				BG.xScale = (Group.maxLineWidth + BG.marginX*2) / BG.width
			end
		end

	end
    
    -- ADJUST SCROLLBAR
    if Group.Scrollbar ~= nil then
    	local Scrollbar = Group.Scrollbar
    	local txtHeight = Group[2].height; if Group.fixedHeight > 0 then txtHeight = Group.fixedHeight end

	    -- HIDE / SHOW SCROLLBAR?
		if Scrollbar.autoHide == true and (#Group.wrappedLines <= Group.linesToShow) or (Group.linesToShow == 0) then Scrollbar.isVisible = false else Scrollbar.isVisible = true end

		-- POSITION SCROLLBAR
		if Group.fixedWidth > 0 then 
			x = Group[2].contentBounds.xMin + (Group.fixedWidth-Scrollbar.Frame.width*.5)*Group.xScale
		else 
			x = Group[2].contentBounds.xMin + (Group.maxLineWidth + Scrollbar.xOffset)*Group.xScale 
		end
		Scrollbar.x, Scrollbar.y = Group[2]:contentToLocal(x, Group[2].contentBounds.yMin)

		-- ADJUST SCROLLBAR	HEIGHT 
		local h = txtHeight
		
		if Scrollbar.Frame then
			Scrollbar.Frame.x = 0
			Scrollbar.Frame.y = 0
			if Scrollbar.FrameBottom then h = h - Scrollbar.FrameBottom.height end
			if Scrollbar.FrameTop    then h = h - Scrollbar.FrameTop.height; Scrollbar.Frame.y = Scrollbar.FrameTop.height end
			Scrollbar.Frame.yScale = h / Scrollbar.Frame.height
		end

		if Scrollbar.FrameBottom then
			Scrollbar.FrameBottom.x = 0
			Scrollbar.FrameBottom.y = txtHeight
		end

		Scrollbar.Button.x = 0
		Scrollbar.Button.y = 0
		if Scrollbar.ButtonTop then Scrollbar.Button.y = Scrollbar.ButtonTop.height end

		h = Scrollbar.Button.oHeight
		if Scrollbar.scaleButton == true then
			h = txtHeight * (Group.linesToShow / #Group.wrappedLines)
			if Scrollbar.ButtonBottom then h = h - Scrollbar.ButtonBottom.height end
			if Scrollbar.ButtonTop	  then h = h - Scrollbar.ButtonTop.height; Scrollbar.Button.y = Scrollbar.ButtonTop.height end
			Scrollbar.Button.yScale = h / Scrollbar.Button.oHeight
		end

		if Scrollbar.ButtonBottom then
			Scrollbar.ButtonBottom.x = 0
			Scrollbar.ButtonBottom.y = Scrollbar.Button.y + h
		end
	end

	-- RENDER APPLIED DEFORMATIONS?
	if Group.DeformEffect ~= nil then V.PDoDeform (Group) end

	-- AUTO-APPLY IN-OUT EFFECT?
	if Group.InOutEffect ~= nil and Group.InOutEffect.restartOnChange == true then 
		V.PStartInOutTransition(Group) 
	end

	-- AUTO-APPLY ANIMATION?
	if Group.AnimEffect ~= nil and Group.AnimEffect.restartOnChange == true then
		Group:startAnimation()
	end

end
V.PDrawChars = PDrawChars


----------------------------------------------------------------
-- PRIVATE: RENDER DEFORMATION APPLIED TO A SPECIFIED TEXT
----------------------------------------------------------------
local PDoDeform = function(Group)
	local i, n, j, v1, v2, v3
	
	local Deform = Group.DeformEffect
	
	--------------------------------------------------------
	if Deform.type == V.DEFORM_SHAKE then
		math.randomseed(1)
		for j = 1, Group[2].numChildren do
			v1 = -(Deform.scaleVariation*.5) + V.Rnd()*Deform.scaleVariation
			Group[2][j].rotation = Group[2][j].rotation - (Deform.angleVariation*.5) + V.Rnd()*Deform.angleVariation
			Group[2][j].xScale   = Group[2][j].xScale + v1
			Group[2][j].yScale   = Group[2][j].yScale + v1
			Group[2][j].x        = Group[2][j].x -(Deform.xVariation*.5) + V.Rnd()*Deform.xVariation
			Group[2][j].y        = Group[2][j].y -(Deform.yVariation*.5) + V.Rnd()*Deform.yVariation
		end
	--------------------------------------------------------
	elseif Deform.type == V.DEFORM_WAVE_Y then
		for j = 1, Group[2].numChildren do
			Group[2][j].y = Group[2][j].y + V.Sin(Group[2][j].x / Deform.frequency) * (Deform.amplitude)
		end
	--------------------------------------------------------
	elseif Deform.type == V.DEFORM_WAVE_SCALE then
		for j = 1, Group[2].numChildren do
			v1 = Deform.minScale + (V.Sin(Group[2][j].x / Deform.frequency) * (Deform.amplitude))
			if Deform.scaleX then Group[2][j].xScale = Group[2][j].xScale + v1 end
			if Deform.scaleY then Group[2][j].yScale = Group[2][j].yScale + v1 end
		end
	--------------------------------------------------------
	elseif Deform.type == V.DEFORM_MIRROR then
		for j = 1, Group[2].numChildren do
			if Deform.mirrorX then Group[2][j].xScale = Group[2][j].xScale * -1 end
			if Deform.mirrorY then Group[2][j].yScale = Group[2][j].yScale * -1 end
		end
	--------------------------------------------------------
	elseif Deform.type == V.DEFORM_ZIGZAG then
		for j = 1, Group[2].numChildren do
			if V.Mod(j,2) == 0 then
				Group[2][j].y		 = Group[2][j].y		  - Deform.toggleY
				Group[2][j].rotation = Group[2][j].rotation - Deform.toggleAngle
				Group[2][j].xScale	 = Group[2][j].xScale	  - Deform.toggleScale
				Group[2][j].yScale	 = Group[2][j].yScale	  - Deform.toggleScale
			else
				Group[2][j].y		 = Group[2][j].y 		  + Deform.toggleY
				Group[2][j].rotation = Group[2][j].rotation + Deform.toggleAngle
				Group[2][j].xScale	 = Group[2][j].xScale	  + Deform.toggleScale
				Group[2][j].yScale	 = Group[2][j].yScale	  + Deform.toggleScale
			end
			if Deform.minScale ~= nil then
				if Group[2][j].xScale < Deform.minScale then Group[2][j].xScale = Deform.minScale end
				if Group[2][j].yScale < Deform.minScale then Group[2][j].yScale = Deform.minScale end
			end
		end
	--------------------------------------------------------
	elseif Deform.type == V.DEFORM_SQUEEZE then
		local Charset = V.Charsets[Group.fontName]
		local Char, x, percent
		local minX = 0
		local maxX = 0
		for j = 1, Group[2].numChildren do 
				if Group[2][j].x < minX then minX = Group[2][j].x end
				if Group[2][j].x > maxX then maxX = Group[2][j].x end
		end
		local width = Group.maxLineWidth; if minX < 0 then width = maxX - minX end

		for j = 1, Group[2].numChildren do
			x 		= Group[2][j].x; if minX < 0 then x = x - minX end
			percent = x / width
			Char 	= Charset.Chars[Group[2][j].charNum]

			if Deform.mode == "INNER" then
				if percent <= 0.5 then
					v1 = Deform.min + V.Cos(2.0*(percent)^.3) * Deform.max 
				else
					v1 = Deform.min + V.Cos(2.0*(1.0-percent)^.3) * Deform.max 
				end
				if Deform.scaleX then Group[2][j].xScale = Group[2][j].xScale + v1 end
				if Deform.scaleY then Group[2][j].yScale = Group[2][j].yScale + v1 end

			elseif Deform.mode == "OUTER" then
				if percent <= 0.5 then
					v1 = Deform.min + V.Sin(2.0*(percent)^0.65) * Deform.max 
				else
					v1 = Deform.min + V.Sin(2.0*(1.0-percent)^0.65) * Deform.max 
				end
				if Deform.scaleX then Group[2][j].xScale = Group[2][j].xScale + v1 end
				if Deform.scaleY then Group[2][j].yScale = Group[2][j].yScale + v1 end

			elseif Deform.mode == "LEFT" then
				if Deform.scaleX then Group[2][j].xScale = Group[2][j].xScale + (Deform.min + percent * Deform.max) end
				if Deform.scaleY then Group[2][j].yScale = Group[2][j].yScale + (Deform.min + percent * Deform.max) end

			elseif Deform.mode == "RIGHT" then
				if Deform.scaleX then Group[2][j].xScale = Group[2][j].xScale + (Deform.min + (1.0-percent) * Deform.max) end
				if Deform.scaleY then Group[2][j].yScale = Group[2][j].yScale + (Deform.min + (1.0-percent) * Deform.max) end
			end
			--print(percent.."%  "..Group[2][j].yScale)
		end
	--------------------------------------------------------
	elseif Deform.type == V.DEFORM_CIRCLE then
		if Group[2].numChildren == 0 then return end
		local Char, a, c, step, offY 
		local Charset = V.Charsets[Group.fontName]
		local childs  = Group[2].numChildren 
		local radius  = Deform.radius
		local angle   = 0

		if Deform.autoStep == true then step = 360.0 / string.len(Group.text) else step = Deform.angleStep end

		for j = 1, childs do
			if Group[2][j].spaceBefore == true and Deform.ignoreSpaces ~= true then angle = angle + step end

			a = V.Rad(angle-90)  
			if Group[2][j].char ~= " " and Group[2][j].char ~= V.newLineChar then
				offY = 0; Char = Charset.Chars[Group[2][j].charNum]; if Char ~= nil then offY = Char.offY end
				if offY > 0 then
					Group[2][j].x = V.Cos(a) * (radius - offY * -.5)
					Group[2][j].y = V.Sin(a) * (radius - offY * -.5)
				else
					Group[2][j].x = V.Cos(a) * (radius - offY * 2.0)
					Group[2][j].y = V.Sin(a) * (radius - offY * 2.0)
				end
				Group[2][j].rotation = angle
			end
			angle  = angle  + step
			if Deform.radiusChange ~= nil then radius = radius + Deform.radiusChange end
			if Deform.stepChange   ~= nil then step   = step   + Deform.stepChange end
		end
	--------------------------------------------------------

	if V.debug then print("--> TextFX: PROCESSED DEFORMATION (TYPE: "..Deform.type..")") end
	end --/SWITCH DEFORM NAME
end
V.PDoDeform = PDoDeform


----------------------------------------------------------------
-- PRIVATE: SET WRAPPED TEXT LINE DATA ON A TEXT OBJECT
----------------------------------------------------------------
local PSetWrappedTextData = function(Group)
	local fontName    = Group.fontName
	local wrapWidth   = Group.wrapWidth
	local charSpacing = Group.charSpacing
	local txt         = Group.text
	local Charset     = V.Charsets[fontName]; if Charset == nil then print("!!! TextFX: CHARSET "..fontName.." NOT FOUND."); return 0 end
	local ln          = 1 	-- CURRENT LINE NUMBER			
	local cl          = ""	-- CURRENT LINE TEXT
	local c, n, cc, cw, i, j, len1, len2

	-- DISCARD OLD WRAPPED DATA
	Group.wrappedLines = nil; Group.wrappedLines = {}
	Group.lineWidths   = nil; Group.lineWidths   = {}
	Group.maxLineWidth	= 0
	
	-- REMOVE NEW LINES AT BEGINNING
	i = 1; while string.sub(txt,i,i) == V.newLineChar do i = i + 1 end; txt = string.sub(txt,i)

	-- WRAP TEXT
	len1= string.len(txt)
	for i = 1, len1 do
		c = string.sub(txt,i,i)

			cw = V.GetLineWidth(fontName, cl, charSpacing)

			-- NEW LINE CHAR?
			if c == V.newLineChar then 
				Group.wrappedLines[ln] = cl
				Group.lineWidths  [ln] = cw
				cl = ""
				ln = ln + 1

			else cl = cl..c end
			
			-- LENGTH EXCEEDED? WRAP TO NEW LINE
			if wrapWidth > 0 and cw > wrapWidth then
				len2 = string.len(cl)
				for j = len2, 1, -1 do
					cc = string.sub (cl,j,j)
					n  = string.byte(cc)
					
					if n == 32 then
						Group.wrappedLines[ln] = string.sub(cl,1,j-1)
						Group.lineWidths  [ln] = V.GetLineWidth(fontName, Group.wrappedLines[ln], charSpacing)
						cl = string.sub(cl,j+1)
						ln = ln + 1

					elseif cc == "-" then
						Group.wrappedLines[ln] = string.sub(cl,1,j)
						Group.lineWidths  [ln] = V.GetLineWidth(fontName, Group.wrappedLines[ln], charSpacing)
						cl = string.sub(cl,j+1)
						ln = ln + 1
					end
				
				end -- /REWIND
			end -- /IF MAXWIDTH EXCEEDED?
	end -- /LOOP STRING

	Group.wrappedLines[ln] = cl
	Group.lineWidths  [ln] = V.GetLineWidth(fontName, Group.wrappedLines[ln], charSpacing)

	-- FIND MAX LINE WIDTH
	for i = 1, #Group.wrappedLines do
		if Group.lineWidths[i] > Group.maxLineWidth then Group.maxLineWidth = Group.lineWidths[i] end
		--print("LINE "..i.." = '"..Group.wrappedLines[i].."'    WIDTH = "..Group.lineWidths[i] )
	end

	-- START LINE & VISIBLE LINES
	if Group.linesToShow == 0 then
		Group.maxScroll = 1
		if Group.startLine > #Group.wrappedLines then Group.startLine = #Group.wrappedLines end
		Group.endLine = #Group.wrappedLines
	else
		Group.maxScroll = #Group.wrappedLines - (Group.linesToShow-1)
		if Group.maxScroll < 1 then Group.maxScroll = 1 end
		if Group.startLine > Group.maxScroll then Group.startLine = Group.maxScroll end
		if Group.startLine < 1 then Group.startLine = 1 end
		Group.endLine = Group.startLine + (Group.linesToShow-1)
		if Group.endLine > #Group.wrappedLines then Group.endLine = #Group.wrappedLines end
	end
	local numLines = (Group.endLine - Group.startLine) + 1

	-- GET MAX HEIGHT
	Group.totalHeight = numLines * Charset.lineHeight + (numLines-1) * Group.lineSpacing

end
V.PSetWrappedTextData = PSetWrappedTextData


----------------------------------------------------------------
-- PRIVATE: PROCESS TEXT ANIMATION
----------------------------------------------------------------
local PAnimate = function(event)

	local Timer 	= event.source
	local Group 	= Timer.Target
	local FX    	= Group.AnimEffect
	local numChars 	= Group[2].numChildren
	local now		= V.GetTimer()
	local i, vSin, vCos, alpha
	
	-- JUST STARTED?
	if Timer._count < 3 then
		if FX.duration		  == nil then FX.duration = 0 end
		if FX.delay			  == nil then FX.delay	= 0 end
		if FX.charWise		  == nil then FX.charWise = true end

		Timer.startTime = now
		Timer.endTime   = now + FX.delay + FX.duration
	
	-- RUNNING?
	elseif now-Timer.startTime >= FX.delay then
		if FX.charWise == true then
			for i = 1, numChars do 
				vSin  = V.Sin(now / FX.frequency + i)
				vCos  = V.Cos(now / FX.frequency + i)
				if FX.alphaRange	~= nil then 
					alpha 				= Group[2][i].origAlpha  + vSin * FX.alphaRange; if alpha > 1.0 then alpha = 1.0 elseif alpha < 0 then alpha = 0 end
					Group[2][i].alpha	= alpha 
				end
				if FX.xScaleRange 	~= nil then Group[2][i].xScale 		= Group[2][i].origXScale + vSin * FX.xScaleRange end
				if FX.yScaleRange 	~= nil then Group[2][i].yScale 		= Group[2][i].origYScale + vSin * FX.yScaleRange end
				if FX.rotationRange	~= nil then Group[2][i].rotation 	= Group[2][i].origRot    + vSin * FX.rotationRange end
				if FX.xRange		~= nil then Group[2][i].x		 	= Group[2][i].origX      + vSin * FX.xRange end
				if FX.yRange		~= nil then Group[2][i].y		 	= Group[2][i].origY      + vCos * FX.yRange end
			end
		else
			vSin  = V.Sin(now / FX.frequency)
			vCos  = V.Cos(now / FX.frequency)
			if FX.alphaRange~= nil then 
				alpha 		= Group.origAlpha  + vSin * FX.alphaRange; if alpha > 1.0 then alpha = 1.0 elseif alpha < 0 then alpha = 0  end
				Group.alpha	= alpha 
			end
			if FX.xScaleRange 	~= nil then Group.xScale 	= Group.origXScale + vSin * FX.xScaleRange end
			if FX.yScaleRange 	~= nil then Group.yScale 	= Group.origYScale + vSin * FX.yScaleRange end
			if FX.rotationRange	~= nil then Group.rotation 	= Group.origRot    + vSin * FX.rotationRange end
			if FX.xRange		~= nil then Group.x		 	= Group.origX      + vSin * FX.xRange end
			if FX.yRange		~= nil then Group.y		 	= Group.origY      + vCos * FX.yRange end
		end
		
		-- FINISHED?
		if FX.duration > 0 and now > Timer.endTime then 
			Group:stopAnimation() 
			if FX.autoRemoveText then V.DeleteText(Group) end
		end
	end

end
V.PAnimate = PAnimate


----------------------------------------------------------------
-- PRIVATE: MARQUEE ANIMATION
----------------------------------------------------------------
local PMarquee = function(event)
	local Group = event.source.Target
	
	Group[2].x = Group[2].x - Group.marqueeSpeed

	if Group[2].x < Group.endX then
		Group[2].x 		= Group[2].x  - Group.endX
		Group.text		= string.sub(Group.text,2)..string.sub(Group.marqueeText,Group.nextCharPos,Group.nextCharPos)
		Group.nextCharPos	= Group.nextCharPos + 1; if Group.nextCharPos > string.len(Group.marqueeText) then Group.nextCharPos = 1 end
		V.PDrawChars		(Group)
		
		if string.sub (Group.text,1,1) == " " then 
			Group.charW = V.Charsets[Group.fontName].spaceWidth 
		elseif Group.shadowOffX ~= 0 or Group.shadowOffY ~= 0 then
			Group.charW = Group[2][1][1].width 
		else 
			Group.charW = Group[2][1].width 
		end
		
		Group.endX = - (Group.charW + Group.charSpacing) * V.Charsets[Group.fontName].scale
	end
end
V.PMarquee = PMarquee


return V