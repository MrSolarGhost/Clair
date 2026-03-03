/// Represents a game in the library
class Game {
  final int? id;
  final String title;
  final String? system;
  final String? genre;
  final GameStatus status;
  final String? coverPath;
  final String? executablePath;
  final DateTime? lastPlayed;
  final int playTimeMinutes;
  final DateTime addedDate;
  final bool isFavorite;
  final double? completionPercentage;
  final int fileStatus;

  Game({
    this.id,
    required this.title,
    this.system,
    this.genre,
    this.status = GameStatus.unplayed,
    this.coverPath,
    this.executablePath,
    this.lastPlayed,
    this.playTimeMinutes = 0,
    DateTime? addedDate,
    this.isFavorite = false,
    this.completionPercentage,
    this.fileStatus = 0,
  }) : addedDate = addedDate ?? DateTime.now();

  /// Convert Game to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'system': system,
      'genre': genre,
      'status': status.index,
      'coverPath': coverPath,
      'executablePath': executablePath,
      'lastPlayed': lastPlayed?.millisecondsSinceEpoch,
      'playTimeMinutes': playTimeMinutes,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'completionPercentage': completionPercentage,
      'file_status': fileStatus,
    };
  }

  /// Create Game from SQLite Map
  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      title: map['title'] as String,
      system: map['system'] as String?,
      genre: map['genre'] as String?,
      status: GameStatus.values[map['status'] as int],
      coverPath: map['coverPath'] as String?,
      executablePath: map['executablePath'] as String?,
      lastPlayed: map['lastPlayed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'] as int)
          : null,
      playTimeMinutes: map['playTimeMinutes'] as int,
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate'] as int),
      isFavorite: map['isFavorite'] == 1,
      completionPercentage: map['completionPercentage'] as double?,
      fileStatus: map['file_status'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields
  Game copyWith({
    int? id,
    String? title,
    String? system,
    String? genre,
    GameStatus? status,
    String? coverPath,
    String? executablePath,
    DateTime? lastPlayed,
    int? playTimeMinutes,
    DateTime? addedDate,
    bool? isFavorite,
    double? completionPercentage,
    int? fileStatus,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      system: system ?? this.system,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      coverPath: coverPath ?? this.coverPath,
      executablePath: executablePath ?? this.executablePath,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playTimeMinutes: playTimeMinutes ?? this.playTimeMinutes,
      addedDate: addedDate ?? this.addedDate,
      isFavorite: isFavorite ?? this.isFavorite,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      fileStatus: fileStatus ?? this.fileStatus,
    );
  }
}

/// Game completion status
enum GameStatus {
  unplayed,
  playing,
  beaten,
  completed,
  dropped,
}

extension GameStatusExtension on GameStatus {
  String get displayName {
    switch (this) {
      case GameStatus.unplayed:
        return 'Unplayed';
      case GameStatus.playing:
        return 'Playing';
      case GameStatus.beaten:
        return 'Beaten';
      case GameStatus.completed:
        return '100% Completed';
      case GameStatus.dropped:
        return 'Dropped';
    }
  }
}
