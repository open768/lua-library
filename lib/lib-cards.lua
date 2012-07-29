--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
--[[
	there are bugs in storyboard which I cant wait around to be fixed
	so this is a simpler replacement for it.
	
	the bug is that scenes that have graphical objects that are 
	partly off screen cause the scene to be moved when it is restored.
	which is pants
	
	STAGE 1 - create a wrapper for storyboard --- DONE
	STAGE 2 - replace the content of the wrapped functions
]]--

require ("inc.lib.lib-events")
require "inc.lib.lib-class"

-- ####################################################################
-- # cardscene object
-- ####################################################################
cDisplayCard = {
	name = nil,
	view = nil,
	purgeOnExit = false
}

function cDisplayCard:create( psName )
	local oInstance = cClass.createInstance("cDisplayCard", cDisplayCard)
	
	cLibEvents:instrument(oInstance)
	oInstance.name = psName
	oInstance.view = nil
	
	return oInstance
end

-- ####################################################################
-- # cards object
-- ####################################################################

cCards = { 
	history = {},
	cards = {},
	event={
		enter = "enterScene",
		exit= "exitScene",
		destroy = "destroyScene"
	}
}

--*******************************************************
function cCards:getScene(psSceneName)
	return self.cards[psSceneName]
end

--*******************************************************
function cCards:createScene(psSceneName)
	cDebug:print(DEBUG__INFO, "creating scene:",psSceneName)
	-- check whether the scene exists
	if self:getScene(psSceneName)  then
		error ("Scene with name :", psSceneName , " allready exists" )
	end
	
	-- create a scene object giving it an empty view and remember it in the cards table
	local oScene = cDisplayCard:create(psSceneName)
	self.cards[psSceneName] = oScene
	
	return oScene
end

--*******************************************************
function cCards:purgeScene(psSceneName)
	local oScene

	cDebug:print(DEBUG__INFO, "purging scene: ",psSceneName)
	if (psSceneName == nil) then
		error ("no scene name - perhaps you did a . instead of :")
	end
	
	-- get the scene
	oScene = self:getScene(psSceneName)
	if oScene == nil  then
		error ("no scene exists with name: ", psSceneName  )
	end
	
	-- call listener
	oScene:notify({name=self.event.destroy})
	
	-- clean out the view
	if oScene.view then
		oScene.view:removeSelf()
		oScene.view = nil
	end
	
end

--*******************************************************
function cCards:gotoScene(psSceneName, psEffect, piEffectTime)
	--print ("going to scene:"..psSceneName)
	local sCurrent, oNewScene, oGroup
	
	cDebug:print(DEBUG__INFO, "going to scene:", psSceneName)
	
	-- get the new scene
	oNewScene = self:getScene(psSceneName)
	if oNewScene == nil  then
		error ("no scene exists with name: ", psSceneName  )
	end
	
	-- hide the current scene
	sCurrent = self:getCurrentSceneName()
	if sCurrent then
		self:hideScene(sCurrent, psEffect, piEffectTime)
	end

	-- create the view if it doesnt exist
	if oNewScene.view == nil then
		cDebug:print(DEBUG__INFO, "creating view on scene:", psSceneName)
		oNewScene.view  = display.newGroup()
		oNewScene:createScene()
	end
	oNewScene.view.isVisible = true
	
	-- enter the scene
	cDebug:print(DEBUG__INFO, "entering scene:", psSceneName)
	oNewScene:notify({name=self.event.enter})

	-- last thing rermember the new scene name
	table.insert(self.history, psSceneName)
end

--*******************************************************
function cCards:hideScene(psSceneName, psEffect, piEffectTime)
	local oScene
	
	cDebug:print(DEBUG__INFO, "hiding scene:", psSceneName)
	
	oScene= self:getScene(psSceneName)
	if oScene then
		oScene:notify({name=self.event.exit})
		oScene.view.isVisible = false	-- then hide
	end
end

--*******************************************************
function cCards:getCurrentSceneName()
	local iLen, sSceneName
	
	iLen = #(self.history)
	if iLen > 0 then
		return  self.history[iLen]
	else
		return nil
	end
end

--*******************************************************
function cCards:goBack( psEffect, piEffectTime)
	local iLen, sNow, sLast, oScene
	
	iLen = #(self.history)
	if iLen < 2 then
		print ("Can't go back in storyboard history")
		return false
	else
		-- hide the current scene
		sNow= table.remove(self.history, iLen) 
		cDebug:print(DEBUG__INFO, "hiding scene:", sNow)
		self:hideScene(sNow, psEffect, piEffectTime)
		
		sLast = self:getCurrentSceneName()
		cDebug:print(DEBUG__INFO, "entering scene:", sLast)
		oScene = self:getScene(sLast)
		oScene:notify({name=self.event.enter})
		oScene.view.isVisible = true
	end
end

