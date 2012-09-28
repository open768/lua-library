-- VERSION
-- -- This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
-- -- http://creativecommons.org/licenses/by-sa/3.0/
-- -- Absolutely no warranties or guarantees given or implied - use at your own risk
-- -- Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

local lfs = require "lfs"
require "inc.lib.lib-settings"

-- **********************************************************
-- * LIB-DEBUG
-- **********************************************************
DEBUG__NONE = 	1
DEBUG__ERROR = 	2
DEBUG__WARN = 	3
DEBUG__INFO = 	4
DEBUG__DEBUG = 	5
DEBUG__EXTRA_DEBUG = 6
DEBUG_MAX_DEPTH = 1

local aDebugLevels = {"NONE", "ERROR", "WARN", "INFO", "DEBUG", "EXTDEBUG"}

cDebug = {
	DEBUG_LEVEL=DEBUG__NONE, 
	fileHandle=nil, 
	remoteURL=nil, 
	URLParam="MSG",
	dateFormat="%d/%m/%Y %H:%M:%S",
	writeToFile = false,
	packageName = "corona application"
}

local DEBUG__FOLDER = "cktmp"
local DEBUG__FILENAME = "debug.txt"
local DEBUG__DROIDROOT = "/sdcard"
local DEBUG__KEY_LEVEL = "duckl"
local DEBUG__KEY_WRITEFILE ="duckwife"

-- **********************************************************
function cDebug:loadState()
	self.DEBUG_LEVEL = cSettings:get(DEBUG__KEY_LEVEL, DEBUG__NONE )
	self.writeToFile = cSettings:get(DEBUG__KEY_WRITEFILE, false)
end

function cDebug:saveState()
	cSettings:set(DEBUG__KEY_LEVEL, self.DEBUG_LEVEL)
	cSettings:set(DEBUG__KEY_WRITEFILE, self.writeToFile)
	cSettings:commit()
end

-- **********************************************************
function cDebug:printOnce(piLevel, ...)
	local sID
	local aArg = {}
	
	local sID = self.toString(...)
	
	if not self.onceMemory then
		self.onceMemory = {}
	end
	
	if not self.onceMemory[sID] then
		self:print(piLevel, sID)
		self.onceMemory[sID]  = true
	end
end

-- **********************************************************
function cDebug.toString(...)
	local arg={...}
	local aStrings, i, vArg, sTxt
	
	aStrings = {}
	iLen = #arg
	
	for i=1, iLen do
		vArg = arg[i]
		sTxt = cDebug.prv__toString(vArg, 0)
		table.insert (aStrings, sTxt)
	end	

	return table.concat(aStrings, "")
end

-- **********************************************************
function cDebug.prv__toString(pvWhat, piLevel)
	local aStrings, i, sType, k,v

	aStrings = {}

	if pvWhat == nil then
		table.insert(aStrings,"nil")
	else
		sType = type(pvWhat)
		if (sType=="string") then
			table.insert(aStrings,pvWhat)
		elseif (sType=="table") then
			table.insert (aStrings, "table[")
			if piLevel < DEBUG_MAX_DEPTH then
				for k,v in pairs(pvWhat) do
					table.insert (aStrings, "{"..cDebug.prv__toString(k, piLevel +1)..":")
					table.insert (aStrings, cDebug.prv__toString(v, piLevel +1).."}")
				end
			end
			table.insert (aStrings, "]")
		elseif (sType=="function") then
			table.insert(aStrings,"<function>")
		else
			table.insert(aStrings,"{"..sType.."}")
			table.insert(aStrings,tostring(pvWhat))
		end
	end
	
		
	return table.concat(aStrings, "")
end

-- **********************************************************
function cDebug:print(piLevel, ...)
	local sDebugMsg, sDate, sText
	local arg={...}
	
	if (piLevel == nil) then
		error ("cDebug: piLevel is nil - check for typos")
	end
	if (piLevel > self.DEBUG_LEVEL) then return end

	if  iLen == 0 then
		sText = "No message to display"
	else
		sText = self.toString(...)
	end
	
	sDate = os.date(self.dateFormat)
		
	sDebugMsg = aDebugLevels[piLevel]..": "..sDate..": "..sText 
	
	self:prv__print(sDebugMsg)
	
	if piLevel == DEBUG__ERROR then
		sTraceback = cDebug.getTraceBack()
		if sTraceback  then
			self:prv__print(sTraceback )
		end
	end
	
end

-- **********************************************************
function cDebug:prv__print(psMsg)
	print ("LOG:",psMsg )
	self:filePrint(psMsg)
end

-- **********************************************************
function cDebug:throw(...)
	cDebug:print(DEBUG__ERROR, ...)
	error(table.concat({...}," "))
end

-- **********************************************************
function cDebug:getTraceBack()
	local aStrings = {}
    local iLevel = 0
	local sLine, aInfo, sName, sSrc, sLineNo
	
	table.insert(aStrings, "***** start TRACEBACK *****")
    while true do
        aInfo = debug.getinfo(iLevel, "nSl")
        if not aInfo  then break end
		
		sName = utility.defaultValue(aInfo.name, "unknown")
		sLineNo= utility.defaultValue(aInfo.linedefined, "unknown")
		sSrc = utility.defaultValue(aInfo.source, "unknown")
		sLine = sName.. " at line "..sLineNo .." in "..sSrc
		
		if not string.find( sSrc, "debug") and (sName ~= "pcall") and (sName ~= "getinfo") then
			table.insert(aStrings, sLine)
		end
		
		--[[
		local sKey, oValue
		sLine = ""
		for sKey,oValue in pairs(aInfo) do
			sLine = sLine.."\n"..sKey.."="..tostring(oValue)
		end
		table.insert(aStrings, sLine)
		--]]
		
        iLevel = iLevel + 1
    end	
	table.insert(aStrings, "***** end TRACEBACK *****")
	
	return table.concat(aStrings ,"\n")
end

-- **********************************************************
function cDebug:filePrint(psMessage)
	local sFolderPath, sFilePath, sErr

	if not self.writeToFile then
		return
	end
	
	if system.getInfo("platformName") == "iPhone OS" then
		print "debug fileprint not supported on IOS"
		return
	end	
	
	if self.filehandle == nil then
		if system.getInfo("environment") == "simulator" then
			sFolderPath = system.pathForFile( DEBUG__FOLDER, system.DocumentsDirectory )
			sFilePath = sFolderPath .. "\\" ..  DEBUG__FILENAME
		else
			sFolderPath = DEBUG__DROIDROOT.."/"..DEBUG__FOLDER
			sFilePath = sFolderPath .. "/" ..  DEBUG__FILENAME
		end
		if not utility.fileExists(sFolderPath) then
			--os.execute('mkdir "'..sFolderPath..'"')
			lfs.mkdir(sFolderPath)
		end
		
		self.filehandle, sErr = io.open( sFilePath, "a" )
		if not self.filehandle then 
			print ("Error opening file:",sFilePath, "\n", sErr)
		end
	end
	self.filehandle:write(psMessage, "\n")
	self.filehandle:flush()
end

cDebug:loadState()
print "##cDebug needs android permission android.permission.WRITE_EXTERNAL_STORAGE"


