--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
local json = require "json"


-- **********************************************************
-- * UTILITY CLASS 
-- **********************************************************
cJson = {}
-- cant instrument cDebug as cDebug uses this indirectly

-- *********************************************************
-- adapted from 
-- http://blog.anscamobile.com/2011/08/tutorial-exploring-json-usage-in-corona/
 function cJson.loadJson ( psfilename, psFolder )
	local sPath, sData, oFile, oJson
	
	-- set default base dir if none specified
	if not psFolder then psFolder = system.ResourceDirectory; end

	-- create a file path for corona i/o
	sPath = system.pathForFile( psfilename, psFolder )
	if cDebug then
		cDebug:print(DEBUG__DEBUG, "cJson: file ",  sPath)
	end

	-- io.open opens a file at path. returns nil if no file found
	local oFile = io.open( sPath, "r" )
	if oFile then
		-- read all contents of file into a string
		sData = oFile:read( "*a" )
		io.close( oFile )	-- close the file after using it

		-- convert to json 
		oJson = json.decode(sData)
		if (not oJson) and cDebug then
			cDebug:throw("cJson: check for syntax errors in: file ",  sPath)
		end
	   
	elseif cDebug then
		cDebug:print(DEBUG__DEBUG, "cJson: no file found: ",  sPath)
	end

	return oJson
end

-- *********************************************************
-- adapted from 
 function cJson.writeJson ( poData, psfilename, psFolder)
	local sPath, sData, oFile, oJson
	
	-- set default base dir if none specified
	if not psFolder then psFolder = system.DocumentsDirectory; end
	
	-- create a file path for corona i/o
	sPath = system.pathForFile( psfilename, psFolder )

	-- io.open opens a file at path. returns nil if no file found
	local oFile = io.open( sPath, "w" )
	if oFile then
	   -- convert to jSON
	   sData = json.encode(poData)
	   oFile:write( sData )
	   io.close( oFile )	-- close the file after using it
	else
		error ("couldnt write file "..psfilename)
	end
end
