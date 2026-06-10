import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';

const _kPrefsKey = 'custom_exercises_v1';

/// Persists user-created custom exercises in SharedPreferences.
class CustomExerciseRepository {
  static CustomExerciseRepository? _instance;
  static CustomExerciseRepository get instance =>
      _instance ??= CustomExerciseRepository._();
  CustomExerciseRepository._();

  List<ExerciseModel>? _cache;

  Future<List<ExerciseModel>> loadAll() async {
    if (_cache != null) return _cache!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null) return _cache = [];
      final list = jsonDecode(raw) as List<dynamic>;
      _cache = list
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CustomExerciseRepo] load error: $e');
      _cache = [];
    }
    return _cache!;
  }

  Future<void> save(ExerciseModel exercise) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == exercise.id);
    if (idx >= 0) {
      all[idx] = exercise;
    } else {
      all.add(exercise);
    }
    _cache = all;
    await _persist(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    _cache = all;
    await _persist(all);
  }

  void invalidateCache() => _cache = null;

  Future<void> _persist(List<ExerciseModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kPrefsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('[CustomExerciseRepo] persist error: $e');
    }
  }
}
