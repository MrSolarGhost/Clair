import '../models/collection.dart';
import '../models/game.dart';
import 'database_service.dart';

class CollectionsService {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<int> createCollection(Collection collection) async {
    return _dbService.insertCollection(collection);
  }

  Future<Collection> updateCollection(Collection collection) async {
    await _dbService.updateCollection(collection);
    final updated = await _dbService.getCollection(collection.id!);
    return updated ?? collection;
  }

  Future<void> deleteCollection(int id) async {
    await _dbService.deleteCollection(id);
  }

  Future<Collection?> getCollection(int id) async {
    return _dbService.getCollection(id);
  }

  Future<List<Collection>> listCollections() async {
    return _dbService.getAllCollections();
  }

  Future<void> addGameToCollection(int collectionId, int gameId) async {
    await _dbService.addGameToCollection(collectionId, gameId);
  }

  Future<void> removeGameFromCollection(int collectionId, int gameId) async {
    await _dbService.removeGameFromCollection(collectionId, gameId);
  }

  Future<List<Game>> getGamesForCollection(int collectionId) async {
    return _dbService.getGamesInCollection(collectionId);
  }
}
