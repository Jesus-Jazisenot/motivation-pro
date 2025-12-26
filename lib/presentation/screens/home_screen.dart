import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';
import '../widgets/quote_card.dart';
import 'settings_screen.dart';
import '../../core/services/stats_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  Quote? _currentQuote;
  bool _isLoading = true;

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

    // Cargar nombre de usuario
    final profile = await db.getUserProfile();
    if (profile != null) {
      _userName = profile.name;
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

      // 🆕 RASTREAR EN ESTADÍSTICAS
      await StatsService.instance.trackQuoteView(quote);

      // 🆕 AGREGAR XP
      await StatsService.instance.addXP(10);

      // 🆕 ACTUALIZAR RACHA
      await StatsService.instance.updateUserStreak();
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
                    ),

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
