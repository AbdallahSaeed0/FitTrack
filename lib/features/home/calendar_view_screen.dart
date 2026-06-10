import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../programs/programs_provider.dart';
import 'home_provider.dart';

class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<WorkoutSessionModel>> _sessionsByDay = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final byDay = <DateTime, List<WorkoutSessionModel>>{};
    for (final s in SessionRepository.instance.getAll()) {
      if (!s.completed) continue;
      final d = _midnight(s.startTime);
      byDay.putIfAbsent(d, () => []).add(s);
    }
    setState(() => _sessionsByDay = byDay);
  }

  static DateTime _midnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  List<WorkoutSessionModel> _eventsFor(DateTime day) =>
      _sessionsByDay[_midnight(day)] ?? [];

  int get _totalWorkouts =>
      _sessionsByDay.values.fold(0, (s, l) => s + l.length);

  int get _thisMonthWorkouts {
    final now = DateTime.now();
    return _sessionsByDay.entries
        .where((e) => e.key.year == now.year && e.key.month == now.month)
        .fold(0, (s, e) => s + e.value.length);
  }

  int get _thisWeekWorkouts {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _sessionsByDay.entries
        .where((e) => !e.key.isBefore(start) && e.key.isBefore(end))
        .fold(0, (s, e) => s + e.value.length);
  }

  void _showSessionReport(WorkoutSessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionReportSheet(session: session),
    );
  }

  void _showManualLogSheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualLogSheet(
        date: day,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedSessions = _selectedDay != null
        ? (_sessionsByDay[_midnight(_selectedDay!)] ?? [])
        : <WorkoutSessionModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Training Calendar')),
      body: Column(
        children: [
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _StatBubble(
                    label: 'Total', value: '$_totalWorkouts', color: steelBlue),
                const SizedBox(width: 10),
                _StatBubble(
                    label: 'This Month',
                    value: '$_thisMonthWorkouts',
                    color: tealSuccess),
                const SizedBox(width: 10),
                _StatBubble(
                    label: 'This Week',
                    value: '$_thisWeekWorkouts',
                    color: primaryRed),
              ],
            ),
          ),

          const SizedBox(height: 8),

          TableCalendar<WorkoutSessionModel>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            eventLoader: _eventsFor,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: steelBlue.withAlpha(100),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: primaryRed,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: tealSuccess,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1D3557),
              ),
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF457B9D),
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0D1B2A),
              ),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
          ),

          const Divider(height: 1),

          // Selected day hint / rest / sessions
          Expanded(
            child: _selectedDay == null
                ? _hint()
                : selectedSessions.isEmpty
                    ? _restDay(_selectedDay!)
                    : _sessionList(selectedSessions),
          ),
        ],
      ),
    );
  }

  Widget _hint() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_rounded, size: 40, color: steelBlue),
            const SizedBox(height: 10),
            Text('Tap a day to see details',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Tap a session to view details · Swipe to delete',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF8899AA))),
          ],
        ),
      );

  Widget _restDay(DateTime day) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement_rounded,
                size: 40, color: Color(0xFF8899AA)),
            const SizedBox(height: 10),
            Text(DateFormat('EEEE, d MMM').format(day),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Rest day', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showManualLogSheet(day),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Log Workout for This Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: steelBlue,
              ),
            ),
          ],
        ),
      );

  Widget _sessionList(List<WorkoutSessionModel> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final s = sessions[i];
        return Dismissible(
          key: Key(s.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: primaryRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  barrierColor: Colors.black.withAlpha(160),
                  builder: (ctx) =>
                      _DeleteWorkoutDialog(dayName: s.dayName),
                ) ??
                false;
          },
          onDismissed: (_) async {
            await SessionRepository.instance.delete(s.id);
            // Roll the program back so the deleted day becomes next again.
            if (s.programId.isNotEmpty) {
              await ProgramRepository.instance
                  .revertToDay(s.programId, s.dayName);
              ref.read(programsProvider.notifier).refresh();
            }
            _load();
            // Notify home page so stats/recent sessions update immediately.
            ref.read(homeRefreshProvider.notifier).refresh();
          },
          child: GestureDetector(
            onTap: () => _showSessionReport(s),
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tealSuccess.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: tealSuccess, size: 22),
                ),
                title: Text(s.dayName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${DateFormat('h:mm a').format(s.startTime)} · ${s.durationMinutes} min · ${s.exercises.length} exercises',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tealSuccess.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: tealSuccess.withAlpha(60)),
                      ),
                      child: const Text('Done',
                          style: TextStyle(
                              color: tealSuccess,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Color(0xFF8899AA)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Session Report Sheet ───────────────────────────────────────────────────────

class _SessionReportSheet extends StatelessWidget {
  final WorkoutSessionModel session;
  const _SessionReportSheet({required this.session});

  @override
  Widget build(BuildContext context) {
    final activeExercises = session.exercises.where((e) => e.sets.isNotEmpty).toList();
    final skippedExercises = session.exercises.where((e) => e.sets.isEmpty).toList();
    final totalSets = activeExercises.fold<int>(0, (s, ex) => s + ex.sets.length);
    final totalVolume = activeExercises.fold<double>(
        0, (s, ex) => s + ex.sets.fold<double>(0, (s2, set) => s2 + set.weight * set.reps));
    // estimated time per active exercise
    final estMinsPerEx = activeExercises.isEmpty
        ? 0
        : (session.durationMinutes / activeExercises.length).round();

    return Container(
      // Fixed height — lets tapping above dismiss the modal naturally
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle + tap-to-close area
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withAlpha(80),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.dayName,
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        DateFormat('EEEE, d MMM yyyy').format(session.startTime),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF8899AA)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tealSuccess.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tealSuccess.withAlpha(60)),
                    ),
                    child: Text(
                      '${session.durationMinutes} min',
                      style: const TextStyle(
                          color: tealSuccess, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _StatChip(
                  label: 'Done',
                  value: '${activeExercises.length}',
                  color: tealSuccess,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Sets',
                  value: '$totalSets',
                  color: primaryRed,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: skippedExercises.isEmpty ? 'Volume' : 'Skipped',
                  value: skippedExercises.isEmpty
                      ? (totalVolume > 0
                          ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
                          : '—')
                      : '${skippedExercises.length}',
                  color: skippedExercises.isEmpty ? steelBlue : primaryRed,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Exercise list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active exercises
                ...activeExercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ex = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExerciseReportCard(
                      ex: ex,
                      index: i + 1,
                      estMinutes: estMinsPerEx,
                    ),
                  );
                }),
                // Skipped exercises
                if (skippedExercises.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: primaryRed),
                        const SizedBox(width: 6),
                        Text('Skipped Exercises',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    color: primaryRed,
                                    fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  ...skippedExercises.map((ex) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryRed.withAlpha(8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryRed.withAlpha(40)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.skip_next_rounded,
                                  size: 16, color: primaryRed),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(ex.exerciseName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: primaryRed,
                                            fontWeight: FontWeight.w500)),
                              ),
                              const Text('Skipped',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: primaryRed,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _ExerciseReportCard extends StatelessWidget {
  final LoggedExerciseModel ex;
  final int index;
  final int estMinutes;

  const _ExerciseReportCard({
    required this.ex,
    required this.index,
    required this.estMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final vol = ex.sets.fold<double>(0, (s, set) => s + set.weight * set.reps);
    final maxW = ex.sets
        .where((s) => !s.isBodyweight)
        .map((s) => s.weight)
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Theme.of(context).dividerColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: steelBlue.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$index',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: steelBlue)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(ex.exerciseName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (estMinutes > 0)
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: Color(0xFF8899AA)),
                    const SizedBox(width: 3),
                    Text('~$estMinutes min',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8899AA))),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ex.sets.asMap().entries.map((e) {
              final s = e.value;
              String summary;
              if (s.isCardio) {
                summary = s.formatSummary();
              } else {
                final wStr = s.isBodyweight
                    ? 'BW'
                    : (s.weight == s.weight.floorToDouble()
                        ? '${s.weight.toInt()}kg'
                        : '${s.weight.toStringAsFixed(1)}kg');
                final uniStr = s.isUnilateral ? '/side' : '';
                final failStr = s.toFailure ? ' F' : '';
                summary = '$wStr$uniStr × ${s.reps}$failStr';
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tealSuccess.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tealSuccess.withAlpha(50)),
                ),
                child: Text(
                  'S${e.key + 1}: $summary',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tealSuccess),
                ),
              );
            }).toList(),
          ),
          if (ex.sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (maxW > 0) ...[
                  const Icon(Icons.arrow_upward_rounded,
                      size: 13, color: Color(0xFF8899AA)),
                  const SizedBox(width: 3),
                  Text(
                    'Top: ${maxW.toStringAsFixed(maxW == maxW.floorToDouble() ? 0 : 1)}kg',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8899AA)),
                  ),
                  const SizedBox(width: 12),
                ],
                if (vol > 0) ...[
                  const Icon(Icons.bar_chart_rounded,
                      size: 13, color: Color(0xFF8899AA)),
                  const SizedBox(width: 3),
                  Text(
                    'Vol: ${vol.toStringAsFixed(0)}kg',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8899AA)),
                  ),
                ],
                // Notes
                ...ex.sets
                    .where((s) => s.notes != null && s.notes!.isNotEmpty)
                    .take(1)
                    .map((s) => Expanded(
                          child: Text(
                            '  · "${s.notes}"',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8899AA),
                                fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withAlpha(180))),
          ],
        ),
      ),
    );
  }
}

// ── Manual Log Sheet (log a past workout) ─────────────────────────────────────

class _ManualExerciseEntry {
  String name;
  List<({double weight, int reps})> sets;
  _ManualExerciseEntry({this.name = '', List<({double weight, int reps})>? sets})
      : sets = sets ?? [const (weight: 0, reps: 10)];
}

class _ManualLogSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final VoidCallback onSaved;
  const _ManualLogSheet({required this.date, required this.onSaved});

  @override
  ConsumerState<_ManualLogSheet> createState() => _ManualLogSheetState();
}

class _ManualLogSheetState extends ConsumerState<_ManualLogSheet> {
  final _nameController = TextEditingController(text: 'Manual Workout');
  final List<_ManualExerciseEntry> _exercises = [_ManualExerciseEntry()];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_exercises.isEmpty || _exercises.every((e) => e.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one exercise')));
      return;
    }
    setState(() => _saving = true);

    final loggedExercises = _exercises
        .where((e) => e.name.trim().isNotEmpty)
        .map((e) {
          final sets = e.sets.asMap().entries.map((entry) => LoggedSetModel(
                setNumber: entry.key + 1,
                weight: entry.value.weight,
                reps: entry.value.reps,
                isBodyweight: entry.value.weight == 0,
              )).toList();
          return LoggedExerciseModel(
            exerciseId: '',
            exerciseName: e.name.trim(),
            sets: sets,
          );
        })
        .toList();

    final now = widget.date;
    final session = WorkoutSessionModel(
      id: const Uuid().v4(),
      programId: '',
      dayName: _nameController.text.trim().isEmpty
          ? 'Manual Workout'
          : _nameController.text.trim(),
      startTime: DateTime(now.year, now.month, now.day, 10, 0),
      endTime: DateTime(now.year, now.month, now.day, 11, 0),
      durationMinutes: 60,
      exercises: loggedExercises,
      completed: true,
    );

    await SessionRepository.instance.save(session);
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withAlpha(80),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.edit_calendar_rounded, color: steelBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log Past Workout',
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text(
                        DateFormat('EEEE, d MMM yyyy').format(widget.date),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF8899AA)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: steelBlue))
                      : const Text('Save',
                          style: TextStyle(
                              color: steelBlue,
                              fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Workout Name',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                ..._exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ex = entry.value;
                  return _ExerciseInputCard(
                    key: ValueKey(i),
                    exercise: ex,
                    index: i,
                    onChanged: () => setState(() {}),
                    onRemove: _exercises.length > 1
                        ? () => setState(() => _exercises.removeAt(i))
                        : null,
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _exercises.add(_ManualExerciseEntry())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercise'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: steelBlue,
                      side: const BorderSide(color: steelBlue)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseInputCard extends StatefulWidget {
  final _ManualExerciseEntry exercise;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _ExerciseInputCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_ExerciseInputCard> createState() => _ExerciseInputCardState();
}

class _ExerciseInputCardState extends State<_ExerciseInputCard> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exercise.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Exercise name (e.g. Bench Press)',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) {
                      widget.exercise.name = v;
                      widget.onChanged();
                    },
                  ),
                ),
                if (widget.onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: primaryRed),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Sets
            ...widget.exercise.sets.asMap().entries.map((e) {
              final si = e.key;
              final set = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('S${si + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: steelBlue,
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'kg',
                          suffixText: 'kg',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                        controller: TextEditingController(
                            text: set.weight > 0
                                ? set.weight.toStringAsFixed(
                                    set.weight == set.weight.floorToDouble()
                                        ? 0
                                        : 1)
                                : ''),
                        onChanged: (v) {
                          final w = double.tryParse(v) ?? 0;
                          widget.exercise.sets[si] =
                              (weight: w, reps: set.reps);
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('×',
                        style: TextStyle(
                            color: Color(0xFF8899AA), fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'reps',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                        controller: TextEditingController(
                            text:
                                set.reps > 0 ? '${set.reps}' : ''),
                        onChanged: (v) {
                          final r = int.tryParse(v) ?? set.reps;
                          widget.exercise.sets[si] =
                              (weight: set.weight, reps: r);
                          widget.onChanged();
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          size: 18, color: primaryRed),
                      onPressed: widget.exercise.sets.length > 1
                          ? () => setState(
                              () => widget.exercise.sets.removeAt(si))
                          : null,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() =>
                  widget.exercise.sets.add(const (weight: 0, reps: 10))),
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add Set', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: steelBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat bubble ───────────────────────────────────────────────────────────────

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBubble(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withAlpha(180),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Delete Workout confirmation dialog ────────────────────────────────────────

class _DeleteWorkoutDialog extends StatelessWidget {
  final String dayName;
  const _DeleteWorkoutDialog({required this.dayName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Red danger header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withAlpha(60), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Delete Workout?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  // Workout name chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fitness_center_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Text(
                          dayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'This session will be permanently removed\nfrom your history. This cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Color(0xFF334155), height: 1),
            ),

            // ── Buttons ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  // Cancel
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: const Color(0xFF334155)),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Delete
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withAlpha(80),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
