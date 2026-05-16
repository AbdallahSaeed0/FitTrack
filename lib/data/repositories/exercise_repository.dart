import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';
import '../models/free_exercise_entry.dart';

/// Offline exercise repository backed by the bundled free-exercise-db JSON.
/// 873 exercises, zero API calls, works with no internet connection.
class ExerciseRepository {
  // In-memory cache shared across all instances (static so it's loaded once)
  static List<FreeExerciseEntry>? _cache;

  Future<List<FreeExerciseEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => FreeExerciseEntry.fromJson(e as Map<String, dynamic>))
        .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
        .toList();
    return _cache!;
  }

  /// Search by name, equipment, or primary muscle. Returns up to [limit] results.
  Future<List<ExerciseModel>> searchByName(String query,
      {int limit = 25}) async {
    if (query.trim().isEmpty) return [];
    final all = await _loadAll();
    final q = query.toLowerCase().trim();
    return all
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            (e.equipment?.toLowerCase().contains(q) ?? false) ||
            e.primaryMuscles.any((m) => m.toLowerCase().contains(q)))
        .take(limit)
        .map((e) => e.toExerciseModel())
        .toList();
  }

  /// Returns exercises targeting the same muscle group as [bodyPart].
  /// Handles both free-exercise-db muscle names ("chest", "quadriceps") and
  /// the older body-part labels ("upper legs", "upper arms", etc.).
  Future<List<ExerciseModel>> getSimilarExercises(String bodyPart,
      {int limit = 25}) async {
    final all = await _loadAll();
    final terms = _expandMuscleGroup(bodyPart.toLowerCase().trim());

    final results = all.where((e) {
      return e.primaryMuscles.any((m) {
        final ml = m.toLowerCase();
        return terms.any((t) => ml.contains(t) || t.contains(ml));
      });
    }).take(limit).map((e) => e.toExerciseModel()).toList();

    // Fallback: match by category (e.g. "cardio")
    if (results.isEmpty) {
      return all
          .where((e) => e.category.toLowerCase() == bodyPart.toLowerCase())
          .take(limit)
          .map((e) => e.toExerciseModel())
          .toList();
    }
    return results;
  }

  /// Looks up an exercise by name (exact → partial → word-by-word).
  /// Used by the program seeder to fetch full exercise data.
  Future<ExerciseModel?> getByExactName(String name) async {
    final all = await _loadAll();
    final lower = name.toLowerCase().trim();

    // 1. Exact match
    for (final e in all) {
      if (e.name.toLowerCase() == lower) return e.toExerciseModel();
    }

    // 2. One contains the other
    for (final e in all) {
      final n = e.name.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return e.toExerciseModel();
    }

    // 3. Every significant word from the query appears in the entry name
    final words =
        lower.split(' ').where((w) => w.length > 3).toList();
    if (words.isNotEmpty) {
      for (final e in all) {
        final n = e.name.toLowerCase();
        if (words.every((w) => n.contains(w))) return e.toExerciseModel();
      }
    }

    return null;
  }

  /// Returns the raw [FreeExerciseEntry] for [id] so callers can get full
  /// image URL lists for the animated detail view.
  Future<FreeExerciseEntry?> getEntryById(String id) async {
    final all = await _loadAll();
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Muscle-group expansion — maps old body-part labels to free-exercise-db
  // primaryMuscle terminology so "upper legs" still finds quad/hamstring exercises.
  // ---------------------------------------------------------------------------
  static List<String> _expandMuscleGroup(String bodyPart) {
    const map = <String, List<String>>{
      'upper legs': ['quadriceps', 'hamstrings', 'glutes', 'hip flexors'],
      'lower legs': ['calves', 'gastrocnemius', 'soleus', 'tibialis anterior'],
      'upper arms': ['biceps brachii', 'triceps brachii', 'biceps', 'triceps'],
      'lower arms': ['forearms', 'brachioradialis'],
      'back': [
        'latissimus dorsi',
        'rhomboids',
        'lower back',
        'upper back',
        'traps',
        'trapezius',
      ],
      'chest': ['chest', 'pectorals', 'pectoralis'],
      'shoulders': [
        'anterior deltoid',
        'lateral deltoid',
        'rear deltoid',
        'deltoid',
        'deltoids',
      ],
      'waist': ['abdominals', 'obliques', 'core'],
      'cardio': ['cardiovascular system'],
    };
    return map[bodyPart] ?? [bodyPart];
  }

  // ---------------------------------------------------------------------------
  // Legacy compatibility stubs (previously Hive-backed, now unused)
  // ---------------------------------------------------------------------------
  ExerciseModel? getCachedById(String id) => null;
  List<ExerciseModel> getAllCached() => [];
}
