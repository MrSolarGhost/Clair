# Game Card Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Add a full-screen Game Card detail page that loads a game from SQLite and becomes the entry point for game actions.

**Architecture:** New `GameCardScreen` that loads a game via `DatabaseService.getGame(id)`, renders core fields and action buttons, and is navigated from Play and Collections. Notes/Guides/Achievements panels are mocked until those modules are wired.

**Tech Stack:** Flutter, Dart, sqflite

---

### Task 1: Add failing widget test for GameCardScreen

**Files:**
- Create: `test/screens/game_card_screen_test.dart`

**Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:clair/screens/game_card_screen.dart';

void main() {
  testWidgets('GameCardScreen renders title and status', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameCardScreen(gameId: 1),
      ),
    );

    // Expect placeholders until data loads
    expect(find.textContaining('Loading'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/screens/game_card_screen_test.dart`
Expected: FAIL with "GameCardScreen not found" (or import error)

**Step 3: Commit**

```bash
git add test/screens/game_card_screen_test.dart
git commit -m "test: add game card screen placeholder test"
```

---

### Task 2: Implement GameCardScreen shell

**Files:**
- Create: `lib/screens/game_card_screen.dart`

**Step 1: Implement minimal screen**

```dart
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';

class GameCardScreen extends StatefulWidget {
  final int gameId;

  const GameCardScreen({super.key, required this.gameId});

  @override
  State<GameCardScreen> createState() => _GameCardScreenState();
}

class _GameCardScreenState extends State<GameCardScreen> {
  late Future<Game?> _gameFuture;

  @override
  void initState() {
    super.initState();
    _gameFuture = DatabaseService.instance.getGame(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Game?>(
        future: _gameFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }
          final game = snapshot.data;
          if (game == null) {
            return _notFoundState();
          }

          return _buildContent(context, game);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Game game) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Text(game.title, style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                _statusChip(game.status),
              ],
            ),
            const SizedBox(height: 24),
            Text(game.system ?? 'Unknown system'),
            const SizedBox(height: 8),
            Text('Last played: ${game.lastPlayed?.toLocal().toString().split(' ').first ?? 'Never'}'),
            const SizedBox(height: 8),
            Text('Play time: ${game.playTimeMinutes} min'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton('Launch', Icons.play_arrow, _mockLaunch),
                _actionButton('Status', Icons.check_circle, () {}),
                _actionButton('Notes', Icons.note, () {}),
                _actionButton('Guides', Icons.book, () {}),
                _actionButton('Achievements', Icons.emoji_events, () {}),
                _actionButton('Collections', Icons.collections_bookmark, () {}),
              ],
            ),
            const SizedBox(height: 24),
            _mockPanel('Notes', '3 notes'),
            const SizedBox(height: 12),
            _mockPanel('Guides', '2 guides'),
            const SizedBox(height: 12),
            _mockPanel('Achievements', '15/40 unlocked'),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(GameStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.displayName),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _mockPanel(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _notFoundState() {
    return const Center(child: Text('Game not found'));
  }

  Widget _errorState(String message) {
    return Center(child: Text('Error: $message'));
  }

  void _mockLaunch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Launching game (mock)...')),
    );
  }
}
```

**Step 2: Run test to verify it passes**

Run: `flutter test test/screens/game_card_screen_test.dart`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/screens/game_card_screen.dart
git commit -m "feat(ui): add game card screen"
```

---

### Task 3: Wire Play screen to GameCardScreen

**Files:**
- Modify: `lib/screens/play_screen.dart:490-510`

**Step 1: Update navigation**

```dart
import 'game_card_screen.dart';

void _openGameCard(Game game) {
  if (game.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game not available')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GameCardScreen(gameId: game.id!),
    ),
  );
}
```

**Step 2: Run existing tests (if any)**

Run: `flutter test`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/screens/play_screen.dart
git commit -m "feat(nav): open game card from play"
```

---

### Task 4: Wire Collections detail to GameCardScreen

**Files:**
- Modify: `lib/screens/collection_detail_screen.dart:270-320`

**Step 1: Add navigation on tap and Enter**

```dart
import 'game_card_screen.dart';

void _openGameCard(Game game) {
  if (game.id == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GameCardScreen(gameId: game.id!),
    ),
  );
}
```

In `_buildGameCard` onTap, call `_openGameCard(game)` after selecting.

If keyboard/controller Enter handling exists, add an Enter/Space case to call `_openGameCard` for the selected game.

**Step 2: Run tests**

Run: `flutter test`
Expected: PASS

**Step 3: Commit**

```bash
git add lib/screens/collection_detail_screen.dart
git commit -m "feat(nav): open game card from collections"
```

---

### Task 5: Light wiring for Home (if/when widgets exist)

**Files:**
- Modify: `lib/screens/home_screen.dart` (only if there are game tiles)

**Step 1: If any Home widgets render games, route them to GameCardScreen**

If Home currently has no game tiles, document that no change was required.

**Step 2: Commit (only if modified)**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat(nav): open game card from home widgets"
```

---

### Task 6: Update docs

**Files:**
- Modify: `docs/screens/game-card.md`

**Step 1: Add implementation note**

Add a short note that Game Card is a full-screen detail page and notes/guides/achievements are mocked until wired.

**Step 2: Commit**

```bash
git add docs/screens/game-card.md
git commit -m "docs: note game card implementation status"
```
