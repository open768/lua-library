require "inc.lib.lib-spritegen"

cImgCutter = {}

function  cImgCutter.shred(psImg, piCellW, piCellH)
	local iw,ih, iCountX, iCountY, iNSprites, a 
	
	--------------- get number of sprites
	iw,ih = utility.getImageDimensions(psImg)
	iCountX = math.floor(iw / piCellW)
	iCountY = math.floor(ih / piCellH)
	
	iNSprites = iCountX * iCountY
	
	--------------- get the sprites
	oGen = cSpriteGenerator:create(psImg, piCellW, piCellH, iNSprites)
	
	return oGen, iCountX, iCountY, iw,ih
end