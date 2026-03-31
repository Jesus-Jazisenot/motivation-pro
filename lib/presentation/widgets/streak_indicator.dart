import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StreakIndicator extends StatelessWidget {
  final int streak;

  const StreakIndicator({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _streakColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _streakColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _flameEmoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            '$streak ${streak == 1 ? 'día' : 'días'}',
            style: TextStyle(
              color: _streakColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String get _flameEmoji {
    if (streak >= 30) return '🔥';
    if (streak >= 7) return '🔥';
    return '🔥';
  }

  Color get _streakColor {
    if (streak >= 30) return const Color(0xFFFF4500);
    if (streak >= 7) return const Color(0xFFFF6B00);
    return AppColors.accent;
  }
}
