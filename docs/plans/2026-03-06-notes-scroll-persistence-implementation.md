# Notes Scroll Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Persist per-note scroll position and restore it when reopening a note.

**Architecture:** Use `shared_preferences` to store a scroll offset per note id. `NoteDetailScreen` will read the stored offset on open and write updates via a `ScrollController` listener. Offsets are clamped to the current scroll extent.

**Tech Stack:** Flutter, shared_preferences, widget tests.

---

### Task 1: Add shared_preferences integration

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependency**

Add to `dependencies`:
```yaml
shared_preferences: ^2.2.2
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: dependency resolved with no errors.

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add shared_preferences for notes scroll state"
```

---

### Task 2: Implement scroll persistence in NoteDetailScreen

**Files:**
- Modify: `lib/screens/note_detail_screen.dart`

**Step 1: Write failing widget test**

Create failing test in `test/screens/note_detail_screen_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clair/models/note.dart';
import 'package:clair/screens/note_detail_screen.dart';

void main() {
  testWidgets('restores scroll position per note', (tester) async {
    SharedPreferences.setMockInitialValues({
      'notes.scroll.1': 120.0,
    });

    final note = Note(
      id: 1,
      title: 'Test Note',
      content: 'Line\n' * 200,
      type: NoteType.text,
      createdDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteDetailScreen(note: note)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.pixels, greaterThanOrEqualTo(120.0));
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/note_detail_screen_test.dart -v`
Expected: FAIL (scroll offset not restored).

**Step 3: Implement ScrollController + preferences**

In `NoteDetailScreen`:
- Add a `ScrollController _scrollController`.
- On `initState`, load offset from `SharedPreferences`.
- After first frame, jump to stored offset (clamped to max extent).
- Add listener to save offset with key `notes.scroll.<noteId>`.
- Use a single controller for both read/edit views.

**Step 4: Run test to verify it passes**

Run: `flutter test test/screens/note_detail_screen_test.dart -v`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/screens/note_detail_screen.dart test/screens/note_detail_screen_test.dart
git commit -m "feat(notes): persist scroll position per note"
```

---

### Task 3: Clamp scroll offset and handle missing id

**Files:**
- Modify: `lib/screens/note_detail_screen.dart`
- Test: `test/screens/note_detail_screen_test.dart`

**Step 1: Add edge case test**

Add a test for missing id and clamping:
```dart
testWidgets('ignores scroll restore when id is null', (tester) async {
  SharedPreferences.setMockInitialValues({'notes.scroll.1': 200.0});

  final note = Note(
    id: null,
    title: 'No ID',
    content: 'Short note',
    type: NoteType.text,
    createdDate: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await tester.pumpWidget(MaterialApp(home: NoteDetailScreen(note: note)));
  await tester.pumpAndSettle();

  final scrollable = find.byType(Scrollable).first;
  final state = tester.state<ScrollableState>(scrollable);
  expect(state.position.pixels, 0.0);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/note_detail_screen_test.dart -v`
Expected: FAIL (restore still attempted).

**Step 3: Implement guard + clamp**

- Only restore/save when `note.id != null`.
- Clamp stored offset to `scrollController.position.maxScrollExtent` after layout.

**Step 4: Run tests**

Run: `flutter test test/screens/note_detail_screen_test.dart -v`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/screens/note_detail_screen.dart test/screens/note_detail_screen_test.dart
git commit -m "fix(notes): guard scroll restore and clamp offsets"
```

---

### Task 4: Update docs + pending list

**Files:**
- Modify: `docs/screens/notes.md`
- Modify: `docs/PENDING.md`

**Step 1: Update notes screen doc**

Add line to notes screen doc:
- “Scroll position is restored per note using local device storage.”

**Step 2: Update pending list**

Move “Notes persistence (restore scroll/cursor)” from pending to completed.

**Step 3: Commit**

```bash
git add docs/screens/notes.md docs/PENDING.md
git commit -m "docs: mark notes scroll persistence complete"
```

---

### Task 5: Verification

**Step 1: Run full test suite**

Run: `flutter test`
Expected: PASS.

**Step 2: Document results**

Note test result in PR/summary.
