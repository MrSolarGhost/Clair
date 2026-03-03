import 'package:sqflite/sqflite.dart';
import 'steamgriddb_service.dart';
import 'cover_storage_service.dart';
import 'database_service.dart';

class CoverFetchQueue {
  final Database db;
  final SteamGridDBService? steamGridDB;
  final CoverStorageService? storage;
  final DatabaseService? gameService;

  CoverFetchQueue({
    required this.db,
    this.steamGridDB,
    this.storage,
    this.gameService,
  });

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
}
