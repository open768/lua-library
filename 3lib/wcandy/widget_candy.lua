require("string")
require("sprite")

--[[
----------------------------------------------------------------
WIDGET CANDY FOR CORONA SDK
----------------------------------------------------------------
PRODUCT  :		WIDGET CANDY GUI LIBRARY
VERSION  :		1.0.5
AUTHOR   :		MIKE DOGAN / X-PRESSIVE.COM
WEB SITE :		http:www.x-pressive.com
SUPPORT  :		info@x-pressive.com
PUBLISHER:		X-PRESSIVE.COM
COPYRIGHT:		(C)2012 MIKE DOGAN GAMES & ENTERTAINMENT

----------------------------------------------------------------

PLEASE NOTE:
A LOT OF HARD AND HONEST WORK HAS BEEN SPENT
INTO THIS PROJECT AND WE'RE STILL WORKING HARD
TO IMPROVE IT FURTHER.
IF YOU DID NOT PURCHASE THIS SOURCE LEGALLY,
PLEASE ASK YOURSELF IF YOU DID THE RIGHT AND
GET A LEGAL COPY (YOU'LL BE ABLE TO RECEIVE
ALL FUTURE UPDATES FOR FREE THEN) TO HELP
US CONTINUING OUR WORK. THE PRICE IS REALLY
FAIR. THANKS FOR YOUR SUPPORT AND APPRECIATION.

FOR FEEDBACK & SUPPORT, PLEASE CONTACT:
INFO@X-PRESSIVE.COM

]]--


-- TO HOLD VARIABLES AND FUNCTIONS
local V = {}

-- A WIDGET'S DEFAULT SETTINGS (IF NOT SPECIFIED)
V.Defaults =
	{
	alpha                   = 1.0,
	visible                 = true,
	x                       = "auto",
	y                       = "auto",
	width                   = "auto",
	height                  = "auto",
	scale                   = 1.0,
	zindex                  = 0,
	icon                    = 0,
	toggleButton            = false,
	toggleState             = false,
	group                   = "",
	enabled                 = true,
	textAlign               = "left",
	lineSpacing             = 0, -- TEXT
	border                  = {},
	value                   = 0,
	-- PROGBAR, SLIDER
	percent                 = 0, -- READONLY
	minValue                = 0,
	maxValue                = 1,
	-- FOR PARENT LAYOUT:
	includeInLayout         = true,
	newLayoutLine           = false,
	rightMargin             = 0,
	bottomMargin            = 0,
	leftMargin              = 0,
	topMargin               = 0,
	caption                 = "",
	-- FOR CONTAINER WIDGETS:
	gradientDirection       = "left",
	shadow                  = false,
	dragX                   = false,
	dragY                   = false,
	stayOnTop               = false,
	closeButton             = false,
	resizable               = false,
	slideOut                = 0,
	margin                  = 0,
	tapToFront              = true,
	}

V.Abs         = math.abs
V.Rnd         = math.random
V.Ceil        = math.ceil
V.Round       = math.round
V.Floor       = math.floor
V.Sin         = math.sin
V.Cos         = math.cos
V.Time        = system.getTimer
V.screenW     = display.contentWidth
V.screenH     = display.contentHeight ; if (system.getInfo("model") == "Kindle Fire") then V.screenH = display.contentHeight - 20 end
V.Stage       = display.getCurrentStage()
V.widgetCount = 0
V.print       = "simulator" == system.getInfo("environment") and print or function() end

-- WIDGET IDs
V.TYPE_WINDOW       = 1
V.TYPE_BORDER       = 2
V.TYPE_BUTTON       = 3
V.TYPE_SQUAREBUTTON = 4
V.TYPE_CHECKBOX     = 5
V.TYPE_RADIO        = 6
V.TYPE_TEXT         = 7
V.TYPE_PROGBAR      = 8
V.TYPE_SWITCH       = 9
V.TYPE_SLIDER       = 10
V.TYPE_LIST         = 11
V.TYPE_LABEL        = 12
V.TYPE_INPUT        = 13
V.TYPE_DRAGBUTTON   = 14
V.TYPE_IMAGE        = 15

-- TO STORE LOADED THEMES
V.Themes       = {}
V.defaultTheme = ""

-- TO STORE EXISTING WIDGETS
V.Widgets      = {}

-- TOP-SCREEN INPUT FIELD
V.Input        = nil

-- MODAL DIALOG SCREEN FADE
V.Fader        = nil
V.numModals    = 0

----------------------------------------------------------------
-- PRIVATE: VERIFY A WIDGET'S EXISTING PROPERTY COLLECTION
----------------------------------------------------------------
V._CheckProps = function ( Widget)
	local Props = Widget.Props
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: _CheckProps(): Unknown theme '"..Props.theme.."' for widget '"..Props.name.."'."); return end
	V.Defaults.name      = "Widget"..V.widgetCount
	V.Defaults.fontSize  = V.Themes[Props.theme].WidgetFontSize
	V.Defaults.minWidth  = Props.minW
	V.Defaults.maxWidth  = Props.maxW
	V.Defaults.minHeight = Props.minH
	V.Defaults.maxHeight = Props.maxH
	
	-- APPLY THEME COLOR?
	if Props.color == nil then Props.color = V.Themes[Props.theme].color end
	
	local k,v; for k,v in pairs(V.Defaults) do 
		if Props[k] == nil then Props[k] = V.Defaults[k] elseif Props[k] == "" then Props[k] = V.Defaults[k] end 
	end
	
	-- SET PARENT
	Props.parentGroup = V._SetWidgetParent(Widget, Props.parentGroup)

	-- CAPTION: REMOVE NEW LINES / CONVERT BOOLEAN TO STRING
	if type(Props.caption) == "string" then 
		Props.caption = Props.caption:gsub("\n", "|")               
	elseif type(Props.caption) == "boolean" then       
		Props.caption = Props.caption == true and "true" or "false" 
	end 
	
	if Props.minWidth  < V.Defaults.minWidth * Props.scale  then Props.minWidth  = V.Defaults.minWidth * Props.scale end
	if Props.minHeight < V.Defaults.minHeight * Props.scale then Props.minHeight = V.Defaults.minHeight * Props.scale end

	    if Props.maxWidth  < Props.minWidth * Props.scale  then Props.maxWidth  = Props.minWidth * Props.scale 
	elseif Props.maxWidth  > Props.maxW * Props.scale      then Props.maxWidth  = Props.maxW * Props.scale end

	    if Props.maxHeight < Props.minHeight * Props.scale then Props.maxHeight = Props.minHeight * Props.scale 
	elseif Props.maxHeight > Props.maxH * Props.scale      then Props.maxHeight = Props.maxH * Props.scale end

	if Props.Shape == nil then Props.Shape = {} end
	V._SetSize      (Widget)
	V._SetPos       (Widget)
end


----------------------------------------------------------------
-- PRIVATE: GET MINX,MAXX,MINY,MAXY,WIDTH,HEIGHT OF A WIDGETS PARENT
----------------------------------------------------------------
V._GetParentShape = function ( Widget )
	local P         = {}
	P.insideWidget  = Widget.parent.isContainer
	P.insideGroup   =(P.insideWidget ~= true and Widget.parent ~= V.Stage) and true or false

	-- INSIDE A WIDGET? (GETS LOCAL COORDINATES)
	if P.insideWidget == true then
		local ParentProps = Widget.parent.parent.Props
		P.minX  = ParentProps.margin
		P.maxX  = ParentProps.Shape.w - ParentProps.margin
		P.minY  = ParentProps.margin
		P.maxY  = ParentProps.Shape.h - ParentProps.margin - V.Themes[ParentProps.theme].widgetFrameSize
		P.w     = P.maxX - P.minX
		P.h     = P.maxY - P.minY
	-- INSIDE A GROUP? (GETS SCREEN COORDINATES)
	elseif P.insideGroup == true then
		local Group = Widget.parent
		if Group.bounds == nil then Group.bounds = {0,0,V.screenW,V.screenH} end -- TOP,LEFT,WIDTH,HEIGHT
		P.minX   = Group.bounds[1]
		P.maxX   = Group.bounds[1] + Group.bounds[3]
		P.minY   = Group.bounds[2]
		P.maxY   = Group.bounds[2] + Group.bounds[4]
		P.w      = Group.bounds[3]
		P.h      = Group.bounds[4]
	-- NO PARENT? (GETS SCREEN COORDINATES)
	else
		P.minX   = 0
		P.maxX   = V.screenW
		P.minY   = 0
		P.maxY   = V.screenH
		P.w      = V.screenW
		P.h      = V.screenH
	end

	return P
end

----------------------------------------------------------------
-- PRIVATE: SET A WIDGET'S SIZE, CALCULATE STRING TO VALUE
----------------------------------------------------------------
V._SetSize = function (Widget)
	local Props  = Widget.Props
	local Shape  = Widget.Props.Shape
	local PShape = V._GetParentShape(Widget)

	-- WIDTH
	if Props.width == "auto" then 
		if Shape.w == nil then Shape.w = Props.minWidth end
	else 
		Shape.w = type(Props.width ) == "string" and (PShape.w/100) *  (Props.width:sub(1,Props.width:len()-1)) or Props.width 
	end

	       Shape.w = Shape.w * (1/Props.scale)
		if Shape.w < Props.minWidth * (1/Props.scale) then Shape.w = Props.minWidth* (1/Props.scale) 
	elseif Shape.w > Props.maxWidth * (1/Props.scale) then Shape.w = Props.maxWidth* (1/Props.scale) end

	-- HEIGHT
	if Props.height == "auto" then 
		if Shape.h == nil then Shape.h = Props.minHeight end
	else 
		Shape.h = type(Props.height) == "string" and (PShape.h/100) *  (Props.height:sub(1,Props.height:len()-1)) or Props.height 
	end

	       Shape.h = Shape.h * (1/Props.scale)
	    if Shape.h < Props.minHeight * (1/Props.scale) then Shape.h = Props.minHeight* (1/Props.scale) 
	elseif Shape.h > Props.maxHeight * (1/Props.scale) then Shape.h = Props.maxHeight* (1/Props.scale) end

	Shape.w = V.Floor(Shape.w)
	Shape.h = V.Floor(Shape.h)
	
end

----------------------------------------------------------------
-- PRIVATE: SET A WIDGET'S POS, CALCULATE STRING TO VALUE
----------------------------------------------------------------
V._SetPos = function (Widget)
	local tmp
	local Props  = Widget.Props
	local Shape  = Widget.Props.Shape
	local PShape = V._GetParentShape(Widget)

	-- XPOS
	if Props.x == "auto" then
		if Shape.x == nil then Shape.x = 0 end
	else
		Shape.x = Props.x
		if type(Props.x) == "string"   then
				if Props.x == "left"   then Shape.x = PShape.minX
			elseif Props.x == "center" then Shape.x = PShape.minX + PShape.w*.5 - (Shape.w * Props.scale)*.5
			elseif Props.x == "right"  then Shape.x = PShape.maxX - (Shape.w * Props.scale)
			elseif string.find(Props.x,"%",1,true) then Shape.x = PShape.minX + (PShape.w/100) *  tonumber(Props.x:sub(1,Props.x:len()-1))
			else   Props.x = 0; print("!!! WIDGET ERROR: INVALID X-POS SPECIFIED FOR WIDGET '"..Props.name.."'") end
			-- REFERS TO SCREEN COORDS?
			--if PShape.insideGroup then Shape.x, tmp = Widget.parent:contentToLocal(Shape.x, 0) end
		end
	end

	-- YPOS
	if Props.y == "auto" then
		if Shape.y == nil then Shape.y = 0 end
	else
		Shape.y = Props.y
		if type(Props.y) == "string"   then
				if Props.y == "top"    then Shape.y = PShape.minY
			elseif Props.y == "center" then Shape.y = PShape.minY + PShape.h*.5 - (Shape.h * Props.scale)*.5
			elseif Props.y == "bottom" then Shape.y = PShape.maxY - (Shape.h * Props.scale)
			elseif string.find(Props.y,"%",1,true) then Shape.y = PShape.minY + (PShape.h/100) *  tonumber(Props.y:sub(1,Props.y:len()-1)) 
			else   Props.y = 0; print("!!! WIDGET ERROR: INVALID Y-POS SPECIFIED FOR WIDGET '"..Props.name.."'") end
			-- REFERS TO SCREEN COORDS?
			--if PShape.insideGroup then tmp, Shape.y = Widget.parent:contentToLocal(0, Shape.y) end
		end
	end

	Shape.x  = V.Floor(Shape.x)
	Shape.y  = V.Floor(Shape.y)
	Widget.x = Shape.x
	Widget.y = Shape.y
end

----------------------------------------------------------------
-- PRIVATE: SET A WIDGET'S PARENT (WINDOW, GROUP OR STAGE)
----------------------------------------------------------------
V._SetWidgetParent = function (Widget, newParent)

	local Props = Widget.Props
	local name  = ""; if Props ~= nil and Props.name ~= nil then name = Props.name end

	-- SAME PARENT AS BEFORE?
	if Widget.parent == newParent or (Widget.parent.parent ~= nil and Widget.parent.parent.Props ~= nil and Widget.parent.parent == newParent) then 
		if Props.zindex > 0 then Widget.parent:insert(Props.zindex,Widget) end
		return newParent 
	end

	Props.myWindow = ""

	-- NO PARENT SPECIFIED? SET TO STAGE!
	if newParent == nil then newParent = V.Stage end

	-- PARENT IS ANOTHER WIDGET?
	if newParent~= nil and type(newParent) == "string" then
		local P = V.Widgets[newParent]
	
		-- PARENT WIDGET DOES NOT EXIST?
		if P == nil or (P ~= nil and P.Widgets == nil) or Widget.typ == V.TYPE_WINDOW then
			print("!!! WIDGET ERROR: Can't insert widget "..name.." into specified parent." ) 
			return nil
		-- OK
		else
			Props.myWindow = P.Props.name
			if Props.zindex > 0 then 
				P.Widgets:insert(Props.zindex,Widget) 
			else 
				P.Widgets:insert(Widget)
			end
			V.print("--> Widgets: Inserted widget "..name.." to parent '"..P.Props.name.."'.")
			return P
		end
	end

	-- INSERT TO A GROUP OR STAGE?	
	if newParent ~= nil then
		if Props.zindex > 0 then 
			newParent:insert(Props.zindex,Widget) 
		else 
			newParent:insert(Widget) 
		end
		V.print("--> Widgets: Inserted widget "..name.." into display group or stage.")
		return newParent
	end

end


----------------------------------------------------------------
-- PRIVATE: AUTOMATICALLY ARRANGE ALL WIDGETS INSIDE A WINDOW OR FRAME
----------------------------------------------------------------
V._ArrangeWidgets = function (Win, doScreenAlign)
	if Win.Widgets == nil then V._ArrangeWidget(Win); return end

	V.print("--> Widgets: Calculating layout for window "..Win.Props.name)
	
	Win.maxY = Win.Props.minHeight

	local i
	-- LOOP THROUGH WINDOW'S WIDGETS, ARRANGE
	for i = 1, Win.Widgets.numChildren do
		--if Win.Widgets[i].Props.x == "auto" or Win.Widgets[i].Props.y == "auto" then 
		if Win.Widgets[i].Props.includeInLayout == true then 
			V._ArrangeWidget(Win.Widgets[i]) 
		end
	end

	-- NEW WINDOW AUTO HEIGHT?
	if Win.Props.height  == "auto" and Win.maxY ~= Win.Props.Shape.h then 
		Win.Props.Shape.h = Win.maxY
		if doScreenAlign == true then V._SetPos(Win) end -- SCREEN ALIGN
		Win:_update( )
	end

	-- NOW RE-ADJUST ANY AUTO-SIZE BORDER WIDGETS
	for i = 1, Win.Widgets.numChildren do
		if Win.Widgets[i].typ == V.TYPE_BORDER and Win.Widgets[i].Props.group ~= "" then 
			Win.Widgets[i]:_update() 
		end
	end
end

----------------------------------------------------------------
-- PRIVATE: AUTOMATICALLY ARRANGE A WIDGET INSIDE A WINDOW OR FRAME
----------------------------------------------------------------
V._ArrangeWidget = function (Widget)
	if Widget.Props == nil then print("!!! WIDGET ERROR: ArrangeWidgets(): Invalid widget handle."); return end

	local i, depth, W, WShape, set
	local Widgets = Widget.parent
	local Props   = Widget.Props
	local Win     = Widgets.parent
	local Shape   = Widget.Props.Shape
	local minX    = Win.Props.margin
	local maxX    = Win.Props.Shape.w - Win.Props.margin
	local x       = minX + Props.leftMargin
	local y       = Props.topMargin

	-- FIND THIS WIDGET'S DEPTH
	for i = 1,Widgets.numChildren do if Widgets[i] == Widget then depth = i; break end end

	-- LOOP WIDGETS BACKWARDS
	for i = depth-1,1,-1 do
		W      = Widgets[i]
		WShape = W.Props.Shape
		if W.Props.includeInLayout == true then
			-- ALIGN TO FIRST AUTOINCLUDE ANCESTOR FOUND
			if set ~= true then
				set = true
				x   = WShape.x + WShape.w + W.Props.rightMargin + Props.leftMargin
				y   = WShape.y + Props.topMargin
				-- NEW LINE OR EXCEED WINDOW WIDTH? NEXT LINE!
				if Props.newLayoutLine or (Win.Props.width ~= "auto" and x + Shape.w > maxX) then 
					x = minX + Props.leftMargin
					y = WShape.y + WShape.h + W.Props.bottomMargin + Props.topMargin
				end
			-- OVERLAPPING ANY EARLIER ANCESTOR? 
			elseif y < WShape.y + WShape.h and x < WShape.x + WShape.w then 
				x = WShape.x + WShape.w + W.Props.rightMargin
				if Win.Props.width ~= "auto" and x + Shape.w > maxX then
					x = minX + Props.leftMargin
					y = WShape.y + WShape.h + W.Props.bottomMargin + Props.topMargin
				end
			end
		end
	end
	if Props.x == "auto" then Shape.x = V.Floor(x); Widget.x = Shape.x end
	if Props.y == "auto" then Shape.y = V.Floor(y); Widget.y = Shape.y end

	-- REMEMBER NEW WINDOW HEIGHT
	local maxY = (Widgets.y + Shape.y + Shape.h + Win.Props.margin)-- * Win.Props.scale
	   if maxY >  Win.maxY then Win.maxY = maxY end
	
end


----------------------------------------------------------------
-- PRIVATE: SHORTEN A GADGET TEXT TO STAY WITHIN A GIVEN WIDTH
----------------------------------------------------------------
V._WrapGadgetText = function (Obj, maxw, font, size)
	if Obj.width*.5 <= maxw then return end
	local Tmp2  = display.newText("...",0,0,font,size*2)
	while Obj.text:len() > 0 and Obj.width + Tmp2.width > maxw*2 do 
		Obj.text = Obj.text:sub(1,Obj.text:len()-1) 
	end
	if Obj.text ~= "" then Obj.text = Obj.text.."..." end
	Tmp2:removeSelf()
end


----------------------------------------------------------------
-- PRIVATE: ADD A BORDER TO A WIDGET {"type", [cornerRadius], [strokeWidth], [R],[G],[B],[A], [R],[G],[B],[A]}
----------------------------------------------------------------
V._AddBorder = function (Widget)
	while Widget[1].numChildren > 0 do Widget[1][1]:removeSelf() end
	if Widget.Props.border[1] == nil then return end
	
	local Tmp1, Tmp2
	local Props  = Widget.Props
	local Theme  = V.Themes [Props.theme]
	local corner = Props.border[2] == nil and 2   or Props.border[2]
	local stroke = Props.border[3] == nil and 1   or Props.border[3]
	local R      = Props.border[4] == nil and 0   or Props.border[4]
	local G      = Props.border[5] == nil and 0   or Props.border[5]
	local B      = Props.border[6] == nil and 0   or Props.border[6]
	local A      = Props.border[7] == nil and 255 or Props.border[7]
	
	if Props.border[1] == "normal" then
		Tmp1  = display.newRoundedRect(Widget[1],stroke,stroke,Props.Shape.w-stroke*2,Props.Shape.h-stroke*2,corner)
		Tmp1.strokeWidth  = stroke
		Tmp1:setFillColor  (Props.border[4],Props.border[5],Props.border[6],Props.border[7])
		Tmp1:setStrokeColor(Props.border[8],Props.border[9],Props.border[10],Props.border[11])
		return
	elseif Props.border[1] == "shadow" then
		Tmp1  = display.newRoundedRect(Widget[1],Props.border[3],Props.border[3],Props.Shape.w,Props.Shape.h,corner)
		Tmp1.strokeWidth  = 0
		Tmp1:setFillColor  (0,0,0,Props.border[4])
		Tmp1:setStrokeColor(0,0,0,0)
		return
	end

	Tmp1 = display.newRoundedRect(Widget[1],stroke*2,stroke*2,Props.Shape.w-stroke*3,Props.Shape.h-stroke*3,corner)
	Tmp1.strokeWidth = stroke
	Tmp1:setFillColor (Props.border[4],Props.border[5],Props.border[6],Props.border[7])

	Tmp2 = display.newRoundedRect(Widget[1],stroke,stroke,Props.Shape.w-stroke*3,Props.Shape.h-stroke*3,corner)
	Tmp2.strokeWidth = stroke
	Tmp2:setFillColor (0,0,0,0)
	
	    if Props.border[1] == "inset"  then Tmp1:setStrokeColor(Theme.EmbossColorHigh[1],Theme.EmbossColorHigh[2],Theme.EmbossColorHigh[3],255); Tmp2:setStrokeColor(Theme.EmbossColorLow[1],Theme.EmbossColorLow[2],Theme.EmbossColorLow[3],255)
	elseif Props.border[1] == "outset" then Tmp1:setStrokeColor(Theme.EmbossColorLow[1],Theme.EmbossColorLow[2],Theme.EmbossColorLow[3],255); Tmp2:setStrokeColor(Theme.EmbossColorHigh[1],Theme.EmbossColorHigh[2],Theme.EmbossColorHigh[3],255) end
end


----------------------------------------------------------------
-- PRIVATE: APPLY STANDARD WIDGET METHODS
----------------------------------------------------------------
V._ApplyWidgetMethods = function (Widget)
	function Widget:show     (state,anim) V.Show(self.Props.name, state, anim) end
	function Widget:enable   (state) V.Enable(self.Props.name, state) end
	function Widget:set      (A, B, C) V.Set(self.Props.name, A, B, C) end
	function Widget:get      (name) return V.Get(self.Props.name, name) end
	function Widget:layout   (doScreenAlign) V._ArrangeWidgets(self, doScreenAlign) end
	function Widget:setPos   (x,y) self.Props.x = x; self.Props.y = y; V._SetPos(self); if self.Props.myWindow ~= "" then V._ArrangeWidgets(V.Widgets[self.Props.myWindow]) end end
	function Widget:getShape () return V.GetShape(self.Props.name) end
	function Widget:getHandle() return V.GetHandle(self.Props.name) end
	function Widget:destroy  () V._RemoveWidget(self.Props.name) end
	function Widget:update   () self:_update() end
	function Widget:getDepth () return V.GetDepth(self.Props.name) end
	function Widget:toFront  () self.parent:insert(self); self.Props.zindex = V.GetDepth(self.Props.name); return self.Props.zindex end
	--function Widget:animate  (typ, Props) V.Animate(self.Props.name, typ, Props) end
	--function Widget:animStop () V.AnimStop(self.Props.name) end

	if Widget.typ == V.TYPE_WINDOW then
		function Widget:close() 
			if self.Props.onClose ~= nil then self.Props.onClose(		
			{ 
			Widget = self,
			Props  = self.Props,
			name   = self.Props.name,
			}) 
			end 
		end
	end
end


----------------------------------------------------------------
-- PRIVATE: WIDGET LISTENERS
----------------------------------------------------------------
V._OnWidgetTouch = function (event)

	local i,v
	local Obj   = event.target
	local Props = Obj.Props
	local Theme = V.Themes [Props.theme]
	local name  = Props.name
	local ex,ey = Obj:contentToLocal(event.x, event.y)
	local EventData = 
		{ 
		Widget      = Obj,
		Props       = Props,
		name        = name,
		x           = event.x,
		y           = event.y,
		lx          = ex,
		ly          = ey,
		inside      = true,
		}

	-- INPUT TEXT OKAY BUTTON CLICKED?
	if V.Input ~= nil then 
		if event.phase == "began" then V._RemoveInput() end 
		return true 
	end

	-- WIDGET OR WINDOW DISABLED?
	if Props.enabled == false or (Props.myWindow ~= "" and V.Widgets[Props.myWindow].Props.enabled == false) then
		Obj.isFocus = false; V.Stage:setFocus( nil )
		return true
	end

	-- PRESS
	if event.phase == "began" then
		if Props.myWindow ~= "" and V.Widgets[Props.myWindow].Props.tapToFront == true then V.Widgets[Props.myWindow]:toFront() end
		Obj.inside  = true
		Obj.isFocus = true; V.Stage:setFocus( Obj )
		Obj:_drawPressed( EventData )
		EventData.value       = Props.value
		EventData.toggleState = Props.toggleState
		if Props.onPress ~= nil then Props.onPress( EventData ) end 
		if Props.tapSound~= nil then audio.play(Theme.Sounds[Props.tapSound]) end
		-- WIDGET HAS NOT BEEN REMOVED IN .onRelease() BUT WAS DISABLED THERE?
		if V.Widgets[name] == nil or (V.Widgets[name] and (Props.enabled == false or (Props.myWindow ~= "" and V.Widgets[Props.myWindow] and V.Widgets[Props.myWindow].Props.enabled == false))) then Obj.isFocus = false; V.Stage:setFocus( nil ); return true end
		-- INPUT TEXT?
		if Obj.typ == V.TYPE_INPUT then
			if Props.disableInput ~= true then
				if V.Input == nil then V._CreateInput(Obj) end
				native.setKeyboardFocus(V.Input.Txt)
			end
		else
			V._RemoveInput() 
		end

	elseif Obj.isFocus then

		-- INSIDE WIDGET?
		if ex > 0 and ex < Props.Shape.w and ey > 0 and ey < Props.Shape.h then EventData.inside = true else EventData.inside = false end

		-- DRAG
		if event.phase == "moved" then
			Obj.inside            = EventData.inside
			if Obj._drawDragged  then Obj:_drawDragged( EventData ) end
			EventData.value       = Props.value
			EventData.toggleState = Props.toggleState
			if Props.onDrag      then Props.onDrag    ( EventData ) end 

		-- RELEASE
		elseif event.phase == "ended" or event.phase == "cancelled" then
			Obj.inside            = EventData.inside
			Obj.isFocus           = false; V.Stage:setFocus( nil )
			Obj:_drawReleased( EventData )
			EventData.value       = Props.value
			EventData.toggleState = Props.toggleState
			if Props.onRelease   ~= nil then Props.onRelease( EventData ) end
			if Props.releaseSound~= nil then audio.play(Theme.Sounds[Props.releaseSound]) end
			-- WIDGET HAS NOT BEEN REMOVED IN .onRelease() BUT WAS DISABLED THERE?
			if V.Widgets[name] == nil or (V.Widgets[name] and (Props.enabled == false or (Props.myWindow ~= "" and V.Widgets[Props.myWindow] and V.Widgets[Props.myWindow].Props.enabled == false))) then Obj.isFocus = false; V.Stage:setFocus( nil ); return true end
		end
	end
	
	return true
end


----------------------------------------------------------------
-- PRIVATE: WINDOW TOUCH
----------------------------------------------------------------
V._OnWindowTouch = function (event)
	local Win   = event.target.parent
	local Props = Win.Props
	local p     = event.phase
	local ex,ey = Win.parent:contentToLocal(event.x, event.y)

	-- WINDOW DISABLED?
	if Props.enabled == false then Win.isFocus = false; display.getCurrentStage():setFocus( nil ) end

	if p == "began" then
		if Props.tapToFront == true then Win:toFront() end
		V._RemoveInput() 
		Win.isFocus  = true; display.getCurrentStage():setFocus( event.target )
		Win.sx, Win.sy = 0,0
		Win.lx, Win.ly = Win.x, Win.y
		Win.ox, Win.oy = Win.x - ex, Win.y - ey
		if Props.onPress then Props.onPress(Win, Props) end
		if Win.DragTimer ~= nil then timer.cancel(Win.DragTimer); Win.DragTimer.Win = nil; Win.DragTimer = nil end
		if Props.slideOut > 0 then
			Win.DragTimer = timer.performWithDelay(1, 
				function (event) 
					-- GET VELOCITY
					if Win.isFocus then
						Win.sx, Win.sy = Win.x - Win.lx, Win.y - Win.ly
						Win.lx, Win.ly = Win.x, Win.y
						Win.fx, Win.fy = Win.x, Win.y
					-- SLIDE OUT
					else
						if Props.dragX then Win.fx = Win.fx + Win.sx; Win.x = V.Ceil(Win.fx) end
						if Props.dragY then Win.fy = Win.fy + Win.sy; Win.y = V.Ceil(Win.fy) end

						Win.sx = Win.sx * Props.slideOut
						Win.sy = Win.sy * Props.slideOut
						if Props.dragArea ~= nil then Win:_keepInsideArea() end

						if V.Abs(Win.sx) < 0.1 and V.Abs(Win.sy) < 0.1 then
							timer.cancel(Win.DragTimer)
							Win.x             = V.Ceil(Win.x)
							Win.y             = V.Ceil(Win.y)
							Props.Shape.x = Win.x
							Props.Shape.y = Win.y
							Win.DragTimer.Win = nil
							Win.DragTimer     = nil
						end
					end
				end, 0)
			Win.DragTimer.Win = Win
		end

	elseif Win.isFocus == true then
		if p == "moved" then
			if Props.dragX then Win.x = V.Ceil(ex + Win.ox) end
			if Props.dragY then Win.y = V.Ceil(ey + Win.oy) end
			if Props.dragArea ~= nil then Win:_keepInsideArea() end
			if Props.onDrag   ~= nil then Props.onDrag(Win, Props) end

		elseif p == "ended" or p == "cancelled" then
			Win.isFocus = false; display.getCurrentStage():setFocus( nil )
			if Props.onRelease ~= nil then Props.onRelease(Win, Props) end
		end
	end
	
	Props.Shape.x = Win.x
	Props.Shape.y = Win.y
	
	return true
end


----------------------------------------------------------------
-- PRIVATE: WINDOW CLOSE
----------------------------------------------------------------
V._OnWindowClose = function (event)
	local But   = event.target
	local Win   = But.parent.parent
	local Props = Win.Props
	local Theme = V.Themes [Props.theme]

	V._RemoveInput() 

	if event.phase == "began" then
		if Props.tapToFront == true then Win:toFront() end
		But.isFocus = true; display.getCurrentStage():setFocus( But )
		But:setFrame(Theme.Frame_Win_CloseButtonDown)
	
	elseif But.isFocus then
		-- OVER / OUTSIDE BUTTON?
		local size = Theme.widgetFrameSize
		local x,y  = But:contentToLocal(event.x, event.y)
		x = x + size*.5
		y = y + size*.5
		But:setFrame( (x > 0 and x < size and y > 0 and y < size) and Theme.Frame_Win_CloseButtonDown or Theme.Frame_Win_CloseButton )

		if event.phase == "ended" or event.phase == "cancelled" then
			But.isFocus = false; display.getCurrentStage():setFocus( nil )
			if But:getFrame() == Theme.Frame_Win_CloseButtonDown then 
				Win:close() 
				But:setFrame(Theme.Frame_Win_CloseButton)
			end
		end
	end
	
	return true
end


----------------------------------------------------------------
-- PRIVATE: WINDOW RESIZE
----------------------------------------------------------------
V._OnWindowResize = function (event)
	V._RemoveInput() 
end


----------------------------------------------------------------
-- PRIVATE: INPUT TEXT FUNCTIONS
----------------------------------------------------------------
V._CreateInput = function(Widget)
	V._RemoveInput()
	local Tmp
	local Props     = Widget.Props
	local Theme     = V.Themes[Props.theme]
	local Window    = V.Widgets[Props.myWindow]
	local scale     = Window ~= nil and Window.Props.scale or Props.scale
	local size      = Props.fontSize + 8
	local w         = (V.screenW - 40)-- * (1/scale)
	local y         = (size + 10) * scale
	local margin    = 10
	local physicalW = math.round( (V.screenW - display.screenOriginX*2) )
	local physicalH = math.round( (V.screenH - display.screenOriginY*2) )

	V.Input           = {}
	V.Input.MyObject  = Widget
	V.Input.oText     = Widget.Props.caption

	-- MODAL BG
	if V.Fader == nil then
		V.Fader = display.newRect(display.screenOriginX,display.screenOriginY,physicalW,physicalH)
		V.Fader:setFillColor (0,0,0,128)
		V.Fader.strokeWidth = 0
		V.Fader.alpha       = 0
		V.Fader:addEventListener("touch", function() V._RemoveInput(); return true end)
	end
	transition.to (V.Fader, {time = 750, alpha = 1.0})
	V.numModals = V.numModals + 1

	-- BORDER
	Tmp              = display.newRoundedRect(0,0,w,(size+margin*2)*scale, 8)
	Tmp.x            = V.screenW * .5
	Tmp.y            = y
	Tmp.strokeWidth  = 1
	Tmp:setFillColor  (0,0,0,150)
	Tmp:setStrokeColor(255,255,255,255)
	V.Input.Border   = Tmp
	
	-- INPUT TEXT
	Tmp = native.newTextField(0,0,w-margin*2,(size+4)*scale)
	Tmp:addEventListener("userInput", V._OnInput)
	Tmp.x            = V.screenW * .5
	Tmp.y            = y
	Tmp.text         = Props.caption
	Tmp.size         = Props.fontSize
	Tmp.isSecure     = Props.isSecure  ~= nil and Props.isSecure  or false
	Tmp.inputType    = Props.inputType ~= nil and Props.inputType or "default"
	Tmp.isEditable   = true
	Tmp:setTextColor(0,0,0,255)  
	V.Input.Txt      = Tmp
	native.setKeyboardFocus(V.Input.Txt)
	if Widget.Props.onFocus then Widget.Props.onFocus(
		{
		Widget = Widget,
		Props  = Widget.Props,
		name   = Widget.Props.name,
		value  = Widget.Props.caption,
		}) end
	
	-- QUIT CAPTION
	Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
	Tmp.xScale = .5 * scale
	Tmp.yScale = .5 * scale
	Tmp.x      = V.screenW * .5
	Tmp.y      = y + size + margin*2
	Tmp.text   = Props.quitCaption
	V.Input.QuitTxt = Tmp

end

V._OnInput = function(event)
	--if V.Input == nil then return end
	local O     = V.Input.MyObject
	local Props = O.Props
	local Theme = V.Themes[Props.theme]

	-- CHECK FOR ALLOWED CHARS
	if Props.allowedChars ~= nil then
		for i = 1, V.Input.Txt.text:len() do
			local found = false 
			for j = 1, Props.allowedChars:len() do
				if V.Input.Txt.text:sub(i,i) == Props.allowedChars:sub(j,j) then found = true; break end
			end
			if found == false then V.Input.Txt.text = V.Input.Txt.text:sub(1,V.Input.Txt.text:len()-1) end
		end
	end

	O:set("caption", V.Input.Txt.text)
	if event.phase == "editing" then 
		if Props.changeSound~= nil then audio.play(Theme.Sounds[Props.changeSound]) end
		if Props.onChange then Props.onChange(
			{
			Widget = O,
			Props  = Props,
			name   = Props.name,
			value  = V.Input.Txt.text,
			}) end 
	--elseif event.phase == "ended" or event.phase == "submitted" then
		--V._RemoveInput()
	end
end

V._RemoveInput = function(restore)
	if V.Input ~= nil then
		local O   = V.Input.MyObject
		local txt = V.Input.Txt.text; if (txt == "" and O.Props.notEmpty == true) or restore == true then txt = V.Input.oText end
		
		V.Input.MyObject:set("caption", txt)
		if O.Props.onBlur then O.Props.onBlur(
			{
			Widget = O,
			Props  = O.Props,
			name   = O.Props.name,
			value  = txt,
			}) end
		
		V.Input.Txt:removeSelf()
		V.Input.QuitTxt:removeSelf()
		V.Input.Border:removeSelf()
		V.Input.Border   = nil
		V.Input.MyObject = nil
		V.Input.Txt      = nil
		V.Input.QuitTxt  = nil
		V.Input          = nil
		native.setKeyboardFocus(nil)

		-- REMOVE MODAL BG?
		V.numModals = V.numModals - 1
		if V.numModals == 0 then V.Fader:removeSelf(); V.Fader = nil end
	end
	return true
end


----------------------------------------------------------------
-- PRIVATE: CREATE A NEW SPRITE
----------------------------------------------------------------
if graphics.newImageSheet == nil then

	-- OLD API
	V.newSprite = function(Set, frame)
		local    Img = sprite.newSprite(Set)
		function Img:setFrame(frame) self.currentFrame = frame end
		function Img:getFrame() return self.currentFrame end
		Img:setFrame( frame ~= nil and frame or 1 )
		return   Img
	end

else

	-- NEW API
	V.newSprite = function(Set, frame)
		local Img = display.newSprite(Set.Sheet, Set.Sequence)
		function Img:getFrame() return self.frame end
		Img:setSequence("all")
		Img:setFrame   ( frame ~= nil and frame or 1 )
		return Img
		--return display.newImageRect( Set.Sheet, frame, Set.Options.width, Set.Options.height )
	end

end



----------------------------------------------------------------


----------------------------------------------------------------
-- PUBLIC: LOAD A THEME
----------------------------------------------------------------
V.LoadTheme = function ( themeName, folderPath)
	local i, Theme

	if V.Themes[themeName] ~= nil then print("!!! WIDGET ERROR: LoadTheme(): Theme '"..themeName.."' already loaded!"); return end
	
	Theme = require(themeName)
	
	-- LOAD SOUNDS
	Theme.Sounds = {}
	for i = 1,#Theme.SoundFiles do
		table.insert(Theme.Sounds, audio.loadSound(folderPath..Theme.SoundFiles[i]))
	end

	-- LOAD SPRITE SHEET (OLD API)
	if graphics.newImageSheet == nil then
		Theme.Sheet      = sprite.newSpriteSheet(folderPath..Theme.widgetGraphics, Theme.widgetFrameSize, Theme.widgetFrameSize)
		Theme.Set        = sprite.newSpriteSet  (Theme.Sheet,1,Theme.Sheet.frameCount)
		Theme.SheetIcons = sprite.newSpriteSheet(folderPath..Theme.iconGraphics, Theme.iconFrameSize, Theme.iconFrameSize)
		Theme.SetIcons   = sprite.newSpriteSet  (Theme.SheetIcons,1,Theme.SheetIcons.frameCount)
	
	-- LOAD IMAGE SHEET (NEW API)
	else
		local SheetOptions =
			{
			sheetContentWidth  = Theme.widgetSheetSize,
			sheetContentHeight = Theme.widgetSheetSize,
			width              = Theme.widgetFrameSize,
			height             = Theme.widgetFrameSize,
			numFrames          = V.Floor(Theme.widgetSheetSize / Theme.widgetFrameSize) * V.Floor(Theme.widgetSheetSize / Theme.widgetFrameSize),
			}

		local IconOptions =
			{
			sheetContentWidth  = Theme.iconSheetSize,
			sheetContentHeight = Theme.iconSheetSize,
			width              = Theme.iconFrameSize,
			height             = Theme.iconFrameSize,
			numFrames          = V.Floor(Theme.iconSheetSize / Theme.iconFrameSize) * V.Floor(Theme.iconSheetSize / Theme.iconFrameSize),
			}

		local SheetSequence = { name = "all", start = 1, count = SheetOptions.numFrames }	
		local IconSequence  = { name = "all", start = 1, count = IconOptions.numFrames}	
			
		Theme.Set = 
			{
			Sheet    = graphics.newImageSheet(folderPath..Theme.widgetGraphics, SheetOptions),
			Options  = SheetOptions,
			Sequence = SheetSequence,
			}

		Theme.SetIcons  = 
			{
			Sheet    = graphics.newImageSheet(folderPath..Theme.iconGraphics  , IconOptions),
			Options  = IconOptions,
			Sequence = IconSequence,
			}
	end

	Theme.folderPath    = folderPath

	V.Themes[themeName] = Theme
	V.Themes[themeName].color = {255,255,255,255}

	V.print("--> Widgets.LoadTheme(): Loaded theme '"..themeName.."'.")
end


----------------------------------------------------------------
-- PUBLIC: SET THEME COLOR
----------------------------------------------------------------
V.SetThemeColor = function ( themeName, color)
	if V.Themes[themeName] == nil then print("!!! WIDGET ERROR: SetThemeColor(): Theme '"..themeName.."' does not exist!"); return end
	
	V.Themes[themeName].color = color
	
	-- LOOP THROUGH EXISTING WIDGETS, APPLY COLOR
	local name, Widget
	for name,Widget in pairs(V.Widgets) do 
		Widget.Props.color = color
		Widget:_update()
	end
end

----------------------------------------------------------------
-- PUBLIC: SET DEFAULT THEME
----------------------------------------------------------------
V.SetTheme = function(name, applyNow, color) 
	local k,v,W
	if V.Themes[name] == nil then print("!!! WIDGET ERROR: SetTheme(): Theme '"..name.."' does not exist!"); return end

	V.defaultTheme = name 
	
	if color then V.Themes[name].color = color end

	if applyNow == true then
		-- APPLY TO EXISTING WIDGETS
		for k,v in pairs(V.Widgets) do
			V.Widgets[k].Props.theme = name
			V.Widgets[k]:_create()
		end
		-- RE-LAYOUT WINDOWS
		for k,v in pairs(V.Widgets) do if V.Widgets[k].Widgets then V.Widgets[k]:layout() end end
	end
end

----------------------------------------------------------------
-- PUBLIC: UNLOAD A THEME
----------------------------------------------------------------
V.UnloadTheme = function (themeName)
	local Theme = V.Themes[themeName]; if Theme == nil then print("!!! WIDGET ERROR: UnloadTheme(): No theme named '"..themeName.."' found!"); return end

	-- UNLOAD SOUNDS
	while #Theme.Sounds > 0 do
		audio.dispose(Theme.Sounds[#Theme.Sounds])
		table.remove(Theme.Sounds)
	end
	
	-- UNLOAD IMAGES
	if Theme.Sheet      ~= nil then Theme.Sheet:dispose() end
	if Theme.SheetIcons ~= nil then Theme.SheetIcons:dispose() end
	
	-- NEW IMAGE API USED?
	Theme.Set.Sheet         = nil 
	Theme.Set.Options       = nil 
	Theme.Set.Sequence      = nil 
	Theme.SetIcons.Sheet    = nil 
	Theme.SetIcons.Options  = nil 
	Theme.SetIcons.Sequence = nil 
	
	-- AND BYE!
	local k,v; for k,v in pairs(Theme) do Theme[k] = nil end
	V.Themes[themeName] = nil

	V.print("--> Widgets.UnloadTheme(): Removed theme '"..themeName.."'.")
end


----------------------------------------------------------------
-- PRIVATE: REMOVE A WIDGET
----------------------------------------------------------------
V._RemoveWidget = function (name)

	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: RemoveWidget(): No widget named '"..name.."' found!"); return end

	if Widget.typ ~= V.TYPE_LABEL then Widget:removeEventListener("touch", V._OnWidgetTouch ) end
	if V.Input ~= nil and V.Input.MyObject == Widget then V._RemoveInput() end

	local k,v; for k,v in pairs(Widget.Props) do Widget.Props[k] = nil end
	
	if Widget.FadeTrans ~= nil then transition.cancel(Widget.FadeTrans); Widget.FadeTrans = nil end
	
	Widget.show          = nil
	Widget.enable        = nil
	Widget.set           = nil
	Widget.get           = nil
	Widget.getShape      = nil
	Widget.getHandle     = nil
	Widget.destroy       = nil
	Widget.Props         = nil
	Widget._drawDragged  = nil
	Widget._drawPressed  = nil
	Widget._drawReleased = nil
	Widget._create       = nil
	Widget._update       = nil
	display.remove(Widget)
	V.Widgets[name]      = nil
	Widget               = nil
	
	V.print("--> Widgets: Removed widget '"..name.."'.")
end


----------------------------------------------------------------
-- PUBLIC: REMOVE ALL WIDGETS
----------------------------------------------------------------
V.RemoveAllWidgets = function (unloadThemes)
	local i,v
	if unloadThemes == true then for i,v in pairs(V.Themes) do V.UnloadTheme(i) end end
	for i,v in pairs(V.Widgets) do V._RemoveWidget(i) end
	collectgarbage("collect")
end


----------------------------------------------------------------
-- PUBLIC: SET / GET WIDGET PROPERTIES
----------------------------------------------------------------
V.Set = function (name, A, B)
	local i,v
	local list   = {}
	local create = false
	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: Set(): Widget '"..name.."' does not exist!"); return end
	
	-- SINGLE PROPERTY OR LIST OF PROPERTIES?
	if type(A) == "string" then list[A] = B else list = A end
	
	-- SET PROPERTIES
	for i,v in pairs(list) do Widget.Props[i] = v; if i == "theme" then create = true end end

	V._CheckProps(Widget)

	-- NEED TO RE-CREATE GRAPHICS?
	if create == true then Widget:_create() else Widget:_update() end

	-- INCLUDE CHILDREN?
	if B and Widget.Widgets then
		for i = 1, Widget.Widgets.numChildren do V.Set(Widget.Widgets[i].Props.name, A,B) end
		Widget:layout()
	end
	V.print("--> Widgets.Set(): Updated properties of widget '"..name.."'.")
end

V.Get = function (name, A)
	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: get(): Widget '"..name.."' does not exist!"); return end
	local n,v
	local values = {}
	-- RETURN A TABLE WITH ALL PROPERTIES
	if A == nil then
		for n,v in pairs(Widget.Props) do values[n] = v end; return values
	-- RETURN A SINGLE PROPERTY VALUE ONLY
	elseif type(A) == "string" then 
		return Widget.Props[A] 
	-- RETURN A TABLE WITH SELECTED VALUES
	else
		for n,v in pairs(A) do values[v] = Widget.Props[v] end; return values
	end
end

V.Show = function (name, state, anim) 
	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: show(): Widget '"..name.."' does not exist!"); return end
	if Widget.isVisible == state then return end
	if Widget.FadeTrans ~= nil   then transition.cancel(Widget.FadeTrans); Widget.FadeTrans = nil end
	if anim == true then
		Widget.isVisible = true
		Widget.alpha     = state == true and 0 or Widget.Props.alpha
		local alpha      = state == true and Widget.Props.alpha or 0
		Widget.FadeTrans = transition.to(Widget, {time = 300, alpha = alpha, onComplete = function() Widget.alpha = Widget.Props.alpha; Widget.isVisible = state end})
	else
		Widget.isVisible = state
	end
end

V.Enable = function (name, state) 
	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: Enable(): Widget '"..name.."' does not exist!"); return end
	Widget.Props.enabled = state
	Widget.alpha = Widget.Props.enabled == true and Widget.Props.alpha or Widget.Props.alpha * V.Themes[Widget.Props.theme].WidgetDisabledAlpha
end

V.GetShape = function (name)
	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: GetShape(): Widget '"..name.."' does not exist!"); return end
	return Widget.Props.Shape
end

V.GetHandle = function (name) return V.Widgets[name] end

V.GetDepth = function (name)
	local Widget = V.Widgets[name]; if Widget == nil then print("!!! WIDGET ERROR: GetDepth(): Widget '"..name.."' does not exist!"); return end
	if Widget.parent ~= nil then
		local i
		local n = Widget.parent.numChildren
		for i = 1,n do if Widget.parent[i] == Widget then return i end end
	end
	return nil
end




----------------------------------------------------------------





----------------------------------------------------------------
-- PUBLIC: CREATE A BUTTON
----------------------------------------------------------------
V.NewButton = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewButton(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewButton(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_BUTTON
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize * 2.1
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 1
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp
	
	Grp.oldCaption = ""

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- LEFT CAP
		Tmp          = V.newSprite(Theme.Set, Theme.Frame_Button_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x = 0
		Tmp.y = 0
		self:insert(Tmp)
		-- MIDDLE
		Tmp          = V.newSprite(Theme.Set, Theme.Frame_Button_M)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x = size
		Tmp.y = 0
		self:insert(Tmp)
		-- RIGHT CAP
		Tmp          = V.newSprite(Theme.Set, Theme.Frame_Button_R)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)
		-- ICON 
		Tmp = V.newSprite(Theme.SetIcons)
		Tmp:setReferencePoint(display.CenterReferencePoint)
		Tmp.xScale = Theme.ButtonIconSize / Tmp.width
		Tmp.yScale = Theme.ButtonIconSize / Tmp.height
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()
	
		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local size      = Theme.widgetFrameSize

		-- FIT BUTTON WIDTH TO TEXT?
		if Props.width == "auto" and Props.caption ~= self.oldCaption then
			self.oldCaption = Props.caption
			self[5].xScale  = 1
			self[5].yScale  = 1
			self[5].text    = Props.caption 
			Props.width     = V.Round(self[5].width * .5) + size + 4
			V._CheckProps(self)
			Props.width     = "auto"
		end

		local w         = Props.Shape.w
		local h         = Props.Shape.h
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.ButtonTextColor; if textColor == nil then textColor = Theme.WidgetTextColor end
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then 
			for i = 2, 4 do self[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end
		end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]

		-- MIDDLE
		self[3].xScale = (w - size*2) / self[3].width
		-- RIGHT CAP
		self[4].x      = w
		-- CAPTION
		self[5].text   = Props.caption
		self[5]:setTextColor(textColor[1],textColor[2],textColor[3],255)
		V._WrapGadgetText(self[5], w-size-4, Theme.WidgetFont, Props.fontSize)
		self[5].xScale = 1
		self[5].yScale = 1
		self[5]:setReferencePoint(display.CenterLeftReferencePoint)
		self[5].xScale = .5
		self[5].yScale = .5
		self[5].y      = size*.5 + Theme.WidgetTextYOffset
		self[5].x      = Theme.MarginX; if Props.textAlign == "right" then self[5].x = Props.Shape.w - Theme.MarginX - self[5].width*.5 elseif Props.textAlign == "center" then self[5].x = Props.Shape.w*.5 -  self[5].width*.25 end
		-- ICON 
		local halfW = (self[6].width*self[6].xScale)*.5
		self[6]:setFrame( Props.icon > 0 and Props.icon or 1 )
		self[6].isVisible    = Props.icon > 0 and true or false
		self[6].x = halfW + Theme.MarginX; if Props.textAlign == "right" then self[6].x = Props.Shape.w - halfW-Theme.MarginX elseif Props.textAlign == "center" then self[6].x = Props.Shape.w*.5 end
		self[6].y = size*.5

		if Props.icon > 0 and Props.caption ~= "" then 
			    if Props.textAlign == "left"   then self[5].x = self[6].x + halfW + 4 
			elseif Props.textAlign == "center" then self[5].x = self[5].x + halfW + 2; self[6].x = self[5].x - halfW - 4 
			elseif Props.textAlign == "right"  then self[6].x = Props.Shape.w - halfW - Theme.MarginX; self[5].x = self[5].x - halfW*2 - 4 end
		end

		self.tx   = self[5].x
		self.ty   = self[5].y
		self.ix   = self[6].x
		self.iy   = self[6].y
		
		-- BUTTON CURRENTLY PRESSED OR NORMAL STATE?
		if self.isFocus and self.inside then self:_drawPressed() else self:_drawReleased() end
		
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW DRAGGED
	---------------------------------------------
	function Grp:_drawDragged(EventData)
		if EventData.inside then self:_drawPressed(EventData) else self:_drawReleased(EventData) end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed()
		local Props = self.Props; if Props == nil then return end
		local Theme = V.Themes [Props.theme]

		-- LEFT CAP
		self[2]:setFrame( Props.toggleState == false and Theme.Frame_ButtonDown_L or Theme.Frame_ButtonToggled_L)
		-- MIDDLE
		self[3]:setFrame( Props.toggleState == false and Theme.Frame_ButtonDown_M or Theme.Frame_ButtonToggled_M)
		-- RIGHT CAP
		self[4]:setFrame(Props.toggleState == false and  Theme.Frame_ButtonDown_R or Theme.Frame_ButtonToggled_R)
		-- CAPTION
		self[5].x = self.tx + 1; self[5].y = self.ty + 1
		-- ICON 
		self[6].x = self.ix + 1; self[6].y = self.iy + 1
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased(EventData)
		local Props = self.Props; if Props == nil then return end
		local Theme = V.Themes [Props.theme]
		
		-- TOGGLE?
		if EventData then
			if EventData.inside and Props.toggleButton then Props.toggleState = not Props.toggleState end
		end

		-- UNCHECK OTHERS?
		if Props.toggleButton and Props.toggleState == true then
			for i,v in pairs(V.Widgets) do
				local W  = V.Widgets[i]
				if W.typ == V.TYPE_BUTTON and W.Props.toggleButton and W.Props.toggleGroup == Props.toggleGroup and W.Props.toggleState and W ~= self then
					W.Props.toggleState = false
					W:_drawReleased()
				end
			end
		end
		
		-- LEFT CAP
		self[2]:setFrame( Props.toggleState == false and Theme.Frame_Button_L or Theme.Frame_ButtonToggled_L )
		-- MIDDLE
		self[3]:setFrame( Props.toggleState == false and Theme.Frame_Button_M or Theme.Frame_ButtonToggled_M )
		-- RIGHT CAP
		self[4]:setFrame( Props.toggleState == false and Theme.Frame_Button_R or Theme.Frame_ButtonToggled_R )
		-- CAPTION
		self[5].x = self.tx; self[5].y = self.ty
		-- ICON 
		self[6].x = self.ix; self[6].y = self.iy
		
	end
	
	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewButton(): Created new button '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A SQUARE BUTTON
----------------------------------------------------------------
V.NewSquareButton = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewSquareButton(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewSquareButton(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_SQUAREBUTTON
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize
	Props.minH = V.Themes[Props.theme].widgetFrameSize
	Props.maxW = Props.minW
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- BUTTON
		Tmp          = V.newSprite(Theme.Set, Theme.Frame_SquareButton)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		self:insert(Tmp)
		-- ICON 
		Tmp = V.newSprite(Theme.SetIcons)
		Tmp:setReferencePoint(display.CenterReferencePoint)
		Tmp.xScale = Theme.ButtonIconSize / Tmp.width
		Tmp.yScale = Theme.ButtonIconSize / Tmp.height
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props    = self.Props
		local Theme    = V.Themes [Props.theme]
		local size     = Theme.widgetFrameSize
		local w        = Props.Shape.w
		local h        = Props.Shape.h
		self.alpha     = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale    = Props.scale
		self.yScale    = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then self[2]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		-- BUTTON
		self[2]:setFrame( Theme.Frame_SquareButton )
		self[2].x      = 0
		self[2].y      = 0
		-- ICON 
		self[3]:setFrame  ( Props.icon > 0 and Props.icon or 1 )
		self[3].isVisible = Props.icon > 0 and true or false
		self[3].x         = size*.5
		self[3].y         = size*.5
		self.ix           = self[3].x
		self.iy           = self[3].y

		-- BUTTON CURRENTLY PRESSED OR NORMAL STATE?
		if self.isFocus and self.inside then self:_drawPressed() else self:_drawReleased() end

	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW DRAGGED
	---------------------------------------------
	function Grp:_drawDragged(EventData)
		if EventData.inside then self:_drawPressed(EventData) else self:_drawReleased(EventData) end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed()
		local Props = self.Props; if Props == nil then return end
		local Theme = V.Themes [Props.theme]
		-- BUTTON
		self[2]:setFrame( Props.toggleState == false and Theme.Frame_SquareButtonDown or Theme.Frame_SquareButtonToggled )
		-- ICON 
		self[3].x = self.ix + 1; self[3].y = self.iy + 1
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased(EventData)
		local Props = self.Props; if Props == nil then return end
		local Theme = V.Themes [Props.theme]

		-- TOGGLE?
		if EventData then
			if EventData.inside and Props.toggleButton then Props.toggleState = not Props.toggleState end
		end

		-- UNCHECK OTHERS
		if Props.toggleButton and Props.toggleState == true then
			for i,v in pairs(V.Widgets) do
				local W  = V.Widgets[i]
				if W.typ == V.TYPE_SQUAREBUTTON and W.Props.toggleButton and W.Props.toggleGroup == Props.toggleGroup and W.Props.toggleState and W ~= self then
					W.Props.toggleState = false
					W:_drawReleased()
				end
			end
		end

		-- BUTTON
		self[2]:setFrame( Props.toggleState == false and Theme.Frame_SquareButton or Theme.Frame_SquareButtonToggled )
		-- ICON 
		self[3].x = self.ix; self[3].y = self.iy
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewSquareButton(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A DRAG BUTTON
----------------------------------------------------------------
V.NewDragButton = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewDragButton(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewDragButton(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_DRAGBUTTON
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize
	Props.minH = V.Themes[Props.theme].widgetFrameSize
	Props.maxW = Props.minW
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- BUTTON
		Tmp   = V.newSprite(Theme.Set, Theme.Frame_DragButton)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x     = 0
		Tmp.y     = 0
		self:insert(Tmp)
		-- BUBBLE GROUP
		local Grp = display.newGroup()
		Grp:setReferencePoint(display.CenterRightReferencePoint)
		self:insert(Grp)
		Grp.alpha = 0
		-- BUBBLE L
		Tmp              = V.newSprite(Theme.Set, Theme.Frame_Tooltip_L)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Tmp.y            = 0
		Grp:insert(Tmp)
		-- BUBBLE M
		Tmp              = V.newSprite(Theme.Set, Theme.Frame_Tooltip_M)
		Tmp:setReferencePoint(display.TopCenterReferencePoint)
		Tmp.y            = 0
		Grp:insert(Tmp)
		-- BUBBLE R
		Tmp              = V.newSprite(Theme.Set, Theme.Frame_Tooltip_R)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y            = 0
		Grp:insert(Tmp)
		-- CAPTION		
		Tmp           = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale    = .5
		Tmp.yScale    = .5
		Grp:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props    = self.Props
		local Theme    = V.Themes [Props.theme]
		local size     = Theme.widgetFrameSize
		local w        = Props.Shape.w
		local h        = Props.Shape.h
		self.alpha     = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale    = Props.scale
		self.yScale    = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then self[2]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed(event)
		self.sx     = event.lx
		self.sy     = event.ly
		self.val    = self.Props.value
		-- BUTTON
		self[2]:setFrame( V.Themes[self.Props.theme].Frame_DragButtonDown )
		-- SHOW BUBBLE
		if self.Props.hideBubble ~= true then
			self.Trans = transition.to(self[3], {time = 250, alpha = 1})
		end
		self:_setValue(event)
	end
	
	---------------------------------------------
	-- PRIVATE METHOD: DRAW DRAGGED
	---------------------------------------------
	function Grp:_drawDragged(event)
		local Props = self.Props
		local val   = Props.value
		self:_setValue(event)
		if Props.value ~= val and Props.onChange then 
			if Props.changeSound~= nil then audio.play(V.Themes[Props.theme].Sounds[Props.changeSound]) end
			local EventData =
				{
				Widget = self,
				Props  = Props,
				name   = Props.name,
				value  = Props.value,
				}
			Props.onChange(EventData) 
		end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased()
		-- BUTTON
		self[2]:setFrame( V.Themes[self.Props.theme].Frame_DragButton )
		-- HIDE BUBBLE
		if self.Trans then transition.cancel(self.Trans) end
		self[3].alpha  = 0
	end

	---------------------------------------------
	-- PRIVATE METHOD: SET VALUE
	---------------------------------------------
	function Grp:_setValue(event)
		local Props       = self.Props
		local sensitivity = Props.sensitivity ~= nil and Props.sensitivity or 0.05
		local Theme       = V.Themes [Props.theme]
		local size        = Theme.widgetFrameSize
		local Bubble      = self[3]
		local step        = Props.step ~= nil and Props.step or 1
		local textColor   = Props.textColor ~= nil and Props.textColor or Theme.BubbleTextColor

		Props.value  = self.val + (V.Round( (self.sy - event.ly) * sensitivity )*step)
		    if Props.value < Props.minValue then Props.value = Props.minValue
		elseif Props.value > Props.maxValue then Props.value = Props.maxValue end
		
		-- CAPTION
		Bubble[4].text   = Props.textFormatter == nil and Props.value or Props.textFormatter(Props.value)
		Bubble[4].xScale = 1
		Bubble[4].yScale = 1
		Bubble[4]:setReferencePoint(display.CenterReferencePoint)
		Bubble[4].xScale = .5
		Bubble[4].yScale = .5
		Bubble[4].y      = size*.5 + Theme.TooltipTextYOffset
		Bubble[4]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		-- MIDDLE / LEFT / RIGHT CAPS
		Bubble[2].xScale =  (Bubble[4].width*.5) / Bubble[2].width
		Bubble[1].x      = -(Bubble[4].width*.25)
		Bubble[3].x      =  (Bubble[4].width*.25)
		-- POSITION BUBBLE
		Bubble.x = -(Bubble[4].width*.5 + size*.5)
		Bubble.y = 0
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewDragButton(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A CHECKBOX
----------------------------------------------------------------
V.NewCheckbox = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewCheckbox(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewCheckbox(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_CHECKBOX
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize
	Props.minH = V.Themes[Props.theme].widgetFrameSize
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local currentFrame

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- BUTTON
		currentFrame = Props.toggleState == false and Theme.Frame_CheckBox or Theme.Frame_CheckBoxChecked
		Tmp          = V.newSprite(Theme.Set, currentFrame)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then self[2]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		-- CAPTION
		self[3].text   = Props.caption
		self[3]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		V._WrapGadgetText(self[3], w-size-4, Theme.WidgetFont, Props.fontSize)
		self[3].xScale = 1
		self[3].yScale = 1
		self[3]:setReferencePoint(display.CenterLeftReferencePoint)
		self[3].xScale = .5
		self[3].yScale = .5
		self[3].y      = size*.5 + Theme.WidgetTextYOffset

		-- TEXT ALIGN
		if Props.textAlign == "right" then
			self[2].x = 0
			self[3].x = size + 4
		else
			self[2].x = w-size
			self[3].x = w-size - 4 - self[3].width*.5
		end

		-- IS SELECTED?
		self[2]:setFrame( Props.toggleState == false and Theme.Frame_CheckBox or Theme.Frame_CheckBoxChecked )
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed() 
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		Props.toggleState = not Props.toggleState
		self[2]:setFrame( Props.toggleState == false and Theme.Frame_CheckBox or Theme.Frame_CheckBoxChecked )
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased() end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewCheckbox(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A RADIO BUTTON
----------------------------------------------------------------
V.NewRadiobutton = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewRadiobutton(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewRadiobutton(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_RADIO
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize
	Props.minH = V.Themes[Props.theme].widgetFrameSize
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local currentFrame

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- BUTTON
		currentFrame = Props.toggleState == false and Theme.Frame_RadioButton or Theme.Frame_RadioButtonChecked
		Tmp          = V.newSprite(Theme.Set, currentFrame)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then self[2]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		-- CAPTION
		self[3].text   = Props.caption
		self[3]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		V._WrapGadgetText(self[3], w-size, Theme.WidgetFont, Props.fontSize)
		self[3].xScale = 1
		self[3].yScale = 1
		self[3]:setReferencePoint(display.CenterLeftReferencePoint)
		self[3].xScale = .5
		self[3].yScale = .5
		self[3].y      = size*.5 + Theme.WidgetTextYOffset

		-- TEXT ALIGN
		if Props.textAlign == "right" then
			self[2].x = 0
			self[3].x = size
		else
			self[2].x = w-size
			self[3].x = w-size - self[3].width*.5
		end
		
		-- IS SELECTED?
		if Props.toggleState == true then self:_drawPressed() end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed() 
		local i,v
		local Props = self.Props
		local Theme = V.Themes[Props.theme]
		-- CHECK THIS
		Props.toggleState =  true 
		self[2]:setFrame( Theme.Frame_RadioButtonChecked )
		-- UNCHECK OTHERS
		for i,v in pairs(V.Widgets) do
			if V.Widgets[i].typ == V.TYPE_RADIO and V.Widgets[i].Props.toggleGroup == Props.toggleGroup and V.Widgets[i] ~= self then
				V.Widgets[i].Props.toggleState = false
				V.Widgets[i][2]:setFrame( V.Themes[V.Widgets[i].Props.theme].Frame_RadioButton )
			end
		end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased() end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewRadiobutton(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A MULTILINE TEXT
----------------------------------------------------------------
V.NewText = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewText(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewText(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_TEXT
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize
	Props.minH = V.Floor(V.Themes[Props.theme].WidgetFontSize * 1.5)
	Props.maxW = 9999
	Props.maxH = 9999

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local w     = Props.Shape.w
		local h     = Props.Shape.h

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp = display.newGroup(); self:insert(Tmp)

		local i,c,Tmp,brk,old,new,pos
		local maxW  =  w*2 - Props.fontSize*2
		local lineH =  Props.fontSize + Props.lineSpacing
		local y     =  2
		local autoH = false; if Props.height == 0 or Props.height == "auto" then autoH = true end
		local lines = {}

		-- SPLIT TEXT BY LINE FEEDS ("|")
		pos = 1
		while pos < #Props.caption do
			brk = Props.caption:find('|', pos, true); if brk == nil then brk = #Props.caption end
			c   = Props.caption:sub(brk, brk)
			i   = 0 if c == "|" or c == " " then i = 1 end
			table.insert(lines, Props.caption:sub(pos, brk-i) )
			pos = brk + 1
		end

		-- CREATE EACH LINE AND WRAP IT, IF NECCESSARY
		for i = 1, #lines do
			if autoH == false and y + lineH > h then break end

			-- NEW TEXT LINE?
			if lines[i] ~= "" then
				Tmp    = display.newText(self,"",0,y,Theme.WidgetFont,Props.fontSize*2)
				Tmp.yy = y
			end

			y = y + lineH

			pos = 1
			while pos <= #lines[i] do
				brk = lines[i]:find('[ %-%;,]', pos, false); if brk == nil then brk = #lines[i] end
				new = lines[i]:sub(pos, brk)
				old = Tmp.text
				Tmp.text = Tmp.text..new
				-- NEW TEXT LINE?
				if Tmp.width > maxW then
					Tmp.text = old:gsub("[%s]*$", "")
					if autoH == false and y + lineH > h then break end
					Tmp      =  display.newText(self,new,0,y,Theme.WidgetFont,Props.fontSize*2)
					Tmp.yy   =  y
					y        =  y + lineH
				end
				pos = brk + 1
			end
		end

		-- APPLY AUTO-HEIGHT?
		if autoH then 
			Props.Shape.h = Tmp ~= nil and Tmp.yy + Tmp.height*.5 + 2 or 0
			if Props.Shape.h < Props.minH then Props.Shape.h = Props.minH end
		end

		self.oldCaption = Props.caption
		self.oldWidth   = Props.Shape.w
		self.oldHeight  = Props.Shape.h
		self:_update() 
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()
		local Tmp,i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- RE-CREATE TEXT LINES?
		if Props.caption ~= self.oldCaption or w ~= self.oldWidth or h ~= self.oldHeight then 
			self:_create()
		end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]

		-- ALIGN TEXT LINES, SET COLOR
		for i = 2, self.numChildren do
			if self[i].text then
				self[i]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
				self[i].xScale = 1
				self[i].yScale = 1
				self[i]:setReferencePoint(display.TopLeftReferencePoint)
				self[i].xScale = .5
				self[i].yScale = .5
				self[i].x      = Props.fontSize*.5; if Props.textAlign == "center" then self[i].x = w*.5 - self[i].width*.25 elseif Props.textAlign == "right" then self[i].x = w - self[i].width*.5 - Props.fontSize*.5 end
				self[i].y      = self[i].yy
			end
		end
		
		-- RE-ALIGN ON SCREEN
		self:setPos(self.Props.x, self.Props.y)

	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewText(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A PROGRESS BAR
----------------------------------------------------------------
V.NewProgBar = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewProgBar(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewProgBar(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount = V.widgetCount + 1
	Grp           = display.newGroup()
	Grp.typ       = V.TYPE_PROGBAR
	Grp.Props     = Props
	
	Grp.Mask      = graphics.newMask(V.Themes[Props.theme].folderPath..V.Themes[Props.theme].maskImage)
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize * 3
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 1
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp, G
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp = display.newGroup(); self:insert(Tmp)
		-- LEFT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Progress_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		self:insert(Tmp)
		-- MIDDLE
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Progress_M)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		self:insert(Tmp)
		-- RIGHT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Progress_R)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		self:insert(Tmp)
		-- BAR
		local Grp = display.newGroup()
		Grp:setMask(self.Mask)
		Grp.maskScaleY      = size / Theme.maskImageSize
		Grp.maskY           = size*.5
		Grp.isHitTestMasked = true
		self:insert(Grp)

		Tmp = V.newSprite(Theme.Set, Theme.Frame_ProgressBar_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Grp:insert(Tmp)

		Tmp = V.newSprite(Theme.Set, Theme.Frame_ProgressBar_M)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Grp:insert(Tmp)

		Tmp = V.newSprite(Theme.Set, Theme.Frame_ProgressBar_R)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Grp:insert(Tmp)
		-- CAPTION SHADOW
		Tmp = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp:setTextColor(Theme.EmbossColorLow[1],Theme.EmbossColorLow[2],Theme.EmbossColorLow[3],255)  
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- COLORIZE PARTS?
		for i = 2,4 do self[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		-- LEFT CAP
		self[2].x      = 0
		self[2].y      = 0
		-- MIDDLE
		self[3].x      = size
		self[3].y      = 0
		self[3].xScale = (w-(size*2)) / self[3].width
		-- RIGHT CAP
		self[4].x      = w
		self[4].y      = 0
		-- BAR
		self:_setValue(Props.value)
		self[5][1].x      = 0
		self[5][1].y      = 0
		self[5][2].x      = size
		self[5][2].y      = 0
		self[5][2].xScale = (w-(size*2)) / self[5][2].width
		self[5][3].x      = w
		self[5][3].y      = 0
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE WIDGET'S VALUE (AND BAR)
	---------------------------------------------
	function Grp:_setValue(value)
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor

		    if value  < Props.minValue then value = Props.minValue 
		elseif value  > Props.maxValue then value = Props.maxValue end
		Props.percent = V.Floor( value*100 )
		Props.value   = value

		-- BAR
		local v = Props.value == 0 and 0.001 or Props.value
		self[5].maskScaleX = (v * (Props.Shape.w)) / Theme.maskImageSize
		self[5].maskX      =  v * (Props.Shape.w)*.5

		-- CAPTION
		self[6].text   = Props.textFormatter == nil and Props.value or Props.textFormatter(Props.value)
		V._WrapGadgetText(self[6], Props.Shape.w-Theme.widgetFrameSize-4, Theme.WidgetFont, Props.fontSize)
		self[6].xScale = 1
		self[6].yScale = 1
		self[6]:setReferencePoint(display.CenterLeftReferencePoint)
		self[6].xScale = .5
		self[6].yScale = .5
		self[6].y      = (Theme.widgetFrameSize*.5 + Theme.WidgetTextYOffset)+1
		self[6].x      = (Props.Shape.w*.5 - self[6].width*.25)+1

		self[7]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		self[7].text   = self[6].text
		self[7].xScale = 1
		self[7].yScale = 1
		self[7]:setReferencePoint(display.CenterLeftReferencePoint)
		self[7].xScale = .5
		self[7].yScale = .5
		self[7].x      = self[6].x-1
		self[7].y      = self[6].y-1
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed(event)
		if self.Props.allowDrag then self:_setValue( event.lx / self.Props.Shape.w ) end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased() end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW DRAGGED
	---------------------------------------------
	function Grp:_drawDragged(event) 
		if self.Props.allowDrag then self:_setValue ( event.lx / self.Props.Shape.w ) end
	end

	---------------------------------------------
	-- PUBLIC METHOD: DESTROY
	---------------------------------------------
	function Grp:destroy() 
		self[5]:setMask(nil)
		self.Mask     = nil
		V._RemoveWidget(self.Props.name) 
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewProgBar(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A BORDER
----------------------------------------------------------------
V.NewBorder = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewBorder(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewBorder(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_BORDER
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize
	Props.minH = V.Themes[Props.theme].widgetFrameSize
	Props.maxW = 9999
	Props.maxH = 9999

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create() 
		Tmp = display.newGroup(); self:insert(Tmp)
		Grp:_update() 
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()
		local Tmp,i,v
		local Props    = self.Props
		local Theme    = V.Themes [Props.theme]
		local size     = Theme.widgetFrameSize

		self.alpha     = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale    = Props.scale
		self.yScale    = Props.scale

		Props.includeInLayout = false

		-- FIT TO A WIDGET GROUP
		if Props.group ~= "" then
			Props.x      = 0
			Props.y      = 0
			local minX   =  9999
			local maxX   = -9999
			local minY   =  9999
			local maxY   = -9999
			local Parent = Props.parentGroup
			local P
			for i,v in pairs(V.Widgets) do 
				P = V.Widgets[i].Props
				if P ~= nil and P.parentGroup == Parent and (P.group == Props.group or Props.group == "auto") and P.name ~= Props.name then
					if P.Shape.x < minX then minX = P.Shape.x end
					if P.Shape.x+P.Shape.w*P.scale > maxX then maxX = P.Shape.x + P.Shape.w*P.scale end
					if P.Shape.y < minY then minY = P.Shape.y end
					if P.Shape.y+P.Shape.h*P.scale > maxY then maxY = P.Shape.y + P.Shape.h*P.scale end
				end
			end
			self.x        = minX
			self.y        = minY
			Props.Shape.x = minX
			Props.Shape.y = minY
			Props.Shape.w = maxX-minX
			Props.Shape.h = maxY-minY
		end
		
		-- BACKGROUND & BORDER
		V._AddBorder(self)

	end


	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewBorder(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A SWITCH
----------------------------------------------------------------
V.NewSwitch = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewSwitch(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewSwitch(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_SWITCH
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize * 2
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 1
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp
	
	Grp.lastState = Grp.Props.toggleState

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp = display.newGroup(); self:insert(Tmp)
		-- LEFT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Switch_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- RIGHT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Switch_R)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- SLIDER 
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Switch_Button)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then 
			for i = 2, 4 do self[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end
		end

		-- SET SWITCH COLOR
		self:_setColor()

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		-- CAPTION
		self[5].text   = Props.caption
		self[5]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		V._WrapGadgetText(self[5], w-(size*2)-4, Theme.WidgetFont, Props.fontSize)
		self[5].xScale = 1
		self[5].yScale = 1
		self[5]:setReferencePoint(display.CenterLeftReferencePoint)
		self[5].xScale = .5
		self[5].yScale = .5
		self[5].y      = size*.5 + Theme.WidgetTextYOffset
		-- TEXT ALIGN
		if Props.textAlign == "left" then
			self[2].x = 0
			self[3].x = size
			self[4].x = Props.toggleState == false and self[2].x or self[3].x
			self[5].x = size*2 + 4
		else
			self[2].x = w-size*2
			self[3].x = w-size
			self[4].x = Props.toggleState == false and self[2].x or self[3].x
			self[5].x = self[2].x - 4 - self[5].width*.5
		end
		
		-- CHECK IF TOGGLE STATE CHANGED PROGRAMMATICALLY?
		self:_changed()

	end

	---------------------------------------------
	-- PRIVATE METHOD: CURRENTLY DRAGGED
	---------------------------------------------
	function Grp:_setPos( event )
		local Props    = self.Props
		local halfSize = V.Themes[Props.theme].widgetFrameSize *.5
		local x        = event.lx - halfSize; if x < self[2].x then x = self[2].x elseif x > self[3].x then x = self[3].x end
		if self.Trans then transition.cancel(self.Trans); self.Trans = nil end

		-- SET TOGGLESTATE
		Props.toggleState = x > self[2].x + halfSize and true or false
		
		-- SET SWITCH COLOR
		self:_setColor()

		-- DRAG KNOB
		self[4].x = x
	end
	
	---------------------------------------------
	-- PRIVATE METHOD: APPLY CUSTOM COLOR
	---------------------------------------------
	function Grp:_setColor()
		local Props    = self.Props
		local Theme    = V.Themes [Props.theme]
		-- SET COLOR?
		if Theme.SwitchOnColor then
			if Props.toggleState == true then 
				self[2]:setFillColor(Theme.SwitchOnColor[1],Theme.SwitchOnColor[2],Theme.SwitchOnColor[3],255) 
				self[3]:setFillColor(Theme.SwitchOnColor[1],Theme.SwitchOnColor[2],Theme.SwitchOnColor[3],255) 
			else
				self[2]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) 
				self[3]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) 
			end
		end
	end
	
	---------------------------------------------
	-- PRIVATE METHOD: TOGGLE STATE CHANGED
	---------------------------------------------
	function Grp:_changed()
		local Props = self.Props
		if self.lastState ~= Props.toggleState then
			self.lastState = Props.toggleState
			if Props.changeSound~= nil then audio.play(V.Themes[Props.theme].Sounds[Props.changeSound]) end
			if Props.onChange   ~= nil then Props.onChange(
				{
				Widget      = self,
				Props       = Props,
				name        = Props.name,
				toggleState = Props.toggleState,
				}) 
			end
		end
	end
	
	---------------------------------------------
	-- PRIVATE METHODS: PRESSED / DRAGGED / RELEASED
	---------------------------------------------
	function Grp:_drawPressed ( event ) Grp:_setPos(event) end
	function Grp:_drawDragged ( event ) Grp:_setPos(event) end

	function Grp:_drawReleased( event ) 
		-- SLIDE OUT, THEN CALL _changed()		
		self.SlideTimer = timer.performWithDelay(1,
			function(event)
				local Widget = event.source.Widget
				local x      = event.source.targetX
				local Knob   = Widget[4]
				Knob.x       = Knob.x - (Knob.x - x)/2
				if V.Abs(Knob.x - x) < 1 then
					Knob.x = V.Round(x)
					timer.cancel(Widget.SlideTimer)
					event.source.Widget.SlideTimer = nil
					event.source.Widget            = nil
					Widget:_changed()
				end
			end	,0)
		self.SlideTimer.Widget  = self
		self.SlideTimer.targetX = self.Props.toggleState == true and self[3].x or self[2].x
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewSwitch(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A SLIDER
----------------------------------------------------------------
V.NewSlider = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewSlider(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewSlider(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_SLIDER
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	if Props.vertical == true then
		Props.minW = V.Themes[Props.theme].widgetFrameSize * 1
		Props.minH = V.Themes[Props.theme].widgetFrameSize * 3
		Props.maxW = Props.minW
		Props.maxH = 9999
	else
		Props.minW = V.Themes[Props.theme].widgetFrameSize * 3
		Props.minH = V.Themes[Props.theme].widgetFrameSize * 1
		Props.maxW = 9999
		Props.maxH = Props.minH
	end

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp
	
	Grp.oldValue = Grp.Props.value

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp = display.newGroup(); self:insert(Tmp)
		-- LEFT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Slider_L)
		if Props.vertical then 
			Tmp:setReferencePoint(display.BottomLeftReferencePoint)
			Tmp.rotation = 90
			Tmp.x        = size
			Tmp.y        = 0
			Tmp.yScale   = -1 
		else
			Tmp:setReferencePoint(display.TopLeftReferencePoint)
			Tmp.x        = 0
			Tmp.y        = 0
		end
		self:insert(Tmp)
		-- MIDDLE
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Slider_M)
		if Props.vertical then 
			Tmp:setReferencePoint(display.TopLeftReferencePoint)
			Tmp.rotation = 90
			Tmp.x        = 0
			Tmp.y        = size 
			Tmp.yScale   = -1 
		else
			Tmp:setReferencePoint(display.TopLeftReferencePoint)
			Tmp.x        = size
			Tmp.y        = 0
		end
		self:insert(Tmp)
		-- RIGHT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Slider_R)
		if Props.vertical then 
			Tmp:setReferencePoint(display.TopRightReferencePoint)
			Tmp.rotation = 90
			Tmp.x        = 0 
			Tmp.yScale   = -1 
		else
			Tmp:setReferencePoint(display.TopRightReferencePoint)
			Tmp.y        = 0
		end
		self:insert(Tmp)
		-- TICKS GROUP
		local Grp = display.newGroup(); self:insert(Grp)
		-- SLIDER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Slider_Button)
		Tmp:setReferencePoint(display.TopCenterReferencePoint)
		Tmp.x = 0
		Tmp.y = 0
		if Props.vertical then 
			Tmp.rotation = 90
			Tmp.yScale   = -1
		end
		self:insert(Tmp)
		-- BUBBLE GROUP
		local Grp = display.newGroup(); self:insert(Grp)
		Grp.alpha = Props.alwaysShowBubble ~= true and 0 or 1
		-- BUBBLE L
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Tooltip_L)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Tmp.y            = 0
		Grp:insert(Tmp)
		-- BUBBLE M
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Tooltip_M)
		Tmp:setReferencePoint(display.TopCenterReferencePoint)
		Tmp.y            = 0
		Grp:insert(Tmp)
		-- BUBBLE R
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Tooltip_R)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.y            = 0
		Grp:insert(Tmp)
		-- CAPTION		
		Tmp           = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale    = .5
		Tmp.yScale    = .5
		Grp:insert(Tmp)
		
		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props    = self.Props
		local Theme    = V.Themes [Props.theme]
		local size     = Theme.widgetFrameSize
		local w        = Props.Shape.w
		local h        = Props.Shape.h
		self.alpha     = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale    = Props.scale
		self.yScale    = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then 
			for i = 2, 4 do self[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end
			self[6]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255)
		end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		-- MIDDLE
		if Props.vertical then self[3].xScale = (h-(size*2)) / self[3].width else self[3].xScale = (w-(size*2)) / self[3].width end
		-- RIGHT CAP
		if Props.vertical then self[4].y = h else self[4].x = w end
		-- SLIDER
		self:_setValue(Props.value)
		-- TICKS
		self[5]:removeSelf()
		local Grp = display.newGroup(); self:insert(5, Grp)
		local stepSize
		if Props.tickStep and Props.tickStep > 1 then
			if Props.vertical then
				stepSize = (h-size) / ((Props.maxValue-Props.minValue)/Props.tickStep)
				for i = size*.5, h-size*.5, stepSize do
					Tmp = display.newRect(Grp,size*.5+Theme.SliderTicksCenterOffset,V.Floor(i), 4,1)
					Tmp.strokeWidth  = 1
					Tmp:setStrokeColor(Theme.SliderTickStrokeColor [1],Theme.SliderTickStrokeColor [2],Theme.SliderTickStrokeColor [3])
					Tmp:setFillColor  (Theme.SliderTickFillColor[1],Theme.SliderTickFillColor[2],Theme.SliderTickFillColor[3])
				end
			else
				stepSize = (w-size) / ((Props.maxValue-Props.minValue)/Props.tickStep)
				for i = size*.5, w-size*.5, stepSize do
					Tmp = display.newRect(Grp,V.Floor(i),size*.5+Theme.SliderTicksCenterOffset, 1,4)
					Tmp.strokeWidth  = 1
					Tmp:setStrokeColor(Theme.SliderTickStrokeColor [1],Theme.SliderTickStrokeColor [2],Theme.SliderTickStrokeColor [3])
					Tmp:setFillColor  (Theme.SliderTickFillColor[1],Theme.SliderTickFillColor[2],Theme.SliderTickFillColor[3])
				end
			end
		end

	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE WIDGET'S VALUE (AND KNOB)
	---------------------------------------------
	function Grp:_setValue(value)
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.BubbleTextColor
		local size      = Theme.widgetFrameSize
		local Knob      = self[6]
		local Bubble    = self[7]

		    if value  < Props.minValue then value = Props.minValue 
		elseif value  > Props.maxValue then value = Props.maxValue end
		Props.percent = V.Floor( ((value-Props.minValue) / (Props.maxValue-Props.minValue))*100 )
		Props.value   = value

		-- SLIDER
		if Props.vertical == true then 
			Knob.y = Props.reversed ~= nil and V.Floor((Props.Shape.h-size*.5) - (Props.percent/100) * (Props.Shape.h-size)) or V.Floor(size*.5 + (Props.percent/100) * (Props.Shape.h-size))
		else 
			Knob.x = Props.reversed ~= nil and V.Floor((Props.Shape.w-size*.5) - (Props.percent/100) * (Props.Shape.w-size)) or V.Floor(size*.5 + (Props.percent/100) * (Props.Shape.w-size)) 
		end

		-- CAPTION
		Bubble[4].text   = Props.textFormatter == nil and Props.value or Props.textFormatter(Props.value)
		Bubble[4].xScale = 1
		Bubble[4].yScale = 1
		Bubble[4]:setReferencePoint(display.CenterReferencePoint)
		Bubble[4].xScale = .5
		Bubble[4].yScale = .5
		Bubble[4].y      = size*.5 + Theme.TooltipTextYOffset
		Bubble[4]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		-- MIDDLE / LEFT / RIGHT CAPS
		Bubble[2].xScale =  (Bubble[4].width*.5) / Bubble[2].width
		Bubble[1].x      = -(Bubble[4].width*.25)
		Bubble[3].x      =  (Bubble[4].width*.25)
		-- POSITION BUBBLE
		if self.Props.vertical then Bubble.x = Knob.x+size*.5; Bubble.y = Knob.y-size*1.5
		                       else Bubble.x = Knob.x; Bubble.y = Knob.y-size end
		local minX, minY = self:contentToLocal(0,0)
		local maxX, maxY = self:contentToLocal(V.screenW,V.screenH)
		local bounds     = Bubble.contentBounds
		if Bubble.x < minX + Bubble.contentWidth*.5 then Bubble.x = minX + Bubble.contentWidth*.5 elseif Bubble.x > maxX - Bubble.contentWidth*.5 then Bubble.x = maxX - Bubble.contentWidth *.5 end
		if Bubble.y < minY then Bubble.y = Knob.y + size end
		-- ON CHANGE
		if self.oldValue ~= Props.value then
			self.oldValue = Props.value

			if Props.changeSound~= nil then audio.play(Theme.Sounds[Props.changeSound]) end
			if Props.onChange then Props.onChange(
				{
				Widget = self,
				Props  = Props,
				name   = Props.name,
				value  = Props.value,
				}) 
			end
		end
	end

	---------------------------------------------
	-- PRIVATE METHOD: PRESSED
	---------------------------------------------
	function Grp:_drawPressed( event )
		-- SHOW BUBBLE
		if Props.hideBubble ~= true then
			self.Trans = transition.to(self[7], {time = 250, alpha = 1})
		end
		-- POSITION KNOB
		if self.Props.vertical then Grp:_setPosV(event) else Grp:_setPosH(event) end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAGGED
	---------------------------------------------
	function Grp:_drawDragged( event ) 
		-- POSITION KNOB
		if self.Props.vertical then Grp:_setPosV(event) else Grp:_setPosH(event) end
	end

	---------------------------------------------
	-- PRIVATE METHOD: MOVE KNOB
	---------------------------------------------
	function Grp:_setPosH( event )
		local Props = self.Props
		local Theme = V.Themes[Props.theme]
		event.lx    = Props.reversed ~= nil and Props.Shape.w - event.lx - Theme.widgetFrameSize*.5 or event.lx - Theme.widgetFrameSize*.5
		-- STEP
		if Props.step then
			local stepSize = (Props.Shape.w-Theme.widgetFrameSize) / ((Props.maxValue-Props.minValue)/Props.step)
			event.lx       = V.Floor(event.lx / stepSize) * stepSize
		end
		-- GET VALUE & PERCENT, POSITION KNOB
		local percent = event.lx / (Props.Shape.w-Theme.widgetFrameSize)
		local value   = V.Floor (Props.minValue + (Props.maxValue-Props.minValue)*percent)
		self:_setValue  (value)
	end

	function Grp:_setPosV( event )
		local Props = self.Props
		local Theme = V.Themes[Props.theme]
		event.ly    = Props.reversed ~= nil and Props.Shape.h - event.ly - Theme.widgetFrameSize*.5 or event.ly - Theme.widgetFrameSize*.5
		-- STEP
		if Props.step then
			local stepSize = (Props.Shape.h-Theme.widgetFrameSize) / ((Props.maxValue-Props.minValue)/Props.step)
			event.ly       = V.Floor(event.ly / stepSize) * stepSize
		end
		-- GET VALUE & PERCENT, POSITION KNOB
		local percent = event.ly / (Props.Shape.h-Theme.widgetFrameSize)
		local value   = V.Floor (Props.minValue + (Props.maxValue-Props.minValue)*percent)
		self:_setValue  (value)
	end
	
	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased() 
		-- HIDE BUBBLE
		if self.Trans then transition.cancel(self.Trans) end
		self[7].alpha  = self.Props.alwaysShowBubble ~= true and 0 or 1
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewSlider(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A LIST
----------------------------------------------------------------
V.NewList = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewList(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewList(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount = V.widgetCount + 1
	Grp           = display.newGroup()
	Grp.typ       = V.TYPE_LIST
	Grp.Props     = Props

	Grp.Mask      = graphics.newMask(V.Themes[Props.theme].folderPath..V.Themes[Props.theme].maskImage)
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize * 5
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 3
	Props.maxW = 9999
	Props.maxH = 9999

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp
	
	Props.editMode = false

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup()
		self:insert(Tmp)
		-- BG
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_M)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		self:insert(Tmp)
		-- R
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_R)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		self:insert(Tmp)
		-- L
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		self:insert(Tmp)
		-- T
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_T)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		self:insert(Tmp)
		-- B
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_B)
		Tmp:setReferencePoint(display.BottomLeftReferencePoint)
		self:insert(Tmp)
		-- BR CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_BR)
		Tmp:setReferencePoint(display.BottomRightReferencePoint)
		self:insert(Tmp)
		-- TL CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_TL)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x = 0
		Tmp.y = 0
		self:insert(Tmp)
		-- TR CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_TR)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		self:insert(Tmp)
		-- BL CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_BL)
		Tmp:setReferencePoint(display.BottomLeftReferencePoint)
		self:insert(Tmp)
		-- GROUP FOR LINE ITEMS
		Tmp = display.newGroup()
		self:insert(Tmp)
		-- BACK BUTTON
		Tmp = V.newSprite(Theme.Set, Theme.Frame_List_BackButton)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x = 4
		Tmp.y = 0
		self:insert(Tmp)
		-- CAPTION		
		Tmp              = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale       = .5
		Tmp.yScale       = .5
		Grp:insert(Tmp)
		-- BOTTOM CAPTION		
		Tmp              = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale       = .5
		Tmp.yScale       = .5
		Tmp.isVisible    = false
		Grp:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update(animate)

		local i, Grp1, Grp2, Item, Tmp
		local Props       = self.Props
		local Theme       = V.Themes [Props.theme]
		local size        = Theme.widgetFrameSize
		local w           = Props.Shape.w
		local h           = Props.Shape.h
		local textColor   = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor
		self.alpha        = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale       = Props.scale
		self.yScale       = Props.scale

		if Props.list == nil then Props.list = {} end
		
		self.listMinY     = Props.caption ~= "" and -(((#Props.list*size-h)+size) + size) or -((#Props.list*size-h)+size)
		self.itemOffset   = 0
		self.lastOffset   = -1
		self.numItems     = Props.caption ~= "" and V.Floor(h / size)+1 or V.Floor(h / size)+2
		self.margin       = size*.25 + Theme.MarginX
		
		-- SAME LIST AS BEFORE?
		if Props.list == self.lastList then
			if self.listY < self.listMinY then 
				self.listY          = self.listMinY 
				if Props.selectedIndex > #Props.list then Props.selectedIndex = #Props.list end
			end
		-- SWITCHED TO ANOTHER LIST
		else self.listY = 0; Props.selectedIndex = 0 end

		self.lastList = Props.list

		-- COLORIZE PARTS?
		for i = 2,10 do self[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]
		
		-- CREATE NEW LIST
		self[11]:setMask(nil)
		self[11]:removeSelf()
		Grp1 = display.newGroup()
		self:insert(11,Grp1)
		Grp1:setMask(self.Mask)
		self:_adjustMask()

		Grp2 = display.newGroup()
		Grp1:insert(Grp2)
		for i = 1, self.numItems do
			Item  = display.newGroup()
			Grp2:insert(Item)
			Item.x = 0
			Item.y = (i-1)*size
			-- ITEM BG GRAPHIC
			Tmp = V.newSprite(Theme.Set, Theme.Frame_List_ItemBG)
			Tmp:setReferencePoint(display.TopLeftReferencePoint)
			Tmp.x            = 0
			Tmp.y            = 0
			Tmp.xScale       = w / Tmp.width
			Item:insert(Tmp)
			-- ITEM BG COLOR
			Tmp = display.newRect(0,0,w,size-1)
			Tmp.strokeWidth  = 0
			Item:insert(Tmp)
			-- ITEM CAPTION
			Tmp = display.newText("",0,0,Theme.WidgetFont,Props.fontSize*2)
			Item:insert(Tmp)
			-- RIGHT ICON
			Tmp = V.newSprite(Theme.SetIcons)
			Tmp:setReferencePoint(display.CenterReferencePoint)
			Tmp.xScale       = Theme.ListIconSize / Tmp.width
			Tmp.yScale       = Theme.ListIconSize / Tmp.height
			Tmp.x            = (w-self.margin) - Theme.ListIconSize * .5
			Tmp.y            = size*.5
			Item:insert(Tmp)
			-- LEFT ICON
			Tmp              = V.newSprite(Theme.SetIcons)
			Tmp:setReferencePoint(display.CenterReferencePoint)
			Tmp.xScale       = Theme.ListIconSize / Tmp.width
			Tmp.yScale       = Theme.ListIconSize / Tmp.height
			Tmp.x            = self.margin + Theme.ListIconSize * .5
			Tmp.y            = size*.5
			Item:insert(Tmp)
		end
		self:_arrangeList()
		
		-- ANIMATION?
		if animate then
			Grp2.x     = animate == "right" and -w or w
			Grp2.Trans = transition.to(Grp2, {time = 250, x = 0})
		end
		
		-- BG
		self[2].x       = size
		self[2].y       = size
		self[2].xScale  = (w-(size*2)) / self[2].width
		self[2].yScale  = (h-(size*2)) / self[2].height
		-- R
		self[3].x       = w
		self[3].y       = size
		self[3].yScale  = (h-(size*2)) / self[3].height
		-- L
		self[4].x       = 0
		self[4].y       = size
		self[4].yScale  = (h-(size*2)) / self[4].height
		-- T
		self[5].x       = size
		self[5].y       = 0
		self[5].xScale  = (w-(size*2)) / self[5].width
		-- B
		self[6].x       = size
		self[6].y       = h
		self[6].xScale  = (w-(size*2)) / self[6].width
		-- BR CORNER
		self[7].x = w; self[7].y = h
		-- TR CORNER
		self[9].x = w; self[9].y = 0
		-- BL CORNER
		self[10].x = 0; self[10].y = h
		-- CAPTION
		self[13].text = Props.caption
		self[13]:setTextColor(textColor[1],textColor[2],textColor[3])
		V._WrapGadgetText(self[13], w-size-8, Theme.WidgetFont, Props.fontSize)
		self[13].xScale = 1
		self[13].yScale = 1
		self[13]:setReferencePoint(display.CenterLeftReferencePoint)
		self[13].xScale = .5
		self[13].yScale = .5
		self[13].y      = size*.5 + Theme.WidgetTextYOffset
		self[13].x      = w*.5 - self[13].width*.25 -- CENTER
		-- BACK BUTTON?
		if Props.list.parentList ~= nil then
			self[12].isVisible = true
			self[12].alpha     = 0
			transition.to(self[12], {time = 250, alpha = 1 })
			if self[13].x < size+8 then transition.to(self[13], { time = 150, x = (w-4)-self[13].width*.5 }) end
		else
			self[12].isVisible = false
		end
		-- BOTTOM CAPTION
		self[14]:setTextColor(textColor[1],textColor[2],textColor[3])
	end

	---------------------------------------------
	-- PRIVATE METHOD: POSITION LIST, UPDATE ITEMS
	---------------------------------------------
	function Grp:_arrangeList()
		local Props     = self.Props; if Props == nil then return end
		local Theme     = V.Themes[Props.theme]
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.ListItemTextColor
		local size      = Theme.widgetFrameSize
		local Items     = self[11][1]
		local i, num, data, maxTextW
		
		-- POSITION LIST
		if self.listMinY >= 0 then self.listY = 0
		else
			if self.listY > 0 then self.listY = 0; self.speedY = 0 elseif self.listY < self.listMinY then self.listY = self.listMinY; self.speedY = 0 end
		end
		Items.y = Props.caption ~= "" and size + V.Floor(self.listY % -size) or V.Floor(self.listY % -size)
		
		-- UPDATE ITEMS
		self.itemOffset = (V.Floor(-self.listY / size))
		if self.lastOffset ~= self.itemOffset then
			self.lastOffset = self.itemOffset
			for i = 1,Items.numChildren do
				num      = i + self.itemOffset
				data     = Props.list[num]
				maxTextW = Props.Shape.w - 8

				-- NORMAL / SELECTED BACKGROUND?
				if num == Props.selectedIndex then
					 Items[i][2].isVisible = true
					 Items[i][2]:setFillColor(Theme.ListItemSelectedGradient)
				else Items[i][2].isVisible = false end

				-- IS EMPTY OR TEXT ITEM?
				if type(data) == "string" or data == nil then
					Items[i][3].text = data ~= nil and data or ""
					Items[i][3]:setTextColor(textColor[1],textColor[2],textColor[3],255)
					Items[i][4].isVisible = false
					Items[i][5].isVisible = false
				
				-- IS TABLE ITEM?
				elseif type(data) == "table" then
					-- CAPTION
					Items[i][3].text   = data.caption
					-- BG COLOR
					if num ~= Props.selectedIndex then
						Items[i][2].isVisible = true
						if data.bgColor ~= nil then 
							Items[i][2]:setFillColor(data.bgColor[1],data.bgColor[2],data.bgColor[3],64) 
						else
							Items[i][2]:setFillColor(Theme.color[1],Theme.color[2],Theme.color[3],64) 
						end
					end
					-- TEXT COLOR
					if data.textColor then 
						Items[i][3]:setTextColor(data.textColor[1],data.textColor[2],data.textColor[3],255) 
					else
						Items[i][3]:setTextColor(textColor[1],textColor[2],textColor[3],255) 
					end
					-- RIGHT ICON
					if data.iconR ~= nil and data.iconR > 0 then Items[i][4].isVisible = true; Items[i][4]:setFrame( data.iconR ); maxTextW = maxTextW - Theme.ListIconSize else Items[i][4].isVisible = false end
					-- LEFT ICON
					if data.iconL ~= nil and data.iconL > 0 then Items[i][5].isVisible = true; Items[i][5]:setFrame( data.iconL ); maxTextW = maxTextW - Theme.ListIconSize else Items[i][5].isVisible = false end
				end
				
				if Props.editMode and data then
					-- SHOW DELETE ICONS?
					if Props.allowDelete then Items[i][5].isVisible = true; Items[i][5]:setFrame( Theme.Icon_List_Delete ) end
					-- SHOW SORT ICONS?
					if Props.allowSort   then Items[i][4].isVisible = true; Items[i][4]:setFrame( Theme.Icon_List_Move ) end
				end
				
				-- POSITION TEXT
				V._WrapGadgetText(Items[i][3], maxTextW, Theme.WidgetFont, Props.fontSize)
				Items[i][3].xScale = 1
				Items[i][3].yScale = 1
				Items[i][3]:setReferencePoint(display.CenterLeftReferencePoint)
				Items[i][3].xScale = .5
				Items[i][3].yScale = .5
				Items[i][3].x      = Items[i][5].isVisible == false and self.margin or self.margin + Theme.ListIconSize + 4
				Items[i][3].y      = size *.5
			end
		end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed(event) 
		local Props = self.Props
		local Theme = V.Themes[Props.theme]
		local size  = Theme.widgetFrameSize
		-- BACK BUTTON PRESSED?
		if self[12].isVisible and event.lx < size and event.ly < size then
			self.backButtonPressed = true
			self[12]:setFrame( Theme.Frame_List_BackButtonDown )
			return
		-- BOTTOM BUTTON PRESSED?
		elseif Props.editMode == true and event.ly > Props.Shape.h - size then
			self.bottomButtonPressed = true
			self[6 ]:setFrame( Theme.Frame_List_B3 )
			self[7 ]:setFrame( Theme.Frame_List_BR3)
			self[10]:setFrame( Theme.Frame_List_BL3)
			return
		-- DEL ICON PRESSED?
		elseif Props.editMode and Props.allowDelete and event.lx < 8 + Theme.ListIconSize then
			self.delIconPressed = true
			local List,i = self[11][1]
			local index  = Props.caption ~= "" and V.Ceil(((event.ly-size)-self.listY) / size) or V.Ceil((event.ly-self.listY) / size)
			local item   = V.Ceil( (event.ly-List.y) / size)
			print("INDEX: "..index)
			print("ITEM:  "..item)
			local data   = Props.list[index]
			if data and data.selectable ~= false and data.deletable ~= false then
				for i = item+1, List.numChildren do
					transition.to (List[i], { time = 200, y = List[i].y - size })
				end
				transition.to (List[item], { time = 200, alpha = 0.999, onComplete = function() self:deleteItem(Props.list,index) end })
				return
			end
		-- SORT ICON PRESSED?
		--elseif Props.editMode and Props.allowSort and event.lx > Props.Shape.w - Theme.ListIconSize then
		--	local List = self[11][1]
		--	self.sortIconPressed = true
		--	self.DragItem        = List[V.Ceil( (event.ly-List.y) / size)]
		--	self.DragItem.sy     = self.DragItem.y            -- ORIGINAL Y-POS
		--	self.DragItem.oy     = event.ly - self.DragItem.y -- DRAG OFFSET
		end
		-- INIT DRAG
		if self.Timer ~= nil then timer.cancel(self.Timer); self.Timer = nil end
		self.speedY    = 0
		self.clickedX  = event.lx
		self.clickedY  = event.ly
		self.lastY     = event.ly
		self.currListY = self.listY
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW DRAGGED
	---------------------------------------------
	function Grp:_drawDragged(event) 
		-- BUTTON DOWN?
		if self.delIconPressed or self.backButtonPressed or self.bottomButtonPressed then return end
		-- ITEM DRAGGING?
		--if self.DragItem then
		--	self.DragItem.y = event.ly - self.DragItem.oy
		--	return
		--end
		
		self.listY  = self.currListY + (event.ly-self.clickedY)
		self.speedY = event.ly - self.lastY
		self.lastY  = event.ly
		self:_arrangeList()
	end
	
	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased(event) 
		local Props = self.Props
		local Theme = V.Themes[Props.theme]
		local size  = Theme.widgetFrameSize
		local Items = self[11][1]
		
		-- BACK BUTTON RELEASED?
		if self.backButtonPressed then
			self.backButtonPressed = false
			self[12]:setFrame( Theme.Frame_List_BackButton )
			if Props.onBackButton then Props.onBackButton(Props.list, Props.selectedIndex) end
			if Props.list.parentList ~= nil then 
				self:setList(Props.list.parentList, "right")
			end
			return
		
		-- BOTTOM BUTTON RELEASED?
		elseif self.bottomButtonPressed then
			self.bottomButtonPressed  = false
			self:editMode(false)
			return
			
		-- DEL ICON PRESSED?
		elseif self.delIconPressed then
			self.delIconPressed = false
			return

		-- SWIPE RIGHT -ENTER EDIT MODE?
		elseif (Props.allowDelete or Props.allowSort) and V.Abs(event.ly - self.clickedY) < size and event.lx - self.clickedX > size then 
			self:editMode(true)
			return
		
		else
			-- ITEM CLICKED?
			if Props.editMode == false and V.Abs(self.clickedX - event.lx) < 10 and V.Abs(self.clickedY - event.ly) < 10 then
				local index = Props.caption ~= "" and V.Ceil(((event.ly-size)-self.listY) / size) or V.Ceil((event.ly-self.listY) / size)
				if Props.list[index] and Props.list[index].selectable ~= false then
					Props.selectedIndex = index
					self.lastOffset     = -1
					self:_arrangeList()
					-- CHANGE TO CHILD LIST?
					-- if Props.list[index].childList ~= nil then 
					-- 	self:setList(Props.list[index].childList, "left")
					-- end
					-- ON SELECT LISTENER?
					if Props.selectSound ~= nil then audio.play(Theme.Sounds[Props.selectSound]) end
					if self.Props.onSelect then
						local EventData =
							{
							Widget = self,
							Props  = Props,
							name   = Props.name,
							List   = Props.list,
							Item   = Props.list[index],
							selectedIndex = Props.selectedIndex,
							} 
						local Timer = timer.performWithDelay(50,
							function(event)
									event.source.onSelect(event.source.EventData)
									event.source.EventData = nil
									event.source.onSelect  = nil
							end	,1)
						Timer.EventData = EventData
						Timer.onSelect  = self.Props.onSelect
					end
				end
				return
			end
		end
		
		-- SCROLLED - DRAG SLIDE-OUT
		self.Timer    = timer.performWithDelay(33,
			function(event)
				local Widget = event.source.Widget
				Widget.listY = Widget.listY + Widget.speedY
				Widget.speedY= Widget.speedY * .85
				Widget:_arrangeList()
				if V.Abs(Widget.speedY) < 0.1 then 
					event.source.Widget = nil
					timer.cancel(Widget.Timer) 
					Widget.Timer = nil
				end
			end	,0)
		self.Timer.Widget = self
	end

	---------------------------------------------
	-- PRIVATE METHOD: ADJUST MASK
	---------------------------------------------
	function Grp:_adjustMask()
		local Props = self.Props
		local Theme = V.Themes[Props.theme]
		local size  = Theme.widgetFrameSize
		self[11].maskScaleX = Props.Shape.w / Theme.maskImageSize
		self[11].maskX      = Props.Shape.w*.5
		if Props.caption == "" then
			self[11].maskScaleY = Props.editMode == true and (Props.Shape.h-size*.5-size*.25) / Theme.maskImageSize or Props.Shape.h / Theme.maskImageSize
			self[11].maskY      = Props.editMode == true and Props.Shape.h*.5 - size*.4 or Props.Shape.h*.5
		else
			self[11].maskScaleY = Props.editMode == true and (Props.Shape.h-size*2) / Theme.maskImageSize or (Props.Shape.h-size) / Theme.maskImageSize
			self[11].maskY      = Props.editMode == true and Props.Shape.h*.5 or Props.Shape.h*.5 + size*.45 
		end
	end
	
	---------------------------------------------
	-- PUBLIC METHODS: LISTS & ITEMS
	---------------------------------------------
	function Grp:setIndex(index)
		local Props = self.Props
		if index < 1 then index = 1 elseif index > #Props.list then index = #Props.list end
		if Props.list[index].selectable ~= false then
			Props.selectedIndex = index 
			self.lastOffset     = -1
			self:_arrangeList()
		end
	end

	function Grp:getIndex() return Props.selectedIndex end

	function Grp:setList(List, slideDirection)
		local Props = self.Props
		if Props.list == List then return end
		if Props.list == nil then print("!!! WIDGET ERROR: List:setList(): Specified list table does not exist."); return end
		-- CURRENT LIST IS EMPTY? NO ANIMATION
		-- if Props.list == self.emptyList then Props.list = List; self:_update(); return end
		-- CHANGE WITH ANIMATION
		local x = slideDirection == "left" and -Props.Shape.w or Props.Shape.w
		Props.list = List
		transition.to(self[11][1], {time = 250, x = x, onComplete = function() self:_update(slideDirection) end })
		transition.to(self[12]  , {time = 250, alpha = 0})
	end

	function Grp:getCurrList() return self.Props.list end

	function Grp:deleteItem(List, pos)
		local k,v
		if List == nil then print("!!! WIDGET ERROR: List:deleteItem(): Specified list table does not exist."); return end
		if List[pos] ~= nil then
			if type(List[pos]) == "table" then
				for k,v in pairs(List[pos]) do List[pos][k] = nil end
			end
			table.remove(List, pos)
			if self.Props.list == List then self:_update() end
		end
	end
	
	---------------------------------------------
	-- PUBLIC METHOD: ENABLE / DISABLE EDIT MODE
	---------------------------------------------
	function Grp:editMode(mode)
		local Props,i  = self.Props
		local Theme    = V.Themes[Props.theme]
		local size     = Theme.widgetFrameSize
		local List     = self[11][1]
		if Props.editMode == mode then return false end
		Props.editMode = mode == true and mode or false

		if mode == true then
			-- SHOW BOTTOM BUTTON
			self[6]:setFrame ( Theme.Frame_List_B2 )
			self[7]:setFrame ( Theme.Frame_List_BR2)
			self[10]:setFrame( Theme.Frame_List_BL2)
			-- BOTTOM CAPTION
			self[14].text      = Props.readyCaption
			V._WrapGadgetText (self[14], Props.Shape.w-size-8, Theme.WidgetFont, Props.fontSize)
			self[14].xScale    = 1
			self[14].yScale    = 1
			self[14]:setReferencePoint(display.CenterLeftReferencePoint)
			self[14].xScale    = .5
			self[14].yScale    = .5
			self[14].y         = (Props.Shape.h - size*.5) + Theme.WidgetTextYOffset
			self[14].x         = Props.Shape.w*.5 - self[14].width*.25 -- CENTER
			self[14].isVisible = true
		else
			self[6]:setFrame ( Theme.Frame_List_B )
			self[7]:setFrame ( Theme.Frame_List_BR)
			self[10]:setFrame( Theme.Frame_List_BL)
			self[14].isVisible   = false
		end
		-- ADJUST MASK
		self:_adjustMask()
		-- ANIMATE ICONS
		for i = 1, List.numChildren do
			if Props.allowSort == true then
				List[i][4].xScale, List[i][4].yScale = 0.001, 0.001
				transition.to(List[i][4], {time = 200, xScale = 1, yScale = 1})
			end
			if Props.allowDelete == true then
				List[i][5].xScale, List[i][5].yScale = 0.001, 0.001
				transition.to(List[i][5], {time = 200, xScale = Theme.ListIconSize / List[i][5].width, yScale = Theme.ListIconSize / List[i][5].height})
			end
		end
		self.lastOffset = -1
		self:_arrangeList()
	end

	---------------------------------------------
	-- PUBLIC METHOD: DESTROY
	---------------------------------------------
	function Grp:destroy() 
		self.setIndex      = nil
		self.getIndex      = nil
		self.getCurrList   = nil
		self.deleteItem    = nil
		self.editMode      = nil
		self._arrangeList  = nil
		self._adjustMask   = nil
		-- DELETE MASK
		self[11]:setMask (nil)
		self.Mask         = nil
		self.DragItem     = nil
		-- DELETE TIMER
		if self.Timer    ~= nil then timer.cancel(self.Timer); self.Timer = nil end
		-- DELETE LISTS
		local k,v
		self.Props.list   = nil
		self.lastList     = nil
		V._RemoveWidget(self.Props.name) 
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewList(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A WINDOW
----------------------------------------------------------------
V.NewWindow = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewWindow(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewWindow(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_WINDOW
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize * 3
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 3
	Props.maxW = 9999
	Props.maxH = 9999

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	Grp.Shadow  = display.newGroup()
	Grp:insert(Grp.Shadow)
	
	Grp.Parts   = display.newGroup()
	Grp.Parts:addEventListener("touch", V._OnWindowTouch )
	Grp:insert(Grp.Parts)

	Grp.Widgets = display.newGroup()
	Grp.Widgets.isContainer = true
	Grp:insert(Grp.Widgets)

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )
	

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local Parts = self.Parts
		local size  = Theme.widgetFrameSize

		while Parts.numChildren > 0 do self.Parts[1]:removeSelf() end

		-- BG
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_BG)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Parts:insert(Tmp)
		-- R
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_R)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Parts:insert(Tmp)
		-- L
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Parts:insert(Tmp)
		Tmp.x = 0
		-- T
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_T)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Parts:insert(Tmp)
		Tmp.y = 0
		-- B
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_B)
		Tmp:setReferencePoint(display.BottomLeftReferencePoint)
		Parts:insert(Tmp)
		-- BR CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_BR)
		Tmp:setReferencePoint(display.BottomRightReferencePoint)
		Parts:insert(Tmp)
		-- TL CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_TL)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Parts:insert(Tmp)
		Tmp.x = 0
		Tmp.y = 0
		-- TR CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_TR)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Parts:insert(Tmp)
		Tmp.y = 0
		-- BL CORNER
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_BL)
		Tmp:setReferencePoint(display.BottomLeftReferencePoint)
		Parts:insert(Tmp)
		Tmp.x = 0
		-- GROUP FOR GRADIENT SHADE
		Tmp = display.newGroup()
		Parts:insert(Tmp)
		-- CLOSE BUTTON?
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_CloseButton)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Tmp:addEventListener ("touch", V._OnWindowClose)
		Parts:insert(Tmp)
		Tmp.y = 0
		-- RESIZE BUTTON?
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Win_ResizeButton)
		Tmp:setReferencePoint(display.BottomRightReferencePoint)
		Tmp:addEventListener ("touch", V._OnWindowResize)
		Parts:insert(Tmp)
		-- ICON 
		Tmp = V.newSprite(Theme.SetIcons)
		Tmp:setReferencePoint(display.CenterReferencePoint)
		Parts:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WindowCaptionFont,Theme.WindowFontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		Parts:insert(Tmp)
		Tmp        = display.newText(" ",0,0,Theme.WindowCaptionFont,Theme.WindowFontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		Parts:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local Parts     = self.Parts
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		self.Widgets.y   = Theme.widgetFrameSize
		self.Parts.alpha = Theme.WindowFrameAlpha

		-- COLORIZE PARTS?
		if Props.color ~= nil then 
			for i = 1,9 do Parts[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end
		end

		-- ADD SHADOW?
		if self.Shadow.numChildren > 0 then self.Shadow[1]:removeSelf() end
		if Props.shadow == true then
			Tmp = display.newRoundedRect(Theme.WindowShadowOffset,Theme.WindowShadowOffset,w,h, Theme.WindowShadowCornerSize)
			Tmp:setReferencePoint(display.TopLeftReferencePoint)
			Tmp.strokeWidth = 0
			Tmp:setFillColor  (0,0,0,Theme.WindowShadowAlpha*255)
			self.Shadow:insert(Tmp)
		end

		-- BG
		Parts[1].x       = size
		Parts[1].y       = size
		Parts[1].xScale  = (w-(size*2)) / Parts[1].width
		Parts[1].yScale  = (h-(size*2)) / Parts[1].height
		-- R
		Parts[2].x       = w
		Parts[2].y       = size
		Parts[2].yScale  = (h-(size*2)) / Parts[2].height
		-- L
		Parts[3].y       = size
		Parts[3].yScale  = (h-(size*2)) / Parts[3].height
		-- T
		Parts[4].x       = size
		Parts[4].xScale  = (w-(size*2)) / Parts[4].width
		-- B
		Parts[5].x       = size
		Parts[5].y       = h
		Parts[5].xScale  = (w-(size*2)) / Parts[5].width
		-- BR CORNER
		Parts[6].x       = w
		Parts[6].y       = h
		-- TR CORNER
		Parts[8].x       = w
		-- BL CORNER
		Parts[9].y       = h
		-- WINDOW SHADE
		if Parts[10].numChildren > 0 then Parts[10][1]:removeSelf() end
		if Props.gradientColor1 ~= nil and Props.gradientColor2 ~= nil then
			Tmp = display.newRect(Parts[10],Theme.WindowGradientMargin,Theme.WindowGradientMargin,w-Theme.WindowGradientMargin*2,h-Theme.WindowGradientMargin*2)
			Tmp:setReferencePoint(display.TopLeftReferencePoint)
			Tmp.strokeWidth  = 0
			Tmp:setStrokeColor(0,0,0,0)
			Tmp:setFillColor  ( graphics.newGradient(Props.gradientColor1, Props.gradientColor2, Props.gradientDirection ) )
		end
		-- CLOSE BUTTON
		Parts[11].x         = w
		Parts[11].isVisible = Props.closeButton == true and true or false
		-- RESIZE BUTTON
		Parts[12].x         = w
		Parts[12].y         = h
		Parts[12].isVisible = Props.resizable == true and true or false
		-- ICON 
		Parts[13].xScale    = Theme.WindowIconSize / Parts[13].width
		Parts[13].yScale    = Theme.WindowIconSize / Parts[13].height
		Parts[13].x         = size*.5 + Theme.WindowIconOffsetX
		Parts[13].y         = size*.5 + Theme.WindowCaptionOffsetY
		Parts[13].isVisible = Props.icon > 0 and true or false
		if Props.icon     > 0 then Parts[13]:setFrame( Props.icon ) end
		-- CAPTION
		Parts[15].text   = Props.caption
		Parts[15]:setTextColor(Theme.WindowCaptionColor1[1],Theme.WindowCaptionColor1[2],Theme.WindowCaptionColor1[3],255)  
		V._WrapGadgetText(Parts[15], w-(size*2)-8, Theme.WindowCaptionFont, Props.fontSize)
		Parts[15].xScale = 1
		Parts[15].yScale = 1
		Parts[15]:setReferencePoint(display.CenterReferencePoint)
		Parts[15].xScale = .5
		Parts[15].yScale = .5
		Parts[15].x      = w*.5
		Parts[15].y      = size*.5 + Theme.WindowCaptionOffsetY
		
		Parts[14].text   = Parts[15].text
		Parts[14]:setTextColor(Theme.WindowCaptionColor2[1],Theme.WindowCaptionColor2[2],Theme.WindowCaptionColor2[3],255)  
		Parts[14].xScale = 1
		Parts[14].yScale = 1
		Parts[14]:setReferencePoint(display.CenterReferencePoint)
		Parts[14].xScale = .5
		Parts[14].yScale = .5
		-- TEXT ALIGN
		if Props.caption ~= "" then 
			    if Props.textAlign == "left"   then 
			    	local iw = Parts[13].isVisible == true and Theme.WindowIconSize + 4 or 0 
			    	Parts[15].x = 4 + iw + Parts[15].width*.25
			elseif Props.textAlign == "right"  then 
			   	local iw = Parts[11].isVisible == true and size + 4 or 0 
				Parts[15].x = w-4 - iw - Parts[15].width*.25 
			end
		end
		Parts[14].x = Parts[15].x + 1
		Parts[14].y = Parts[15].y + 1
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed()
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased()
	end

	---------------------------------------------
	-- PRIVATE METHOD: KEEP INSIDE DRAG AREA
	---------------------------------------------
	function Grp:_keepInsideArea()
		local minX,minY,maxX,maxY
		local Props = self.Props
		local w     = self.Props.Shape.w*Props.scale
		local h     = self.Props.Shape.h*Props.scale
		if Props.dragArea ~= "auto" then
			minX = Props.dragArea[1] -- DRAG AREA X
			minY = Props.dragArea[2] -- DRAG AREA Y
			maxX = Props.dragArea[3] -- DRAG AREA W
			maxY = Props.dragArea[4] -- DRAG AREA H
		else
			minX = 0
			minY = 0
			maxX = V.screenW
			maxY = V.screenH
			if h > V.screenH then minY = -(h - V.screenH); maxY = h + V.Abs(minY) end
			if w > V.screenW then minX = -(w - V.screenW); maxX = w + V.Abs(minX) end
		end
		
		if self.x < minX then self.x = minX elseif self.x + w > minX+maxX then self.x = (minX+maxX) - w end
		if self.y < minY then self.y = minY elseif self.y + h > minY+maxY then self.y = (minY+maxY) - h end
	end
	
	---------------------------------------------
	-- PUBLIC METHOD: DESTROY
	---------------------------------------------
	function Grp:destroy()
		while self.Widgets.numChildren > 0 do self.Widgets[1]:destroy() end
		self.Parts:removeEventListener("touch", V._OnWindowTouch )
		self.Widgets:removeSelf(); self.Widgets = nil
		self.Shadow:removeSelf (); self.Shadow  = nil
		self.Parts:removeSelf  (); self.Parts   = nil
		if self.DragTimer ~= nil then timer.cancel(self.DragTimer); self.DragTimer.Win = nil; self.DragTimer = nil end
		V._RemoveWidget(self.Props.name) 
		collectgarbage("collect")
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewWindow(): Created new window '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE A LABEL
----------------------------------------------------------------
V.NewLabel = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewLabel(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewLabel(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_LABEL
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Themes[Props.theme].widgetFrameSize * 1
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 1
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	-- Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)
		-- ICON 
		Tmp = V.newSprite(Theme.SetIcons)
		Tmp:setReferencePoint(display.CenterReferencePoint)
		Tmp.xScale = Theme.ButtonIconSize / Tmp.width
		Tmp.yScale = Theme.ButtonIconSize / Tmp.height
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.WidgetTextColor

		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]

		-- CAPTION
		self[2].text   = Props.caption
		self[2]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		V._WrapGadgetText(self[2], w-8, Theme.WidgetFont, Props.fontSize)
		self[2].xScale = 1
		self[2].yScale = 1
		self[2]:setReferencePoint(display.CenterLeftReferencePoint)
		self[2].xScale = .5
		self[2].yScale = .5
		self[2].y      = size*.5 + Theme.WidgetTextYOffset
		self[2].x      = Theme.MarginX; if Props.textAlign == "right" then self[2].x = Props.Shape.w - self[2].width*.5 - Theme.MarginX elseif Props.textAlign == "center" then self[2].x = Props.Shape.w*.5 -  self[2].width*.25 end
		-- ICON 
		local halfW = (self[3].width*self[3].xScale)*.5
		self[3]:setFrame( Props.icon > 0 and Props.icon or 1 )
		self[3].isVisible    = Props.icon > 0 and true or false
		self[3].x = Theme.MarginX + halfW; if Props.textAlign == "right" then self[3].x = Props.Shape.w elseif Props.textAlign == "center" then self[3].x = Props.Shape.w*.5 end
		self[3].y = size*.5

		if Props.icon > 0 and Props.caption ~= "" then 
			    if Props.textAlign == "left"   then self[2].x = self[3].x + halfW + 4 
			elseif Props.textAlign == "center" then self[2].x = self[2].x + halfW + 2; self[3].x = self[2].x - halfW - 4 
			elseif Props.textAlign == "right"  then self[3].x = Props.Shape.w - halfW - Theme.MarginX; self[2].x = self[2].x - halfW*2 - 8 end
		end
		
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed()
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased()
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewLabel(): Created new label '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: CREATE AN INPUT FIELD
----------------------------------------------------------------
V.NewInput = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end
	if V.Themes [Props.theme] == nil then print("!!! WIDGET ERROR: NewInput(): Invalid theme specified."); return end
	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewInput(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	local Grp, Tmp

	V.widgetCount         = V.widgetCount + 1
	Grp                   = display.newGroup()
	Grp.typ               = V.TYPE_INPUT
	Grp.Props             = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW = V.Round(V.Themes[Props.theme].widgetFrameSize * 2.1)
	Props.minH = V.Themes[Props.theme].widgetFrameSize * 1
	Props.maxW = 9999
	Props.maxH = Props.minH

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp   = display.newGroup(); self:insert(Tmp)
		-- LEFT CAP
		Tmp   = V.newSprite(Theme.Set, Theme.Frame_Input_L)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x = 0
		Tmp.y = 0
		self:insert(Tmp)
		-- MIDDLE
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Input_M)
		Tmp:setReferencePoint(display.TopLeftReferencePoint)
		Tmp.x = size
		Tmp.y = 0
		self:insert(Tmp)
		-- RIGHT CAP
		Tmp = V.newSprite(Theme.Set, Theme.Frame_Input_R)
		Tmp:setReferencePoint(display.TopRightReferencePoint)
		Tmp.y = 0
		self:insert(Tmp)
		-- CAPTION
		Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
		Tmp.xScale = .5
		Tmp.yScale = .5
		self:insert(Tmp)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props     = self.Props
		local Theme     = V.Themes [Props.theme]
		local textColor = Props.textColor ~= nil and Props.textColor or Theme.InputTextColor
		local size      = Theme.widgetFrameSize
		local w         = Props.Shape.w
		local h         = Props.Shape.h

		self.alpha      = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale     = Props.scale
		self.yScale     = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil then 
			for i = 2, 4 do self[i]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end
		end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]

		-- MIDDLE
		self[3].xScale = (w-(size*2)) / self[3].width
		-- RIGHT CAP
		self[4].x      = w
		-- CAPTION
		if Props.isSecure == true then
			self[5].text = ""
			for i = 1, Props.caption:len() do self[5].text = self[5].text .. "*" end
		else
			self[5].text   = Props.caption
		end
		self[5]:setTextColor(textColor[1],textColor[2],textColor[3],255)  
		V._WrapGadgetText(self[5], w-size-4, Theme.WidgetFont, Props.fontSize)
		self[5].xScale = 1
		self[5].yScale = 1
		self[5]:setReferencePoint(display.CenterLeftReferencePoint)
		self[5].xScale = .5
		self[5].yScale = .5
		self[5].y      = size*.5
		self[5].x      = Theme.InputMarginX
		
		-- IS CURRENTLY IN INPUT MODE? UPDATE NATIVE TEXT BOX THEN AS WELL
		if V.Input ~= nil and V.Input.MyObject == self then V.Input.Txt.text = Props.caption end
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW PRESSED
	---------------------------------------------
	function Grp:_drawPressed()
	end

	---------------------------------------------
	-- PRIVATE METHOD: DRAW RELEASED
	---------------------------------------------
	function Grp:_drawReleased()
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewInput(): Created new input field '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: ADD AN IMAGE OBJECT
----------------------------------------------------------------
V.NewImage = function (ImgObj, Props)

	if V.Widgets[Props.name ] ~= nil then print("!!! WIDGET ERROR: NewImage(): Widget name '"..Props.name.."' is already in use. Try a unique one."); return end

	-- APPLY DEFAULT THEME?
	if Props.theme == nil then
		local k,v
		for k,v in pairs(V.Themes) do Props.theme = k; break end
		if Props.theme == nil then print("!!! WIDGET ERROR: NewImage(): No themes loaded. Load at least one theme."); return end
	end
	
	Props.ImgObj = ImgObj

	local Grp, Tmp

	V.widgetCount = V.widgetCount + 1
	Grp           = display.newGroup()
	Grp.typ       = V.TYPE_IMAGE
	Grp.Props     = Props
	
	-- ADD & VERIFY PROPS, SET SHAPE AND PARENT
	Props.minW    = 16
	Props.minH    = 16
	Props.maxW    = 9999
	Props.maxH    = 9999

	V._CheckProps        (Grp)
	V._ApplyWidgetMethods(Grp)
	V.Widgets[Props.name] = Grp

	-- WIDGET TOUCH LISTENER
	Grp:addEventListener("touch", V._OnWidgetTouch )

	---------------------------------------------
	-- PRIVATE METHOD: CREATE PARTS
	---------------------------------------------
	function Grp:_create()
		local Tmp
		local Props = self.Props
		local Theme = V.Themes [Props.theme]
		local size  = Theme.widgetFrameSize

		-- REMOVE IMAGE FROM GROUP
		display.getCurrentStage():insert(Props.ImgObj)

		while self.numChildren > 0 do self[1]:removeSelf() end

		-- BACKGROUND & BORDER
		Tmp = display.newGroup(); self:insert(Tmp)

		-- PLACE IMAGE IN GROUP
		self:insert(Props.ImgObj)

		self:_update()
	end

	---------------------------------------------
	-- PRIVATE METHOD: UPDATE SHAPE
	---------------------------------------------
	function Grp:_update()

		local i
		local Props    = self.Props
		local Theme    = V.Themes [Props.theme]
		local size     = Theme.widgetFrameSize
		local w        = Props.Shape.w
		local h        = Props.Shape.h
		self.alpha     = Props.enabled == true and Props.alpha or Props.alpha * Theme.WidgetDisabledAlpha
		self.xScale    = Props.scale
		self.yScale    = Props.scale

		-- COLORIZE PARTS?
		if Props.color ~= nil and self[2].setFillColor then self[2]:setFillColor(Props.color[1],Props.color[2],Props.color[3],255) end

		-- BACKGROUND & BORDER?
		V._AddBorder(self) -- self[1]

		-- IMAGE
		local Img  = Props.ImgObj
		Img:setReferencePoint(display.TopLeftReferencePoint)
		Img.x      = 0
		Img.y      = 0
		Img.xScale = Props.Shape.w / Img.width
		Img.yScale = Props.Shape.h / Img.height
	end

	---------------------------------------------
	-- PRIVATE METHODS: PRESSED / DRAGGED / RELEASED
	---------------------------------------------
	function Grp:_drawPressed ( event ) end
	function Grp:_drawDragged ( event ) end
	function Grp:_drawReleased( event ) end

	---------------------------------------------
	-- PUBLIC METHOD: DESTROY
	---------------------------------------------
	function Grp:destroy(keepImage) 
		if keepImage ~= true then 
			self.Props.ImgObj:removeSelf() 
		else
			display.getCurrentStage():insert(self.Props.ImgObj)
		end
		self.Props.ImgObj = nil
		V._RemoveWidget(self.Props.name) 
	end

	-- CREATE & UPDATE PARTS
	Grp:_create ()

	V.print("--> Widgets.NewImage(): Created new widget '"..Props.name.."'.")

	return Grp
end


----------------------------------------------------------------
-- PUBLIC: ALERT WINDOW
----------------------------------------------------------------
V.Confirm = function (Props)

	if Props.theme == nil then Props.theme = V.defaultTheme end

	local i, Grp, Win, Tmp
	local Theme     = V.Themes[Props.theme]; if Theme == nil then print("!!! Widgets.Alert(): Specified theme does not exist."); return end
	local physicalW = math.round( (V.screenW - display.screenOriginX*2) )
	local physicalH = math.round( (V.screenH - display.screenOriginY*2) )

	V._RemoveInput()

	if Props.modal  == true then
		if V.Fader == nil then
			V.Fader = display.newRect(display.screenOriginX,display.screenOriginY,physicalW,physicalH)
			V.Fader:setFillColor (0,0,0,128)
			V.Fader.strokeWidth = 0
			V.Fader.alpha       = 0
			V.Fader:addEventListener("touch", function() V._RemoveInput(); return true end)
		end
		transition.to (V.Fader, {time = 750, alpha = 1.0})
		V.numModals = V.numModals + 1
	end

	Grp         = display.newGroup()
	Grp.x       = display.screenOriginX
	Grp.y       = display.screenOriginY
	Grp.bounds  = {0,0,physicalW,physicalH} -- MINX,MINY,WIDTH,HEIGHT INSIDE GROUP
	Grp.winName = "AlertWin"..V.widgetCount; V.widgetCount = V.widgetCount + 1

	Win = V.NewWindow(
		{
		name            = Grp.winName,
		x               = "center",
		y               = "center",
		scale           = Props.scale       ~= nil and Props.scale or 1.0,
		parentGroup     = Grp,
		width           = Props.width       ~= nil and Props.width or "35%",
		minHeight       = 40,
		height          = "auto",
		theme           = Props.theme,
		caption         = Props.title       ~= nil and Props.title or "ALERT",
		textAlign       = "center",
		alpha           = Props.alpha       ~= nil and Props.alpha or 1.0,
		icon            = Props.icon        ~= nil and Props.icon or 0,
		margin          = Props.margin      ~= nil and Props.margin or 8,
		shadow          = Props.shadow      ~= nil and Props.shadow or true,
		dragX           = Props.dragX       ~= nil and Props.dragX or false,
		dragY           = Props.dragY       ~= nil and Props.dragY or false,
		closeButton     = Props.closeButton ~= nil and Props.closeButton or false,
		onClose         = Props.onClose,
		} )

	Tmp = V.NewText( 
		{
		x                 = "center",
		y                 = "auto",
		width             = "100%",
		height            = "auto",
		parentGroup       = Grp.winName,
		theme             = Props.theme,
		caption           = Props.caption,
		textAlign         = "center",
		} )

	local spacing     = 8
	local winW        = Win.Props.Shape.w - Win.Props.margin*2
	local butW        = (winW / #Props.buttons)
	local butX        = Win.Props.margin + (winW - #Props.buttons * butW) / 2
	local pressFunc   = Props.onPress   ~= nil and Props.onPress   or function() end
	local releaseFunc = Props.onRelease ~= nil and Props.onRelease or function() end

	for i = 1, #Props.buttons do
		local topMargin = i == 1 and 10 or 0
		Tmp = V.NewButton(
			{
			x               = butX + (i-1)*butW,
			y               = "auto",
			width           = butW,
			textAlign       = "center",
			theme           = Props.theme,
			parentGroup     = Grp.winName,
			caption         = Props.buttons[i].caption,
			icon            = Props.buttons[i].icon,
			topMargin       = topMargin,
			myNumber        = i,
			onPress         = function(event) event.button = event.Props.myNumber; pressFunc  (event) end,
			onRelease       = function(event) event.button = event.Props.myNumber; releaseFunc(event); V.Widgets[event.Props.myWindow].parent:destroy() end, 
			} )
	end
	Win:layout(true)

	-- PLACE FADER ON TOP OF EVERYTHING, BUT BELOW MODAL WINDOWS
	if V.Fader then display.getCurrentStage():insert(display.getCurrentStage().numChildren-V.numModals, V.Fader) end

	---------------------------------------------
	-- PUBLIC METHOD: DESTROY PROGRAMMATICALLY
	---------------------------------------------
	function Grp:destroy()
		V.numModals = V.numModals - 1
		if V.numModals == 0 then V.Fader:removeSelf(); V.Fader = nil end
		V.GetHandle(self.winName):destroy()
		self:removeSelf()
	end

	V.print("--> Widgets.Confirm(): Created dialog window with "..#Props.buttons.." buttons.")
	
	return Grp
end

return V
