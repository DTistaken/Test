-- Game Boy Graphics/PPU (Picture Processing Unit)
-- Handles rendering and video output

local GPU = {}
GPU.__index = GPU

function GPU.new()
	local self = setmetatable({}, GPU)
	
	-- Game Boy screen dimensions
	self.width = 160
	self.height = 144
	
	-- Tile data
	self.framebuffer = {}
	for i = 1, self.width * self.height do
		self.framebuffer[i] = 0
	end
	
	self.tileCache = {}
	self.scanline = 0
	self.cycles = 0
	self.mode = 0  -- 0: HBlank, 1: VBlank, 2: OAM search, 3: Pixel transfer
	
	-- GPU Registers
	self.lcdc = 0x91  -- LCD Control
	self.stat = 0x00  -- LCD Status
	self.scy = 0      -- Scroll Y
	self.scx = 0      -- Scroll X
	self.ly = 0       -- Current scanline
	self.lyc = 0      -- LY Compare
	self.pal = 0xE4   -- BG Palette
	self.obp0 = 0xFF  -- Object Palette 0
	self.obp1 = 0xFF  -- Object Palette 1
	self.wy = 0       -- Window Y
	self.wx = 0       -- Window X
	
	self.memory = nil
	
	return self
end

function GPU:setMemory(memory)
	self.memory = memory
end

function GPU:getPaletteColor(paletteIndex, colorIndex)
	-- Decode 2-bit color from palette
	local shift = colorIndex * 2
	local colorData = math.floor(paletteIndex / math.pow(2, shift)) % 4
	
	-- Map to grayscale (0-3 -> 0-255)
	local colors = {255, 192, 96, 0}  -- White to black
	return colors[colorData + 1]
end

function GPU:getTile(tileIndex)
	if self.tileCache[tileIndex] then
		return self.tileCache[tileIndex]
	end
	
	local tileData = {}
	local baseAddr = 0x8000 + (tileIndex * 16)
	
	for y = 0, 7 do
		local byte1 = self.memory:readByte(baseAddr + (y * 2))
		local byte2 = self.memory:readByte(baseAddr + (y * 2) + 1)
		
		for x = 0, 7 do
			local bit1 = math.floor(byte1 / math.pow(2, 7 - x)) % 2
			local bit2 = math.floor(byte2 / math.pow(2, 7 - x)) % 2
			local colorIndex = (bit2 * 2) + bit1
			tileData[y * 8 + x + 1] = colorIndex
		end
	end
	
	self.tileCache[tileIndex] = tileData
	return tileData
end

function GPU:renderScanline()
	if not self.memory then return end
	
	local lcdc = self.memory:getDirect(0xFF40)
	local bgEnable = (lcdc % 2 == 1)
	local spriteEnable = (math.floor(lcdc / 2) % 2 == 1)
	local spriteSize = (math.floor(lcdc / 4) % 2 == 1) and 16 or 8
	
	if not bgEnable and not spriteEnable then
		return
	end
	
	-- Render background
	if bgEnable then
		local scx = self.memory:getDirect(0xFF43)
		local scy = self.memory:getDirect(0xFF42)
		local pal = self.memory:getDirect(0xFF47)
		
		for x = 0, self.width - 1 do
			local mapX = (x + scx) % 256
			local mapY = (self.ly + scy) % 256
			
			local tileX = math.floor(mapX / 8)
			local tileY = math.floor(mapY / 8)
			local inTileX = mapX % 8
			local inTileY = mapY % 8
			
			local mapAddr = 0x9800 + (tileY * 32) + tileX
			local tileIndex = self.memory:readByte(mapAddr)
			
			local tile = self:getTile(tileIndex)
			local colorIndex = tile[inTileY * 8 + inTileX + 1] or 0
			local color = self:getPaletteColor(pal, colorIndex)
			
			local pixelIdx = self.ly * self.width + x + 1
			self.framebuffer[pixelIdx] = color
		end
	end
	
	-- Render sprites
	if spriteEnable then
		for spriteNum = 0, 39 do
			local oamAddr = 0xFE00 + (spriteNum * 4)
			local spriteY = self.memory:readByte(oamAddr)
			local spriteX = self.memory:readByte(oamAddr + 1)
			local tileIndex = self.memory:readByte(oamAddr + 2)
			local flags = self.memory:readByte(oamAddr + 3)
			
			if self.ly >= spriteY and self.ly < (spriteY + spriteSize) then
				local tile = self:getTile(tileIndex)
				local inTileY = self.ly - spriteY
				
				for inTileX = 0, 7 do
					local screenX = spriteX - 8 + inTileX
					if screenX >= 0 and screenX < self.width then
						local colorIndex = tile[inTileY * 8 + inTileX + 1] or 0
						if colorIndex > 0 then
							local palReg = (math.floor(flags / 16) % 2 == 1) and 0xFF49 or 0xFF48
							local pal = self.memory:getDirect(palReg)
							local color = self:getPaletteColor(pal, colorIndex)
							local pixelIdx = self.ly * self.width + screenX + 1
							self.framebuffer[pixelIdx] = color
						end
					end
				end
			end
		end
	end
end

function GPU:step(cycles)
	self.cycles = self.cycles + cycles
	
	-- Scanline timing:
	-- Mode 0 (HBlank): 204 cycles
	-- Mode 1 (VBlank): 456 cycles per line * 10 lines
	-- Mode 2 (OAM search): 80 cycles
	-- Mode 3 (Pixel transfer): 172 cycles
	
	if self.ly < 144 then
		if self.cycles >= 456 then
			self.cycles = 0
			self.ly = (self.ly + 1) % 154
			if self.ly == 144 then
				self.mode = 1  -- VBlank
			else
				self.mode = 2  -- OAM search
			end
		end
		
		if self.mode == 2 and self.cycles >= 80 then
			self.mode = 3  -- Pixel transfer
		elseif self.mode == 3 and self.cycles >= 252 then
			self:renderScanline()
			self.mode = 0  -- HBlank
		end
	else
		if self.cycles >= 456 then
			self.cycles = 0
			self.ly = (self.ly + 1) % 154
			if self.ly == 0 then
				self.mode = 2  -- OAM search
			end
		end
	end
	
	self.memory:setDirect(0xFF44, self.ly)
end

function GPU:getFramebuffer()
	return self.framebuffer
end

return GPU
