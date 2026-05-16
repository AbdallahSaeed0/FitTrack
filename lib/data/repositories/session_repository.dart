import '../models/session_model.dart';
import '../services/hive_service.dart';

class SessionRepository {
  List<WorkoutSessionModel> getAll() {
    return HiveService.sessions.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<WorkoutSessionModel> getRecent({int limit = 5}) {
    return getAll().take(limit).toList();
  }

  List<WorkoutSessionModel> getThisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    return getAll().where((s) => s.startTime.isAfter(start) && s.completed).toList();
  }

  List<WorkoutSessionModel> getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getAll().where((s) => s.startTime.isAfter(start) && s.completed).toList();
  }

  List<WorkoutSessionModel> getLast12Weeks() {
    final cutoff = DateTime.now().subtract(const Duration(days: 84));
    return getAll().where((s) => s.startTime.isAfter(cutoff) && s.completed).toList();
  }

  Future<void> save(WorkoutSessionModel session) async {
    await HiveService.sessions.put(session.id, session);
  }

  Future<void> delete(String id) async {
    await HiveService.sessions.delete(id);
  }

  WorkoutSessionModel? getById(String id) {
    return HiveService.sessions.get(id);
  }

  /// Returns the last [limit] completed sessions that contain [exerciseName],
  /// each as the list of sets logged for that exercise.
  List<({DateTime date, List<LoggedSetModel> sets})> getExerciseHistory(
    String exerciseName, {
    int limit = 5,
  }) {
    final result = <({DateTime date, List<LoggedSetModel> sets})>[];
    for (final session in getAll().where((s) => s.completed)) {
      for (final ex in session.exercises) {
        if (ex.exerciseName.toLowerCase().trim() ==
                exerciseName.toLowerCase().trim() &&
            ex.sets.isNotEmpty) {
          result.add((date: session.startTime, sets: ex.sets));
          break;
        }
      }
      if (result.length >= limit) break;
    }
    return result;
  }

  int getConsecutiveWeeks() {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 52; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final hasSession = HiveService.sessions.values.any(
        (s) => s.completed && s.startTime.isAfter(weekStart) && s.startTime.isBefore(weekEnd),
      );
      if (hasSession) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }
}
