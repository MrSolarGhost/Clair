/// Represents a custom collection of games
class Collection {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdDate;
  final int gameCount;

  Collection({
    this.id,
    required this.name,
    this.description,
    DateTime? createdDate,
    this.gameCount = 0,
  }) : createdDate = createdDate ?? DateTime.now();

  /// Convert Collection to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'gameCount': gameCount,
    };
  }

  /// Create Collection from SQLite Map
  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] as int),
      gameCount: map['gameCount'] as int,
    );
  }

  /// Create a copy with updated fields
  Collection copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdDate,
    int? gameCount,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdDate: createdDate ?? this.createdDate,
      gameCount: gameCount ?? this.gameCount,
    );
  }
}

/// Junction table entry linking games to collections
class CollectionGame {
  final int collectionId;
  final int gameId;
  final DateTime addedDate;

  CollectionGame({
    required this.collectionId,
    required this.gameId,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  /// Convert to Map for SQLite storage
  Map<String, dynamic> toMap() {
    return {
      'collectionId': collectionId,
      'gameId': gameId,
      'addedDate': addedDate.millisecondsSinceEpoch,
    };
  }

  /// Create from SQLite Map
  factory CollectionGame.fromMap(Map<String, dynamic> map) {
    return CollectionGame(
      collectionId: map['collectionId'] as int,
      gameId: map['gameId'] as int,
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate'] as int),
    );
  }
}
