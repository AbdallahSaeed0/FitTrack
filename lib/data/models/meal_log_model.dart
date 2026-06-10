import 'food_item_model.dart';

class MealLog {
  final String id;
  final DateTime timestamp;
  final String foodName;
  final double quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;

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

  Map<String, dynamic> toRow(String userId) => {
        'id': id,
        'user_id': userId,
        'timestamp': timestamp.toIso8601String(),
        'food_name': foodName,
        'quantity': quantity,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal_type': mealType,
      };

  factory MealLog.fromRow(Map<String, dynamic> row) => MealLog(
        id: row['id'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String),
        foodName: row['food_name'] as String,
        quantity: (row['quantity'] as num).toDouble(),
        calories: (row['calories'] as num).toDouble(),
        protein: (row['protein'] as num).toDouble(),
        carbs: (row['carbs'] as num).toDouble(),
        fat: (row['fat'] as num).toDouble(),
        mealType: row['meal_type'] as String,
      );
}
