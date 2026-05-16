import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/services/workoutx_service.dart';
import '../../data/warmup_library.dart';
import '../../shared/providers/api_key_provider.dart';
import '../../shared/widgets/rest_timer_widget.dart';
import '../home/home_provider.dart';
import '../programs/programs_provider.dart';
import 'log_set_sheet.dart';
import 'workout_provider.dart';

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  const LiveWorkoutScreen({super.key});

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen> {
  bool _warmupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWorkout());
  }

  void _initWorkout() {
    final workoutState = ref.read(workoutProvider);
    if (workoutState.isActive) {
      // Resuming — skip warmup
      setState(() => _warmupDone = true);
    } else {
      final activeProgram = ref.read(activeProgramProvider);
      if (activeProgram != null && activeProgram.days.isNotEmpty) {
        final dayIndex = activeProgram.currentDayIndex % activeProgram.days.length;
        final day = activeProgram.days[dayIndex];
        ref.read(workoutProvider.notifier).startWorkout(activeProgram, day);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);

    if (!state.isActive || state.currentDay == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator(color: tealSuccess)),
      );
    }

    final day = state.currentDay!;

    if (!_warmupDone) {
      return _WarmupScreen(
        dayName: day.name,
        onStart: () => setState(() => _warmupDone = true),
        onSkip: () => setState(() => _warmupDone = true),
      );
    }

    final exercises = day.exercises;
    final currentIndex = state.currentExerciseIndex;
    final currentExercise = currentIndex < exercises.length ? exercises[currentIndex] : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldLeave = await _confirmLeave(context);
          if (shouldLeave && context.mounted) {
            ref.read(workoutProvider.notifier).cancelWorkout();
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final shouldLeave = await _confirmLeave(context);
              if (shouldLeave && context.mounted) {
                ref.read(workoutProvider.notifier).cancelWorkout();
                context.pop();
              }
            },
          ),
          title: Text(day.name),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded, color: primaryRed, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        FitDateUtils.formatTime(state.elapsedSeconds),
                        style: const TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.restTimerActive) const RestTimerWidget(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (currentExercise != null)
                    SliverToBoxAdapter(
                      child: _CurrentExerciseCard(
                        exercise: currentExercise,
                        exerciseIndex: currentIndex,
                        totalExercises: exercises.length,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('Sets', style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ),
                  if (currentExercise != null)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final completedSets = ref
                              .read(workoutProvider.notifier)
                              .completedSetsForExercise(currentIndex);
                          final totalSets = currentExercise.sets;
                          if (index >= totalSets) return null;
                          final isCompleted = index < completedSets;
                          final isActive = index == completedSets;

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                            child: _SetRow(
                              setNumber: index + 1,
                              isCompleted: isCompleted,
                              isActive: isActive,
                              session: state.session,
                              exerciseIndex: currentIndex,
                              setIndex: index,
                              exercise: currentExercise,
                            ),
                          );
                        },
                        childCount: currentExercise.sets,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            _BottomActions(
              onLogSet: () => _showLogSetSheet(context),
              onFinish: () => _showCooldownSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSetSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogSetSheet(),
    );
  }

  void _showCooldownSheet(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CooldownSheet(
        onDone: () {
          Navigator.pop(context);
          _saveAndExit(context);
        },
        onSkip: () {
          Navigator.pop(context);
          _saveAndExit(context);
        },
      ),
    );
  }

  Future<void> _saveAndExit(BuildContext context) async {
    final session = await ref.read(workoutProvider.notifier).finishWorkout();
    if (context.mounted) {
      ref.read(homeRefreshProvider.notifier).refresh();
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(session != null
              ? 'Workout complete! ${session.durationMinutes} min'
              : 'Workout saved!'),
          backgroundColor: tealSuccess,
        ),
      );
    }
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: primaryRed)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─── Warmup Screen ────────────────────────────────────────────────────────────

class _WarmupScreen extends StatelessWidget {
  final String dayName;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const _WarmupScreen({
    required this.dayName,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final warmups = WarmupLibrary.forDay(dayName);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warm-Up'),
        actions: [
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip', style: TextStyle(color: Color(0xFF8899AA))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryRed.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: primaryRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete these warm-up exercises before starting $dayName.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...warmups.map((w) => _WarmupRow(warmup: w)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Workout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmupRow extends ConsumerStatefulWidget {
  final WarmupExercise warmup;
  const _WarmupRow({required this.warmup});

  @override
  ConsumerState<_WarmupRow> createState() => _WarmupRowState();
}

class _WarmupRowState extends ConsumerState<_WarmupRow> {
  String? _gifUrl;
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _tryLoadGif();
  }

  Future<void> _tryLoadGif() async {
    final key = ref.read(apiKeyProvider);
    if (key.isEmpty) return;
    _apiKey = key;
    final gif = await WorkoutXService(apiKey: key)
        .getExerciseGif(widget.warmup.name);
    if (mounted && gif != null) setState(() => _gifUrl = gif);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          // GIF or icon thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _gifUrl != null
                ? CachedNetworkImage(
                    imageUrl: _gifUrl!,
                    httpHeaders: _apiKey.isNotEmpty
                        ? {'X-WorkoutX-Key': _apiKey}
                        : null,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _iconBox(),
                  )
                : _iconBox(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.warmup.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(widget.warmup.description,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: steelBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.warmup.durationLabel,
              style: const TextStyle(
                color: steelBlue,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox() => Container(
        width: 52,
        height: 52,
        color: steelBlue.withAlpha(20),
        child: const Icon(Icons.directions_run_rounded,
            color: steelBlue, size: 24),
      );
}

// ─── Cooldown Sheet ───────────────────────────────────────────────────────────

class _CooldownSheet extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onSkip;

  const _CooldownSheet({required this.onDone, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    const cooldowns = WarmupLibrary.cooldowns;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.self_improvement_rounded, color: tealSuccess, size: 24),
              const SizedBox(width: 10),
              Text('Cool-Down', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: const Text('Skip', style: TextStyle(color: Color(0xFF8899AA))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Great workout! Take 5 minutes to recover.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ...cooldowns.map((c) => _CooldownRow(cooldown: c)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: tealSuccess,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Done — Save Workout'),
          ),
        ],
      ),
    );
  }
}

class _CooldownRow extends StatelessWidget {
  final WarmupExercise cooldown;
  const _CooldownRow({required this.cooldown});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.spa_rounded, color: tealSuccess, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cooldown.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(cooldown.description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            cooldown.durationLabel,
            style: const TextStyle(color: tealSuccess, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Existing Widgets ─────────────────────────────────────────────────────────

class _CurrentExerciseCard extends ConsumerWidget {
  final dynamic exercise;
  final int exerciseIndex;
  final int totalExercises;

  const _CurrentExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navyDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${exerciseIndex + 1}/$totalExercises',
                style: const TextStyle(color: lightSteel, fontSize: 12),
              ),
              Row(
                children: [
                  if (exerciseIndex > 0)
                    IconButton(
                      onPressed: () => ref.read(workoutProvider.notifier).previousExercise(),
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: lightSteel, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  if (exerciseIndex < totalExercises - 1)
                    IconButton(
                      onPressed: () => ref.read(workoutProvider.notifier).nextExercise(),
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: lightSteel, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${exercise.sets} sets × ${exercise.repsFrom}–${exercise.repsTo} reps · Rest ${exercise.restTime}',
            style: const TextStyle(color: lightSteel, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final bool isCompleted;
  final bool isActive;
  final dynamic session;
  final int exerciseIndex;
  final int setIndex;
  final dynamic exercise;

  const _SetRow({
    required this.setNumber,
    required this.isCompleted,
    required this.isActive,
    required this.session,
    required this.exerciseIndex,
    required this.setIndex,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    String setInfo = '${exercise.repsFrom}–${exercise.repsTo} reps';
    if (isCompleted && session != null) {
      try {
        final loggedEx = session.exercises[exerciseIndex];
        if (setIndex < loggedEx.sets.length) {
          final s = loggedEx.sets[setIndex];
          setInfo = '${s.weight}kg × ${s.reps} reps';
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? tealSuccess.withAlpha(15)
            : isActive
                ? primaryRed.withAlpha(10)
                : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? tealSuccess.withAlpha(80)
              : isActive
                  ? primaryRed.withAlpha(80)
                  : Theme.of(context).dividerColor.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              'S$setNumber',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isCompleted
                    ? tealSuccess
                    : isActive
                        ? primaryRed
                        : Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              setInfo,
              style: TextStyle(
                color: isCompleted
                    ? tealSuccess
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? tealSuccess
                  : isActive
                      ? primaryRed
                      : Theme.of(context).dividerColor.withAlpha(80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isCompleted ? '✓' : isActive ? '→' : '–',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onLogSet;
  final VoidCallback onFinish;

  const _BottomActions({required this.onLogSet, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            onPressed: onLogSet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log Next Set'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onFinish,
            style: TextButton.styleFrom(
              foregroundColor: tealSuccess,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('Finish Workout', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
