--[[
This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License.
	http://creativecommons.org/licenses/by-sa/3.0/
Absolutely no warranties or guarantees given or implied - use at your own risk
Copyright (C) 2012 ChickenKatsu All Rights Reserved. http://www.chickenkatsu.co.uk/
--]]
ads = require("ads")

cAds = {
	sType = nil, aArgs=nil, 
	showDelay=10000, hideDelay=20000,
	whichWay = "portrait",
	applicationID= "not set",
	adEvents = 0,
	adEventThreshold = 3
}

--TODO check device has capabilities
-- *********************************************************
-- shows and hides banner adds on a timer
function cAds:init(psProvider, psType, paArgs)
	if utility.isSimulator  then 
		cDebug:print(DEBUG__WARN,"** Ads not available on simulator")
		return
	end
	ads.init(psProvider, self.applicationID)	
	
	self.sType = psType
	self.aArgs  = paArgs
	self.otimer = nil
	self.paused = false
	self.listening=false
	
	self:resume()
end

-- *********************************************************
function cAds:orientation(poEvent)
	if utility.isSimulator  then return end
	
	cDebug:print(DEBUG__INFO, "ads orientation:",poEvent.type)
	self.whichWay  = poEvent.type
end

-- *********************************************************
function cAds:showBannerAd()
	if utility.isSimulator  then return end
	
	if self.paused then return end
	self.otimer = nil
	ads.show(self.sType, self.aArgs)	
	local fnCallback = function() self:hideBannerAd() end
	self.otimer = timer.performWithDelay(self.hideDelay, fnCallback,1)
end

-- *********************************************************
function cAds:hideBannerAd()
	if self.paused then return end
	self.otimer = nil
	ads.hide()
	local fnCallback = function() self:showBannerAd() end
	self.otimer = timer.performWithDelay(self.showDelay, fnCallback,1)
end

-- *********************************************************
function cAds:stopBanners()
	if self.otimer then 	
		timer.cancel(self.otimer)
		self.otimer = nil
	end
	ads.hide()
end

-- *********************************************************
function cAds:pause()	
	self.paused = true
	if self.otimer then 	
		timer.cancel(self.otimer)
		self.otimer = nil
	end
	if listening then
		Runtime:removeEventListener( "orientation", self )
	end
	ads.hide()
end

-- *********************************************************
function cAds:resume()
	self.paused = false
	if not listening then
		Runtime:addEventListener( "orientation", self )
	end
	self:showBannerAd()
end

-- *********************************************************
function cAds:yesNoFullScreenAd()
	self.adEvents = self.adEvents  + 1
	if self.adEvents >= self.adEventThreshold then
		self.adEvents  = 0
		return true
	else
		return false
	end
end

