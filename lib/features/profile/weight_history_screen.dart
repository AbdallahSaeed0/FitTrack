import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';

// ─── Data helpers ─────────────────────────────────────────────────────────────

class _ExerciseHistory {
  final String name;
  // Each entry = one session with its sets for this exercise
  final List<({DateTime date, String dayName, List<LoggedSetModel> sets})> sessions;

  const _ExerciseHistory({required this.name, required this.sessions});

  DateTime get lastDate => sessions.first.date;

  /// Best single set by weight across all sessions
  LoggedSetModel? get bestSet {
    LoggedSetModel? best;
    for (final s in sessions) {
      for (final set in s.sets) {
        if (best == null || set.weight > best.weight) best = set;
      }
    }
    return best;
  }

  int get totalSets =>
      sessions.fold(0, (sum, s) => sum + s.sets.length);
}

List<_ExerciseHistory> _buildHistory(List<WorkoutSessionModel> sessions) {
  // Map: exerciseName → list of session entries (newest first)
  final Map<String, List<({DateTime date, String dayName, List<LoggedSetModel> sets})>> map = {};

  for (final session in sessions) {
    if (!session.completed) continue;
    for (final ex in session.exercises) {
      if (ex.sets.isEmpty) continue;
      map.putIfAbsent(ex.exerciseName, () => []);
      map[ex.exerciseName]!.add((
        date: session.startTime,
        dayName: session.dayName,
        sets: ex.sets,
      ));
    }
  }

  // Build list, sort each exercise's sessions newest→oldest, then sort exercises by last date
  final list = map.entries.map((e) {
    final sorted = List.of(e.value)
      ..sort((a, b) => b.date.compareTo(a.date));
    return _ExerciseHistory(name: e.key, sessions: sorted);
  }).toList()
    ..sort((a, b) => b.lastDate.compareTo(a.lastDate));

  return list;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class WeightHistoryScreen extends StatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  State<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends State<WeightHistoryScreen> {
  List<_ExerciseHistory> _all = [];
  List<_ExerciseHistory> _filtered = [];
  final _searchController = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  void _load() {
    final sessions = SessionRepository().getAll();
    final history = _buildHistory(sessions);
    setState(() {
      _all = history;
      _filtered = history;
      _loaded = true;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((e) => e.name.toLowerCase().contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight History'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercise…',
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8899AA)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Summary strip
          if (_loaded && _all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _StatChip(
                    icon: Icons.fitness_center_rounded,
                    label: '${_all.length} exercises',
                    color: AppColors.activeDark,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.bar_chart_rounded,
                    label:
                        '${_all.fold(0, (s, e) => s + e.totalSets)} total sets',
                    color: tealSuccess,
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : _all.isEmpty
                    ? _EmptyState()
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No exercises match "${_searchController.text}"',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) =>
                                _ExerciseCard(entry: _filtered[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise Card (expandable) ───────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  final _ExerciseHistory entry;
  const _ExerciseCard({required this.entry});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = false;

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${diff ~/ 7}w ago';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final best = entry.bestSet;
    final bestW = best == null
        ? '—'
        : best.weight == best.weight.floorToDouble()
            ? '${best.weight.toInt()}kg'
            : '${best.weight.toStringAsFixed(1)}kg';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Theme.of(context).dividerColor.withAlpha(60)),
      ),
      child: Column(
        children: [
          // Header — always visible
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.activeDark.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded,
                        color: AppColors.activeDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _MetaChip(
                              icon: Icons.calendar_today_rounded,
                              label: _relativeDate(entry.lastDate),
                            ),
                            const SizedBox(width: 8),
                            _MetaChip(
                              icon: Icons.repeat_rounded,
                              label:
                                  '${entry.sessions.length} ${entry.sessions.length == 1 ? 'session' : 'sessions'}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Best weight badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bestW,
                        style: TextStyle(
                          color: AppColors.activeDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'best',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8899AA),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Sessions detail — shown when expanded
          if (_expanded) ...[
            Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withAlpha(60)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: entry.sessions
                    .map((s) => _SessionRow(session: s))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Session row inside an expanded exercise card ─────────────────────────────

class _SessionRow extends StatelessWidget {
  final ({DateTime date, String dayName, List<LoggedSetModel> sets}) session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(session.date);
    final dayLabel = session.dayName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + day row
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 13, color: Color(0xFF8899AA)),
              const SizedBox(width: 5),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.activeDark,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dayLabel,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sets as chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: session.sets.asMap().entries.map((e) {
              final s = e.value;
              final w = s.weight;
              final wStr = w == w.floorToDouble()
                  ? w.toInt().toString()
                  : w.toStringAsFixed(1);
              final hasNote = s.notes != null && s.notes!.isNotEmpty;
              return Tooltip(
                message: hasNote ? s.notes! : '',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.activeDark.withAlpha(14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.activeDark.withAlpha(35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'S${s.setNumber}',
                        style: TextStyle(
                          color: AppColors.activeDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${wStr}kg × ${s.reps}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                      ),
                      if (hasNote) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.sticky_note_2_rounded,
                            size: 12, color: Color(0xFF8899AA)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Volume line
          const SizedBox(height: 6),
          _VolumeBar(sets: session.sets),
        ],
      ),
    );
  }
}

// ─── Volume bar (total volume + per-set bars) ─────────────────────────────────

class _VolumeBar extends StatelessWidget {
  final List<LoggedSetModel> sets;
  const _VolumeBar({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox.shrink();
    final totalVol =
        sets.fold(0.0, (sum, s) => sum + s.weight * s.reps);
    final maxVol = sets.map((s) => s.weight * s.reps).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume: ${totalVol.toInt()} kg·reps',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontSize: 11, color: const Color(0xFF8899AA)),
        ),
        const SizedBox(height: 4),
        Row(
          children: sets.map((s) {
            final ratio = maxVol > 0 ? (s.weight * s.reps) / maxVol : 0.0;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.activeDark
                      .withAlpha((ratio * 180).round().clamp(30, 180)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Small helper widgets ─────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF8899AA)),
        const SizedBox(width: 3),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 11)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_rounded,
                size: 56,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withAlpha(80)),
            const SizedBox(height: 16),
            Text('No workout history yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Complete your first workout and your weight history will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
