import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/session_model.dart';
import '../../data/services/hive_service.dart';

class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// date (midnight) → list of sessions
  Map<DateTime, List<WorkoutSessionModel>> _sessionsByDay = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final box = HiveService.sessions;
    final byDay = <DateTime, List<WorkoutSessionModel>>{};
    for (final s in box.values) {
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
          // ── Stats row ──────────────────────────────────────────────────────
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

          // ── Calendar ───────────────────────────────────────────────────────
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

          // ── Selected day sessions ──────────────────────────────────────────
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
          ],
        ),
      );

  Widget _sessionList(List<WorkoutSessionModel> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final s = sessions[i];
        return Card(
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
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tealSuccess.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tealSuccess.withAlpha(60)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: tealSuccess,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        );
      },
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
