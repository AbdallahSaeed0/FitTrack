import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'history_provider.dart';

class ExerciseProgressionScreen extends ConsumerWidget {
  final String exerciseName;
  const ExerciseProgressionScreen({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progression = ref.watch(exerciseProgressionProvider(exerciseName));

    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: progression.history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 56,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(height: 16),
                  Text('No data yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Log some sets to see progress',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _PRBanner(allTimeMax: progression.allTimeMax),
                const SizedBox(height: 20),
                Text('Weight Progression',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _WeightLineChart(history: progression.history),
                const SizedBox(height: 20),
                Text('Volume Per Session',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _VolumeBarChart(history: progression.history),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Session History',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text('${progression.history.length} sessions',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                ...progression.history.reversed
                    .map((entry) => _HistoryEntry(
                          entry: entry,
                          allTimeMax: progression.allTimeMax,
                        )),
              ],
            ),
    );
  }
}

// ── PR Banner ─────────────────────────────────────────────────────────────────

class _PRBanner extends StatelessWidget {
  final double allTimeMax;
  const _PRBanner({required this.allTimeMax});

  @override
  Widget build(BuildContext context) {
    final weightStr = allTimeMax == allTimeMax.floorToDouble()
        ? '${allTimeMax.toInt()} kg'
        : '${allTimeMax.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tealSuccess.withAlpha(40), tealSuccess.withAlpha(10)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tealSuccess.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: tealSuccess, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Record',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tealSuccess.withAlpha(200)),
              ),
              Text(
                weightStr,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: tealSuccess),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Weight Line Chart ─────────────────────────────────────────────────────────

class _WeightLineChart extends StatelessWidget {
  final List<ExerciseProgressEntry> history;
  const _WeightLineChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Need 2+ sessions to show trend',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      );
    }

    final spots = history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.maxWeight))
        .toList();

    final weights = history.map((e) => e.maxWeight).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final padding = ((maxW - minW) * 0.2).clamp(5.0, 20.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: (minW - padding).clamp(0, double.infinity),
              maxY: maxW + padding,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: borderLight, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}kg',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8899AA)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= history.length) {
                        return const SizedBox.shrink();
                      }
                      if (idx != 0 && idx != history.length - 1) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('MMM d').format(history[idx].date),
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8899AA)),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: tealSuccess,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) {
                      final isPR = spot.y == maxW;
                      return FlDotCirclePainter(
                        radius: isPR ? 5 : 3,
                        color: tealSuccess,
                        strokeWidth: isPR ? 2 : 0,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: tealSuccess.withAlpha(25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Volume Bar Chart ──────────────────────────────────────────────────────────

class _VolumeBarChart extends StatelessWidget {
  final List<ExerciseProgressEntry> history;
  const _VolumeBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final display = history.length > 12
        ? history.sublist(history.length - 12)
        : history;
    final maxVol =
        display.map((e) => e.volume).reduce((a, b) => a > b ? a : b);

    final groups = display.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.volume,
            color: AppColors.primary,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 130,
          child: BarChart(
            BarChartData(
              maxY: maxVol * 1.25,
              barGroups: groups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: borderLight, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (v, _) {
                      final label = v >= 1000
                          ? '${(v / 1000).toStringAsFixed(0)}k'
                          : v.toInt().toString();
                      return Text(label,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8899AA)));
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Session history entry ─────────────────────────────────────────────────────

class _HistoryEntry extends StatelessWidget {
  final ExerciseProgressEntry entry;
  final double allTimeMax;
  const _HistoryEntry({required this.entry, required this.allTimeMax});

  @override
  Widget build(BuildContext context) {
    final bestSet =
        entry.sets.reduce((a, b) => a.weight > b.weight ? a : b);
    final isAllTimePR = bestSet.weight >= allTimeMax;
    final date = DateFormat('EEE, MMM d, yyyy').format(entry.date);
    final bestWeightStr = bestSet.weight == bestSet.weight.floorToDouble()
        ? '${bestSet.weight.toInt()}kg'
        : '${bestSet.weight.toStringAsFixed(1)}kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isAllTimePR) ...[
                  const Icon(Icons.emoji_events_rounded,
                      size: 14, color: tealSuccess),
                  const SizedBox(width: 4),
                ],
                Text(date, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAllTimePR
                        ? tealSuccess.withAlpha(25)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(6),
                    border: isAllTimePR
                        ? Border.all(color: tealSuccess.withAlpha(80))
                        : null,
                  ),
                  child: Text(
                    'Best: $bestWeightStr × ${bestSet.reps}',
                    style: TextStyle(
                        color: isAllTimePR
                            ? tealSuccess
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: entry.sets.map((s) {
                final wStr = s.weight == s.weight.floorToDouble()
                    ? '${s.weight.toInt()}'
                    : s.weight.toStringAsFixed(1);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(120),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context)
                            .dividerColor
                            .withAlpha(60)),
                  ),
                  child: Text(
                    '$wStr×${s.reps}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
