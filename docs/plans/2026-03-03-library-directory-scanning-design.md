# Library Directory Scanning - Design Document

**Date:** 2026-03-03  
**Status:** Approved  
**Feature:** Game library directory management and automatic scanning

---

## Overview

Allow users to add directories containing game files (ROMs, executables) and automatically import them into Clair's library. Support re-scanning to detect new/removed games while preserving user data.

---

## Requirements

1. User can add multiple directories, each mapped to a specific platform/system
2. Each directory can be scanned recursively or top-level only
3. Filenames are automatically converted to readable titles
4. Re-scanning detects new files and missing files
5. Missing files are marked but not deleted (preserves user data)
6. Duplicate detection prevents re-importing existing games
7. User can manually refresh each directory

---

## Database Schema

### New Table: `library_directories`

```sql
CREATE TABLE library_directories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT NOT NULL,              -- Absolute path to directory
  system TEXT NOT NULL,             -- Platform (PS Vita, Nintendo 3DS, etc.)
  scan_recursive INTEGER NOT NULL,  -- 1 = scan subdirs, 0 = top level only
  last_scanned_at INTEGER,          -- Timestamp of last scan
  created_at INTEGER NOT NULL
)
```

### Modify `games` Table

Add two new columns:

```sql
ALTER TABLE games ADD COLUMN source_directory_id INTEGER;
ALTER TABLE games ADD COLUMN file_status INTEGER DEFAULT 0;

FOREIGN KEY (source_directory_id) REFERENCES library_directories(id) ON DELETE SET NULL;
```

Where `file_status`:
- `0` = file available
- `1` = file missing

---

## Services Architecture

### 1. DirectoryScannerService

**Responsibility:** Scan filesystem and parse filenames into game data.

**Key Methods:**
```dart
Future<List<DiscoveredGame>> scanDirectory(String path, bool recursive)
String parseTitle(String filename)
```

**Title Parsing Logic:**
```dart
String parseTitle(String filename) {
  // Remove extension
  final nameWithoutExt = path.basenameWithoutExtension(filename);
  
  // Replace dashes, underscores, dots with spaces
  final cleaned = nameWithoutExt
    .replaceAll(RegExp(r'[-_.]'), ' ')
    .trim();
  
  // Title case each word
  return cleaned.split(' ')
    .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
    .join(' ');
}

// Example: "atelier-ryza.vpk" → "Atelier Ryza"
```

**File Extension Filtering:**
Only scan files with known game extensions:
- `.vpk`, `.nds`, `.3ds`, `.cia`
- `.iso`, `.cue`, `.bin`, `.mds`
- `.exe`, `.elf`, `.dol`
- `.rom`, `.z64`, `.n64`
- `.gba`, `.nds`, `.gb`, `.gbc`

Ignore: `.txt`, `.jpg`, `.png`, `.nfo`, `.xml`, etc.

---

### 2. LibraryDirectoryService

**Responsibility:** CRUD for library directories and orchestrate scanning.

**Key Methods:**
```dart
Future<LibraryDirectory> addDirectory(String path, String system, bool recursive)
Future<void> refreshDirectory(int directoryId)
Future<void> removeDirectory(int directoryId)
Future<List<LibraryDirectory>> getAllDirectories()
```

**Add Directory Flow:**
1. Validate path exists and is readable
2. Save to `library_directories` table
3. Call `DirectoryScannerService.scanDirectory()`
4. Bulk-insert discovered games via `DatabaseService`
5. Trigger SteamGridDB cover fetch for new games
6. Update `last_scanned_at`

**Refresh Directory Flow:**
1. Load directory from DB
2. Scan filesystem again
3. Match discovered files against existing games by `executablePath` + `source_directory_id`
4. **New files:** Add as new games
5. **Missing files:** Set `file_status = 1` (missing) but keep in library
6. **Existing files:** No action (preserves user metadata)

---

### 3. DatabaseService Updates

Add methods for:
```dart
// Library directories
Future<int> insertLibraryDirectory(LibraryDirectory dir)
Future<LibraryDirectory?> getLibraryDirectory(int id)
Future<List<LibraryDirectory>> getAllLibraryDirectories()
Future<void> deleteLibraryDirectory(int id)

// Bulk game operations
Future<void> bulkInsertGames(List<Game> games)
Future<void> markGameMissing(int gameId)
Future<List<Game>> getGamesBySourceDirectory(int directoryId)
```

---

## User Interface

### Settings Screen - Library Directories Section

Add new section below SteamGridDB API settings:

```
Library Directories
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[+ Add Directory]

╭─────────────────────────────────────╮
│ PS Vita                             │
│ /home/user/ROMs/vita                │
│ Subdirectories: Yes                 │
│ Last scanned: 2 hours ago           │
│ 23 games                            │
│                                     │
│ [Refresh] [Remove]                  │
╰─────────────────────────────────────╯

╭─────────────────────────────────────╮
│ Nintendo 3DS                        │
│ /home/user/ROMs/3ds                 │
│ Subdirectories: No                  │
│ Last scanned: Never                 │
│ 0 games                             │
│                                     │
│ [Refresh] [Remove]                  │
╰─────────────────────────────────────╯
```

### Add Directory Dialog

Modal with 4 steps:

1. **Select Directory:** File picker button
2. **Select Platform:** Dropdown with platforms:
   - PC (Windows)
   - PC (Linux)
   - PC (Mac)
   - Steam
   - GOG
   - Epic Games
   - PlayStation Vita
   - Nintendo 3DS
   - Nintendo Switch
   - GameCube
   - Wii
   - PlayStation 2
   - Xbox
   - Xbox 360
   - Custom...
3. **Scan Options:** Checkbox "Include subdirectories"
4. **Action:** [Scan & Import] button

**Progress Indicator:**
Show while scanning: "Scanning... 142 files found"

**Success Message:**
"Found 23 games, imported 23 new"

---

## Re-scan & Duplicate Detection

### Duplicate Detection
Match by `executablePath`:
- Query: `SELECT id FROM games WHERE executablePath = ? AND source_directory_id = ?`
- If match found → skip (already imported)
- If no match → new game, import it

### Missing File Detection
During refresh:
1. Get all games with `source_directory_id = X`
2. Check if `executablePath` exists on filesystem
3. If missing → `UPDATE games SET file_status = 1 WHERE id = ?`
4. If present → `UPDATE games SET file_status = 0 WHERE id = ?` (in case it was re-added)

---

## Error Handling

### Permission Errors
- If directory not readable: Show error "Cannot access directory. Check permissions."
- Don't crash, just notify user

### Empty Directories
- If no game files found: Show "No game files found in this directory."
- Still save directory to DB (user might add files later)

### Invalid Paths
- Validate directory exists before saving
- If deleted after being added, mark all games as missing on next refresh

### Large Directories
- Show progress: "Scanning... 142 files found"
- Consider async scanning to avoid blocking UI

---

## Data Preservation

**Philosophy:** Never delete user data automatically.

When a game file is missing:
- Keep game in library
- Mark `file_status = 1`
- Preserve: playtime, status, notes, achievements, collections
- User can manually delete if desired
- If file reappears on re-scan, restore `file_status = 0`

**Rationale:**
- ROMs get moved around
- External drives get disconnected
- Users reorganize directories
- Losing playtime/notes is worse than seeing a "missing" indicator

---

## Testing Strategy

### Unit Tests
- `DirectoryScannerService.parseTitle()` - various filename formats
- `DirectoryScannerService.scanDirectory()` - recursive vs non-recursive
- `LibraryDirectoryService.refreshDirectory()` - detect new/missing files

### Integration Tests
- Add directory → scan → verify games in DB
- Re-scan → verify duplicates not created
- Re-scan → verify missing files marked correctly

### Manual Testing
- Test with real ROM directories
- Test with nested subdirectories
- Test permission errors
- Test very large directories (1000+ files)

---

## Future Enhancements (Not in Scope)

- Auto-detect platform from file extensions
- IGDB/SteamGridDB title matching
- Auto-scan on app startup
- Watch directories for filesystem changes
- Bulk edit/delete operations
- Import from other launcher databases (Steam, Lutris, etc.)

---

## Approved By

Guillermo - 2026-03-03
