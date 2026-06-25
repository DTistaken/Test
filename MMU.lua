-- Game Boy Memory Management Unit (MMU)
-- Handles memory mapping and access across ROM, RAM, VRAM, etc.

local MMU = {}
MMU.__index = MMU

-- Memory Map:
-- 0x0000-0x00FF: Bootstrap ROM
-- 0x0100-0x7FFF: Game ROM (32KB)
-- 0x8000-0x9FFF: Video RAM (8KB)
-- 0xA000-0xBFFF: External RAM (8KB)
-- 0xC000-0xDFFF: Internal RAM (8KB)
-- 0xE000-0xFDFF: Echo of Internal RAM (7680 bytes)
-- 0xFE00-0xFE9F: OAM - Sprite Attribute Table (160 bytes)
-- 0xFEA0-0xFEFF: Unusable (96 bytes)
-- 0xFF00-0xFF7F: I/O Registers (128 bytes)
-- 0xFF80-0xFFFE: High RAM (127 bytes)
-- 0xFFFF: Interrupt Enable Register

function MMU.new()
	local self = setmetatable({}, MMU)
	
	self.romBank = 1
	self.ramBank = 0
	self.ramEnabled = false
	self.romSize = 32 * 1024  -- 32KB
	self.ramSize = 8 * 1024   -- 8KB
	
	-- Initialize memory
	self.memory = {}
	for i = 0, 65535 do
		self.memory[i] = 0
	end
	
	self.rom = {}
	self.externalRam = {}
	
	return self
end

function MMU:loadROM(romData)
	-- romData should be a string of bytes
	self.rom = {}
	for i = 1, math.min(#romData, self.romSize) do
		self.rom[i - 1] = string.byte(romData, i)
	end
end

function MMU:readByte(address)
	address = address % 65536
	
	if address < 0x8000 then
		-- ROM area
		if address < self.romSize then
			return self.rom[address] or 0
		end
	elseif address < 0xA000 then
		-- VRAM (0x8000-0x9FFF)
		return self.memory[address] or 0
	elseif address < 0xC000 then
		-- External RAM (0xA000-0xBFFF)
		if self.ramEnabled then
			local ramAddr = (address - 0xA000) + (self.ramBank * self.ramSize)
			return self.externalRam[ramAddr] or 0
		end
		return 0xFF
	elseif address < 0xE000 then
		-- Internal RAM (0xC000-0xDFFF)
		return self.memory[address] or 0
	elseif address < 0xFE00 then
		-- Echo RAM (0xE000-0xFDFF)
		return self:readByte(address - 0x2000)
	elseif address < 0xFEA0 then
		-- OAM (0xFE00-0xFE9F)
		return self.memory[address] or 0
	elseif address < 0xFF00 then
		-- Unusable (0xFEA0-0xFEFF)
		return 0xFF
	else
		-- I/O Registers and High RAM
		return self.memory[address] or 0
	end
end

function MMU:writeByte(address, value)
	address = address % 65536
	value = value % 256
	
	if address < 0x2000 then
		-- RAM Enable (0x0000-0x1FFF)
		self.ramEnabled = (value % 16 == 0x0A)
	elseif address < 0x4000 then
		-- ROM Bank (0x2000-0x3FFF)
		self.romBank = math.max(1, value % 128)
	elseif address < 0x6000 then
		-- RAM Bank (0x4000-0x5FFF)
		self.ramBank = value % 4
	elseif address < 0x8000 then
		-- Mode Select (0x6000-0x7FFF)
		-- Bank mode switching
	elseif address < 0xA000 then
		-- VRAM (0x8000-0x9FFF)
		self.memory[address] = value
	elseif address < 0xC000 then
		-- External RAM (0xA000-0xBFFF)
		if self.ramEnabled then
			local ramAddr = (address - 0xA000) + (self.ramBank * self.ramSize)
			self.externalRam[ramAddr] = value
		end
	elseif address < 0xE000 then
		-- Internal RAM (0xC000-0xDFFF)
		self.memory[address] = value
	elseif address < 0xFE00 then
		-- Echo RAM (0xE000-0xFDFF)
		self:writeByte(address - 0x2000, value)
	elseif address < 0xFEA0 then
		-- OAM (0xFE00-0xFE9F)
		self.memory[address] = value
	elseif address < 0xFF00 then
		-- Unusable (0xFEA0-0xFEFF)
		-- Do nothing
	elseif address == 0xFF44 then
		-- LY - Scanline (write resets to 0)
		self.memory[address] = 0
	else
		-- I/O Registers and High RAM
		self.memory[address] = value
	end
end

function MMU:read16bit(address)
	local low = self:readByte(address)
	local high = self:readByte(address + 1)
	return (high * 256) + low
end

function MMU:write16bit(address, value)
	self:writeByte(address, value % 256)
	self:writeByte(address + 1, math.floor(value / 256))
end

function MMU:getDirect(address)
	return self.memory[address % 65536] or 0
end

function MMU:setDirect(address, value)
	self.memory[address % 65536] = value % 256
end

return MMU
