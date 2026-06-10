import '../../data/models/muscle_groups.dart';
import '../../data/models/muscle_intensity_model.dart';
import '../../data/repositories/session_repository.dart';

class MuscleAnalyticsService {
  const MuscleAnalyticsService();

  Map<MuscleGroup, int> _calculateMuscleWorkouts(DateTime startDate, DateTime endDate) {
    final sessions = SessionRepository.instance.getAll().where((s) {
      return s.completed &&
          !s.startTime.isBefore(startDate) &&
          !s.startTime.isAfter(endDate);
    });

    final muscleCount = <MuscleGroup, int>{};

    for (final session in sessions) {
      for (final exercise in session.exercises) {
        final name = exercise.exerciseName;
        final primary = MuscleGroupExtension.fromApiString(name);
        if (primary != null) {
          muscleCount[primary] = (muscleCount[primary] ?? 0) + 2;
        }
        // Also parse from exercise name keywords
        for (final muscle in MuscleGroup.values) {
          if (name.toLowerCase().contains(muscle.displayName.toLowerCase())) {
            muscleCount[muscle] = (muscleCount[muscle] ?? 0) + 1;
          }
        }
      }
    }

    return muscleCount;
  }

  List<MuscleIntensity> getIntensities(DateTime startDate, DateTime endDate) {
    final counts = _calculateMuscleWorkouts(startDate, endDate);
    return MuscleGroup.values
        .where((m) => m != MuscleGroup.fullBody)
        .map((m) => MuscleIntensity(
              muscle: m,
              workoutCount: counts[m] ?? 0,
            ))
        .toList();
  }

  List<MuscleIntensity> getThisWeek() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return getIntensities(
      DateTime(start.year, start.month, start.day),
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  List<MuscleIntensity> getThisMonth() {
    final now = DateTime.now();
    return getIntensities(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  List<MuscleIntensity> getThisYear() {
    final now = DateTime.now();
    return getIntensities(
      DateTime(now.year, 1, 1),
      DateTime(now.year, 12, 31, 23, 59, 59),
    );
  }
}
