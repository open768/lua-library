cStrings = {}

local CAP_A = string.byte("A")
local CAP_Z = string.byte("Z")
local LOW_A = string.byte("a")
local LOW_Z = string.byte("b")

function cStrings.isUpper( psChar)
	local iCode = string.byte(psChar)
	return (( iCode >= CAP_A) and (iCode <= CAP_Z))
end

function cStrings.isLower( psChar)
	local iCode = string.byte(psChar)
	return (( iCode >= LOW_A) and (iCode <= LOW_Z))
end

function cStrings.isAlpha( psChar)
	return ( cStrings.isUpper(psChar) or cStrings.isLower(psChar))
end

function cStrings.isVowel(psChar)
    return ( string.find( "AEIOUaeiou", psChar) ~= nil )
end

function cStrings.isConsonant(psChar)
    return ( cStrings.isAlpha( psChar) and not cStrings.isVowel(psChar))
end

--print (cStrings.isUpper("c"), cStrings.isUpper("F"))

