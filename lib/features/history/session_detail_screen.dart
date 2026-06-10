import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';
import 'history_provider.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  bool _showComparison = false;

  @override
  Widget build(BuildContext context) {
    final session = SessionRepository.instance.getById(widget.sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session')),
        body: const Center(child: Text('Session not found')),
      );
    }

    final prevSession =
        ref.watch(previousSessionProvider(widget.sessionId));

    final date =
        DateFormat('EEEE, MMMM d · h:mm a').format(session.startTime);

    double totalVol = 0;
    for (final ex in session.exercises) {
      for (final s in ex.sets) {
        totalVol += s.weight * s.reps;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.dayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share workout',
            onPressed: () => context.push('/share-workout', extra: session),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(date, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),

          // ── Header stats ─────────────────────────────────────────────────
          Row(
            children: [
              _HeaderStat(
                label: 'Duration',
                value: '${session.durationMinutes}m',
                icon: Icons.timer_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _HeaderStat(
                label: 'Volume',
                value: totalVol >= 1000
                    ? '${(totalVol / 1000).toStringAsFixed(1)}k kg'
                    : '${totalVol.toStringAsFixed(0)} kg',
                icon: Icons.bar_chart_rounded,
                color: tealSuccess,
              ),
              const SizedBox(width: 8),
              _HeaderStat(
                label: 'Exercises',
                value: '${session.exercises.length}',
                icon: Icons.fitness_center_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Compare button ───────────────────────────────────────────────
          if (prevSession != null)
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _showComparison = !_showComparison),
              icon: Icon(
                _showComparison
                    ? Icons.expand_less_rounded
                    : Icons.compare_arrows_rounded,
                size: 18,
              ),
              label: Text(_showComparison
                  ? 'Hide Comparison'
                  : 'Compare with Previous'),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text('First time doing this workout',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),

          if (_showComparison && prevSession != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'vs. ${DateFormat('MMM d, yyyy').format(prevSession.startTime)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Exercises ────────────────────────────────────────────────────
          ...session.exercises.asMap().entries.map((entry) {
            final ex = entry.value;
            final prevEx = _findPrevExercise(prevSession, ex.exerciseName);
            return _ExerciseCard(
              exercise: ex,
              prevExercise: _showComparison ? prevEx : null,
              onProgressTap: () => context.push(
                '/exercise-progress',
                extra: ex.exerciseName,
              ),
            ).animate().fadeIn(delay: (entry.key * 60).ms);
          }),
        ],
      ),
    );
  }

  LoggedExerciseModel? _findPrevExercise(
      WorkoutSessionModel? prev, String name) {
    if (prev == null) return null;
    try {
      return prev.exercises.firstWhere(
        (e) => e.exerciseName.toLowerCase().trim() == name.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final LoggedExerciseModel exercise;
  final LoggedExerciseModel? prevExercise;
  final VoidCallback onProgressTap;

  const _ExerciseCard({
    required this.exercise,
    required this.prevExercise,
    required this.onProgressTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasComparison = prevExercise != null;
    final isCardio =
        exercise.sets.isNotEmpty && exercise.sets.every((s) => s.isCardio);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!isCardio)
                  TextButton(
                    onPressed: onProgressTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Progress',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                        SizedBox(width: 2),
                        Icon(Icons.trending_up_rounded,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!isCardio) _SetTableHeader(showComparison: hasComparison),
            const Divider(height: 12),
            ...exercise.sets.asMap().entries.map((e) {
              final prevSet = (hasComparison &&
                      e.key < (prevExercise?.sets.length ?? 0))
                  ? prevExercise!.sets[e.key]
                  : null;
              return _SetRow(
                set: e.value,
                prevSet: prevSet,
                showComparison: hasComparison,
              ).animate().slideX(
                    begin: -0.1,
                    end: 0,
                    delay: (e.key * 40).ms,
                    curve: Curves.easeOut,
                  );
            }),
          ],
        ),
      ),
    );
  }
}

class _SetTableHeader extends StatelessWidget {
  final bool showComparison;
  const _SetTableHeader({required this.showComparison});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      children: [
        SizedBox(
            width: 32,
            child: Text('Set', style: style, textAlign: TextAlign.center)),
        const Spacer(),
        SizedBox(
            width: 88,
            child:
                Text('Weight', style: style, textAlign: TextAlign.center)),
        SizedBox(
            width: 52,
            child: Text('Reps', style: style, textAlign: TextAlign.center)),
        if (showComparison)
          SizedBox(
              width: 64,
              child:
                  Text('Δ Weight', style: style, textAlign: TextAlign.center)),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  final LoggedSetModel set;
  final LoggedSetModel? prevSet;
  final bool showComparison;

  const _SetRow({
    required this.set,
    required this.prevSet,
    required this.showComparison,
  });

  @override
  Widget build(BuildContext context) {
    if (set.isCardio) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text('${set.setNumber}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const Spacer(),
            Expanded(
              flex: 3,
              child: Text(set.formatSummary(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (showComparison) const SizedBox(width: 64),
          ],
        ),
      );
    }

    double? delta;
    Color? deltaColor;
    String deltaStr = '–';

    if (prevSet != null && !prevSet!.isCardio) {
      delta = set.weight - prevSet!.weight;
      deltaColor = delta > 0
          ? tealSuccess
          : delta < 0
              ? AppColors.error
              : Theme.of(context).textTheme.bodySmall?.color;
      deltaStr = delta == 0
          ? '='
          : delta > 0
              ? '+${delta.toStringAsFixed(1)}'
              : delta.toStringAsFixed(1);
    }

    final weightStr = set.weight == set.weight.floorToDouble()
        ? '${set.weight.toInt()} kg'
        : '${set.weight.toStringAsFixed(1)} kg';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${set.setNumber}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const Spacer(),
          SizedBox(
            width: 88,
            child: Text(weightStr,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 52,
            child: Text('× ${set.reps}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (showComparison)
            SizedBox(
              width: 64,
              child: Text(
                deltaStr,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: deltaColor),
              ),
            ),
        ],
      ),
    );
  }
}
