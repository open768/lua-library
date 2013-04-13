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
	className="cFacebook",
	errorEventName="onFBError",
	loginEventName="onFBLogin",
	requestEventName="onFBRequest",
	loggedIn = false,
	fnClosure = nil,
	simulate_error = false,
	sim_bool_return = false,
	min_time = 100, max_time = 200
}
cLibEvents.instrument(cFacebook)
cDebug.instrument(cFacebook)

 --#################################################################
 --#
 --#################################################################
function cFacebook:login(psAppID)
	local oEvent
	
	if utility.isSimulator() then
		self:debug(DEBUG__WARN, "simulating login")
		oEvent = {
			name = "onFBEvent",
			type = "session",
			phase = "login",
			token = "testtokentesttokentesttokentesttoken",
			expiration = "test"
		}
		self:prv__onSimulatedFBEvent(oEvent)
		return
	end
		
	if self.fnClosure == nil then
		self.fnClosure  = cLibEvents.makeEventClosure(self,"onFBEvent")
	end

	self:debug(DEBUG__DEBUG, "attempt login requesting publish_stream")
	facebook.login( psAppID, self.fnClosure, {"publish_stream"}  )
end

--******************************************************************
function cFacebook:logout()
	if not self.loggedIn then
		self:debug(DEBUG__DEBUG, "not logged in")
		return
	end

	if utility.isSimulator() then
		local oEvent = {}
		
		self:debug(DEBUG__WARN, "simulating logout")
		oEvent.type = "session"
		oEvent.phase = "logout"
		
		self:prv__onSimulatedFBEvent(oEvent)
		return
	else
		self:debug(DEBUG__DEBUG, "making fb logout request")
		facebook.logout()
	end
end

--******************************************************************
function cFacebook:post(psGraphID, poParams)
	if not self.loggedIn then
		self:throw("cFacebook - not logged in")
	end
	
	self:debug(DEBUG__DEBUG, "post request  ",psGraphID)
	self.FBResponse = nil
	
	if (poParams == nil) then 
		self:debug(DEBUG__WARN, "post no params provided")
		poParams = {} 
	end

	if utility.isSimulator() then
		local oEvent = {}
		
		self:debug(DEBUG__WARN, "simulating post")
		
		if self.simulate_error then
			self:debug(DEBUG__WARN, "simulating error request")
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
		self:debug(DEBUG__DEBUG, "making fb request")
		facebook.request( psGraphID, "POST", poParams) 
	end
end

--******************************************************************
function cFacebook:request(psGraphID)
	self:debug(DEBUG__DEBUG, "request ",psGraphID)
	self.FBResponse = nil
	
	if utility.isSimulator() then
		local oEvent = {}
		
		self:debug(DEBUG__WARN, "simulating request")
		oEvent.type = "request"
		if self.simulate_error then
			self:debug(DEBUG__WARN, "simulating error request")
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
	self:debug(DEBUG__DEBUG, "like", psGraphID)
	self:post(psGraphID.."/likes")
end

--******************************************************************
function cFacebook:comment(psGraphID, psMessage)
	self:debug(DEBUG__DEBUG, "comment", psGraphID)
	self:post(psGraphID.."/comments", { message=psMessage} )
end

--******************************************************************
--note params can include 
-- message, picture, link, name, caption, description, source, place, tags
function cFacebook:postToWall(pvArg)
	self:debug(DEBUG__DEBUG, "postToWall")
	
	if type(pvArg) == "string" then
		self:debug(DEBUG__DEBUG, "-- simple string", pvArg)
		self:post("me/feed", { message=pvArg} )
	else
		self:debug(DEBUG__DEBUG, "-- complex - table")
		self:post("me/feed", pvArg )
	end
end


 --#################################################################
 --#
 --#################################################################
 function cFacebook:onFBEvent(poEvent)
	local bOK, sErr
	
	self:debug(DEBUG__DEBUG, "onFBEvent")
	self:debug(DEBUG__EXTRA_DEBUG, json.encode(poEvent))
	
	if  (poEvent.type == "session") then
		self:debug(DEBUG__DEBUG, "login event")
		self:prv__onFBLogin(poEvent)
	elseif (poEvent.type == "request") then
		self:debug(DEBUG__DEBUG, "request event")
		self:prv__onFBRequest(poEvent)
	else
		self:debug(DEBUG_ERROR, "unknown event type:", poEvent.type)
	end
end
 
--******************************************************************
--* EVENTS
--******************************************************************
function cFacebook:prv__onSimulatedFBEvent(poEvent)
	local fnClosure, iRnd
	
	iRnd = math.random(self.min_time,self.max_time)
	self:debug(DEBUG__DEBUG, "onSimulatedFBEvent - ", iRnd, "delay")
	fnClosure = function() self:onFBEvent(poEvent) end
	timer.performWithDelay(iRnd, fnClosure)
end
 
--******************************************************************
function cFacebook:prv__onFBLogin(poEvent)
	self:debug(DEBUG__DEBUG, "onFBlogin")
	if poEvent.phase == "login" then
		self:debug(DEBUG__INFO, "login OK")
		
		cSettings:set(FB_TOKEN_KEY, poEvent.token)
		cSettings:set(FB_TOKEN_EXPIRY_KEY, poEvent.expiration)
		cSettings:set(FB_IS_AUTHORISED_KEY, true)
		cSettings:commit()
		self.loggedIn = true
		poEvent.name = self.loginEventName
		
		--login can be ok, without permissions - remember to check permissions next
	elseif poEvent.phase == "logout" then
		self:debug(DEBUG__INFO, "logged out")
		self.loggedIn = false
		poEvent.name = self.loginEventName
	else
		self:debug(DEBUG__ERROR, "login Failed")
		poEvent.name = self.errorEventName
	end	
	
	self:notify(poEvent)
 end
 

 -- *****************************************************************
function cFacebook:prv__onFBRequest(poEvent)
	local oResponse
	
	self:debug(DEBUG__DEBUG, "onFBRequest")
	
	if poEvent.response then
		self:debug(DEBUG__DEBUG, "response:",poEvent.response)
		poEvent.response = json.decode(poEvent.response)
	else
		self:debug(DEBUG__DEBUG, "no response content")
	end
	
	if poEvent.isError then
		self:debug(DEBUG__ERROR, "request Failed")
		self.label.text = "request failed"
		
		poEvent.name = self.errorEventName
		poEvent.response = oResponse
		self:notify(poEvent)
	else
		if (type(poEvent.response) == "table") then
			if (poEvent.response.error) then
				self:debug(DEBUG__ERROR, "request failed")
				self:debug(DEBUG__ERROR, poEvent.response.error.message)
				poEvent.name = self.errorEventName
				self:notify(poEvent)
				return
			end
		end 
		
		self:debug(DEBUG__DEBUG, "request ok")
				
		poEvent.name = self.requestEventName
		self:notify(poEvent)
	end
	
end
 