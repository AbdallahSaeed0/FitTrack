import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/session_model.dart';

// ── Colour palette (self-contained, no AppColors dependency) ──────────────────
const _bg = Color(0xFF0F172A);
const _surface = Color(0xFF1E293B);
const _border = Color(0xFF2A3F58);
const _primary = Color(0xFF38BDF8);
const _success = Color(0xFF34D399);
const _warn = Color(0xFFFB923C);
const _t1 = Color(0xFFF1F5F9);
const _t2 = Color(0xFF94A3B8);
const _t3 = Color(0xFF475569);

// ── PR detection helper ───────────────────────────────────────────────────────

/// Detects which dates had a personal-record broken.
/// Iterates sessions chronologically, tracking the running max weight per
/// exercise name. A date is a PR date if any exercise in that session beat the
/// historical max seen in all earlier sessions.
Set<String> detectPRDates(Map<String, WorkoutSessionModel> sessions) {
  final prDates = <String>{};
  if (sessions.isEmpty) return prDates;

  // Sort dates ascending so we accumulate history correctly.
  final sortedKeys = sessions.keys.toList()..sort();

  // exerciseName (lowercased) → historical max weight (from all prior sessions)
  final Map<String, double> historicalMax = {};

  for (final dateKey in sortedKeys) {
    final session = sessions[dateKey]!;
    bool isPRDay = false;

    for (final ex in session.exercises) {
      final name = ex.exerciseName.trim().toLowerCase();
      double sessionMax = 0;
      for (final s in ex.sets) {
        if (!s.isBodyweight && s.weight > sessionMax) sessionMax = s.weight;
      }
      if (sessionMax > 0) {
        final prev = historicalMax[name] ?? 0;
        if (sessionMax > prev) {
          isPRDay = true;
          historicalMax[name] = sessionMax;
        } else {
          historicalMax[name] = math.max(prev, sessionMax);
        }
      }
    }

    if (isPRDay) prDates.add(dateKey);
  }

  return prDates;
}

// ── WorkoutCalendar ────────────────────────────────────────────────────────────

class WorkoutCalendar extends StatefulWidget {
  final Map<String, WorkoutSessionModel> sessionsByDate;
  final Set<String> prDates;

  const WorkoutCalendar({
    super.key,
    required this.sessionsByDate,
    required this.prDates,
  });

  @override
  State<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends State<WorkoutCalendar> {
  late DateTime _displayedMonth;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _sameMonth(DateTime d) =>
      d.year == _displayedMonth.year && d.month == _displayedMonth.month;

  /// Returns the Mon-anchored grid cells for the displayed month.
  /// Includes leading days from prev month and trailing from next month.
  List<DateTime?> _buildGridCells() {
    final firstOfMonth = _displayedMonth;
    // weekday: Mon=1 … Sun=7
    final leadingBlanks = (firstOfMonth.weekday - 1) % 7;
    final daysInMonth =
        DateUtils.getDaysInMonth(firstOfMonth.year, firstOfMonth.month);
    final total = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - total % 7) % 7;

    final cells = <DateTime?>[];
    // Leading ghost days
    for (int i = leadingBlanks - 1; i >= 0; i--) {
      cells.add(firstOfMonth.subtract(Duration(days: i + 1)));
    }
    // Actual month days
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(firstOfMonth.year, firstOfMonth.month, d));
    }
    // Trailing ghost days
    for (int i = 1; i <= trailingBlanks; i++) {
      cells.add(DateTime(firstOfMonth.year, firstOfMonth.month, daysInMonth + i));
    }
    return cells;
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  int get _totalSessions => widget.sessionsByDate.length;

  int get _thisMonthCount {
    return widget.sessionsByDate.keys.where((k) {
      final d = DateTime.tryParse(k);
      return d != null &&
          d.year == _displayedMonth.year &&
          d.month == _displayedMonth.month;
    }).length;
  }

  int get _thisWeekCount {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    return widget.sessionsByDate.keys.where((k) {
      final d = DateTime.tryParse(k);
      return d != null &&
          !d.isBefore(weekStart) &&
          d.isBefore(weekEnd);
    }).length;
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  void _prevMonth() => setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month - 1);
        _selectedDate = null;
      });

  void _nextMonth() => setState(() {
        _displayedMonth =
            DateTime(_displayedMonth.year, _displayedMonth.month + 1);
        _selectedDate = null;
      });

  @override
  Widget build(BuildContext context) {
    final cells = _buildGridCells();

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MonthNav(
            displayedMonth: _displayedMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          _Divider(),
          _StatsRow(
            total: _totalSessions,
            thisMonth: _thisMonthCount,
            thisWeek: _thisWeekCount,
          ),
          _Divider(),
          _WeekdayHeaders(),
          _DayGrid(
            cells: cells,
            displayedMonth: _displayedMonth,
            sessionsByDate: widget.sessionsByDate,
            prDates: widget.prDates,
            selectedDate: _selectedDate,
            isToday: _isToday,
            sameMonth: _sameMonth,
            fmt: _fmt,
            onSelect: (dateKey) {
              setState(() {
                _selectedDate =
                    _selectedDate == dateKey ? null : dateKey;
              });
            },
          ),
          // Session detail card
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selectedDate != null &&
                    widget.sessionsByDate.containsKey(_selectedDate)
                ? _SessionDetailCard(
                    dateKey: _selectedDate!,
                    session: widget.sessionsByDate[_selectedDate!]!,
                    isPR: widget.prDates.contains(_selectedDate),
                  )
                : const SizedBox.shrink(),
          ),
          _Legend(),
        ],
      ),
    );
  }
}

// ── Month navigation bar ──────────────────────────────────────────────────────

class _MonthNav extends StatelessWidget {
  final DateTime displayedMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNav({
    required this.displayedMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM').format(displayedMonth),
            style: const TextStyle(
              color: _t1,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${displayedMonth.year}',
            style: const TextStyle(
              color: _t2,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
          const SizedBox(width: 8),
          _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered ? _primary : _border,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovered ? _primary : _t2,
          ),
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int thisMonth;
  final int thisWeek;

  const _StatsRow({
    required this.total,
    required this.thisMonth,
    required this.thisWeek,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '$total',
              label: 'TOTAL',
              color: _primary,
            ),
          ),
          _VDivider(),
          Expanded(
            child: _StatCell(
              value: '$thisMonth',
              label: 'THIS MONTH',
              color: _success,
            ),
          ),
          _VDivider(),
          Expanded(
            child: _StatCell(
              value: '$thisWeek',
              label: 'THIS WEEK',
              color: _warn,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _t3,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekday headers ───────────────────────────────────────────────────────────

class _WeekdayHeaders extends StatelessWidget {
  const _WeekdayHeaders();

  static const _labels = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: List.generate(7, (i) {
          final isWeekend = i >= 5;
          return Expanded(
            child: Center(
              child: Text(
                _labels[i],
                style: TextStyle(
                  color: _t3.withAlpha(isWeekend ? 178 : 255),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Day grid ──────────────────────────────────────────────────────────────────

class _DayGrid extends StatelessWidget {
  final List<DateTime?> cells;
  final DateTime displayedMonth;
  final Map<String, WorkoutSessionModel> sessionsByDate;
  final Set<String> prDates;
  final String? selectedDate;
  final bool Function(DateTime) isToday;
  final bool Function(DateTime) sameMonth;
  final String Function(DateTime) fmt;
  final void Function(String) onSelect;

  const _DayGrid({
    required this.cells,
    required this.displayedMonth,
    required this.sessionsByDate,
    required this.prDates,
    required this.selectedDate,
    required this.isToday,
    required this.sameMonth,
    required this.fmt,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: cells.length,
        itemBuilder: (_, i) {
          final d = cells[i];
          if (d == null) return const SizedBox.shrink();

          final inMonth = sameMonth(d);
          final dateKey = fmt(d);
          final hasSession = sessionsByDate.containsKey(dateKey);
          final isPR = prDates.contains(dateKey);
          final today = isToday(d);
          final selected = selectedDate == dateKey;

          if (!inMonth) {
            return _GhostCell(day: d.day);
          }

          return _DayCell(
            day: d.day,
            hasSession: hasSession,
            isPR: isPR,
            isToday: today,
            isSelected: selected,
            onTap: hasSession ? () => onSelect(dateKey) : null,
          );
        },
      ),
    );
  }
}

// ── Ghost cell (prev/next month) ──────────────────────────────────────────────

class _GhostCell extends StatelessWidget {
  final int day;
  const _GhostCell({required this.day});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Opacity(
        opacity: 0.25,
        child: Center(
          child: Text(
            '$day',
            style: const TextStyle(
              color: _t3,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasSession;
  final bool isPR;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.hasSession,
    required this.isPR,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  Color get _bgColor {
    if (isSelected) return isPR ? _primary : _success;
    if (hasSession && isPR) return const Color(0xFF38BDF8).withAlpha(18);
    if (hasSession) return const Color(0xFF34D399).withAlpha(15);
    if (isToday) return const Color(0xFF0D2133);
    return Colors.transparent;
  }

  Color get _borderColor {
    if (isSelected) return isPR ? _primary : _success;
    if (hasSession && isPR)
      return const Color(0xFF38BDF8).withAlpha(77);
    if (hasSession) return const Color(0xFF34D399).withAlpha(64);
    if (isToday) return _primary;
    return Colors.transparent;
  }

  Color get _textColor {
    if (isSelected) return isPR ? const Color(0xFF021826) : const Color(0xFF0A1F18);
    if (hasSession) return _t1;
    if (isToday) return _primary;
    return _t2;
  }

  FontWeight get _fontWeight {
    if (isSelected || isToday) return FontWeight.w700;
    if (hasSession) return FontWeight.w600;
    return FontWeight.w500;
  }

  Color get _arcColor => isPR
      ? const Color(0xFF38BDF8).withAlpha(128)
      : const Color(0xFF34D399).withAlpha(128);

  @override
  Widget build(BuildContext context) {
    Widget cell = AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _borderColor,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: _fontWeight,
                  height: 1.0,
                ),
              ),
              if (hasSession && !isSelected) ...[
                const SizedBox(height: 3),
                _DotIndicator(isPR: isPR),
              ],
            ],
          ),
        ),
      ),
    );

    // Wrap session days in a ring arc painter.
    if (hasSession && !isSelected) {
      cell = _RingArcWrapper(color: _arcColor, child: cell);
    }

    return cell;
  }
}

// ── Ring arc wrapper ──────────────────────────────────────────────────────────

class _RingArcWrapper extends StatelessWidget {
  final Color color;
  final Widget child;

  const _RingArcWrapper({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _RingArcPainter(color: color),
      child: child,
    );
  }
}

class _RingArcPainter extends CustomPainter {
  final Color color;
  const _RingArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 1.5;

    const gapDeg = 20.0;
    final startAngle = (-math.pi / 2) + (gapDeg / 2) * math.pi / 180;
    final sweepAngle = (360 - gapDeg) * math.pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingArcPainter old) => old.color != color;
}

// ── Dot indicator ─────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final bool isPR;
  const _DotIndicator({required this.isPR});

  @override
  Widget build(BuildContext context) {
    if (!isPR) {
      return _dot(_success);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(_primary),
        const SizedBox(width: 2),
        _dot(_warn),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ── Session detail card ───────────────────────────────────────────────────────

class _SessionDetailCard extends StatelessWidget {
  final String dateKey;
  final WorkoutSessionModel session;
  final bool isPR;

  const _SessionDetailCard({
    required this.dateKey,
    required this.session,
    required this.isPR,
  });

  int get _totalSets =>
      session.exercises.fold(0, (sum, e) => sum + e.sets.length);

  double get _totalVolume => session.exercises.fold(
      0,
      (sum, e) =>
          sum +
          e.sets.fold(
              0.0, (s2, set) => s2 + (set.isBodyweight ? 0 : set.weight * set.reps)));

  String _fmtVol(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

  String _fmtDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(dateKey) ?? DateTime.now();
    final dateLabel = DateFormat('EEE, MMMM d').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: _t2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isPR ? _primary : _success).withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPR ? '🏆 PR Broken' : '✓ Completed',
                    style: TextStyle(
                      color: isPR ? _primary : _success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Body row
            Row(
              children: [
                // Icon box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isPR ? _primary : _success).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      isPR ? '🏆' : '💪',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.dayName,
                        style: const TextStyle(
                          color: _t1,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Duration: ${_fmtDuration(session.durationMinutes)}',
                        style: const TextStyle(
                          color: _t2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniStat(
                      value: _totalSets > 0 ? '$_totalSets' : '—',
                      label: 'Sets',
                    ),
                    const SizedBox(width: 14),
                    _MiniStat(
                      value: _totalVolume > 0
                          ? '${_fmtVol(_totalVolume)} kg'
                          : '—',
                      label: 'Vol',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _t1,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: _t3,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: const [
          _LegendItem(color: _success, label: 'Workout', outlined: false),
          _LegendItem(color: _primary, label: 'PR broken', outlined: false),
          _LegendItem(color: _primary, label: 'Today', outlined: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool outlined;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(3),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _t3,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Shared dividers ───────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: _border, height: 1, thickness: 1);
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        color: _border,
      );
}
