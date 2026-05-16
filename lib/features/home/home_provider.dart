import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/models/session_model.dart';

final sessionRepositoryProvider = Provider((_) => SessionRepository());

final recentSessionsProvider = Provider<List<WorkoutSessionModel>>((ref) {
  final repo = ref.read(sessionRepositoryProvider);
  return repo.getRecent(limit: 5);
});

final thisWeekSessionsProvider = Provider<List<WorkoutSessionModel>>((ref) {
  final repo = ref.read(sessionRepositoryProvider);
  return repo.getThisWeek();
});

final streakProvider = Provider<int>((ref) {
  final repo = ref.read(sessionRepositoryProvider);
  return repo.getConsecutiveWeeks();
});

class HomeRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

final homeRefreshProvider = NotifierProvider<HomeRefreshNotifier, int>(HomeRefreshNotifier.new);
