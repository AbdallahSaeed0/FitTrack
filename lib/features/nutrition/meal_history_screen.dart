import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/meal_log_model.dart';
import 'nutrition_provider.dart';

class MealHistoryScreen extends ConsumerWidget {
  const MealHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(allMealLogsProvider);

    // Group by date
    final Map<String, List<MealLog>> grouped = {};
    for (final log in logs) {
      final key = DateFormat('yyyy-MM-dd').format(log.timestamp);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Meal History')),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'No meals logged yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dates.length,
              itemBuilder: (_, i) {
                final date = dates[i];
                final dayLogs = grouped[date]!;
                final totalCal = dayLogs.fold(0.0, (s, l) => s + l.calories);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${totalCal.toStringAsFixed(0)} kcal total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...dayLogs.map((log) => _HistoryCard(log: log)),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
    );
  }

  String _formatDate(String dateKey) {
    final dt = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(dt);
  }
}

class _HistoryCard extends ConsumerWidget {
  final MealLog log;

  const _HistoryCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        title: Text(
          log.foodName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${log.mealType[0].toUpperCase()}${log.mealType.substring(1)} · ${log.quantity.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${log.calories.toStringAsFixed(0)} kcal',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
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
        content: Text('Remove "${log.foodName}"?'),
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
}
