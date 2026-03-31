import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/mood_entry.dart';

class MoodPickerWidget extends StatefulWidget {
  const MoodPickerWidget({super.key});

  @override
  State<MoodPickerWidget> createState() => _MoodPickerWidgetState();
}

class _MoodPickerWidgetState extends State<MoodPickerWidget> {
  MoodEntry? _todayMood;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayMood();
  }

  Future<void> _loadTodayMood() async {
    final mood = await DatabaseHelper.instance.getMoodForDate(DateTime.now());
    if (mounted) setState(() { _todayMood = mood; _loading = false; });
  }

  Future<void> _saveMood(int value) async {
    final entry = MoodEntry(mood: value, createdAt: DateTime.now());
    await DatabaseHelper.instance.insertMood(entry);
    if (mounted) setState(() => _todayMood = entry);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: _todayMood == null ? _buildPicker() : _buildResult(),
      ),
    );
  }

  Widget _buildPicker() {
    return Row(
      children: [
        Text(
          '¿Cómo te sientes?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        ...List.generate(5, (i) {
          final value = i + 1;
          return GestureDetector(
            onTap: () => _saveMood(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                MoodEntry.emojiForMood(value),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResult() {
    return Row(
      children: [
        Text(
          MoodEntry.emojiForMood(_todayMood!.mood),
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(width: 8),
        Text(
          'Hoy: ${MoodEntry.labelForMood(_todayMood!.mood)}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _todayMood = null),
          child: Text(
            'Cambiar',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
