extension _NonZero on double {
  double? get nonZero => this == 0.0 ? null : this;
}

class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double servingSizeG;
  final String? barcode;
  final String source; // 'usda' or 'openfoodfacts'

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.servingSizeG,
    this.barcode,
    required this.source,
  });

  factory FoodItem.fromUsdaJson(Map<String, dynamic> json) {
    final nutrients = json['foodNutrients'] as List? ?? [];

    // Supports two formats:
    // 1. Official USDA API: {"nutrient": {"id": 1008}, "amount": 120}
    // 2. Custom bundled format: {"nutrientName": "Energy", "value": 120}
    double byId(int nutrientId) {
      try {
        final n = nutrients.firstWhere(
          (n) => n['nutrient'] != null && n['nutrient']['id'] == nutrientId,
          orElse: () => null,
        );
        return (n?['amount'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }

    double byName(String name) {
      try {
        final n = nutrients.firstWhere(
          (n) => (n['nutrientName'] as String?)
                  ?.toLowerCase()
                  .contains(name.toLowerCase()) ==
              true,
          orElse: () => null,
        );
        return (n?['value'] as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        return 0.0;
      }
    }

    // Try ID-based first (official USDA), fall back to name-based (bundled)
    final cal  = byId(1008).nonZero ?? byName('energy');
    final prot = byId(1003).nonZero ?? byName('protein');
    final carb = byId(1005).nonZero ?? byName('carbohydrate');
    final fat  = byId(1004).nonZero ?? byName('fat');
    final fib  = byId(1079).nonZero ?? byName('fiber');
    final sug  = byId(2000).nonZero ?? byName('sugar');

    return FoodItem(
      id: (json['fdcId'] ?? json['id'])?.toString() ?? '',
      name: json['description'] as String? ?? 'Unknown Food',
      brand: null,
      calories: cal,
      protein: prot,
      carbs: carb,
      fat: fat,
      fiber: fib,
      sugar: sug,
      servingSizeG: 100.0,
      source: 'usda',
    );
  }

  factory FoodItem.fromOpenFoodFactsJson(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    return FoodItem(
      id: json['code'] as String? ?? json['_id'] as String? ?? '',
      name: json['product_name'] as String? ?? 'Unknown Product',
      brand: json['brands'] as String?,
      calories: (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0.0,
      protein: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0.0,
      carbs: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0.0,
      fat: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0.0,
      fiber: (nutriments['fiber_100g'] as num?)?.toDouble() ?? 0.0,
      sugar: (nutriments['sugars_100g'] as num?)?.toDouble() ?? 0.0,
      servingSizeG: 100.0,
      barcode: json['code'] as String?,
      source: 'openfoodfacts',
    );
  }

  FoodItem withQuantity(double grams) {
    final m = grams / servingSizeG;
    return FoodItem(
      id: id,
      name: name,
      brand: brand,
      calories: calories * m,
      protein: protein * m,
      carbs: carbs * m,
      fat: fat * m,
      fiber: fiber * m,
      sugar: sugar * m,
      servingSizeG: grams,
      barcode: barcode,
      source: source,
    );
  }

  String get displayName => brand != null ? '$brand $name' : name;
}
