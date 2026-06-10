import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(historyGroupedProvider);

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 56,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text('No workouts yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Complete a workout to see your history',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: groups.length,
      itemBuilder: (context, i) => _WeekSection(group: groups[i]),
    );
  }
}

class _WeekSection extends StatelessWidget {
  final WeekGroup group;
  const _WeekSection({required this.group});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekStart = DateTime(monday.year, monday.month, monday.day);
    final diff = thisWeekStart.difference(group.weekStart).inDays;

    final String label;
    if (diff == 0) {
      label = 'This Week';
    } else if (diff == 7) {
      label = 'Last Week';
    } else {
      label =
          '${DateFormat('MMM d').format(group.weekStart)} – ${DateFormat('MMM d').format(group.weekStart.add(const Duration(days: 6)))}';
    }

    final vol = group.totalVolume;
    final volStr = vol >= 1000
        ? '${(vol / 1000).toStringAsFixed(1)}k kg'
        : '${vol.toStringAsFixed(0)} kg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                '${group.sessionCount} sessions · $volStr',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ...group.sessions.map((s) => _SessionCard(summary: s)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionSummary summary;
  const _SessionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary.session;
    final date = DateFormat('EEE, MMM d').format(s.startTime);
    final time = DateFormat('h:mm a').format(s.startTime);
    final vol = summary.totalVolume;
    final volStr =
        vol >= 1000 ? '${(vol / 1000).toStringAsFixed(1)}k' : vol.toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/session/${s.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.dayName,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                ],
              ),
              const SizedBox(height: 2),
              Text('$date · $time',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(
                      icon: Icons.timer_outlined,
                      label: '${s.durationMinutes}m'),
                  const SizedBox(width: 16),
                  _Stat(
                      icon: Icons.fitness_center_rounded,
                      label: '${summary.exerciseCount} exercises'),
                  const SizedBox(width: 16),
                  _Stat(
                      icon: Icons.bar_chart_rounded,
                      label: '$volStr kg',
                      color: tealSuccess),
                ],
              ),
              if (s.exercises.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  s.exercises.map((e) => e.exerciseName).take(3).join(' · ') +
                      (s.exercises.length > 3
                          ? ' +${s.exercises.length - 3}'
                          : ''),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Stat({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).textTheme.bodySmall?.color;
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: c)),
      ],
    );
  }
}
