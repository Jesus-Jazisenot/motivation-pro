/// Modelo del perfil de usuario
class UserProfile {
  final int? id;
  final String name;
  final List<String> challenges;
  final List<String> preferredTimes;
  final List<String> values;
  final String tonePreference;
  final DateTime createdAt;
  final int level;
  final int totalXp;
  final int currentStreak;
  final int maxStreak;

  UserProfile({
    this.id,
    required this.name,
    this.challenges = const [],
    this.preferredTimes = const [],
    this.values = const [],
    this.tonePreference = 'balanced',
    DateTime? createdAt,
    this.level = 1,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'challenges': challenges.join(','),
      'preferred_times': preferredTimes.join(','),
      'user_values': values.join(','),
      'tone_preference': tonePreference,
      'created_at': createdAt.toIso8601String(),
      'level': level,
      'total_xp': totalXp,
      'current_streak': currentStreak,
      'max_streak': maxStreak,
    };
  }

  /// Crear desde Map de SQLite
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      challenges: (map['challenges'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      preferredTimes: (map['preferred_times'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      values: (map['user_values'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      tonePreference: map['tone_preference'] as String? ?? 'balanced',
      createdAt: DateTime.parse(map['created_at'] as String),
      level: map['level'] as int? ?? 1,
      totalXp: map['total_xp'] as int? ?? 0,
      currentStreak: map['current_streak'] as int? ?? 0,
      maxStreak: map['max_streak'] as int? ?? 0,
    );
  }

  /// Copiar con cambios
  UserProfile copyWith({
    int? id,
    String? name,
    List<String>? challenges,
    List<String>? preferredTimes,
    List<String>? values,
    String? tonePreference,
    DateTime? createdAt,
    int? level,
    int? totalXp,
    int? currentStreak,
    int? maxStreak,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      challenges: challenges ?? this.challenges,
      preferredTimes: preferredTimes ?? this.preferredTimes,
      values: values ?? this.values,
      tonePreference: tonePreference ?? this.tonePreference,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, level: $level, streak: $currentStreak)';
  }
}
