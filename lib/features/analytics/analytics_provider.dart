import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/session_model.dart';
import '../home/home_provider.dart';

class LiftData {
  final String exerciseName;
  final List<({DateTime date, double weight})> history;
  final double currentMax;
  final double previousMax;

  const LiftData({
    required this.exerciseName,
    required this.history,
    required this.currentMax,
    required this.previousMax,
  });

  double get trend => currentMax - previousMax;
}

final analyticsProvider = Provider<List<LiftData>>((ref) {
  final repo = ref.read(sessionRepositoryProvider);
  final sessions = repo.getLast12Weeks();

  const trackedExercises = [
    'barbell bench press',
    'barbell squat',
    'romanian deadlift',
    'pull up',
  ];

  return trackedExercises.map((name) {
    final history = <({DateTime date, double weight})>[];
    for (final session in sessions) {
      for (final ex in session.exercises) {
        if (ex.exerciseName.toLowerCase().contains(name.toLowerCase())) {
          double maxWeight = 0;
          for (final set in ex.sets) {
            if (set.weight > maxWeight) maxWeight = set.weight;
          }
          if (maxWeight > 0) {
            history.add((date: session.startTime, weight: maxWeight));
          }
        }
      }
    }
    history.sort((a, b) => a.date.compareTo(b.date));

    final currentMax = history.isNotEmpty ? history.last.weight : 0.0;
    final previousMax = history.length > 1 ? history[history.length - 2].weight : 0.0;

    return LiftData(
      exerciseName: name,
      history: history,
      currentMax: currentMax,
      previousMax: previousMax,
    );
  }).toList();
});

final weeklySessionsProvider = Provider<Map<int, int>>((ref) {
  final repo = ref.read(sessionRepositoryProvider);
  final sessions = repo.getLast12Weeks();
  final Map<int, int> weekCounts = {};
  final now = DateTime.now();

  for (final session in sessions) {
    final weeksAgo = now.difference(session.startTime).inDays ~/ 7;
    weekCounts[weeksAgo] = (weekCounts[weeksAgo] ?? 0) + 1;
  }
  return weekCounts;
});

final allSessionsProvider = Provider<List<WorkoutSessionModel>>((ref) {
  final repo = ref.read(sessionRepositoryProvider);
  return repo.getAll();
});
