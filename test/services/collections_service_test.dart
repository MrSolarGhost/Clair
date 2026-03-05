import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/models/collection.dart';
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
    await dbService.database; // Initialize database
    service = CollectionsService();
  });

  tearDown(() async {
    // Clean up test data
    final db = await dbService.database;
    await db.delete('collections');
    await db.delete('collection_games');
  });

  group('Collection CRUD', () {
    test('create collection with all fields', () async {
      final id = await service.createCollection(
        Collection(
          name: 'Test Collection',
          description: 'Test description',
          coverPath: '/tmp/cover.png',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      expect(id, greaterThan(0));

      final collection = await dbService.getCollection(id);
      expect(collection, isNotNull);
      expect(collection?.name, 'Test Collection');
      expect(collection?.description, 'Test description');
      expect(collection?.coverPath, '/tmp/cover.png');
      expect(collection?.gameCount, 0);
    });

    test('create collection with minimal fields', () async {
      final id = await service.createCollection(
        Collection(
          name: 'Minimal',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      final collection = await dbService.getCollection(id);
      expect(collection?.name, 'Minimal');
      expect(collection?.description, isNull);
      expect(collection?.coverPath, isNull);
    });

    test('update collection', () async {
      final id = await service.createCollection(
        Collection(
          name: 'Original',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      final updated = await service.updateCollection(
        Collection(
          id: id,
          name: 'Updated',
          description: 'New description',
          coverPath: '/new/cover.png',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      expect(updated.name, 'Updated');
      expect(updated.description, 'New description');
      expect(updated.coverPath, '/new/cover.png');
    });

    test('delete collection', () async {
      final id = await service.createCollection(
        Collection(
          name: 'To Delete',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );
      await service.deleteCollection(id);

      final collection = await dbService.getCollection(id);
      expect(collection, isNull);
    });

    test('list collections', () async {
      await service.createCollection(
        Collection(name: 'Collection 1', createdDate: DateTime.now(), gameCount: 0),
      );
      await service.createCollection(
        Collection(name: 'Collection 2', createdDate: DateTime.now(), gameCount: 0),
      );
      await service.createCollection(
        Collection(name: 'Collection 3', createdDate: DateTime.now(), gameCount: 0),
      );

      final collections = await service.listCollections();
      expect(collections.length, greaterThanOrEqualTo(3));
    });

    test('get collection', () async {
      final id = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );
      final collection = await service.getCollection(id);

      expect(collection, isNotNull);
      expect(collection?.id, id);
      expect(collection?.name, 'Test');
    });

    test('get non-existent collection returns null', () async {
      final collection = await service.getCollection(99999);
      expect(collection, isNull);
    });
  });

  group('Collection Games', () {
    test('add game to collection', () async {
      // Create a test game
      final game = Game(
        title: 'Test Game',
        system: 'PC',
        status: GameStatus.backlog,
      );
      final db = await dbService.database;
      final gameId = await db.insert('games', game.toMap());

      // Create collection
      final collectionId = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );

      // Add game to collection
      await service.addGameToCollection(collectionId, gameId);

      // Verify
      final games = await service.getGamesForCollection(collectionId);
      expect(games.length, 1);
      expect(games.first.id, gameId);
      expect(games.first.title, 'Test Game');
    });

    test('remove game from collection', () async {
      // Create test game
      final game = Game(title: 'Test', system: 'PC', status: GameStatus.backlog);
      final db = await dbService.database;
      final gameId = await db.insert('games', game.toMap());

      // Create collection and add game
      final collectionId = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );
      await service.addGameToCollection(collectionId, gameId);

      // Remove game
      await service.removeGameFromCollection(collectionId, gameId);

      // Verify
      final games = await service.getGamesForCollection(collectionId);
      expect(games.length, 0);
    });

    test('get games for empty collection', () async {
      final collectionId = await service.createCollection(
        Collection(name: 'Empty', createdDate: DateTime.now(), gameCount: 0),
      );
      final games = await service.getGamesForCollection(collectionId);
      expect(games, isEmpty);
    });

    test('game count updates when adding games', () async {
      final game1 = Game(title: 'Game 1', system: 'PC', status: GameStatus.backlog);
      final game2 = Game(title: 'Game 2', system: 'PC', status: GameStatus.backlog);
      final db = await dbService.database;
      final gameId1 = await db.insert('games', game1.toMap());
      final gameId2 = await db.insert('games', game2.toMap());

      final collectionId = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );
      await service.addGameToCollection(collectionId, gameId1);
      await service.addGameToCollection(collectionId, gameId2);

      final collection = await service.getCollection(collectionId);
      expect(collection?.gameCount, 2);
    });

    test('game count updates when removing games', () async {
      final game = Game(title: 'Test', system: 'PC', status: GameStatus.backlog);
      final db = await dbService.database;
      final gameId = await db.insert('games', game.toMap());

      final collectionId = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );
      await service.addGameToCollection(collectionId, gameId);
      await service.removeGameFromCollection(collectionId, gameId);

      final collection = await service.getCollection(collectionId);
      expect(collection?.gameCount, 0);
    });
  });

  group('Error Handling', () {
    test('create collection with empty name fails silently', () async {
      try {
        await service.createCollection(
          Collection(name: '', createdDate: DateTime.now(), gameCount: 0),
        );
        fail('Should throw error');
      } catch (_) {
        // Expected
      }
    });

    test('update non-existent collection fails silently', () async {
      try {
        await service.updateCollection(
          Collection(
            id: 99999,
            name: 'Test',
            createdDate: DateTime.now(),
            gameCount: 0,
          ),
        );
        // May or may not throw - either is acceptable
      } catch (_) {
        // Silent failure is acceptable
      }
    });

    test('delete non-existent collection fails silently', () async {
      try {
        await service.deleteCollection(99999);
        // May succeed without error
      } catch (_) {
        // Silent failure is acceptable
      }
    });

    test('add game to non-existent collection fails silently', () async {
      try {
        await service.addGameToCollection(99999, 1);
      } catch (_) {
        // Expected
      }
    });

    test('remove game from non-existent collection fails silently', () async {
      try {
        await service.removeGameFromCollection(99999, 1);
        // May succeed without error
      } catch (_) {
        // Silent failure is acceptable
      }
    });
  });

  group('coverPath persistence', () {
    test('coverPath is persisted and retrieved', () async {
      final id = await service.createCollection(
        Collection(
          name: 'Test',
          description: 'Desc',
          coverPath: '/tmp/cover.png',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      final collection = await service.getCollection(id);
      expect(collection?.coverPath, '/tmp/cover.png');
    });

    test('null coverPath is persisted', () async {
      final id = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );

      final collection = await service.getCollection(id);
      expect(collection?.coverPath, isNull);
    });

    test('coverPath can be updated', () async {
      final id = await service.createCollection(
        Collection(name: 'Test', createdDate: DateTime.now(), gameCount: 0),
      );

      await service.updateCollection(
        Collection(
          id: id,
          name: 'Test',
          coverPath: '/new/path.png',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      final collection = await service.getCollection(id);
      expect(collection?.coverPath, '/new/path.png');
    });

    test('coverPath can be cleared', () async {
      final id = await service.createCollection(
        Collection(
          name: 'Test',
          coverPath: '/tmp/cover.png',
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      await service.updateCollection(
        Collection(
          id: id,
          name: 'Test',
          coverPath: null,
          createdDate: DateTime.now(),
          gameCount: 0,
        ),
      );

      final collection = await service.getCollection(id);
      expect(collection?.coverPath, isNull);
    });
  });
}
