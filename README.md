# Game Boy Emulator for Roblox Studio

A full-featured Game Boy emulator written in Lua and integrated with Roblox Studio. This emulator can run Game Boy ROM files within Roblox games.

## Features

- **Full CPU Emulation**: Z80-compatible instruction set with 255+ opcodes
- **Memory Management**: Complete memory mapping including ROM, RAM, VRAM, and I/O registers
- **Graphics Rendering**: Accurate PPU (Picture Processing Unit) implementation
  - Tile-based background rendering
  - Sprite rendering with transparency
  - Scanline rendering
  - LCD status modes (HBlank, VBlank, OAM search, Pixel transfer)
- **Audio System**: APU (Audio Processing Unit) with sound register support
- **Input Handling**: Full joypad support with customizable key bindings
- **ROM Loading**: Cartridge detection and ROM header parsing
- **Roblox Integration**: Real-time display rendering using Roblox GUI

## File Structure

```
├── GameBoy.lua           # Main emulator orchestrator
├── CPU.lua              # Z80 CPU implementation
├── MMU.lua              # Memory Management Unit
├── GPU.lua              # Graphics Processing Unit (PPU)
├── APU.lua              # Audio Processing Unit
├── DisplayRenderer.lua  # Roblox GUI renderer
├── InputHandler.lua     # Keyboard input handler
├── ROMLoader.lua        # ROM file parser and validator
├── RobloxMain.lua       # Roblox integration script
└── README.md            # This file
```

## Components

### CPU.lua
- Implements Z80 instruction set
- Manages registers (A, B, C, D, E, F, H, L, SP, PC)
- Handles flags (Zero, Subtract, Half-carry, Carry)
- Stack operations (push/pop)
- Interrupt handling

### MMU.lua
- Maps entire Game Boy memory space (0x0000-0xFFFF)
- ROM banking support
- External RAM banking
- I/O register access
- Echo RAM handling

### GPU.lua
- Renders scanlines to framebuffer
- Tile data processing
- Background layer rendering
- Sprite rendering with OAM
- LCD mode cycling (HBlank, VBlank, OAM search, Pixel transfer)
- Palette color mapping

### APU.lua
- 4 audio channels (Square1, Square2, Wave, Noise)
- Envelope control
- Frequency modulation
- Volume control
- Wave RAM management

### DisplayRenderer.lua
- Converts framebuffer to Roblox GUI pixels
- Scalable pixel display (configurable size)
- Real-time frame updates
- Color mapping from grayscale

### InputHandler.lua
- Keyboard input capture
- Joypad button mapping
- Customizable key bindings
- Default controls:
  - Arrow Keys = D-Pad
  - Z = A Button
  - X = B Button
  - Enter = Start
  - Backspace = Select

### ROMLoader.lua
- ROM header parsing
- Cartridge type detection
- ROM/RAM size calculation
- ROM validation

## Usage in Roblox Studio

1. **Create a LocalScript** in `StarterPlayer.StarterCharacterScripts` or `StarterGui`

2. **Add the emulator modules** to the script:
   - Create a Folder named "GameBoyModules"
   - Add all .lua files as ModuleScripts inside

3. **Load a Game Boy ROM**:
   ```lua
   local emulator = GameBoy.new()
   local romData = -- load your ROM file bytes here
   emulator:loadROM(romData)
   emulator:run()
   ```

4. **The emulator will**:
   - Display a 160x144 Game Boy screen in the GUI
   - Process input from keyboard
   - Run the ROM at approximately 60 FPS

## Controls

| Key | Function |
|-----|----------|
| ↑ | D-Pad Up |
| ↓ | D-Pad Down |
| ← | D-Pad Left |
| → | D-Pad Right |
| Z | A Button |
| X | B Button |
| Enter | Start Button |
| Backspace | Select Button |

## Performance Notes

- The emulator runs at approximately 60 FPS in Roblox
- Each frame processes ~70,224 CPU cycles
- GPU rendering is optimized for Roblox GUI performance
- Consider using pixel scaling (pixelSize) for better visual quality vs performance

## Limitations

- This is a simplified emulator for demonstration purposes
- Not all Game Boy games may run perfectly
- Some advanced cartridge features (MBC3 RTC, etc.) have basic support
- Sound output is system-dependent (APU registers are supported but audio output requires custom audio API)
- Some edge cases in CPU instruction handling may exist

## Future Improvements

- [ ] Full MBC cartridge support
- [ ] Accurate cycle timing
- [ ] Save state functionality
- [ ] Debugger integration
- [ ] Color Game Boy (CGB) support
- [ ] More optimized rendering
- [ ] Sound output implementation
- [ ] Game selection UI

## Technical Details

### Memory Mapping

```
0x0000-0x00FF: Bootstrap ROM (256 bytes)
0x0100-0x7FFF: Game ROM (32KB)
0x8000-0x9FFF: Video RAM (8KB)
0xA000-0xBFFF: External RAM (8KB) - Cartridge RAM
0xC000-0xDFFF: Internal RAM (8KB)
0xE000-0xFDFF: Echo of Internal RAM (7680 bytes)
0xFE00-0xFE9F: OAM - Sprite Table (160 bytes)
0xFEA0-0xFEFF: Unusable (96 bytes)
0xFF00-0xFF7F: I/O Registers (128 bytes)
0xFF80-0xFFFE: High RAM (127 bytes)
0xFFFF: Interrupt Enable Register (1 byte)
```

### CPU Timing

- CPU Frequency: 4.19 MHz
- Frame Rate: 59.7 Hz (~60 FPS)
- Cycles per Frame: 70,224

### GPU Modes

- **Mode 0 (HBlank)**: 204 CPU cycles
- **Mode 1 (VBlank)**: 4,560 CPU cycles (10 lines × 456 cycles)
- **Mode 2 (OAM Search)**: 80 CPU cycles
- **Mode 3 (Pixel Transfer)**: 172 CPU cycles

## License

This emulator is provided as-is for educational and entertainment purposes.

## Credits

Created for use with Roblox Studio. Based on Game Boy technical documentation and emulator specifications.
