# Guides Scroll Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Persist per-guide scroll position and restore it when reopening a guide detail view.

**Architecture:** Use `shared_preferences` to store a scroll offset per guide id. `GuideDetailScreen` will read the stored offset on open and write updates via a `ScrollController` listener, clamping to the max scroll extent.

**Tech Stack:** Flutter, shared_preferences, widget tests.

---

### Task 1: Add widget test for guide scroll restore

**Files:**
- Create: `test/screens/guide_detail_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:clair/models/guide.dart';
import 'package:clair/screens/guide_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('restores scroll position per guide', (tester) async {
    SharedPreferences.setMockInitialValues({
      'guides.scroll.1': 120.0,
    });

    final guide = Guide(
      id: 1,
      title: 'Test Guide',
      content: 'Line\n' * 200,
      createdDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: GuideDetailScreen(guide: guide)),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.pixels, greaterThanOrEqualTo(120.0));
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/guide_detail_screen_test.dart -v`
Expected: FAIL (scroll offset not restored).

**Step 3: Commit**

```bash
git add test/screens/guide_detail_screen_test.dart
git commit -m "test(guides): add scroll restore widget test"
```

---

### Task 2: Implement scroll persistence in GuideDetailScreen

**Files:**
- Modify: `lib/screens/guide_detail_screen.dart`

**Step 1: Add ScrollController + prefs integration**

- Add `ScrollController _scrollController`.
- Add `Timer? _scrollSaveTimer`.
- Load saved offset in `initState` using key `guides.scroll.<guideId>`.
- Apply offset after first frame, clamped to max extent.
- Save offset on scroll with a short debounce (200ms).
- Use the controller in the `SingleChildScrollView`.

**Step 2: Run test**

Run: `flutter test test/screens/guide_detail_screen_test.dart -v`
Expected: PASS.

**Step 3: Commit**

```bash
git add lib/screens/guide_detail_screen.dart
git commit -m "feat(guides): persist scroll position per guide"
```

---

### Task 3: Guard null ids + add test

**Files:**
- Modify: `lib/screens/guide_detail_screen.dart`
- Modify: `test/screens/guide_detail_screen_test.dart`

**Step 1: Add test for null id**

```dart
testWidgets('ignores scroll restore when id is null', (tester) async {
  SharedPreferences.setMockInitialValues({'guides.scroll.1': 200.0});

  final guide = Guide(
    id: null,
    title: 'No ID',
    content: 'Short guide',
    createdDate: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await tester.pumpWidget(MaterialApp(home: GuideDetailScreen(guide: guide)));
  await tester.pumpAndSettle();

  final scrollable = find.byType(Scrollable).first;
  final state = tester.state<ScrollableState>(scrollable);
  expect(state.position.pixels, 0.0);
});
```

**Step 2: Run test**

Run: `flutter test test/screens/guide_detail_screen_test.dart -v`
Expected: PASS.

**Step 3: Commit**

```bash
git add lib/screens/guide_detail_screen.dart test/screens/guide_detail_screen_test.dart
git commit -m "fix(guides): guard scroll restore and clamp offsets"
```

---

### Task 4: Update docs + pending list

**Files:**
- Modify: `docs/screens/guides.md`
- Modify: `docs/PENDING.md`

**Step 1: Update guides doc**

Add line to guides screen doc:
- “Scroll position is restored per guide using local device storage.”

**Step 2: Update pending list**

Move “Guides persistence (resume position)” from pending to completed.

**Step 3: Commit**

```bash
git add docs/screens/guides.md docs/PENDING.md
git commit -m "docs: mark guides scroll persistence complete"
```

---

### Task 5: Verification

**Step 1: Run full test suite**

Run: `flutter test -r expanded`
Expected: PASS.

**Step 2: Document results**

Note test result in summary.
