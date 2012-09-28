cWidgetDecorator = { 
	className="cWidgetDecorator", 
	widget=nil,
	}

--[[
	usage: myObj= cWidgetDecorator:create({options})
	where options are
		widget	: 
		width	:
		height	:
		backColour :
		border :
		cornerRadius :
		borderColour :
		borderInset:
		alpha
		padding
		
		TO BE DONE
]]--
--*******************************************************
function cWidgetDecorator:create(paOptions)
	if not self then error "did you call decorator with a . instead of :" end
	
	local oInstance = cClass.createGroupInstance(self)
	oInstance:prv__init(paOptions)
	return oInstance 
end

--*******************************************************
function cWidgetDecorator:prv__init(paOptions)
	local oGroup
	
	-- validate options
	if not paOptions then	error "decorator must have some properties" end
	if not paOptions.widget then	error "decorator: no widget" end
	if not paOptions.backColour then	error "decorator: no backColour" end
	
	-- validate options
	self.backColour = paOptions.backColour 
	self.widget = paOptions.widget
	self.padding = utility.defaultValue( paOptions.padding, 0)
	self.cornerRadius = utility.defaultValue( paOptions.cornerRadius, 0)
	self.borderWidth = utility.defaultValue( paOptions.borderWidth, 0)
	self.borderInset = utility.defaultValue( paOptions.borderInset, 0)
	self.bgAlpha = utility.defaultValue( paOptions.alpha, 1.0)
	self.bgWidth = utility.defaultValue( paOptions.width, self.widget.width + self.padding *2)
	self.bgHeight = utility.defaultValue( paOptions.height, self.widget.height + self.padding *2)
	
	if self.borderWidth >0 then
		if not paOptions.borderColour then error "decorator: no borderColour" end
		self.borderColour = paOptions.borderColour 
	end
	self.objs = {}
	
	-- decorator group sits behind widget
	oGroup = display.newGroup()
	oGroup.alpha = self.bgAlpha
	self.decorGrp = oGroup 
	self:insert(oGroup)
	
	-- insert widget
	self:insert(paOptions.widget)
	
	-- perform decoration
	self:decorate()
end

--*******************************************************
function cWidgetDecorator:decorate()
	local iWidw, ich, iw, ih, oBG, oGroup
	
	-- remove any decorations
	oGroup = self.decorGrp
	utility.removeChildren(oGroup)
	
	--create background
	if self.cornerRadius >0 then
		oBG = display.newRoundedRect(-self.padding,-self.padding,self.bgWidth,self.bgHeight, self.cornerRadius)
	else
		oBG = display.newRect(-self.padding,-self.padding,self.bgWidth,self.bgHeight)
	end
	oBG:setFillColor(cColours.explode(self.backColour))
	oGroup:insert(oBG)
	
	--create border
	if self.borderWidth == 0 then return end
	
	oBorder = oBG
	if self.borderInset then
		-- not implemented
	end
	oBorder.strokeWidth = self.borderWidth
	oBorder:setStrokeColor(cColours.explode(self.borderColour))
	
end