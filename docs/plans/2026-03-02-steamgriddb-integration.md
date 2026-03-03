# SteamGridDB Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Add SteamGridDB integration to auto-fetch game covers with manual override capability.

**Architecture:** Service layer pattern with background queue. `SteamGridDBService` handles API calls, `CoverStorageService` manages downloads, `CoverFetchQueue` handles retries. Integration points: game add flow, settings screen, game detail screen.

**Tech Stack:** Flutter/Dart 3.6+, http package for API calls, flutter_dotenv for env config, SQLite for queue persistence

---

## Phase 1: Dependencies and Setup

### Task 1.1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Create: `.env.example`
- Modify: `.gitignore`

**Step 1: Add packages to pubspec.yaml**

```yaml
dependencies:
  # ... existing dependencies ...
  http: ^1.1.0
  flutter_dotenv: ^5.1.0
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: Dependencies installed successfully

**Step 3: Create .env.example**

```env
# SteamGridDB API Key
# Get your key from: https://www.steamgriddb.com/profile/preferences/api
STEAMGRIDDB_API_KEY=your_key_here
```

**Step 4: Update .gitignore**

Add to .gitignore:
```
.env
```

**Step 5: Load dotenv in main.dart**

```dart
// lib/main.dart - add at top of main()
await dotenv.load(fileName: ".env");
```

**Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock .env.example .gitignore lib/main.dart
git commit -m "chore: add http and flutter_dotenv dependencies for SteamGridDB"
```

---

## Phase 2: Core Services

### Task 2.1: Create SteamGridDB API Service

**Files:**
- Create: `lib/services/steamgriddb_service.dart`
- Create: `test/services/steamgriddb_service_test.dart`

**Step 1: Write failing test for API search**

```dart
// test/services/steamgriddb_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clair/services/steamgriddb_service.dart';

void main() {
  group('SteamGridDBService', () {
    test('search returns game results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"success": true, "data": [{"id": 123, "name": "Test Game"}]}',
          200,
        );
      });

      final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
      final results = await service.search('Test Game');

      expect(results, isNotEmpty);
      expect(results.first['id'], 123);
      expect(results.first['name'], 'Test Game');
    });

    test('search handles timeout', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(Duration(seconds: 5));
        return http.Response('{}', 200);
      });

      final service = SteamGridDBService(
        client: mockClient,
        apiKey: 'test-key',
        timeout: Duration(seconds: 2),
      );

      expect(
        () => service.search('Test Game'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/steamgriddb_service_test.dart`
Expected: FAIL with "SteamGridDBService not defined"

**Step 3: Implement minimal SteamGridDBService**

```dart
// lib/services/steamgriddb_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SteamGridDBService {
  final http.Client client;
  final String apiKey;
  final Duration timeout;

  static const String baseUrl = 'https://www.steamgriddb.com/api/v2';

  SteamGridDBService({
    http.Client? client,
    required this.apiKey,
    this.timeout = const Duration(seconds: 10),
  }) : client = client ?? http.Client();

  /// Search for games by title
  Future<List<Map<String, dynamic>>> search(String query) async {
    final uri = Uri.parse('$baseUrl/search/autocomplete/$query');
    final response = await client
        .get(
          uri,
          headers: {'Authorization': 'Bearer $apiKey'},
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['success'] != true) {
      throw Exception('API returned error');
    }

    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/steamgriddb_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/steamgriddb_service.dart test/services/steamgriddb_service_test.dart
git commit -m "feat(steamgriddb): add basic API search service with timeout"
```

---

### Task 2.2: Add Cover Fetching to SteamGridDBService

**Files:**
- Modify: `lib/services/steamgriddb_service.dart`
- Modify: `test/services/steamgriddb_service_test.dart`

**Step 1: Write failing test for getting covers**

```dart
// test/services/steamgriddb_service_test.dart - add to main group
test('getCovers returns cover URLs', () async {
  final mockClient = MockClient((request) async {
    return http.Response(
      '{"success": true, "data": [{"id": 1, "url": "https://example.com/cover.jpg", "score": 10}]}',
      200,
    );
  });

  final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
  final covers = await service.getCovers(123);

  expect(covers, isNotEmpty);
  expect(covers.first['url'], 'https://example.com/cover.jpg');
  expect(covers.first['score'], 10);
});

test('getCovers sorts by score', () async {
  final mockClient = MockClient((request) async {
    return http.Response(
      '{"success": true, "data": [{"id": 1, "score": 5}, {"id": 2, "score": 10}, {"id": 3, "score": 8}]}',
      200,
    );
  });

  final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
  final covers = await service.getCovers(123);

  expect(covers[0]['score'], 10); // Highest first
  expect(covers[1]['score'], 8);
  expect(covers[2]['score'], 5);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/steamgriddb_service_test.dart`
Expected: FAIL with "getCovers not defined"

**Step 3: Implement getCovers method**

```dart
// lib/services/steamgriddb_service.dart - add to class
/// Get cover art for a game
/// Returns covers sorted by score (best first)
Future<List<Map<String, dynamic>>> getCovers(int gameId) async {
  final uri = Uri.parse('$baseUrl/grids/game/$gameId').replace(
    queryParameters: {'dimensions': '600x900'},
  );

  final response = await client
      .get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      )
      .timeout(timeout);

  if (response.statusCode != 200) {
    throw Exception('Failed to get covers: ${response.statusCode}');
  }

  final data = json.decode(response.body);
  if (data['success'] != true) {
    throw Exception('API returned error');
  }

  final covers = List<Map<String, dynamic>>.from(data['data'] ?? []);
  
  // Sort by score (highest first)
  covers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
  
  return covers;
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/steamgriddb_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/steamgriddb_service.dart test/services/steamgriddb_service_test.dart
git commit -m "feat(steamgriddb): add getCovers method with score sorting"
```

---

### Task 2.3: Add Quick Fetch Helper

**Files:**
- Modify: `lib/services/steamgriddb_service.dart`
- Modify: `test/services/steamgriddb_service_test.dart`

**Step 1: Write failing test for quick fetch**

```dart
// test/services/steamgriddb_service_test.dart - add to main group
test('quickFetch returns best cover URL with short timeout', () async {
  final mockClient = MockClient((request) async {
    if (request.url.path.contains('search')) {
      return http.Response(
        '{"success": true, "data": [{"id": 123, "name": "Test Game"}]}',
        200,
      );
    } else {
      return http.Response(
        '{"success": true, "data": [{"id": 1, "url": "https://example.com/best.jpg", "score": 10}]}',
        200,
      );
    }
  });

  final service = SteamGridDBService(client: mockClient, apiKey: 'test-key');
  final coverUrl = await service.quickFetch('Test Game');

  expect(coverUrl, 'https://example.com/best.jpg');
});

test('quickFetch returns null on timeout', () async {
  final mockClient = MockClient((request) async {
    await Future.delayed(Duration(seconds: 5));
    return http.Response('{}', 200);
  });

  final service = SteamGridDBService(
    client: mockClient,
    apiKey: 'test-key',
    timeout: Duration(seconds: 2),
  );

  final coverUrl = await service.quickFetch('Test Game');
  expect(coverUrl, isNull);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/steamgriddb_service_test.dart`
Expected: FAIL with "quickFetch not defined"

**Step 3: Implement quickFetch method**

```dart
// lib/services/steamgriddb_service.dart - add to class
/// Quick fetch: search + get best cover with short timeout
/// Returns null if timeout or no results
Future<String?> quickFetch(String gameName, {String? platform}) async {
  try {
    // Search for game
    final searchResults = await search(gameName);
    if (searchResults.isEmpty) {
      return null;
    }

    // Get covers for first result (best match)
    final gameId = searchResults.first['id'] as int;
    final covers = await getCovers(gameId);
    
    if (covers.isEmpty) {
      return null;
    }

    // Return best cover (already sorted by score)
    return covers.first['url'] as String?;
  } on TimeoutException {
    return null;
  } catch (e) {
    // Log error but don't throw - graceful failure
    print('QuickFetch failed: $e');
    return null;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/steamgriddb_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/steamgriddb_service.dart test/services/steamgriddb_service_test.dart
git commit -m "feat(steamgriddb): add quickFetch helper with timeout handling"
```

---

### Task 2.4: Create Cover Storage Service

**Files:**
- Create: `lib/services/cover_storage_service.dart`
- Create: `test/services/cover_storage_service_test.dart`

**Step 1: Write failing test for downloading cover**

```dart
// test/services/cover_storage_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:clair/services/cover_storage_service.dart';

void main() {
  group('CoverStorageService', () {
    test('downloadCover saves file and returns path', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes([1, 2, 3, 4], 200);
      });

      final service = CoverStorageService(client: mockClient);
      final path = await service.downloadCover(
        'https://example.com/cover.jpg',
        gameId: 123,
      );

      expect(path, isNotNull);
      expect(path, contains('123'));
      expect(File(path!).existsSync(), isTrue);

      // Cleanup
      File(path).deleteSync();
    });

    test('downloadCover handles network failure', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final service = CoverStorageService(client: mockClient);
      final path = await service.downloadCover(
        'https://example.com/cover.jpg',
        gameId: 123,
      );

      expect(path, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/cover_storage_service_test.dart`
Expected: FAIL with "CoverStorageService not defined"

**Step 3: Implement CoverStorageService**

```dart
// lib/services/cover_storage_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CoverStorageService {
  final http.Client client;

  CoverStorageService({http.Client? client})
      : client = client ?? http.Client();

  /// Download cover from URL and save to app documents directory
  /// Returns file path on success, null on failure
  Future<String?> downloadCover(String url, {required int gameId}) async {
    try {
      // Download image
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }

      // Get app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(path.join(dir.path, 'covers'));
      
      // Create covers directory if it doesn't exist
      if (!coversDir.existsSync()) {
        coversDir.createSync(recursive: true);
      }

      // Generate filename (game ID + timestamp to allow updates)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'game_${gameId}_$timestamp.jpg';
      final filePath = path.join(coversDir.path, filename);

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      print('Failed to download cover: $e');
      return null;
    }
  }

  /// Delete cover file
  Future<void> deleteCover(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to delete cover: $e');
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/cover_storage_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/cover_storage_service.dart test/services/cover_storage_service_test.dart
git commit -m "feat(covers): add storage service for downloading and saving covers"
```

---

## Phase 3: Queue System

### Task 3.1: Add Queue Table to Database

**Files:**
- Modify: `lib/services/database_service.dart`

> **Note:** Use context-manager to identify which database service file to modify if there are multiple.

**Step 1: Add queue table to database schema**

```dart
// lib/services/database_service.dart - add to _createTables method
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
```

**Step 2: Add database version increment**

```dart
// lib/services/database_service.dart - update database version
static const int _databaseVersion = 2; // Increment from current version
```

**Step 3: Add migration logic**

```dart
// lib/services/database_service.dart - add to onUpgrade callback
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add cover_fetch_queue table
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
}
```

**Step 4: Test manually**

Run: Delete app data and reinstall to test migration
Expected: App starts successfully, queue table created

**Step 5: Commit**

```bash
git add lib/services/database_service.dart
git commit -m "feat(db): add cover_fetch_queue table for retry logic"
```

---

### Task 3.2: Create Cover Fetch Queue Service

**Files:**
- Create: `lib/services/cover_fetch_queue.dart`
- Create: `test/services/cover_fetch_queue_test.dart`

**Step 1: Write failing test for adding to queue**

```dart
// test/services/cover_fetch_queue_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/cover_fetch_queue.dart';
import 'package:clair/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CoverFetchQueue', () {
    late Database db;
    late CoverFetchQueue queue;

    setUp(() async {
      db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cover_fetch_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              game_id INTEGER NOT NULL,
              retry_count INTEGER DEFAULT 0,
              next_retry_at INTEGER,
              last_error TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
        },
      );
      queue = CoverFetchQueue(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('add inserts game into queue', () async {
      await queue.add(gameId: 123);
      
      final items = await queue.getPending();
      expect(items, hasLength(1));
      expect(items.first['game_id'], 123);
      expect(items.first['retry_count'], 0);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/cover_fetch_queue_test.dart`
Expected: FAIL with "CoverFetchQueue not defined"

**Step 3: Implement basic CoverFetchQueue**

```dart
// lib/services/cover_fetch_queue.dart
import 'package:sqflite/sqflite.dart';

class CoverFetchQueue {
  final Database db;

  CoverFetchQueue({required this.db});

  /// Add game to fetch queue
  Future<void> add({required int gameId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert('cover_fetch_queue', {
      'game_id': gameId,
      'retry_count': 0,
      'next_retry_at': now,
      'created_at': now,
    });
  }

  /// Get pending items ready for processing
  Future<List<Map<String, dynamic>>> getPending() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.query(
      'cover_fetch_queue',
      where: 'next_retry_at <= ? AND retry_count < 3',
      whereArgs: [now],
      orderBy: 'created_at ASC',
    );
  }

  /// Mark item as completed and remove from queue
  Future<void> markCompleted({required int gameId}) async {
    await db.delete(
      'cover_fetch_queue',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }

  /// Update retry count and next retry time
  Future<void> markFailed({
    required int gameId,
    required String error,
  }) async {
    final item = await db.query(
      'cover_fetch_queue',
      where: 'game_id = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    if (item.isEmpty) return;

    final retryCount = (item.first['retry_count'] as int) + 1;
    final backoffMinutes = [1, 5, 15][retryCount.clamp(0, 2)];
    final nextRetry = DateTime.now()
        .add(Duration(minutes: backoffMinutes))
        .millisecondsSinceEpoch;

    await db.update(
      'cover_fetch_queue',
      {
        'retry_count': retryCount,
        'next_retry_at': nextRetry,
        'last_error': error,
      },
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/cover_fetch_queue_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/cover_fetch_queue.dart test/services/cover_fetch_queue_test.dart
git commit -m "feat(queue): add cover fetch queue with retry logic"
```

---

### Task 3.3: Add Queue Processor

**Files:**
- Modify: `lib/services/cover_fetch_queue.dart`
- Modify: `test/services/cover_fetch_queue_test.dart`

**Step 1: Write failing test for processing queue**

```dart
// test/services/cover_fetch_queue_test.dart - add to main group
test('processQueue fetches covers and updates games', () async {
  final mockSteamGridDB = MockSteamGridDBService();
  final mockStorage = MockCoverStorageService();
  final mockGameService = MockGameService();

  when(mockSteamGridDB.quickFetch(any))
      .thenAnswer((_) async => 'https://example.com/cover.jpg');
  when(mockStorage.downloadCover(any, gameId: any))
      .thenAnswer((_) async => '/path/to/cover.jpg');

  final queue = CoverFetchQueue(
    db: db,
    steamGridDB: mockSteamGridDB,
    storage: mockStorage,
    gameService: mockGameService,
  );

  await queue.add(gameId: 123);
  await queue.processQueue();

  verify(mockGameService.updateCoverPath(123, '/path/to/cover.jpg')).called(1);
  
  final remaining = await queue.getPending();
  expect(remaining, isEmpty); // Should be removed after success
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/cover_fetch_queue_test.dart`
Expected: FAIL with "processQueue not defined"

**Step 3: Implement processQueue method**

```dart
// lib/services/cover_fetch_queue.dart - add to class
final SteamGridDBService? steamGridDB;
final CoverStorageService? storage;
final DatabaseService? gameService;

CoverFetchQueue({
  required this.db,
  this.steamGridDB,
  this.storage,
  this.gameService,
});

/// Process pending queue items
Future<void> processQueue() async {
  if (steamGridDB == null || storage == null || gameService == null) {
    print('Queue processor not fully initialized');
    return;
  }

  final pending = await getPending();
  
  for (final item in pending) {
    final gameId = item['game_id'] as int;
    
    try {
      // Get game details for search
      final game = await gameService!.getGame(gameId);
      if (game == null) {
        await markCompleted(gameId: gameId);
        continue;
      }

      // Fetch cover
      final coverUrl = await steamGridDB!.quickFetch(
        game.title,
        platform: game.system,
      );

      if (coverUrl == null) {
        await markFailed(gameId: gameId, error: 'No cover found');
        continue;
      }

      // Download and save
      final coverPath = await storage!.downloadCover(
        coverUrl,
        gameId: gameId,
      );

      if (coverPath == null) {
        await markFailed(gameId: gameId, error: 'Download failed');
        continue;
      }

      // Update game
      await gameService!.updateGame(
        game.copyWith(coverPath: coverPath),
      );

      // Remove from queue
      await markCompleted(gameId: gameId);
    } catch (e) {
      await markFailed(gameId: gameId, error: e.toString());
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/cover_fetch_queue_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/cover_fetch_queue.dart test/services/cover_fetch_queue_test.dart
git commit -m "feat(queue): add queue processor for background cover fetching"
```

---

## Phase 4: UI Integration

### Task 4.1: Add API Key Settings UI

**Files:**
- Create: `lib/screens/settings_screen.dart` (or modify existing)
- Modify: `lib/main.dart` (add route if needed)

> **Note:** Use context-manager to find existing settings screen location.

**Step 1: Create settings screen with API key input**

```dart
// lib/screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final envFile = File('${dir.path}/.env');
      
      if (envFile.existsSync()) {
        final contents = await envFile.readAsString();
        final lines = contents.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('STEAMGRIDDB_API_KEY=')) {
            _apiKeyController.text = line.substring(20);
            break;
          }
        }
      }
    } catch (e) {
      print('Error loading API key: $e');
    }
  }

  Future<void> _saveApiKey() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final envFile = File('${dir.path}/.env');
      
      final key = _apiKeyController.text.trim();
      if (key.isEmpty) {
        setState(() {
          _statusMessage = 'API key cannot be empty';
          _isLoading = false;
        });
        return;
      }

      // Read existing .env or create new
      final lines = <String>[];
      if (envFile.existsSync()) {
        final contents = await envFile.readAsString();
        lines.addAll(contents.split('\n'));
      }

      // Update or add API key line
      bool found = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('STEAMGRIDDB_API_KEY=')) {
          lines[i] = 'STEAMGRIDDB_API_KEY=$key';
          found = true;
          break;
        }
      }

      if (!found) {
        lines.add('STEAMGRIDDB_API_KEY=$key');
      }

      // Write back to file
      await envFile.writeAsString(lines.join('\n'));

      setState(() {
        _statusMessage = 'API key saved successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving API key: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SteamGridDB API Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter your API key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get your API key from: https://www.steamgriddb.com/profile/preferences/api',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveApiKey,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save API Key'),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Error')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
```

**Step 2: Add route to main.dart**

```dart
// lib/main.dart - add to routes
'/settings': (context) => const SettingsScreen(),
```

**Step 3: Test manually**

Run: `flutter run`
Navigate to settings screen, enter API key, verify save
Expected: API key saved to .env file in app documents directory

**Step 4: Commit**

```bash
git add lib/screens/settings_screen.dart lib/main.dart
git commit -m "feat(settings): add API key configuration UI"
```

---

### Task 4.2: Add Batch Cover Fetch Button

**Files:**
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/services/database_service.dart` (add getGamesWithoutCovers method)

**Step 1: Add getGamesWithoutCovers to database service**

```dart
// lib/services/database_service.dart - add method
Future<List<Game>> getGamesWithoutCovers() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'games',
    where: 'coverPath IS NULL OR coverPath = ?',
    whereArgs: [''],
  );
  
  return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
}
```

**Step 2: Add batch fetch button to settings screen**

```dart
// lib/screens/settings_screen.dart - add to State class
int _totalGames = 0;
int _gamesWithCovers = 0;
bool _isFetching = false;

@override
void initState() {
  super.initState();
  _loadApiKey();
  _loadStats();
}

Future<void> _loadStats() async {
  // TODO: Get actual stats from database service
  final dbService = DatabaseService.instance;
  final allGames = await dbService.getAllGames();
  final withCovers = allGames.where((g) => g.coverPath != null).length;
  
  setState(() {
    _totalGames = allGames.length;
    _gamesWithCovers = withCovers;
  });
}

Future<void> _fetchAllCovers() async {
  setState(() => _isFetching = true);
  
  try {
    final dbService = DatabaseService.instance;
    final queue = CoverFetchQueue(
      db: await dbService.database,
      steamGridDB: SteamGridDBService(apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? ''),
      storage: CoverStorageService(),
      gameService: dbService,
    );
    
    final gamesWithoutCovers = await dbService.getGamesWithoutCovers();
    
    for (final game in gamesWithoutCovers) {
      await queue.add(gameId: game.id!);
    }
    
    await queue.processQueue();
    await _loadStats();
    
    setState(() {
      _statusMessage = 'Fetched covers for ${gamesWithoutCovers.length} games';
      _isFetching = false;
    });
  } catch (e) {
    setState(() {
      _statusMessage = 'Error fetching covers: $e';
      _isFetching = false;
    });
  }
}

// Add to build method after API key section:
const SizedBox(height: 32),
const Text(
  'Cover Art',
  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Text('$_gamesWithCovers/$_totalGames games have covers'),
const SizedBox(height: 16),
ElevatedButton(
  onPressed: _isFetching ? null : _fetchAllCovers,
  child: _isFetching
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('Get Game Covers'),
),
```

**Step 3: Test manually**

Run: `flutter run`
Add API key, add games without covers, tap "Get Game Covers"
Expected: Covers fetched and saved for all games

**Step 4: Commit**

```bash
git add lib/screens/settings_screen.dart lib/services/database_service.dart
git commit -m "feat(settings): add batch cover fetch functionality"
```

---

### Task 4.3: Integrate Auto-Fetch on Game Add

**Files:**
- Modify: Game add flow (find with context-manager)
- Create: `lib/services/cover_orchestrator.dart` (coordinator service)

> **Note:** Use context-manager to find where games are added to the database.

**Step 1: Create cover orchestrator service**

```dart
// lib/services/cover_orchestrator.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clair/models/game.dart';
import 'package:clair/services/steamgriddb_service.dart';
import 'package:clair/services/cover_storage_service.dart';
import 'package:clair/services/cover_fetch_queue.dart';
import 'package:clair/services/database_service.dart';

class CoverOrchestrator {
  final SteamGridDBService _steamGridDB;
  final CoverStorageService _storage;
  final CoverFetchQueue _queue;
  final DatabaseService _dbService;

  CoverOrchestrator({
    SteamGridDBService? steamGridDB,
    CoverStorageService? storage,
    CoverFetchQueue? queue,
    DatabaseService? dbService,
  })  : _steamGridDB = steamGridDB ??
              SteamGridDBService(
                apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
                timeout: const Duration(seconds: 3),
              ),
        _storage = storage ?? CoverStorageService(),
        _queue = queue ?? CoverFetchQueue(db: dbService!.database),
        _dbService = dbService ?? DatabaseService.instance;

  /// Auto-fetch cover when game is added
  /// Tries quick fetch (3s timeout), queues on failure
  Future<void> onGameAdded(Game game) async {
    if (game.id == null) return;

    try {
      // Quick fetch attempt
      final coverUrl = await _steamGridDB.quickFetch(
        game.title,
        platform: game.system,
      );

      if (coverUrl != null) {
        // Success - download and update
        final coverPath = await _storage.downloadCover(
          coverUrl,
          gameId: game.id!,
        );

        if (coverPath != null) {
          await _dbService.updateGame(
            game.copyWith(coverPath: coverPath),
          );
          return;
        }
      }

      // Failed or timeout - queue for retry
      await _queue.add(gameId: game.id!);
    } catch (e) {
      // Queue on any error
      print('Auto-fetch failed, queuing: $e');
      await _queue.add(gameId: game.id!);
    }
  }
}
```

**Step 2: Integrate with game add flow**

> **Note:** This example assumes a game creation service/repository pattern. Adjust to actual architecture.

```dart
// Example: lib/services/game_service.dart or wherever games are created
import 'package:clair/services/cover_orchestrator.dart';

final _coverOrchestrator = CoverOrchestrator();

Future<Game> addGame(Game game) async {
  // Save game to database
  final savedGame = await _dbService.insertGame(game);
  
  // Trigger cover fetch
  _coverOrchestrator.onGameAdded(savedGame);
  
  return savedGame;
}
```

**Step 3: Test manually**

Run: `flutter run`
Add new game, wait 3 seconds
Expected: Cover appears if found, otherwise queued for background retry

**Step 4: Commit**

```bash
git add lib/services/cover_orchestrator.dart [game_add_integration_files]
git commit -m "feat(covers): auto-fetch covers on game add with queue fallback"
```

---

### Task 4.4: Add Change Cover Action

**Files:**
- Create: `lib/screens/cover_picker_screen.dart`
- Modify: Game detail screen (add "Change cover" button)

**Step 1: Create cover picker screen**

```dart
// lib/screens/cover_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:clair/models/game.dart';
import 'package:clair/services/steamgriddb_service.dart';
import 'package:clair/services/cover_storage_service.dart';
import 'package:clair/services/database_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CoverPickerScreen extends StatefulWidget {
  final Game game;

  const CoverPickerScreen({Key? key, required this.game}) : super(key: key);

  @override
  State<CoverPickerScreen> createState() => _CoverPickerScreenState();
}

class _CoverPickerScreenState extends State<CoverPickerScreen> {
  List<Map<String, dynamic>> _covers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCovers();
  }

  Future<void> _loadCovers() async {
    try {
      final service = SteamGridDBService(
        apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
      );

      // Search for game
      final results = await service.search(widget.game.title);
      if (results.isEmpty) {
        setState(() {
          _error = 'No results found';
          _isLoading = false;
        });
        return;
      }

      // Get covers for first result
      final covers = await service.getCovers(results.first['id']);
      setState(() {
        _covers = covers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCover(String coverUrl) async {
    final storage = CoverStorageService();
    final coverPath = await storage.downloadCover(
      coverUrl,
      gameId: widget.game.id!,
    );

    if (coverPath != null) {
      final dbService = DatabaseService.instance;
      await dbService.updateGame(
        widget.game.copyWith(coverPath: coverPath),
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Cover - ${widget.game.title}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _covers.length,
                  itemBuilder: (context, index) {
                    final cover = _covers[index];
                    return GestureDetector(
                      onTap: () => _selectCover(cover['url']),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          cover['url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
```

**Step 2: Add "Change cover" button to game detail screen**

```dart
// Example: lib/screens/game_detail_screen.dart - add button
ElevatedButton.icon(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoverPickerScreen(game: widget.game),
      ),
    );
    
    if (result == true) {
      // Refresh game detail to show new cover
      setState(() {});
    }
  },
  icon: const Icon(Icons.image),
  label: const Text('Change Cover'),
)
```

**Step 3: Test manually**

Run: `flutter run`
Open game detail, tap "Change cover", select new cover
Expected: Cover picker shows options, selection updates game

**Step 4: Commit**

```bash
git add lib/screens/cover_picker_screen.dart [game_detail_screen_file]
git commit -m "feat(covers): add manual cover picker UI"
```

---

## Phase 5: Polish & Testing

### Task 5.1: Add Loading States to UI

**Files:**
- Modify game card/list UI components
- Add loading indicators for cover fetch

> **Note:** Use context-manager to find game card components.

**Step 1: Add loading indicator to game card**

```dart
// Example: Update game card widget to show loading state
if (game.coverPath == null || game.coverPath!.isEmpty)
  Stack(
    children: [
      Container(
        color: Colors.grey[800],
        child: const Icon(Icons.videogame_asset, size: 48),
      ),
      if (_isLoadingCover[game.id] ?? false)
        const Positioned.fill(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
    ],
  )
else
  Image.file(
    File(game.coverPath!),
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: Colors.grey[800],
        child: const Icon(Icons.broken_image, size: 48),
      );
    },
  )
```

**Step 2: Listen for cover updates**

> **Note:** Implement using provider, streams, or your preferred state management approach.

**Step 3: Test manually**

Run: `flutter run`
Add game, verify loading indicator appears while fetching
Expected: Spinner shows during fetch, disappears when complete

**Step 4: Commit**

```bash
git add [game_card_files]
git commit -m "feat(ui): add loading indicators for cover fetching"
```

---

### Task 5.2: Add Error Handling UI

**Files:**
- Modify: Settings screen (show error messages)
- Modify: Cover picker screen (handle API errors)

**Step 1: Update settings screen error display**

Already implemented in Task 4.1 with `_statusMessage` state.

**Step 2: Add retry logic to cover picker**

```dart
// lib/screens/cover_picker_screen.dart - add retry button to error state
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Error: $_error'),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
            _error = null;
          });
          _loadCovers();
        },
        child: const Text('Retry'),
      ),
    ],
  ),
)
```

**Step 3: Test manually**

Run: `flutter run`
Test with invalid API key, network error scenarios
Expected: Clear error messages, retry options

**Step 4: Commit**

```bash
git add lib/screens/cover_picker_screen.dart
git commit -m "feat(ui): improve error handling and retry logic"
```

---

### Task 5.3: Integration Testing

**Files:**
- Create: `integration_test/cover_fetch_integration_test.dart`

> **Note:** Use testing skill for integration test patterns.

**Step 1: Write integration test**

```dart
// integration_test/cover_fetch_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clair/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cover Fetch Integration', () {
    testWidgets('Add game triggers auto-fetch', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to add game screen
      // Fill in game details
      // Submit
      // Verify cover appears or loading indicator shows

      // TODO: Implement based on actual app structure
    });

    testWidgets('Manual cover change works', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to game detail
      // Tap "Change cover"
      // Select cover from picker
      // Verify cover updates

      // TODO: Implement based on actual app structure
    });
  });
}
```

**Step 2: Run integration tests**

Run: `flutter test integration_test/cover_fetch_integration_test.dart`
Expected: Tests pass (once implemented)

**Step 3: Document test coverage**

Add to README.md or TESTING.md:
- Unit tests: Service layer (SteamGridDB, Storage, Queue)
- Integration tests: End-to-end cover fetch flows
- Manual test scenarios: API key config, offline mode, error states

**Step 4: Commit**

```bash
git add integration_test/cover_fetch_integration_test.dart [docs]
git commit -m "test: add integration tests for cover fetch flows"
```

---

## Final Steps

### Task 6.1: Documentation

**Files:**
- Create: `docs/features/steamgriddb-integration.md`
- Modify: `README.md` (add setup instructions)

**Step 1: Create feature documentation**

```markdown
# SteamGridDB Integration

## Overview

Automatically fetch game cover art from SteamGridDB when adding games to your library.

## Setup

1. Get API key from https://www.steamgriddb.com/profile/preferences/api
2. Open Settings in the app
3. Enter API key under "SteamGridDB API Key"
4. Click "Save API Key"

## Features

### Auto-Fetch
- Covers fetch automatically when adding games
- 3-second timeout for quick results
- Failed fetches retry in background

### Manual Selection
- Tap "Change Cover" on any game
- Browse all available covers
- Select your preferred artwork

### Batch Operations
- Settings → "Get Game Covers"
- Fetches covers for all games without artwork
- Shows progress indicator

## Troubleshooting

**Covers not downloading:**
- Check API key is configured
- Verify internet connection
- Check rate limits (500 requests/hour)

**Wrong cover selected:**
- Use "Change Cover" to pick manually
- Search uses game title + platform for best match

## Technical Details

- Covers saved to app documents directory
- Queue persists across app restarts
- Retry logic: 1min, 5min, 15min intervals
- Failed fetches removed after 3 attempts
```

**Step 2: Update README**

Add to README.md setup section:
```markdown
### SteamGridDB Configuration (Optional)

For automatic game cover art:
1. Get free API key from https://www.steamgriddb.com/
2. Configure in Settings → SteamGridDB API Key
```

**Step 3: Commit**

```bash
git add docs/features/steamgriddb-integration.md README.md
git commit -m "docs: add SteamGridDB integration documentation"
```

---

### Task 6.2: Code Review Checklist

**Before marking complete, verify:**

- [ ] All tests pass (`flutter test`)
- [ ] Integration tests run (`flutter test integration_test/`)
- [ ] No compiler warnings
- [ ] API key stored securely in .env
- [ ] .env excluded from git
- [ ] Error messages are user-friendly
- [ ] Loading indicators don't block UI
- [ ] Queue processes in background
- [ ] Controller navigation works in picker UI
- [ ] Documentation is complete
- [ ] Conventional commit messages used
- [ ] No hardcoded API keys or secrets
- [ ] Coverage for error scenarios (missing key, network failure)

---

## Execution Notes

**Key Skills to Reference:**
- **context-manager**: Before modifying database service or finding game add flow
- **testing**: For test design and mocking strategies
- **diff-editing**: If modifying large files (> 100 lines)

**Manual Testing Scenarios:**
1. Fresh install with API key setup
2. Add game with valid API key (verify auto-fetch)
3. Add game with invalid API key (verify graceful failure)
4. Add game offline (verify queue)
5. Manual "Change cover" flow
6. Batch "Get game covers" operation
7. App restart with pending queue items

**Verification Commands:**
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Check for warnings
flutter analyze

# Run app
flutter run
```

**Success Criteria:**
- Auto-fetch works on game add (3s timeout)
- Queue retries failed fetches
- Manual cover picker shows all options
- Batch operation processes all games
- API key stored in .env
- All error states handled gracefully
- UI remains responsive
- Controller navigation works

---

**Plan complete and saved to `docs/plans/2026-03-02-steamgriddb-integration.md`.**

**To execute: Use the executing-plans skill with this plan file in a new development session.**
