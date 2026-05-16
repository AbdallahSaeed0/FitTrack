import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/meal_log_model.dart';
import 'nutrition_provider.dart';
import 'food_search_screen.dart';
import 'meal_history_screen.dart';

class NutritionHomeScreen extends ConsumerWidget {
  const NutritionHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogs = ref.watch(todayMealLogsProvider);
    final goals = ref.watch(dailyNutritionGoalsProvider);

    final totalCalories = todayLogs.fold(0.0, (s, l) => s + l.calories);
    final totalProtein = todayLogs.fold(0.0, (s, l) => s + l.protein);
    final totalCarbs = todayLogs.fold(0.0, (s, l) => s + l.carbs);
    final totalFat = todayLogs.fold(0.0, (s, l) => s + l.fat);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Nutrition",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _MacroProgress(
                    label: 'Calories',
                    current: totalCalories,
                    goal: goals.calories,
                    color: AppColors.primaryBlue,
                    unit: 'kcal',
                  ),
                  const SizedBox(height: 12),
                  _MacroProgress(
                    label: 'Protein',
                    current: totalProtein,
                    goal: goals.protein,
                    color: AppColors.growthGreen,
                    unit: 'g',
                  ),
                  const SizedBox(height: 12),
                  _MacroProgress(
                    label: 'Carbs',
                    current: totalCarbs,
                    goal: goals.carbs,
                    color: AppColors.energyOrange,
                    unit: 'g',
                  ),
                  const SizedBox(height: 12),
                  _MacroProgress(
                    label: 'Fat',
                    current: totalFat,
                    goal: goals.fat,
                    color: const Color(0xFFFCD34D),
                    unit: 'g',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log Food'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          if (todayLogs.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text("Today's Meals", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._buildMealSections(context, todayLogs),
          ],
        ],
      ),
    );
  }
}

List<Widget> _buildMealSections(BuildContext context, List<MealLog> logs) {
  const order = ['breakfast', 'lunch', 'dinner', 'snack'];
  final grouped = <String, List<MealLog>>{};
  for (final log in logs) {
    final key = log.mealType.toLowerCase();
    grouped.putIfAbsent(key, () => []).add(log);
  }

  final widgets = <Widget>[];
  for (final type in order) {
    final group = grouped[type];
    if (group == null || group.isEmpty) continue;
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Icon(_mealTypeIcon(type), size: 16, color: AppColors.activeDark),
            const SizedBox(width: 6),
            Text(
              _mealTypeLabel(type),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.activeDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: AppColors.activeDark.withAlpha(60), height: 1)),
          ],
        ),
      ),
    );
    for (final log in group) {
      widgets.add(_MealLogCard(log: log));
    }
  }
  // Any types not in the standard order
  for (final entry in grouped.entries) {
    if (order.contains(entry.key)) continue;
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Icon(Icons.restaurant_rounded, size: 16, color: AppColors.activeDark),
            const SizedBox(width: 6),
            Text(
              entry.key.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.activeDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
    for (final log in entry.value) {
      widgets.add(_MealLogCard(log: log));
    }
  }
  return widgets;
}

IconData _mealTypeIcon(String type) {
  switch (type) {
    case 'breakfast': return Icons.wb_sunny_rounded;
    case 'lunch':     return Icons.lunch_dining_rounded;
    case 'dinner':    return Icons.dinner_dining_rounded;
    case 'snack':     return Icons.fastfood_rounded;
    default:          return Icons.restaurant_rounded;
  }
}

String _mealTypeLabel(String type) {
  switch (type) {
    case 'breakfast': return 'BREAKFAST';
    case 'lunch':     return 'LUNCH';
    case 'dinner':    return 'DINNER';
    case 'snack':     return 'SNACK';
    default:          return type.toUpperCase();
  }
}

class _MacroProgress extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final String unit;

  const _MacroProgress({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
            Text(
              '${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withAlpha(50),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _MealLogCard extends ConsumerWidget {
  final MealLog log;

  const _MealLogCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.activeDark.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_mealIcon(log.mealType), color: AppColors.activeDark),
        ),
        title: Text(
          log.foodName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${log.quantity.toStringAsFixed(0)}g · ${log.calories.toStringAsFixed(0)} kcal',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('P: ${log.protein.toStringAsFixed(0)}g',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('C: ${log.carbs.toStringAsFixed(0)}g',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        onLongPress: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Remove Entry?'),
        content: Text('Remove "${log.foodName}" from today?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(mealLogsNotifierProvider.notifier).deleteLog(log.id);
    }
  }

  IconData _mealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snack':
        return Icons.fastfood_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }
}
