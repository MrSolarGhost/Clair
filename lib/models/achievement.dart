/// Represents an achievement for a game
class Achievement {
  final int? id;
  final int gameId;
  final String title;
  final String? description;
  final bool isUnlocked;
  final DateTime? unlockedDate;

  Achievement({
    this.id,
    required this.gameId,
    required this.title,
    this.description,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  /// Convert Achievement to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'title': title,
      'description': description,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedDate': unlockedDate?.millisecondsSinceEpoch,
    };
  }

  /// Create Achievement from SQLite Map
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] as int?,
      gameId: map['gameId'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      isUnlocked: map['isUnlocked'] == 1,
      unlockedDate: map['unlockedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['unlockedDate'] as int)
          : null,
    );
  }

  /// Create a copy with updated fields
  Achievement copyWith({
    int? id,
    int? gameId,
    String? title,
    String? description,
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      title: title ?? this.title,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}
