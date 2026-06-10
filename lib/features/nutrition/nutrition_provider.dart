import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/meal_log_model.dart';
import '../../data/repositories/meal_log_repository.dart';

final todayMealLogsProvider = Provider<List<MealLog>>((ref) {
  ref.watch(mealLogsRefreshProvider);
  return MealLogRepository.instance.getToday();
});

final allMealLogsProvider = Provider<List<MealLog>>((ref) {
  ref.watch(mealLogsRefreshProvider);
  return MealLogRepository.instance.getAll();
});

class NutritionGoals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionGoals({
    this.calories = 2200,
    this.protein = 160,
    this.carbs = 250,
    this.fat = 70,
  });
}

final dailyNutritionGoalsProvider = StateProvider<NutritionGoals>(
  (ref) => const NutritionGoals(),
);

final waterReminderEnabledProvider = StateProvider<bool>((ref) => true);

class MealLogsRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}

final mealLogsRefreshProvider =
    NotifierProvider<MealLogsRefreshNotifier, int>(MealLogsRefreshNotifier.new);

class MealLogsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addLog(MealLog log) async {
    await MealLogRepository.instance.add(log);
    ref.invalidate(mealLogsRefreshProvider);
  }

  Future<void> deleteLog(String id) async {
    await MealLogRepository.instance.delete(id);
    ref.invalidate(mealLogsRefreshProvider);
  }
}

final mealLogsNotifierProvider =
    NotifierProvider<MealLogsNotifier, void>(MealLogsNotifier.new);
