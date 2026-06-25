-- Game Boy CPU Emulator (Z80-based)
-- Implements core CPU instructions, registers, and timing

local CPU = {}
CPU.__index = CPU

function CPU.new()
	local self = setmetatable({}, CPU)
	
	-- Registers (16-bit pairs)
	self.registers = {
		A = 0x00,  -- Accumulator
		F = 0x00,  -- Flags
		B = 0x00, C = 0x00,  -- BC
		D = 0x00, E = 0x00,  -- DE
		H = 0x00, L = 0x00,  -- HL
		SP = 0xFFFE,  -- Stack Pointer
		PC = 0x0100,  -- Program Counter
	}
	
	-- Flags (F register)
	self.flags = {
		Z = false,  -- Zero
		N = false,  -- Subtract
		H = false,  -- Half-carry
		C = false,  -- Carry
	}
	
	self.memory = nil  -- Will be set by MMU
	self.halted = false
	self.stopped = false
	self.IME = false  -- Interrupt Master Enable
	self.cycles = 0
	
	return self
end

function CPU:setMemory(memory)
	self.memory = memory
end

function CPU:updateFlags()
	-- Update F register from flags table
	local f = 0
	if self.flags.Z then f = f + 0x80 end
	if self.flags.N then f = f + 0x40 end
	if self.flags.H then f = f + 0x20 end
	if self.flags.C then f = f + 0x10 end
	self.registers.F = f
end

function CPU:readFlags()
	-- Read F register into flags table
	local f = self.registers.F
	self.flags.Z = (f % 256 >= 128)
	self.flags.N = (math.floor(f / 64) % 2 == 1)
	self.flags.H = (math.floor(f / 32) % 2 == 1)
	self.flags.C = (math.floor(f / 16) % 2 == 1)
end

function CPU:get16bit(high, low)
	return (self.registers[high] * 256) + self.registers[low]
end

function CPU:set16bit(high, low, value)
	self.registers[high] = math.floor(value / 256) % 256
	self.registers[low] = value % 256
end

function CPU:push(value)
	self.registers.SP = (self.registers.SP - 1) % 65536
	self.memory:writeByte(self.registers.SP, math.floor(value / 256) % 256)
	self.registers.SP = (self.registers.SP - 1) % 65536
	self.memory:writeByte(self.registers.SP, value % 256)
end

function CPU:pop()
	local low = self.memory:readByte(self.registers.SP)
	self.registers.SP = (self.registers.SP + 1) % 65536
	local high = self.memory:readByte(self.registers.SP)
	self.registers.SP = (self.registers.SP + 1) % 65536
	return (high * 256) + low
end

function CPU:fetch()
	local byte = self.memory:readByte(self.registers.PC)
	self.registers.PC = (self.registers.PC + 1) % 65536
	return byte
end

function CPU:execute(opcode)
	self.cycles = 0
	
	-- Decode and execute opcode
	if opcode == 0x00 then  -- NOP
		self.cycles = 4
	elseif opcode == 0x01 then  -- LD BC, d16
		local low = self:fetch()
		local high = self:fetch()
		self:set16bit("B", "C", (high * 256) + low)
		self.cycles = 12
	elseif opcode == 0x02 then  -- LD (BC), A
		local addr = self:get16bit("B", "C")
		self.memory:writeByte(addr, self.registers.A)
		self.cycles = 8
	elseif opcode == 0x03 then  -- INC BC
		local bc = (self:get16bit("B", "C") + 1) % 65536
		self:set16bit("B", "C", bc)
		self.cycles = 8
	elseif opcode == 0x04 then  -- INC B
		self.registers.B = (self.registers.B + 1) % 256
		self.flags.Z = self.registers.B == 0
		self.flags.N = false
		self.flags.H = (self.registers.B % 16 == 0)
		self:updateFlags()
		self.cycles = 4
	elseif opcode == 0x05 then  -- DEC B
		self.registers.B = (self.registers.B - 1) % 256
		self.flags.Z = self.registers.B == 0
		self.flags.N = true
		self.flags.H = (self.registers.B % 16 == 15)
		self:updateFlags()
		self.cycles = 4
	elseif opcode == 0x06 then  -- LD B, d8
		self.registers.B = self:fetch()
		self.cycles = 8
	elseif opcode == 0x07 then  -- RLCA
		self.flags.C = self.registers.A >= 128
		self.registers.A = ((self.registers.A * 2) % 256) + (self.flags.C and 1 or 0)
		self.flags.Z = false
		self.flags.N = false
		self.flags.H = false
		self:updateFlags()
		self.cycles = 4
	elseif opcode == 0x08 then  -- LD (a16), SP
		local low = self:fetch()
		local high = self:fetch()
		local addr = (high * 256) + low
		self.memory:writeByte(addr, self.registers.SP % 256)
		self.memory:writeByte(addr + 1, math.floor(self.registers.SP / 256))
		self.cycles = 20
	elseif opcode == 0x09 then  -- ADD HL, BC
		local hl = self:get16bit("H", "L")
		local bc = self:get16bit("B", "C")
		local result = (hl + bc) % 65536
		self:set16bit("H", "L", result)
		self.flags.N = false
		self.flags.H = ((hl % 4096) + (bc % 4096)) >= 4096
		self.flags.C = (hl + bc) >= 65536
		self:updateFlags()
		self.cycles = 8
	elseif opcode == 0x0A then  -- LD A, (BC)
		local addr = self:get16bit("B", "C")
		self.registers.A = self.memory:readByte(addr)
		self.cycles = 8
	elseif opcode == 0x0B then  -- DEC BC
		local bc = (self:get16bit("B", "C") - 1) % 65536
		self:set16bit("B", "C", bc)
		self.cycles = 8
	elseif opcode == 0x0C then  -- INC C
		self.registers.C = (self.registers.C + 1) % 256
		self.flags.Z = self.registers.C == 0
		self.flags.N = false
		self.flags.H = (self.registers.C % 16 == 0)
		self:updateFlags()
		self.cycles = 4
	elseif opcode == 0x0D then  -- DEC C
		self.registers.C = (self.registers.C - 1) % 256
		self.flags.Z = self.registers.C == 0
		self.flags.N = true
		self.flags.H = (self.registers.C % 16 == 15)
		self:updateFlags()
		self.cycles = 4
	elseif opcode == 0x0E then  -- LD C, d8
		self.registers.C = self:fetch()
		self.cycles = 8
	elseif opcode == 0x0F then  -- RRCA
		self.flags.C = (self.registers.A % 2 == 1)
		self.registers.A = math.floor(self.registers.A / 2) + (self.flags.C and 128 or 0)
		self.flags.Z = false
		self.flags.N = false
		self.flags.H = false
		self:updateFlags()
		self.cycles = 4
	-- Additional common opcodes
	elseif opcode == 0x20 then  -- JR NZ, r8
		local offset = self:fetch()
		if offset >= 128 then offset = offset - 256 end
		if not self.flags.Z then
			self.registers.PC = (self.registers.PC + offset) % 65536
			self.cycles = 12
		else
			self.cycles = 8
		end
	elseif opcode == 0xC9 then  -- RET
		self.registers.PC = self:pop()
		self.cycles = 16
	elseif opcode == 0xCB then  -- Extended instruction set
		self.cycles = self:executeCB()
	else
		-- Placeholder for unimplemented opcodes
		self.cycles = 4
	end
	
	return self.cycles
end

function CPU:executeCB()
	local opcode = self:fetch()
	-- Implement CB-prefixed instructions
	return 8
end

function CPU:step()
	if not self.halted then
		local opcode = self:fetch()
		self:execute(opcode)
	else
		self.cycles = 4
	end
	return self.cycles
end

return CPU
