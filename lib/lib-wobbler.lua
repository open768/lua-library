-- VERSION
-- -- This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
-- -- http://creativecommons.org/licenses/by-sa/3.0/
-- -- Absolutely no warranties or guarantees given or implied - use at your own risk
-- -- Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

require ("sprite")
require ("lib-debug")
require ("lib-spritegen")
require ("lib-utility")


--#################################################################
--#
--#################################################################
cWobbler = { ribbonHeight=2, magnitude=20, dAngle=3, delay=40}

-- ****************************************************************
function cWobbler:create(psFilename, piWidth, piHeight)
	local oInstance = {}
	
	setmetatable( oInstance, { __index = cWobbler } )  -- sets inheritance
	
	oInstance.maxSprites = math.floor(piHeight / self.ribbonHeight)
	oInstance.sprites = {}
	oInstance.group = display.newGroup()
	oInstance.startAngle = 0
	
	oInstance:init(psFilename, piWidth)
	
	return oInstance
end

-- ****************************************************************
function cWobbler:init(psFilename, piWidth)
	local oGen, iSprite, oSprite, iY
	
	iY = 0
	
	oGen = cSpriteGenerator:create(psFilename, piWidth, self.ribbonHeight, self.maxSprites)
	
	for iSprite =1, self.maxSprites do
		oSprite = oGen:getSprite(iSprite)
		oSprite.y = iY
		iY = iY + self.ribbonHeight
		self.group:insert(oSprite)
	end
end

-- **************************************************************
function cWobbler:go()
	timer.performWithDelay(self.delay, self, 1)	-- 0 means forever
end

-- **************************************************************
function cWobbler:timer()
	local iSprite, oSprite, iDeg, iRad, iX
	
	-- set the starting wobble angle
	self.startAngle = self.startAngle + self.dAngle
	if self.startAngle > 360 then self.startAngle = 0 end
	iDeg = self.startAngle 

	-- go through group contents and adjust x
	for iSprite =1, self.maxSprites do
		oSprite = self.group[iSprite]
		iRad = math.rad(iDeg)
		iX = math.sin(iRad ) * self.magnitude
		oSprite.x = iX
		
		iDeg = iDeg + self.dAngle
		if iDeg> 360 then iDeg= 0 end
	end
	
	self:go()
end
