--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-debug"

cLibEvents = {}

--*******************************************************
--* call this method to add event listeners to a table 
-- usage dispatchEvent({name="myevent"})
--*******************************************************
function cLibEvents:instrument(poObj)
	if poObj["addListener"] then 
		cDebug:print(DEBUG__WARN,"table allready instrumented")
		error ("cLibEvents: error")
	end
	
	poObj.addListener = function(poSelf,psEvent, poListener) 
			cLibEvents:addListener(poSelf,psEvent, poListener)
		end
	poObj.notify = function (poSelf,poEvent)
			return cLibEvents:notify(poSelf, poEvent)
		end
end

--*******************************************************
-- only one listener per event! could do more
--*******************************************************
function cLibEvents:addListener(poObj,psEvent, poListener)
	if not poObj.EventListeners then
		poObj.EventListeners  = {}
	end
	
	poObj.EventListeners[psEvent]  = poListener 
end

--*******************************************************
function cLibEvents:notify( poObj, poEvent)
	local bSuccess, retval 
	
	bSuccess, retval = pcall( self._notify, self, poObj, poEvent)
	if bSuccess then
		return retval 
	else
		print ("ERROR:"..retval)
	end
end

--*******************************************************
function cLibEvents:_notify( poObj, poEvent)
	local oListener, sEventNamSWSe, oCall
	local bOk, oStatusOrMsg
	
	if poEvent == nil then
		error ".dispatch event called - you meant :"
	end
	
	sEventName = poEvent["name"]
	
	if not poObj.EventListeners then 
		cDebug:print(DEBUG__INFO, "no event listeners for ", sEventName)
		return;
	end
	
	cDebug:print(DEBUG__EXTRA_DEBUG,"cLibEvents dispatching event: ", sEventName) 
	oListener = poObj.EventListeners[sEventName] 
	if oListener then
		if type(oListener) == "function" then
			cDebug:print(DEBUG__EXTRA_DEBUG,"cLibEvents calling function :" ) 
			bOk,oStatusOrMsg = pcall(oListener, poEvent)
			if bOk then
				return oStatusOrMsg 
			else
				cDebug:print(DEBUG__INFO,"callback failed ", oStatusOrMsg) 
				return
			end
		else
			oCall = oListener[sEventName]
			if oCall then 
				cDebug:print(DEBUG__EXTRA_DEBUG,"cLibEvents calling table listener:" ) 
				bOk,oStatusOrMsg = pcall(oCall, oListener, poEvent)
				if bOk then
					return oStatusOrMsg 
				else
					cDebug:print(DEBUG__INFO,"callback failed", oStatusOrMsg) 
					return
				end
			else
				cDebug:print(DEBUG__ERROR,"CLibEvents: method not found on listener -", sEventName)
				error("cLibEvents error")
			end
		end
	else
		cDebug:print(DEBUG__WARN,"no Listener for event:",sEventName)
	end
end

--*******************************************************
function cLibEvents.makeEventClosure( poListener, psEvent)
	local fnClosure 
	
	if poListener == nil then
		cDebug:print(DEBUG__ERROR, "makeEventClosure no listener specified")
		error ("makeEventClosure error")
	end
	
	fnClosure = function(poEvent)
		local oCall = poListener[psEvent]
		if oCall == nil then
			cDebug:print(DEBUG__ERROR,"makeEventClosure no method found that corresponds to ", psEvent)
			error ("makeEventClosure error")
		end
		return oCall(poListener, poEvent)
	end
	
	return fnClosure 
end



