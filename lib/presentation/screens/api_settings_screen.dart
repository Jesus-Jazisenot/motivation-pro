import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/quote_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_selector_screen.dart'; // ⬅️ Import para temas

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  bool _useApi = true;
  bool _isCheckingConnection = false;
  bool? _isConnected;
  String _languagePreference = 'both'; // 'es', 'en', 'both'

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
      _languagePreference = prefs.getString('language_preference') ?? 'both';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_api', _useApi);
    await prefs.setString('language_preference', _languagePreference);
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

  Widget _buildLanguageOption(String value, String title, String subtitle) {
    final isSelected = _languagePreference == value;

    return GestureDetector(
      onTap: () async {
        setState(() {
          _languagePreference = value;
        });
        await _saveSettings();

        if (mounted) {
          String message = '';
          if (value == 'both') {
            message = '🌐 Verás frases en español e inglés';
          } else if (value == 'es') {
            message =
                '🇪🇸 Solo verás frases en español (traducidas automáticamente)';
          } else if (value == 'en') {
            message = '🇬🇧 Solo verás frases en inglés';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimensions.paddingS),
        padding: EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppDimensions.iconL,
              ),
          ],
        ),
      ),
    );
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
                          'Configuración',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Personaliza tu experiencia',
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
                  padding: EdgeInsets.all(AppDimensions.paddingL),
                  children: [
                    // ⬅️ NUEVO: Sección de Personalización
                    Text(
                      'PERSONALIZACIÓN',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                    ),

                    SizedBox(height: AppDimensions.paddingM),

                    // ⬅️ NUEVO: Opción de Temas
                    Container(
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
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.all(AppDimensions.paddingM),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.palette_outlined,
                            color: AppColors.primary,
                            size: AppDimensions.iconL,
                          ),
                        ),
                        title: Text(
                          'Temas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Personaliza los colores de la app',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ThemeSelectorScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: AppDimensions.paddingXL),

                    // Sección de Fuente de Frases
                    Text(
                      'FUENTE DE FRASES',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                    ),

                    SizedBox(height: AppDimensions.paddingM),

                    // Toggle API
                    Container(
                      padding: EdgeInsets.all(AppDimensions.paddingL),
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
                          SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usar APIs Externas',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                SizedBox(height: 4),
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
                                    duration: Duration(seconds: 3),
                                  ),
                                );

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

                    SizedBox(height: AppDimensions.paddingL),

                    // Selector de Idioma
                    Container(
                      padding: EdgeInsets.all(AppDimensions.paddingL),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.language,
                                color: AppColors.primary,
                                size: AppDimensions.iconL,
                              ),
                              SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Idioma de Frases',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Elige qué idioma prefieres',
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
                            ],
                          ),

                          SizedBox(height: AppDimensions.paddingM),

                          // Opciones de idioma
                          _buildLanguageOption(
                            'both',
                            '🌐 Ambos idiomas',
                            'Español e Inglés mezclados',
                          ),

                          _buildLanguageOption(
                            'es',
                            '🇪🇸 Solo Español',
                            'Frases traducidas automáticamente',
                          ),

                          _buildLanguageOption(
                            'en',
                            '🇬🇧 Solo Inglés',
                            'Frases en inglés (requiere APIs)',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimensions.paddingL),

                    // Estado de conexión
                    Container(
                      padding: EdgeInsets.all(AppDimensions.paddingL),
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
                            SizedBox(
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
                          SizedBox(width: AppDimensions.paddingM),
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
                                SizedBox(height: 4),
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
                            icon: Icon(Icons.refresh),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimensions.paddingL),

                    // Info
                    Container(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
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
                          SizedBox(width: AppDimensions.paddingM),
                          Expanded(
                            child: Text(
                              'Con APIs activadas y filtro de español, las frases se traducen automáticamente. '
                              'Sin internet, se usan las frases locales.',
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

                    SizedBox(height: AppDimensions.paddingL),

                    // APIs usadas
                    Text(
                      'APIs Utilizadas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    SizedBox(height: AppDimensions.paddingM),

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

                    _buildApiCard(
                      title: 'Google Translate',
                      description: 'Traducción automática de frases',
                      icon: Icons.translate,
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
      margin: EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: EdgeInsets.all(AppDimensions.paddingM),
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
          SizedBox(width: AppDimensions.paddingM),
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
