# Emulator Integration Design

## Goal
Enable a full “select game → launch” flow using a RetroArch-first emulator abstraction layer.

## Selected Approach
Emulator abstraction layer with a RetroArch adapter first, plus a configurable core matrix for v1 systems.

## Architecture
- EmulatorAdapter interface (launch, validate, supported systems).
- RetroArchAdapter as first implementation.
- EmulatorRegistry resolves system → adapter (RetroArch for v1).
- CoreMatrix config for v1 systems (NES, SNES, GB, GBC, GBA, PS1).
- Settings UI to configure RetroArch path/package and default cores.
- GameCard “Launch” uses EmulatorRegistry → adapter.

## Components
- **EmulatorAdapter**: `launch(Game)`, `validate()`, `supportedSystems`.
- **RetroArchAdapter**: builds command/intent for RetroArch + core + ROM.
- **EmulatorRegistry**: system → adapter mapping.
- **CoreMatrix config**: system → core id + extensions.
- **Settings UI**: configure RetroArch path/package per OS and default cores.
- **Launch hook**: GameCard “Launch” uses registry.

## Data Flow
1. User selects ROM folder + system in Library Directories.
2. Scanner imports games with system + executablePath.
3. GameCard “Launch” → EmulatorRegistry → RetroArchAdapter.
4. Adapter validates RetroArch path/package; if missing, show error.
5. Adapter builds launch command/intent using core from CoreMatrix + ROM path.

## Error Handling
- Missing RetroArch path/package → show “RetroArch not configured” with Settings CTA.
- Unsupported system → show “No emulator configured.”
- ROM missing → show “File missing.”

## Testing
- Unit tests for CoreMatrix (system → core + extensions).
- Adapter tests for command/intent construction (no actual launch).

## Deferred Systems (log for later)
- Genesis/Mega Drive (Genesis Plus GX)
- Master System / Game Gear (Genesis Plus GX)
- NES (alt cores: FCEUmm/Nestopia)
- SNES (alt cores: Snes9x 2010/2002)
- PSP (PPSSPP core)
- N64 (Mupen64Plus-Next)
- Dreamcast (Flycast)
- Saturn (Beetle Saturn)
- Arcade (FinalBurn Neo / MAME)
- Atari 2600/5200/7800 (Stella / Atari800)
- DS (MelonDS)
- 3DS (Citra)
- PS2 (PCSX2, likely standalone)
- GameCube/Wii (Dolphin, likely standalone)
- Switch (standalone)
