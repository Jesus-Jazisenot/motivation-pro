import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Fases: inhale(4s) → hold(4s) → exhale(4s) → rest(2s)
  static const _phases = [
    _Phase('Inhala', 4, true),
    _Phase('Sostén', 4, false),
    _Phase('Exhala', 6, false),
    _Phase('Descansa', 2, false),
  ];

  int _phaseIndex = 0;
  int _secondsLeft = 0;
  bool _running = false;
  int _cyclesCompleted = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _resetPhase(0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _resetPhase(int index) {
    _phaseIndex = index;
    _secondsLeft = _phases[index].duration;

    final phase = _phases[index];
    _pulseController.stop();
    _pulseController.reset();

    if (phase.expand) {
      _pulseController.duration = Duration(seconds: phase.duration);
      _pulseController.forward();
    } else if (phase.name == 'Exhala') {
      _pulseController.duration = Duration(seconds: phase.duration);
      _pulseController.reverse(from: 1.0);
    }
  }

  void _start() {
    setState(() => _running = true);
    _tick();
  }

  void _stop() {
    setState(() {
      _running = false;
      _cyclesCompleted = 0;
    });
    _pulseController.stop();
    _resetPhase(0);
  }

  Future<void> _tick() async {
    while (_running && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_running) break;

      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          final nextIndex = (_phaseIndex + 1) % _phases.length;
          if (nextIndex == 0) _cyclesCompleted++;
          _resetPhase(nextIndex);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_phaseIndex];

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
                    Text(
                      'Respiración Consciente',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              if (_cyclesCompleted > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$_cyclesCompleted ciclo${_cyclesCompleted == 1 ? '' : 's'} completado${_cyclesCompleted == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const Spacer(),

              // Círculo animado
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _BreathingPainter(
                      scale: _running ? _pulseAnimation.value : 0.6,
                      color: AppColors.primary,
                    ),
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              phase.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_secondsLeft',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 40,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Phase indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_phases.length, (i) {
                  final active = _running && i == _phaseIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 12),
              Text(
                'Inhala 4s · Sostén 4s · Exhala 6s · Descansa 2s',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              // Botón
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: _running
                      ? OutlinedButton.icon(
                          onPressed: _stop,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Detener'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Comenzar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            elevation: 4,
                          ),
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

class _Phase {
  final String name;
  final int duration;
  final bool expand;
  const _Phase(this.name, this.duration, this.expand);
}

class _BreathingPainter extends CustomPainter {
  final double scale;
  final Color color;

  const _BreathingPainter({required this.scale, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer glow rings
    for (int i = 3; i >= 1; i--) {
      final radius = maxRadius * scale * (1 + i * 0.12);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.06 * i)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);
    }

    // Main circle
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * scale, mainPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - maxRadius * 0.15, center.dy - maxRadius * 0.15),
      maxRadius * scale * 0.4,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_BreathingPainter old) =>
      old.scale != scale || old.color != color;
}
