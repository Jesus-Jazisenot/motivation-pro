import 'package:flutter/material.dart';

/// Colores de la aplicación Motivation Pro
class AppColors {
  // Constructor privado para evitar instanciación
  AppColors._();

  // Colores principales - Tema Violeta
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);

  static const Color secondary = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFEC4899);

  // Fondos
  static const Color backgroundDark = Color(0xFF0F0C29);
  static const Color backgroundMid = Color(0xFF302B63);
  static const Color backgroundLight = Color(0xFF24243E);

  // Superficies
  static const Color surface = Color(0xFF1A1335);
  static const Color surfaceLight = Color(0xFF2D2640);

  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Específicos de features
  static const Color favorite = Color(0xFFFF6B9D);
  static const Color streak = Color(0xFFFF8C42);
  static const Color badge = Color(0xFFFBBF24);

  // Transparencias
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Bordes
  static const Color border = Color(0x33FFFFFF);
  static const Color borderLight = Color(0x1AFFFFFF);
}
