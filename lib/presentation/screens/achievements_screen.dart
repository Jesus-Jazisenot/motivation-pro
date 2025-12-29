import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/achievements.dart';
import '../../core/services/stats_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _totalQuotesViewed = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final stats = StatsService.instance;
    final total = await stats.getTotalQuotesViewed();
    final streak = await stats.getCurrentStreak();

    setState(() {
      _totalQuotesViewed = total;
      _currentStreak = streak;
      _isLoading = false;
    });
  }

  bool _isAchievementUnlocked(Achievement achievement) {
    if (achievement.id.contains('quote') ||
        achievement.id.contains('dedicated') ||
        achievement.id.contains('enthusiast') ||
        achievement.id.contains('master')) {
      return _totalQuotesViewed >= achievement.requiredValue;
    }

    if (achievement.id.contains('streak')) {
      return _currentStreak >= achievement.requiredValue;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundMid,
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: AppDimensions.paddingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logros',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Desbloquea todos los badges',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(AppDimensions.paddingL),
                        itemCount: Achievements.all.length,
                        itemBuilder: (context, index) {
                          final achievement = Achievements.all[index];
                          final isUnlocked =
                              _isAchievementUnlocked(achievement);

                          return _buildAchievementCard(
                            achievement,
                            isUnlocked,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.surface,
                ],
              )
            : null,
        color: isUnlocked ? null : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.border,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Emoji
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 30,
                  color: isUnlocked ? null : Colors.grey.shade700,
                ),
              ),
            ),
          ),

          SizedBox(width: AppDimensions.paddingM),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isUnlocked
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),

          // Estado
          if (isUnlocked)
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: AppDimensions.iconL,
            )
          else
            Icon(
              Icons.lock_outline,
              color: AppColors.textTertiary,
              size: AppDimensions.iconL,
            ),
        ],
      ),
    );
  }
}
