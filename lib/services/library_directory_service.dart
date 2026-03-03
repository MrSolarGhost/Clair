import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/library_directory.dart';
import '../models/discovered_game.dart';
import '../models/game.dart';
import 'database_service.dart';
import 'directory_scanner_service.dart';
import 'cover_orchestrator.dart';

class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  
  @override
  String toString() => message;
}

/// Service for managing library directories and importing games
class LibraryDirectoryService {
  final DatabaseService _dbService = DatabaseService.instance;
  final DirectoryScannerService _scanner = DirectoryScannerService();
  final CoverOrchestrator _coverOrchestrator = CoverOrchestrator();

  /// Add a new library directory and scan it
  Future<LibraryDirectory> addDirectory(
    String path,
    String system,
    bool scanRecursive,
  ) async {
    // Validate directory exists
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw DirectoryNotFoundException('Directory not found: $path');
    }

    // Save directory to database
    final libDir = LibraryDirectory(
      path: path,
      system: system,
      scanRecursive: scanRecursive,
    );
    
    final id = await _dbService.insertLibraryDirectory(libDir);
    final savedDir = libDir.copyWith(id: id);

    // Scan and import games
    await _scanAndImport(savedDir);

    return savedDir;
  }

  /// Refresh an existing library directory
  Future<void> refreshDirectory(int directoryId) async {
    final libDir = await _dbService.getLibraryDirectory(directoryId);
    if (libDir == null) {
      throw Exception('Library directory not found: $directoryId');
    }

    await _scanAndImport(libDir);
  }

  /// Remove a library directory (does not delete games)
  Future<void> removeDirectory(int directoryId) async {
    await _dbService.deleteLibraryDirectory(directoryId);
  }

  /// Get all library directories
  Future<List<LibraryDirectory>> getAllDirectories() async {
    return await _dbService.getAllLibraryDirectories();
  }

  /// Scan directory and import/update games
  Future<void> _scanAndImport(LibraryDirectory libDir) async {
    // Scan filesystem
    final discovered = await _scanner.scanDirectory(
      libDir.path,
      libDir.system,
      libDir.scanRecursive,
    );

    // Get existing games from this directory
    final existing = await _dbService.getGamesBySourceDirectory(libDir.id!);
    final existingPaths = existing.map((g) => g.executablePath).toSet();

    // Track which existing games we've seen (to detect missing files)
    final seenPaths = <String>{};

    // Import new games
    for (final disc in discovered) {
      seenPaths.add(disc.executablePath);

      if (!existingPaths.contains(disc.executablePath)) {
        // New game - insert it
        final game = Game(
          title: disc.title,
          system: disc.system,
          executablePath: disc.executablePath,
        );
        
        final gameId = await _dbService.insertGame(game);
        
        // Update with source directory and ID
        final updatedGame = game.copyWith(
          id: gameId,
        );
        
        // Set source_directory_id manually (not in Game model copyWith)
        final db = await _dbService.database;
        await db.update(
          'games',
          {'source_directory_id': libDir.id},
          where: 'id = ?',
          whereArgs: [gameId],
        );

        // Trigger cover fetch if API key is configured
        final apiKey = dotenv.env['STEAMGRIDDB_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          await _coverOrchestrator.onGameAdded(updatedGame);
        }
      } else {
        // Existing game - mark as available if it was missing
        final existingGame = existing.firstWhere(
          (g) => g.executablePath == disc.executablePath,
        );
        await _dbService.markGameAvailable(existingGame.id!);
      }
    }

    // Mark missing games
    for (final game in existing) {
      if (!seenPaths.contains(game.executablePath)) {
        await _dbService.markGameMissing(game.id!);
      }
    }

    // Update last scanned timestamp
    final updated = libDir.copyWith(lastScannedAt: DateTime.now());
    await _dbService.updateLibraryDirectory(updated);
  }
}
