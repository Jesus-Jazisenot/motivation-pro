import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/stats_service.dart';
import '../../data/database/database_helper.dart';

class DailyChallengeCard extends StatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  State<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends State<DailyChallengeCard> {
  String? _challengeText;
  bool _completed = false;
  bool _isLoading = true;
  bool _isGenerating = false;

  static const _keyText = 'daily_challenge_text';
  static const _keyDate = 'daily_challenge_date';
  static const _keyDone = 'daily_challenge_done';

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final savedDate = prefs.getString(_keyDate);

    if (savedDate == today) {
      setState(() {
        _challengeText = prefs.getString(_keyText);
        _completed = prefs.getBool(_keyDone) ?? false;
        _isLoading = false;
      });
    } else {
      await _generateNew(prefs, today);
    }
  }

  Future<void> _generateNew([SharedPreferences? prefs, String? today]) async {
    setState(() {
      _isGenerating = true;
      _isLoading = false;
    });

    try {
      prefs ??= await SharedPreferences.getInstance();
      today ??= _todayStr();

      final profile = await DatabaseHelper.instance.getUserProfile();
      if (profile == null) {
        setState(() => _isGenerating = false);
        return;
      }

      final text =
          await AiService.instance.generateDailyChallenge(profile);

      await prefs.setString(_keyText, text);
      await prefs.setString(_keyDate, today);
      await prefs.setBool(_keyDone, false);

      if (mounted) {
        setState(() {
          _challengeText = text;
          _completed = false;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _toggleComplete() async {
    final newValue = !_completed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDone, newValue);

    setState(() => _completed = newValue);

    if (newValue) {
      await StatsService.instance.addXP(20);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Desafío completado! +20 XP'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _completed
            ? AppColors.success.withOpacity(0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _completed
              ? AppColors.success.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 16,
                color: _completed ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'DESAFÍO DEL DÍA',
                style: TextStyle(
                  color: _completed ? AppColors.success : AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Botón regenerar
              if (!_completed)
                GestureDetector(
                  onTap: _isGenerating ? null : () => _generateNew(),
                  child: Icon(
                    Icons.refresh,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isGenerating)
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Generando desafío...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else if (_challengeText != null)
            Text(
              _challengeText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    decoration: _completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: _completed
                        ? AppColors.textTertiary
                        : null,
                  ),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _challengeText == null ? null : _toggleComplete,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _completed
                        ? AppColors.success
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _completed
                          ? AppColors.success
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: _completed
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  _completed ? 'Completado hoy' : 'Marcar como completado',
                  style: TextStyle(
                    color: _completed
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: _completed
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
