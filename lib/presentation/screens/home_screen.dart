import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';
import '../widgets/quote_card.dart';
import 'settings_screen.dart';
import '../../core/services/stats_service.dart';
import '../widgets/xp_bar.dart';
import '../widgets/level_up_dialog.dart';
import '../../data/models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  Quote? _currentQuote;
  bool _isLoading = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper.instance;

    // Cargar nombre de usuario y perfil
    final profile = await db.getUserProfile();
    if (profile != null) {
      _userName = profile.name;
      _userProfile = profile; // ⬅️ AGREGAR ESTA LÍNEA
    }

    // Cargar frase aleatoria
    await _loadRandomQuote();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRandomQuote() async {
    final db = DatabaseHelper.instance;
    final quote = await db.getRandomQuote();

    if (quote != null) {
      setState(() {
        _currentQuote = quote;
      });

      // Actualizar última vez mostrada y contador
      final updatedQuote = quote.copyWith(
        lastShown: DateTime.now(),
        viewCount: quote.viewCount + 1,
      );
      await db.updateQuote(updatedQuote);

      // Rastrear en estadísticas
      await StatsService.instance.trackQuoteView(quote);

      // ⬅️ GUARDAR NIVEL ANTERIOR
      final oldLevel = _userProfile?.level ?? 1;

      // Agregar XP
      await StatsService.instance.addXP(10);

      // Actualizar racha
      await StatsService.instance.updateUserStreak();

      // ⬅️ RECARGAR PERFIL Y DETECTAR LEVEL UP
      final newProfile = await db.getUserProfile();
      if (newProfile != null) {
        final newLevel = newProfile.level;

        setState(() {
          _userProfile = newProfile;
        });

        // ⬅️ MOSTRAR ANIMACIÓN SI SUBIÓ DE NIVEL
        if (newLevel > oldLevel && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => LevelUpDialog(
              newLevel: newLevel,
              totalXp: newProfile.totalXp,
            ),
          );
        }
      }
    }
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Hola, $_userName! 👋',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.homeQuoteOfDay,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.settings_outlined),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ), // ⬅️ AGREGAR ESTO:
                    if (_userProfile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: XpBar(
                          currentXp: _userProfile!.totalXp,
                          level: _userProfile!.level,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Quote Card
                    Expanded(
                      child: Center(
                        child: _currentQuote != null
                            ? QuoteCard(
                                quote: _currentQuote!,
                                onNextQuote: _loadRandomQuote,
                              )
                            : Text(
                                'No hay frases disponibles',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                      ),
                    ),

                    // Bottom info
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Desliza hacia abajo para actualizar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
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
