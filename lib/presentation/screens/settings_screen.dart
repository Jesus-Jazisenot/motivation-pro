import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'notification_settings_screen.dart';
import 'achievements_screen.dart';
import 'api_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    Text(
                      'Configuración',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(AppDimensions.paddingL),
                  children: [
                    // NOTIFICACIONES
                    _buildSettingTile(
                      context,
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones',
                      subtitle: 'Configura tus recordatorios',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    // LOGROS
                    _buildSettingTile(
                      context,
                      icon: Icons.emoji_events,
                      title: 'Logros',
                      subtitle: 'Ver tus badges desbloqueados',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        );
                      },
                    ),

                    // FUENTE DE FRASES (NUEVO)
                    _buildSettingTile(
                      context,
                      icon: Icons.cloud_outlined,
                      title: 'Fuente de Frases',
                      subtitle: 'APIs externas y configuración',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApiSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    // EDITAR PERFIL
                    _buildSettingTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Editar Perfil',
                      subtitle: 'Actualiza tu información',
                      onTap: () {
                        // TODO: Próximamente
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Próximamente...'),
                          ),
                        );
                      },
                    ),

                    // BORRAR DATOS
                    _buildSettingTile(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Borrar Datos',
                      subtitle: 'Elimina toda tu información',
                      onTap: () {
                        // TODO: Próximamente
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Próximamente...'),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: AppDimensions.paddingL),

                    Center(
                      child: Text(
                        'Más opciones próximamente...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: AppColors.primary,
          size: AppDimensions.iconL,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textTertiary,
          size: AppDimensions.iconS,
        ),
      ),
    );
  }
}
