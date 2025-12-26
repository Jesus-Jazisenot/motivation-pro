import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/database/database_helper.dart';
import 'onboarding/onboarding_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Iniciar animación
    _controller.forward();

    // Navegar después de 2.5 segundos
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Verificar si el usuario ya completó el onboarding
    final db = DatabaseHelper.instance;
    // Evitar esperas indefinidas al inicializar la BD: timeout de 5s
    final profile = await db
        .getUserProfile()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);

    if (profile == null) {
      // Primera vez - Ir a Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    } else {
      // Ya completó onboarding - Ir a Main Navigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(128),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Título
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // Subtítulo
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  AppStrings.appTagline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),

              const SizedBox(height: 60),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
