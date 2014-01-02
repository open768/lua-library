if not cDebug then require("inc.lib.lib-debug") end
cRequirer = {className = "cRequirer"}
cDebug.instrument(cRequirer)
function cRequirer.include(psPath)
	local oObj
	
	cRequirer:debug(DEBUG__DEBUG, psPath)
	oObj = require(psPath)
	cRequirer:debug(DEBUG__DEBUG, "done: ",  psPath)	
	return oObj
end
