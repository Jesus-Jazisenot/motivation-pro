import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_models.dart';
import 'theme_presets.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._init();

  ThemeService._init();

  AppThemeData _currentTheme = ThemePresets.darkTheme;
  String _currentThemeId = 'dark';

  AppThemeData get currentTheme => _currentTheme;
  String get currentThemeId => _currentThemeId;

  /// Inicializar tema guardado
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString('theme_id') ?? 'dark';

    _currentThemeId = savedThemeId;
    _currentTheme = ThemePresets.getThemeById(savedThemeId);

    print('✅ Tema cargado: $savedThemeId');

    // Actualizar widget al iniciar
    await _updateWidgetColors();

    notifyListeners();
  }

  /// Cambiar tema
  Future<void> setTheme(String themeId) async {
    final theme = ThemePresets.getThemeById(themeId);

    _currentTheme = theme;
    _currentThemeId = themeId;

    // Guardar preferencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_id', themeId);

    print('🎨 Tema cambiado a: $themeId');

    // Actualizar widget de Android con nuevos colores
    await _updateWidgetColors();

    notifyListeners();
  }

  /// Actualizar colores del widget de Android
  Future<void> _updateWidgetColors() async {
    try {
      // Obtener la última frase mostrada para actualizar el widget completo
      final prefs = await SharedPreferences.getInstance();
      final lastQuoteText = prefs.getString('last_quote_text') ??
          'Cambia de frase para ver el nuevo tema';
      final lastQuoteAuthor =
          prefs.getString('last_quote_author') ?? 'Motivation PRO';

      // Enviar datos completos al widget
      final widgetData = {
        'text': lastQuoteText,
        'author': lastQuoteAuthor,
        'primaryColor': _currentTheme.primary.value,
        'backgroundColor': _currentTheme.backgroundDark.value,
        'textColor': _currentTheme.textPrimary.value,
        'themeName': _currentThemeId,
      };

      await const MethodChannel('com.example.motivation_pro/widget')
          .invokeMethod('updateWidget', widgetData);

      print('✅ Widget actualizado con tema: $_currentThemeId');
    } catch (e) {
      print('⚠️ Error actualizando widget: $e');
      // No es crítico si falla, el widget se actualizará en el próximo cambio de frase
    }
  }

  /// Obtener todos los temas disponibles
  List<AppThemeData> getAllThemes() {
    return ThemePresets.allThemes;
  }

  /// Verificar si es el tema actual
  bool isCurrentTheme(String themeId) {
    return _currentThemeId == themeId;
  }
}
