-- ROM Loader for Game Boy Emulator - Roblox Version
-- Handles loading Game Boy ROM data from Roblox-compatible sources

local ROMLoader = {}
ROMLoader.__index = ROMLoader

-- Game Boy cartridge types
local CARTRIDGE_TYPES = {
	[0x00] = "ROM_ONLY",
	[0x01] = "MBC1",
	[0x02] = "MBC1_RAM",
	[0x03] = "MBC1_RAM_BATTERY",
	[0x05] = "MBC2",
	[0x06] = "MBC2_BATTERY",
	[0x08] = "ROM_RAM",
	[0x09] = "ROM_RAM_BATTERY",
	[0x0B] = "MMM01",
	[0x0C] = "MMM01_RAM",
	[0x0D] = "MMM01_RAM_BATTERY",
	[0x0F] = "MBC3_TIMER_BATTERY",
	[0x10] = "MBC3_TIMER_RAM_BATTERY",
	[0x11] = "MBC3",
	[0x12] = "MBC3_RAM",
	[0x13] = "MBC3_RAM_BATTERY",
	[0x15] = "MBC4",
	[0x16] = "MBC4_RAM",
	[0x17] = "MBC4_RAM_BATTERY",
	[0x19] = "MBC5",
	[0x1A] = "MBC5_RAM",
	[0x1B] = "MBC5_RAM_BATTERY",
	[0x1C] = "MBC5_RUMBLE",
	[0x1D] = "MBC5_RUMBLE_RAM",
	[0x1E] = "MBC5_RUMBLE_RAM_BATTERY",
}

function ROMLoader.new()
	local self = setmetatable({}, ROMLoader)
	return self
end

function ROMLoader:loadFromAsset(assetId)
	-- Load ROM from a Roblox asset (e.g., decal, image, or uploaded file)
	-- This requires the asset to be converted to binary data
	-- For now, this is a placeholder
	warn("Asset loading not fully supported - use base64 encoded ROMs instead")
	return nil
end

function ROMLoader:decodeBase64(str)
	-- Decode base64 string to binary data
	local base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local result = ""
	
	str = str:gsub("[^" .. base64chars .. "=]", "")
	
	for i = 1, #str, 4 do
		local chunk = str:sub(i, i + 3)
		local c1, c2, c3, c4 = chunk:byte(1), chunk:byte(2), chunk:byte(3), chunk:byte(4)
		
		local p1 = base64chars:find(string.char(c1)) - 1
		local p2 = base64chars:find(string.char(c2)) - 1
		local p3 = base64chars:find(string.char(c3)) - 1 or 0
		local p4 = base64chars:find(string.char(c4)) - 1 or 0
		
		local b1 = bit32.bor(bit32.lshift(p1, 2), bit32.rshift(p2, 4))
		local b2 = bit32.bor(bit32.lshift(bit32.band(p2, 15), 4), bit32.rshift(p3, 2))
		local b3 = bit32.bor(bit32.lshift(bit32.band(p3, 3), 6), p4)
		
		result = result .. string.char(b1)
		if c3 ~= string.byte("=") then result = result .. string.char(b2) end
		if c4 ~= string.byte("=") then result = result .. string.char(b3) end
	end
	
	return result
end

function ROMLoader:loadFromDataModule(moduleScript)
	-- Load ROM data from a ModuleScript that contains binary ROM data
	-- Usage: Create a ModuleScript that returns a string of binary data
	if not moduleScript then
		return nil, "No module provided"
	end
	
	local success, romData = pcall(function()
		return require(moduleScript)
	end)
	
	if not success then
		return nil, "Failed to load ROM module: " .. tostring(romData)
	end
	
	if type(romData) == "string" then
		return romData, "ROM loaded successfully"
	elseif type(romData) == "function" then
		return romData(), "ROM function executed"
	else
		return nil, "ROM module must return a string or function"
	end
end

function ROMLoader:createTestROM()
	-- Create a minimal test ROM for demonstration
	-- This is a very basic ROM that won't do much but can be displayed
	local rom = {}
	
	-- ROM header at 0x100-0x14F
	-- Entry point
	for i = 0x100, 0x103 do table.insert(rom, 0x00) end
	
	-- Logo (simplified)
	for i = 0x104, 0x133 do table.insert(rom, 0xCE) end
	
	-- Title: "TESTGAME"
	local title = "TESTGAME"
	for i = 1, #title do table.insert(rom, string.byte(title, i)) end
	for i = #title, 15 do table.insert(rom, 0x00) end
	
	-- Cartridge type: ROM_ONLY
	table.insert(rom, 0x00)
	-- ROM size: 32KB
	table.insert(rom, 0x00)
	-- RAM size: 0
	table.insert(rom, 0x00)
	-- Destination: Japan
	table.insert(rom, 0x00)
	-- Licensee
	table.insert(rom, 0x33)
	-- Version
	table.insert(rom, 0x00)
	-- Header checksum
	table.insert(rom, 0x00)
	-- Global checksum
	table.insert(rom, 0x00)
	table.insert(rom, 0x00)
	
	-- Fill rest of ROM with zeros (up to 32KB)
	while #rom < 32768 do
		table.insert(rom, 0x00)
	end
	
	return string.char(unpack(rom)), "Test ROM created"
end

function ROMLoader:parseROMHeader(romData)
	-- Parse Game Boy ROM header information
	local info = {
		title = "",
		type = "Unknown",
		romSize = 0,
		ramSize = 0,
		isJapanese = false,
		licenseeCode = 0,
		version = 0,
		headerChecksum = 0,
		globalChecksum = 0,
	}
	
	if #romData < 0x150 then
		return info, "ROM too small for header parsing"
	end
	
	-- Title (0x0134 - 0x0143)
	for i = 0x0134, 0x0143 do
		local byte = string.byte(romData, i + 1) or 0
		if byte ~= 0 and byte >= 32 and byte < 127 then
			info.title = info.title .. string.char(byte)
		end
	end
	
	-- Cartridge type (0x0147)
	local typeCode = string.byte(romData, 0x0148) or 0
	info.type = CARTRIDGE_TYPES[typeCode] or "Unknown (0x" .. string.format("%02X", typeCode) .. ")"
	
	-- ROM size (0x0148)
	local romSizeCode = string.byte(romData, 0x0149) or 0
	info.romSize = 32 * (math.pow(2, romSizeCode))
	
	-- RAM size (0x0149)
	local ramSizeCode = string.byte(romData, 0x014A) or 0
	local ramSizes = {0, 2, 8, 32, 128, 64}
	info.ramSize = ramSizes[ramSizeCode + 1] or 0
	
	-- Destination code (0x014B)
	info.isJapanese = (string.byte(romData, 0x014B) or 0) == 0
	
	-- Licensee code (0x014C)
	info.licenseeCode = string.byte(romData, 0x014C) or 0
	
	-- ROM version (0x014D)
	info.version = string.byte(romData, 0x014D) or 0
	
	-- Header checksum (0x014E)
	info.headerChecksum = string.byte(romData, 0x014E) or 0
	
	-- Global checksum (0x014F - 0x0150)
	local byte1 = string.byte(romData, 0x0150) or 0
	local byte2 = string.byte(romData, 0x0151) or 0
	info.globalChecksum = (byte1 * 256) + byte2
	
	return info, "Header parsed successfully"
end

function ROMLoader:validateROM(romData)
	-- Verify ROM is valid Game Boy ROM
	if #romData < 0x150 then
		return false, "ROM too small (minimum 336 bytes needed)"
	end
	
	-- Check for valid cartridge type
	local typeCode = string.byte(romData, 0x0148) or 0
	if not CARTRIDGE_TYPES[typeCode] then
		return false, "Unknown cartridge type: 0x" .. string.format("%02X", typeCode)
	end
	
	return true, "Valid Game Boy ROM"
end

function ROMLoader:getInfo(romData)
	local valid, message = self:validateROM(romData)
	if not valid then
		return nil, message
	end
	
	return self:parseROMHeader(romData)
end

return ROMLoader
