--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
cAccelerometer = { minChange=1}

--*******************************************************
function cAccelerometer:keepVertical( poGraphics)
	local fnCallback 
	
	if utility.isSimulator() then
		fnCallback = function(poEvent) 	self:orientation(poEvent, poGraphics) end
		Runtime:addEventListener( "orientation", fnCallback )
	else
		fnCallback = function(poEvent) 	self:accelerometer(poEvent, poGraphics) end
		Runtime:addEventListener( "accelerometer", fnCallback )
	end
	
	return fnCallback
end

function cAccelerometer:pause( pfnListener)
	if utility.isSimulator() then
		Runtime:removeEventListener( "orientation", pfnListener )
	else
		Runtime:removeEventListener( "accelerometer", pfnListener )
	end
end

function cAccelerometer:resume( pfnListener)
	if utility.isSimulator() then
		Runtime:addEventListener( "orientation", pfnListener )
	else
		Runtime:addEventListener( "accelerometer", pfnListener )
	end
end

--*******************************************************
function cAccelerometer:accelerometer(poEvent, poGraphics)
	local iNewAngle, bDoIt
	
	iNewAngle = utility.getAngle(poEvent.xGravity, poEvent.yGravity)
	poGraphics.lastAngle = iNewAngle
	poGraphics.rotation = iNewAngle
end

--*******************************************************
function cAccelerometer:orientation(poEvent, poGraphics)
	local aVector, iAngle
	
	aVector = utility.OrientationGravity[poEvent.type]
	iAngle = utility.getAngle(aVector.x, aVector.y)
	transition.to( poGraphics, {rotation = iAngle} )
end

