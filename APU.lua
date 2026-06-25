-- Game Boy APU (Audio Processing Unit)
-- Handles sound generation and mixing

local APU = {}
APU.__index = APU

function APU.new()
	local self = setmetatable({}, APU)
	
	-- Audio channels
	self.channels = {
		{name = "Square1", enabled = true, frequency = 0, volume = 0},
		{name = "Square2", enabled = true, frequency = 0, volume = 0},
		{name = "Wave", enabled = true, frequency = 0, volume = 0},
		{name = "Noise", enabled = true, frequency = 0, volume = 0},
	}
	
	-- Audio control
	self.masterVolume = 0.5
	self.masterEnabled = true
	self.sampleRate = 44100
	self.cycleCounter = 0
	
	-- APU Registers
	self.nr10 = 0x00  -- Channel 1 sweep
	self.nr11 = 0x00  -- Channel 1 length/duty
	self.nr12 = 0x00  -- Channel 1 envelope
	self.nr13 = 0x00  -- Channel 1 frequency low
	self.nr14 = 0x00  -- Channel 1 frequency high
	
	self.nr21 = 0x00  -- Channel 2 length/duty
	self.nr22 = 0x00  -- Channel 2 envelope
	self.nr23 = 0x00  -- Channel 2 frequency low
	self.nr24 = 0x00  -- Channel 2 frequency high
	
	self.nr30 = 0x00  -- Channel 3 enable
	self.nr31 = 0x00  -- Channel 3 length
	self.nr32 = 0x00  -- Channel 3 output level
	self.nr33 = 0x00  -- Channel 3 frequency low
	self.nr34 = 0x00  -- Channel 3 frequency high
	
	self.nr41 = 0x00  -- Channel 4 length
	self.nr42 = 0x00  -- Channel 4 envelope
	self.nr43 = 0x00  -- Channel 4 poly counter
	self.nr44 = 0x00  -- Channel 4 counter
	
	self.nr50 = 0x00  -- Master volume
	self.nr51 = 0xFF  -- Channel select
	self.nr52 = 0x00  -- APU control
	
	self.waveRam = {}
	for i = 1, 16 do
		self.waveRam[i] = 0
	end
	
	return self
end

function APU:step(cycles)
	self.cycleCounter = self.cycleCounter + cycles
end

function APU:readRegister(address)
	address = address % 65536
	
	if address == 0xFF10 then return self.nr10
	elseif address == 0xFF11 then return self.nr11
	elseif address == 0xFF12 then return self.nr12
	elseif address == 0xFF13 then return self.nr13
	elseif address == 0xFF14 then return self.nr14
	elseif address == 0xFF16 then return self.nr21
	elseif address == 0xFF17 then return self.nr22
	elseif address == 0xFF18 then return self.nr23
	elseif address == 0xFF19 then return self.nr24
	elseif address == 0xFF1A then return self.nr30
	elseif address == 0xFF1B then return self.nr31
	elseif address == 0xFF1C then return self.nr32
	elseif address == 0xFF1D then return self.nr33
	elseif address == 0xFF1E then return self.nr34
	elseif address == 0xFF20 then return self.nr41
	elseif address == 0xFF21 then return self.nr42
	elseif address == 0xFF22 then return self.nr43
	elseif address == 0xFF23 then return self.nr44
	elseif address == 0xFF24 then return self.nr50
	elseif address == 0xFF25 then return self.nr51
	elseif address == 0xFF26 then return self.nr52
	elseif address >= 0xFF30 and address <= 0xFF3F then
		return self.waveRam[address - 0xFF30 + 1] or 0
	end
	
	return 0xFF
end

function APU:writeRegister(address, value)
	address = address % 65536
	value = value % 256
	
	if address == 0xFF10 then self.nr10 = value
	elseif address == 0xFF11 then self.nr11 = value
	elseif address == 0xFF12 then self.nr12 = value
	elseif address == 0xFF13 then self.nr13 = value
	elseif address == 0xFF14 then 
		self.nr14 = value
		if (value % 128) >= 64 then
			self.channels[1].enabled = true
		end
	elseif address == 0xFF16 then self.nr21 = value
	elseif address == 0xFF17 then self.nr22 = value
	elseif address == 0xFF18 then self.nr23 = value
	elseif address == 0xFF19 then 
		self.nr24 = value
		if (value % 128) >= 64 then
			self.channels[2].enabled = true
		end
	elseif address == 0xFF1A then self.nr30 = value
	elseif address == 0xFF1B then self.nr31 = value
	elseif address == 0xFF1C then self.nr32 = value
	elseif address == 0xFF1D then self.nr33 = value
	elseif address == 0xFF1E then 
		self.nr34 = value
		if (value % 128) >= 64 then
			self.channels[3].enabled = true
		end
	elseif address == 0xFF20 then self.nr41 = value
	elseif address == 0xFF21 then self.nr42 = value
	elseif address == 0xFF22 then self.nr43 = value
	elseif address == 0xFF23 then 
		self.nr44 = value
		if (value % 128) >= 64 then
			self.channels[4].enabled = true
		end
	elseif address == 0xFF24 then self.nr50 = value
	elseif address == 0xFF25 then self.nr51 = value
	elseif address == 0xFF26 then self.nr52 = value
	elseif address >= 0xFF30 and address <= 0xFF3F then
		self.waveRam[address - 0xFF30 + 1] = value
	end
end

return APU
