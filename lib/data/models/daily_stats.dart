/// Modelo de estadísticas diarias
class DailyStats {
  final int? id;
  final DateTime date;
  final int quotesViewed;
  final int timeSpentSeconds;
  final List<String> categoriesViewed;
  final int reflectionsWritten;

  DailyStats({
    this.id,
    required this.date,
    this.quotesViewed = 0,
    this.timeSpentSeconds = 0,
    this.categoriesViewed = const [],
    this.reflectionsWritten = 0,
  });

  /// Convertir a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'quotes_viewed': quotesViewed,
      'time_spent_seconds': timeSpentSeconds,
      'categories_viewed': categoriesViewed.join(','),
      'reflections_written': reflectionsWritten,
    };
  }

  /// Crear desde Map de SQLite
  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      quotesViewed: map['quotes_viewed'] as int? ?? 0,
      timeSpentSeconds: map['time_spent_seconds'] as int? ?? 0,
      categoriesViewed: (map['categories_viewed'] as String)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
      reflectionsWritten: map['reflections_written'] as int? ?? 0,
    );
  }

  /// Copiar con cambios
  DailyStats copyWith({
    int? id,
    DateTime? date,
    int? quotesViewed,
    int? timeSpentSeconds,
    List<String>? categoriesViewed,
    int? reflectionsWritten,
  }) {
    return DailyStats(
      id: id ?? this.id,
      date: date ?? this.date,
      quotesViewed: quotesViewed ?? this.quotesViewed,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      categoriesViewed: categoriesViewed ?? this.categoriesViewed,
      reflectionsWritten: reflectionsWritten ?? this.reflectionsWritten,
    );
  }

  @override
  String toString() {
    return 'DailyStats(date: $date, quotesViewed: $quotesViewed)';
  }
}
