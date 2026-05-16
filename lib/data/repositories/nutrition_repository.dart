import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/food_item_model.dart';

class NutritionRepository {
  List<FoodItem>? _cachedUsdaFoods;
  List<FoodItem>? _cachedOpenFoodFacts;

  Future<List<FoodItem>> loadAllFoods() async {
    if (_cachedUsdaFoods == null || _cachedOpenFoodFacts == null) {
      await _loadDatabases();
    }
    return [..._cachedUsdaFoods!, ..._cachedOpenFoodFacts!];
  }

  Future<void> _loadDatabases() async {
    _cachedUsdaFoods = await _loadUsda();
    _cachedOpenFoodFacts = await _loadOpenFoodFacts();
  }

  Future<List<FoodItem>> _loadUsda() async {
    try {
      final raw = await rootBundle.loadString('assets/data/usda_foods.json');
      final list = json.decode(raw) as List;
      return list
          .map((item) => FoodItem.fromUsdaJson(item as Map<String, dynamic>))
          .where((f) => f.name.isNotEmpty && f.calories > 0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<FoodItem>> _loadOpenFoodFacts() async {
    try {
      final raw = await rootBundle.loadString('assets/data/openfoodfacts.json');
      final list = json.decode(raw) as List;
      return list
          .map((item) => FoodItem.fromOpenFoodFactsJson(item as Map<String, dynamic>))
          .where((f) => f.name.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<FoodItem>> searchFoods(String query) async {
    final all = await loadAllFoods();
    if (query.isEmpty) return all; // show everything

    final q = query.toLowerCase();
    return all
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            (f.brand?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<FoodItem?> searchByBarcode(String barcode) async {
    final all = await loadAllFoods();
    try {
      return all.firstWhere((f) => f.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
}
