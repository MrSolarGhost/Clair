enum GuideType { pdf, text, url }

enum GuideSource { manual, gamefaqs, other }

class Guide {
  final int? id;
  final String title;
  final String? gameTitle; // Optional: associate with a game
  final GuideType type;
  final GuideSource source;
  final String? localPath; // Path to downloaded file
  final String? url; // Original URL if from web
  final int currentPage; // For PDFs
  final int totalPages; // For PDFs
  final double scrollPosition; // For text guides (0.0 to 1.0)
  final DateTime? lastAccessed;
  final DateTime createdAt;

  const Guide({
    this.id,
    required this.title,
    this.gameTitle,
    required this.type,
    this.source = GuideSource.manual,
    this.localPath,
    this.url,
    this.currentPage = 0,
    this.totalPages = 0,
    this.scrollPosition = 0.0,
    this.lastAccessed,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'gameTitle': gameTitle,
      'type': type.toString(),
      'source': source.toString(),
      'localPath': localPath,
      'url': url,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'scrollPosition': scrollPosition,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Guide.fromMap(Map<String, dynamic> map) {
    return Guide(
      id: map['id'] as int?,
      title: map['title'] as String,
      gameTitle: map['gameTitle'] as String?,
      type: GuideType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      source: GuideSource.values.firstWhere(
        (e) => e.toString() == map['source'],
        orElse: () => GuideSource.manual,
      ),
      localPath: map['localPath'] as String?,
      url: map['url'] as String?,
      currentPage: map['currentPage'] as int? ?? 0,
      totalPages: map['totalPages'] as int? ?? 0,
      scrollPosition: map['scrollPosition'] as double? ?? 0.0,
      lastAccessed: map['lastAccessed'] != null
          ? DateTime.parse(map['lastAccessed'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Guide copyWith({
    int? id,
    String? title,
    String? gameTitle,
    GuideType? type,
    GuideSource? source,
    String? localPath,
    String? url,
    int? currentPage,
    int? totalPages,
    double? scrollPosition,
    DateTime? lastAccessed,
    DateTime? createdAt,
  }) {
    return Guide(
      id: id ?? this.id,
      title: title ?? this.title,
      gameTitle: gameTitle ?? this.gameTitle,
      type: type ?? this.type,
      source: source ?? this.source,
      localPath: localPath ?? this.localPath,
      url: url ?? this.url,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress {
    if (type == GuideType.pdf && totalPages > 0) {
      return currentPage / totalPages;
    }
    return scrollPosition;
  }

  String get progressText {
    if (type == GuideType.pdf && totalPages > 0) {
      return 'Page $currentPage of $totalPages';
    }
    return '${(scrollPosition * 100).toInt()}% read';
  }
}
