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
import '../../core/services/connectivity_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/notification_service.dart';
import '../widgets/streak_indicator.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/mood_picker_widget.dart';
import 'reflection_screen.dart';
import 'package:in_app_review/in_app_review.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  Quote? _currentQuote;
  bool _isLoading = true;
  bool _hasInternet = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadData();
  }

  // ⬇️⬇️⬇️ MÉTODO NUEVO AGREGADO ⬇️⬇️⬇️
  /// Guardar última frase para el widget
  Future<void> _saveLastQuoteForWidget(Quote quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_quote_text', quote.text);
      await prefs.setString('last_quote_author', quote.author ?? 'Anónimo');
      print(
          '✅ Última frase guardada para widget: ${quote.text.substring(0, min(30, quote.text.length))}...');
    } catch (e) {
      print('⚠️ Error guardando última frase: $e');
    }
  }
  // ⬆️⬆️⬆️ FIN MÉTODO NUEVO ⬆️⬆️⬆️

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

        // Programar recordatorio de racha si tiene racha activa
        if (profile.currentStreak > 0) {
          NotificationService.instance
              .scheduleStreakReminder(profile.currentStreak);
        }
      }

      // Cargar frase del día (misma todo el día)
      await _loadDailyQuote();

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

  Future<void> _checkConnection() async {
    final connectivity = ConnectivityService.instance;
    final hasConnection = await connectivity.hasConnection();

    if (mounted) {
      setState(() {
        _hasInternet = hasConnection;
      });
    }
  }

  Future<void> _loadDailyQuote() async {
    try {
      final quote = await DatabaseHelper.instance.getDailyQuote();
      if (quote != null && mounted) {
        setState(() => _currentQuote = quote);
        await DatabaseHelper.instance.updateQuote(
          quote.copyWith(
            lastShown: DateTime.now(),
            viewCount: quote.viewCount + 1,
          ),
        );
        await _saveLastQuoteForWidget(quote);
      }
    } catch (e) {
      print('🚨 Error en _loadDailyQuote: $e');
      await _loadRandomQuote();
    }
  }

  Future<void> _loadRandomQuote() async {
    print('🔵 Iniciando _loadRandomQuote()');

    try {
      print('🔵 Obteniendo database...');
      final db = DatabaseHelper.instance;

      print('🔵 Llamando getRandomQuote()...');
      final quote = await db.getRandomQuote().timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ TIMEOUT en getRandomQuote');
          return null;
        },
      );

      if (quote != null) {
        print(
            '🔵 Quote obtenido: ${quote.text.substring(0, min(20, quote.text.length))}...');

        final updatedQuote = quote.copyWith(
          lastShown: DateTime.now(),
          viewCount: quote.viewCount + 1,
        );

        await db.updateQuote(updatedQuote);
        print('✅ Quote marcado como visto - last_shown actualizado');

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
      await _checkConnection();

      final db = DatabaseHelper.instance;
      final quote = await db.getHybridQuote().timeout(
        Duration(seconds: 8),
        onTimeout: () {
          print('⏱️ TIMEOUT en getHybridQuote');
          return null;
        },
      );

      if (quote != null) {
        setState(() {
          _currentQuote = quote;
        });

        final updatedQuote = quote.copyWith(
          lastShown: DateTime.now(),
          viewCount: quote.viewCount + 1,
        );
        await db.updateQuote(updatedQuote);

        // ⬇️⬇️⬇️ LLAMADA AGREGADA ⬇️⬇️⬇️
        await _saveLastQuoteForWidget(quote);
        // ⬆️⬆️⬆️ FIN LLAMADA ⬆️⬆️⬆️

        await StatsService.instance.trackQuoteView(quote);

        final oldLevel = _userProfile?.level ?? 1;

        await StatsService.instance.addXP(10);
        await StatsService.instance.updateUserStreak();

        await _checkAndRequestReview();

        final newProfile = await db.getUserProfile();
        if (newProfile != null) {
          final newLevel = newProfile.level;

          setState(() {
            _userProfile = newProfile;
          });

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

  Future<void> _checkAndRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyRequested = prefs.getBool('review_requested') ?? false;
      if (alreadyRequested) return;

      final streak = _userProfile?.currentStreak ?? 0;
      if (streak < 3) return;

      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool('review_requested', true);
      }
    } catch (e) {
      print('Review request error: $e');
    }
  }

  Future<void> _generateAiQuote() async {
    print('🤖 Iniciando generación con IA...');

    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Perfil no encontrado'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accent),
              SizedBox(height: 16),
              Text(
                '✨ Generando tu frase...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Esto puede tomar unos segundos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final aiService = AiService.instance;
      final generatedText =
          await aiService.generatePersonalizedQuote(_userProfile!);

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      if (generatedText != null && generatedText.isNotEmpty) {
        // Crear Quote con la frase generada
        final aiQuote = Quote(
          text: generatedText,
          author: 'IA Personalizada para ${_userProfile!.name}',
          category: 'Personalizada',
          source: 'ai-generated',
          language: 'es',
          isFavorite: true,
          lastShown: DateTime.now(),
          viewCount: 1,
        );

        // Guardar en BD
        final db = DatabaseHelper.instance;
        await db.insertQuote(aiQuote);

        // Mostrar
        setState(() {
          _currentQuote = aiQuote;
        });

        // ⬇️⬇️⬇️ LLAMADA AGREGADA ⬇️⬇️⬇️
        await _saveLastQuoteForWidget(aiQuote);
        // ⬆️⬆️⬆️ FIN LLAMADA ⬆️⬆️⬆️

        // Agregar XP bonus por usar IA
        await StatsService.instance.addXP(25);

        // Actualizar perfil
        final newProfile = await db.getUserProfile();
        if (newProfile != null && mounted) {
          setState(() {
            _userProfile = newProfile;
          });
        }

        // Actualizar widget de Android
        if (mounted) {
          final quoteData = {
            'text': aiQuote.text,
            'author': aiQuote.author ?? 'IA Personalizada',
          };

          try {
            await const MethodChannel('com.example.motivation_pro/widget')
                .invokeMethod('updateWidget', quoteData);
            print('✅ Widget actualizado con frase de IA');
          } catch (e) {
            print('⚠️ Error actualizando widget: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Frase personalizada generada (+25 XP)'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ No se pudo generar frase. Intenta de nuevo'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error generando con IA: $e');

      // Cerrar loading si aún está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
      ''').timeout(Duration(seconds: 3));

      print('✅ Todas las frases reseteadas');

      print('🟡 RESET: Esperando 500ms...');
      await Future.delayed(Duration(milliseconds: 500));

      print('🟡 RESET: Llamando _loadRandomQuote()...');
      await _loadRandomQuote();

      print('🟡 RESET: _loadRandomQuote() terminó');

      if (mounted && _currentQuote != null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
          SnackBar(
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
            duration: Duration(seconds: 3),
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
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'No cuentes los días, haz que los días cuenten.',
          author: 'Muhammad Ali',
          category: 'Motivación',
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'El único modo de hacer un gran trabajo es amar lo que haces.',
          author: 'Steve Jobs',
          category: 'Productividad',
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'Cree que puedes y ya estarás a medio camino.',
          author: 'Theodore Roosevelt',
          category: 'Mentalidad',
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'La vida es 10% lo que te pasa y 90% cómo reaccionas.',
          author: 'Charles Swindoll',
          category: 'Bienestar',
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text:
              'El futuro pertenece a quienes creen en la belleza de sus sueños.',
          author: 'Eleanor Roosevelt',
          category: 'Motivación',
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text: 'La mejor manera de predecir el futuro es crearlo.',
          author: 'Peter Drucker',
          category: 'Metas',
          language: 'es',
          lastShown: null,
          viewCount: 0,
        ),
        Quote(
          text:
              'Elige un trabajo que ames y no tendrás que trabajar ni un día.',
          author: 'Confucio',
          category: 'Productividad',
          language: 'es',
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

      await Future.delayed(Duration(milliseconds: 300));
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
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
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
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : Column(
                  children: [
                    // Banner de sin conexión
                    if (!_hasInternet)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.warning.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Sin conexión - Mostrando frases guardadas',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header
                    Padding(
                      padding: EdgeInsets.all(24),
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
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      AppStrings.homeQuoteOfDay,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    if (_userProfile != null &&
                                        _userProfile!.currentStreak > 0) ...[
                                      SizedBox(width: 10),
                                      StreakIndicator(
                                          streak:
                                              _userProfile!.currentStreak),
                                    ],
                                  ],
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
                            icon: Icon(Icons.settings_outlined),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),

                    // XP Bar
                    if (_userProfile != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: XpBar(
                          currentXp: _userProfile!.totalXp,
                          level: _userProfile!.level,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Estado de ánimo diario
                    const MoodPickerWidget(),

                    const SizedBox(height: 8),

                    // Desafío del día
                    const DailyChallengeCard(),

                    const SizedBox(height: 8),

                    // Quote Card o Pantalla de Emergencia
                    Expanded(
                      child: Center(
                        child: _currentQuote != null
                            ? Column(
                                children: [
                                  // Quote Card
                                  Expanded(
                                    child: QuoteCard(
                                      key: ValueKey(_currentQuote!.id ??
                                          _currentQuote!.text),
                                      quote: _currentQuote!,
                                      onNextQuote: _loadRandomQuoteWithStats,
                                    ),
                                  ),

                                  // Botones de acción
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        // Botón IA
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _generateAiQuote,
                                            icon: const Icon(
                                                Icons.auto_awesome,
                                                size: 18),
                                            label: const Text(
                                              'Generar con IA',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.accent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              elevation: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Botón Reflexionar
                                        ElevatedButton.icon(
                                          onPressed: _currentQuote == null
                                              ? null
                                              : () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ReflectionScreen(
                                                              quote:
                                                                  _currentQuote!),
                                                    ),
                                                  ),
                                          icon: const Icon(
                                              Icons.edit_note_outlined,
                                              size: 18),
                                          label: const Text('Reflexionar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.surface,
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14, horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              side: BorderSide(
                                                  color: AppColors.primary
                                                      .withOpacity(0.4)),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Padding(
                                padding: EdgeInsets.all(32),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 80,
                                        color: AppColors.warning,
                                      ),
                                      SizedBox(height: 24),
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
                                      SizedBox(height: 12),
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
                                      SizedBox(height: 32),

                                      // BOTÓN 1: Cargar Frases de Emergencia
                                      ElevatedButton.icon(
                                        onPressed: _forceLoadEmergencyQuotes,
                                        icon: Icon(Icons.add_circle_outline,
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
                                          padding: EdgeInsets.symmetric(
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

                                      SizedBox(height: 12),

                                      // BOTÓN 2: Resetear
                                      OutlinedButton.icon(
                                        onPressed: _resetQuotes,
                                        icon: Icon(Icons.refresh),
                                        label:
                                            const Text('Resetear Existentes'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: BorderSide(
                                            color: AppColors.primary,
                                            width: 2,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: 12),

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
                                        icon: Icon(Icons.cloud_outlined),
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
                      padding: EdgeInsets.all(24),
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
