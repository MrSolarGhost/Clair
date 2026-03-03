import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clair/services/library_directory_service.dart';
import 'package:clair/services/database_service.dart';
import 'package:path/path.dart' as path;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Initialize dotenv for testing
    dotenv.testLoad(fileInput: '');
  });

  group('Library Directory Integration', () {
    late LibraryDirectoryService service;
    late DatabaseService dbService;
    late Directory testDir;

    setUp(() async {
      service = LibraryDirectoryService();
      dbService = DatabaseService.instance;

      // Create test directory with mock game files
      testDir = Directory.systemTemp.createTempSync('clair_test_');
      File(path.join(testDir.path, 'game1.vpk')).writeAsStringSync('mock');
      File(path.join(testDir.path, 'game2.iso')).writeAsStringSync('mock');
      
      // Clean database
      final db = await dbService.database;
      await db.delete('library_directories');
      await db.delete('games');
    });

    tearDown(() async {
      testDir.deleteSync(recursive: true);
    });

    test('add directory imports games', () async {
      final dir = await service.addDirectory(
        testDir.path,
        'PS Vita',
        false,
      );

      expect(dir.id, isNotNull);

      final games = await dbService.getGamesBySourceDirectory(dir.id!);
      expect(games.length, 2);
      expect(games[0].title, anyOf('Game1', 'Game2'));
    });

    test('refresh detects new files', () async {
      final dir = await service.addDirectory(testDir.path, 'PS Vita', false);
      
      // Add new file
      File(path.join(testDir.path, 'game3.vpk')).writeAsStringSync('mock');
      
      await service.refreshDirectory(dir.id!);

      final games = await dbService.getGamesBySourceDirectory(dir.id!);
      expect(games.length, 3);
    });

    test('refresh marks missing files', () async {
      final dir = await service.addDirectory(testDir.path, 'PS Vita', false);
      
      // Delete a file
      File(path.join(testDir.path, 'game1.vpk')).deleteSync();
      
      await service.refreshDirectory(dir.id!);

      final games = await dbService.getGamesBySourceDirectory(dir.id!);
      final missing = games.where((g) => g.fileStatus == 1).toList();
      expect(missing.length, 1);
    });
  });
}
