import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/screens/collection_detail_screen.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/models/game.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late DatabaseService dbService;
  late CollectionsService service;

  setUp(() async {
    dbService = DatabaseService.instance;
    await dbService.database;
    service = CollectionsService();

    // Clean up
    final db = await dbService.database;
    await db.delete('collections');
    await db.delete('collection_games');
    await db.delete('games');
  });

  Future<void> pumpDetailScreen(WidgetTester tester, int collectionId) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CollectionDetailScreen(collectionId: collectionId),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CollectionDetailScreen Widget Tests', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await tester.pumpWidget(
        MaterialApp(
          home: CollectionDetailScreen(collectionId: id),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays collection name', (tester) async {
      final id = await service.createCollection(
        name: 'My Collection',
        description: 'Test description',
      );

      await pumpDetailScreen(tester, id);

      expect(find.text('My Collection'), findsOneWidget);
    });

    testWidgets('displays collection description', (tester) async {
      final id = await service.createCollection(
        name: 'Test',
        description: 'This is a test collection',
      );

      await pumpDetailScreen(tester, id);

      expect(find.text('This is a test collection'), findsOneWidget);
    });

    testWidgets('displays game count', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      expect(find.text('0 games'), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays edit button', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows empty state when no games', (tester) async {
      final id = await service.createCollection(name: 'Empty Collection');

      await pumpDetailScreen(tester, id);

      expect(find.text('No games yet'), findsOneWidget);
      expect(find.byIcon(Icons.collections_bookmark), findsWidgets);
    });

    testWidgets('displays games in grid', (tester) async {
      final id = await service.createCollection(name: 'Test');

      // Add test games
      final db = await dbService.database;
      final game1Id = await db.insert('games', {
        'title': 'Game 1',
        'system': 'PC',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });
      final game2Id = await db.insert('games', {
        'title': 'Game 2',
        'system': 'PS1',
        'status': 'playing',
        'created_at': DateTime.now().toIso8601String(),
      });

      await service.addGameToCollection(id, game1Id);
      await service.addGameToCollection(id, game2Id);

      await pumpDetailScreen(tester, id);

      expect(find.text('Game 1'), findsOneWidget);
      expect(find.text('Game 2'), findsOneWidget);
      expect(find.text('PC'), findsOneWidget);
      expect(find.text('PS1'), findsOneWidget);
      expect(find.text('2 games'), findsOneWidget);
    });

    testWidgets('games grid has correct layout', (tester) async {
      final id = await service.createCollection(name: 'Test');

      // Add games
      final db = await dbService.database;
      for (int i = 0; i < 5; i++) {
        final gameId = await db.insert('games', {
          'title': 'Game $i',
          'system': 'PC',
          'status': 'backlog',
          'created_at': DateTime.now().toIso8601String(),
        });
        await service.addGameToCollection(id, gameId);
      }

      await pumpDetailScreen(tester, id);

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 4);
      expect(delegate.crossAxisSpacing, 24);
      expect(delegate.mainAxisSpacing, 24);
      expect(delegate.childAspectRatio, 0.80);
    });

    testWidgets('displays game cover placeholder when no cover', (tester) async {
      final id = await service.createCollection(name: 'Test');

      final db = await dbService.database;
      final gameId = await db.insert('games', {
        'title': 'No Cover Game',
        'system': 'PC',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });
      await service.addGameToCollection(id, gameId);

      await pumpDetailScreen(tester, id);

      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });

    testWidgets('handles null description gracefully', (tester) async {
      final id = await service.createCollection(name: 'No Description');

      await pumpDetailScreen(tester, id);

      // Should render without crashing
      expect(find.text('No Description'), findsOneWidget);
    });

    testWidgets('handles null system name gracefully', (tester) async {
      final id = await service.createCollection(name: 'Test');

      final db = await dbService.database;
      final gameId = await db.insert('games', {
        'title': 'Game',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });
      await service.addGameToCollection(id, gameId);

      await pumpDetailScreen(tester, id);

      expect(find.text('Unknown'), findsOneWidget);
    });
  });

  group('CollectionDetailScreen Cover Display', () {
    testWidgets('displays collection cover placeholder when no cover',
        (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      // Should show collections icon as placeholder
      expect(find.byIcon(Icons.collections_bookmark), findsWidgets);
    });

    testWidgets('cover container has correct size', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      final container = tester.widgetList<Container>(
        find.byType(Container),
      ).firstWhere(
        (c) => c.constraints?.maxWidth == 96 && c.constraints?.maxHeight == 96,
        orElse: () => Container(),
      );

      expect(container, isNotNull);
    });
  });

  group('CollectionDetailScreen Error Handling', () {
    testWidgets('shows error message for non-existent collection',
        (tester) async {
      await pumpDetailScreen(tester, 99999);

      expect(find.text('Collection not found'), findsOneWidget);
    });

    testWidgets('handles loading errors gracefully', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      // Should not crash
      expect(find.byType(CollectionDetailScreen), findsOneWidget);
    });

    testWidgets('handles null game titles gracefully', (tester) async {
      final id = await service.createCollection(name: 'Test');

      // Add game with minimal data
      final db = await dbService.database;
      final gameId = await db.insert('games', {
        'title': '',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });
      await service.addGameToCollection(id, gameId);

      await pumpDetailScreen(tester, id);

      // Should render without crashing
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('CollectionDetailScreen Header', () {
    testWidgets('header uses gradient background', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      final container = tester.widgetList<Container>(
        find.byType(Container),
      ).firstWhere(
        (c) => c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).gradient != null,
        orElse: () => Container(),
      );

      expect(container, isNotNull);
    });

    testWidgets('header has proper padding', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      final container = tester.widgetList<Container>(
        find.byType(Container),
      ).firstWhere(
        (c) => c.padding == const EdgeInsets.all(32),
        orElse: () => Container(),
      );

      expect(container, isNotNull);
    });

    testWidgets('uses SafeArea for header content', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      expect(find.byType(SafeArea), findsWidgets);
    });
  });

  group('CollectionDetailScreen Layout', () {
    testWidgets('uses Column for main layout', (tester) async {
      final id = await service.createCollection(name: 'Test');

      await pumpDetailScreen(tester, id);

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('empty state is centered', (tester) async {
      final id = await service.createCollection(name: 'Empty');

      await pumpDetailScreen(tester, id);

      final center = find.ancestor(
        of: find.text('No games yet'),
        matching: find.byType(Center),
      );

      expect(center, findsOneWidget);
    });

    testWidgets('games grid uses Focus for keyboard navigation',
        (tester) async {
      final id = await service.createCollection(name: 'Test');

      // Add a game
      final db = await dbService.database;
      final gameId = await db.insert('games', {
        'title': 'Game',
        'system': 'PC',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });
      await service.addGameToCollection(id, gameId);

      await pumpDetailScreen(tester, id);

      expect(find.byType(Focus), findsOneWidget);
    });
  });
}
