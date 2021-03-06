--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

Usage
	require "lib-events"
	local myTable1 = {}
	cLibEvents.instrument(myTable1)  -- adds methods to table1
	function myTable1:myfunction() 
		...
		self:notify({name="myeventname", ...}) -- fires the event
	end
	
	local myTable2 = {}
	function myTable2:myeventname(poEvent)		-- receives the event
		...
	end
	myTable1:addListener("myeventname", myTable2) -- registers the listener
	
--]]
require "inc.lib.lib-debug"

cLibEvents = {timerDelay = 0, className="cLibEvents"}
cDebug.instrument(cLibEvents)

--*******************************************************
--* transparently instruments the passed in class
--*******************************************************
function cLibEvents.instrument(poObj)
	if poObj["addListener"] then 
		cLibEvents:throw("table allready instrumented")
	end
	
	poObj.addListener = cLibEvents.addListener
	poObj.notify = cLibEvents.notify
	poObj.prv__notify = cLibEvents.prv__notify
end

--*******************************************************
-- only one listener per event! could do more
--*******************************************************
function cLibEvents.addListener(poObj,psEvent, poListener)
	if type(psEvent) ~= "string" then
		cLibEvents:throw("addListener: event not a string\n")
	end
	
	if not poObj.EventListeners then
		poObj.EventListeners  = {}
	end
	
	if poObj.EventListeners[psEvent] ~= nil then
		cLibEvents:throw("listener exists for :", psEvent)
	else
		poObj.EventListeners[psEvent]  = poListener 
	end
end

--*******************************************************
-- notify should be asynchronous
function cLibEvents.notify( poObj, poEvent)
	local bSuccess, retval, fnPayload
	
	if poEvent  == nil then 
		cLibEvents:throw(".notify event called? - you meant :notify") 
	end
	
	fnPayload = 
		function ()
			local bSuccess, retval
			bSuccess, retval = pcall( poObj.prv__notify, poObj, poEvent)
			if not bSuccess then
				cLibEvents:debug(DEBUG__ERROR,"notify failed:", poEvent.name,":", retval)
			end
		end
	timer.performWithDelay( cLibEvents.timerDelay, fnPayload )
end

--*******************************************************
function cLibEvents.prv__notify( poObj, poEvent)
	local oListener, sEventNamSWSe, oCall
	local bOk, oStatusOrMsg
	
	sEventName = poEvent.name
	if sEventName == nil then
		cLibEvents:throw( "no event name")
	end
	
	if not poObj.EventListeners then 
		cLibEvents:debug(DEBUG__WARN, "no event listeners at all! event was", sEventName)
		return;
	end
	
	cLibEvents:debug(DEBUG__EXTRA_DEBUG,"dispatching event: ", sEventName) 
	oListener = poObj.EventListeners[sEventName] 
	if oListener then
		if type(oListener) == "function" then
			cLibEvents:debug(DEBUG__EXTRA_DEBUG,"calling function :" ) 
			bOk,oStatusOrMsg = pcall(oListener, poEvent)
			if bOk then
				return oStatusOrMsg 
			else
				cLibEvents:throw("callback: ",sEventName, "failed with status", oStatusOrMsg) 
			end
		else
			oCall = oListener[sEventName]
			if oCall then 
				cLibEvents:debug(DEBUG__EXTRA_DEBUG,"calling table listener:" ) 
				bOk,oStatusOrMsg = pcall(oCall, oListener, poEvent)
				if bOk then
					return oStatusOrMsg 
				else
					cLibEvents:throw("callback: ",sEventName, "failed with status", oStatusOrMsg) 
					return
				end
			else
				cLibEvents:throw("method not found on listener -", sEventName)
			end
		end
	else
		cLibEvents:debug(DEBUG__WARN,"no Listener for event:",sEventName)
		cLibEvents:debug(DEBUG__EXTRA_DEBUG,"Listeners were: ",poObj.EventListeners)
	end
end

--*******************************************************
function cLibEvents.makeEventClosure( poListener, psEvent)
	local fnClosure 
	
	if poListener == nil then
		cLibEvents:throw("no listener specified")
	end
	
	fnClosure = function(poEvent)
		local oCall = poListener[psEvent]
		if oCall == nil then
			cLibEvents:throw("no method found that corresponds to ", psEvent)
		end
		return oCall(poListener, poEvent)
	end
	
	return fnClosure 
end



