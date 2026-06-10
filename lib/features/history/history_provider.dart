import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';
import '../home/home_provider.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class SessionSummary {
  final WorkoutSessionModel session;
  final double totalVolume;
  final int totalSets;
  final int exerciseCount;

  const SessionSummary({
    required this.session,
    required this.totalVolume,
    required this.totalSets,
    required this.exerciseCount,
  });
}

class WeekGroup {
  final DateTime weekStart;
  final List<SessionSummary> sessions;

  const WeekGroup({required this.weekStart, required this.sessions});

  double get totalVolume => sessions.fold(0.0, (s, e) => s + e.totalVolume);
  int get sessionCount => sessions.length;
}

class PersonalRecord {
  final String exerciseName;
  final double maxWeight;
  final int maxRepsAtMaxWeight;
  final double maxSessionVolume;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.exerciseName,
    required this.maxWeight,
    required this.maxRepsAtMaxWeight,
    required this.maxSessionVolume,
    required this.achievedAt,
  });
}

class AnalyticsSummary {
  final int totalWorkouts;
  final double totalVolume;
  final double avgDurationMinutes;
  final int streak;

  const AnalyticsSummary({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.avgDurationMinutes,
    required this.streak,
  });
}

class ExerciseProgression {
  final String exerciseName;
  final List<ExerciseProgressEntry> history;

  const ExerciseProgression({
    required this.exerciseName,
    required this.history,
  });

  double get allTimeMax => history.isEmpty
      ? 0.0
      : history.map((e) => e.maxWeight).reduce((a, b) => a > b ? a : b);
}

class ExerciseProgressEntry {
  final DateTime date;
  final double maxWeight;
  final double volume;
  final List<LoggedSetModel> sets;

  const ExerciseProgressEntry({
    required this.date,
    required this.maxWeight,
    required this.volume,
    required this.sets,
  });
}

// ── Internal helpers ──────────────────────────────────────────────────────────

SessionSummary _toSummary(WorkoutSessionModel s) {
  double vol = 0;
  int sets = 0;
  for (final ex in s.exercises) {
    for (final set in ex.sets) {
      vol += set.weight * set.reps;
      sets++;
    }
  }
  return SessionSummary(
    session: s,
    totalVolume: vol,
    totalSets: sets,
    exerciseCount: s.exercises.length,
  );
}

DateTime _weekStart(DateTime d) {
  final mon = d.subtract(Duration(days: d.weekday - 1));
  return DateTime(mon.year, mon.month, mon.day);
}

class _PRAccum {
  final String exerciseName;
  double maxWeight = 0;
  int maxRepsAtMax = 0;
  double maxVol = 0;
  DateTime achievedAt = DateTime.fromMillisecondsSinceEpoch(0);

  _PRAccum(this.exerciseName);

  void process(DateTime date, List<LoggedSetModel> sets) {
    double vol = 0;
    for (final s in sets) {
      vol += s.weight * s.reps;
      if (s.weight > maxWeight ||
          (s.weight == maxWeight && s.reps > maxRepsAtMax)) {
        maxWeight = s.weight;
        maxRepsAtMax = s.reps;
        achievedAt = date;
      }
    }
    if (vol > maxVol) maxVol = vol;
  }

  PersonalRecord toRecord() => PersonalRecord(
        exerciseName: exerciseName,
        maxWeight: maxWeight,
        maxRepsAtMaxWeight: maxRepsAtMax,
        maxSessionVolume: maxVol,
        achievedAt: achievedAt,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final allSessionSummariesProvider = Provider<List<SessionSummary>>((ref) {
  ref.watch(homeRefreshProvider);
  return SessionRepository.instance
      .getAll()
      .where((s) => s.completed)
      .map(_toSummary)
      .toList();
});

final historyGroupedProvider = Provider<List<WeekGroup>>((ref) {
  final summaries = ref.watch(allSessionSummariesProvider);
  final Map<DateTime, List<SessionSummary>> map = {};
  for (final s in summaries) {
    final week = _weekStart(s.session.startTime);
    map.putIfAbsent(week, () => []).add(s);
  }
  return map.entries
      .map((e) => WeekGroup(weekStart: e.key, sessions: e.value))
      .toList()
    ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
});

final personalRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  ref.watch(homeRefreshProvider);
  final sessions =
      SessionRepository.instance.getAll().where((s) => s.completed);

  final Map<String, _PRAccum> acc = {};
  for (final session in sessions) {
    for (final ex in session.exercises) {
      final key = ex.exerciseName.trim().toLowerCase();
      acc.putIfAbsent(key, () => _PRAccum(ex.exerciseName.trim()));
      acc[key]!.process(session.startTime, ex.sets);
    }
  }

  return acc.values
      .where((a) => a.maxWeight > 0)
      .map((a) => a.toRecord())
      .toList()
    ..sort((a, b) =>
        a.exerciseName.toLowerCase().compareTo(b.exerciseName.toLowerCase()));
});

enum AnalyticsPeriod { week, month, allTime }

final analyticsSummaryProvider =
    Provider.family<AnalyticsSummary, AnalyticsPeriod>((ref, period) {
  ref.watch(homeRefreshProvider);
  final repo = SessionRepository.instance;

  final List<WorkoutSessionModel> sessions;
  switch (period) {
    case AnalyticsPeriod.week:
      sessions = repo.getThisWeek();
      break;
    case AnalyticsPeriod.month:
      sessions = repo.getThisMonth();
      break;
    case AnalyticsPeriod.allTime:
      sessions = repo.getAll().where((s) => s.completed).toList();
      break;
  }

  double totalVol = 0;
  int totalDur = 0;
  for (final s in sessions) {
    for (final ex in s.exercises) {
      for (final set in ex.sets) {
        totalVol += set.weight * set.reps;
      }
    }
    totalDur += s.durationMinutes;
  }

  return AnalyticsSummary(
    totalWorkouts: sessions.length,
    totalVolume: totalVol,
    avgDurationMinutes: sessions.isEmpty ? 0.0 : totalDur / sessions.length,
    streak: repo.getConsecutiveWeeks(),
  );
});

final exerciseProgressionProvider =
    Provider.family<ExerciseProgression, String>((ref, exerciseName) {
  ref.watch(homeRefreshProvider);
  final sessions =
      SessionRepository.instance.getAll().where((s) => s.completed);
  final history = <ExerciseProgressEntry>[];

  for (final session in sessions) {
    for (final ex in session.exercises) {
      if (ex.exerciseName.toLowerCase().trim() ==
              exerciseName.toLowerCase().trim() &&
          ex.sets.isNotEmpty) {
        double maxW = 0;
        double vol = 0;
        for (final set in ex.sets) {
          if (set.weight > maxW) maxW = set.weight;
          vol += set.weight * set.reps;
        }
        history.add(ExerciseProgressEntry(
          date: session.startTime,
          maxWeight: maxW,
          volume: vol,
          sets: ex.sets,
        ));
        break; // one entry per session
      }
    }
  }

  history.sort((a, b) => a.date.compareTo(b.date));
  return ExerciseProgression(exerciseName: exerciseName, history: history);
});

// Finds the previous completed session for the same workout day name.
final previousSessionProvider =
    Provider.family<WorkoutSessionModel?, String>((ref, sessionId) {
  ref.watch(homeRefreshProvider);
  final session = SessionRepository.instance.getById(sessionId);
  if (session == null) return null;

  final candidates = SessionRepository.instance
      .getAll()
      .where((s) =>
          s.completed &&
          s.id != sessionId &&
          s.dayName.toLowerCase() == session.dayName.toLowerCase());

  return candidates.isEmpty ? null : candidates.first;
});

// Historical max weight for an exercise across all completed sessions.
double historicalMaxForExercise(String exerciseName) {
  double max = 0;
  final history = SessionRepository.instance
      .getExerciseHistory(exerciseName, limit: 500);
  for (final entry in history) {
    for (final s in entry.sets) {
      if (s.weight > max) max = s.weight;
    }
  }
  return max;
}
