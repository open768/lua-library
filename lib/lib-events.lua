--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-debug"
require "inc.3lib.vardump"

cLibEvents = {}

--*******************************************************
--* call this method to add event listeners to a table 
-- usage dispatchEvent({name="myevent"})
--*******************************************************
function cLibEvents.instrument(poObj)
	if poObj["addListener"] then 
		cDebug:throw(DEBUG__ERROR,"table allready instrumented")
	end
	
	poObj.addListener = cLibEvents.addListener
	poObj.notify = cLibEvents.notify
	poObj._notify = cLibEvents._notify
end

--*******************************************************
-- only one listener per event! could do more
--*******************************************************
function cLibEvents.addListener(poObj,psEvent, poListener)
	if not poObj.EventListeners then
		poObj.EventListeners  = {}
	end
	
	if poObj.EventListeners[psEvent] ~= nil then
		cDebug:throw(DEBUG__ERROR,"listener exists for :", psEvent)
	else
		poObj.EventListeners[psEvent]  = poListener 
	end
end

--*******************************************************
function cLibEvents.notify( poObj, poEvent)
	local bSuccess, retval 
	
	if poEvent  == nil then 
		cDebug:throw(".notify event called? - you meant :notify") 
	end
	
	bSuccess, retval = pcall( poObj._notify, poObj, poEvent)
	if bSuccess then
		return retval 
	else
		cDebug:print(DEBUG__ERROR,"notify failed:", poEvent.name,":", retval)
	end
end

--*******************************************************
function cLibEvents._notify( poObj, poEvent)
	local oListener, sEventNamSWSe, oCall
	local bOk, oStatusOrMsg
	
	sEventName = poEvent.name
	if sEventName == nil then
		cDebug:throw( "no event name")
	end
	
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
				cDebug:throw("callback: ",sEventName, "failed with status", oStatusOrMsg) 
			end
		else
			oCall = oListener[sEventName]
			if oCall then 
				cDebug:print(DEBUG__EXTRA_DEBUG,"cLibEvents calling table listener:" ) 
				bOk,oStatusOrMsg = pcall(oCall, oListener, poEvent)
				if bOk then
					return oStatusOrMsg 
				else
					cDebug:throw("callback: ",sEventName, "failed with status", oStatusOrMsg) 
					return
				end
			else
				cDebug:throw("CLibEvents: method not found on listener -", sEventName)
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
		cDebug:throw(DEBUG__ERROR, "makeEventClosure no listener specified")
	end
	
	fnClosure = function(poEvent)
		local oCall = poListener[psEvent]
		if oCall == nil then
			cDebug:throw(DEBUG__ERROR,"makeEventClosure no method found that corresponds to ", psEvent)
		end
		return oCall(poListener, poEvent)
	end
	
	return fnClosure 
end



