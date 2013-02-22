require "inc.lib.lib-class"
require "inc.lib.lib-events"

--########################################################
--#
--########################################################
cStackItem = {className="cStackItem", next=nil, data=nil}
function cStackItem:create(poData)
	local oInstance = cClass.createInstance(self)
	oInstance.data = poData
	return oInstance
end
cStackModes={fifo =1, filo=2}

--########################################################
--#
--########################################################
cStack = {className="cStack", mode=cStackModes.fifo}
cLibEvents.instrument(cStack)

function cStack:create(piMode)
	local oInstance = cClass.createInstance(self)
	
	if ( not piMode) then piMode = cStackModes.fifo end
	
	oInstance.top = nil
	oInstance.mode = piMode
	
	return oInstance
end

--*********************************************************
function cStack:push(poObj)
	local oStackItem 
	
	oStackItem = cStackItem:create(poObj)
	if (self.top == nil) then
		self.top = oStackItem
	elseif (self.mode == cStackModes.fifo) then
		self:prv_pushAtTop(oStackItem)
	else
		self:prv_pushToEnd(oStackItem, self.top)
	end
end

--*********************************************************
function cStack:pushAtTop(poData)
	self:prv_pushAtTop(cStackItem:create(poData))
end 

--*********************************************************
function cStack:prv_pushAtTop(poItem)
	poItem.next = self.top
	self.top = poItem
end

--*********************************************************
function cStack:prv_pushToEnd(poItem, poNode)
	if poNode.next then
		self:prv_pushToEnd(poItem, poNode.next)
	else
		poNode.next = poItem
	end
end

--*********************************************************
function cStack:pop()
	local oData, oStackItem
	
	oData = nil
	if self.top then
		oStackItem = self.top
		self.top = oStackItem.next
		oData = oStackItem.data
	end
	
	return oData
end
