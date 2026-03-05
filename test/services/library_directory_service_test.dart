import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clair/services/library_directory_service.dart';
import 'package:clair/services/database_service.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    
    // Initialize dotenv with empty values for testing
    dotenv.testLoad(fileInput: '');
  });

  group('LibraryDirectoryService', () {
    late LibraryDirectoryService service;
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      service = LibraryDirectoryService();
      
      final db = await dbService.database;
      await db.delete('library_directories');
      await db.delete('games');
    });

    test('addDirectory validates path exists', () async {
      expect(
        () => service.addDirectory('/nonexistent/path', 'PS Vita', false),
        throwsA(isA<DirectoryNotFoundException>()),
      );
    });
  });
}
