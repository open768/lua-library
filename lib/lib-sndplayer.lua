--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
cSoundPlayer = 	{ eventName = "onComplete", className="cSoundPlayer"}
cLibEvents.instrument(cSoundPlayer)
cDebug.instrument(cSoundPlayer)

require "inc.lib.lib-class"
require "inc.lib.lib-stack"

--########################################################
--# PRIVATE
--########################################################
function cSoundPlayer:prv_playInSeq(piIndex)
	local fnCallback, sFilename
	
	if not self.files then
		self:throw("no Files to play")
	end
	
	if self.stopped then 
		self:debug(DEBUG__DEBUG, "cant play stopped")
		return 
	end

	sFilename = self.files[piIndex]
	self:debug(DEBUG__DEBUG, "playing: ", sFilename)
	self.channel = audio.findFreeChannel()
	self.handle = audio.loadStream(sFilename)
	self.nowPlaying = piIndex
	
	fnCallback = function(poEvent) 	self:onComplete(poEvent) end
	self.alChannel, self.alSource = audio.play(self.handle, {onComplete=fnCallback, channel=self.channel})
end

--########################################################
--# PUBLIC
--########################################################
function cSoundPlayer:create(paFiles)
	local oInstance = cClass.createInstance(self)
	
	oInstance.files=paFiles
	oInstance.nowPlaying = 0
	oInstance.handle = nil
	oInstance.stopped = false
	oInstance.channel = nil
	oInstance.looped = false
	oInstance.autoClear = true
	
	return oInstance
end

--*******************************************************
function cSoundPlayer:play()
	self:prv_playInSeq(1)
end

--*******************************************************
function cSoundPlayer:preload()
	self:debug(DEBUG__WARN, "preload not implemented")
end

--*******************************************************
function cSoundPlayer:stop()
	if self.channel then
		self:debug(DEBUG__INFO, "stopping sounds on channel ",self.channel)
		self.stopped = true
		audio.stop(self.channel)
	end
end

--########################################################
--# EVENTS
--########################################################
function cSoundPlayer:onComplete(poEvent)
	local oListener, sFilename
	
	sFilename = self.files[self.nowPlaying]
	self:debug(DEBUG__DEBUG, "finished:", sFilename)
	-- clear out the previous audio
	audio.dispose(self.handle)
	self.handle = nil
	self.channel = nil
	self.alChannel = nil
	self.alSource = nil
	
	-- bomb out if stopped
	if not poEvent.completed then 
		self.stopped = false
		return 
	end
	
	--
	if (self.nowPlaying < #(self.files)) then
		self:prv_playInSeq(self.nowPlaying + 1 )
	else
		if self.looped then
			self:prv_playInSeq(1)
			return
		else
			self:debug(DEBUG__EXTRA_DEBUG, "notifying: ",self.eventName)
			self:notify({ name=self.eventName })

			-- clear out the 
			if self.autoClear  then self.files = nil end
		end
	end
end

