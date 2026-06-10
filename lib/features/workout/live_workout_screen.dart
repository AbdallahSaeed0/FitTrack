import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/warmup_library.dart';
import '../../shared/widgets/animated_exercise_image.dart';
import '../../shared/widgets/exercise_gif_widget.dart';
import '../../shared/widgets/rest_timer_widget.dart';
import '../achievements/achievement_overlay.dart';
import '../achievements/achievements_provider.dart';
import '../history/history_provider.dart';
import '../home/home_provider.dart';
import '../programs/programs_provider.dart';
import 'log_set_sheet.dart';
import 'workout_provider.dart';
import '../../data/models/session_model.dart';

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  const LiveWorkoutScreen({super.key});

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen>
    with WidgetsBindingObserver {
  bool _warmupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWorkout());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When coming back from background the periodic timer has been paused,
    // so elapsedSeconds drifts from wall-clock time. Re-sync from startTime.
    if (state == AppLifecycleState.resumed) {
      final session = ref.read(workoutProvider).session;
      if (session != null) {
        final elapsed = DateTime.now()
            .difference(session.startTime)
            .inSeconds
            .clamp(0, 86400);
        ref.read(workoutProvider.notifier).syncElapsedTime(elapsed);
      }
    }
  }

  void _showPrOverlay(BuildContext context, String exerciseName) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PrOverlayBanner(
        exerciseName: exerciseName,
        onDone: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }

  void _initWorkout() {
    final workoutState = ref.read(workoutProvider);
    if (workoutState.isActive) {
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
    // Show a PR overlay banner in the center whenever a new PR is detected.
    ref.listen(
      workoutProvider.select((s) => s.prExerciseName),
      (prev, next) {
        if (next != null && mounted) {
          _showPrOverlay(context, next);
        }
      },
    );

    final state = ref.watch(workoutProvider);

    if (!state.isActive || state.currentDay == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center_rounded,
                  size: 56, color: Color(0xFF8899AA)),
              const SizedBox(height: 16),
              const Text('No active workout session'),
              const SizedBox(height: 8),
              const Text(
                'Start a workout from the Workout tab.',
                style: TextStyle(color: Color(0xFF8899AA), fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/workout'),
                child: const Text('Go to Workout'),
              ),
            ],
          ),
        ),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
          title: Text(day.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: () => _showTimeAdjustDialog(context),
              tooltip: 'Adjust start time',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cancel') _confirmCancel(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: primaryRed, size: 18),
                      SizedBox(width: 8),
                      Text('Cancel Workout',
                          style: TextStyle(color: primaryRed)),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16, left: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded,
                          color: primaryRed, size: 16),
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
              child: Builder(builder: (context) {
                // Assign superset labels (A1/A2…, B1/B2…) based on groupId order.
                final supersetLabels = _computeSupersetLabels(exercises);
                return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: exercises.length,
                itemBuilder: (context, i) {
                  final ex = exercises[i];
                  final completedSets = ref
                      .read(workoutProvider.notifier)
                      .completedSetsForExercise(i);
                  final targetSets = ref
                      .read(workoutProvider.notifier)
                      .targetSetsForExercise(i);
                  final prevSameGroup = i > 0 &&
                      ex.supersetGroupId != null &&
                      exercises[i - 1].supersetGroupId == ex.supersetGroupId;
                  final nextSameGroup = i < exercises.length - 1 &&
                      ex.supersetGroupId != null &&
                      exercises[i + 1].supersetGroupId == ex.supersetGroupId;
                  return _ExerciseSummaryCard(
                    key: ValueKey(i),
                    exercise: ex,
                    exerciseIndex: i,
                    isCurrent: i == currentIndex,
                    completedSets: completedSets,
                    targetSets: targetSets,
                    supersetLabel: supersetLabels[i],
                    supersetContinuesAbove: prevSameGroup,
                    supersetContinuesBelow: nextSameGroup,
                    onTap: () {
                      ref
                          .read(workoutProvider.notifier)
                          .setCurrentExercise(i);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            _ExerciseDetailSheet(exerciseIndex: i),
                      );
                    },
                  );
                },
              );
              }),
            ),
            _BottomActions(
              onFinish: () => _showCooldownSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showCooldownSheet(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _CooldownSheet(
        onDone: () {
          Navigator.pop(sheetCtx);
          _saveAndExit(context);
        },
        onSkip: () {
          Navigator.pop(sheetCtx);
          _saveAndExit(context);
        },
      ),
    );
  }

  Future<void> _saveAndExit(BuildContext context) async {
    // Capture router & refs BEFORE the async gap so they stay valid even
    // after finishWorkout() resets the workout state and the widget rebuilds.
    final router = GoRouter.of(context);
    final notifier = ref.read(workoutProvider.notifier);
    final homeRefresh = ref.read(homeRefreshProvider.notifier);
    final programsNotifier = ref.read(programsProvider.notifier);
    final achievementsNotifier = ref.read(achievementsProvider.notifier);

    final session = await notifier.finishWorkout();

    // Refresh home stats and program state (so next-day index is visible immediately).
    homeRefresh.refresh();
    programsNotifier.refresh();

    // Check achievements.
    if (session != null) {
      final newAchievements =
          await achievementsNotifier.checkAfterWorkout(session);
      for (final achievement in newAchievements) {
        if (!context.mounted) break;
        await AchievementOverlay.show(context, achievement);
      }
    }

    if (session != null) {
      router.pushReplacement('/share-workout', extra: session);
    } else {
      router.go('/home');
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Workout?'),
        content: const Text('All progress will be lost. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Going')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Workout',
                style: TextStyle(color: primaryRed)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      ref.read(workoutProvider.notifier).cancelWorkout();
      context.go('/workout');
    }
  }

  void _showTimeAdjustDialog(BuildContext context) {
    final session = ref.read(workoutProvider).session;
    if (session == null) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final start = ref.read(workoutProvider).session?.startTime ?? DateTime.now();
          return AlertDialog(
            title: const Text('Adjust Start Time'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Started at: ${DateFormat('h:mm a').format(start)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(workoutProvider.notifier).adjustStartTime(
                                start.subtract(const Duration(minutes: 5)));
                          setDialogState(() {});
                        },
                        child: const Text('−5 min'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final newStart =
                              start.add(const Duration(minutes: 5));
                          if (newStart.isBefore(DateTime.now())) {
                            ref
                                .read(workoutProvider.notifier)
                                .adjustStartTime(newStart);
                            setDialogState(() {});
                          }
                        },
                        child: const Text('+5 min'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(start),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      final newStart = DateTime(
                          now.year, now.month, now.day, picked.hour, picked.minute);
                      if (newStart.isBefore(now)) {
                        ref
                            .read(workoutProvider.notifier)
                            .adjustStartTime(newStart);
                        setDialogState(() {});
                      }
                    }
                  },
                  child: const Text('Set Custom Time'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
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
            child: const Text('Skip',
                style: TextStyle(color: Color(0xFF8899AA))),
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
                      const Icon(Icons.local_fire_department_rounded,
                          color: primaryRed),
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
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
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

class _WarmupRow extends StatefulWidget {
  final WarmupExercise warmup;
  const _WarmupRow({required this.warmup});

  @override
  State<_WarmupRow> createState() => _WarmupRowState();
}

class _WarmupRowState extends State<_WarmupRow> {
  String? _gifUrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _tryLoadGif();
  }

  Future<void> _tryLoadGif() async {
    final exercise =
        await ExerciseRepository().getByExactName(widget.warmup.name);
    if (exercise != null && exercise.gifUrl.isNotEmpty && mounted) {
      setState(() => _gifUrl = exercise.gifUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInstructions = widget.warmup.instructions.isNotEmpty;
    return GestureDetector(
      onTap:
          hasInstructions ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _gifUrl != null
                        ? _gifUrl!.startsWith('assets/')
                            ? Image.asset(_gifUrl!,
                                width: 52, height: 52, fit: BoxFit.cover)
                            : kIsWeb
                                ? Image.network(_gifUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _iconBox())
                                : CachedNetworkImage(
                                    imageUrl: _gifUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _iconBox())
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
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: steelBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.warmup.durationLabel,
                      style: const TextStyle(
                          color: steelBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                  if (hasInstructions) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF8899AA),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
            if (_expanded && hasInstructions)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: steelBlue.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: steelBlue.withAlpha(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt_rounded,
                            size: 14, color: steelBlue),
                        const SizedBox(width: 6),
                        Text(
                          'How to do it',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  color: steelBlue,
                                  fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.warmup.instructions.asMap().entries.map((e) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin:
                                    const EdgeInsets.only(top: 1, right: 8),
                                decoration: const BoxDecoration(
                                  color: steelBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                              Expanded(
                                child: Text(e.value,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 13, height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
          ],
        ),
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
              const Icon(Icons.self_improvement_rounded,
                  color: tealSuccess, size: 24),
              const SizedBox(width: 10),
              Text('Cool-Down',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: const Text('Skip',
                    style: TextStyle(color: Color(0xFF8899AA))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Great workout! Take 5 minutes to recover.',
              style: Theme.of(context).textTheme.bodySmall),
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
                Text(cooldown.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(cooldown.description,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            cooldown.durationLabel,
            style: const TextStyle(
                color: tealSuccess,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Current Exercise Card ────────────────────────────────────────────────────

class _CurrentExerciseCard extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  final int exerciseIndex;
  final int totalExercises;
  final VoidCallback onSkip;

  const _CurrentExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.onSkip,
  });

  @override
  ConsumerState<_CurrentExerciseCard> createState() =>
      _CurrentExerciseCardState();
}

class _CurrentExerciseCardState extends ConsumerState<_CurrentExerciseCard> {
  bool _showInstructions = false;

  void _showExerciseHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ExerciseHistorySheet(exerciseName: widget.exercise.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final hasContent =
        ex.instructions.isNotEmpty || ex.targetMuscles.isNotEmpty;

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
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise ${widget.exerciseIndex + 1}/${widget.totalExercises}',
                style: const TextStyle(color: lightSteel, fontSize: 12),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showExerciseHistory(context),
                    icon: const Icon(Icons.history_rounded,
                        color: lightSteel, size: 20),
                    tooltip: 'Previous weights',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  if (widget.exerciseIndex > 0)
                    IconButton(
                      onPressed: () =>
                          ref.read(workoutProvider.notifier).previousExercise(),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: lightSteel, size: 18),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  if (widget.exerciseIndex < widget.totalExercises - 1)
                    IconButton(
                      onPressed: () =>
                          ref.read(workoutProvider.notifier).nextExercise(),
                      icon: const Icon(Icons.arrow_forward_ios_rounded,
                          color: lightSteel, size: 18),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  // Skip — compact icon
                  IconButton(
                    onPressed: widget.onSkip,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: Color(0xFF8899AA), size: 18),
                    tooltip: 'Skip exercise',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (ex.gifUrl.isNotEmpty)
            AnimatedExerciseImage(
              imageUrls: ex.gifUrl.contains('/0.jpg')
                  ? [ex.gifUrl, ex.gifUrl.replaceFirst('/0.jpg', '/1.jpg')]
                  : [ex.gifUrl],
              height: 180,
              fit: BoxFit.contain,
              enableFullScreen: true,
              fullScreenTitle: ex.name,
            ),
          const SizedBox(height: 10),
          Text(
            ex.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ex.isCardio
                ? '${ex.sets} sets · Rest ${ex.restTime}'
                : '${ex.sets} sets × ${ex.repsFrom}–${ex.repsTo} reps · Rest ${ex.restTime}',
            style: const TextStyle(color: lightSteel, fontSize: 14),
          ),

          // Instructions toggle
          if (hasContent) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  setState(() => _showInstructions = !_showInstructions),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showInstructions
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: lightSteel,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showInstructions
                          ? 'Hide Instructions'
                          : 'View Instructions & Muscles',
                      style: const TextStyle(
                          color: lightSteel,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Expandable instructions panel
          if (_showInstructions && hasContent) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target muscles
                  if (ex.targetMuscles.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            size: 14, color: steelBlue),
                        const SizedBox(width: 6),
                        const Text('Targets: ',
                            style: TextStyle(
                                color: steelBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(
                            ex.targetMuscles.join(', '),
                            style: const TextStyle(
                                color: lightSteel, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (ex.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded,
                            size: 14, color: Color(0xFF8899AA)),
                        const SizedBox(width: 6),
                        const Text('Secondary: ',
                            style: TextStyle(
                                color: Color(0xFF8899AA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Text(
                            ex.secondaryMuscles.join(', '),
                            style: const TextStyle(
                                color: Color(0xFF8899AA), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (ex.instructions.isNotEmpty) ...[
                    const Divider(color: Colors.white12, height: 20),
                    const Text(
                      'How to perform:',
                      style: TextStyle(
                          color: lightSteel,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...ex.instructions.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(top: 1, right: 8),
                                decoration: const BoxDecoration(
                                    color: steelBlue, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${entry.key + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                      color: lightSteel,
                                      fontSize: 12,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Exercise History Sheet ────────────────────────────────────────────────────

class _ExerciseHistorySheet extends StatefulWidget {
  final String exerciseName;
  const _ExerciseHistorySheet({required this.exerciseName});

  @override
  State<_ExerciseHistorySheet> createState() => _ExerciseHistorySheetState();
}

class _ExerciseHistorySheetState extends State<_ExerciseHistorySheet> {
  List<({DateTime date, List<dynamic> sets})> _history = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final history = SessionRepository.instance
        .getExerciseHistory(widget.exerciseName, limit: 10);
    setState(() {
      _history = history;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 28),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.activeDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Previous Weights',
                        style: Theme.of(context).textTheme.headlineMedium),
                    Text(widget.exerciseName,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_loaded)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_rounded,
                      size: 40,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(height: 8),
                  Text('No history yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Your logged sets will appear here after your first session.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            ...(_history.map((entry) {
              final dateLabel = DateFormat('d MMM yyyy').format(entry.date);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context).dividerColor.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: AppColors.activeDark,
                                fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: entry.sets.asMap().entries.map((e) {
                        final s = e.value;
                        final failStr = s.toFailure ? ' F' : '';
                        final summary = s.isCardio
                            ? s.formatSummary()
                            : '${s.formatSummary()}$failStr';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.activeDark.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'S${e.key + 1}: $summary',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerWidget {
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

  void _openEdit(BuildContext context, WidgetRef ref, LoggedSetModel s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSetSheet(
        setNumber: setNumber,
        existing: s,
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
      ),
    );
  }

  void _openLog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    ref.read(workoutProvider.notifier).setCurrentExercise(exerciseIndex);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogSetSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool exerciseIsCardio = exercise.isCardio == true;
    String setInfo = exerciseIsCardio
        ? 'Duration · Distance'
        : '${exercise.repsFrom}–${exercise.repsTo} reps';
    bool isBodyweight = false;
    bool toFailure = false;
    bool isUnilateral = false;
    LoggedSetModel? loggedSet;

    if (isCompleted && session != null) {
      try {
        final loggedEx = session.exercises[exerciseIndex];
        if (setIndex < loggedEx.sets.length) {
          final s = loggedEx.sets[setIndex];
          loggedSet = s;
          isBodyweight = s.isBodyweight;
          toFailure = s.toFailure;
          isUnilateral = s.isUnilateral;
          if (s.isCardio) {
            setInfo = s.formatSummary();
          } else {
            String wStr;
            if (isBodyweight) {
              wStr = 'BW';
            } else if (isUnilateral && s.weightRight != null) {
              final l = s.weight == s.weight.floorToDouble()
                  ? '${s.weight.toInt()}'
                  : s.weight.toStringAsFixed(1);
              final r = s.weightRight! == s.weightRight!.floorToDouble()
                  ? '${s.weightRight!.toInt()}'
                  : s.weightRight!.toStringAsFixed(1);
              wStr = 'L:${l}kg R:${r}kg';
            } else {
              final w = s.weight == s.weight.floorToDouble()
                  ? '${s.weight.toInt()}kg'
                  : '${s.weight.toStringAsFixed(1)}kg';
              wStr = isUnilateral ? '$w/side' : w;
            }
            setInfo = '$wStr × ${s.reps} reps${toFailure ? ' (max)' : ''}';
          }
        }
      } catch (_) {}
    }

    final row = Container(
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
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tealSuccess.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tealSuccess.withAlpha(80)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✓',
                      style: TextStyle(color: tealSuccess, fontSize: 12)),
                  SizedBox(width: 4),
                  Text('Edit',
                      style: TextStyle(
                          color: tealSuccess,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? primaryRed
                    : Theme.of(context).dividerColor.withAlpha(80),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? '→' : '–',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
    );

    if (isCompleted && loggedSet != null) {
      final s = loggedSet;
      return GestureDetector(
        onTap: () => _openEdit(context, ref, s),
        child: row,
      );
    }
    if (isActive) {
      return GestureDetector(
        onTap: () => _openLog(context, ref),
        child: row,
      );
    }
    return row;
  }
}

// ─── Edit Set Sheet ────────────────────────────────────────────────────────────

class _EditSetSheet extends ConsumerStatefulWidget {
  final int setNumber;
  final LoggedSetModel existing;
  final int exerciseIndex;
  final int setIndex;

  const _EditSetSheet({
    required this.setNumber,
    required this.existing,
    required this.exerciseIndex,
    required this.setIndex,
  });

  @override
  ConsumerState<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends ConsumerState<_EditSetSheet> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final TextEditingController _notesController;
  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;
  late bool _toFailure;
  late bool _isBodyweight;
  late bool _isUnilateral;
  late bool _isCardio;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _isCardio = s.isCardio;
    _weightController = TextEditingController(
        text: s.isBodyweight
            ? ''
            : (s.weight == s.weight.floorToDouble()
                ? s.weight.toInt().toString()
                : s.weight.toStringAsFixed(1)));
    _repsController = TextEditingController(text: '${s.reps}');
    _notesController = TextEditingController(text: s.notes ?? '');
    final mins = (s.durationSeconds ?? 0) / 60;
    _durationController = TextEditingController(
        text: s.durationSeconds == null
            ? ''
            : (mins == mins.floorToDouble()
                ? mins.toInt().toString()
                : mins.toStringAsFixed(1)));
    final dist = s.distanceKm;
    _distanceController = TextEditingController(
        text: dist == null
            ? ''
            : (dist == dist.floorToDouble()
                ? dist.toInt().toString()
                : dist.toString()));
    _toFailure = s.toFailure;
    _isBodyweight = s.isBodyweight;
    _isUnilateral = s.isUnilateral;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_isCardio) {
      final minutes = double.tryParse(_durationController.text) ?? 0;
      if (minutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid duration')),
        );
        return;
      }
      final distance = double.tryParse(_distanceController.text);
      ref.read(workoutProvider.notifier).editSet(
            exerciseIndex: widget.exerciseIndex,
            setIndex: widget.setIndex,
            weight: 0,
            reps: 0,
            notes:
                _notesController.text.isNotEmpty ? _notesController.text : null,
            durationSeconds: (minutes * 60).round(),
            distanceKm: (distance != null && distance > 0) ? distance : null,
          );
      Navigator.of(context).pop();
      return;
    }
    final reps = int.tryParse(_repsController.text) ?? widget.existing.reps;
    final weight = _isBodyweight
        ? 0.0
        : (double.tryParse(_weightController.text) ?? widget.existing.weight);
    if (!_isBodyweight && weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }
    ref.read(workoutProvider.notifier).editSet(
          exerciseIndex: widget.exerciseIndex,
          setIndex: widget.setIndex,
          weight: weight,
          reps: reps,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          toFailure: _toFailure,
          isBodyweight: _isBodyweight,
          isUnilateral: _isUnilateral,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: borderLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Edit Set ${widget.setNumber}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (_isCardio) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                            suffixText: 'min',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Distance (optional)',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _distanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                            suffixText: 'km',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reps',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)),
                    ),
                  ],
                ),
              ),
              if (!_isBodyweight) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                            suffixText: 'kg',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              _chip(
                label: 'Bodyweight',
                active: _isBodyweight,
                activeColor: steelBlue,
                icon: Icons.accessibility_new_rounded,
                onTap: () => setState(() => _isBodyweight = !_isBodyweight),
              ),
              _chip(
                label: 'To Failure',
                active: _toFailure,
                activeColor: primaryRed,
                icon: Icons.local_fire_department_rounded,
                onTap: () => setState(() => _toFailure = !_toFailure),
              ),
              _chip(
                label: 'Each Side',
                active: _isUnilateral,
                activeColor: tealSuccess,
                icon: Icons.swap_horiz_rounded,
                onTap: () => setState(() => _isUnilateral = !_isUnilateral),
              ),
            ],
          ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required Color activeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withAlpha(25) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? activeColor
                  : Theme.of(context).dividerColor.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? activeColor : Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? activeColor : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ─── PR Overlay Banner (center screen) ───────────────────────────────────────

class _PrOverlayBanner extends StatefulWidget {
  final String exerciseName;
  final VoidCallback onDone;

  const _PrOverlayBanner({required this.exerciseName, required this.onDone});

  @override
  State<_PrOverlayBanner> createState() => _PrOverlayBannerState();
}

class _PrOverlayBannerState extends State<_PrOverlayBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDone());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.success.withAlpha(120), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withAlpha(50),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      const Text(
                        'New Personal Record!',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.exerciseName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Superset label helper ────────────────────────────────────────────────────

// Returns a list parallel to `exercises`. For exercises that belong to a
// superset group of 2+ adjacent exercises, the value is e.g. "A1", "A2",
// "B1"... For standalone or single-member groups, the value is null.
List<String?> _computeSupersetLabels(List<ExerciseModel> exercises) {
  final out = List<String?>.filled(exercises.length, null);
  int letterIdx = 0;
  int i = 0;
  while (i < exercises.length) {
    final groupId = exercises[i].supersetGroupId;
    if (groupId == null) {
      i++;
      continue;
    }
    // Find the contiguous run of same groupId.
    int j = i;
    while (j < exercises.length && exercises[j].supersetGroupId == groupId) {
      j++;
    }
    final runLen = j - i;
    if (runLen >= 2) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + letterIdx);
      for (int k = 0; k < runLen; k++) {
        out[i + k] = '$letter${k + 1}';
      }
      letterIdx++;
    }
    i = j;
  }
  return out;
}

// ─── Exercise Summary Card (shown in the main exercise list) ──────────────────

class _ExerciseSummaryCard extends StatelessWidget {
  final ExerciseModel exercise;
  final int exerciseIndex;
  final bool isCurrent;
  final int completedSets;
  final int targetSets;
  final VoidCallback onTap;
  final String? supersetLabel;
  final bool supersetContinuesAbove;
  final bool supersetContinuesBelow;

  const _ExerciseSummaryCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.isCurrent,
    required this.completedSets,
    required this.targetSets,
    required this.onTap,
    this.supersetLabel,
    this.supersetContinuesAbove = false,
    this.supersetContinuesBelow = false,
  });

  bool get _isComplete => completedSets >= targetSets && targetSets > 0;

  bool get _isDropset => exercise.technique == 'drop_sets';

  @override
  Widget build(BuildContext context) {
    final isInSuperset = supersetLabel != null;
    final card = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
            bottom: supersetContinuesBelow ? 2 : 10,
            left: isInSuperset ? 6 : 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isComplete
              ? tealSuccess.withAlpha(15)
              : isCurrent
                  ? primaryRed.withAlpha(10)
                  : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isComplete
                ? tealSuccess.withAlpha(80)
                : isCurrent
                    ? primaryRed
                    : Theme.of(context).dividerColor.withAlpha(60),
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Exercise number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _isComplete
                    ? tealSuccess
                    : isCurrent
                        ? primaryRed
                        : Theme.of(context).dividerColor.withAlpha(60),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isComplete
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 16)
                    : Text(
                        '${exerciseIndex + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // GIF thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: ExerciseGifWidget(
                  gifUrl: exercise.gifUrl,
                  exerciseName: exercise.name,
                  width: 52,
                  height: 52,
                  borderRadius: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + target
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isInSuperset) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: steelBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(supersetLabel!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (_isDropset) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('DROP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.sets} sets × ${exercise.repsFrom}–${exercise.repsTo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isComplete ? tealSuccess : const Color(0xFF8899AA),
                    ),
                  ),
                ],
              ),
            ),
            // Progress pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isComplete
                    ? tealSuccess
                    : isCurrent
                        ? primaryRed
                        : Theme.of(context).dividerColor.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedSets/$targetSets',
                style: TextStyle(
                  color: (isCurrent || _isComplete)
                      ? Colors.white
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!isInSuperset) return card;

    // Wrap with: optional SUPERSET group header + left-edge colored bar.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!supersetContinuesAbove)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: steelBlue.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: steelBlue.withAlpha(80)),
            ),
            child: const Text('SUPERSET',
                style: TextStyle(
                    fontSize: 10,
                    color: steelBlue,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                margin: EdgeInsets.only(
                    top: supersetContinuesAbove ? 0 : 4,
                    bottom: supersetContinuesBelow ? 0 : 10),
                decoration: BoxDecoration(
                  color: steelBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: card),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Exercise Detail Sheet (popup with GIF, sets, history) ───────────────────

class _ExerciseDetailSheet extends ConsumerStatefulWidget {
  final int exerciseIndex;
  const _ExerciseDetailSheet({required this.exerciseIndex});

  @override
  ConsumerState<_ExerciseDetailSheet> createState() =>
      _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<_ExerciseDetailSheet> {
  bool _showInstructions = false;

  void _openHistory(BuildContext context, String exerciseName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseHistorySheet(exerciseName: exerciseName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);
    final exercises = state.currentDay?.exercises ?? [];
    if (widget.exerciseIndex >= exercises.length) {
      return const SizedBox.shrink();
    }
    final ex = exercises[widget.exerciseIndex];
    final notifier = ref.read(workoutProvider.notifier);
    final completedSets = notifier.completedSetsForExercise(widget.exerciseIndex);
    final targetSets = notifier.targetSetsForExercise(widget.exerciseIndex);
    final displayCount = completedSets > targetSets ? completedSets : targetSets;
    final hasContent = ex.instructions.isNotEmpty || ex.targetMuscles.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (sheetContext, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // ── Handle ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // ── Header: name + history ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${ex.sets} sets × ${ex.repsFrom}–${ex.repsTo} reps · Rest ${ex.restTime}',
                              style: const TextStyle(
                                  color: lightSteel, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history_rounded,
                            color: lightSteel, size: 22),
                        onPressed: () => _openHistory(context, ex.name),
                        tooltip: 'Previous weights',
                      ),
                    ],
                  ),
                ),
              ),
              // ── PR hint ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _PRHintBanner(exerciseName: ex.name),
              ),
              // ── GIF ──────────────────────────────────────────────────────────
              if (ex.gifUrl.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedExerciseImage(
                        imageUrls: ex.gifUrl.contains('/0.jpg')
                            ? [
                                ex.gifUrl,
                                ex.gifUrl.replaceFirst('/0.jpg', '/1.jpg')
                              ]
                            : [ex.gifUrl],
                        height: 160,
                        fit: BoxFit.contain,
                        enableFullScreen: true,
                        fullScreenTitle: ex.name,
                      ),
                    ),
                  ),
                ),
              // ── Instructions toggle ──────────────────────────────────────────
              if (hasContent)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: GestureDetector(
                      onTap: () => setState(
                          () => _showInstructions = !_showInstructions),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _showInstructions
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: lightSteel,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showInstructions
                                  ? 'Hide Instructions'
                                  : 'View Instructions & Muscles',
                              style: const TextStyle(
                                  color: lightSteel,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_showInstructions && hasContent)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ex.targetMuscles.isNotEmpty)
                            Text(
                              'Targets: ${ex.targetMuscles.join(', ')}',
                              style: const TextStyle(
                                  color: steelBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          if (ex.instructions.isNotEmpty) ...[
                            const Divider(color: Colors.white12, height: 16),
                            ...ex.instructions.asMap().entries.map((e) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(
                                            top: 1, right: 8),
                                        decoration: const BoxDecoration(
                                          color: steelBlue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('${e.key + 1}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(e.value,
                                            style: const TextStyle(
                                                color: lightSteel,
                                                fontSize: 12,
                                                height: 1.4)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              // ── Sets header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Text('Sets',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                            color: primaryRed),
                        onPressed: () {
                          final done = notifier.completedSetsForExercise(
                              widget.exerciseIndex);
                          if (done > 0) {
                            notifier.removeLastSet(widget.exerciseIndex);
                          } else {
                            notifier.removeTargetSet(widget.exerciseIndex);
                          }
                        },
                        tooltip: 'Remove set',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 20, color: tealSuccess),
                        onPressed: () =>
                            notifier.addTargetSet(widget.exerciseIndex),
                        tooltip: 'Add set',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Set rows ─────────────────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final isCompleted = index < completedSets;
                    final isActive = index == completedSets;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: _SetRow(
                        setNumber: index + 1,
                        isCompleted: isCompleted,
                        isActive: isActive,
                        session: state.session,
                        exerciseIndex: widget.exerciseIndex,
                        setIndex: index,
                        exercise: ex,
                      ),
                    );
                  },
                  childCount: displayCount,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ─── PR Hint Banner ───────────────────────────────────────────────────────────

class _PRHintBanner extends ConsumerWidget {
  final String exerciseName;
  const _PRHintBanner({required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicalMax = historicalMaxForExercise(exerciseName);
    if (historicalMax <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.success, size: 16),
            const SizedBox(width: 8),
            Text(
              'PR: ${historicalMax.toStringAsFixed(1)} kg — beat it to set a new record!',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final VoidCallback onFinish;

  const _BottomActions({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
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
      child: ElevatedButton.icon(
        onPressed: onFinish,
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: const Text('Finish Workout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: tealSuccess,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
