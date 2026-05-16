import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/food_item_model.dart';
import '../../data/models/meal_log_model.dart';
import 'nutrition_provider.dart';

class AddFoodDialog extends ConsumerStatefulWidget {
  final FoodItem food;

  const AddFoodDialog({super.key, required this.food});

  @override
  ConsumerState<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends ConsumerState<AddFoodDialog> {
  final _quantityController = TextEditingController(text: '100');
  String _mealType = 'lunch';

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(_quantityController.text) ?? 100.0;
    final preview = widget.food.withQuantity(quantity);

    return AlertDialog(
      title: const Text('Add Food'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.food.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity (grams)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mealType, // ignore: deprecated_member_use
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
              ),
              items: ['breakfast', 'lunch', 'dinner', 'snack']
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _mealType = v!),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition for ${quantity.toStringAsFixed(0)}g:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _Row('Calories', preview.calories, 'kcal'),
                  _Row('Protein', preview.protein, 'g'),
                  _Row('Carbs', preview.carbs, 'g'),
                  _Row('Fat', preview.fat, 'g'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final log = MealLog.fromFoodItem(
              food: widget.food,
              quantity: quantity,
              mealType: _mealType,
            );
            await ref.read(mealLogsNotifierProvider.notifier).addLog(log);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 44)),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _Row(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text('${value.toStringAsFixed(1)} $unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
