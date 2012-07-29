--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require ("inc.lib.lib-debug")

cClass = {}

--***********************************************************
--sets the index function to be the same of another table - thus inheritance
function cClass.setParent( poObj, poParent)
	setmetatable( poObj, { __index = poParent} )  
end

--***********************************************************
function cClass.createGroupInstance(psClassname, poSuperClass)
	local oInstance
	
	if (not psClassname) or (not poSuperClass) then
		error ("createInstance needs 2 arguments")
	end
	
	oInstance = display.newGroup()
	cClass.addParent(oInstance, poSuperClass)
	oInstance.className = psClassname

	return oInstance
end

--***********************************************************
--sets the index function to be the same of another table - thus inheritance
function cClass.createInstance(psClassname, poSuperClass)
	local oInstance
	
	if (not psClassname) or (not poSuperClass) then
		error ("createInstance needs 2 arguments")
	end
	
	oInstance = {}
	oInstance.className = psClassname
	cClass.setParent ( oInstance , poSuperClass )  

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
			cDebug:print(DEBUG__WARN, "warning cClass.addParent: " , sName , " is already defined - skipping")
		else
			--cDebug:print(DEBUG__DEBUG, "cClass adding ", sName);
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