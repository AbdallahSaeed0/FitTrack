import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/meal_log_model.dart';

// Box name constant
const _mealLogsBox = 'mealLogs';

// All meal logs for today
final todayMealLogsProvider = Provider<List<MealLog>>((ref) {
  final box = Hive.box<MealLog>(_mealLogsBox);
  final today = DateTime.now();
  return box.values.where((log) {
    final t = log.timestamp;
    return t.year == today.year && t.month == today.month && t.day == today.day;
  }).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
});

// All meal logs (for history)
final allMealLogsProvider = Provider<List<MealLog>>((ref) {
  final box = Hive.box<MealLog>(_mealLogsBox);
  return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

// Nutrition goals (daily targets)
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

// Water reminder toggle
final waterReminderEnabledProvider = StateProvider<bool>((ref) => true);

// Notifier for adding/removing meal logs
class MealLogsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addLog(MealLog log) async {
    final box = Hive.box<MealLog>(_mealLogsBox);
    await box.put(log.id, log);
    ref.invalidate(todayMealLogsProvider);
    ref.invalidate(allMealLogsProvider);
  }

  Future<void> deleteLog(String id) async {
    final box = Hive.box<MealLog>(_mealLogsBox);
    await box.delete(id);
    ref.invalidate(todayMealLogsProvider);
    ref.invalidate(allMealLogsProvider);
  }
}

final mealLogsNotifierProvider = NotifierProvider<MealLogsNotifier, void>(
  MealLogsNotifier.new,
);
