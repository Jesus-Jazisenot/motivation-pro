import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/quote_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  bool _useApi = true;
  bool _isCheckingConnection = false;
  bool? _isConnected;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkConnection();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useApi = prefs.getBool('use_api') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_api', _useApi);
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    final isAvailable = await QuoteApiService.instance.isApiAvailable();

    setState(() {
      _isConnected = isAvailable;
      _isCheckingConnection = false;
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fuente de Frases',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Configurar APIs externas',
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
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  children: [
                    // Toggle API
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
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
                            Icons.cloud_outlined,
                            color: AppColors.primary,
                            size: AppDimensions.iconL,
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usar APIs Externas',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accede a 50,000+ frases de internet',
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
                            value: _useApi,
                            onChanged: (value) async {
                              setState(() {
                                _useApi = value;
                              });
                              await _saveSettings();

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value
                                          ? '✅ APIs activadas - Reinicia la app o cambia de frase'
                                          : '💾 Usando solo frases locales',
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );

                                // Verificar conexión después de activar
                                if (value) {
                                  _checkConnection();
                                }
                              }
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.paddingL),

                    // Estado de conexión
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      decoration: BoxDecoration(
                        color: _isConnected == true
                            ? AppColors.success.withOpacity(0.1)
                            : _isConnected == false
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                        border: Border.all(
                          color: _isConnected == true
                              ? AppColors.success
                              : _isConnected == false
                                  ? AppColors.error
                                  : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isCheckingConnection)
                            const SizedBox(
                              width: AppDimensions.iconL,
                              height: AppDimensions.iconL,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            Icon(
                              _isConnected == true
                                  ? Icons.check_circle
                                  : _isConnected == false
                                      ? Icons.error
                                      : Icons.help,
                              color: _isConnected == true
                                  ? AppColors.success
                                  : _isConnected == false
                                      ? AppColors.error
                                      : AppColors.textTertiary,
                              size: AppDimensions.iconL,
                            ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected == true
                                      ? 'Conectado'
                                      : _isConnected == false
                                          ? 'Sin conexión'
                                          : 'Estado desconocido',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isConnected == true
                                      ? 'APIs funcionando correctamente'
                                      : _isConnected == false
                                          ? 'Usando frases locales'
                                          : 'Verificando...',
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
                          IconButton(
                            onPressed: _checkConnection,
                            icon: const Icon(Icons.refresh),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppDimensions.paddingL),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: AppDimensions.iconM,
                          ),
                          const SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: Text(
                              'Con APIs activadas, tendrás acceso a miles de frases nuevas. '
                              'Si no hay internet, la app usará automáticamente las frases locales.',
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

                    const SizedBox(height: AppDimensions.paddingL),

                    // APIs usadas
                    Text(
                      'APIs Utilizadas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: AppDimensions.paddingM),

                    _buildApiCard(
                      title: 'Type.fit',
                      description: '1,600+ frases motivacionales',
                      icon: Icons.format_quote,
                    ),

                    _buildApiCard(
                      title: 'ZenQuotes',
                      description: '50,000+ frases en inglés',
                      icon: Icons.self_improvement,
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

  Widget _buildApiCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
