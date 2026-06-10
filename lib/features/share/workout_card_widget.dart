import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'share_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Template enum
// ─────────────────────────────────────────────────────────────────────────────

enum CardTemplate {
  minimal,
  detailed,
  achievement;

  String get label {
    switch (this) {
      case CardTemplate.minimal:
        return 'Minimal';
      case CardTemplate.detailed:
        return 'Detailed';
      case CardTemplate.achievement:
        return 'Achievement';
    }
  }

  String get description {
    switch (this) {
      case CardTemplate.minimal:
        return 'Clean stats';
      case CardTemplate.detailed:
        return 'Full breakdown';
      case CardTemplate.achievement:
        return 'PRs & wins';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette — fixed values so they render identically off-screen
// ─────────────────────────────────────────────────────────────────────────────

const _bg1 = Color(0xFF08101F);
const _bg2 = Color(0xFF1A2438);
const _blue = Color(0xFF38BDF8);
const _green = Color(0xFF34D399);
const _amber = Color(0xFFFBBF24);
const _white = Colors.white;
const _sub = Color(0xFFCBD5E1);
const _muted = Color(0xFF94A3B8);
const _glass = Color(0x14FFFFFF);
const _glassBorder = Color(0x22FFFFFF);
const _divider = Color(0x33FFFFFF);

// ─────────────────────────────────────────────────────────────────────────────
// Root card widget
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutCardWidget extends StatelessWidget {
  final WorkoutShareData data;
  final CardTemplate template;
  final bool showExercises;
  final bool showQuote;

  const WorkoutCardWidget({
    super.key,
    required this.data,
    required this.template,
    this.showExercises = true,
    this.showQuote = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: switch (template) {
          CardTemplate.minimal => _MinimalCard(
              data: data,
              showQuote: showQuote,
            ),
          CardTemplate.detailed => _DetailedCard(
              data: data,
              showExercises: showExercises,
              showQuote: showQuote,
            ),
          CardTemplate.achievement => _AchievementCard(
              data: data,
              showQuote: showQuote,
            ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

String _formatVol(double vol) => vol >= 1000
    ? '${(vol / 1000).toStringAsFixed(vol % 1000 == 0 ? 0 : 1)}k'
    : vol.toStringAsFixed(0);

String _formatDuration(int minutes) {
  if (minutes >= 60) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
  return '${minutes}m';
}

Widget _divLine({Color color = _divider, double height = 1}) => Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.transparent,
          color,
          color,
          Colors.transparent,
        ]),
      ),
    );

Widget _glassStatCard({
  required String value,
  required String label,
  required IconData icon,
  Color color = _blue,
}) {
  return Container(
    decoration: BoxDecoration(
      color: _glass,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _glassBorder),
    ),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _muted, height: 1.1),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _header(WorkoutShareData data) {
  return Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 8),
      const Text(
        'FitTrack',
        style: TextStyle(
            color: _white, fontSize: 15, fontWeight: FontWeight.w800,
            letterSpacing: 0.3),
      ),
      const Spacer(),
      if (data.prExercises.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _amber.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _amber.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆 ', style: TextStyle(fontSize: 10)),
              Text(
                '${data.prExercises.length} PR${data.prExercises.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: _amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
    ],
  );
}

Widget _footer(String quote) => Column(
      children: [
        _divLine(),
        const SizedBox(height: 10),
        Text(
          quote,
          style: const TextStyle(
              color: _sub, fontSize: 12, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'fittrack.app',
          style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Template 1: Minimal
// ─────────────────────────────────────────────────────────────────────────────

class _MinimalCard extends StatelessWidget {
  final WorkoutShareData data;
  final bool showQuote;
  const _MinimalCard({required this.data, required this.showQuote});

  @override
  Widget build(BuildContext context) {
    final session = data.session;
    final date = DateFormat('EEE, MMM d · yyyy').format(session.startTime);
    final volStr = _formatVol(data.totalVolume);

    return Stack(
      children: [
        // Background: photo (if provided) or gradient
        if (data.backgroundPhotoBytes != null)
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(data.backgroundPhotoBytes!, fit: BoxFit.cover),
                Container(color: Colors.black.withAlpha(140)),
              ],
            ),
          )
        else ...[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_bg1, Color(0xFF0D1B2E), _bg2],
                ),
              ),
            ),
          ),
          // Decorative glow — top right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _blue.withAlpha(50),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Decorative glow — bottom left
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _green.withAlpha(35),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Grid dot pattern (top half)
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
        ],

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(data),
              const Spacer(flex: 1),

              // Accent line + workout name
              Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(height: 10),
              Text(
                session.dayName.toUpperCase(),
                style: const TextStyle(
                  color: _white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              if (data.programName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  data.programName,
                  style: const TextStyle(
                      color: _sub, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _muted, size: 12),
                  const SizedBox(width: 5),
                  Text(date,
                      style: const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(width: 14),
                  const Icon(Icons.timer_outlined, color: _muted, size: 12),
                  const SizedBox(width: 5),
                  Text(_formatDuration(session.durationMinutes),
                      style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),

              const Spacer(flex: 1),
              _divLine(color: const Color(0x44FFFFFF)),
              const Spacer(flex: 1),

              // Stats 2×2
              Row(
                children: [
                  Expanded(
                    child: _glassStatCard(
                      value: '$volStr kg',
                      label: 'Volume',
                      icon: Icons.bar_chart_rounded,
                      color: _green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _glassStatCard(
                      value: '${data.totalSets}',
                      label: 'Sets',
                      icon: Icons.repeat_rounded,
                      color: _blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _glassStatCard(
                      value: '${data.exerciseCount}',
                      label: 'Exercises',
                      icon: Icons.fitness_center_rounded,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _glassStatCard(
                      value: data.prExercises.isEmpty
                          ? '–'
                          : '🏆 ${data.prExercises.length}',
                      label: 'New PRs',
                      icon: Icons.emoji_events_rounded,
                      color: _amber,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),
              if (showQuote)
                _footer(data.prExercises.isNotEmpty
                    ? 'New records broken. 🏆 Keep pushing.'
                    : 'Another one in the books. 💪'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template 2: Detailed
// ─────────────────────────────────────────────────────────────────────────────

class _DetailedCard extends StatelessWidget {
  final WorkoutShareData data;
  final bool showExercises;
  final bool showQuote;
  const _DetailedCard({
    required this.data,
    required this.showExercises,
    required this.showQuote,
  });

  @override
  Widget build(BuildContext context) {
    final session = data.session;
    final date = DateFormat('EEE, MMM d').format(session.startTime);
    final exercises = session.exercises.take(6).toList();

    return Stack(
      children: [
        if (data.backgroundPhotoBytes != null)
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(data.backgroundPhotoBytes!, fit: BoxFit.cover),
                Container(color: Colors.black.withAlpha(140)),
              ],
            ),
          )
        else
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.4, 1],
                  colors: [Color(0xFF0C1A2E), Color(0xFF0F2030), _bg2],
                ),
              ),
            ),
          ),

        // Top accent bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_blue, _green]),
            ),
          ),
        ),

        // Side glow (only without photo background)
        if (data.backgroundPhotoBytes == null)
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [_blue.withAlpha(30), Colors.transparent]),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(data),
              const SizedBox(height: 16),

              // Title block
              Text(
                session.dayName.toUpperCase(),
                style: const TextStyle(
                  color: _white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
              ),
              if (data.programName.isNotEmpty)
                Text(
                  data.programName,
                  style: const TextStyle(color: _sub, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(date,
                      style: const TextStyle(color: _muted, fontSize: 11)),
                  const Text('  ·  ',
                      style: TextStyle(color: _muted, fontSize: 11)),
                  Text('${session.durationMinutes} min',
                      style: const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 14),
              _divLine(),
              const SizedBox(height: 12),

              // Section header
              const Text(
                'EXERCISES',
                style: TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),

              if (showExercises)
                ...exercises.map((ex) {
                  final isCardio =
                      ex.sets.isNotEmpty && ex.sets.every((s) => s.isCardio);
                  final maxW = ex.sets.isEmpty
                      ? 0.0
                      : ex.sets
                          .map((s) => s.weight)
                          .reduce((a, b) => a > b ? a : b);
                  final isBW = ex.sets.any((s) => s.isBodyweight);
                  final isPR = data.prExercises.any((p) =>
                      p.toLowerCase().trim() ==
                      ex.exerciseName.toLowerCase().trim());
                  String weightStr;
                  if (isCardio) {
                    final totalSeconds = ex.sets
                        .fold<int>(0, (s, set) => s + (set.durationSeconds ?? 0));
                    final mins = totalSeconds ~/ 60;
                    weightStr = '$mins min';
                  } else {
                    weightStr = isBW
                        ? 'BW'
                        : maxW == maxW.floorToDouble()
                            ? '${maxW.toInt()} kg'
                            : '${maxW.toStringAsFixed(1)} kg';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isPR ? _amber : _blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            ex.exerciseName,
                            style: TextStyle(
                              color: isPR ? _amber : _white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPR)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text('🏆', style: TextStyle(fontSize: 10)),
                          ),
                        Text(
                          '${ex.sets.length} sets · $weightStr',
                          style:
                              const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }),

              if (!showExercises || exercises.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: _glass,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded,
                          color: _blue, size: 16),
                      const SizedBox(width: 10),
                      Text('${data.exerciseCount} exercises completed',
                          style: const TextStyle(color: _sub, fontSize: 12)),
                    ],
                  ),
                ),

              const Spacer(),
              _divLine(),
              const SizedBox(height: 10),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SmallStat(
                    value: '${_formatVol(data.totalVolume)} kg',
                    label: 'volume',
                    color: _green,
                  ),
                  _vDivider(),
                  _SmallStat(
                    value: '${data.totalSets}',
                    label: 'sets',
                    color: _blue,
                  ),
                  _vDivider(),
                  _SmallStat(
                    value: '${data.exerciseCount}',
                    label: 'exercises',
                    color: _blue,
                  ),
                  if (data.prExercises.isNotEmpty) ...[
                    _vDivider(),
                    _SmallStat(
                      value: '${data.prExercises.length}',
                      label: 'new PRs 🏆',
                      color: _amber,
                    ),
                  ],
                ],
              ),

              if (showQuote) ...[
                const SizedBox(height: 10),
                _divLine(),
                const SizedBox(height: 8),
                const Text(
                  'Another one in the books 💪',
                  style: TextStyle(
                      color: _sub, fontSize: 11, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'fittrack.app',
                    style: TextStyle(
                        color: _muted, fontSize: 9, letterSpacing: 1.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Widget _vDivider() => Container(
      width: 1,
      height: 28,
      color: _divider,
    );

class _SmallStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SmallStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: _muted, fontSize: 9)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template 3: Achievement
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final WorkoutShareData data;
  final bool showQuote;
  const _AchievementCard({required this.data, required this.showQuote});

  @override
  Widget build(BuildContext context) {
    final session = data.session;
    final hasPRs = data.prExercises.isNotEmpty;
    final date = DateFormat('EEE, MMM d, yyyy').format(session.startTime);
    final accentColor = hasPRs ? _amber : _blue;
    final bg2 = hasPRs ? const Color(0xFF1A1400) : _bg2;

    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bg1, bg2],
              ),
            ),
          ),
        ),

        // Central glow
        Positioned(
          top: -20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accentColor.withAlpha(hasPRs ? 40 : 25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ),

        // Dot pattern
        Positioned.fill(
          child: CustomPaint(painter: _DotPatternPainter()),
        ),

        // Bottom arc glow
        Positioned(
          bottom: -60,
          left: -60,
          right: -60,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  accentColor.withAlpha(20),
                ],
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _header(data),
              const Spacer(flex: 2),

              // Trophy / fist icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withAlpha(20),
                  border: Border.all(color: accentColor.withAlpha(60), width: 2),
                ),
                child: Center(
                  child: Text(
                    hasPRs ? '🏆' : '💪',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                hasPRs ? 'PERSONAL RECORDS' : 'CRUSHED IT',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                session.dayName.toUpperCase(),
                style: const TextStyle(
                  color: _white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),

              const Spacer(flex: 1),
              _divLine(),
              const Spacer(flex: 1),

              // PR list or stats
              if (hasPRs) ...[
                ...data.prExercises.take(5).map((name) {
                  final ex = session.exercises.firstWhere(
                    (e) => e.exerciseName.toLowerCase().trim() ==
                        name.toLowerCase().trim(),
                    orElse: () => session.exercises.first,
                  );
                  final maxW = ex.sets.isEmpty
                      ? 0.0
                      : ex.sets
                          .map((s) => s.weight)
                          .reduce((a, b) => a > b ? a : b);
                  final weightStr = ex.sets.any((s) => s.isBodyweight)
                      ? 'Bodyweight'
                      : maxW == maxW.floorToDouble()
                          ? '${maxW.toInt()} kg'
                          : '${maxW.toStringAsFixed(1)} kg';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _amber.withAlpha(12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _amber.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  color: _white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            weightStr,
                            style: const TextStyle(
                                color: _amber,
                                fontSize: 13,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                // No PRs — show stats grid instead
                Row(
                  children: [
                    Expanded(
                      child: _glassStatCard(
                        value: '${_formatVol(data.totalVolume)} kg',
                        label: 'Volume',
                        icon: Icons.bar_chart_rounded,
                        color: _green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _glassStatCard(
                        value: '${data.totalSets}',
                        label: 'Sets',
                        icon: Icons.repeat_rounded,
                        color: _blue,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(flex: 1),
              _divLine(),
              const SizedBox(height: 10),

              // Summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _muted, size: 11),
                  const SizedBox(width: 4),
                  Text(date,
                      style:
                          const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(width: 12),
                  const Icon(Icons.timer_outlined, color: _muted, size: 11),
                  const SizedBox(width: 4),
                  Text('${session.durationMinutes} min',
                      style:
                          const TextStyle(color: _muted, fontSize: 11)),
                ],
              ),

              if (showQuote) ...[
                const SizedBox(height: 10),
                Text(
                  hasPRs
                      ? '🔥 Records are made to be broken.'
                      : '💪 The grind never stops.',
                  style: const TextStyle(
                      color: _sub,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'fittrack.app',
                  style: TextStyle(
                      color: _muted, fontSize: 9, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot pattern background painter
// ─────────────────────────────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06FFFFFF)
      ..style = PaintingStyle.fill;

    const spacing = 22.0;
    const radius = 1.2;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        // Fade dots toward the center for a vignette effect
        final distFromCenter = math.sqrt(
          math.pow(x - size.width / 2, 2) + math.pow(y - size.height / 2, 2),
        );
        final maxDist = math.sqrt(
          math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2),
        );
        final alpha = (distFromCenter / maxDist).clamp(0.0, 1.0);
        paint.color = Color.fromRGBO(255, 255, 255, alpha * 0.06);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter oldDelegate) => false;
}
