--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
cSoundPlayer = 	{ eventName = "onComplete", className="cSoundPlayer"}
require "inc.lib.lib-class"

--TBD remove listener and use events

function cSoundPlayer:play(paFiles, poListener, pbLooped)
	local oInstance = cClass.createInstance(self)
	
	oInstance.files=paFiles
	oInstance.nowPlaying = 0
	oInstance.handle = nil
	oInstance.listener = poListener 
	oInstance.stopped = false
	oInstance.channel = nil
	oInstance.looped = pbLooped
	
	oInstance:_playInSeq(1)

	return oInstance
end

--*******************************************************
function cSoundPlayer:_playInSeq(piIndex)
	local fnCallback
	
	if not self.files then
		cDebug:throw("no Files to play")
	end
	
	if self.stopped then return end

	self.channel = audio.findFreeChannel()
	self.handle = audio.loadStream(self.files[piIndex])
	self.nowPlaying = piIndex
	
	fnCallback = function(poEvent) 	self:onComplete(poEvent) end
	self.alChannel, self.alSource = audio.play(self.handle, {onComplete=fnCallback, channel=self.channel})
end

--*******************************************************
function cSoundPlayer:onComplete(poEvent)
	local oListener
	-- clear out the previous audio
	audio.dispose(self.handle)
	self.handle = nil
	self.channel = nil
	self.alChannel = nil
	self.alSource = nil
	
	-- bomb out if stopped
	if self.stopped then return end
	
	--
	if (self.nowPlaying < #(self.files)) then
		self:_playInSeq(self.nowPlaying + 1 )
	else
		if self.looped then
			self:_playInSeq(1)
			return
		else
			-- tbd 
			if (self.listener ) then
				self.files=nil
				if type(self.listener) == "function" then
					self.listener(poEvent)
				else
					self.listener:onComplete()
				end
				self.listener = nil
			end

			-- clear out the 
			self.files = nil
		end
	end
end

--*******************************************************
function cSoundPlayer:stop()
	if self.channel then
		cDebug:print(DEBUG__INFO, "stopping sounds on channel ",self.channel)
		self.stopped = true
		audio.stop(self.channel)
	end
end