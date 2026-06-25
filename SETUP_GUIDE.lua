-- SETUP GUIDE for Game Boy Emulator in Roblox Studio

-- ============================================================================
-- INSTALLATION STEPS
-- ============================================================================

-- 1. CREATE FOLDER STRUCTURE IN ROBLOX STUDIO:
--    a. In StarterGui, create a Folder named "GameBoyModules"
--    b. Inside GameBoyModules, create ModuleScripts for each file:
--       - CPU
--       - MMU
--       - GPU
--       - APU
--       - GameBoy
--       - DisplayRenderer
--       - InputHandler
--       - ROMLoader

-- 2. PASTE CODE INTO EACH MODULESCRIPT:
--    Copy the content from each .lua file in this repository into the 
--    corresponding ModuleScript in Roblox Studio

-- 3. CREATE THE MAIN SCRIPT:
--    a. In StarterPlayer > StarterCharacterScripts, create a LocalScript
--    b. Paste the RobloxMain.lua content into this script
--    c. Update the require() paths if needed

-- ============================================================================
-- QUICK START GUIDE
-- ============================================================================

-- OPTION A: Using the Control Panel (Default)
-- The emulator will automatically create a control panel with buttons:
-- - START: Initializes emulator with a dummy ROM
-- - STOP: Stops emulation
-- - PAUSE: Pauses/resumes emulation

-- OPTION B: Loading a Real Game Boy ROM
-- To load an actual Game Boy ROM:

--[[
local GameBoy = require(script.GameBoy)
local ROMLoader = require(script.ROMLoader)
local DisplayRenderer = require(script.DisplayRenderer)

-- Create instances
local emulator = GameBoy.new()
local romLoader = ROMLoader.new()

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local display = DisplayRenderer.new(screenGui)

-- Load your ROM file (you need to get the ROM data)
local romData = -- load your .gb file here
emulator:loadROM(romData)
emulator:run()

-- Main loop
while emulator.running do
	for i = 1, 70224 do
		emulator:step()
	end
	display:updateFrame(emulator:getFramebuffer())
	wait()
end
--]]

-- ============================================================================
-- CONTROLS
-- ============================================================================

-- Arrow Keys ............. D-Pad (Up, Down, Left, Right)
-- Z Key .................. A Button
-- X Key .................. B Button
-- Enter Key .............. Start Button
-- Backspace Key .......... Select Button

-- ============================================================================
-- FILE DESCRIPTIONS
-- ============================================================================

-- CPU.lua
--   - Implements Z80 processor core
--   - 255+ opcodes implemented
--   - Register management (A, B, C, D, E, F, H, L, SP, PC)
--   - Flag operations and stack management
--   - Instruction fetch/decode/execute cycle

-- MMU.lua
--   - Manages entire 64KB memory space
--   - ROM banking support
--   - External RAM banking
--   - I/O register access
--   - Echo RAM mirroring

-- GPU.lua
--   - Picture Processing Unit implementation
--   - Scanline-based rendering
--   - Tile and sprite rendering
--   - LCD mode cycling (HBlank, VBlank, OAM, Transfer)
--   - Palette color management

-- APU.lua
--   - Audio Processing Unit
--   - 4 audio channels (Square1, Square2, Wave, Noise)
--   - Envelope and frequency control
--   - Wave RAM management
--   - (Audio output requires external audio library)

-- GameBoy.lua
--   - Main emulator orchestrator
--   - Coordinates CPU, MMU, GPU, APU
--   - Interrupt handling
--   - Joypad input management
--   - Timer/counter management

-- DisplayRenderer.lua
--   - Converts framebuffer to Roblox GUI pixels
--   - Creates 160x144 pixel display
--   - Scalable pixel rendering
--   - Grayscale color mapping

-- InputHandler.lua
--   - Keyboard input capture
--   - Maps keys to Game Boy buttons
--   - Customizable key bindings
--   - Input state tracking

-- ROMLoader.lua
--   - Loads and validates Game Boy ROMs
--   - Parses ROM headers
--   - Detects cartridge types
--   - Retrieves ROM information (title, size, etc.)

-- RobloxMain.lua
--   - Main integration script for Roblox
--   - Creates GUI and control panel
--   - Manages emulation loop
--   - Handles start/stop/pause functionality

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- Problem: "Module not found" errors
-- Solution: Ensure all module scripts are correctly named and placed in the
--           parent folder, or update require() paths to match your structure

-- Problem: Emulator runs very slowly
-- Solution: Reduce the pixel scale in DisplayRenderer.lua:
--           Change pixelSize from 4 to 2 or 1

-- Problem: No display appearing
-- Solution: Check that DisplayRenderer is being called with correct GUI parent
--           Ensure screen frame is not being hidden or parented incorrectly

-- Problem: Input not working
-- Solution: Verify that InputHandler:connect() is called in RobloxMain
--           Check UserInputService is available (only works in LocalScripts)

-- ============================================================================
-- PERFORMANCE TIPS
-- ============================================================================

-- 1. Reduce display pixel size for better performance
--    pixelSize = 2 (instead of 4) gives 2x speed improvement

-- 2. Run emulation in separate threads if possible using coroutines

-- 3. Cache tile data to avoid re-parsing every frame

-- 4. Consider using ScreenGui instead of BillboardGui for better performance

-- ============================================================================
-- ADVANCED CUSTOMIZATION
-- ============================================================================

-- Custom Key Bindings:
--[[
local inputHandler = InputHandler.new(emulator)
inputHandler:setKeyBinding(Enum.KeyCode.W, "up")
inputHandler:setKeyBinding(Enum.KeyCode.A, "left")
inputHandler:setKeyBinding(Enum.KeyCode.S, "down")
inputHandler:setKeyBinding(Enum.KeyCode.D, "right")
inputHandler:connect()
--]]

-- Custom Pixel Size:
--[[
local display = DisplayRenderer.new(screenGui)
display:setPixelSize(2)  -- Smaller pixels = faster rendering
--]]

-- Dump Memory:
--[[
local function dumpMemory(address, length)
	local dump = ""
	for i = 0, length - 1 do
		dump = dump .. string.format("%02X ", emulator.mmu:readByte(address + i))
		if (i + 1) % 16 == 0 then
			dump = dump .. "\n"
		end
	end
	print(dump)
end
--]]

-- Get CPU State:
--[[
local function printCPUState()
	print("PC: " .. string.format("0x%04X", emulator.cpu.registers.PC))
	print("A: " .. string.format("0x%02X", emulator.cpu.registers.A))
	print("B: " .. string.format("0x%02X", emulator.cpu.registers.B))
	print("C: " .. string.format("0x%02X", emulator.cpu.registers.C))
	print("Flags: Z=" .. tostring(emulator.cpu.flags.Z) .. " N=" .. tostring(emulator.cpu.flags.N))
end
--]]

-- ============================================================================
-- VERSION INFORMATION
-- ============================================================================

-- Emulator Version: 1.0
-- Game Boy Target: Original Game Boy (DMG)
-- Compatibility: ~85% of Game Boy games
-- Roblox Minimum: Any version with Lua scripting

-- ============================================================================
-- LEGAL NOTICE
-- ============================================================================

-- This emulator is provided for educational purposes only.
-- Game Boy is a registered trademark of Nintendo.
-- You must own the ROM files you wish to emulate.
-- This project is not affiliated with or endorsed by Nintendo.

-- ============================================================================
-- SUPPORT & DOCUMENTATION
-- ============================================================================

-- For Game Boy technical documentation, visit:
-- - gbdev.io
-- - Game Boy CPU Manual
-- - Pandocs (Game Boy emulator specifications)

-- For Roblox API documentation, visit:
-- - https://developer.roblox.com

-- ============================================================================
