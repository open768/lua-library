--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]

require "inc.lib.lib-utility"

cSettings = { 
	data={},
	filename = "corona_settings.json",
	changed = 0,
	loaded = false
}

--************************************************************************
function  cSettings:load()
	local oData
	
	if self.loaded then return end -- can only load once as file wont change 
	
	oData = utility.loadJson(cSettings.filename, system.DocumentsDirectory)
	if oData  then  
		self.data = oData 
	else
		self.data = {}
	end
	
	self.loaded = true
end

--************************************************************************
function cSettings:get(psKey, psDefault)
	local svalue 
	
	if psKey == nil then
		error "cSettings:Attempting to get with a nil key";
	end
	
	svalue = self.data[psKey]
	if svalue == nil then svalue = psDefault end
	
	return svalue 
end

--************************************************************************
function cSettings:set(psKey, psValue)
	if psKey == nil then
		error "cSettings:Attempting to set with a nil key";
	end
	if self.data[psKey]  ~= psValue then
		self.data[psKey] = psValue
		self.changed = self.changed +1
	end
end

--************************************************************************
function cSettings:commit()
	if self.changed >0 then
		utility.writeJson(self.data, cSettings.filename, system.DocumentsDirectory )
		self.changed  = 0
	end
end

cSettings:load()