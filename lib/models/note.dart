enum NoteType { text, checklist }

class Note {
  final int? id;
  final String title;
  final String content;
  final NoteType type;
  final String? gameTitle; // Optional: associate with a game
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    this.id,
    required this.title,
    required this.content,
    this.type = NoteType.text,
    this.gameTitle,
    this.tags = const [],
    this.isPinned = false,
    required this.createdDate,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString(),
      'gameTitle': gameTitle,
      'tags': tags.join(','),
      'isPinned': isPinned ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      type: NoteType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NoteType.text,
      ),
      gameTitle: map['gameTitle'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      isPinned: map['isPinned'] == 1,
      createdDate: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    NoteType? type,
    String? gameTitle,
    List<String>? tags,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      gameTitle: gameTitle ?? this.gameTitle,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdDate: createdAt ?? this.createdDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get preview {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }

  int get wordCount {
    return content.trim().split(RegExp(r'\s+')).length;
  }
}

class ChecklistItem {
  final String text;
  final bool isCompleted;

  const ChecklistItem({
    required this.text,
    this.isCompleted = false,
  });

  ChecklistItem copyWith({
    String? text,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
