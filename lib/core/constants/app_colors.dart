import 'package:flutter/material.dart';
import '../theme/theme_service.dart';

/// Colores dinámicos que se actualizan según el tema actual
class AppColors {
  // ⬅️ IMPORTANTE: Ahora lee del tema actual, no son valores fijos

  static Color get backgroundDark =>
      ThemeService.instance.currentTheme.backgroundDark;
  static Color get backgroundMid =>
      ThemeService.instance.currentTheme.backgroundMid;
  static Color get backgroundLight =>
      ThemeService.instance.currentTheme.backgroundLight;

  static Color get primary => ThemeService.instance.currentTheme.primary;
  static Color get accent => ThemeService.instance.currentTheme.accent;
  static Color get surface => ThemeService.instance.currentTheme.surface;

  static Color get textPrimary =>
      ThemeService.instance.currentTheme.textPrimary;
  static Color get textSecondary =>
      ThemeService.instance.currentTheme.textSecondary;
  static Color get textTertiary =>
      ThemeService.instance.currentTheme.textTertiary;

  static Color get success => ThemeService.instance.currentTheme.success;
  static Color get warning => ThemeService.instance.currentTheme.warning;
  static Color get error => ThemeService.instance.currentTheme.error;
  static Color get info => ThemeService.instance.currentTheme.info;

  static Color get cardBackground =>
      ThemeService.instance.currentTheme.cardBackground;
  static Color get border => ThemeService.instance.currentTheme.divider;
  static Color get shadow => ThemeService.instance.currentTheme.shadow;

  // ⬅️ NUEVO: Color para favoritos (usa accent)
  static Color get favorite => ThemeService.instance.currentTheme.accent;
}
