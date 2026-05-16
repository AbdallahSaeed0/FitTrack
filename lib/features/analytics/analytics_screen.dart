import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_generator.dart';
import '../analytics/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liftData = ref.watch(analyticsProvider);
    final weeklyCounts = ref.watch(weeklySessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _exportPdf(context, ref),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('Export'),
              style: TextButton.styleFrom(foregroundColor: primaryRed),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Lift Progress', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Last 12 weeks', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ...liftData.where((d) => d.history.isNotEmpty).map((data) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _LiftChart(data: data),
            );
          }),
          if (liftData.every((d) => d.history.isEmpty))
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withAlpha(60)),
              ),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(height: 12),
                  Text('No data yet', style: Theme.of(context).textTheme.titleMedium),
                  Text('Complete workouts to see progress charts', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text('Top Lifts This Month', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...liftData.map((data) => _TopLiftRow(data: data)),
          const SizedBox(height: 16),
          Text('Sessions Per Week', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _WeeklyBarChart(weeklyCounts: weeklyCounts),
        ],
      ),
    );
  }

  void _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final sessions = ref.read(allSessionsProvider);
      final liftData = ref.read(analyticsProvider);
      await PdfGenerator.generate(sessions: sessions, liftData: liftData);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }
}

class _LiftChart extends StatelessWidget {
  final LiftData data;

  const _LiftChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final minY = data.history.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxY = data.history.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.exerciseName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${data.currentMax.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: tealSuccess),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minY: (minY - 5).clamp(0, double.infinity),
                  maxY: maxY + 5,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: borderLight,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF8899AA)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: tealSuccess,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 3,
                          color: tealSuccess,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: tealSuccess.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopLiftRow extends StatelessWidget {
  final LiftData data;

  const _TopLiftRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final trend = data.trend;
    final trendStr = trend > 0 ? '↑ +${trend.toStringAsFixed(1)}kg' : trend < 0 ? '↓ ${trend.toStringAsFixed(1)}kg' : '→ Same';
    final trendColor = trend > 0 ? tealSuccess : trend < 0 ? primaryRed : const Color(0xFF8899AA);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(data.exerciseName, style: Theme.of(context).textTheme.titleMedium),
            ),
            if (data.currentMax > 0) ...[
              Text(
                '${data.currentMax.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(width: 12),
              Text(trendStr, style: TextStyle(color: trendColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ] else
              const Text('No data', style: TextStyle(color: Color(0xFF8899AA))),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final Map<int, int> weeklyCounts;

  const _WeeklyBarChart({required this.weeklyCounts});

  @override
  Widget build(BuildContext context) {
    if (weeklyCounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text('No session data yet', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    final maxCount = weeklyCounts.values.reduce((a, b) => a > b ? a : b).toDouble();
    final groups = List.generate(12, (i) {
      final count = weeklyCounts[i] ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: i == 0 ? primaryRed : steelBlue,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: (maxCount + 1).clamp(4, double.infinity),
              barGroups: groups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: borderLight, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final weeksAgo = v.toInt();
                      return Text(
                        weeksAgo == 0 ? 'Now' : '-${weeksAgo}w',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8899AA)),
                      );
                    },
                    reservedSize: 20,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8899AA)),
                    ),
                    interval: 1,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
