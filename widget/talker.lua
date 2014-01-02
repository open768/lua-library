--[[
	This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
		http://creativecommons.org/licenses/by-sa/3.0/
	Absolutely no warranties or guarantees given or implied - use at your own risk
	Copyright (C) 2013 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

	its too expensive to convert to phonemes on the fly on the device
	and the phonemes wouldnt match up to the audio
	if you want to go down that monorail http://www2.eng.cam.ac.uk/~tpl/asp/
	
	instead provide an array of timings for mouth sounds
	in edit mode this widget allows timings to be created interatively
]]--
require "inc.widget.textbuttonbar"
require "inc.widget.audiotracker"
require "inc.lib.lib-colours"
require "inc.lib.linkedlist"
require "inc.lib.lib-sndplayer"

local HiliteColour = "salmon"
local NormalColour = "lightgray"

if not cClass then error "cClass object not found" end
if not cLibEvents then error "cLibEvents object not found" end
if not cDebug then error "cDebug object not found" end

--########################################################
--# cMouthItem
--########################################################
cMouthItem = {}
function cMouthItem:create(piTs,psMouth)
	return {ts=piTs, mouth=psMouth}
end

--########################################################
--# cTalker
--########################################################
cTalker = { 
	className="cTalker" , eventName="onTalkedOut", editMode=false, obj=nil, map=nil, gap=10, timerGranularity=50, fontSize=30, 
	mute=false
}
cLibEvents.instrument(cTalker)
cDebug.instrument(cTalker)

function cTalker.comparator(pobj1,pobj2) 
	local iTs1, iTs2
	
	iTs1=pobj1.ts
	iTs2=pobj2.ts
	
	if (iTs2 < iTs1) then   	return -1
	elseif (iTs2 > iTs1) then	return 1
	else						return 0	end
end

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
	oInstance.recording = false
	oInstance.sequence = nil
	oInstance.played = nil
	oInstance.player = nil
	oInstance.startMs=0
	oInstance.talkTimer = nil
	oInstance.objs = {}
	if not pbeditmode == nil then 	oInstance.editMode = pbEditMode 	end
	oInstance:prv_init(poAssembled, paTalkMap)
	
	return oInstance
end

--*******************************************************
function cTalker:init(psSoundFile, paTimings)
	-- load up the sound ready to play
	self:debug(DEBUG__DEBUG, "init", psSoundFile)
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
	self.played = cLinkedList:create()
	self.playing = true

	self.startMs=system.getTimer()
	self:debug(DEBUG__DEBUG, "started at: ",  self.startMs)
	
	if self.mute then
		self:debug(DEBUG__DEBUG, "muted! - not playing")
	else
		self.player:play()		
	end
	
	self:prv_performMouths()
end

--########################################################
--# PRIVATE INitialisa
--########################################################
function cTalker:prv_init(poAssembled, paTalkMap)

	-- add the assembled object
	self:insert(poAssembled)
	self.objs.main = poAssembled
	
	-- check that all the necessary mouth details are there
	self:prv_validate_map(paTalkMap)
	
	-- add buttons
	if self.editMode then 
		self:prv_addButtons() 
		self:prv_addTimeline()
	end
	
	-- now set the initial mouth
	self:prv_setMouth("m") 
end

--*******************************************************
function cTalker:prv_addButtons()
	local oButtons
	
	oButtons = cTextButtonBar:create({
		{label="o", width=40, action="record", bgColour="red", textColour="white"},
		{label=">", width=40, action="play", bgColour="green", textColour="yellow"},
		{label="[]", width=40, action="stop", bgColour="blue", textColour="white"},
		{label="A", width=30, gap=self.gap, action="text"},
		{label="E", width=30, action="text"},
		{label="F", width=30, action="text"},
		{label="M", width=30, action="text"},
		{label="O", width=30, action="text"},
		{label="Th", width=30, action="text"},
		{label="Cons", width=50, action="text"},
	})
	oButtons.eventName="OnButtonTap"
	oButtons:addListener("OnButtonTap", self)
	
	self:insert(oButtons)
	utility.moveRelative(self.objs.main, display.BottomCenterReferencePoint, oButtons, display.TopCenterReferencePoint, 0, self.gap)
	self.objs.buttons = oButtons
end

--########################################################
--# PRIVATE Mouth Related
--########################################################
function cTalker:prv_setMouth(psMouthName)
	local aComponents, sComponent, i, obj, oButton
	
	if self.curr_mouth == psMouthName then return end
	
	self:debug(DEBUG__DEBUG, "setting mouth:", psMouthName)

	if self.editMode then
		-- add to stack if recording
		if self.recording then
			self.played:addComparatively( 
				cMouthItem:create(system.getTimer() - self.startMs, psMouthName), 
				cTalker.comparator)
		end
		
		--add marker to timeline
		
		--change button to be red
		if (self.curr_mouth ~= nil) then
			oButton = self.objs.buttons:get(self.curr_mouth)
			oButton:setFillColour( NormalColour)
		end
		oButton = self.objs.buttons:get(psMouthName)
		oButton:setFillColour( HiliteColour)
	end
	
	-- first hide all the images identified with the current mouth
	if (self.curr_mouth ~= nil) then
		aComponents = self.map.mouths[self.curr_mouth]
		for i=1, #aComponents do
			sComponent = aComponents[i]
			obj = self.objs.main:get(sComponent)
			obj.isVisible = false
		end
	end
	
	-- show all the images identified with the new mouth	
	aComponents = self.map.mouths[psMouthName]
	for i=1, #aComponents do
		sComponent = aComponents[i]
		obj = self.objs.main:get(sComponent)
		obj.isVisible = true
	end
	
	-- remember mouth
	self.curr_mouth = psMouthName
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
--# Other
--########################################################
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

--########################################################
--# callbacks
--########################################################
function cTalker:prv_play()
	self:debug(DEBUG__DEBUG, "clicked play")
	self:prv_stop()
	self:talk()
end
--*******************************************************
function cTalker:prv_record()
	self:debug(DEBUG__DEBUG, "clicked record")
	self:prv_stop()
	self.recording=true
	self:talk()
end

function cTalker:prv_stop()
	self:debug(DEBUG__DEBUG, "clicked stop")
	self.player:stop()
	self.playing = false
	self.recording=false
end


--########################################################
--# EVENTS
--########################################################
function cTalker:OnButtonTap(poEvent)
	local sAction
	sAction = poEvent.action
	
	if poEvent.action == "text" then
		self:prv_setMouth(poEvent.label)
	elseif poEvent.action == "play" then
		self:prv_play()
	elseif poEvent.action == "stop" then
		self:prv_stop()
	elseif poEvent.action == "record" then
		self:prv_record()
	else
		self:throw("unknown action", poEvent.action)
	end
end

function cTalker:onSndComplete(poEvent)
	self:debug(DEBUG__DEBUG, "finished sound")
	self.playing = false
	self.recording = false
end

