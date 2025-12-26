import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_profile.dart';
import '../../core/services/stats_service.dart'; // 🆕 IMPORT AGREGADO

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  int _totalQuotes = 0;
  int _favoriteQuotes = 0;
  int _todayViewed = 0;
  int _totalViewed = 0;
  UserProfile? _profile;
  Map<String, int> _categoryCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // 🆕 MÉTODO COMPLETAMENTE REEMPLAZADO
  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper.instance;
    final statsService = StatsService.instance;

    // Cargar perfil (con racha actualizada)
    await statsService.updateUserStreak();
    final profile = await db.getUserProfile();

    // Cargar todas las frases
    final allQuotes = await db.getAllQuotes();
    final favorites = await db.getFavoriteQuotes();

    // 🆕 ESTADÍSTICAS REALES
    final todayViewed = await statsService.getQuotesViewedToday();
    final totalViewed = await statsService.getTotalQuotesViewed();
    final categoryStats = await statsService.getCategoryStats();

    setState(() {
      _profile = profile;
      _totalQuotes = allQuotes.length;
      _favoriteQuotes = favorites.length;
      _todayViewed = todayViewed;
      _totalViewed = totalViewed;
      _categoryCounts = categoryStats;
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

                      // Stats Grid - FILA 1
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.today,
                              title: 'Vistas Hoy',
                              value: _todayViewed.toString(),
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.visibility,
                              title: 'Total Vistas',
                              value: _totalViewed.toString(),
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      // Stats Grid - FILA 2
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.favorite,
                              title: 'Favoritas',
                              value: _favoriteQuotes.toString(),
                              color: AppColors.favorite,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.format_quote,
                              title: 'Disponibles',
                              value: _totalQuotes.toString(),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      // Stats Grid - FILA 3 (Racha y Nivel)
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

                      // Categorías - 🆕 SECCIÓN ACTUALIZADA
                      Text(
                        'Categorías Más Vistas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      if (_categoryCounts.isEmpty)
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppDimensions.paddingXL),
                            child: Text(
                              'Empieza a ver frases para generar estadísticas',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                          ),
                        )
                      else
                        ..._categoryCounts.entries.map((entry) {
                          final totalViews = _categoryCounts.values
                              .fold<int>(0, (a, b) => a + b);
                          final percentage = totalViews > 0
                              ? ((entry.value / totalViews) * 100).toInt()
                              : 0;
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
            decoration: const BoxDecoration(
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
          const Icon(
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
    // Colores por categoría
    Color getColorForCategory(String cat) {
      switch (cat.toLowerCase()) {
        case 'motivación':
          return AppColors.primary;
        case 'bienestar':
          return AppColors.success;
        case 'productividad':
          return AppColors.warning;
        case 'relaciones':
          return AppColors.favorite;
        case 'metas':
          return const Color(0xFF00BCD4); // Cyan
        case 'mentalidad':
          return const Color(0xFF9C27B0); // Purple
        default:
          return AppColors.primary;
      }
    }

    final color = getColorForCategory(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    category,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Text(
                '$count vistas',
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
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
