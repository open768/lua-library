--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "sprite"
require "inc.lib.lib-class"

cSpriteGenerator = {}


--*******************************************************
function cSpriteGenerator:create(psImageFile, piWidth, piHeight, piMaxSprites)
	-- arcane lua instance creation 
	local oInstance = cClass.createInstance("cSpriteGenerator", cSpriteGenerator)
	
	oInstance.maSpriteSets = {}
	oInstance.miMaxSprites = piMaxSprites
	oInstance:init(psImageFile, piWidth, piHeight)
	
	return oInstance
end

--*******************************************************
function cSpriteGenerator:init(psImageFile, piWidth, piHeight)
	oSheet = sprite.newSpriteSheet(psImageFile, piWidth, piHeight)
	if oSheet == nil then
		error ("couldnt create a spritesheet from file: " + psImageFile)
	end
	
	for i =1, self.miMaxSprites do
		oSpriteSet = sprite.newSpriteSet(oSheet,i,1)
		table.insert(self.maSpriteSets, oSpriteSet)
	end
end

--*******************************************************
function cSpriteGenerator:getRandomSprite()
	local oSprite, iSet
	
	iSet = math.random(1, self.miMaxSprites)
	return self:getSprite(iSet )
	
end

--*******************************************************
function cSpriteGenerator:getSprite(piIndex)
	return sprite.newSprite(self.maSpriteSets[piIndex])
end