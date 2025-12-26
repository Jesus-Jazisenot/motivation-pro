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
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfNeeded();
  }

  Future<void> _refreshIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final useApi = prefs.getBool('use_api') ?? true;
    print('ℹ️ Settings: use_api = $useApi');
  }

  Future<void> _loadData() async {
    print('🔵 LOAD DATA: Iniciando...');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final db = DatabaseHelper.instance;

      // Cargar nombre de usuario y perfil
      final profile = await db.getUserProfile();
      if (profile != null) {
        _userName = profile.name;
        _userProfile = profile;
        print('🔵 LOAD DATA: Perfil cargado - $_userName');
      }

      // Cargar frase aleatoria
      await _loadRandomQuote();

      print('🔵 LOAD DATA: Frase cargada');
    } catch (e) {
      print('🚨 Error en _loadData: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    print('🔵 LOAD DATA: Terminado');
  }

  Future<void> _loadRandomQuote() async {
    print('🔵 Iniciando _loadRandomQuote()');

    // NO verificar _isLoading aquí - puede ser llamado desde _loadData()

    try {
      print('🔵 Obteniendo database...');
      final db = DatabaseHelper.instance;

      print('🔵 Llamando getRandomQuote()...');
      final quote = await db.getRandomQuote().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ TIMEOUT en getRandomQuote');
          return null;
        },
      );

      if (quote != null) {
        print(
            '🔵 Quote obtenido: ${quote.text.substring(0, min(20, quote.text.length))}...');
        if (mounted) {
          setState(() {
            _currentQuote = quote;
          });
        }
        print('🔵 Estado actualizado con quote');
      } else {
        print('❌ Quote es NULL');
        if (mounted) {
          setState(() {
            _currentQuote = null;
          });
        }
      }
    } catch (e, stackTrace) {
      print('🚨 ERROR en _loadRandomQuote:');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _currentQuote = null;
        });
      }
    }

    print('🔵 _loadRandomQuote() TERMINÓ');
  }

  Future<void> _loadRandomQuoteWithStats() async {
    print('🟣 Iniciando _loadRandomQuoteWithStats()');

    if (_isLoading) {
      print('⚠️ Ya está cargando, saliendo...');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper.instance;
      final quote = await db.getHybridQuote().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print('⏱️ TIMEOUT en getHybridQuote');
          return null;
        },
      );

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

        // Guardar nivel anterior
        final oldLevel = _userProfile?.level ?? 1;

        // Agregar XP
        await StatsService.instance.addXP(10);

        // Actualizar racha
        await StatsService.instance.updateUserStreak();

        // Recargar perfil
        final newProfile = await db.getUserProfile();
        if (newProfile != null) {
          final newLevel = newProfile.level;

          setState(() {
            _userProfile = newProfile;
          });

          // Level up animation
          if (newLevel > oldLevel && mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => LevelUpDialog(
                newLevel: newLevel,
                totalXp: newProfile.totalXp,
              ),
            );

            if (mounted) {
              setState(() {});
            }
          }
        }

        // Actualizar widget
        if (mounted) {
          final quoteData = {
            'text': quote.text,
            'author': quote.author ?? 'Anónimo',
          };

          try {
            await const MethodChannel('com.example.motivation_pro/widget')
                .invokeMethod('updateWidget', quoteData);
          } catch (e) {
            print('Widget update error: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      print('🚨 ERROR en _loadRandomQuoteWithStats:');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _currentQuote = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetQuotes() async {
    print('🟡 RESET: Iniciando resetQuotes()');

    setState(() {
      _isLoading = true;
    });

    try {
      print('🟡 RESET: Obteniendo database...');
      final db = DatabaseHelper.instance;
      final database = await db.database;

      print('🟡 RESET: Ejecutando UPDATE...');
      await database.rawUpdate('''
        UPDATE quotes 
        SET last_shown = NULL
      ''').timeout(const Duration(seconds: 3));

      print('✅ Todas las frases reseteadas');

      print('🟡 RESET: Esperando 500ms...');
      await Future.delayed(const Duration(milliseconds: 500));

      print('🟡 RESET: Llamando _loadRandomQuote()...');
      await _loadRandomQuote();

      print('🟡 RESET: _loadRandomQuote() terminó');

      if (mounted && _currentQuote != null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Frases reseteadas'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('⚠️ Frases reseteadas pero no se pudo cargar ninguna'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('🚨 ERROR en resetQuotes:');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    print('🟡 RESET: Método terminó');
  }

  Future<void> _forceLoadEmergencyQuotes() async {
    print('🚨 EMERGENCIA: Iniciando carga forzada...');

    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper.instance;

      final emergencyQuotes = [
        Quote(
          text:
              'El éxito es la suma de pequeños esfuerzos repetidos día tras día.',
          author: 'Robert Collier',
          category: 'Motivación',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'No cuentes los días, haz que los días cuenten.',
          author: 'Muhammad Ali',
          category: 'Motivación',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'El único modo de hacer un gran trabajo es amar lo que haces.',
          author: 'Steve Jobs',
          category: 'Productividad',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'Cree que puedes y ya estarás a medio camino.',
          author: 'Theodore Roosevelt',
          category: 'Mentalidad',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'La vida es 10% lo que te pasa y 90% cómo reaccionas.',
          author: 'Charles Swindoll',
          category: 'Bienestar',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text:
              'El futuro pertenece a quienes creen en la belleza de sus sueños.',
          author: 'Eleanor Roosevelt',
          category: 'Motivación',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'La mejor manera de predecir el futuro es crearlo.',
          author: 'Peter Drucker',
          category: 'Metas',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text:
              'Elige un trabajo que ames y no tendrás que trabajar ni un día.',
          author: 'Confucio',
          category: 'Productividad',
          lastShown: null,
          viewCount: 0,
        ),
      ];

      int inserted = 0;
      for (final quote in emergencyQuotes) {
        try {
          await db.insertQuote(quote);
          inserted++;
          print('✅ Frase $inserted insertada');
        } catch (e) {
          print('⚠️ Frase duplicada, continuando...');
        }
      }

      print('✅ Total frases insertadas: $inserted');

      // Cargar una frase
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadRandomQuote();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $inserted frases cargadas'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('🚨 Error en modo emergencia:');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
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
                    ),

                    // XP Bar
                    if (_userProfile != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: XpBar(
                          currentXp: _userProfile!.totalXp,
                          level: _userProfile!.level,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Quote Card o Pantalla de Emergencia
                    Expanded(
                      child: Center(
                        child: _currentQuote != null
                            ? QuoteCard(
                                key: ValueKey(
                                    _currentQuote!.id ?? _currentQuote!.text),
                                quote: _currentQuote!,
                                onNextQuote: _loadRandomQuoteWithStats,
                              )
                            : Padding(
                                padding: const EdgeInsets.all(32),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 80,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Sin Frases Disponibles',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Vamos a solucionar esto',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),

                                      // BOTÓN 1: Cargar Frases de Emergencia
                                      ElevatedButton.icon(
                                        onPressed: _forceLoadEmergencyQuotes,
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 24),
                                        label: const Text(
                                          'Cargar Frases Ahora',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          elevation: 8,
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // BOTÓN 2: Resetear
                                      OutlinedButton.icon(
                                        onPressed: _resetQuotes,
                                        icon: const Icon(Icons.refresh),
                                        label:
                                            const Text('Resetear Existentes'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // BOTÓN 3: APIs
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const SettingsScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.cloud_outlined),
                                        label: const Text(
                                            'Activar APIs (Miles de frases)'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
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
