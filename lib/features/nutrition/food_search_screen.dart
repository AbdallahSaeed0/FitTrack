import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/food_item_model.dart';
import '../../data/repositories/nutrition_repository.dart';
import 'add_food_dialog.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchController = TextEditingController();
  final _repo = NutritionRepository();
  List<FoodItem> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() => _loading = true);
    final results = await _repo.searchFoods(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Food')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _load('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                if (v.length >= 2 || v.isEmpty) _load(v);
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'No foods found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) => _FoodResultCard(
                          food: _results[i],
                          onTap: () => _showAdd(_results[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAdd(FoodItem food) {
    showDialog(
      context: context,
      builder: (_) => AddFoodDialog(food: food),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }
}

class _FoodResultCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;

  const _FoodResultCard({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUsda = food.source == 'usda';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isUsda ? AppColors.primaryBlue : AppColors.growthGreen).withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restaurant_rounded,
            color: isUsda ? AppColors.primaryBlue : AppColors.growthGreen,
          ),
        ),
        title: Text(
          food.displayName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Per 100g: ${food.calories.toStringAsFixed(0)} kcal · P: ${food.protein.toStringAsFixed(1)}g · C: ${food.carbs.toStringAsFixed(1)}g',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBlue),
      ),
    );
  }
}
