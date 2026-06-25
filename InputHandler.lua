-- Input Handler for Game Boy Emulator
-- Manages keyboard/controller input mapping to Game Boy joypad

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new(gameBoy)
	local self = setmetatable({}, InputHandler)
	
	self.gameBoy = gameBoy
	self.enabled = true
	
	-- Key mappings
	self.keyBindings = {
		-- Arrow keys for D-Pad
		[Enum.KeyCode.Up] = "up",
		[Enum.KeyCode.Down] = "down",
		[Enum.KeyCode.Left] = "left",
		[Enum.KeyCode.Right] = "right",
		
		-- Z for A button
		[Enum.KeyCode.Z] = "a",
		-- X for B button
		[Enum.KeyCode.X] = "b",
		-- Enter for Start
		[Enum.KeyCode.Return] = "start",
		-- Backspace for Select
		[Enum.KeyCode.BackSpace] = "select",
	}
	
	-- Input state tracking
	self.inputState = {
		up = false,
		down = false,
		left = false,
		right = false,
		a = false,
		b = false,
		start = false,
		select = false,
	}
	
	return self
end

function InputHandler:connect()
	local UserInputService = game:GetService("UserInputService")
	
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if not self.enabled then return end
		
		local button = self.keyBindings[input.KeyCode]
		if button then
			self.inputState[button] = true
			self.gameBoy:setJoypadInput(button, true)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		local button = self.keyBindings[input.KeyCode]
		if button then
			self.inputState[button] = false
			self.gameBoy:setJoypadInput(button, false)
		end
	end)
end

function InputHandler:setKeyBinding(keyCode, button)
	self.keyBindings[keyCode] = button
end

function InputHandler:setEnabled(enabled)
	self.enabled = enabled
end

function InputHandler:getInputState()
	return self.inputState
end

return InputHandler
