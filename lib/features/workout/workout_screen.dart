import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../shared/widgets/exercise_gif_widget.dart';
import '../programs/programs_provider.dart';
import 'workout_provider.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProgram = ref.watch(activeProgramProvider);
    final workoutState = ref.watch(workoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ProgramRepository.instance.fetchFromRemote();
          ref.read(programsProvider.notifier).refresh();
        },
        color: primaryRed,
        child: activeProgram == null
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: _NoProgram(onSetup: () => context.push('/programs/create')),
                ),
              )
            : _ProgramPreview(
                program: activeProgram,
                isWorkoutActive: workoutState.isActive,
                onStart: () => context.push('/workout/active'),
              ),
      ),
    );
  }
}

class _NoProgram extends StatelessWidget {
  final VoidCallback onSetup;

  const _NoProgram({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryRed.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center_rounded, color: primaryRed, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Program',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set up a workout program to start tracking your sessions.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Set Up Program'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramPreview extends ConsumerWidget {
  final dynamic program;
  final bool isWorkoutActive;
  final VoidCallback onStart;

  const _ProgramPreview({
    required this.program,
    required this.isWorkoutActive,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayIndex = program.currentDayIndex % program.days.length;
    final today = program.days[dayIndex];

    // Detect if this day was already completed in a prior session
    final alreadyDone = SessionRepository.instance.getAll().any((s) =>
        s.programId == program.id &&
        s.dayName == today.name &&
        s.completed);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program name chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: steelBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    program.name,
                    style: const TextStyle(
                      color: steelBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Today: ${today.name}",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${today.exercises.length} exercises',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (isWorkoutActive)
                  _ActiveBanner(onResume: onStart)
                else
                  ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Workout'),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                  ),
                if (!isWorkoutActive && alreadyDone) ...[
                  const SizedBox(height: 10),
                  _AlreadyDoneBanner(
                    onSkip: () async {
                      await ProgramRepository.instance.advanceDay(program.id);
                      ref.read(programsProvider.notifier).refresh();
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Text("Today's Exercises", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ex = today.exercises[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ExerciseGifWidget(gifUrl: ex.gifUrl, exerciseName: ex.name, width: 52, height: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ex.sets} × ${ex.repsFrom}–${ex.repsTo} · ${ex.restTime}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: primaryRed.withAlpha(150),
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: today.exercises.length,
          ),
        ),
        // Upcoming days
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Upcoming Days', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final upcomingIndex = (dayIndex + index + 1) % program.days.length;
              final day = program.days[upcomingIndex];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: borderLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'D${day.dayNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: textDark,
                          ),
                        ),
                      ),
                    ),
                    title: Text(day.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text('${day.exercises.length} exercises', style: Theme.of(context).textTheme.bodySmall),
                    dense: true,
                  ),
                ),
              );
            },
            childCount: (program.days.length - 1).clamp(0, 3),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final VoidCallback onResume;

  const _ActiveBanner({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tealSuccess.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tealSuccess.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: tealSuccess),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Workout In Progress', style: TextStyle(color: tealSuccess, fontWeight: FontWeight.w700)),
                Text('Tap to resume', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: tealSuccess,
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}

class _AlreadyDoneBanner extends StatelessWidget {
  final VoidCallback onSkip;
  const _AlreadyDoneBanner({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primaryRed.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryRed.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: primaryRed, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Looks like you already did this day.',
              style: TextStyle(color: primaryRed, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Next Day →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
