--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-utility"
require "inc.lib.lib-draggable"
require "inc.lib.lib-class"

--[[
example map 
local aMap= {
		{
			sprite = "dash.png",
			name = "dash",
			x=0,
			y=0,
			hidden=false,
			fixed=true
		}
		...
	}
return aMap
--]]

cObjMaker = { className="cObjMaker", draggable = true}
cDebug.instrument(cObjMaker)

--*******************************************************
function cObjMaker:create( psSpriteFile, poSpriteData, paMap)
	local oInstance
	
	self:debug(DEBUG__EXTRA_DEBUG, "creating")
	-- validate 
	if (psSpriteFile==nil) then self:throw("no sprite file") end
	if (poSpriteData==nil) then self:throw("no sprite data") end
	if (paMap==nil) then self:throw("no character mapping") end

	-- create an instance and initialise
	oInstance = cClass.createGroupInstance(self)
	
	oInstance.objects = {}
	oInstance.spriteSheet = nil
	
	oInstance:_initobjmaker(psSpriteFile, poSpriteData, paMap)
	self:debug(DEBUG__EXTRA_DEBUG, "finished")

	-- return instance
	return oInstance
end

--*******************************************************
function cObjMaker:_initobjmaker( psSpriteFile, poSpriteData, paMap)
	local iItem, oItem, sSpriteName
	local aSpriteSets, oSprite, oDraggable
	
	-- load up the spritesheet
	aSpriteSets = utility.getSpriteSets(psSpriteFile, poSpriteData)
	
	-- work through map building the image
	for iItem=1,#paMap do
	
		-- create the sprite
		oItem = paMap[iItem]
		sSpriteName = oItem.sprite
		--self:debug(DEBUG__DEBUG, "cObjMaker:", "sprite: ", sSpriteName )

		oSet = aSpriteSets[sSpriteName]
		if oSet == nil then 
			self:throw("no sprite found for mapping ",sSpriteName)	
		end
		oSprite = sprite.newSprite(oSet)
		--self:debug(DEBUG__DEBUG, "w:", oSprite.width, ",h:", oSprite.height )
		
		oSprite.id = oItem.name
		
		-- add to the group and move as described
		self:insert(oSprite)
		self.objects[oItem.name] = oSprite
		
		oSprite:setReferencePoint(display.BottomLeftReferencePoint)
		oSprite.x = oItem.x
		oSprite.y = oItem.y
		--self:debug(DEBUG__DEBUG, "x:", oItem.x, ",y:", oItem.y )
		
		if oItem.hidden then
			oSprite.isVisible = false
		end
		
		-- allow drag
		if self.draggable and not oItem.fixed then
			oDraggable = cDraggable:create(oSprite)
			oDraggable.usePhysics = false
			oDraggable:addListener("onDrag", self)
		end
	end
end

--*******************************************************
function cObjMaker:onDrag(poEvent)
	local oObj
	
	if poEvent.phase == "ended" then
		oObj = poEvent.source.thing
		self:debug(DEBUG__DEBUG, "dragged:", oObj.id, " ", oObj.x, ",", oObj.y)
	end
	return true
end

--*******************************************************
function cObjMaker:get(psName)
	return self.objects[psName]
end

