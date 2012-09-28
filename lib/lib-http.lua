--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
--
-- BEWARE the useragents set by this module may not match the useragent set by the 
-- device browser , so may result in less/cheaper ads (bad fillrate)
--
local http = require("socket.http")
local ltn12 = require("ltn12")

cHttp = {
	reachableDomain="www.bbc.co.uk",
	isNetReachable = false,
	testMode = false,
	userAgents={
		["Mac OS X"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5",
		Win = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.52 Safari/536.5",
		["iPhone OS"] = "Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
	},
	forceUserAgent = nil,
	userAgent = nil
}

-- **********************************************************
function cHttp:init()
	if network.canDetectNetworkStatusChanges then
		local fnCallBack = function(poEvent) self:netWorkListener(poEvent) end
		network.setStatusListener( self.reachableDomain, fnCallBack )
	else
		self:checkConnectivity()
		cDebug:print(DEBUG__INFO, "cHttp: Net is reachable: ", self.isNetReachable)
	end
end

-- **********************************************************
function cHttp:checkConnectivity()
	local oResponse = http.request("http://"..self.reachableDomain.."/")
	self.isNetReachable = (oResponse ~= nil)
	cDebug:print(DEBUG__INFO, "cHttp: checkConnectivity Net is reachable: ", self.isNetReachable)
	
	return self.isNetReachable
end

-- **********************************************************
function cHttp:get(psUrl)
	local oResponse, oSink
	local rCode,rCount,rHeaders, iLen
	
	if not psUrl then
		cDebug:throw("cHttp:get -- No Url")
	end
	cDebug:print(DEBUG__INFO, "cHttp: URL:", psUrl)
	
	oSink = {}
	rCode,rCount,rHeaders = http.request	({
		url=psUrl,
		sink=ltn12.sink.table(oSink),
		headers={
			Accept="text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
			["Accept-Language"] = "en-GB,en-US;q=0.8,en;q=0.6"
		},
		userAgent=self:getUserAgent()
	})
	sResponse = table.concat(oSink)
	cDebug:print(DEBUG__DEBUG, "cHttp: response=",sResponse)
	cDebug:print(DEBUG__DEBUG, "cHttp: headers=",rHeaders)
	cDebug:print(DEBUG__DEBUG, "cHttp: code=",rCode)
	
	iLen = rHeaders["content-length"] + 0
	if iLen == 0 then
		cDebug:print(DEBUG__ERROR, "no data returned")
		sResponse = nil
	end
	return sResponse
end

-- **********************************************************
-- Decode an URL-encoded string (see RFC 2396)
--from https://github.com/keplerproject/cgilua/blob/master/src/cgilua/urlcode.luaœ
----------------------------------------------------------------------------
function cHttp:unescape (str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

-- **********************************************************
-- URL-encode a string (see RFC 2396)
--from https://github.com/keplerproject/cgilua/blob/master/src/cgilua/urlcode.lua
----------------------------------------------------------------------------
function cHttp:escape (str)
	str = string.gsub (str, "\n", "\r\n")
	str = string.gsub (str, "([^0-9a-zA-Z ])", -- locale independent
		function (c) return string.format ("%%%02X", string.byte(c)) end)
	str = string.gsub (str, " ", "+")
	return str
end

-- **********************************************************
function cHttp:netWorkListener(poEvent)
	self.sNetReachable = poEvent.isReachable
	vardump(poEvent)
	print ("network is reachable "..poEvent.isReachable)
end

-- **********************************************************
-- based on discussion in - http://developer.anscamobile.com/forum/2011/04/30/ads-revenue-examples
-- see http://developer.anscamobile.com/reference/index/systemgetinfo
-- **********************************************************
function cHttp:getUserAgent()
	local sUserAgent, sPlatName, sPlatVersion , sModel
	
	-- returned forced useragent if there - but only once
	if self.forceUserAgent then
		sUserAgent = self.forceUserAgent 
		self.forceUserAgent  = nil
		cDebug:print(DEBUG__INFO, "cHttp: forced useragent=",sUserAgent )
		return sUserAgent 
	end
	
	-- returned remembered useragent if there
	if self.userAgent then
		cDebug:print(DEBUG__INFO, "cHttp: useragent=",sUserAgent )
		return self.userAgent 
	end
	
	-- get all needed information
	sPlatName = system.getInfo("platformName")
	sPlatVersion = system.getInfo("platformVersion")
	sModel = system.getInfo("model")

	-- deal with simulator first - its the easiest
	if utility.isSimulator() and (not self.testMode) then
		sPlatName = system.getInfo("platformName")
		sUserAgent = self.userAgents[sPlatName]
		if not sUserAgent  then
			error ("unknown environment for simulator: ".. sPlatName)
		end
	else
		if sPlatName == "iPhone OS" then
			sUserAgent = "Mozilla/5.0 (iPod; U; CPU "..sModel.." "..sPlatVersion.." like Mac OS X) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
		else
			sUserAgent = "Mozilla/5.0 (Linux; U; Android 2.2; "..sModel.." Build/"..sPlatVersion..") AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5"
		end
	end
	
	-- remember the useragent
	self.userAgent = sUserAgent
	
	cDebug:print(DEBUG__INFO, "cHttp: useragent=",sUserAgent )
	return sUserAgent 
end

-- **********************************************************
cHttp:init()
