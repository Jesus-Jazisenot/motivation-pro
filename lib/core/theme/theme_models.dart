import 'package:flutter/material.dart';

/// Modelo de datos para un tema completo
class AppThemeData {
  final String id;
  final String name;
  final String emoji;
  final String description;

  // Colores principales
  final Color backgroundDark;
  final Color backgroundMid;
  final Color backgroundLight;
  final Color primary;
  final Color accent;
  final Color surface;

  // Colores de texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Colores de estado
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // UI específicos
  final Color cardBackground;
  final Color divider;
  final Color shadow;

  const AppThemeData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.backgroundDark,
    required this.backgroundMid,
    required this.backgroundLight,
    required this.primary,
    required this.accent,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.cardBackground,
    required this.divider,
    required this.shadow,
  });

  /// Convertir a ThemeData de Flutter
  ThemeData toThemeData() {
    return ThemeData(
      brightness: _getBrightness(),
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardBackground,
      dividerColor: divider,
      colorScheme: ColorScheme(
        brightness: _getBrightness(),
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        error: error,
        onError: Colors.white,
        background: backgroundDark,
        onBackground: textPrimary,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textTertiary,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Brightness _getBrightness() {
    // Calcular luminancia del background
    final luminance = backgroundDark.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }
}
