import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_profile.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  int _totalQuotes = 0;
  int _favoriteQuotes = 0;
  UserProfile? _profile;
  Map<String, int> _categoryCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper.instance;

    // Cargar perfil
    final profile = await db.getUserProfile();

    // Cargar todas las frases
    final allQuotes = await db.getAllQuotes();
    final favorites = await db.getFavoriteQuotes();

    // Contar por categoría
    final categoryCounts = <String, int>{};
    for (final quote in allQuotes) {
      categoryCounts[quote.category] =
          (categoryCounts[quote.category] ?? 0) + 1;
    }

    setState(() {
      _profile = profile;
      _totalQuotes = allQuotes.length;
      _favoriteQuotes = favorites.length;
      _categoryCounts = categoryCounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(
                            Icons.bar_chart,
                            color: AppColors.primary,
                            size: AppDimensions.iconL,
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estadísticas',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'Tu progreso',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.paddingXL),

                      // Perfil Card
                      if (_profile != null) _buildProfileCard(_profile!),

                      const SizedBox(height: AppDimensions.paddingL),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.format_quote,
                              title: 'Total Frases',
                              value: _totalQuotes.toString(),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.favorite,
                              title: 'Favoritas',
                              value: _favoriteQuotes.toString(),
                              color: AppColors.favorite,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.local_fire_department,
                              title: 'Racha Actual',
                              value: '${_profile?.currentStreak ?? 0} días',
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.military_tech,
                              title: 'Nivel',
                              value: '${_profile?.level ?? 1}',
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.paddingL),

                      // Categorías
                      Text(
                        'Frases por Categoría',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      ..._categoryCounts.entries.map((entry) {
                        final percentage =
                            (_categoryCounts[entry.key]! / _totalQuotes * 100)
                                .toInt();
                        return _buildCategoryBar(
                          entry.key,
                          entry.value,
                          percentage,
                        );
                      }),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.name[0].toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Nivel ${profile.level} • ${profile.totalXp} XP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textTertiary,
            size: AppDimensions.iconS,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: AppDimensions.iconL,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String category, int count, int percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '$count frases ($percentage%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
