import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/stats_service.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/habit.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Habit> _habits = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await DatabaseHelper.instance.getAllHabits();
    if (mounted) setState(() => _habits = list);
  }

  Future<void> _addHabit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final habit = Habit(
      name: name.length > 100 ? name.substring(0, 100) : name,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertHabit(habit);
    _controller.clear();
    await _load();
  }

  Future<void> _toggleComplete(Habit habit) async {
    if (habit.completedToday) return; // ya completado hoy

    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    // Calcular nueva racha
    int newStreak = habit.currentStreak;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (habit.lastCompletedDate == yesterdayStr) {
      newStreak++; // racha consecutiva
    } else {
      newStreak = 1; // reinicia
    }

    final newMax =
        newStreak > habit.maxStreak ? newStreak : habit.maxStreak;

    final updated = habit.copyWith(
      currentStreak: newStreak,
      maxStreak: newMax,
      lastCompletedDate: today,
    );
    await DatabaseHelper.instance.updateHabit(updated);

    // +10 XP por completar hábito
    await StatsService.instance.addXP(10);

    await _load();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '✅ ${habit.name} completado — racha: $newStreak día${newStreak == 1 ? '' : 's'} (+10 XP)'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _deleteHabit(int id) async {
    await DatabaseHelper.instance.deleteHabit(id);
    await _load();
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                    ),
                    Expanded(
                      child: Text(
                        'Mis Hábitos',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Marca cada hábito completado para mantener tu racha diaria.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
              ),

              // Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLength: 100,
                          decoration: InputDecoration(
                            hintText: 'Nuevo hábito (ej: Leer 15 min)...',
                            hintStyle:
                                TextStyle(color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            counterText: '',
                          ),
                          style: TextStyle(color: AppColors.textPrimary),
                          onSubmitted: (_) => _addHabit(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addHabit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _habits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 52, color: AppColors.textTertiary),
                            const SizedBox(height: 14),
                            Text(
                              'Aún no tienes hábitos.\nAgrega el primero arriba.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, height: 1.6),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _habits.length,
                        itemBuilder: (context, i) {
                          final h = _habits[i];
                          final done = h.completedToday;

                          return Dismissible(
                            key: ValueKey(h.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) => _deleteHabit(h.id!),
                            child: GestureDetector(
                              onTap: () => _toggleComplete(h),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: done
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: done
                                        ? AppColors.primary.withValues(alpha: 0.4)
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Checkbox visual
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: done
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: done
                                              ? AppColors.primary
                                              : AppColors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: done
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),

                                    // Texto
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h.name,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: done
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (h.currentStreak > 0) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              '🔥 ${h.currentStreak} día${h.currentStreak == 1 ? '' : 's'} · máx ${h.maxStreak}',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Estado
                                    if (done)
                                      Text(
                                        '¡Listo!',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Toca para completar',
                                        style: TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
