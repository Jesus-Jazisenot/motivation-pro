class Habit {
  final int? id;
  final String name;
  final String? description;
  final bool active;
  final int currentStreak;
  final int maxStreak;
  final String? lastCompletedDate; // "YYYY-MM-DD"
  final DateTime createdAt;

  const Habit({
    this.id,
    required this.name,
    this.description,
    this.active = true,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastCompletedDate,
    required this.createdAt,
  });

  bool get completedToday {
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    return lastCompletedDate == today;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'active': active ? 1 : 0,
        'current_streak': currentStreak,
        'max_streak': maxStreak,
        'last_completed_date': lastCompletedDate,
        'created_at': createdAt.toIso8601String(),
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        active: (map['active'] as int) == 1,
        currentStreak: map['current_streak'] as int? ?? 0,
        maxStreak: map['max_streak'] as int? ?? 0,
        lastCompletedDate: map['last_completed_date'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    bool? active,
    int? currentStreak,
    int? maxStreak,
    String? lastCompletedDate,
    DateTime? createdAt,
  }) =>
      Habit(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        active: active ?? this.active,
        currentStreak: currentStreak ?? this.currentStreak,
        maxStreak: maxStreak ?? this.maxStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
        createdAt: createdAt ?? this.createdAt,
      );
}
