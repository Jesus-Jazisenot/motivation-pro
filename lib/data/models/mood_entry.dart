class MoodEntry {
  final int? id;
  final int mood; // 1-5
  final String? note;
  final int? quoteId;
  final DateTime createdAt;

  const MoodEntry({
    this.id,
    required this.mood,
    this.note,
    this.quoteId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'mood': mood,
        'note': note,
        'quote_id': quoteId,
        'created_at': createdAt.toIso8601String(),
      };

  factory MoodEntry.fromMap(Map<String, dynamic> map) => MoodEntry(
        id: map['id'] as int?,
        mood: map['mood'] as int,
        note: map['note'] as String?,
        quoteId: map['quote_id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  MoodEntry copyWith({
    int? id,
    int? mood,
    String? note,
    int? quoteId,
    DateTime? createdAt,
  }) =>
      MoodEntry(
        id: id ?? this.id,
        mood: mood ?? this.mood,
        note: note ?? this.note,
        quoteId: quoteId ?? this.quoteId,
        createdAt: createdAt ?? this.createdAt,
      );

  static String emojiForMood(int mood) {
    switch (mood) {
      case 1:
        return '😔';
      case 2:
        return '😐';
      case 3:
        return '🙂';
      case 4:
        return '😊';
      case 5:
        return '🤩';
      default:
        return '😐';
    }
  }

  static String labelForMood(int mood) {
    switch (mood) {
      case 1:
        return 'Mal';
      case 2:
        return 'Regular';
      case 3:
        return 'Bien';
      case 4:
        return 'Genial';
      case 5:
        return 'Increíble';
      default:
        return '';
    }
  }
}
