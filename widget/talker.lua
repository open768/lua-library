--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2013 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
--[[
	its too expensive to convert to phonemes on the fly on the device
	and the phonemes wouldnt match up to the audio
	if you want to go down that monorail http://www2.eng.cam.ac.uk/~tpl/asp/
	
	instead provide an array of timings for mouth sounds
	in edit mode this widget allows timings to be created interatively
]]--
require "inc.widget.textbutton"
require "inc.widget.textbutton"
require "inc.lib.lib-colours"

local HiliteColour = "salmon"
local NormalColour = "lightgray"

if not cClass then error "cClass object not found" end
if not cLibEvents then error "cLibEvents object not found" end
if not cDebug then error "cDebug object not found" end
require "inc.lib.lib-stack"
require "inc.lib.lib-sndplayer"

cTalker = { className="cTalker" , eventName="onTalkedOut", editMode=false, obj=nil, map=nil, gap=10, timerGranularity=50, fontSize=30}
cLibEvents.instrument(cTalker)
cDebug.instrument(cTalker)

--########################################################
--# PUBLIC
--########################################################
function cTalker:create(poAssembled, paTalkMap, pbEditMode)
	if poAssembled.className ~= cObjMaker.className then
		self:throw( "not an Assembled object ")
	end
	
	local oInstance = cClass.createGroupInstance(self)
	oInstance.curr_mouth = nil
	oInstance.talking = false
	oInstance.sequence = nil
	oInstance.played = nil
	oInstance.player = nil
	oInstance.startMs=0
	oInstance.talkTimer = nil
	if not pbeditmode == nil then 	oInstance.editMode = pbEditMode 	end
	oInstance:prv_init(poAssembled, paTalkMap)
	
	return oInstance
end

--*******************************************************
function cTalker:init(psSoundFile, paTimings)
	-- load up the sound ready to play
	self:debug(DEBUG__DEBUG, "init")
	self.player = cSoundPlayer:create({psSoundFile})
	self.player:preload()
	self.player.autoClear = false
	self.player.eventName = "onSndComplete"
	self.player:addListener( "onSndComplete", self)
end

--*******************************************************
function cTalker:talk()
	
	if self.playing then return end
	if not self.player then self:throw("no sound loaded") end
	
	self:debug(DEBUG__DEBUG, "talk")
	self.played = cStack:create()
	self.playing = true

	self:debug(DEBUG__DEBUG, "started at: ",  self.startMs)
	self.startMs=system.getTimer()
	self.player:play()				-- play sound
	self:prv_performMouths()
end

--########################################################
--# PRIVATE
--########################################################
function cTalker:prv_init(poAssembled, paTalkMap)
	self:insert(poAssembled)
	self.obj = poAssembled
	
	self:prv_validate_map(paTalkMap)
	
	-- add buttons
	if self.editMode then self:prv_addButtons() end
	
	-- now set the initial mouth
	self:prv_setMouth("m") 
end

--*******************************************************
function cTalker:prv_addButtons()
	local oPlay, oStop, oA, oE, oF, oM, oO, oTh, oCNS

	self:debug(DEBUG__DEBUG, "new button")
	self.buttons  = {}
	
	oPlay = self:prv_addButton({label=">", width=40},"onClickPlay",self.obj,display.BottomLeftReferencePoint,display.TopLeftReferencePoint,0,self.gap)
	oStop = self:prv_addButton({label="[]", width=40},"onClickStop",oPlay,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	
	oA = self:prv_addButton({label="A", width=30},"onClickA",oStop,display.TopRightReferencePoint,display.TopLeftReferencePoint,self.gap,0)
	oE = self:prv_addButton({label="E", width=30},"onClickE",oA,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	oF = self:prv_addButton({label="F", width=30},"onClickF",oE,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	oM = self:prv_addButton({label="M", width=30},"onClickM",oF,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	oO = self:prv_addButton({label="O", width=30},"onClickO",oM,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	oTh = self:prv_addButton({label="Th", width=30},"onClickTH",oO,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	oCons = self:prv_addButton({label="Con", width=50},"onClickCons",oTh,display.TopRightReferencePoint,display.TopLeftReferencePoint,0,0)
	
	self.buttons.play = oPlay
	self.buttons.stop = oStop
	self.buttons.a = oA
	self.buttons.e = oE
	self.buttons.f = oF
	self.buttons.m = oM
	self.buttons.o = oO
	self.buttons.th = oTh
	self.buttons.cons = oCons
end

--*******************************************************
function cTalker:prv_addButton(paOptions, psEvent, poOther, psOtherRef, psButRef, piDx, piDy)
	local oButton
	
	paOptions.onRelease = cLibEvents.makeEventClosure(self, psEvent)
	--oButton = widget.newButton(paOptions)
	cTextButton.fontSize = self.fontSize
	cTextButton.FixedWidth = paOptions.width
	cTextButton.eventName = psEvent
	oButton= cTextButton:create(paOptions.label)
	oButton:addListener(psEvent, self)
	self:insert(oButton)
	
	utility.moveRelative(poOther, psOtherRef, oButton,  psButRef, piDx, piDy)	
	return oButton
end

--*******************************************************
function cTalker:prv_setMouth(psMouthName)
	local aComponents, sComponent, i, obj, oButton
	
	if self.curr_mouth == psMouthName then return end
	
	self:debug(DEBUG__DEBUG, "setting mouth:", psMouthName)

	if self.editMode then
		-- add to stack if playing in edit mode
		if self.playing then
			self.played:push({system.getTimer() - self.startMs, psMouthName})
		end
		
		--change button to be red
		if (self.curr_mouth ~= nil) then
			oButton = self.buttons[self.curr_mouth]
			oButton:setFillColour( NormalColour)
		end
		oButton = self.buttons[psMouthName]
		oButton:setFillColour( HiliteColour)
	end
	
	-- first hide all the images identified with the current mouth
	if (self.curr_mouth ~= nil) then
		aComponents = self.map.mouths[self.curr_mouth]
		for i=1, #aComponents do
			sComponent = aComponents[i]
			obj = self.obj:get(sComponent)
			obj.isVisible = false
		end
	end
	
	-- show all the images identified with the new mouth	
	aComponents = self.map.mouths[psMouthName]
	for i=1, #aComponents do
		sComponent = aComponents[i]
		obj = self.obj:get(sComponent)
		obj.isVisible = true
	end
	
	-- remember mouth
	self.curr_mouth = psMouthName
end

--*******************************************************
function cTalker:prv_validate_map(poMap)
	if not poMap.mouths then 	self:throw("map missing mouths")	end
	if not poMap.mouths.a then	self:throw("map missing mouth a")	end
	if not poMap.mouths.e then	self:throw("map missing mouth e")	end
	if not poMap.mouths.f then	self:throw("map missing mouth f")	end
	if not poMap.mouths.m then	self:throw("map missing mouth m")	end
	if not poMap.mouths.o then	self:throw("map missing mouth o")	end
	if not poMap.mouths.th then	self:throw("map missing mouth th")	end
	if not poMap.mouths.cons then	self:throw("map missing mouth cons")	end
	
	self.map = poMap
end

--*******************************************************
function cTalker:prv_performMouths()
	local poItem
	-- take the top item on the stack
	-- if item is nil 
		--stop timer
	
	if not poItem then
	else
	end
	
	-- if timer not running start timer
end

--########################################################
--# EVENTS
--########################################################
function cTalker:onClickPlay(poEvent)
	self:debug(DEBUG__DEBUG, "clicked play")
	self:talk()
end
function cTalker:onClickStop(poEvent)
	self:debug(DEBUG__DEBUG, "clicked stop")
	self.player:stop()
	self.playing = false
end

function cTalker:onClickA(poEvent) self:prv_setMouth("a") end
function cTalker:onClickE(poEvent) self:prv_setMouth("e") end
function cTalker:onClickF(poEvent) self:prv_setMouth("f") end
function cTalker:onClickM(poEvent) self:prv_setMouth("m") end
function cTalker:onClickO(poEvent) self:prv_setMouth("o") end
function cTalker:onClickTH(poEvent) self:prv_setMouth("th") end
function cTalker:onClickCons(poEvent) self:prv_setMouth("cons") end

function cTalker:onSndComplete(poEvent)
	self:debug(DEBUG__DEBUG, "finished sound")
	self.playing = false
end

function cTalker:timer(poEvent)
end
