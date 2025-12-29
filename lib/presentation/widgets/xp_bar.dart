import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int level;

  const XpBar({
    super.key,
    required this.currentXp,
    required this.level,
  });

  int get _xpForCurrentLevel => (level - 1) * 100;
  int get _xpForNextLevel => level * 100;
  int get _currentLevelXp => currentXp - _xpForCurrentLevel;
  int get _xpNeededForLevel => _xpForNextLevel - _xpForCurrentLevel;
  double get _progress => _currentLevelXp / _xpNeededForLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nivel y XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: AppDimensions.paddingS,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.success,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.military_tech,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Nivel $level',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                '$_currentLevelXp / $_xpNeededForLevel XP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.paddingS),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: Stack(
              children: [
                // Fondo
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                ),

                // Progreso con gradiente
                FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.success,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 4),

          // Texto de progreso
          Text(
            _progress >= 1.0
                ? '¡Listo para subir de nivel!'
                : 'Faltan ${_xpNeededForLevel - _currentLevelXp} XP para nivel ${level + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _progress >= 1.0
                      ? AppColors.success
                      : AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}
