--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "sprite"
require "inc.lib.lib-class"

cSpriteGenerator = {className="cSpriteGenerator"}


--*******************************************************
function cSpriteGenerator:create(psImageFile, piSpriteWidth, piSpriteHeight, piMaxSprites)
	-- arcane lua instance creation 
	local oInstance = cClass.createInstance(self)
	
	oInstance.maSpriteSets = {}
	oInstance.miMaxSprites = piMaxSprites
	oInstance:init(psImageFile, piSpriteWidth, piSpriteHeight)
	
	return oInstance
end

--*******************************************************
function cSpriteGenerator:init(psImageFile, piSpriteWidth, piSpriteHeight)
	oSheet = sprite.newSpriteSheet(psImageFile, piSpriteWidth, piSpriteHeight)
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