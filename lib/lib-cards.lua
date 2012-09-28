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
]]--

require ("inc.lib.lib-events")
require "inc.lib.lib-class"
require "analytics"

-- ####################################################################
-- # cards object
-- ####################################################################

cCards = { 
	history = {},
	cards = {},
}

--*******************************************************
function cCards:getScene(psSceneName)
	local oScene
	
	oScene = self.cards[psSceneName]
	if not oScene then
		cDebug:print(DEBUG__DEBUG, " no such scene: ", psSceneName);
	end
	return oScene
end

--*******************************************************
function cCards:createScene(poScene)
	local sSceneName
	
	if not poScene  then
		cDebug:throw("no scene provided for ")
	end
	
	sSceneName = poScene.sceneName  
	if (sSceneName == nil) then
		cDebug:throw("cCards:no sceneName property for scene:", poScene )
	end

	cDebug:print(DEBUG__DEBUG, "creating scene:",sSceneName)
	
-- check whether the scene exists
	if self:getScene(sSceneName )  then
		cDebug:throw("Scene with name :", sSceneName  , " allready exists" )
	end
	
	-- create a scene object
	if not poScene.createScene then
		cDebug:throw("Scene ", sSceneName , "doesnt define createScene")
	end
	if not poScene.createView then
		cDebug:throw("Scene ", sSceneName , "doesnt define createView")
	end
	poScene.view= nil
	poScene:createScene()
	
	-- remember it in the cards table
	self.cards[sSceneName] = poScene
end

--*******************************************************
--* remove the scenes view
function cCards:purgeScene(psSceneName)
	local oScene

	cDebug:print(DEBUG__INFO, "** purging scene: ",psSceneName)
	if (psSceneName == nil) then
		cDebug:throw ("no scene name - perhaps you did a . instead of :")
	end
	
	-- get the scene
	oScene = self:getScene(psSceneName)
	if oScene == nil  then
		cDebug:throw ("no scene exists with name: ", psSceneName  )
	end
	
	-- call listener
	if oScene.destroyScene then 
		cDebug:print(DEBUG__DEBUG, "-- calling destroyScene:")
		oScene:destroyScene()
	end
	
	-- clean out the view
	if oScene.view then
		cDebug:print(DEBUG__DEBUG, "-- deleting view:")
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
		cDebug:throw ("no scene exists with name: ", psSceneName  )
	end
	
	-- hide the current scene
	sCurrent = self:getCurrentSceneName()
	if sCurrent then
		self:hideScene(sCurrent, psEffect, piEffectTime)
	end
	
	self:prv_enterScene(oNewScene)

	-- last thing remember the new scene name
	table.insert(self.history, psSceneName)
end

--*******************************************************
function cCards:hideScene(psSceneName, psEffect, piEffectTime)
	local oScene
	
	cDebug:print(DEBUG__DEBUG, "hiding scene:", psSceneName)
	
	oScene= self:getScene(psSceneName)
	if oScene then
		if oScene.exitScene then 
			cDebug:print(DEBUG__DEBUG, "-- calling exitscene:", psSceneName)
			oScene:exitScene()
		end
		oScene.view.isVisible = false	-- then hide
		
		if oScene.purgeOnExit then
			self:purgeScene(psSceneName)
		end 
	end
end

--*******************************************************
function cCards:getCurrentSceneName()
	local iLen
	
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
		cDebug:print(DEBUG__WARN, "Can't go back in storyboard history")
		return false
	else
		-- hide the current scene
		sNow= table.remove(self.history, iLen) 
		cDebug:print(DEBUG__INFO, "hiding scene:", sNow)
		self:hideScene(sNow, psEffect, piEffectTime)
		
		sLast = self:getCurrentSceneName()
		cDebug:print(DEBUG__INFO, "entering scene:", sLast)
		oScene = self:getScene(sLast)
		self:prv_enterScene(oScene)
	end
end

--*******************************************************
function cCards:prv_enterScene( poScene)
	cDebug:print(DEBUG__DEBUG, "cCards:prv_enterScene:", poScene.sceneName)
	analytics.logEvent("Scene: "..poScene.sceneName)
	
	if not poScene.view then
		cDebug:print(DEBUG__DEBUG, "creating view on scene:", poScene.sceneName)
		poScene.view  = display.newGroup()
		poScene:createView()
	end
	
	if poScene.enterScene then 
		cDebug:print(DEBUG__DEBUG, "-- calling EnterScene:")
		poScene:enterScene()
	end
	
	poScene.view.isVisible = true
end


