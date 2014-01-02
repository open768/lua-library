-- Code from: http://lua-users.org/wiki/LuaXml
-----------------------------------------------------------------------------------------
-- LUA only XmlParser from Alexander Makeev
-----------------------------------------------------------------------------------------

XmlParser = {};

-- ****************************************************************************
function XmlParser:ToXmlString(value)
	value = string.gsub (value, "&", "&amp;");		-- '&' -> "&amp;"
	value = string.gsub (value, "<", "&lt;");		-- '<' -> "&lt;"
	value = string.gsub (value, ">", "&gt;");		-- '>' -> "&gt;"
	--value = string.gsub (value, "'", "&apos;");	-- '\'' -> "&apos;"
	value = string.gsub (value, "\"", "&quot;");	-- '"' -> "&quot;"
	-- replace non printable char -> "&#xD;"
   	value = string.gsub(value, "([^%w%&%;%p%\t% ])",
       	function (c) 
       		return string.format("&#x%X;", string.byte(c)) 
       	end);
	return value;
end

-- ****************************************************************************
function XmlParser:FromXmlString(value)
  	value = string.gsub(value, "&#x([%x]+)%;",
      	function(h) 
      		return string.char(tonumber(h,16)) 
      	end);
  	value = string.gsub(value, "&#([0-9]+)%;",
      	function(h) 
      		return string.char(tonumber(h,10)) 
      	end);
	value = string.gsub (value, "&quot;", "\"");
	value = string.gsub (value, "&apos;", "'");
	value = string.gsub (value, "&gt;", ">");
	value = string.gsub (value, "&lt;", "<");
	value = string.gsub (value, "&amp;", "&");
	return value;
end
   
-- ****************************************************************************
function XmlParser:ParseArgs(s)
  local arg = {}
  string.gsub(s, "([%w\:]+)=([\"'])(.-)%2", function (w, _, a)
    	arg[w] = self:FromXmlString(a);
  	end)
  return arg
end

-- ****************************************************************************
function XmlParser:ParseXmlText(xmlText)
  local stack = {}
  local top = {Name=nil,Value=nil,Attributes={},ChildNodes={}}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(xmlText, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(xmlText, i, ni-1);
    if not string.find(text, "^%s*$") then
      top.Value=(top.Value or "")..self:FromXmlString(text);
    end
    if empty == "/" then  -- empty element tag
      table.insert(top.ChildNodes, {Name=label,Value=nil,Attributes=self:ParseArgs(xarg),ChildNodes={}})
    elseif c == "" then   -- start tag
      top = {Name=label, Value=nil, Attributes=self:ParseArgs(xarg), ChildNodes={}}
      table.insert(stack, top)   -- new level
      --print("openTag ="..top.Name);
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      --print("closeTag="..toclose.Name);
      top = stack[#stack]
      if #stack < 1 then
        error("XmlParser: nothing to close with "..label)
      end
      if toclose.Name ~= label then
        error("XmlParser: trying to close "..toclose.Name.." with "..label)
      end
      table.insert(top.ChildNodes, toclose)
    end
    i = j+1
  end
  local text = string.sub(xmlText, i);
  if not string.find(text, "^%s*$") then
      stack[#stack].Value=(stack[#stack].Value or "")..self:FromXmlString(text);
  end
  if #stack > 1 then
    error("XmlParser: unclosed "..stack[stack.n].Name)
  end
  return stack[1].ChildNodes[1];
end

-- ****************************************************************************
function XmlParser:ParseXmlFile(xmlFileName)
	local hFile,err = io.open(xmlFileName,"r");
	if (not err) then
		local xmlText=hFile:read("*a"); -- read file content
		io.close(hFile);
        return self:ParseXmlText(xmlText),nil;
	else
		return nil,err;
	end
end


-- ****************************************************************************
-- Added by SV 250412
function XmlParser.findNode( psName, poNode, pbRecursive, pbError)
	local oNode
	
	oNode = XmlParser._findNode(psName:upper(), poNode, pbRecursive)
	if oNode then
		return oNode
	elseif pbError then
		error ("XMLParser couldnt find node ".. psName)
	else
		cDebug:print(DEBUG__INFO, "XMLParser couldnt find node ", psName)
		return nil
	end
end

-- ****************************************************************************
-- Added by SV 250412
function XmlParser._findNode( psName, poNode, pbRecursive)
	local aChild, sKey, oChild, oNode
	
	if poNode.Name:upper() == psName then
		return poNode
	elseif pbRecursive and poNode.ChildNodes then
		for sKey,oChild in pairs(poNode.ChildNodes) do
			oNode = XmlParser._findNode( psName, oChild, pbRecursive)
			if oNode  then return oNode end
		end
	end
	
	return nil
end

-- ****************************************************************************
-- Added by SV 250412
function XmlParser.getNodeAttr(psAttrName, poNode)
	local sKey, sValue, sUpper
	
	sUpper = psAttrName:upper()
	cDebug:print(DEBUG__INFO, "looking for: ", psAttrName)
	
	if poNode.Attributes then
		for sKey,sValue in pairs(poNode.Attributes ) do
			if sKey:upper() == sUpper then 
				return sValue 
			end
		end
	else
		error "no attributes found"
	end
	
	cDebug:print(DEBUG__INFO, "XmlParser: couldnt find attribute: ",psAttrName)
	return nil
end


