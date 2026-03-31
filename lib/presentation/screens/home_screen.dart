import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/mood_entry.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/stats_service.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';
import '../../data/models/user_profile.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/xp_bar.dart';
import '../widgets/streak_indicator.dart';
import 'reflection_screen.dart';
import 'settings_screen.dart';
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
  bool _isGeneratingAi = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadData();
  }

  Future<void> _saveLastQuoteForWidget(Quote quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_quote_text', quote.text);
      await prefs.setString('last_quote_author', quote.author ?? 'Anónimo');
    } catch (_) {}
  }

  Future<void> _checkConnection() async {
    final hasConnection =
        await ConnectivityService.instance.hasConnection();
    if (mounted) setState(() => _hasInternet = hasConnection);
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final profile = await DatabaseHelper.instance.getUserProfile();
      if (profile != null) {
        _userName = profile.name;
        _userProfile = profile;
        if (profile.currentStreak > 0) {
          NotificationService.instance
              .scheduleStreakReminder(profile.currentStreak);
        }
      }
      await _loadDailyQuote();
    } catch (e) {
      print('Error en _loadData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDailyQuote() async {
    try {
      final quote = await DatabaseHelper.instance.getDailyQuote();
      if (quote != null && mounted) {
        setState(() => _currentQuote = quote);
        await DatabaseHelper.instance.updateQuote(quote.copyWith(
          lastShown: DateTime.now(),
          viewCount: quote.viewCount + 1,
        ));
        await _saveLastQuoteForWidget(quote);
      }
    } catch (_) {
      await _loadRandomQuote();
    }
  }

  Future<void> _loadRandomQuote() async {
    try {
      final quote = await DatabaseHelper.instance.getRandomQuote().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (quote != null && mounted) {
        setState(() => _currentQuote = quote);
      }
    } catch (_) {}
  }

  Future<void> _loadNextQuote() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _checkConnection();
      final quote = await DatabaseHelper.instance.getHybridQuote().timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
      if (quote != null) {
        setState(() => _currentQuote = quote);
        await DatabaseHelper.instance.updateQuote(quote.copyWith(
          lastShown: DateTime.now(),
          viewCount: quote.viewCount + 1,
        ));
        await _saveLastQuoteForWidget(quote);
        await StatsService.instance.trackQuoteView(quote);

        final oldLevel = _userProfile?.level ?? 1;
        await StatsService.instance.addXP(10);
        await StatsService.instance.updateUserStreak();
        await _checkAndRequestReview();

        final newProfile = await DatabaseHelper.instance.getUserProfile();
        if (newProfile != null && mounted) {
          setState(() => _userProfile = newProfile);
          if (newProfile.level > oldLevel) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => LevelUpDialog(
                newLevel: newProfile.level,
                totalXp: newProfile.totalXp,
              ),
            );
          }
        }

        try {
          await const MethodChannel('com.example.motivation_pro/widget')
              .invokeMethod('updateWidget', {
            'text': quote.text,
            'author': quote.author ?? 'Anónimo',
          });
        } catch (_) {}
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('review_requested') ?? false) return;
      if ((_userProfile?.currentStreak ?? 0) < 3) return;
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool('review_requested', true);
      }
    } catch (_) {}
  }

  Future<void> _generateAiQuote() async {
    if (_userProfile == null || _isGeneratingAi) return;
    setState(() => _isGeneratingAi = true);
    try {
      final generatedText =
          await AiService.instance.generatePersonalizedQuote(_userProfile!);
      if (generatedText != null && generatedText.isNotEmpty && mounted) {
        final aiQuote = Quote(
          text: generatedText,
          author: null, // frase personal, sin autor ficticio
          category: 'Personalizada',
          source: 'ai-generated',
          language: 'es',
          isFavorite: false,
          lastShown: DateTime.now(),
          viewCount: 1,
        );
        final id = await DatabaseHelper.instance.insertQuote(aiQuote);
        final saved = aiQuote.copyWith(id: id);
        setState(() => _currentQuote = saved);
        await _saveLastQuoteForWidget(saved);
        await StatsService.instance.addXP(25);
        final newProfile = await DatabaseHelper.instance.getUserProfile();
        if (newProfile != null && mounted) {
          setState(() => _userProfile = newProfile);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('✨ Frase personalizada generada (+25 XP)'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al generar: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAi = false);
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
          child: _isLoading && _currentQuote == null
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    // ── Header compacto ──
                    _buildHeader(),

                    // ── Sin conexión (banner fino) ──
                    if (!_hasInternet) _buildOfflineBanner(),

                    // ── FRASE — ocupa todo el espacio disponible ──
                    Expanded(
                      child: _currentQuote != null
                          ? _buildQuoteSection()
                          : _buildEmptyState(),
                    ),

                    // ── Acciones inferiores ──
                    if (_currentQuote != null) _buildBottomActions(),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Header compacto: nombre + streak + XP + settings en una sola fila ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '¡Hola, $_userName!',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_userProfile != null &&
                            _userProfile!.currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          StreakIndicator(streak: _userProfile!.currentStreak),
                        ],
                      ],
                    ),
                    Text(
                      AppStrings.homeQuoteOfDay,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Mood del día (compacto, solo el emoji seleccionado)
              const _CompactMoodButton(),
              IconButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: const Icon(Icons.settings_outlined, size: 22),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          // XP bar delgada
          if (_userProfile != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: XpBar(
                currentXp: _userProfile!.totalXp,
                level: _userProfile!.level,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 14),
          const SizedBox(width: 8),
          Text(
            'Sin conexión — mostrando frases guardadas',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── La frase ocupa el espacio y se centra visualmente ──
  Widget _buildQuoteSection() {
    final quote = _currentQuote!;
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -300) {
          _loadNextQuote(); // swipe up = nueva frase
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Comilla decorativa
            Text(
              '"',
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.25),
                fontSize: 120,
                height: 0.6,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 16),

            // TEXTO DE LA FRASE — protagonista
            Text(
              quote.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
            ),

            // Autor (solo si existe y no es "IA Personalizada")
            if (quote.author != null &&
                !quote.author!.startsWith('IA') &&
                quote.author!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '— ${quote.author}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Categoría (chip pequeño)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                quote.category.toUpperCase(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Hint de swipe
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Desliza arriba para nueva frase',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Acciones en la parte inferior: iconos + dos botones ──
  Widget _buildBottomActions() {
    final quote = _currentQuote!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Iconos de acción (favorito, reflexionar, compartir)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionIcon(
                icon: quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: quote.isFavorite ? AppColors.favorite : AppColors.textSecondary,
                onTap: _toggleFavorite,
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.edit_note_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ReflectionScreen(quote: quote)),
                ),
              ),
              const SizedBox(width: 16),
              _ActionIcon(
                icon: Icons.share_outlined,
                onTap: _shareQuote,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Botón principal: Nueva frase + Generar con IA
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loadNextQuote,
                  icon: _isLoading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Nueva frase'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingAi ? null : _generateAiQuote,
                  icon: _isGeneratingAi
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generar con IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 64, color: AppColors.warning),
            const SizedBox(height: 20),
            Text('Sin frases disponibles',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_currentQuote == null) return;
    final updated =
        _currentQuote!.copyWith(isFavorite: !_currentQuote!.isFavorite);
    await DatabaseHelper.instance.updateQuote(updated);
    setState(() => _currentQuote = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(updated.isFavorite
            ? '❤️ Añadido a favoritos'
            : '💔 Eliminado de favoritos'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _shareQuote() {
    if (_currentQuote == null) return;
    final q = _currentQuote!;
    final text = q.author != null && q.author!.isNotEmpty
        ? '"${q.text}"\n\n— ${q.author}'
        : '"${q.text}"';
    Share.share(text);
  }
}

// ── Widget compacto de mood en el header ──
class _CompactMoodButton extends StatefulWidget {
  const _CompactMoodButton();

  @override
  State<_CompactMoodButton> createState() => _CompactMoodButtonState();
}

class _CompactMoodButtonState extends State<_CompactMoodButton> {
  int? _todayMood;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mood =
        await DatabaseHelper.instance.getMoodForDate(DateTime.now());
    if (mounted) setState(() => _todayMood = mood?.mood);
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Cómo te sientes hoy?',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final value = i + 1;
                return GestureDetector(
                  onTap: () async {
                    final entry = MoodEntry(
                        mood: value, createdAt: DateTime.now());
                    await DatabaseHelper.instance.insertMood(entry);
                    setState(() => _todayMood = value);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      Text(MoodEntry.emojiForMood(value),
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 4),
                      Text(MoodEntry.labelForMood(value),
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          _todayMood != null ? MoodEntry.emojiForMood(_todayMood!) : '🙂',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

// ── Icono de acción con ripple ──
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 24,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
