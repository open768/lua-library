-- VERSION
-- -- This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
-- -- http://creativecommons.org/licenses/by-sa/3.0/
-- -- Absolutely no warranties or guarantees given or implied - use at your own risk
-- -- Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

require "inc.lib.lib-settings"
require "inc.lib.lib-utility"
require "inc.lib.lib-events"
require "inc.lib.lib-debug"

local facebook = require "facebook"
local json = require "json"

 --#################################################################
 --#
 --#################################################################
local FB_TOKEN_KEY = "fbtk"
local FB_TOKEN_EXPIRY_KEY = "fbtek"
local FB_IS_AUTHORISED_KEY = "fbiak"

 
 --#################################################################
 --#
 --#################################################################
 cFacebook = { 
	errorEventName="onFBError",
	loginEventName="onFBLogin",
	requestEventName="onFBRequest",
	loggedIn = false,
	fnClosure = nil,
	simulate_error = false,
	sim_bool_return = false
}
cLibEvents.instrument(cFacebook)

 --#################################################################
 --#
 --#################################################################
function cFacebook:login(psAppID)
	local oEvent = {}
	
	if utility.isSimulator() then
		cDebug:print(DEBUG__WARN, "cFacebook simulating login")
		oEvent.name = "onFBEvent"
		oEvent.type = "session"
		oEvent.phase = "login"
		oEvent.token = "testtokentesttokentesttokentesttoken"
		oEvent.expiration = "test"
		self:prv__onSimulatedFBEvent(oEvent)
		return
	end
		
	if self.fnClosure == nil then
		self.fnClosure  = cLibEvents.makeEventClosure(self,"onFBEvent")
	end

	cDebug:print(DEBUG__DEBUG, "attempt login requesting publish_stream")
	facebook.login( psAppID, self.fnClosure, {"publish_stream"}  )
end

--******************************************************************
function cFacebook:logout()
	if not self.loggedIn then
		cDebug:print(DEBUG__DEBUG, "not logged in")
		return
	end

	if utility.isSimulator() then
		local oEvent = {}
		
		cDebug:print(DEBUG__WARN, "cFacebook simulating logout")
		oEvent.type = "session"
		oEvent.phase = "logout"
		
		self:prv__onSimulatedFBEvent(oEvent)
		return
	else
		cDebug:print(DEBUG__DEBUG, "cFacebook making fb logout request")
		facebook.logout()
	end
end

--******************************************************************
function cFacebook:post(psGraphID, poParams)
	if not self.loggedIn then
		cDebug:throw("cFacebook - not logged in")
	end
	
	cDebug:print(DEBUG__DEBUG, "cFacebook post request  ",psGraphID)
	self.FBResponse = nil
	
	if (poParams == nil) then 
		cDebug:print(DEBUG__WARN, "cFacebook post no params provided")
		poParams = {} 
	end

	if utility.isSimulator() then
		local oEvent = {}
		
		cDebug:print(DEBUG__WARN, "cFacebook simulating post")
		
		if self.simulate_error then
			cDebug:print(DEBUG__WARN, "simulating error request")
			self.simulate_error = false
			oEvent.response = json.encode({error={message="(#506) Duplicate status message",type="OAuthException",code=506}})
		elseif self.sim_bool_return then
			self.sim_bool_return = false
			oEvent.response = json.encode(true)
		else
			oEvent.response = json.encode({id="test",simulated=1})
		end
		oEvent.type = "request"
		self:prv__onSimulatedFBEvent(oEvent)
	else
		cDebug:print(DEBUG__DEBUG, "cFacebook making fb request")
		facebook.request( psGraphID, "POST", poParams) 
	end
end

--******************************************************************
function cFacebook:request(psGraphID)
	cDebug:print(DEBUG__DEBUG, "cFacebook request ",psGraphID)
	self.FBResponse = nil
	
	if utility.isSimulator() then
		local oEvent = {}
		
		cDebug:print(DEBUG__WARN, "cFacebook simulating request")
		oEvent.type = "request"
		if self.simulate_error then
			cDebug:print(DEBUG__WARN, "simulating error request")
			self.simulate_error = false
			oEvent.response = json.encode({error={message="simulated error"}})
		elseif self.sim_bool_return then
			self.sim_bool_return = false
			oEvent.response = json.encode(true)
		else
			oEvent.response = json.encode({simulated=1})
		end
		self:prv__onSimulatedFBEvent(oEvent)
	else
		facebook.request( psGraphID )
	end
end
		
 --#################################################################
 --#
 --#################################################################
function cFacebook:like(psGraphID)
	if utility.isSimulator() then
		self.sim_bool_return = true
	end
	cDebug:print(DEBUG__DEBUG, "cFacebook:like", psGraphID)
	self:post(psGraphID.."/likes")
end

--******************************************************************
function cFacebook:comment(psGraphID, psMessage)
	cDebug:print(DEBUG__DEBUG, "cFacebook:comment", psGraphID)
	self:post(psGraphID.."/comments", { message=psMessage} )
end

--******************************************************************
--note params can include 
-- message, picture, link, name, caption, description, source, place, tags
function cFacebook:postToWall(pvArg)
	cDebug:print(DEBUG__DEBUG, "cFacebook:postToWall")
	
	if type(pvArg) == "string" then
		cDebug:print(DEBUG__DEBUG, "-- simple string", pvArg)
		self:post("me/feed", { message=pvArg} )
	else
		cDebug:print(DEBUG__DEBUG, "-- complex - table")
		self:post("me/feed", pvArg )
	end
end


 --#################################################################
 --#
 --#################################################################
 function cFacebook:onFBEvent(poEvent)
	local bOK, sErr
	
	cDebug:print(DEBUG__DEBUG, "cFacebook:onFBEvent")
	cDebug:print(DEBUG__EXTRA_DEBUG, json.encode(poEvent))
	
	if  (poEvent.type == "session") then
		cDebug:print(DEBUG__DEBUG, "login event")
		self:prv__onFBLogin(poEvent)
	elseif (poEvent.type == "request") then
		cDebug:print(DEBUG__DEBUG, "request event")
		self:prv__onFBRequest(poEvent)
	else
		cDebug:print(DEBUG_ERROR, "unknown event type:", poEvent.type)
	end
end
 
--******************************************************************
--* EVENTS
--******************************************************************
function cFacebook:prv__onSimulatedFBEvent(poEvent)
	local fnClosure, iRnd
	
	iRnd = math.random(400,900)
	cDebug:print(DEBUG__DEBUG, "cFacebook:onSimulatedFBEvent - ", iRnd, "delay")
	fnClosure = function() self:onFBEvent(poEvent) end
	timer.performWithDelay(iRnd, fnClosure)
end
 
--******************************************************************
function cFacebook:prv__onFBLogin(poEvent)
	cDebug:print(DEBUG__DEBUG, "cFacebook:onFBlogin")
	if poEvent.phase == "login" then
		cDebug:print(DEBUG__INFO, "cFacebook: login OK")
		
		cSettings:set(FB_TOKEN_KEY, poEvent.token)
		cSettings:set(FB_TOKEN_EXPIRY_KEY, poEvent.expiration)
		cSettings:set(FB_IS_AUTHORISED_KEY, true)
		cSettings:commit()
		self.loggedIn = true
		poEvent.name = self.loginEventName
		
		--login can be ok, without permissions - go and check permissions
	elseif poEvent.phase == "logout" then
		cDebug:print(DEBUG__INFO, "cFacebook: logged out")
		self.loggedIn = false
		poEvent.name = self.loginEventName
	else
		cDebug:print(DEBUG__ERROR, "cFacebook: login Failed")
		poEvent.name = self.errorEventName
	end	
	
	self:notify(poEvent)
 end
 

 -- *****************************************************************
function cFacebook:prv__onFBRequest(poEvent)
	local oResponse
	
	cDebug:print(DEBUG__DEBUG, "cFacebook:onFBRequest")
	
	if poEvent.response then
		cDebug:print(DEBUG__DEBUG, "response:",poEvent.response)
		poEvent.response = json.decode(poEvent.response)
	else
		cDebug:print(DEBUG__DEBUG, "no response content")
	end
	
	if poEvent.isError then
		cDebug:print(DEBUG__ERROR, "request Failed")
		self.label.text = "request failed"
		
		poEvent.name = self.errorEventName
		poEvent.response = oResponse
		self:notify(poEvent)
	else
		if (type(poEvent.response) == "table") then
			if (poEvent.response.error) then
				cDebug:print(DEBUG__ERROR, "request failed")
				cDebug:print(DEBUG__ERROR, poEvent.response.error.message)
				poEvent.name = self.errorEventName
				self:notify(poEvent)
				return
			end
		end 
		
		cDebug:print(DEBUG__DEBUG, "request ok")
				
		poEvent.name = self.requestEventName
		self:notify(poEvent)
	end
	
end
 