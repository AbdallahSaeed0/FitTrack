import 'package:hive/hive.dart';
import 'food_item_model.dart';

part 'meal_log_model.g.dart';

@HiveType(typeId: 8)
class MealLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String foodName;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final double calories;

  @HiveField(5)
  final double protein;

  @HiveField(6)
  final double carbs;

  @HiveField(7)
  final double fat;

  @HiveField(8)
  final String mealType; // breakfast, lunch, dinner, snack

  MealLog({
    required this.id,
    required this.timestamp,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
  });

  factory MealLog.fromFoodItem({
    required FoodItem food,
    required double quantity,
    required String mealType,
  }) {
    final f = food.withQuantity(quantity);
    return MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      foodName: food.displayName,
      quantity: quantity,
      calories: f.calories,
      protein: f.protein,
      carbs: f.carbs,
      fat: f.fat,
      mealType: mealType,
    );
  }
}
