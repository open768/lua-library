cStrings = {}

local CAP_A = string.byte("A")
local CAP_Z = string.byte("Z")
local LOW_A = string.byte("a")
local LOW_Z = string.byte("b")
local TOSTRING_MAX_DEPTH = 1


--*******************************************************
function cStrings.splitString(psString)
	local aStrings = {}
	cDebug:print(DEBUG__EXTRA_DEBUG, " splitting text: ", psString)
	cStrings.prv__splitString(aStrings,psString)
	return aStrings
end

--*******************************************************
function cStrings.prv__splitString(paArray, psString)
	local iPos, sL, sR
	
	iPos = psString:find("[%s;:,-%.]")
	if iPos == nil then
		table.insert(paArray, psString)
	else
		sL = psString:sub(1,iPos)
		sR = psString:sub(iPos+1)

		table.insert(paArray, sL)
		cStrings.prv__splitString(paArray, sR)
	end
end

--*******************************************************
function cStrings.extract(psStr, psStart, psEnd)
	local aStart, aEnd, sExtract
	local aStart = {}
	local aEnd={}
	
	aStart[1],aStart[2] = psStr:find(psStart) 
	aEnd[1],aEnd[2] = psStr:find(psEnd) 
	return psStr:sub( aStart[2]+1, aEnd[1]-1)
end

-- **********************************************************
function cStrings.findNoCase(psStr, psWhat)
	return string.find( string.lower(psStr), string.lower(psWhat),1)
end

-- **********************************************************
function cStrings.isUpper( psChar)
	local iCode = string.byte(psChar)
	return (( iCode >= CAP_A) and (iCode <= CAP_Z))
end

-- **********************************************************
function cStrings.isLower( psChar)
	local iCode = string.byte(psChar)
	return (( iCode >= LOW_A) and (iCode <= LOW_Z))
end

-- **********************************************************
function cStrings.isAlpha( psChar)
	return ( cStrings.isUpper(psChar) or cStrings.isLower(psChar))
end

-- **********************************************************
function cStrings.isVowel(psChar)
    return ( string.find( "AEIOUaeiou", psChar) ~= nil )
end

-- **********************************************************
function cStrings.isConsonant(psChar)
    return ( cStrings.isAlpha( psChar) and not cStrings.isVowel(psChar))
end

-- **********************************************************
function cStrings.toString(...)
	local arg={...}
	local aStrings, i, vArg, sTxt
	
	aStrings = {}
	iLen = #arg
	
	for i=1, iLen do
		vArg = arg[i]
		sTxt = cStrings.prv__toString(vArg, 0)
		table.insert (aStrings, sTxt)
	end	

	return table.concat(aStrings, "")
end

--########################################################
--########################################################
function cStrings.prv__toString(pvWhat, piLevel)
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
			if piLevel < TOSTRING_MAX_DEPTH then
				for k,v in pairs(pvWhat) do
					table.insert (aStrings, "{"..cStrings.prv__toString(k, piLevel +1)..":")
					table.insert (aStrings, cStrings.prv__toString(v, piLevel +1).."}")
				end
			end
			table.insert (aStrings, "]")
		elseif (sType=="function") then
			table.insert(aStrings,"<function>")
		elseif (sType=="number" or sType=="boolean" ) then
			table.insert(aStrings,tostring(pvWhat))
		else
			table.insert(aStrings,"{"..sType.."}")
			table.insert(aStrings,tostring(pvWhat))
		end
	end
	
		
	return table.concat(aStrings, "")
end
--print (cStrings.isUpper("c"), cStrings.isUpper("F"))

