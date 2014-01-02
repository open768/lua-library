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
	
	if not Props.dontChangePos then
		V._SetPos       (Widget)
	end
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
	cDebug:print(DEBUG__DEBUG, "V._SetWidgetParent");

	local Props = Widget.Props
	local name  = ""; if Props ~= nil and Props.name ~= nil then name = Props.name end

	Props.myWindow = ""

	-- SAME PARENT AS BEFORE?
	if Widget.parent == newParent or (Widget.parent.parent ~= nil and Widget.parent.parent.Props ~= nil and Widget.parent.parent == newParent) then 
		if Props.zindex > 0 then Widget.parent:insert(Props.zindex,Widget) end
		return newParent 
	end
	
	-- SGV
	if Props.dontChangeParent then 
		cDebug:print(DEBUG__DEBUG, "not changing parent");
		return Widget.parent 
	end						--SV
	

	-- NO PARENT SPECIFIED? SET TO STAGE!
	if newParent == nil then 
		cDebug:print(DEBUG__DEBUG, "new parent is stage");
		newParent = V.Stage 
	end

	-- PARENT IS ANOTHER WIDGET?
	if type(newParent) == "string" then
		cDebug:print(DEBUG__DEBUG, "new parent is a string ",newParent);

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
	cDebug:print(DEBUG__DEBUG, "_OnWidgetTouch");

	local i,v
	local Obj   = event.target
	local Props = Obj.Props
	local Theme = V.Themes [Props.theme]
	local name  = Props.name
	cDebug:print(DEBUG__DEBUG, "widget=",name);
	
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
		if event.phase == "began" then 
			cDebug:print(DEBUG__DEBUG, "V._RemoveInput() 1")
			V._RemoveInput() 
		end 
		return true 
	end

	-- WIDGET OR WINDOW DISABLED?
	if Props.enabled == false or (Props.myWindow ~= "" and V.Widgets[Props.myWindow].Props.enabled == false) then
		cDebug:print(DEBUG__DEBUG, "window or widget disabled")
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
		if V.Widgets[name] == nil or (V.Widgets[name] and (Props.enabled == false or (Props.myWindow ~= "" and V.Widgets[Props.myWindow] and V.Widgets[Props.myWindow].Props.enabled == false))) then Obj.isFocus = false; V.Stage:setFocus( nil ); 
			return true 
		end
		-- INPUT TEXT?
		if Obj.typ == V.TYPE_INPUT then
			if Props.disableInput ~= true then
				if V.Input == nil then V._CreateInput(Obj) 	end
				if not utility.isSimulator() then
					native.setKeyboardFocus(V.Input.Txt)
				end
			end
		else
			cDebug:print(DEBUG__DEBUG, "V._RemoveInput() 2")
			V._RemoveInput() 
		end

	elseif Obj.isFocus then
		cDebug:print(DEBUG__DEBUG, "obj is focus");
		-- INSIDE WIDGET?
		if ex > 0 and ex < Props.Shape.w and ey > 0 and ey < Props.Shape.h then 
			EventData.inside = true 
			cDebug:print(DEBUG__DEBUG, "inside");
		else 
			EventData.inside = false 
			cDebug:print(DEBUG__DEBUG, "not inside");
		end

		-- DRAG
		if event.phase == "moved" then
			cDebug:print(DEBUG__DEBUG, "phase =moved");
			Obj.inside            = EventData.inside
			if Obj._drawDragged  then Obj:_drawDragged( EventData ) end
			EventData.value       = Props.value
			EventData.toggleState = Props.toggleState
			if Props.onDrag      then Props.onDrag    ( EventData ) end 

		-- RELEASE
		elseif event.phase == "ended" or event.phase == "cancelled" then
			cDebug:print(DEBUG__DEBUG, "phase = ended or cancelled");
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


local function onfaderTouch()
	cDebug:print(DEBUG__DEBUG, "onfaderTouch");
	V._RemoveInput(); 
	return true
end
local function onfaderTap()
	cDebug:print(DEBUG__DEBUG, "onfaderTap");
	V._RemoveInput(); 
	return true
end

----------------------------------------------------------------
-- PRIVATE: INPUT TEXT FUNCTIONS
----------------------------------------------------------------
V._CreateInput = function(Widget)
	cDebug:print(DEBUG__DEBUG, "_CreateInput");
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
	local boxmargin = 50
	local physicalW = math.round( (V.screenW - display.screenOriginX*2) )
	local physicalH = math.round( (V.screenH - display.screenOriginY*2) )
	
	cDebug:print(DEBUG__DEBUG, "scale =",scale);

	V.Input           = {}
	V.Input.MyObject  = Widget
	V.Input.oText     = Widget.Props.caption

	if V.Fader == nil then
	-- MODAL BG
		V.Fader = display.newRect(display.screenOriginX,display.screenOriginY,physicalW,physicalH)
		-- V.Fader:setFillColor (0,0,0,128)		
		V.Fader:setFillColor (0,0,0,Props.faderFill)		--SGV
		V.Fader.strokeWidth = 0
		V.Fader.alpha       = 0
		V.Fader:addEventListener("touch", onfaderTouch)
		V.Fader:addEventListener("tap", onfaderTap)
	end
	transition.to (V.Fader, {time = 750, alpha = 1.0})
	V.numModals = V.numModals + 1

	-- some calculations
	local ntfw, ntfh				--sv
	ntfw=w-margin*2					--sv
	ntfh=Props.fontSize *4		--sv
	
	-- BORDER
	Tmp              = display.newRoundedRect(0,0,w,ntfh+margin*2, 8)
	Tmp:setReferencePoint(display.TopCentreReferencePoint)	
	Tmp.x            = V.screenW/2
	Tmp.y            = 100
	Tmp.strokeWidth  = 2
	Tmp:setFillColor  (0,0,0,150)
	Tmp:setStrokeColor(255,255,255,255)
	V.Input.Border   = Tmp
		
	-- QUIT CAPTION
	V.Input.Border:setReferencePoint(display.BottomCentreReferencePoint)	
	Tmp        = display.newText(" ",0,0,Theme.WidgetFont,Props.fontSize*2)
	Tmp:setReferencePoint(display.TopCentreReferencePoint)	
	Tmp.xScale = .5 * scale
	Tmp.yScale = .5 * scale
	Tmp.x      = V.Input.Border.x
	Tmp.y      = V.Input.Border.y + 20
	Tmp.text   = Props.quitCaption
	V.Input.QuitTxt = Tmp
	
	-- INPUT TEXT
	V.Input.Border:setReferencePoint(display.CenterReferencePoint)	
	if utility.isSimulator() then --SV
		Tmp = display.newText("Sorry textinput not supported on simulator", 0,0,ntfw,ntfh, Theme.WidgetFont,Props.fontSize-5) -- SV
		Tmp:setReferencePoint(display.CenterReferencePoint)	
		Tmp.x = V.Input.Border.x
		Tmp.y = V.Input.Border.y
	else  --SV
		--Tmp = native.newTextField(0,0,w-margin*2,(size+4)*scale) 
		Tmp = native.newTextField(V.Input.Border.x-ntfw/2,V.Input.Border.y-ntfh/2,ntfw,ntfh) --sv
		Tmp:addEventListener("userInput", V._OnInput)
		--Tmp.x            = V.screenW * .5
		--Tmp.x            = V.screenW 
		--Tmp.y            = y
		Tmp.text         = Props.caption
		Tmp.size         = Props.fontSize
		Tmp.isSecure     = Props.isSecure  ~= nil and Props.isSecure  or false
		Tmp.inputType    = Props.inputType ~= nil and Props.inputType or "default"
		Tmp.isEditable   = true
		Tmp:setTextColor(0,0,0,255)  
		native.setKeyboardFocus(V.Input.Txt)
	end
	V.Input.Txt      = Tmp
	
	if Widget.Props.onFocus then Widget.Props.onFocus(
		{
		Widget = Widget,
		Props  = Widget.Props,
		name   = Widget.Props.name,
		value  = Widget.Props.caption,
		}) end
	

end

V._OnInput = function(event)
	--if V.Input == nil then return end
	local O     = V.Input.MyObject
	local Props = O.Props
	local Theme = V.Themes[Props.theme]

	O:set("caption", V.Input.Txt.text)
	if event.phase == "editing" then 
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
	cDebug:print(DEBUG__DEBUG, "_RemoveInput ",tostring(restore))
	
	if V.Input ~= nil then
		local O   = V.Input.MyObject
		local txt = V.Input.Txt.text
		if (txt == "" and O.Props.notEmpty == true) or restore == true then txt = V.Input.oText end
		
		V.Input.MyObject:set("caption", txt)  --SV bug is here
		
		if O.Props.onBlur then O.Props.onBlur(
			{
			Widget = O,
			Props  = O.Props,
			name   = O.Props.name,
			value  = txt,
			}) end
		
		--V.Input.Txt:removeSelf()
		--V.Input.QuitTxt:removeSelf()
		--V.Input.Border:removeSelf()
		if V.Input.Txt then V.Input.Txt:removeSelf() end -- sv
		if V.Input.QuitTxt then V.Input.QuitTxt:removeSelf() end --sv
		if V.Input.Border then V.Input.Border:removeSelf() end --sv
		
		
		V.Input.Border   = nil
		V.Input.MyObject = nil
		V.Input.Txt      = nil
		V.Input.QuitTxt  = nil
		V.Input          = nil
		if not utility.isSimulator() then
			native.setKeyboardFocus(nil)
		end

		-- REMOVE MODAL BG?
		V.numModals = V.numModals - 1
		if V.numModals == 0 then 
			cDebug:print(DEBUG__DEBUG, "_Removing Modal BG")
			V.Fader:removeSelf()
			V.Fader = nil 
		end
	end
	
	return false
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
	
	cDebug:print(DEBUG__DEBUG, "V.Set");
	-- SINGLE PROPERTY OR LIST OF PROPERTIES?
	if type(A) == "string" then list[A] = B else list = A end
	
	-- SET PROPERTIES
	for i,v in pairs(list) do Widget.Props[i] = v; if i == "theme" then create = true end end

	V._CheckProps(Widget)

	-- NEED TO RE-CREATE GRAPHICS?
	if create == true then Widget:_create() else Widget:_update() end  -- sv 

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
-- PUBLIC: CREATE A MULTILINE TEXT
----------------------------------------------------------------
V.NewText = function (Props)
	cDebug:print(DEBUG__DEBUG, "NewText");

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
				brk = lines[i]:find('[ %-%;,]', pos, false)
				if brk == nil then brk = #lines[i] end
				
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
	if not Props.faderFill  then Props.faderFill = 128 end		--SV

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

		cDebug:print(DEBUG__DEBUG, "NewInput _create");
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

		cDebug:print(DEBUG__DEBUG, "NewInput _update");
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



return V
