import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clair/services/database_service.dart';
import 'package:clair/services/collections_service.dart';
import 'package:clair/models/collection.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  test('collection coverPath is persisted', () async {
    final dbService = DatabaseService.instance;
    final id = await dbService.insertCollection(Collection(
      name: 'Test',
      description: 'Desc',
      coverPath: '/tmp/cover.png',
    ));

    final collection = await dbService.getCollection(id);
    expect(collection?.coverPath, '/tmp/cover.png');
  });

  test('create/update/delete collection', () async {
    final service = CollectionsService();
    final id = await service.createCollection(Collection(name: 'Test'));
    final updated = await service.updateCollection(
      Collection(id: id, name: 'Updated'),
    );
    expect(updated.name, 'Updated');
    await service.deleteCollection(id);
  });
}
