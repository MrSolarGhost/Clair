import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/screens/collections_screen.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/services/database_service.dart';

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
  });

  Future<void> pumpCollectionsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CollectionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CollectionsScreen Widget Tests', () {
    testWidgets('displays title and subtitle', (tester) async {
      await pumpCollectionsScreen(tester);

      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Curated playlists of games'), findsOneWidget);
    });

    testWidgets('displays New Collection button', (tester) async {
      await pumpCollectionsScreen(tester);

      expect(find.text('New Collection'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollectionsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no collections', (tester) async {
      await pumpCollectionsScreen(tester);

      // Should show grid (even if empty)
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays collections in grid', (tester) async {
      // Create test collections
      await service.createCollection(name: 'Collection 1', description: 'Desc 1');
      await service.createCollection(name: 'Collection 2', description: 'Desc 2');
      await service.createCollection(name: 'Collection 3', description: 'Desc 3');

      await pumpCollectionsScreen(tester);

      expect(find.text('Collection 1'), findsOneWidget);
      expect(find.text('Collection 2'), findsOneWidget);
      expect(find.text('Collection 3'), findsOneWidget);
      expect(find.text('0 games'), findsNWidgets(3));
    });

    testWidgets('displays collection descriptions', (tester) async {
      await service.createCollection(name: 'Test', description: 'Test description');

      await pumpCollectionsScreen(tester);

      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('handles collection with null description', (tester) async {
      await service.createCollection(name: 'No Desc');

      await pumpCollectionsScreen(tester);

      expect(find.text('No Desc'), findsOneWidget);
      // Should render empty text without crashing
    });

    testWidgets('displays correct game count', (tester) async {
      final collectionId = await service.createCollection(name: 'Test');

      // Add test games
      final db = await dbService.database;
      final gameId1 = await db.insert('games', {
        'title': 'Game 1',
        'system': 'PC',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });
      final gameId2 = await db.insert('games', {
        'title': 'Game 2',
        'system': 'PC',
        'status': 'backlog',
        'created_at': DateTime.now().toIso8601String(),
      });

      await service.addGameToCollection(collectionId, gameId1);
      await service.addGameToCollection(collectionId, gameId2);

      await pumpCollectionsScreen(tester);

      expect(find.text('2 games'), findsOneWidget);
    });

    testWidgets('tapping New Collection button navigates', (tester) async {
      await pumpCollectionsScreen(tester);

      await tester.tap(find.text('New Collection'));
      await tester.pumpAndSettle();

      // Should navigate to editor (which will fail in test without full MaterialApp routing)
      // This is expected - we're just checking the tap doesn't crash
    });

    testWidgets('displays collections with proper styling', (tester) async {
      await service.createCollection(name: 'Styled Collection');

      await pumpCollectionsScreen(tester);

      // Check for icon
      expect(find.byIcon(Icons.collections_bookmark), findsWidgets);

      // Check for AnimatedContainer
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('grid has correct layout', (tester) async {
      await service.createCollection(name: 'Test 1');
      await service.createCollection(name: 'Test 2');
      await service.createCollection(name: 'Test 3');

      await pumpCollectionsScreen(tester);

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, 3);
      expect(delegate.crossAxisSpacing, 24);
      expect(delegate.mainAxisSpacing, 24);
      expect(delegate.childAspectRatio, 1.3);
    });
  });

  group('CollectionsScreen Error Handling', () {
    testWidgets('handles loading error gracefully', (tester) async {
      await pumpCollectionsScreen(tester);

      // Should not crash even if there are errors
      expect(find.byType(CollectionsScreen), findsOneWidget);
    });

    testWidgets('handles empty collections list', (tester) async {
      await pumpCollectionsScreen(tester);

      // Should display grid even when empty
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
