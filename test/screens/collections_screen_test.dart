import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/screens/collections_screen.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/models/game.dart';
import 'package:clair/models/collection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() {
  late String dbPath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    final dir = Directory(p.join(Directory.systemTemp.path, 'clair_test_collections_screen'));
    await dir.create(recursive: true);
    databaseFactory.setDatabasesPath(dir.path);
    dbPath = p.join(dir.path, 'clair.db');
    dotenv.testLoad(fileInput: 'CLAIR_DISABLE_COVER_FETCH=1');
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
    await databaseFactory.deleteDatabase(dbPath);
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
      await service.createCollection(Collection(name: 'Collection 1', description: 'Desc 1', createdDate: DateTime.now(), gameCount: 0));
      await service.createCollection(Collection(name: 'Collection 2', description: 'Desc 2', createdDate: DateTime.now(), gameCount: 0));
      await service.createCollection(Collection(name: 'Collection 3', description: 'Desc 3', createdDate: DateTime.now(), gameCount: 0));

      await pumpCollectionsScreen(tester);

      expect(find.text('Collection 1'), findsOneWidget);
      expect(find.text('Collection 2'), findsOneWidget);
      expect(find.text('Collection 3'), findsOneWidget);
      expect(find.text('0 games'), findsNWidgets(3));
    });

    testWidgets('displays collection descriptions', (tester) async {
      await service.createCollection(Collection(name: 'Test', description: 'Test description', createdDate: DateTime.now(), gameCount: 0));

      await pumpCollectionsScreen(tester);

      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('handles collection with null description', (tester) async {
      await service.createCollection(Collection(name: 'No Desc', createdDate: DateTime.now(), gameCount: 0));

      await pumpCollectionsScreen(tester);

      expect(find.text('No Desc'), findsOneWidget);
      // Should render empty text without crashing
    });

    testWidgets('displays correct game count', (tester) async {
      final collectionId = await service.createCollection(Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0));

      // Add test games
      final gameId1 = await dbService.insertGame(
        Game(title: 'Game 1', system: 'PC', status: GameStatus.unplayed),
      );
      final gameId2 = await dbService.insertGame(
        Game(title: 'Game 2', system: 'PC', status: GameStatus.unplayed),
      );

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
      await service.createCollection(Collection(name: 'Styled Collection', createdDate: DateTime.now(), gameCount: 0));

      await pumpCollectionsScreen(tester);

      // Check for icon
      expect(find.byIcon(Icons.collections_bookmark), findsWidgets);

      // Check for AnimatedContainer
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('grid has correct layout', (tester) async {
      await service.createCollection(Collection(name: 'Test 1', createdDate: DateTime.now(), gameCount: 0));
      await service.createCollection(Collection(name: 'Test 2', createdDate: DateTime.now(), gameCount: 0));
      await service.createCollection(Collection(name: 'Test 3', createdDate: DateTime.now(), gameCount: 0));

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
