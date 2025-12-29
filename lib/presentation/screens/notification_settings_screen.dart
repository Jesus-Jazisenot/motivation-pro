import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  List<String> _selectedTimes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _selectedTimes = prefs.getStringList('notification_times') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setStringList('notification_times', _selectedTimes);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      // Solicitar permisos
      final hasPermission =
          await NotificationService.instance.requestPermissions();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se necesitan permisos para enviar notificaciones'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Programar notificaciones
      if (_selectedTimes.isNotEmpty) {
        await NotificationService.instance.scheduleMultipleNotifications(
          times: _selectedTimes,
        );
      }
    } else {
      // Cancelar todas
      await NotificationService.instance.cancelAllNotifications();
    }

    setState(() {
      _notificationsEnabled = value;
    });

    await _saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '✅ Notificaciones activadas'
                : '🔕 Notificaciones desactivadas',
          ),
          backgroundColor: value ? AppColors.success : AppColors.textSecondary,
        ),
      );
    }
  }

  Future<void> _toggleTime(String time) async {
    setState(() {
      if (_selectedTimes.contains(time)) {
        _selectedTimes.remove(time);
      } else {
        _selectedTimes.add(time);
      }
    });

    await _saveSettings();

    if (_notificationsEnabled && _selectedTimes.isNotEmpty) {
      await NotificationService.instance.scheduleMultipleNotifications(
        times: _selectedTimes,
      );
    }
  }

  Future<void> _testNotification() async {
    await NotificationService.instance.showInstantNotification(
      title: '✨ Prueba de Notificación',
      body: 'Si ves esto, las notificaciones funcionan correctamente.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📬 Notificación de prueba enviada'),
        ),
      );
    }
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
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : Column(
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
                            'Notificaciones',
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
                          // Activar/Desactivar
                          Container(
                            padding:
                                EdgeInsets.all(AppDimensions.paddingL),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.primary,
                                  size: AppDimensions.iconL,
                                ),
                                SizedBox(width: AppDimensions.paddingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notificaciones Diarias',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Recibe frases motivacionales',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _notificationsEnabled,
                                  onChanged: _toggleNotifications,
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: AppDimensions.paddingL),

                          // Horarios
                          Text(
                            'Horarios',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),

                          SizedBox(height: AppDimensions.paddingM),

                          _buildTimeOption(
                            icon: Icons.wb_sunny,
                            title: 'Mañana',
                            subtitle: '8:00 AM',
                            time: 'morning',
                          ),

                          _buildTimeOption(
                            icon: Icons.wb_twilight,
                            title: 'Tarde',
                            subtitle: '2:00 PM',
                            time: 'afternoon',
                          ),

                          _buildTimeOption(
                            icon: Icons.nightlight_round,
                            title: 'Noche',
                            subtitle: '8:00 PM',
                            time: 'night',
                          ),

                          SizedBox(height: AppDimensions.paddingL),

                          // Botón de prueba
                          ElevatedButton.icon(
                            onPressed: _testNotification,
                            icon: Icon(Icons.send),
                            label: const Text('Enviar Notificación de Prueba'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(
                                AppDimensions.paddingM,
                              ),
                            ),
                          ),

                          SizedBox(height: AppDimensions.paddingM),

                          // Info
                          Container(
                            padding:
                                EdgeInsets.all(AppDimensions.paddingM),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: AppDimensions.iconM,
                                ),
                                SizedBox(width: AppDimensions.paddingM),
                                Expanded(
                                  child: Text(
                                    'Recibirás una frase motivacional diferente cada día en los horarios seleccionados.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ],
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

  Widget _buildTimeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    final isSelected = _selectedTimes.contains(time);

    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggleTime(time),
        activeColor: AppColors.primary,
        secondary: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
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
      ),
    );
  }
}
