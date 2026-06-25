-- Display Renderer for Roblox Studio
-- Renders Game Boy framebuffer to Roblox GUI

local DisplayRenderer = {}
DisplayRenderer.__index = DisplayRenderer

function DisplayRenderer.new(parentGui)
	local self = setmetatable({}, DisplayRenderer)
	
	self.parent = parentGui
	self.screenWidth = 160
	self.screenHeight = 144
	self.pixelSize = 4  -- Scale each pixel to 4x4 in Roblox
	
	-- Create main screen frame
	self.screenFrame = Instance.new("Frame")
	self.screenFrame.Name = "GameBoyScreen"
	self.screenFrame.Size = UDim2.new(0, self.screenWidth * self.pixelSize, 0, self.screenHeight * self.pixelSize)
	self.screenFrame.Position = UDim2.new(0.5, -(self.screenWidth * self.pixelSize / 2), 0.5, -(self.screenHeight * self.pixelSize / 2))
	self.screenFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.screenFrame.BorderSizePixel = 0
	self.screenFrame.Parent = self.parent
	
	-- Create pixel grid
	self.pixels = {}
	for y = 0, self.screenHeight - 1 do
		self.pixels[y] = {}
		for x = 0, self.screenWidth - 1 do
			local pixel = Instance.new("Frame")
			pixel.Name = "Pixel_" .. x .. "_" .. y
			pixel.Size = UDim2.new(0, self.pixelSize, 0, self.pixelSize)
			pixel.Position = UDim2.new(0, x * self.pixelSize, 0, y * self.pixelSize)
			pixel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			pixel.BorderSizePixel = 0
			pixel.Parent = self.screenFrame
			
			self.pixels[y][x] = pixel
		end
	end
	
	return self
end

function DisplayRenderer:updateFrame(framebuffer)
	-- Update display with framebuffer data
	for i = 1, math.min(#framebuffer, self.screenWidth * self.screenHeight) do
		local pixelValue = framebuffer[i] or 0
		local y = math.floor((i - 1) / self.screenWidth)
		local x = (i - 1) % self.screenWidth
		
		if self.pixels[y] and self.pixels[y][x] then
			-- Convert grayscale value (0-255) to color
			local color = math.floor(pixelValue / 255 * 255)
			self.pixels[y][x].BackgroundColor3 = Color3.fromRGB(color, color, color)
		end
	end
end

function DisplayRenderer:setPixelSize(size)
	self.pixelSize = size
	self.screenFrame.Size = UDim2.new(0, self.screenWidth * self.pixelSize, 0, self.screenHeight * self.pixelSize)
	
	for y = 0, self.screenHeight - 1 do
		for x = 0, self.screenWidth - 1 do
			if self.pixels[y] and self.pixels[y][x] then
				self.pixels[y][x].Size = UDim2.new(0, self.pixelSize, self.pixelSize)
				self.pixels[y][x].Position = UDim2.new(0, x * self.pixelSize, 0, y * self.pixelSize)
			end
		end
	end
end

function DisplayRenderer:clear()
	for y = 0, self.screenHeight - 1 do
		for x = 0, self.screenWidth - 1 do
			if self.pixels[y] and self.pixels[y][x] then
				self.pixels[y][x].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end

function DisplayRenderer:destroy()
	self.screenFrame:Destroy()
	self.pixels = {}
end

return DisplayRenderer
