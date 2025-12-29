import 'package:flutter/material.dart';
import 'theme_models.dart';

class ThemePresets {
  /// 1. Dark Mode (Default) 🌙
  static const AppThemeData darkTheme = AppThemeData(
    id: 'dark',
    name: 'Oscuro',
    emoji: '🌙',
    description: 'Tema oscuro clásico, ideal para la noche',
    backgroundDark: Color(0xFF0F0F0F),
    backgroundMid: Color(0xFF1A1A1A),
    backgroundLight: Color(0xFF252525),
    primary: Color(0xFF9D4EDD),
    accent: Color(0xFF00F5FF),
    surface: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF707070),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    cardBackground: Color(0xFF1E1E1E),
    divider: Color(0xFF2A2A2A),
    shadow: Color(0x40000000),
  );

  /// 2. Light Mode ☀️
  static const AppThemeData lightTheme = AppThemeData(
    id: 'light',
    name: 'Claro',
    emoji: '☀️',
    description: 'Tema claro elegante para el día',
    backgroundDark: Color(0xFFF5F5F5),
    backgroundMid: Color(0xFFFFFFFF),
    backgroundLight: Color(0xFFFAFAFA),
    primary: Color(0xFF6A1B9A),
    accent: Color(0xFFFF6B35),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    textTertiary: Color(0xFF999999),
    success: Color(0xFF059669),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    cardBackground: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E0E0),
    shadow: Color(0x20000000),
  );

  /// 3. Ocean 🌊
  static const AppThemeData oceanTheme = AppThemeData(
    id: 'ocean',
    name: 'Océano',
    emoji: '🌊',
    description: 'Inspirado en las profundidades del mar',
    backgroundDark: Color(0xFF0A1929),
    backgroundMid: Color(0xFF1A2332),
    backgroundLight: Color(0xFF2A3F5F),
    primary: Color(0xFF00B4D8),
    accent: Color(0xFF90E0EF),
    surface: Color(0xFF1E3A5F),
    textPrimary: Color(0xFFE8F4F8),
    textSecondary: Color(0xFFADD8E6),
    textTertiary: Color(0xFF6B9AC4),
    success: Color(0xFF06D6A0),
    warning: Color(0xFFFFB703),
    error: Color(0xFFEF476F),
    info: Color(0xFF4CC9F0),
    cardBackground: Color(0xFF1E3A5F),
    divider: Color(0xFF2A4A6F),
    shadow: Color(0x40001F3F),
  );

  /// 4. Sunset 🌅
  static const AppThemeData sunsetTheme = AppThemeData(
    id: 'sunset',
    name: 'Atardecer',
    emoji: '🌅',
    description: 'Colores cálidos del atardecer',
    backgroundDark: Color(0xFF2D1B2E),
    backgroundMid: Color(0xFF3E2723),
    backgroundLight: Color(0xFF4E3A35),
    primary: Color(0xFFFF6B6B),
    accent: Color(0xFFFFD23F),
    surface: Color(0xFF4A2545),
    textPrimary: Color(0xFFFFF8E1),
    textSecondary: Color(0xFFFFCC80),
    textTertiary: Color(0xFFBF8F6E),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    info: Color(0xFFFB923C),
    cardBackground: Color(0xFF4A2545),
    divider: Color(0xFF5A3555),
    shadow: Color(0x402D1B2E),
  );

  /// 5. Forest 🌲
  static const AppThemeData forestTheme = AppThemeData(
    id: 'forest',
    name: 'Bosque',
    emoji: '🌲',
    description: 'Verde natural y relajante',
    backgroundDark: Color(0xFF0D1F1E),
    backgroundMid: Color(0xFF1A3634),
    backgroundLight: Color(0xFF2A4D4A),
    primary: Color(0xFF10B981),
    accent: Color(0xFF84CC16),
    surface: Color(0xFF1F4037),
    textPrimary: Color(0xFFE8F5E9),
    textSecondary: Color(0xFFA5D6A7),
    textTertiary: Color(0xFF66BB6A),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFACC15),
    error: Color(0xFFF87171),
    info: Color(0xFF14B8A6),
    cardBackground: Color(0xFF1F4037),
    divider: Color(0xFF2F5047),
    shadow: Color(0x400D1F1E),
  );

  /// Lista de todos los temas
  static final List<AppThemeData> allThemes = [
    darkTheme,
    lightTheme,
    oceanTheme,
    sunsetTheme,
    forestTheme,
  ];

  /// Obtener tema por ID
  static AppThemeData getThemeById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      print('⚠️ Tema no encontrado: $id, usando dark');
      return darkTheme;
    }
  }
}
