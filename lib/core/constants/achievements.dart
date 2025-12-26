class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
  });
}

class Achievements {
  static const firstQuote = Achievement(
    id: 'first_quote',
    title: 'Primera Frase',
    description: 'Viste tu primera frase',
    icon: '🌟',
    requiredValue: 1,
  );

  static const dedicated = Achievement(
    id: 'dedicated',
    title: 'Dedicado',
    description: 'Viste 10 frases',
    icon: '💪',
    requiredValue: 10,
  );

  static const enthusiast = Achievement(
    id: 'enthusiast',
    title: 'Entusiasta',
    description: 'Viste 50 frases',
    icon: '🎯',
    requiredValue: 50,
  );

  static const master = Achievement(
    id: 'master',
    title: 'Maestro',
    description: 'Viste 100 frases',
    icon: '🏆',
    requiredValue: 100,
  );

  static const streakStarter = Achievement(
    id: 'streak_3',
    title: 'Racha Iniciada',
    description: 'Racha de 3 días',
    icon: '🔥',
    requiredValue: 3,
  );

  static const streakWarrior = Achievement(
    id: 'streak_7',
    title: 'Guerrero de Rachas',
    description: 'Racha de 7 días',
    icon: '⚡',
    requiredValue: 7,
  );

  static const streakLegend = Achievement(
    id: 'streak_30',
    title: 'Leyenda de Rachas',
    description: 'Racha de 30 días',
    icon: '👑',
    requiredValue: 30,
  );

  static List<Achievement> get all => [
        firstQuote,
        dedicated,
        enthusiast,
        master,
        streakStarter,
        streakWarrior,
        streakLegend,
      ];

  static Achievement? getAchievementForQuotes(int quotesViewed) {
    final achieved = all
        .where((a) =>
            a.id.contains('quote') ||
            (a.id.contains('dedicated') ||
                a.id.contains('enthusiast') ||
                a.id.contains('master')))
        .where((a) => quotesViewed >= a.requiredValue)
        .toList();

    if (achieved.isEmpty) return null;

    achieved.sort((a, b) => b.requiredValue.compareTo(a.requiredValue));
    return achieved.first;
  }

  static Achievement? getAchievementForStreak(int streak) {
    final achieved = all
        .where((a) => a.id.contains('streak'))
        .where((a) => streak >= a.requiredValue)
        .toList();

    if (achieved.isEmpty) return null;

    achieved.sort((a, b) => b.requiredValue.compareTo(a.requiredValue));
    return achieved.first;
  }
}
