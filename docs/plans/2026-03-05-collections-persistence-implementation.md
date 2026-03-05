# Collections Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Replace mock collections with SQLite-backed collections, artwork support, and a dedicated collection editor.

**Architecture:** Add `coverPath` to collections, implement CollectionsService for CRUD + membership, build CollectionEditorScreen, and wire Collections/Detail screens to DB.

**Tech Stack:** Flutter, Dart, sqflite, file_picker, path_provider

**Status:** ✅ IMPLEMENTATION COMPLETE - All tasks completed, tests written, ready for testing

---

## Implementation Status

- ✅ Task 1: Database migration for collection artwork
- ✅ Task 2: Extended Collection model with coverPath
- ✅ Task 3: CollectionsService implementation
- ✅ Task 4: CollectionEditorScreen
- ✅ Task 5: Wire collections_screen.dart
- ✅ Task 6: Wire collection_detail_screen.dart
- ✅ Task 7: Documentation updates
- ✅ Task 8: Comprehensive test coverage

**Test Files Created:**
- `test/services/collections_service_test.dart` - Full CRUD, game management, error handling
- `test/screens/collections_screen_test.dart` - Widget tests, layout, navigation
- `test/screens/collection_editor_screen_test.dart` - Create/edit modes, validation, cover picker
- `test/screens/collection_detail_screen_test.dart` - Game display, empty states, errors

**To Run Tests:**
```bash
flutter test test/services/collections_service_test.dart
flutter test test/screens/collections_screen_test.dart
flutter test test/screens/collection_editor_screen_test.dart
flutter test test/screens/collection_detail_screen_test.dart

# Or run all tests
flutter test
```

---

### Task 1: Add migration for collection artwork

**Files:**
- Modify: `lib/services/database_service.dart`
- Test: `test/services/collections_service_test.dart`

**Step 1: Write failing test for coverPath persistence**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/models/collection.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  test('collection coverPath is persisted', () async {
    final dbService = DatabaseService.instance;
    final id = await dbService.insertCollection(Collection(
      name: 'Test',
      description: 'Desc',
      coverPath: '/tmp/cover.png',
    ));

    final collection = await dbService.getCollection(id);
    expect(collection?.coverPath, '/tmp/cover.png');
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/collections_service_test.dart`
Expected: FAIL with missing fields/methods

**Step 3: Implement migration**

In `database_service.dart`:
- Bump version to 4
- Add `coverPath TEXT` to collections table in `_onCreate`
- Add `ALTER TABLE collections ADD COLUMN coverPath TEXT` in `_onUpgrade` when `oldVersion < 4`

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/collections_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/database_service.dart test/services/collections_service_test.dart
git commit -m "feat(db): add collection coverPath"
```

---

### Task 2: Extend Collection model

**Files:**
- Modify: `lib/models/collection.dart`

**Step 1: Add coverPath field**

```dart
final String? coverPath;
```

Add to constructor, `toMap`, `fromMap`, and `copyWith`.

**Step 2: Commit**

```bash
git add lib/models/collection.dart
git commit -m "feat(models): add collection coverPath"
```

---

### Task 3: Add CollectionsService

**Files:**
- Create: `lib/services/collections_service.dart`
- Test: `test/services/collections_service_test.dart`

**Step 1: Write failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/models/collection.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  test('create/update/delete collection', () async {
    final service = CollectionsService();
    final id = await service.createCollection(Collection(name: 'Test'));
    final updated = await service.updateCollection(Collection(id: id, name: 'Updated'));
    expect(updated.name, 'Updated');
    await service.deleteCollection(id);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/collections_service_test.dart`
Expected: FAIL with missing service

**Step 3: Implement service**

Service should wrap DatabaseService and provide:
- createCollection
- updateCollection
- deleteCollection
- getCollection
- listCollections
- addGameToCollection
- removeGameFromCollection
- getGamesForCollection

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/collections_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/collections_service.dart test/services/collections_service_test.dart
git commit -m "feat(service): add collections service"
```

---

### Task 4: CollectionEditorScreen UI

**Files:**
- Create: `lib/screens/collection_editor_screen.dart`

**Step 1: Build editor screen**

Features:
- Name + description fields
- Artwork picker:
  - Pick file (file_picker) and copy into app docs
  - Select from game covers (list games and choose coverPath)
- Game selection list (checkboxes) using DB games
- Save button calls CollectionsService

**Step 2: Commit**

```bash
git add lib/screens/collection_editor_screen.dart
git commit -m "feat(ui): add collection editor screen"
```

---

### Task 5: Wire CollectionsScreen to DB + editor

**Files:**
- Modify: `lib/screens/collections_screen.dart`

**Step 1: Replace mock data with DB data**
- Load collections via CollectionsService
- New Collection button opens CollectionEditorScreen

**Step 2: Commit**

```bash
git add lib/screens/collections_screen.dart
git commit -m "feat(ui): wire collections screen to db"
```

---

### Task 6: Wire CollectionDetailScreen to DB

**Files:**
- Modify: `lib/screens/collection_detail_screen.dart`

**Step 1: Load collection + games from CollectionsService**
- Show artwork if coverPath exists
- Use DB games instead of mock list

**Step 2: Commit**

```bash
git add lib/screens/collection_detail_screen.dart
git commit -m "feat(ui): wire collection detail to db"
```

---

### Task 7: Update docs

**Files:**
- Modify: `docs/screens/collections.md`
- Modify: `README.md`

**Step 1: Document collection editor + artwork sources**

Add notes about:
- Editor screen
- Artwork from file or game cover

**Step 2: Commit**

```bash
git add docs/screens/collections.md README.md
git commit -m "docs: update collections" 
```
