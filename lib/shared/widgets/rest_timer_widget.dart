import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../features/workout/workout_provider.dart';

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutProvider);
    if (!state.restTimerActive) return const SizedBox.shrink();

    final progress = state.restSecondsTotal > 0
        ? (state.restSecondsRemaining / state.restSecondsTotal).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primaryRed.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryRed.withAlpha(50)),
      ),
      child: Row(
        children: [
          // Circular progress indicator with timer icon inside
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: primaryRed.withAlpha(25),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
                ),
                const Icon(Icons.timer_rounded, color: primaryRed, size: 20),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Label + countdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rest',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryRed,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  FitDateUtils.formatTime(state.restSecondsRemaining),
                  style: const TextStyle(
                    color: primaryRed,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // +15s button
          TextButton(
            onPressed: () =>
                ref.read(workoutProvider.notifier).addRestSeconds(15),
            style: TextButton.styleFrom(
              foregroundColor: primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('+15s',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),

          const SizedBox(width: 4),

          // Skip button
          ElevatedButton(
            onPressed: () => ref.read(workoutProvider.notifier).skipRest(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child:
                const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
