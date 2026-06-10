import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'achievement_model.dart';

/// Full-screen overlay shown when a new achievement is unlocked.
/// Call [show] to present it; it auto-dismisses after 4 seconds.
class AchievementOverlay extends StatefulWidget {
  final AchievementModel achievement;
  final VoidCallback onDismiss;

  const AchievementOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context,
    AchievementModel achievement,
  ) async {
    await HapticFeedback.heavyImpact();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => _AchievementDialog(achievement: achievement),
    );
  }

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    Future.delayed(const Duration(seconds: 4), widget.onDismiss);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(_confettiCtrl.value),
            size: MediaQuery.of(context).size,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.success.withAlpha(100), width: 2),
              boxShadow: [
                BoxShadow(
                    color: AppColors.success.withAlpha(60),
                    blurRadius: 40,
                    spreadRadius: 8),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Achievement Unlocked!',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 20),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.success.withAlpha(60),
                      AppColors.success.withAlpha(20),
                    ]),
                    border: Border.all(color: AppColors.success, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.achievement.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                )
                    .animate()
                    .scale(
                        begin: const Offset(0.3, 0.3),
                        end: const Offset(1.0, 1.0),
                        duration: 500.ms,
                        curve: Curves.elasticOut)
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 20),
                Text(
                  widget.achievement.title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut),
                const SizedBox(height: 8),
                Text(
                  widget.achievement.description,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withAlpha(170)),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(40),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementDialog extends StatelessWidget {
  final AchievementModel achievement;
  const _AchievementDialog({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: _AchievementContent(achievement: achievement),
    );
  }
}

class _AchievementContent extends StatefulWidget {
  final AchievementModel achievement;
  const _AchievementContent({required this.achievement});

  @override
  State<_AchievementContent> createState() => _AchievementContentState();
}

class _AchievementContentState extends State<_AchievementContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _confettiCtrl,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(_confettiCtrl.value),
            size: const Size(400, 600),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: AppColors.success.withAlpha(100), width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.success.withAlpha(60),
                  blurRadius: 40,
                  spreadRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.success.withAlpha(60),
                    AppColors.success.withAlpha(20),
                  ]),
                  border: Border.all(color: AppColors.success, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(widget.achievement.emoji,
                    style: const TextStyle(fontSize: 48)),
              )
                  .animate()
                  .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 20),
              Text(
                widget.achievement.title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 200.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                widget.achievement.description,
                style:
                    TextStyle(fontSize: 14, color: Colors.white.withAlpha(170)),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.success.withAlpha(40),
                  side: const BorderSide(color: AppColors.success),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
                child: const Text('Awesome!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ],
    );
  }
}

// Simple confetti particle painter
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _rng = Random(42);
  static final _particles = List.generate(40, (_) {
    return _Particle(
      x: _rng.nextDouble(),
      startY: -0.1 - _rng.nextDouble() * 0.3,
      speed: 0.3 + _rng.nextDouble() * 0.5,
      size: 4 + _rng.nextDouble() * 6,
      color: _kColors[_rng.nextInt(_kColors.length)],
      rotation: _rng.nextDouble() * 2 * pi,
      rotSpeed: (_rng.nextDouble() - 0.5) * 8,
      wobble: (_rng.nextDouble() - 0.5) * 0.04,
    );
  });

  static const _kColors = [
    Color(0xFF34D399), // success green
    Color(0xFF38BDF8), // primary blue
    Color(0xFFFBBF24), // yellow
    Color(0xFFF472B6), // pink
    Color(0xFFA78BFA), // purple
  ];

  const _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.x) % 1.2;
      if (t < 0) continue;
      final x = (p.x + sin(t * 10) * p.wobble) * size.width;
      final y = (p.startY + t) * size.height;
      if (y > size.height + 20) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * p.rotSpeed);
      final paint = Paint()..color = p.color.withAlpha(220);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  final double x, startY, speed, size, rotation, rotSpeed, wobble;
  final Color color;
  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotSpeed,
    required this.wobble,
  });
}
