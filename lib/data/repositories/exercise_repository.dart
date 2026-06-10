import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';
import '../models/free_exercise_entry.dart';
import 'custom_exercise_repository.dart';

/// Exercise repository with Kaggle-first loading.
/// Tries assets/exercises/data.json (Kaggle, 1500+ GIFs) first;
/// falls back to assets/data/exercises.json (free-exercise-db, 873 exercises).
class ExerciseRepository {
  static List<ExerciseModel>? _cache;

  /// Call this to force a reload (e.g. after asset changes or adding custom exercises).
  static void clearCache() {
    _cache = null;
    CustomExerciseRepository.instance.invalidateCache();
  }

  Future<List<ExerciseModel>> _loadAll() async {
    if (_cache != null) return _cache!;

    // ── 1. Load Kaggle sample (local GIFs) ────────────────────────────────
    final Map<String, ExerciseModel> byName = {};
    try {
      final raw =
          await rootBundle.loadString('assets/exercises/gifs/exercises.json');
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final ex = _fromKaggle(e as Map<String, dynamic>);
        if (ex.id.isNotEmpty && ex.name.isNotEmpty) {
          byName[ex.name.toLowerCase().trim()] = ex;
        }
      }
      debugPrint('[ExerciseRepo] Kaggle: ${byName.length} exercises with local GIFs');
    } catch (_) {
      // No Kaggle data — that's fine, free-exercise-db covers everything
    }

    // ── 2. Load free-exercise-db and fill gaps ────────────────────────────
    try {
      final raw = await rootBundle.loadString('assets/data/exercises.json');
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final entry = FreeExerciseEntry.fromJson(e as Map<String, dynamic>);
        if (entry.name.isEmpty) continue;
        final key = entry.name.toLowerCase().trim();
        if (!byName.containsKey(key)) {
          byName[key] = entry.toExerciseModel();
        }
      }
    } catch (err) {
      debugPrint('[ExerciseRepo] free-exercise-db load error: $err');
    }

    // ── 3. Load supplementary exercises (extra_exercises.json) ────────────
    try {
      final raw =
          await rootBundle.loadString('assets/data/extra_exercises.json');
      final list = jsonDecode(raw) as List<dynamic>;
      int added = 0;
      for (final e in list) {
        final entry = FreeExerciseEntry.fromJson(e as Map<String, dynamic>);
        if (entry.name.isEmpty) continue;
        final key = entry.name.toLowerCase().trim();
        // Extra exercises may override free-exercise-db (better data) but
        // not Kaggle (which already has a local GIF).
        if (!byName.containsKey(key) ||
            byName[key]!.gifUrl.isEmpty) {
          byName[key] = entry.toExerciseModel();
          added++;
        }
      }
      debugPrint('[ExerciseRepo] Extra: $added new exercises added');
    } catch (err) {
      debugPrint('[ExerciseRepo] extra_exercises load error: $err');
    }

    // ── 4. Merge custom user-created exercises (fallback for anything still missing) ──
    try {
      final custom = await CustomExerciseRepository.instance.loadAll();
      for (final ex in custom) {
        byName[ex.name.toLowerCase().trim()] = ex;
      }
      if (custom.isNotEmpty) {
        debugPrint('[ExerciseRepo] Custom: ${custom.length} user exercises merged');
      }
    } catch (_) {}

    _cache = byName.values.toList();
    debugPrint('[ExerciseRepo] Total: ${_cache!.length} exercises loaded');
    return _cache!;
  }

  static ExerciseModel _fromKaggle(Map<String, dynamic> json) {
    final rawGif = json['gifUrl']?.toString() ?? '';
    final gifUrl = rawGif.startsWith('assets/')
        ? rawGif
        : 'assets/exercises/gifs/gifs_360x360/$rawGif';

    return ExerciseModel(
      id: json['exerciseId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gifUrl: gifUrl,
      targetMuscles: List<String>.from(json['targetMuscles'] ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      bodyParts: List<String>.from(json['bodyParts'] ?? []),
      equipments: List<String>.from(json['equipments'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }

  /// Search by name, equipment, or primary muscle.
  Future<List<ExerciseModel>> searchByName(String query,
      {int limit = 25}) async {
    if (query.trim().isEmpty) return [];
    final all = await _loadAll();
    final q = query.toLowerCase().trim();
    return all
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.equipments.any((eq) => eq.toLowerCase().contains(q)) ||
            e.targetMuscles.any((m) => m.toLowerCase().contains(q)) ||
            e.bodyParts.any((b) => b.toLowerCase().contains(q)))
        .take(limit)
        .toList();
  }

  /// Returns exercises targeting the same muscle group as [bodyPart].
  Future<List<ExerciseModel>> getSimilarExercises(String bodyPart,
      {int limit = 25}) async {
    final all = await _loadAll();
    final terms = _expandMuscleGroup(bodyPart.toLowerCase().trim());

    final results = all.where((e) {
      return e.targetMuscles.any((m) {
        final ml = m.toLowerCase();
        return terms.any((t) => ml.contains(t) || t.contains(ml));
      }) ||
          e.bodyParts.any((b) {
            final bl = b.toLowerCase();
            return terms.any((t) => bl.contains(t) || t.contains(bl));
          });
    }).take(limit).toList();

    if (results.isEmpty) {
      return all
          .where((e) => e.bodyParts
              .any((b) => b.toLowerCase() == bodyPart.toLowerCase()))
          .take(limit)
          .toList();
    }
    return results;
  }

  /// Looks up an exercise by name (exact → partial → word-by-word).
  Future<ExerciseModel?> getByExactName(String name) async {
    final all = await _loadAll();
    final lower = name.toLowerCase().trim();

    for (final e in all) {
      if (e.name.toLowerCase() == lower) return e;
    }
    for (final e in all) {
      final n = e.name.toLowerCase();
      if (n.contains(lower) || lower.contains(n)) return e;
    }
    final words = lower.split(' ').where((w) => w.length > 3).toList();
    if (words.isNotEmpty) {
      for (final e in all) {
        final n = e.name.toLowerCase();
        if (words.every((w) => n.contains(w))) return e;
      }
    }
    return null;
  }

  static List<String> _expandMuscleGroup(String bodyPart) {
    const map = <String, List<String>>{
      'upper legs': [
        'quadriceps', 'hamstrings', 'glutes', 'hip flexors', 'quads',
        'upper legs', 'adductors', 'abductors',
      ],
      'lower legs': [
        'calves', 'gastrocnemius', 'soleus', 'tibialis anterior', 'lower legs',
      ],
      'upper arms': [
        'biceps brachii', 'triceps brachii', 'biceps', 'triceps', 'upper arms',
      ],
      'lower arms': ['forearms', 'brachioradialis', 'lower arms'],
      'back': [
        // Kaggle terms
        'latissimus dorsi', 'lats', 'upper back', 'rhomboids', 'trapezius',
        // free-exercise-db primaryMuscles terms  ← was missing these
        'middle back', 'lower back', 'traps', 'back',
      ],
      'chest': ['chest', 'pectorals', 'pectoralis'],
      'shoulders': [
        'anterior deltoid', 'lateral deltoid', 'rear deltoid',
        'deltoid', 'deltoids',
        // free-exercise-db uses 'shoulders' and 'delts'
        'shoulders', 'delts',
      ],
      'waist': ['abdominals', 'obliques', 'core', 'abs', 'waist'],
      'cardio': ['cardiovascular system', 'cardio'],
      'neck': ['neck', 'sternocleidomastoid'],
    };
    return map[bodyPart] ?? [bodyPart];
  }

  // Legacy stubs kept for backward compat
  ExerciseModel? getCachedById(String id) => null;
  List<ExerciseModel> getAllCached() => [];
  Future<FreeExerciseEntry?> getEntryById(String id) async => null;
}
