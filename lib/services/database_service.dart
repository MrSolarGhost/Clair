import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/collection.dart';
import '../models/achievement.dart';
import '../models/library_directory.dart';
import 'cover_orchestrator.dart';

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
      version: 4,
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
        completionPercentage REAL,
        source_directory_id INTEGER,
        file_status INTEGER DEFAULT 0,
        FOREIGN KEY (source_directory_id) REFERENCES library_directories (id) ON DELETE SET NULL
      )
    ''');

    // Collections table
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        createdDate INTEGER NOT NULL,
        gameCount INTEGER NOT NULL DEFAULT 0,
        coverPath TEXT
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

    // Library directories table
    await db.execute('''
      CREATE TABLE library_directories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL,
        system TEXT NOT NULL,
        scan_recursive INTEGER NOT NULL,
        last_scanned_at INTEGER,
        created_at INTEGER NOT NULL
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
    
    if (oldVersion < 3) {
      // Add library directories table
      await db.execute('''
        CREATE TABLE library_directories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          path TEXT NOT NULL,
          system TEXT NOT NULL,
          scan_recursive INTEGER NOT NULL,
          last_scanned_at INTEGER,
          created_at INTEGER NOT NULL
        )
      ''');
      
      // Add new columns to games table
      await db.execute('ALTER TABLE games ADD COLUMN source_directory_id INTEGER');
      await db.execute('ALTER TABLE games ADD COLUMN file_status INTEGER DEFAULT 0');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE collections ADD COLUMN coverPath TEXT');
    }
  }

  // ==================== Game CRUD Operations ====================

  /// Insert a new game
  Future<int> insertGame(Game game) async {
    final db = await database;
    final id = await db.insert('games', game.toMap());
    
    // Trigger cover fetch for new game
    final gameWithId = game.copyWith(id: id);
    final orchestrator = CoverOrchestrator();
    orchestrator.onGameAdded(gameWithId);
    
    return id;
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

  /// Get a single collection by ID
  Future<Collection?> getCollection(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Collection.fromMap(maps.first);
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

  // ============================================================
  // Library Directories
  // ============================================================

  /// Insert a library directory
  Future<int> insertLibraryDirectory(LibraryDirectory directory) async {
    final db = await database;
    return await db.insert('library_directories', directory.toMap());
  }

  /// Get library directory by ID
  Future<LibraryDirectory?> getLibraryDirectory(int id) async {
    final db = await database;
    final maps = await db.query(
      'library_directories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LibraryDirectory.fromMap(maps.first);
  }

  /// Get all library directories
  Future<List<LibraryDirectory>> getAllLibraryDirectories() async {
    final db = await database;
    final maps = await db.query('library_directories', orderBy: 'created_at DESC');
    return maps.map((map) => LibraryDirectory.fromMap(map)).toList();
  }

  /// Update library directory
  Future<void> updateLibraryDirectory(LibraryDirectory directory) async {
    final db = await database;
    await db.update(
      'library_directories',
      directory.toMap(),
      where: 'id = ?',
      whereArgs: [directory.id],
    );
  }

  /// Delete library directory
  Future<void> deleteLibraryDirectory(int id) async {
    final db = await database;
    await db.delete(
      'library_directories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get games by source directory
  Future<List<Game>> getGamesBySourceDirectory(int directoryId) async {
    final db = await database;
    final maps = await db.query(
      'games',
      where: 'source_directory_id = ?',
      whereArgs: [directoryId],
      orderBy: 'title ASC',
    );
    return maps.map((map) => Game.fromMap(map)).toList();
  }

  /// Mark game as missing
  Future<void> markGameMissing(int gameId) async {
    final db = await database;
    await db.update(
      'games',
      {'file_status': 1},
      where: 'id = ?',
      whereArgs: [gameId],
    );
  }

  /// Mark game as available
  Future<void> markGameAvailable(int gameId) async {
    final db = await database;
    await db.update(
      'games',
      {'file_status': 0},
      where: 'id = ?',
      whereArgs: [gameId],
    );
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
