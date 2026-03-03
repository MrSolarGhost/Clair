import '../models/game.dart';
import '../services/database_service.dart';

/// Utility to populate database with sample games for testing
class SampleData {
  static Future<void> populateSampleGames() async {
    final db = DatabaseService.instance;

    // Check if we already have games
    final existingGames = await db.getAllGames();
    if (existingGames.isNotEmpty) return;

    // Add sample games
    final sampleGames = [
      Game(
        title: 'The Legend of Zelda: Breath of the Wild',
        system: 'Nintendo Switch',
        genre: 'Action-Adventure',
        status: GameStatus.playing,
        playTimeMinutes: 2340,
      ),
      Game(
        title: 'Celeste',
        system: 'PC',
        genre: 'Platformer',
        status: GameStatus.completed,
        playTimeMinutes: 720,
        completionPercentage: 100.0,
      ),
      Game(
        title: 'Hollow Knight',
        system: 'PC',
        genre: 'Metroidvania',
        status: GameStatus.playing,
        playTimeMinutes: 1560,
        completionPercentage: 85.0,
      ),
      Game(
        title: 'Super Mario Odyssey',
        system: 'Nintendo Switch',
        genre: 'Platformer',
        status: GameStatus.beaten,
        playTimeMinutes: 900,
        completionPercentage: 75.0,
      ),
      Game(
        title: 'Elden Ring',
        system: 'PC',
        genre: 'Action RPG',
        status: GameStatus.unplayed,
      ),
      Game(
        title: 'Hades',
        system: 'PC',
        genre: 'Roguelike',
        status: GameStatus.completed,
        playTimeMinutes: 3600,
        completionPercentage: 100.0,
        isFavorite: true,
      ),
      Game(
        title: 'Metroid Prime',
        system: 'GameCube',
        genre: 'Action-Adventure',
        status: GameStatus.beaten,
        playTimeMinutes: 780,
      ),
      Game(
        title: 'Portal 2',
        system: 'PC',
        genre: 'Puzzle',
        status: GameStatus.completed,
        playTimeMinutes: 480,
        completionPercentage: 100.0,
      ),
      Game(
        title: 'Persona 5 Royal',
        system: 'PlayStation 5',
        genre: 'JRPG',
        status: GameStatus.dropped,
        playTimeMinutes: 1200,
        completionPercentage: 35.0,
      ),
      Game(
        title: 'Stardew Valley',
        system: 'PC',
        genre: 'Simulation',
        status: GameStatus.playing,
        playTimeMinutes: 5400,
        completionPercentage: 60.0,
        isFavorite: true,
      ),
    ];

    for (final game in sampleGames) {
      await db.insertGame(game);
    }
  }
}
