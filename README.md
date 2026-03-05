this is the readme of the updated project btw

# Clair

Clair is a controller-first game frontend for Android handhelds, Windows, Mac, and Linux that feels like a console OS.
It helps you decide what to play, keep track of progress, and stay inside a calm, focused gaming space.

Clair is a frontend only.
It does not emulate games.
It launches console-forward emulators and organizes everything around play.

---

## Core Philosophy

- Feels like a console, not a phone
- Controller-first, touch-responsive
- Calm, soft UI that reduces decision fatigue
- Offline-first, no required accounts or servers
- Encourages playing and finishing games

---

## Input Model

Clair is **controller-first**, but fully supports touch.

- Every screen is navigable with a controller.
- Every interactive element responds to touch.
- Touch interaction moves focus to the touched element, so controller use can continue seamlessly.

- Gestures are optional and never required.

---

## Setup

### SteamGridDB Configuration (Optional)

For automatic game cover art:

1. Get a free API key from https://www.steamgriddb.com/profile/preferences/api
2. Open Settings in the app
3. Enter your API key under "SteamGridDB API Key"
4. Click "Save API Key"

Covers will automatically download when you add games, or use "Get Game Covers" to batch-fetch all missing covers.

### Library Directories

Automatically import games from your ROM/game directories:

1. Open Settings → Library Directories
2. Click "Add Directory"
3. Select the folder containing your games
4. Choose the platform (PS Vita, Nintendo 3DS, etc.)
5. Enable "Include subdirectories" if your games are organized in subfolders
6. Click "Scan & Import"

Clair will scan for game files and add them to your library. Use "Refresh" to detect new or removed games.

### RetroArch Setup (Play Flow)

To launch games, configure RetroArch:

1. Install RetroArch for your platform
2. Open Settings → RetroArch Configuration
3. Set `RETROARCH_PATH` (RetroArch executable path)
4. Set `RETROARCH_CORES_PATH` (RetroArch cores folder)

**Supported systems (v1):** NES, SNES, GB, GBC, GBA, PS1
