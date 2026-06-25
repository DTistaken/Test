-- ROM Loader for Game Boy Emulator
-- Handles loading Game Boy ROM files

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

function ROMLoader:loadFromFile(filePath)
	-- This would need to be implemented based on how files are accessed in your environment
	-- For now, return a placeholder
	return nil
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
	
	-- Title (0x0134 - 0x0143)
	for i = 0x0134, 0x0143 do
		local byte = string.byte(romData, i + 1) or 0
		if byte ~= 0 then
			info.title = info.title .. string.char(byte)
		end
	end
	
	-- Cartridge type (0x0147)
	local typeCode = string.byte(romData, 0x0148) or 0
	info.type = CARTRIDGE_TYPES[typeCode] or "Unknown"
	
	-- ROM size (0x0148)
	local romSizeCode = string.byte(romData, 0x0149) or 0
	info.romSize = 32 * (math.pow(2, romSizeCode))
	
	-- RAM size (0x0149)
	local ramSizeCode = string.byte(romData, 0x014A) or 0
	local ramSizes = {0, 2, 8, 32, 128, 64}
	info.ramSize = ramSizes[ramSizeCode + 1] or 0
	
	-- Destination code (0x014A)
	info.isJapanese = (string.byte(romData, 0x014B) or 0) == 0
	
	-- Old licensee code (0x014B)
	info.licenseeCode = string.byte(romData, 0x014C) or 0
	
	-- ROM version (0x014C)
	info.version = string.byte(romData, 0x014D) or 0
	
	-- Header checksum (0x014D)
	info.headerChecksum = string.byte(romData, 0x014E) or 0
	
	-- Global checksum (0x014E - 0x014F)
	local byte1 = string.byte(romData, 0x0150) or 0
	local byte2 = string.byte(romData, 0x0151) or 0
	info.globalChecksum = (byte1 * 256) + byte2
	
	return info
end

function ROMLoader:validateROM(romData)
	-- Verify ROM is valid Game Boy ROM
	if #romData < 0x150 then
		return false, "ROM too small"
	end
	
	-- Check for valid cartridge type
	local typeCode = string.byte(romData, 0x0148) or 0
	if not CARTRIDGE_TYPES[typeCode] then
		return false, "Unknown cartridge type: " .. typeCode
	end
	
	return true, "Valid Game Boy ROM"
end

function ROMLoader:getInfo(romData)
	local valid, message = self:validateROM(romData)
	if not valid then
		return nil, message
	end
	
	return self:parseROMHeader(romData), "Header parsed successfully"
end

return ROMLoader
