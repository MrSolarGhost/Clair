# Pending Work

## Emulator/Core Coverage (Deferred)
- Genesis/Mega Drive (Genesis Plus GX)
- Master System / Game Gear (Genesis Plus GX)
- NES alt cores (FCEUmm/Nestopia)
- SNES alt cores (Snes9x 2010/2002)
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

## Emulator Launch Testing (Real)
- Add integration tests that launch RetroArch with a known ROM fixture.
- CI/device setup to install RetroArch and cores.
- Provide ROM fixtures for smoke tests.

## Cover Fetch Tests
- CoverStorageService tests now use MockClient (no network). Consider adding fixture-based success coverage if needed.

## Other App Modules (Doc vs Implementation)
- Home widgets (Continue Playing / Tonight’s Pick)
- Achievements integration (RetroAchievements/Steam/GOG/Epic)
- Friends snapshot + QR import/export
- Profile customization + snapshot

## Completed
- Collections persistence + artwork
- Guides persistence (resume position)
- Notes persistence (scroll position)
