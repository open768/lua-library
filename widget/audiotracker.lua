--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2013 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.lib.lib-colours"

--########################################################
--# CLASS
--########################################################
cTimeMarker= {
	className="cTimeMarker", 
	eventName="onTimeEvent"
}
cLibEvents.instrument(cTimeMarker)
cDebug.instrument(cTimeMarker)

--*******************************************************
function cTimeMarker:create( piWidth, piHeight)
	oInstance = cClass.createGroupInstance(self)
	oInstance:prv_init(piWidth, piHeight)
	return oInstance
end

--########################################################
--# Publics
--########################################################
function cTimeMarker:addMarker(piTime, psName, psColour)
end

--*******************************************************
function cTimeMarker:deleteMarker( psName)
end

--*******************************************************
function cTimeMarker:moveMarker( psName, piTime)
end

--*******************************************************
function cTimeMarker:go( piTime)
end

--*******************************************************
function cTimeMarker:stop( )
end

--########################################################
--# Privates
--########################################################
function cTimeMarker:prv_init( piWidth, piHeight)
	self.markers = {}
	self.nextEvent = nil
	-- create a square for now
end

