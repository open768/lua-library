-- VERSION
-- -- This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
-- -- http://creativecommons.org/licenses/by-sa/3.0/
-- -- Absolutely no warranties or guarantees given or implied - use at your own risk
-- -- Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/

local lfs = require "lfs"

-- **********************************************************
-- * LIB-DEBUG
-- **********************************************************
DEBUG__NONE = 	1
DEBUG__ERROR = 	2
DEBUG__WARN = 	3
DEBUG__INFO = 	4
DEBUG__DEBUG = 	5
DEBUG__EXTRA_DEBUG = 6

local aDebugLevels = {"NONE", "ERROR", "WARN", "INFO", "DEBUG", "EXTDEBUG"}

cDebug = {
	DEBUG_LEVEL=DEBUG__NONE, 
	fileHandle=nil, 
	remoteURL=nil, 
	URLParam="MSG",
	dateFormat="%d/%m/%Y %H:%M:%S",
	droidFolderRoot = "/sdcard",
	folder = "cktmp",
	filename = "debug.txt",
	writeToFile = false,
}

-- **********************************************************
function cDebug:print(piLevel, ...)
	local sDebugMsg, sDate, sText, i, iLen, vArg, aStrings
	
	if (piLevel == nil) then
		error ("cDebug: piLevel is nil - check for typos")
	end
	if (piLevel > self.DEBUG_LEVEL) then return end

	iLen = #arg
	if  iLen == 0 then
		sText = "No message to display"
	else
		aStrings = {}
		sText = ""
		for i=1, iLen do
			vArg = arg[i]
			if vArg == nil then
				table.insert(aStrings,"nil")
			elseif type(vArg)=="string" then
				table.insert(aStrings,vArg)
			else
				table.insert(aStrings,tostring(vArg))
			end
		end	
		sText = table.concat(aStrings, " ")
		aStrings = nil
	end
	
	sDate = os.date(self.dateFormat)
		
	sDebugMsg = aDebugLevels[piLevel]..": "..sDate..": "..sText 
	print ("LOG:"..sDebugMsg)
	self:filePrint(sDebugMsg)
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
	
	if not self.filehandle then
		if system.getInfo("environment") == "simulator" then
			sFolderPath = system.pathForFile( self.folder, system.DocumentsDirectory )
			sFilePath = sFolderPath .. "\\" ..  self.filename
		else
			sFolderPath = self.droidFolderRoot.."/"..self.folder
			sFilePath = sFolderPath .. "/" ..  self.filename
		end
		if not utility.fileExists(sFolderPath) == nil then
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


print "##cDebug needs android permission android.permission.WRITE_EXTERNAL_STORAGE"


