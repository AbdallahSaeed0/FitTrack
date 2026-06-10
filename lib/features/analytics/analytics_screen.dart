import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/muscle_analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/muscle_groups.dart';
import '../../data/models/muscle_intensity_model.dart';
import '../../shared/widgets/muscle_heat_map.dart';
import '../analytics/analytics_provider.dart';
import '../history/history_provider.dart';
import '../home/home_provider.dart';
import '../history/history_screen.dart';
import 'premium_analytics_screen.dart';
import 'widgets/workout_calendar.dart';

enum _HeatMapPeriod { week, month, year }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _HeatMapPeriod _period = _HeatMapPeriod.week;
  List<MuscleIntensity>? _intensities;
  bool _heatMapLoading = true;

  final _muscleService = const MuscleAnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHeatMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHeatMap() async {
    setState(() => _heatMapLoading = true);
    final List<MuscleIntensity> data;
    switch (_period) {
      case _HeatMapPeriod.week:
        data = _muscleService.getThisWeek();
        break;
      case _HeatMapPeriod.month:
        data = _muscleService.getThisMonth();
        break;
      case _HeatMapPeriod.year:
        data = _muscleService.getThisYear();
        break;
    }
    if (mounted) {
      setState(() {
        _intensities = data;
        _heatMapLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'History'),
            Tab(text: 'PRs'),
            Tab(text: '⭐ Premium'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(homeRefreshProvider.notifier).refresh();
          setState(() {});
        },
        color: AppColors.primary,
        child: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTab(
            period: _period,
            intensities: _intensities,
            heatMapLoading: _heatMapLoading,
            onPeriodChanged: (p) {
              setState(() => _period = p);
              _loadHeatMap();
            },
          ),
          const HistoryScreen(),
          const _PRsTab(),
          const PremiumAnalyticsScreen(),
        ],
        ),
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
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: primaryRed),
        );
      }
    }
  }
}

// ── Dashboard tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  final _HeatMapPeriod period;
  final List<MuscleIntensity>? intensities;
  final bool heatMapLoading;
  final void Function(_HeatMapPeriod) onPeriodChanged;

  const _DashboardTab({
    required this.period,
    required this.intensities,
    required this.heatMapLoading,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liftData = ref.watch(analyticsProvider);
    final weeklyCounts = ref.watch(weeklySessionsProvider);
    final sessionsByDate = ref.watch(sessionsByDateProvider);
    final prDates = ref.watch(prDatesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Workout Calendar ───────────────────────────────────────────────
        WorkoutCalendar(
          sessionsByDate: sessionsByDate,
          prDates: prDates,
        ),
        const SizedBox(height: 16),

        // ── Summary cards ──────────────────────────────────────────────────
        _SummaryCards(),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // ── Muscle Heat Map ────────────────────────────────────────────────
        Text('Muscle Activity',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Muscles worked this period',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            _PeriodChip(
              label: 'This Week',
              selected: period == _HeatMapPeriod.week,
              onTap: () => onPeriodChanged(_HeatMapPeriod.week),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'This Month',
              selected: period == _HeatMapPeriod.month,
              onTap: () => onPeriodChanged(_HeatMapPeriod.month),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: 'This Year',
              selected: period == _HeatMapPeriod.year,
              onTap: () => onPeriodChanged(_HeatMapPeriod.year),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (heatMapLoading)
          const SizedBox(
              height: 200,
              child: Center(
                  child:
                      CircularProgressIndicator(color: tealSuccess)))
        else if (intensities != null) ...[
          MuscleHeatMap(intensities: intensities!),
          const SizedBox(height: 16),
          _IntensityLegend(),
          const SizedBox(height: 16),
          ...(intensities!
                  .where((i) => i.workoutCount > 0)
                  .toList()
                ..sort((a, b) => b.workoutCount.compareTo(a.workoutCount)))
              .take(8)
              .map<Widget>((i) => _MuscleRow(intensity: i)),
        ],

        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // ── Lift Progress ──────────────────────────────────────────────────
        Text('Lift Progress',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Last 12 weeks',
            style: Theme.of(context).textTheme.bodySmall),
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
              border: Border.all(
                  color: Theme.of(context).dividerColor.withAlpha(60)),
            ),
            child: Column(
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 48,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(height: 12),
                Text('No data yet',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Complete workouts to see progress charts',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),

        const SizedBox(height: 16),
        Text('Sessions Per Week',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _WeeklyBarChart(weeklyCounts: weeklyCounts),
      ],
    );
  }
}

// ── Summary cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends ConsumerState<_SummaryCards> {
  AnalyticsPeriod _period = AnalyticsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(analyticsSummaryProvider(_period));

    String periodLabel;
    switch (_period) {
      case AnalyticsPeriod.week:
        periodLabel = 'This Week';
        break;
      case AnalyticsPeriod.month:
        periodLabel = 'This Month';
        break;
      case AnalyticsPeriod.allTime:
        periodLabel = 'All Time';
        break;
    }

    final vol = summary.totalVolume;
    final volStr = vol >= 1000000
        ? '${(vol / 1000000).toStringAsFixed(1)}M'
        : vol >= 1000
            ? '${(vol / 1000).toStringAsFixed(0)}k'
            : vol.toStringAsFixed(0);
    final avgStr = summary.avgDurationMinutes == 0
        ? '–'
        : '${summary.avgDurationMinutes.toInt()}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(periodLabel,
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            // Period toggle
            ...AnalyticsPeriod.values.map((p) {
              final labels = {
                AnalyticsPeriod.week: 'W',
                AnalyticsPeriod.month: 'M',
                AnalyticsPeriod.allTime: 'All',
              };
              final active = _period == p;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _period = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      labels[p]!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryCard(
              label: 'Workouts',
              value: '${summary.totalWorkouts}',
              icon: Icons.fitness_center_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _SummaryCard(
              label: 'Volume',
              value: '${volStr}kg',
              icon: Icons.bar_chart_rounded,
              color: tealSuccess,
            ),
            const SizedBox(width: 8),
            _SummaryCard(
              label: 'Avg Time',
              value: avgStr,
              icon: Icons.timer_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            _SummaryCard(
              label: 'Streak',
              value: '${summary.streak}w',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── PRs tab ───────────────────────────────────────────────────────────────────

class _PRsTab extends ConsumerWidget {
  const _PRsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prs = ref.watch(personalRecordsProvider);

    if (prs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded,
                size: 56,
                color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text('No records yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Complete workouts to set PRs',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: prs.length,
      itemBuilder: (context, i) =>
          _PRCard(pr: prs[i]).animate().fadeIn(delay: (i * 40).ms),
    );
  }
}

class _PRCard extends StatelessWidget {
  final PersonalRecord pr;
  const _PRCard({required this.pr});

  @override
  Widget build(BuildContext context) {
    final weightStr = pr.maxWeight == pr.maxWeight.floorToDouble()
        ? '${pr.maxWeight.toInt()} kg'
        : '${pr.maxWeight.toStringAsFixed(1)} kg';
    final date = DateFormat('MMM d, yyyy').format(pr.achievedAt);
    final vol = pr.maxSessionVolume;
    final volStr = vol >= 1000
        ? '${(vol / 1000).toStringAsFixed(1)}k kg'
        : '${vol.toStringAsFixed(0)} kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tealSuccess.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: tealSuccess, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pr.exerciseName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Achieved $date',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text('Best session: $volStr',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  weightStr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: tealSuccess),
                ),
                Text(
                  '× ${pr.maxRepsAtMaxWeight} reps',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period chip ───────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? primaryRed : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primaryRed
                : Theme.of(context).dividerColor.withAlpha(80),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

// ── Intensity legend ──────────────────────────────────────────────────────────

class _IntensityLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _LegendItem(color: Color(0xFFEF4444), label: 'Very High'),
          _LegendItem(color: Color(0xFFFB923C), label: 'High'),
          _LegendItem(color: Color(0xFFFBBF24), label: 'Medium'),
          _LegendItem(color: Color(0xFF60A5FA), label: 'Low'),
          _LegendItem(color: Color(0xFF94A3B8), label: 'None'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
  }
}

// ── Muscle row ────────────────────────────────────────────────────────────────

class _MuscleRow extends StatelessWidget {
  final MuscleIntensity intensity;
  const _MuscleRow({required this.intensity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: intensity.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(intensity.muscle.displayName,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${intensity.workoutCount} sets',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Lift chart ────────────────────────────────────────────────────────────────

class _LiftChart extends StatelessWidget {
  final LiftData data;
  const _LiftChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final minY =
        data.history.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxY =
        data.history.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.exerciseName,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${data.currentMax.toStringAsFixed(1)} kg',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tealSuccess),
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
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: borderLight, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF8899AA)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: tealSuccess,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
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
            child: Text('No session data yet',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    final maxCount =
        weeklyCounts.values.reduce((a, b) => a > b ? a : b).toDouble();
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
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: borderLight, strokeWidth: 1),
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
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF8899AA)),
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
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF8899AA)),
                    ),
                    interval: 1,
                  ),
                ),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
