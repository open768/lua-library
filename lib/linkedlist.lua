require "inc.lib.lib-class"
require "inc.lib.lib-debug"

--########################################################
--#
--########################################################
cLinkedListNode = {className="cLinkedListNode", data=nil, next=nil, previous=nil}

function cLinkedListNode:create(poData)
	local oInstance = cClass.createInstance(self)
	oInstance.data = poData
	oInstance.previous = nil
	oInstance.next = nil
	return oInstance
end

--*********************************************************
function cLinkedListNode:add(poData)
	local oNewList
	oNewList = cLinkedListNode:create(poData)
	oNewList.previous = self
	self.next = oNewList
end

--*********************************************************
function cLinkedListNode:prv__addComparatively(poData,pfnCmp)
	local bResult
	
	bResult = pfnCmp(self.data, poData)
	if bResult == -1 then   
		-- smaller
		self:prv__addPrevious(poData)
	elseif bResult == 1 then
		-- larger
		if self.next then
			self.next:prv__addComparatively(poData,pfnCmp)
		else
			self:add(poData)
		end
	else
		-- the same
		self.data = poData
	end
end

--*********************************************************
function cLinkedListNode:prv__addPrevious(poData)
	local oNewList
	if self.previous == nil then
		self:throw("previous node is nil")
	else
		oNewList = cLinkedListNode:create(poData)
		oNewList.next = self
		oNewList.previous = self.previous
		self.previous.next = oNewList
		self.previous = oNewList
	end
end


--########################################################
--#
--########################################################
cLinkedList = {className="cLinkedList", data=nil}
cDebug.instrument(cLinkedList)

--*********************************************************
function cLinkedList:create()
	local oInstance = cClass.createInstance(self)
	oInstance.list = nil
	return oInstance
end

--*********************************************************
function cLinkedList:addComparatively(poData, pfnCmp)
	local bReturn, oItem
	
	if self.list == nil then
		self:debug(DEBUG__DEBUG, "nothing in list")
		self:add(poData)
	else
		--verify  the comparator function
		if pfnCmp == nil then self:throw("no function") end
		if ( type(pfnCmp) ~= 'function') then  self:throw("non function") end	
	
		bReturn = pfnCmp(poData,poData)
		if ( bReturn ~= 0) then self:throw("unknown function return: ", bReturn) end	
		
		--first item is a special case
		bReturn = pfnCmp(self.list.data, poData)
		if bReturn == -1 then
			self:debug(DEBUG__DEBUG, "goes at top of list")
			oItem = cLinkedListNode:create(poData)
			oItem.next = self.list
			self.list = oItem
		else
			-- add normally
			self.list:prv__addComparatively(poData,pfnCmp)
		end
	end
end

--*********************************************************
function cLinkedList:add(poData)
	if self.list == nil then
		self.list = cLinkedListNode:create(poData)
	else
		self.list:add(poData)
	end
end