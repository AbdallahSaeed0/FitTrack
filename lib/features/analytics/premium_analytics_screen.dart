import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/session_repository.dart';
import '../../shared/providers/premium_provider.dart';
import '../history/history_provider.dart';
import '../home/home_provider.dart';

// ── Computed data models ───────────────────────────────────────────────────────

class _VolumePoint {
  final DateTime week;
  final double volume;
  const _VolumePoint(this.week, this.volume);
}

class _MuscleVolume {
  final String muscle;
  final double volume;
  const _MuscleVolume(this.muscle, this.volume);
}

class _RecoveryInfo {
  final String muscle;
  final int daysSinceLastTrained;
  final bool overtraining;
  const _RecoveryInfo(this.muscle, this.daysSinceLastTrained,
      {this.overtraining = false});
}

// ── Providers ──────────────────────────────────────────────────────────────────

final _volumeTimelineProvider = Provider<List<_VolumePoint>>((ref) {
  ref.watch(homeRefreshProvider);
  final sessions = SessionRepository.instance
      .getAll()
      .where((s) => s.completed)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Group by week
  final Map<DateTime, double> byWeek = {};
  for (final s in sessions) {
    final mon = s.startTime
        .subtract(Duration(days: s.startTime.weekday - 1));
    final weekStart =
        DateTime(mon.year, mon.month, mon.day);
    double vol = 0;
    for (final ex in s.exercises) {
      for (final set in ex.sets) {
        vol += set.weight * set.reps;
      }
    }
    byWeek[weekStart] = (byWeek[weekStart] ?? 0) + vol;
  }

  return byWeek.entries
      .map((e) => _VolumePoint(e.key, e.value))
      .toList()
    ..sort((a, b) => a.week.compareTo(b.week));
});

final _muscleVolumeProvider = Provider<List<_MuscleVolume>>((ref) {
  ref.watch(homeRefreshProvider);
  final sessions = SessionRepository.instance
      .getAll()
      .where((s) => s.completed);

  final Map<String, double> byMuscle = {};
  for (final s in sessions) {
    for (final ex in s.exercises) {
      double vol = 0;
      for (final set in ex.sets) {
        vol += set.weight * set.reps;
      }
      // Use targetMuscle from exercise if available, else guess from name
      final muscle = _guessMuscle(ex.exerciseName);
      byMuscle[muscle] = (byMuscle[muscle] ?? 0) + vol;
    }
  }

  return byMuscle.entries
      .map((e) => _MuscleVolume(e.key, e.value))
      .toList()
    ..sort((a, b) => b.volume.compareTo(a.volume));
});

final _recoveryProvider = Provider<List<_RecoveryInfo>>((ref) {
  ref.watch(homeRefreshProvider);
  final sessions = SessionRepository.instance
      .getAll()
      .where((s) => s.completed)
      .toList();
  final now = DateTime.now();

  final Map<String, DateTime> lastTrained = {};
  final Map<String, int> trainingDays = {};

  for (final s in sessions) {
    for (final ex in s.exercises) {
      final muscle = _guessMuscle(ex.exerciseName);
      final date = DateTime(
          s.startTime.year, s.startTime.month, s.startTime.day);
      final prev = lastTrained[muscle];
      if (prev == null || date.isAfter(prev)) {
        lastTrained[muscle] = date;
      }
      trainingDays[muscle] = (trainingDays[muscle] ?? 0) + 1;
    }
  }

  return lastTrained.entries.map((e) {
    final days = now.difference(e.value).inDays;
    final freq = trainingDays[e.key] ?? 0;
    final isOvertraining = freq > 3 && days < 2;
    return _RecoveryInfo(e.key, days, overtraining: isOvertraining);
  }).toList()
    ..sort((a, b) => a.daysSinceLastTrained.compareTo(b.daysSinceLastTrained));
});

String _guessMuscle(String exerciseName) {
  final lower = exerciseName.toLowerCase();
  if (lower.contains('squat') ||
      lower.contains('leg press') ||
      lower.contains('lunge') ||
      lower.contains('leg extension') ||
      lower.contains('quad')) { return 'Quads'; }
  if (lower.contains('deadlift') ||
      lower.contains('leg curl') ||
      lower.contains('hamstring') ||
      lower.contains('rdl') ||
      lower.contains('romanian')) { return 'Hamstrings'; }
  if (lower.contains('bench') ||
      lower.contains('chest') ||
      lower.contains('pec') ||
      lower.contains('fly') ||
      lower.contains('dip')) { return 'Chest'; }
  if (lower.contains('row') ||
      lower.contains('pull') ||
      lower.contains('lat') ||
      lower.contains('back')) { return 'Back'; }
  if (lower.contains('shoulder') ||
      lower.contains('overhead') ||
      lower.contains('ohp') ||
      lower.contains('lateral') ||
      lower.contains('delt') ||
      (lower.contains('press') && !lower.contains('bench'))) { return 'Shoulders'; }
  if (lower.contains('curl') ||
      lower.contains('bicep')) { return 'Biceps'; }
  if (lower.contains('tricep') ||
      lower.contains('pushdown') ||
      (lower.contains('extension') && !lower.contains('leg')) ||
      lower.contains('skull')) { return 'Triceps'; }
  if (lower.contains('calf') || lower.contains('calf raise')) { return 'Calves'; }
  if (lower.contains('core') ||
      lower.contains('plank') ||
      lower.contains('crunch') ||
      lower.contains('ab')) { return 'Core'; }
  return 'Other';
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class PremiumAnalyticsScreen extends ConsumerWidget {
  const PremiumAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider);

    if (!isPremium) {
      return _UpgradeGate(
        onUnlock: () => ref.read(premiumProvider.notifier).setPremium(true),
      );
    }

    return const _PremiumContent();
  }
}

// ── Upgrade gate ──────────────────────────────────────────────────────────────

class _UpgradeGate extends StatelessWidget {
  final VoidCallback onUnlock;
  const _UpgradeGate({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    const features = [
      '📊 Weekly & monthly volume charts',
      '🍕 Volume breakdown by muscle group',
      '🔥 Intensity & recovery insights',
      '📈 Training cycle comparison',
      '💡 Weak point identification',
      '📄 PDF analytics export',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.success],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.star_rounded,
                color: Colors.white, size: 44),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 20),
          const Text(
            'Unlock Premium Analytics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Deep insights to optimize your training and break plateaus.',
            style:
                TextStyle(fontSize: 14, color: Colors.white.withAlpha(160)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ...features.asMap().entries.map(
                (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Text(e.value,
                      style:
                          const TextStyle(fontSize: 15)),
                ],
              )
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 100 + e.key * 80),
                      duration: 400.ms)
                  .slideX(
                      begin: -0.1,
                      end: 0,
                      delay: Duration(milliseconds: 100 + e.key * 80),
                      duration: 400.ms,
                      curve: Curves.easeOut),
            ),
              ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Unlock Premium (Free Demo)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No payment required — this is a preview unlock.',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withAlpha(80)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Premium content ───────────────────────────────────────────────────────────

class _PremiumContent extends ConsumerStatefulWidget {
  const _PremiumContent();

  @override
  ConsumerState<_PremiumContent> createState() =>
      _PremiumContentState();
}

class _PremiumContentState extends ConsumerState<_PremiumContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Volume'),
              Tab(text: 'Recovery'),
              Tab(text: 'Trends'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _VolumeTab(),
              _RecoveryTab(),
              _TrendsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Volume tab ────────────────────────────────────────────────────────────────

class _VolumeTab extends ConsumerWidget {
  const _VolumeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(_volumeTimelineProvider);
    final byMuscle = ref.watch(_muscleVolumeProvider);

    if (timeline.isEmpty) {
      return const _NoData(message: 'Complete workouts to see volume analytics');
    }

    final last12 = timeline.length > 12
        ? timeline.sublist(timeline.length - 12)
        : timeline;
    final maxVol =
        last12.map((p) => p.volume).reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: 'Weekly Volume (last 12 weeks)'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVol * 1.2,
              barGroups: last12.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.volume,
                      color: AppColors.primaryBlue,
                      width: 16,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx >= last12.length) return const SizedBox.shrink();
                      final w = last12[idx].week;
                      return Text(
                        DateFormat('M/d').format(w),
                        style: const TextStyle(fontSize: 9),
                      );
                    },
                    reservedSize: 20,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (v, _) => Text(
                      v >= 1000
                          ? '${(v / 1000).toStringAsFixed(0)}k'
                          : v.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withAlpha(15),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Volume by Muscle Group'),
        const SizedBox(height: 12),
        _MuscleVolumeList(data: byMuscle.take(8).toList()),
      ],
    );
  }
}

class _MuscleVolumeList extends StatelessWidget {
  final List<_MuscleVolume> data;
  const _MuscleVolumeList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVol = data.first.volume;
    return Column(
      children: data.map((m) {
        final pct = maxVol > 0 ? m.volume / maxVol : 0.0;
        final volStr = m.volume >= 1000
            ? '${(m.volume / 1000).toStringAsFixed(1)}k'
            : m.volume.toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                  width: 90,
                  child: Text(m.muscle,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withAlpha(15),
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryBlue),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: Text(
                  '${volStr}kg',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(140)),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Recovery tab ──────────────────────────────────────────────────────────────

class _RecoveryTab extends ConsumerWidget {
  const _RecoveryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recovery = ref.watch(_recoveryProvider);

    if (recovery.isEmpty) {
      return const _NoData(
          message: 'Complete workouts to see recovery insights');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: 'Muscle Recovery Status'),
        const SizedBox(height: 4),
        Text(
          'Days since last trained per muscle group',
          style: TextStyle(
              fontSize: 13, color: Colors.white.withAlpha(140)),
        ),
        const SizedBox(height: 16),
        ...recovery.take(10).map((r) => _RecoveryCard(info: r)),
        const SizedBox(height: 16),
        _SectionTitle(title: 'Recovery Guide'),
        const SizedBox(height: 8),
        _RecoveryGuideCard(),
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final _RecoveryInfo info;
  const _RecoveryCard({required this.info});

  Color get _statusColor {
    if (info.overtraining) return const Color(0xFFF87171);
    if (info.daysSinceLastTrained < 2) return const Color(0xFFFBBF24);
    if (info.daysSinceLastTrained < 4) return AppColors.success;
    return Colors.white.withAlpha(80);
  }

  String get _statusLabel {
    if (info.overtraining) return 'Overtraining risk';
    if (info.daysSinceLastTrained < 2) return 'Needs rest';
    if (info.daysSinceLastTrained < 4) return 'Ready to train';
    return 'Fully recovered';
  }

  IconData get _statusIcon {
    if (info.overtraining) return Icons.warning_rounded;
    if (info.daysSinceLastTrained < 2) return Icons.hourglass_bottom_rounded;
    if (info.daysSinceLastTrained < 4) return Icons.check_circle_rounded;
    return Icons.battery_full_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _statusColor.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon, color: _statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.muscle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  _statusLabel,
                  style: TextStyle(
                      fontSize: 12, color: _statusColor),
                ),
              ],
            ),
          ),
          Text(
            info.daysSinceLastTrained == 0
                ? 'Today'
                : info.daysSinceLastTrained == 1
                    ? 'Yesterday'
                    : '${info.daysSinceLastTrained}d ago',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withAlpha(140)),
          ),
        ],
      ),
    );
  }
}

class _RecoveryGuideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primaryBlue.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryBlue, size: 18),
              SizedBox(width: 8),
              Text('Recovery Guidelines',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            '< 2 days: Muscle still recovering, avoid direct work',
            '2–3 days: Ready to train at normal intensity',
            '4+ days: Fully recovered, good time for a PR attempt',
          ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.primaryBlue)),
                    Expanded(
                        child: Text(s,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(170)))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Trends tab ────────────────────────────────────────────────────────────────

class _TrendsTab extends ConsumerWidget {
  const _TrendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prs = ref.watch(personalRecordsProvider);
    final summaries = ref.watch(allSessionSummariesProvider);

    if (summaries.isEmpty) {
      return const _NoData(
          message: 'Complete workouts to see training trends');
    }

    // Current vs last month comparison
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    double thisVol = 0, lastVol = 0;
    int thisCount = 0, lastCount = 0;

    for (final s in summaries) {
      final d = s.session.startTime;
      if (!d.isBefore(thisMonthStart)) {
        thisVol += s.totalVolume;
        thisCount++;
      } else if (!d.isBefore(lastMonthStart) && d.isBefore(thisMonthStart)) {
        lastVol += s.totalVolume;
        lastCount++;
      }
    }

    final volDelta = lastVol > 0 ? (thisVol - lastVol) / lastVol * 100 : 0.0;
    final countDelta = lastCount > 0
        ? (thisCount - lastCount) / lastCount * 100
        : 0.0;

    // Top 5 exercises by max weight
    final top5 = prs.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: 'This Month vs Last Month'),
        const SizedBox(height: 12),
        Row(
          children: [
            _CompareCard(
              label: 'Workouts',
              thisValue: thisCount.toString(),
              delta: countDelta,
            ),
            const SizedBox(width: 12),
            _CompareCard(
              label: 'Volume',
              thisValue: thisVol >= 1000
                  ? '${(thisVol / 1000).toStringAsFixed(1)}k'
                  : thisVol.toStringAsFixed(0),
              delta: volDelta,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Strength Leaders'),
        const SizedBox(height: 4),
        Text(
          'Your current personal bests',
          style: TextStyle(
              fontSize: 13, color: Colors.white.withAlpha(140)),
        ),
        const SizedBox(height: 12),
        if (top5.isEmpty)
          Text('No PRs recorded yet.',
              style: TextStyle(color: Colors.white.withAlpha(100)))
        else
          ...top5.map(
            (pr) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(pr.exerciseName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                  Text(
                    '${pr.maxWeight.toStringAsFixed(1)} kg × ${pr.maxRepsAtMaxWeight}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String label;
  final String thisValue;
  final double delta;

  const _CompareCard(
      {required this.label,
      required this.thisValue,
      required this.delta});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final deltaColor =
        isPositive ? AppColors.success : const Color(0xFFF87171);
    final deltaStr =
        '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}%';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withAlpha(140))),
            const SizedBox(height: 4),
            Text(thisValue,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: deltaColor,
                  size: 14,
                ),
                Text(deltaStr,
                    style:
                        TextStyle(color: deltaColor, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _NoData extends StatelessWidget {
  final String message;
  const _NoData({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 48, color: Colors.white.withAlpha(60)),
          const SizedBox(height: 12),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withAlpha(120)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
