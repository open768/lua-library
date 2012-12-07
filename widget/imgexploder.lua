--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require "inc.lib.lib-utility"
require "inc.lib.lib-class"
require "inc.lib.lib-events"
require "inc.lib.lib-imgcutter"
require "inc.lib.lib-animate"

--[[
	USAGE
	=====
	myGroup=cMultiLineText.create({options})
		options must contain
			text, maxWidth
		optional options
			font, fontsize, align, maxHeight, colour
		

	** note that while display.newtext does have multiline capabilities, 
	you cant align the text using that, or get fine control. And as 
	you dont have the source you cant modify it to do what you want.
	with this code - you have the source = you have the flexiblity
--]]
cImgExploder = {
	className="cImgExploder", data=nil, exploding=false, eventName="onCompleteAnim",
	gap=0,rows=nil, cols=nil, ImgWidth=0, ImgHeight=0, minSpeed=100
}
	
cLibEvents.instrument(cImgExploder)
cImgExploderData = {className="cImgExploderData", img,x,y,rot,dx,dy,drot}

--########################################################
--#
--########################################################
function cImgExploder.create(paOpts)
	if not paOpts then	error "cImgExploder: option array mandatory " end
	if not paOpts.img then	error "cImgExploder: text mandatory" end
	if not paOpts.w then	error "cImgExploder: w mandatory" end
	if not paOpts.h then	error "cImgExploder: h mandatory" end

	-- create an instance and initialise
	local oInstance = cClass.createGroupInstance(cImgExploder)
	if paOpts.gap then oInstance.gap = paOpts.gap end
	
	oInstance:prv__Init(paOpts.img, paOpts.w, paOpts.h)
	return oInstance 
end

-- ********************************************************
function cImgExploder:prv__Init(psImg, piCellW, piCellH)
	local oGen, iCountX, iCountY
	local aData, iRow, iCol, iIndex
	local iX, iY, iW, iH, oSprite, oItem
	
	
	oGen, iCountX, iCountY, iW, iH = cImgCutter.shred(psImg, piCellW, piCellH)
	self.rows = iCountY
	self.cols = iCountX
	self.data = utility.make2DArray(iCountY)
	self.ImgWidth=iW
	self.ImgHeight=iH
	
	iIndex = 1
	iY = -iH/2
	
	for iRow=1,self.rows do
		iX = -iW/2
		for iCol=1,self.cols do
			-- --------- instantiate sprite into instance data and set default values
			oItem = cClass.createInstance(cImgExploderData)
			oItem.x = iX
			oItem.y = iY
			oItem.img = oGen:getSprite(iIndex)
			
			self:insert(oItem.img)
			self.data[iRow][iCol] = oItem 
			
			-- ------- get ready for next sprite
			iX = iX + piCellW + self.gap
			iIndex = iIndex + 1
		end
		iY = iY + piCellH + self.gap
	end
end

-- ********************************************************
function cImgExploder:prv__getAnimator()
	local oAnim 
	oAnim = cAnimator:create()
	oAnim.wait4All=true
	oAnim.eventName = "onCompleteAnim"						-- choose the event name to fire when animation ended
	oAnim:addListener("onCompleteAnim", self) 
	return oAnim 
end

-- ********************************************************
function cImgExploder:reset( piAnimSpeed)
	local oAnim, iRow, iCol, oItem, bWait
	
	if self.exploding then
		cDebug:print(DEBUG__DEBUG, "stopping...")
		self:stop()
	end
	
	self.exploding=true
	oAnim = self:prv__getAnimator()

	bWait=false					-- last image must wait before starting anim
	for iRow=1,self.rows do
		for iCol=1,self.cols do
			oItem = self.data[iRow][iCol]
			if (iRow==self.rows) and (iCol==self.cols )then bWait = true end
			oAnim:add(oItem.img, {isVisible=true}, {isSetup=true, wait=bWait})
		end
	end
	
	bWait=false					-- last image must wait before firing an event
	for iRow=1,self.rows do
		for iCol=1,self.cols do
			oItem = self.data[iRow][iCol]
			if (iRow==self.rows) and (iCol==self.cols )then bWait = true end
			oAnim:add(oItem.img, {x=oItem.x, y=oItem.y, time=piAnimSpeed, xScale=1.0, yScale=1.0}, {wait = bWait})
		end
	end
	
	cDebug:print(DEBUG__DEBUG, "animating now...")
	oAnim:go( )	
end

-- ********************************************************
function cImgExploder:explode(piMinSpeed, piMaxSpeed)
	local oAnim, bWait, iRow, iCol, oItem
	local iSpeed, iEndX,iEndY, idx, idy
	
	if self.exploding then
		error "allready exploding"
	end
	
	oAnim = self:prv__getAnimator()
	bWait=false					-- last image must wait before firing an event
	
	idx = utility.Screen.w/self.ImgWidth
	idy = utility.Screen.h/self.ImgHeight
	
	for iRow=1,self.rows do
		for iCol=1,self.cols do
			oItem = self.data[iRow][iCol]
			if (iRow==self.rows) and (iCol==self.cols )then bWait = true end
			
			iSpeed = math.random(piMinSpeed, piMaxSpeed)
			iEndX = oItem.x * idx
			iEndY = oItem.y * idy
			
			oAnim:add(oItem.img, {x=iEndX, y=iEndY, xScale=0.2, yScale=0.2, time=iSpeed}, {wait = bWait})
		end
	end
	oAnim:go()
end

-- ********************************************************
function cImgExploder:onCompleteAnim()
	self.exploding = false
	self:notify({name=self.eventName})
end

-- ********************************************************
function cImgExploder:stop()
	self.exploding = false
end
