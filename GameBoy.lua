-- Main Game Boy Emulator
-- Orchestrates all components: CPU, MMU, GPU, APU, Timers

local CPU = require(script.CPU)
local MMU = require(script.MMU)
local GPU = require(script.GPU)
local APU = require(script.APU)

local GameBoy = {}
GameBoy.__index = GameBoy

function GameBoy.new()
	local self = setmetatable({}, GameBoy)
	
	-- Initialize components
	self.mmu = MMU.new()
	self.cpu = CPU.new()
	self.gpu = GPU.new()
	self.apu = APU.new()
	
	-- Connect components
	self.cpu:setMemory(self.mmu)
	self.gpu:setMemory(self.mmu)
	
	-- Timing
	self.cycleCounter = 0
	self.cpuFrequency = 4194304  -- 4.19 MHz
	self.running = false
	
	-- Input
	self.joypad = {
		up = false,
		down = false,
		left = false,
		right = false,
		a = false,
		b = false,
		start = false,
		select = false,
	}
	
	-- Interrupt flags
	self.interruptFlags = 0x00
	self.interruptEnable = 0x00
	
	-- Timers
	self.divCounter = 0
	self.timaCounter = 0
	self.timaFrequencies = {1024, 16, 64, 256}
	
	return self
end

function GameBoy:loadROM(romData)
	self.mmu:loadROM(romData)
end

function GameBoy:step()
	if not self.running then return end
	
	-- Execute CPU instruction
	local cycles = self.cpu:step()
	self.cycleCounter = self.cycleCounter + cycles
	
	-- Update GPU
	self.gpu:step(cycles)
	
	-- Update APU
	self.apu:step(cycles)
	
	-- Update timers
	self:updateTimers(cycles)
	
	-- Handle interrupts
	self:handleInterrupts()
end

function GameBoy:updateTimers(cycles)
	self.divCounter = (self.divCounter + cycles) % 256
	
	local timerControl = self.mmu:readByte(0xFF07)
	local timerEnable = (timerControl % 2 == 1)
	local timerFreq = math.floor(timerControl / 4) % 4
	
	if timerEnable then
		self.timaCounter = self.timaCounter + cycles
		local threshold = self.timaFrequencies[timerFreq + 1]
		
		if self.timaCounter >= threshold then
			self.timaCounter = 0
			local tima = self.mmu:readByte(0xFF05)
			if tima == 255 then
				self.mmu:writeByte(0xFF05, self.mmu:readByte(0xFF06))
				self.interruptFlags = self.interruptFlags + 4  -- Timer interrupt
			else
				self.mmu:writeByte(0xFF05, tima + 1)
			end
		end
	end
	
	-- Update DIV register
	self.mmu:writeByte(0xFF04, math.floor(self.divCounter / 256))
end

function GameBoy:handleInterrupts()
	if self.cpu.IME then
		local enabled = self.mmu:readByte(0xFFFF)
		local flags = self.mmu:readByte(0xFF0F)
		
		if (flags % 2 == 1) and (enabled % 2 == 1) then  -- V-Blank
			self.cpu:push(self.cpu.registers.PC)
			self.cpu.registers.PC = 0x40
			self.cpu.IME = false
			self.mmu:writeByte(0xFF0F, flags - 1)
		elseif (math.floor(flags / 2) % 2 == 1) and (math.floor(enabled / 2) % 2 == 1) then  -- LCD Stat
			self.cpu:push(self.cpu.registers.PC)
			self.cpu.registers.PC = 0x48
			self.cpu.IME = false
			self.mmu:writeByte(0xFF0F, flags - 2)
		elseif (math.floor(flags / 4) % 2 == 1) and (math.floor(enabled / 4) % 2 == 1) then  -- Timer
			self.cpu:push(self.cpu.registers.PC)
			self.cpu.registers.PC = 0x50
			self.cpu.IME = false
			self.mmu:writeByte(0xFF0F, flags - 4)
		elseif (math.floor(flags / 8) % 2 == 1) and (math.floor(enabled / 8) % 2 == 1) then  -- Serial
			self.cpu:push(self.cpu.registers.PC)
			self.cpu.registers.PC = 0x58
			self.cpu.IME = false
			self.mmu:writeByte(0xFF0F, flags - 8)
		elseif (math.floor(flags / 16) % 2 == 1) and (math.floor(enabled / 16) % 2 == 1) then  -- Joypad
			self.cpu:push(self.cpu.registers.PC)
			self.cpu.registers.PC = 0x60
			self.cpu.IME = false
			self.mmu:writeByte(0xFF0F, flags - 16)
		end
	end
end

function GameBoy:setJoypadInput(input, pressed)
	self.joypad[input] = pressed
	self:updateJoypadRegister()
end

function GameBoy:updateJoypadRegister()
	local joyp = self.mmu:readByte(0xFF00)
	local buttonSelect = (joyp % 32 < 16)  -- Bit 5
	local directionSelect = (joyp % 16 < 8)  -- Bit 4
	
	local result = 0x0F
	
	if directionSelect then
		if not self.joypad.right then result = result - 1 end
		if not self.joypad.left then result = result - 2 end
		if not self.joypad.up then result = result - 4 end
		if not self.joypad.down then result = result - 8 end
	end
	
	if buttonSelect then
		if not self.joypad.a then result = result - 1 end
		if not self.joypad.b then result = result - 2 end
		if not self.joypad.select then result = result - 4 end
		if not self.joypad.start then result = result - 8 end
	end
	
	result = result + math.floor(joyp / 16) * 16
	self.mmu:writeByte(0xFF00, result)
end

function GameBoy:getFramebuffer()
	return self.gpu:getFramebuffer()
end

function GameBoy:run()
	self.running = true
end

function GameBoy:pause()
	self.running = false
end

function GameBoy:getROMTitle()
	local title = ""
	for i = 0, 15 do
		local byte = self.mmu:readByte(0x0134 + i)
		if byte ~= 0 then
			title = title .. string.char(byte)
		end
	end
	return title
end

return GameBoy
