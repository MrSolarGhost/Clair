import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/models/library_directory.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService - Library Directories', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      final db = await dbService.database;
      // Clean up
      await db.delete('library_directories');
      await db.delete('games');
    });

    test('insertLibraryDirectory saves and returns directory with id', () async {
      final dir = LibraryDirectory(
        path: '/test/roms/vita',
        system: 'PS Vita',
        scanRecursive: true,
      );

      final id = await dbService.insertLibraryDirectory(dir);
      expect(id, greaterThan(0));

      final retrieved = await dbService.getLibraryDirectory(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.path, '/test/roms/vita');
      expect(retrieved.system, 'PS Vita');
      expect(retrieved.scanRecursive, true);
    });
  });
}
