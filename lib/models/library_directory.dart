/// Represents a tracked directory for automatic game import
class LibraryDirectory {
  final int? id;
  final String path;
  final String system;
  final bool scanRecursive;
  final DateTime? lastScannedAt;
  final DateTime createdAt;

  LibraryDirectory({
    this.id,
    required this.path,
    required this.system,
    required this.scanRecursive,
    this.lastScannedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'system': system,
      'scan_recursive': scanRecursive ? 1 : 0,
      'last_scanned_at': lastScannedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from SQLite Map
  factory LibraryDirectory.fromMap(Map<String, dynamic> map) {
    return LibraryDirectory(
      id: map['id'] as int?,
      path: map['path'] as String,
      system: map['system'] as String,
      scanRecursive: map['scan_recursive'] == 1,
      lastScannedAt: map['last_scanned_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_scanned_at'] as int)
          : null,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Create copy with updated fields
  LibraryDirectory copyWith({
    int? id,
    String? path,
    String? system,
    bool? scanRecursive,
    DateTime? lastScannedAt,
    DateTime? createdAt,
  }) {
    return LibraryDirectory(
      id: id ?? this.id,
      path: path ?? this.path,
      system: system ?? this.system,
      scanRecursive: scanRecursive ?? this.scanRecursive,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      createdDate: createdAt ?? this.createdDate,
    );
  }
}
