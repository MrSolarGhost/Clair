# Library Directory Scanning Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Allow users to add game directories (ROMs, executables) and automatically scan/import them into Clair's library with re-scan support.

**Architecture:** Three-service architecture - DirectoryScannerService (filesystem scanning), LibraryDirectoryService (directory management), DatabaseService (persistence). UI in Settings screen with add/refresh/remove per directory.

**Tech Stack:** Flutter, Dart, SQLite (sqflite), path_provider, file_picker

---

## Task 1: Database Migration

**Files:**
- Modify: `lib/services/database_service.dart`

**Step 1: Add migration to version 3**

Locate the `_initDatabase` method and change version to 3:

```dart
return await openDatabase(
  path,
  version: 3,  // Changed from 2
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
);
```

**Step 2: Update onCreate to include new table**

In `_onCreate`, add after the cover_fetch_queue table:

```dart
// Library directories table
await db.execute('''
  CREATE TABLE library_directories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT NOT NULL,
    system TEXT NOT NULL,
    scan_recursive INTEGER NOT NULL,
    last_scanned_at INTEGER,
    created_at INTEGER NOT NULL
  )
''');
```

**Step 3: Update onCreate for games table columns**

In the games table CREATE statement, add two new columns at the end:

```dart
CREATE TABLE games (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  system TEXT,
  genre TEXT,
  status INTEGER NOT NULL DEFAULT 0,
  coverPath TEXT,
  executablePath TEXT,
  lastPlayed INTEGER,
  playTimeMinutes INTEGER NOT NULL DEFAULT 0,
  addedDate INTEGER NOT NULL,
  isFavorite INTEGER NOT NULL DEFAULT 0,
  completionPercentage REAL,
  source_directory_id INTEGER,
  file_status INTEGER DEFAULT 0,
  FOREIGN KEY (source_directory_id) REFERENCES library_directories (id) ON DELETE SET NULL
)
```

**Step 4: Add onUpgrade handler for migration**

Replace the existing `_onUpgrade` method:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add cover fetch queue (existing migration)
    await db.execute('''
      CREATE TABLE cover_fetch_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        next_retry_at INTEGER,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');
  }
  
  if (oldVersion < 3) {
    // Add library directories table
    await db.execute('''
      CREATE TABLE library_directories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL,
        system TEXT NOT NULL,
        scan_recursive INTEGER NOT NULL,
        last_scanned_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Add new columns to games table
    await db.execute('ALTER TABLE games ADD COLUMN source_directory_id INTEGER');
    await db.execute('ALTER TABLE games ADD COLUMN file_status INTEGER DEFAULT 0');
  }
}
```

**Step 5: Test migration**

Run: `flutter clean && flutter run` (will drop and recreate database)
Expected: App starts without errors

**Step 6: Commit**

```bash
git add lib/services/database_service.dart
git commit -m "feat(db): add library_directories table and game tracking columns"
```

---

## Task 2: Create LibraryDirectory Model

**Files:**
- Create: `lib/models/library_directory.dart`

**Step 1: Create model file**

```dart
/// Represents a tracked directory for automatic game import
class LibraryDirectory {
  final int? id;
  final String path;
  final String system;
  final bool scanRecursive;
  final DateTime? lastScannedAt;
  final DateTime createdAt;

  LibraryDirectory({
    this.id,
    required this.path,
    required this.system,
    required this.scanRecursive,
    this.lastScannedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'system': system,
      'scan_recursive': scanRecursive ? 1 : 0,
      'last_scanned_at': lastScannedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from SQLite Map
  factory LibraryDirectory.fromMap(Map<String, dynamic> map) {
    return LibraryDirectory(
      id: map['id'] as int?,
      path: map['path'] as String,
      system: map['system'] as String,
      scanRecursive: map['scan_recursive'] == 1,
      lastScannedAt: map['last_scanned_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_scanned_at'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Create copy with updated fields
  LibraryDirectory copyWith({
    int? id,
    String? path,
    String? system,
    bool? scanRecursive,
    DateTime? lastScannedAt,
    DateTime? createdAt,
  }) {
    return LibraryDirectory(
      id: id ?? this.id,
      path: path ?? this.path,
      system: system ?? this.system,
      scanRecursive: scanRecursive ?? this.scanRecursive,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/models/library_directory.dart
git commit -m "feat(models): add LibraryDirectory model"
```

---

## Task 3: Create DiscoveredGame Model

**Files:**
- Create: `lib/models/discovered_game.dart`

**Step 1: Create model for scan results**

```dart
/// Represents a game discovered during directory scan (not yet in database)
class DiscoveredGame {
  final String title;
  final String executablePath;
  final String system;

  DiscoveredGame({
    required this.title,
    required this.executablePath,
    required this.system,
  });
}
```

**Step 2: Commit**

```bash
git add lib/models/discovered_game.dart
git commit -m "feat(models): add DiscoveredGame for scan results"
```

---

## Task 4: Create DirectoryScannerService

**Files:**
- Create: `lib/services/directory_scanner_service.dart`
- Create: `test/services/directory_scanner_service_test.dart`

**Step 1: Write failing test for title parsing**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:clair/services/directory_scanner_service.dart';

void main() {
  group('DirectoryScannerService', () {
    late DirectoryScannerService service;

    setUp(() {
      service = DirectoryScannerService();
    });

    test('parseTitle removes extension and formats title', () {
      expect(service.parseTitle('atelier-ryza.vpk'), 'Atelier Ryza');
      expect(service.parseTitle('sonic_adventure_2.iso'), 'Sonic Adventure 2');
      expect(service.parseTitle('mario.kart.8.nsp'), 'Mario Kart 8');
      expect(service.parseTitle('ZELDA_BOTW.xci'), 'Zelda Botw');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/directory_scanner_service_test.dart`
Expected: FAIL with "DirectoryScannerService not defined"

**Step 3: Implement DirectoryScannerService**

```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/discovered_game.dart';

/// Scans directories for game files and parses them into DiscoveredGame objects
class DirectoryScannerService {
  /// Supported game file extensions
  static const supportedExtensions = {
    // PlayStation Vita
    'vpk',
    // Nintendo 3DS
    'cia', '3ds', '3dsx',
    // Nintendo Switch
    'nsp', 'xci',
    // Disc images
    'iso', 'cue', 'bin', 'mds', 'mdf',
    // Executables
    'exe', 'elf', 'dol',
    // Cartridge ROMs
    'rom', 'z64', 'n64', 'gba', 'nds', 'gb', 'gbc',
  };

  /// Scan a directory for game files
  Future<List<DiscoveredGame>> scanDirectory(
    String directoryPath,
    String system,
    bool recursive,
  ) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw DirectoryNotFoundException('Directory not found: $directoryPath');
    }

    final files = <FileSystemEntity>[];
    
    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && _isGameFile(entity.path)) {
          files.add(entity);
        }
      }
    } else {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File && _isGameFile(entity.path)) {
          files.add(entity);
        }
      }
    }

    return files.map((file) {
      final filename = path.basename(file.path);
      return DiscoveredGame(
        title: parseTitle(filename),
        executablePath: file.path,
        system: system,
      );
    }).toList();
  }

  /// Check if file has a supported game extension
  bool _isGameFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (ext.isEmpty) return false;
    final extWithoutDot = ext.substring(1); // Remove leading dot
    return supportedExtensions.contains(extWithoutDot);
  }

  /// Parse filename into readable game title
  String parseTitle(String filename) {
    // Remove extension
    final nameWithoutExt = path.basenameWithoutExtension(filename);
    
    // Replace dashes, underscores, dots with spaces
    final cleaned = nameWithoutExt
        .replaceAll(RegExp(r'[-_.]'), ' ')
        .trim();
    
    // Title case each word
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  
  @override
  String toString() => message;
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/directory_scanner_service_test.dart`
Expected: PASS

**Step 5: Add test for file filtering**

In `test/services/directory_scanner_service_test.dart`, add:

```dart
test('isGameFile filters supported extensions', () {
  final service = DirectoryScannerService();
  
  // Supported
  expect(service.isGameFile('game.vpk'), true);
  expect(service.isGameFile('game.iso'), true);
  expect(service.isGameFile('game.exe'), true);
  
  // Not supported
  expect(service.isGameFile('readme.txt'), false);
  expect(service.isGameFile('cover.jpg'), false);
  expect(service.isGameFile('game.nfo'), false);
});
```

Wait, the `_isGameFile` method is private. Let me make it testable:

Change `_isGameFile` to package-private by removing the underscore:

```dart
/// Check if file has a supported game extension
@visibleForTesting
bool isGameFile(String filePath) {
  final ext = path.extension(filePath).toLowerCase();
  if (ext.isEmpty) return false;
  final extWithoutDot = ext.substring(1);
  return supportedExtensions.contains(extWithoutDot);
}
```

And update the private call in scanDirectory:

```dart
if (entity is File && isGameFile(entity.path)) {
```

**Step 6: Run updated tests**

Run: `flutter test test/services/directory_scanner_service_test.dart`
Expected: PASS (both tests)

**Step 7: Commit**

```bash
git add lib/services/directory_scanner_service.dart test/services/directory_scanner_service_test.dart
git commit -m "feat(scanner): add DirectoryScannerService with file parsing"
```

---

## Task 5: Update DatabaseService with Library Directory Methods

**Files:**
- Modify: `lib/services/database_service.dart`
- Create: `test/services/database_service_library_test.dart`

**Step 1: Write failing test for insertLibraryDirectory**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/models/library_directory.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService - Library Directories', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      final db = await dbService.database;
      // Clean up
      await db.delete('library_directories');
      await db.delete('games');
    });

    test('insertLibraryDirectory saves and returns directory with id', () async {
      final dir = LibraryDirectory(
        path: '/test/roms/vita',
        system: 'PS Vita',
        scanRecursive: true,
      );

      final id = await dbService.insertLibraryDirectory(dir);
      expect(id, greaterThan(0));

      final retrieved = await dbService.getLibraryDirectory(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.path, '/test/roms/vita');
      expect(retrieved.system, 'PS Vita');
      expect(retrieved.scanRecursive, true);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/database_service_library_test.dart`
Expected: FAIL with "insertLibraryDirectory not defined"

**Step 3: Add library directory methods to DatabaseService**

In `lib/services/database_service.dart`, add at the end before the closing brace:

```dart
// ============================================================
// Library Directories
// ============================================================

/// Insert a library directory
Future<int> insertLibraryDirectory(LibraryDirectory directory) async {
  final db = await database;
  return await db.insert('library_directories', directory.toMap());
}

/// Get library directory by ID
Future<LibraryDirectory?> getLibraryDirectory(int id) async {
  final db = await database;
  final maps = await db.query(
    'library_directories',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isEmpty) return null;
  return LibraryDirectory.fromMap(maps.first);
}

/// Get all library directories
Future<List<LibraryDirectory>> getAllLibraryDirectories() async {
  final db = await database;
  final maps = await db.query('library_directories', orderBy: 'created_at DESC');
  return maps.map((map) => LibraryDirectory.fromMap(map)).toList();
}

/// Update library directory
Future<void> updateLibraryDirectory(LibraryDirectory directory) async {
  final db = await database;
  await db.update(
    'library_directories',
    directory.toMap(),
    where: 'id = ?',
    whereArgs: [directory.id],
  );
}

/// Delete library directory
Future<void> deleteLibraryDirectory(int id) async {
  final db = await database;
  await db.delete(
    'library_directories',
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// Get games by source directory
Future<List<Game>> getGamesBySourceDirectory(int directoryId) async {
  final db = await database;
  final maps = await db.query(
    'games',
    where: 'source_directory_id = ?',
    whereArgs: [directoryId],
    orderBy: 'title ASC',
  );
  return maps.map((map) => Game.fromMap(map)).toList();
}

/// Mark game as missing
Future<void> markGameMissing(int gameId) async {
  final db = await database;
  await db.update(
    'games',
    {'file_status': 1},
    where: 'id = ?',
    whereArgs: [gameId],
  );
}

/// Mark game as available
Future<void> markGameAvailable(int gameId) async {
  final db = await database;
  await db.update(
    'games',
    {'file_status': 0},
    where: 'id = ?',
    whereArgs: [gameId],
  );
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/database_service_library_test.dart`
Expected: PASS

**Step 5: Add import for LibraryDirectory**

At top of `lib/services/database_service.dart`:

```dart
import '../models/library_directory.dart';
```

**Step 6: Commit**

```bash
git add lib/services/database_service.dart test/services/database_service_library_test.dart
git commit -m "feat(db): add library directory CRUD methods"
```

---

## Task 6: Create LibraryDirectoryService

**Files:**
- Create: `lib/services/library_directory_service.dart`
- Create: `test/services/library_directory_service_test.dart`

**Step 1: Write failing test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/library_directory_service.dart';
import 'package:clair/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LibraryDirectoryService', () {
    late LibraryDirectoryService service;
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      service = LibraryDirectoryService();
      
      final db = await dbService.database;
      await db.delete('library_directories');
      await db.delete('games');
    });

    test('addDirectory validates path exists', () async {
      expect(
        () => service.addDirectory('/nonexistent/path', 'PS Vita', false),
        throwsA(isA<DirectoryNotFoundException>()),
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/library_directory_service_test.dart`
Expected: FAIL with "LibraryDirectoryService not defined"

**Step 3: Implement LibraryDirectoryService**

```dart
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/library_directory.dart';
import '../models/discovered_game.dart';
import '../models/game.dart';
import 'database_service.dart';
import 'directory_scanner_service.dart';
import 'cover_orchestrator.dart';

class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  
  @override
  String toString() => message;
}

/// Service for managing library directories and importing games
class LibraryDirectoryService {
  final DatabaseService _dbService = DatabaseService.instance;
  final DirectoryScannerService _scanner = DirectoryScannerService();
  final CoverOrchestrator _coverOrchestrator = CoverOrchestrator();

  /// Add a new library directory and scan it
  Future<LibraryDirectory> addDirectory(
    String path,
    String system,
    bool scanRecursive,
  ) async {
    // Validate directory exists
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw DirectoryNotFoundException('Directory not found: $path');
    }

    // Save directory to database
    final libDir = LibraryDirectory(
      path: path,
      system: system,
      scanRecursive: scanRecursive,
    );
    
    final id = await _dbService.insertLibraryDirectory(libDir);
    final savedDir = libDir.copyWith(id: id);

    // Scan and import games
    await _scanAndImport(savedDir);

    return savedDir;
  }

  /// Refresh an existing library directory
  Future<void> refreshDirectory(int directoryId) async {
    final libDir = await _dbService.getLibraryDirectory(directoryId);
    if (libDir == null) {
      throw Exception('Library directory not found: $directoryId');
    }

    await _scanAndImport(libDir);
  }

  /// Remove a library directory (does not delete games)
  Future<void> removeDirectory(int directoryId) async {
    await _dbService.deleteLibraryDirectory(directoryId);
  }

  /// Get all library directories
  Future<List<LibraryDirectory>> getAllDirectories() async {
    return await _dbService.getAllLibraryDirectories();
  }

  /// Scan directory and import/update games
  Future<void> _scanAndImport(LibraryDirectory libDir) async {
    // Scan filesystem
    final discovered = await _scanner.scanDirectory(
      libDir.path,
      libDir.system,
      libDir.scanRecursive,
    );

    // Get existing games from this directory
    final existing = await _dbService.getGamesBySourceDirectory(libDir.id!);
    final existingPaths = existing.map((g) => g.executablePath).toSet();

    // Track which existing games we've seen (to detect missing files)
    final seenPaths = <String>{};

    // Import new games
    for (final disc in discovered) {
      seenPaths.add(disc.executablePath);

      if (!existingPaths.contains(disc.executablePath)) {
        // New game - insert it
        final game = Game(
          title: disc.title,
          system: disc.system,
          executablePath: disc.executablePath,
        );
        
        final gameId = await _dbService.insertGame(game);
        
        // Update with source directory and ID
        final updatedGame = game.copyWith(
          id: gameId,
        );
        
        // Set source_directory_id manually (not in Game model copyWith)
        final db = await _dbService.database;
        await db.update(
          'games',
          {'source_directory_id': libDir.id},
          where: 'id = ?',
          whereArgs: [gameId],
        );

        // Trigger cover fetch if API key is configured
        final apiKey = dotenv.env['STEAMGRIDDB_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          await _coverOrchestrator.fetchCoverForGame(updatedGame);
        }
      } else {
        // Existing game - mark as available if it was missing
        final existingGame = existing.firstWhere(
          (g) => g.executablePath == disc.executablePath,
        );
        await _dbService.markGameAvailable(existingGame.id!);
      }
    }

    // Mark missing games
    for (final game in existing) {
      if (!seenPaths.contains(game.executablePath)) {
        await _dbService.markGameMissing(game.id!);
      }
    }

    // Update last scanned timestamp
    final updated = libDir.copyWith(lastScannedAt: DateTime.now());
    await _dbService.updateLibraryDirectory(updated);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/library_directory_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/library_directory_service.dart test/services/library_directory_service_test.dart
git commit -m "feat(service): add LibraryDirectoryService for directory management"
```

---

## Task 7: Create Library Directories Settings UI

**Files:**
- Create: `lib/screens/library_directories_screen.dart`
- Modify: `lib/screens/settings_screen.dart`

**Step 1: Create library directories screen**

```dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/library_directory.dart';
import '../services/library_directory_service.dart';

class LibraryDirectoriesScreen extends StatefulWidget {
  const LibraryDirectoriesScreen({super.key});

  @override
  State<LibraryDirectoriesScreen> createState() =>
      _LibraryDirectoriesScreenState();
}

class _LibraryDirectoriesScreenState extends State<LibraryDirectoriesScreen> {
  final LibraryDirectoryService _service = LibraryDirectoryService();
  List<LibraryDirectory> _directories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() => _isLoading = true);
    final dirs = await _service.getAllDirectories();
    setState(() {
      _directories = dirs;
      _isLoading = false;
    });
  }

  Future<void> _addDirectory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddDirectoryDialog(),
    );

    if (result != null) {
      try {
        await _service.addDirectory(
          result['path'],
          result['system'],
          result['recursive'],
        );
        _loadDirectories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Directory added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _refreshDirectory(LibraryDirectory dir) async {
    try {
      await _service.refreshDirectory(dir.id!);
      _loadDirectories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directory refreshed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeDirectory(LibraryDirectory dir) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Directory?'),
        content: Text(
          'Remove ${dir.path}?\n\nGames from this directory will remain in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.removeDirectory(dir.id!);
      _loadDirectories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directory removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Directories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton.icon(
                  onPressed: _addDirectory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Directory'),
                ),
                const SizedBox(height: 24),
                ..._directories.map((dir) => Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dir.system,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(dir.path),
                            const SizedBox(height: 4),
                            Text(
                              'Subdirectories: ${dir.scanRecursive ? "Yes" : "No"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (dir.lastScannedAt != null)
                              Text(
                                'Last scanned: ${_formatDate(dir.lastScannedAt!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _refreshDirectory(dir),
                                  child: const Text('Refresh'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _removeDirectory(dir),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class AddDirectoryDialog extends StatefulWidget {
  const AddDirectoryDialog({super.key});

  @override
  State<AddDirectoryDialog> createState() => _AddDirectoryDialogState();
}

class _AddDirectoryDialogState extends State<AddDirectoryDialog> {
  String? _selectedPath;
  String _selectedSystem = 'PC (Windows)';
  bool _scanRecursive = true;

  final List<String> _systems = [
    'PC (Windows)',
    'PC (Linux)',
    'PC (Mac)',
    'Steam',
    'GOG',
    'Epic Games',
    'PlayStation Vita',
    'Nintendo 3DS',
    'Nintendo Switch',
    'GameCube',
    'Wii',
    'PlayStation 2',
    'Xbox',
    'Xbox 360',
  ];

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() => _selectedPath = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Directory'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickDirectory,
              icon: const Icon(Icons.folder),
              label: const Text('Select Directory'),
            ),
            if (_selectedPath != null) ...[
              const SizedBox(height: 8),
              Text(_selectedPath!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSystem,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: _systems
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSystem = value);
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Include subdirectories'),
              value: _scanRecursive,
              onChanged: (value) {
                setState(() => _scanRecursive = value ?? true);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedPath != null
              ? () {
                  Navigator.of(context).pop({
                    'path': _selectedPath,
                    'system': _selectedSystem,
                    'recursive': _scanRecursive,
                  });
                }
              : null,
          child: const Text('Scan & Import'),
        ),
      ],
    );
  }
}
```

**Step 2: Add file_picker dependency**

In `pubspec.yaml`, add:

```yaml
dependencies:
  file_picker: ^8.1.6
```

Run: `flutter pub get`

**Step 3: Add navigation to settings screen**

In `lib/screens/settings_screen.dart`, add after SteamGridDB section:

```dart
// Library Directories
ListTile(
  leading: const Icon(Icons.folder_open),
  title: const Text('Library Directories'),
  subtitle: const Text('Manage game directories'),
  trailing: const Icon(Icons.arrow_forward),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LibraryDirectoriesScreen(),
      ),
    );
  },
),
```

And add import at top:

```dart
import 'library_directories_screen.dart';
```

**Step 4: Test manually**

Run app, go to Settings → Library Directories → Add Directory
Expected: Can select directory, choose system, scan

**Step 5: Commit**

```bash
git add lib/screens/library_directories_screen.dart lib/screens/settings_screen.dart pubspec.yaml
git commit -m "feat(ui): add library directories management screen"
```

---

## Task 8: Connect Play Screen to Real Data

**Files:**
- Modify: `lib/screens/play_screen.dart`

**Step 1: Use context-manager skill**

Before modifying play_screen.dart, use the context-manager skill to understand its current implementation and dependencies.

**Step 2: Replace mock data with database queries**

In `lib/screens/play_screen.dart`, locate the `_loadGames` method and replace mock data logic with:

```dart
Future<void> _loadGames() async {
  setState(() => _isLoading = true);

  final dbService = DatabaseService.instance;
  
  // Load all games, filtering out missing files by default
  final allGames = await dbService.getAllGames();
  final availableGames = allGames.where((g) => g.file_status == 0).toList();

  setState(() {
    _games = availableGames;
    _isLoading = false;
    _selectedGameIndex = _games.isEmpty ? 0 : 0;
  });
}
```

Wait - the Game model doesn't have a `file_status` field yet. We need to add it.

**Step 3: Add file_status to Game model**

In `lib/models/game.dart`, add field:

```dart
final int fileStatus;
```

Add to constructor:

```dart
this.fileStatus = 0,
```

Add to toMap():

```dart
'file_status': fileStatus,
```

Add to fromMap():

```dart
fileStatus: map['file_status'] as int? ?? 0,
```

Add to copyWith():

```dart
int? fileStatus,
// ...
fileStatus: fileStatus ?? this.fileStatus,
```

**Step 4: Update play_screen.dart import**

Add import:

```dart
import '../services/database_service.dart';
```

Replace mock data in `_loadGames()`:

```dart
Future<void> _loadGames() async {
  setState(() => _isLoading = true);

  final dbService = DatabaseService.instance;
  final allGames = await dbService.getAllGames();
  
  // Filter out missing files by default
  final availableGames = allGames.where((g) => g.fileStatus == 0).toList();

  setState(() {
    _games = availableGames;
    _isLoading = false;
    if (_games.isNotEmpty && _selectedGameIndex >= _games.length) {
      _selectedGameIndex = 0;
    }
  });
}
```

**Step 5: Add getAllGames to DatabaseService**

In `lib/services/database_service.dart`, add:

```dart
/// Get all games
Future<List<Game>> getAllGames() async {
  final db = await database;
  final maps = await db.query('games', orderBy: 'title ASC');
  return maps.map((map) => Game.fromMap(map)).toList();
}
```

**Step 6: Test**

Run app, add a directory with games, verify Play screen shows them.

**Step 7: Commit**

```bash
git add lib/models/game.dart lib/services/database_service.dart lib/screens/play_screen.dart
git commit -m "feat(play): connect play screen to real database"
```

---

## Task 9: Integration Testing

**Files:**
- Create: `test/integration/library_directory_integration_test.dart`

**Step 1: Write integration test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/library_directory_service.dart';
import 'package:clair/services/database_service.dart';
import 'package:path/path.dart' as path;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Library Directory Integration', () {
    late LibraryDirectoryService service;
    late DatabaseService dbService;
    late Directory testDir;

    setUp(() async {
      service = LibraryDirectoryService();
      dbService = DatabaseService.instance;

      // Create test directory with mock game files
      testDir = Directory.systemTemp.createTempSync('clair_test_');
      File(path.join(testDir.path, 'game1.vpk')).writeAsStringSync('mock');
      File(path.join(testDir.path, 'game2.iso')).writeAsStringSync('mock');
      
      // Clean database
      final db = await dbService.database;
      await db.delete('library_directories');
      await db.delete('games');
    });

    tearDown(() async {
      testDir.deleteSync(recursive: true);
    });

    test('add directory imports games', () async {
      final dir = await service.addDirectory(
        testDir.path,
        'PS Vita',
        false,
      );

      expect(dir.id, isNotNull);

      final games = await dbService.getGamesBySourceDirectory(dir.id!);
      expect(games.length, 2);
      expect(games[0].title, anyOf('Game1', 'Game2'));
    });

    test('refresh detects new files', () async {
      final dir = await service.addDirectory(testDir.path, 'PS Vita', false);
      
      // Add new file
      File(path.join(testDir.path, 'game3.vpk')).writeAsStringSync('mock');
      
      await service.refreshDirectory(dir.id!);

      final games = await dbService.getGamesBySourceDirectory(dir.id!);
      expect(games.length, 3);
    });

    test('refresh marks missing files', () async {
      final dir = await service.addDirectory(testDir.path, 'PS Vita', false);
      
      // Delete a file
      File(path.join(testDir.path, 'game1.vpk')).deleteSync();
      
      await service.refreshDirectory(dir.id!);

      final games = await dbService.getGamesBySourceDirectory(dir.id!);
      final missing = games.where((g) => g.fileStatus == 1).toList();
      expect(missing.length, 1);
    });
  });
}
```

**Step 2: Run integration test**

Run: `flutter test test/integration/library_directory_integration_test.dart`
Expected: PASS

**Step 3: Commit**

```bash
git add test/integration/library_directory_integration_test.dart
git commit -m "test: add library directory integration tests"
```

---

## Task 10: Final Cleanup and Documentation

**Step 1: Update README**

In `README.md`, add section after SteamGridDB:

```markdown
### Library Directories

Automatically import games from your ROM/game directories:

1. Open Settings → Library Directories
2. Click "Add Directory"
3. Select the folder containing your games
4. Choose the platform (PS Vita, Nintendo 3DS, etc.)
5. Enable "Include subdirectories" if your games are organized in subfolders
6. Click "Scan & Import"

Clair will scan for game files and add them to your library. Use "Refresh" to detect new or removed games.
```

**Step 2: Delete test helper script**

```bash
rm test_steamgrid.dart
git add -A
```

**Step 3: Final commit**

```bash
git commit -m "docs: add library directories usage to README"
```

**Step 4: Push to remote**

```bash
git push
```

---

## Completion Checklist

- [x] Database migration (v3) with library_directories table and game columns
- [x] LibraryDirectory model
- [x] DiscoveredGame model
- [x] DirectoryScannerService with title parsing and file filtering
- [x] LibraryDirectoryService with add/refresh/remove operations
- [x] DatabaseService library directory CRUD methods
- [x] Library Directories settings screen UI
- [x] Add Directory dialog with file picker
- [x] Play screen connected to real database
- [x] Game model updated with fileStatus field
- [x] Integration tests for directory scanning
- [x] README documentation

---

## Notes for Executor

**Use supporting skills:**
- **context-manager** before editing play_screen.dart (Task 8)
- **testing** skill for test design patterns
- **diff-editing** for large file modifications if needed

**Common Issues:**
- File picker permission issues on mobile - test on desktop first
- Database migration - use `flutter clean` to reset if schema issues occur
- Path handling - use `path` package for cross-platform compatibility

**Testing Strategy:**
- Unit tests for title parsing and file filtering
- Integration tests for full scan workflow
- Manual testing with real ROM directories

---

**Plan complete. Ready for execution with executing-plans skill.**
