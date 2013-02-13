--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-utility"

local analytics = require("analytics")

cAnalytics = {}

function cAnalytics:init(psID)
	if utility.isSimulator then
		cDebug:print(DEBUG__WARN,"** Analytics not available on simulator")

	else
		analytics.init(psID)
	end
end

function cAnalytics.logEvent(psMessage)
	if not utility.isSimulator then
		analytics.logEvent(psMessage)
	end
end
