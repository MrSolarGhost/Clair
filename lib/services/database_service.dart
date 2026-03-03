import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/collection.dart';
import '../models/achievement.dart';

/// Manages local SQLite database for games, collections, and achievements
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  /// Get database instance, initializing if needed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'clair.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Games table
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        system TEXT,
        genre TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        coverPath TEXT,
        executablePath TEXT,
        lastPlayed INTEGER,
        playTimeMinutes INTEGER NOT NULL DEFAULT 0,
        addedDate INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        completionPercentage REAL
      )
    ''');

    // Collections table
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        createdDate INTEGER NOT NULL,
        gameCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Collection-Game junction table
    await db.execute('''
      CREATE TABLE collection_games (
        collectionId INTEGER NOT NULL,
        gameId INTEGER NOT NULL,
        addedDate INTEGER NOT NULL,
        PRIMARY KEY (collectionId, gameId),
        FOREIGN KEY (collectionId) REFERENCES collections (id) ON DELETE CASCADE,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    // Achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gameId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        isUnlocked INTEGER NOT NULL DEFAULT 0,
        unlockedDate INTEGER,
        FOREIGN KEY (gameId) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    // Cover fetch queue table
    await db.execute('''
      CREATE TABLE cover_fetch_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        next_retry_at INTEGER,
        last_error TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
      )
    ''');

    // Create indices for better query performance
    await db.execute('CREATE INDEX idx_games_status ON games(status)');
    await db.execute('CREATE INDEX idx_games_system ON games(system)');
    await db.execute('CREATE INDEX idx_games_genre ON games(genre)');
    await db.execute('CREATE INDEX idx_games_lastPlayed ON games(lastPlayed)');
  }

  /// Database upgrade handler
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add cover_fetch_queue table
      await db.execute('''
        CREATE TABLE cover_fetch_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          game_id INTEGER NOT NULL,
          retry_count INTEGER DEFAULT 0,
          next_retry_at INTEGER,
          last_error TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ==================== Game CRUD Operations ====================

  /// Insert a new game
  Future<int> insertGame(Game game) async {
    final db = await database;
    return await db.insert('games', game.toMap());
  }

  /// Get a single game by ID
  Future<Game?> getGame(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Game.fromMap(maps.first);
  }

  /// Get all games
  Future<List<Game>> getAllGames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Get games without covers
  Future<List<Game>> getGamesWithoutCovers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'coverPath IS NULL OR coverPath = ?',
      whereArgs: [''],
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Get games by status
  Future<List<Game>> getGamesByStatus(GameStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'status = ?',
      whereArgs: [status.index],
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Get games by system
  Future<List<Game>> getGamesBySystem(String system) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'system = ?',
      whereArgs: [system],
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Get games by genre
  Future<List<Game>> getGamesByGenre(String genre) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'genre = ?',
      whereArgs: [genre],
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Get recently played games
  Future<List<Game>> getRecentlyPlayedGames({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'lastPlayed IS NOT NULL',
      orderBy: 'lastPlayed DESC',
      limit: limit,
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Get favorite games
  Future<List<Game>> getFavoriteGames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'isFavorite = 1',
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Update a game
  Future<int> updateGame(Game game) async {
    final db = await database;
    return await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  /// Delete a game
  Future<int> deleteGame(int id) async {
    final db = await database;
    return await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unique systems from games
  Future<List<String>> getAllSystems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT system FROM games WHERE system IS NOT NULL ORDER BY system ASC',
    );
    return maps.map((map) => map['system'] as String).toList();
  }

  /// Get unique genres from games
  Future<List<String>> getAllGenres() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT genre FROM games WHERE genre IS NOT NULL ORDER BY genre ASC',
    );
    return maps.map((map) => map['genre'] as String).toList();
  }

  // ==================== Collection CRUD Operations ====================

  /// Insert a new collection
  Future<int> insertCollection(Collection collection) async {
    final db = await database;
    return await db.insert('collections', collection.toMap());
  }

  /// Get all collections
  Future<List<Collection>> getAllCollections() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'collections',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Collection.fromMap(map)).toList();
  }

  /// Update a collection
  Future<int> updateCollection(Collection collection) async {
    final db = await database;
    return await db.update(
      'collections',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  /// Delete a collection
  Future<int> deleteCollection(int id) async {
    final db = await database;
    return await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Add game to collection
  Future<void> addGameToCollection(int collectionId, int gameId) async {
    final db = await database;
    await db.insert(
      'collection_games',
      CollectionGame(collectionId: collectionId, gameId: gameId).toMap(),
    );
    // Update game count
    await _updateCollectionGameCount(collectionId);
  }

  /// Remove game from collection
  Future<void> removeGameFromCollection(int collectionId, int gameId) async {
    final db = await database;
    await db.delete(
      'collection_games',
      where: 'collectionId = ? AND gameId = ?',
      whereArgs: [collectionId, gameId],
    );
    // Update game count
    await _updateCollectionGameCount(collectionId);
  }

  /// Get games in a collection
  Future<List<Game>> getGamesInCollection(int collectionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT g.* FROM games g
      INNER JOIN collection_games cg ON g.id = cg.gameId
      WHERE cg.collectionId = ?
      ORDER BY g.title ASC
    ''', [collectionId]);
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Update collection game count
  Future<void> _updateCollectionGameCount(int collectionId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM collection_games WHERE collectionId = ?',
      [collectionId],
    ));
    await db.update(
      'collections',
      {'gameCount': count},
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  // ==================== Achievement CRUD Operations ====================

  /// Insert a new achievement
  Future<int> insertAchievement(Achievement achievement) async {
    final db = await database;
    return await db.insert('achievements', achievement.toMap());
  }

  /// Get achievements for a game
  Future<List<Achievement>> getAchievementsForGame(int gameId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'title ASC',
    );
    return maps.map((map) => Achievement.fromMap(map)).toList();
  }

  /// Update an achievement
  Future<int> updateAchievement(Achievement achievement) async {
    final db = await database;
    return await db.update(
      'achievements',
      achievement.toMap(),
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  /// Delete an achievement
  Future<int> deleteAchievement(int id) async {
    final db = await database;
    return await db.delete(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
