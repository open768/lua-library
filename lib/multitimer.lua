require "inc.lib.lib-class"
require "inc.lib.lib-events"
require "inc.lib.lib-stack"

--########################################################
--#
--########################################################
cMultiTimer = {className="cMultiTimer"}
cLibEvents.instrument(cMultiTimer)

function cMultiTimer:create(piMode)
	local oInstance = cClass.createInstance(self)
	oInstance.items = cLinkedList:create()
	return oInstance
end

--*********************************************************
function cMultiTimer:addTimer(piMSec, psEventName)
	local oList
	
	oList = self.items
	--while true do 
		
	--end
	-- walk the list, add the timer
end

--*********************************************************
function cMultiTimer:play()
end

--*********************************************************
function cMultiTimer:stop()
end


