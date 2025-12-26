import '../../data/database/database_helper.dart';
import '../../data/models/daily_stats.dart';
import '../../data/models/quote.dart';

class StatsService {
  static final StatsService instance = StatsService._init();

  StatsService._init();

  /// Registrar que se vio una frase
  Future<void> trackQuoteView(Quote quote) async {
    final db = DatabaseHelper.instance;
    final today = DateTime.now();

    // Obtener o crear stats del día
    var stats = await db.getDailyStats(today);

    if (stats == null) {
      // Crear nuevo registro para hoy
      stats = DailyStats(
        date: today,
        quotesViewed: 1,
        categoriesViewed: [quote.category],
      );
    } else {
      // Actualizar existente
      final categories = List<String>.from(stats.categoriesViewed);
      if (!categories.contains(quote.category)) {
        categories.add(quote.category);
      }

      stats = stats.copyWith(
        quotesViewed: stats.quotesViewed + 1,
        categoriesViewed: categories,
      );
    }

    // Guardar
    await db.upsertDailyStats(stats);

    print('📊 Quote view tracked: ${stats.quotesViewed} today');
  }

  /// Obtener frases vistas hoy
  Future<int> getQuotesViewedToday() async {
    final db = DatabaseHelper.instance;
    final today = DateTime.now();
    final stats = await db.getDailyStats(today);

    return stats?.quotesViewed ?? 0;
  }

  /// Obtener total histórico de frases vistas
  Future<int> getTotalQuotesViewed() async {
    final db = DatabaseHelper.instance;
    return await db.getTotalQuotesViewed();
  }

  /// Calcular racha actual
  Future<int> getCurrentStreak() async {
    final db = DatabaseHelper.instance;
    final stats = await db.getRecentStats(365); // Último año

    if (stats.isEmpty) return 0;

    // Ordenar por fecha descendente
    stats.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final stat in stats) {
      final statDate = DateTime(stat.date.year, stat.date.month, stat.date.day);
      final expectedDate =
          DateTime(checkDate.year, checkDate.month, checkDate.day);

      // Si es hoy o ayer
      if (statDate.isAtSameMomentAs(expectedDate) ||
          statDate.isAtSameMomentAs(
              expectedDate.subtract(const Duration(days: 1)))) {
        if (stat.quotesViewed > 0) {
          streak++;
          checkDate = statDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return streak;
  }

  /// Obtener racha máxima
  Future<int> getMaxStreak() async {
    final db = DatabaseHelper.instance;
    final stats = await db.getRecentStats(365);

    if (stats.isEmpty) return 0;

    stats.sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 0;
    int maxStreak = 0;
    DateTime? lastDate;

    for (final stat in stats) {
      if (stat.quotesViewed == 0) {
        currentStreak = 0;
        lastDate = null;
        continue;
      }

      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final daysDiff = stat.date.difference(lastDate).inDays;
        if (daysDiff == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
      }

      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }

      lastDate = stat.date;
    }

    return maxStreak;
  }

  /// Obtener categorías más vistas
  Future<Map<String, int>> getCategoryStats() async {
    final db = DatabaseHelper.instance;
    final allQuotes = await db.getAllQuotes();

    final categoryCounts = <String, int>{};

    for (final quote in allQuotes) {
      if (quote.viewCount > 0) {
        categoryCounts[quote.category] =
            (categoryCounts[quote.category] ?? 0) + quote.viewCount;
      }
    }

    return categoryCounts;
  }

  /// Actualizar racha en perfil de usuario
  Future<void> updateUserStreak() async {
    final db = DatabaseHelper.instance;
    final profile = await db.getUserProfile();

    if (profile == null) return;

    final currentStreak = await getCurrentStreak();
    final maxStreak = await getMaxStreak();

    final updatedProfile = profile.copyWith(
      currentStreak: currentStreak,
      maxStreak: maxStreak > profile.maxStreak ? maxStreak : profile.maxStreak,
    );

    await db.updateUserProfile(updatedProfile);

    print('🔥 Streak updated: $currentStreak days');
  }

  /// Agregar XP (para gamificación futura)
  Future<void> addXP(int xp) async {
    final db = DatabaseHelper.instance;
    final profile = await db.getUserProfile();

    if (profile == null) return;

    final newTotalXp = profile.totalXp + xp;
    final newLevel = (newTotalXp / 100).floor() + 1;

    final updatedProfile = profile.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
    );

    await db.updateUserProfile(updatedProfile);

    print('⭐ XP added: +$xp (Total: $newTotalXp, Level: $newLevel)');
  }

  /// Registrar tiempo en app
  Future<void> trackTimeSpent(int seconds) async {
    final db = DatabaseHelper.instance;
    final today = DateTime.now();

    var stats = await db.getDailyStats(today);

    if (stats == null) {
      stats = DailyStats(
        date: today,
        timeSpentSeconds: seconds,
      );
    } else {
      stats = stats.copyWith(
        timeSpentSeconds: stats.timeSpentSeconds + seconds,
      );
    }

    await db.upsertDailyStats(stats);
  }
}
