import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/game.dart';
import 'steamgriddb_service.dart';
import 'cover_storage_service.dart';
import 'cover_fetch_queue.dart';
import 'database_service.dart';

class CoverOrchestrator {
  final SteamGridDBService _steamGridDB;
  final CoverStorageService _storage;
  final DatabaseService _dbService;

  CoverOrchestrator({
    SteamGridDBService? steamGridDB,
    CoverStorageService? storage,
    DatabaseService? dbService,
  })  : _steamGridDB = steamGridDB ??
              SteamGridDBService(
                apiKey: dotenv.env['STEAMGRIDDB_API_KEY'] ?? '',
                timeout: const Duration(seconds: 3),
              ),
        _storage = storage ?? CoverStorageService(),
        _dbService = dbService ?? DatabaseService.instance;

  /// Auto-fetch cover when game is added
  /// Tries quick fetch (3s timeout), queues on failure
  Future<void> onGameAdded(Game game) async {
    if (game.id == null) return;
    if ((_steamGridDB.apiKey).isEmpty) {
      return;
    }
    if (dotenv.env['CLAIR_DISABLE_COVER_FETCH'] == '1') {
      return;
    }

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
      final db = await _dbService.database;
      final queue = CoverFetchQueue(db: db);
      await queue.add(gameId: game.id!);
    } catch (e) {
      // Queue on any error
      print('Auto-fetch failed, queuing: $e');
      final db = await _dbService.database;
      final queue = CoverFetchQueue(db: db);
      await queue.add(gameId: game.id!);
    }
  }
}
