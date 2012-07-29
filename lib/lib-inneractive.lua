--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
require("inc.lib.lib-utility")
require("inc.lib.lib-http")
require("inc.lib.lib-events")
require("inc.3lib.lib_xmlparser")
require("inc.lib.lib-settings")
require "inc.lib.lib-class"

local cid_settings_key = "inner_cid"

--########################################################################
--#
--########################################################################
cIaAdData = {
	clickUrl = nil,
	imageUrl = nil,
	CID=nil,
	className="cIaAdData"
}
function cIaAdData:create()
	return cClass.createInstance(self)
end

--########################################################################
--#
--########################################################################
cInnerActive = {
	applicationID= "not set",
	adBorder=0,
	fullScreenAd = nil,
	adGroup = nil,
	adData = nil,
	remoteImageFile="adfile",
	baseUrl="http://m2m1.inner-active.com/simpleM2M/",
	testUrl = "http://ia-test.inner-active.mobi:8080/simpleM2M/",
	eventName="onImageLoaded",
	forceUserAgent = "Mozilla/5.0 (Linux; U; Android 1.5; en-us; ADR6200 Build/CUPCAKE) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1",
	version = "Sm2m-1.5.3"
}
cSettings:load()
cLibEvents.instrument(cInnerActive)

-- *********************************************************
function cInnerActive:showFullScreenAd(psAid, poGroup)
	cDebug.DEBUG_LEVEL=DEBUG__INFO
 
	if poGroup then	self.adGroup = poGroup end
	self:getFullScreenAd(psAid, poGroup)
end

-- *********************************************************
function cInnerActive:_buildUrl( poArgs )
	local sUrl, sCID, sID, sAdType 
	
	-- base url
	sUrl=self.baseUrl
	
	-- specify the request
	sUrl = sUrl .. "clientRequestAd"

	-- basic information
	sUrl = sUrl .. "?v="..self.version.."&aid="..self.applicationID
	
	-- width
	if poArgs.w then
		sUrl = sUrl.."&w="..poArgs.w
	end
	
	--height
	if poArgs.h then
		sUrl = sUrl.."&h="..poArgs.h
	end
	
	-- set test flag in simulator
	if utility.isSimulator() then
		sUrl = sUrl.."&test=1"
	end
	
	-- campaign ID 
	sCID = cSettings:get(cid_settings_key, nil)
	if sCID then
		sUrl = sUrl.."&cid="..sCID			--new CID
	end
	
	-- unique ID
	sID = system.getInfo("deviceID")
	sUrl = sUrl.."&hid="..sID
	
	--full screen
	if poArgs.fullScreen then
		sUrl = sUrl.."&fs=true"
	end
	
	cDebug:print(DEBUG__INFO, "inneractive URL - ",sUrl)
	
	return sUrl
end

-- *********************************************************
function cInnerActive:_fetchAd(psUrl)
	local sXML, oXML, oNode, oData
	
	-- get the data
	cHttp.forceUserAgent = self.forceUserAgent
	sXML = cHttp:get(psUrl)
	
	--turn the response into something useful
	oXML = XmlParser:ParseXmlText(sXML)
	
	-- extract the bits from the response
	oData = cIaAdData:create()
	
	oNode = XmlParser.findNode("tns:Url", oXML, true)
	oData.clickUrl = oNode.Value
	oNode = XmlParser.findNode("tns:Image", oXML, true)
	oData.imageUrl = oNode.Value
	oNode = XmlParser.findNode("tns:Client", oXML, true, false)
	if oNode then
		oData.CID = XmlParser.getNodeAttr("ID", oNode)
		cSettings:set(cid_settings_key, oData.CID)
		cSettings:commit()
	end
	
	cDebug:print(DEBUG__INFO, "next CID = ", oData.CID)
	cDebug:print(DEBUG__INFO, "Adurl:",oData.clickUrl)
	cDebug:print(DEBUG__INFO, "Adimg:",oData.imageUrl)
	
	return oData
end

-- *********************************************************
function cInnerActive:getFullScreenAd()
	local sUrl, pfnCallBack, oXML, oNode
	local iw, ih
	
	-- check status of net 
	if not cHttp.isNetReachable then 
		cDebug:print(DEBUG__INFO, "not displaying ads - net unreachable")
		return 
	end
	cDebug:print(DEBUG__INFO, "net reachable - displaying ad")
	
	-- how big and wide
	iw = utility.Screen.w - 2*self.adBorder
	ih = utility.Screen.h - 2*self.adBorder
	
	--build the URL
	cDebug:print(DEBUG__INFO, "about to get ad")
	sUrl = self:_buildUrl( {w=iw, h=ih, fullScreen=true})
	self.adData = self:_fetchAd(sUrl)
	
	-- load the ad image
	cDebug:print(DEBUG__INFO, "about to load image")
	pFnCallback = cLibEvents.makeEventClosure(self, "onLoadRemoteImage")
	display.loadRemoteImage( self.adData.imageUrl, "GET", pFnCallback, self.remoteImageFile )
end

-- *********************************************************
function cInnerActive:onLoadRemoteImage(poEvent)
	local oImg
	
	-- remove previous ad
	if self.fullScreenAd then
		cDebug:print(DEBUG__INFO, "removing old ad")
		self.fullScreenAd:removeEventListener( "tap", self)
		self.fullScreenAd:removeSelf()
		self.fullScreenAd = nil
	end

	--remember the image
	cDebug:print(DEBUG__INFO, "ad image loaded")
	oImg = poEvent.target
	self.fullScreenAd = oImg
	
	-- remember and move ad to centre of screen
	if self.adGroup then self.adGroup:insert(oImg) end
	utility:moveToScreenCentre(oImg, true)
	
	-- add a touch listener
	oImg:addEventListener( "tap", self )
end

-- *********************************************************
function cInnerActive:tap(poEvent)
	cDebug:print(DEBUG__INFO, "ad touched:")
	system.openURL(self.adData.clickUrl)
end

-- *********************************************************
function cInnerActive:hide()
	if self.fullScreenAd then
		self.fullScreenAd:removeSelf()
		self.fullScreenAd = nil
	end
end

