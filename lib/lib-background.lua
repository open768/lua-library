-- -- This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
-- -- http://creativecommons.org/licenses/by-sa/3.0/
-- -- Absolutely no warranties or guarantees given or implied - use at your own risk
-- -- Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
require ("inc.lib.lib-utility")
require "inc.lib.lib-class"

ccBackground={
	portait=nil,
	landscape=nil,
	which = nil,
	image = nil,
	is_listening = false,
	
	trans = {
		portrait ={which="p", rot=0},
		portraitUpsideDown ={which="p", rot=180},
		landscapeLeft ={which="l", rot=270},
		landscapeRight ={which="l", rot=90}
	}
}

--*******************************************************
function ccBackground:create( psPortrait, psLandscape)
	local oInstance = cClass.createGroupInstance("ccBackground", ccBackground)
	oInstance:_create(psPortrait, psLandscape)
	return oInstance
end


--*******************************************************
function ccBackground:_create(psPortrait, psLandscape)

	self.portrait = display.newImage( psPortrait, 0, 0 )
	self:insert(self.portrait)
	
	self.landscape = display.newImage( psLandscape, 0,0 )
	self:insert(self.landscape)
	
	self.landscape.isVisible = false
	self.which  = "p"
	self.image = self.portrait

	--rotate and scale
	self:rotate_and_scale()
	self:resume()
end

--*******************************************************
function ccBackground:pause()
	if self.is_listening then
		self.is_listening = false
		--self.image.isVisible = false
		Runtime:removeEventListener( "orientation", self)      
	end
end

--*******************************************************
function ccBackground:resume()
	if not self.is_listening then
		self.is_listening = true
		self.image.isVisible = true
		Runtime:addEventListener( "orientation", self )      
	end
end


--*******************************************************
function ccBackground:orientation( poEvent)
	local oParams
		
	oParams = self.trans[poEvent.type]

	-- make the correct image visible
	if (self.which ~= oParams.which) then
	
		-- hide the current image
		self.image.isVisible = false
		
		-- select the new image
		if oParams.which == "p" then
			self.image = self.portrait
			self.which = "p"
		else
			self.image = self.landscape
			self.which="l"
		end
		
		-- make image visible and remember
		self.which =  poEvent.type
		self.image.isVisible = true
	end
		
	-- rotate the image to match the orientation
	self:rotate_and_scale(poEvent.type)
end

--*******************************************************
function ccBackground:rotate_and_scale(psOrientation)
	local iRotate, iScale
	local iImg
	
	iImg = self.image 
	
	--rotate the image to be the right way up
	if psOrientation then
		iRotate = self.trans[psOrientation].rot
		iImg.rotation = iRotate
	end

	-- scale and move it
	utility:ScaleToScreen(iImg)
	iImg.x = utility.Screen.Centre.x
	iImg.y = utility.Screen.Centre.y
end
