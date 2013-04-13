--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.lib.lib-utility"
if not cDebug then require "inc.lib.lib-debug" end

local moAnalytics = require("analytics")

cAnalytics = {className="cAnalytics"}
cDebug.instrument(cAnalytics)

function cAnalytics:init(psID)
	if psID==nil then cDebug:throw("Analytics:init called with a . not a :") end
	
	if utility.isSimulator then
		self:debug(DEBUG__WARN,"** Analytics not available on simulator")
	else
		moAnalytics.init(psID)
	end
end

function cAnalytics.logEvent(psMessage)
	if not utility.isSimulator then
		moAnalytics.logEvent(psMessage)
	end
end
