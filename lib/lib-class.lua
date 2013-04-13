--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
if not cDebug then error "cDebug object not found" end

cClass = {className = "cClass"}
cDebug.instrument(cClass)

--***********************************************************
--sets the index function to be the same of another table - thus inheritance
function cClass.setParent( poObj, poParent)
	setmetatable( poObj, { __index = poParent} )  
end

--***********************************************************
function cClass.createGroupInstance(poExemplar)
	local oInstance
	
	if poExemplar==nil then	error ("cClass.CGI no arguments")	end
	if not poExemplar.className then error ("cClass.CGI :exemplar must have property className")	end
	
	cClass:debug(DEBUG__EXTRA_DEBUG, "cClass.CGI create: ", poExemplar.className)
	oInstance = display.newGroup()
	cClass.addParent(oInstance, poExemplar)
	oInstance.className = poExemplar.className

	return oInstance
end

--***********************************************************
--sets the index function to be the same of another table - thus inheritance
function cClass.createInstance(poExemplar)
	local oInstance
	
	if poExemplar ==nil then error ("cClass.CI no arguments")	end
	if poExemplar.className ==nil then	error ("cClass.CI: exemplar must have property className")	end
	
	cClass:debug(DEBUG__EXTRA_DEBUG, "cClass.CI create: ", poExemplar.className)
	oInstance = {}
	oInstance.className = poExemplar.className
	cClass.setParent ( oInstance , poExemplar )  

	return oInstance
end

--***********************************************************
--adds methods from named parent - by copying table
-- not tested
function cClass.addParent( poObj, poParent)
	local sName, vValue
	
	for sName,vValue in pairs(poParent) do
		--if (type(vValue) == 'function') then
		if poObj[sName] then
			cClass:debug(DEBUG__DEBUG, "addParent: " , poParent.className, ".", sName , " exists - skipping")
		else
			--self:debug(DEBUG__DEBUG, "cClass adding ", sName);
			poObj[sName] = vValue
		end
    end
end

--***********************************************************
function cClass.showMembers( poObj)
	local sName, vValue, sType
	
	for sName,vValue in pairs(poObj) do
		sType = type(vValue)
		if (sType == "table") or (sType == "function") then
			print (sName..": ".. sType)
		else
			print (sName..": "..tostring(vValue))
		end
	end
end