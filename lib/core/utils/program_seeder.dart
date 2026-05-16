import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/services/hive_service.dart';

/// Seeds Abdallah's Upper/Lower program from the bundled free-exercise-db JSON.
/// No network calls — instant, offline, reliable.
class ProgramSeeder {
  static const _uuid = Uuid();
  // Bump this when exercise names or gifUrl format changes so Hive data refreshes.
  static const _seederVersion = 3;

  static Future<void> seedIfEmpty() async {
    final settings = HiveService.settings;
    final storedVersion = settings.get('seederVersion', defaultValue: 0) as int;
    final repo = ProgramRepository();

    if (storedVersion >= _seederVersion && repo.getAll().isNotEmpty) return;

    // Version mismatch — clear the default Abdallah program and re-seed so
    // gifUrls from old API versions get replaced with free-exercise-db URLs.
    if (storedVersion < _seederVersion) {
      final programs = repo.getAll();
      for (final p in programs) {
        if (p.name == "Abdallah's Upper/Lower v2") {
          await repo.delete(p.id);
          debugPrint('[Seeder] Cleared stale program for re-seed (v$storedVersion → v$_seederVersion)');
        }
      }
    }

    await _seedAbdallahProgram();
    await settings.put('seederVersion', _seederVersion);
  }

  // ---------------------------------------------------------------------------
  // Helper — look up an exercise from the bundled JSON, apply program params.
  // Falls back to a placeholder if the name isn't found (never crashes).
  // ---------------------------------------------------------------------------
  static Future<ExerciseModel> _fetch(
    ExerciseRepository repo,
    String name, {
    int sets = 3,
    String repsFrom = '8',
    String repsTo = '12',
    String rest = '2-3 min',
  }) async {
    final result = await repo.getByExactName(name);
    if (result != null) {
      debugPrint('[Seeder] ✓ ${result.name}');
      return result.copyWith(
          sets: sets, repsFrom: repsFrom, repsTo: repsTo, restTime: rest);
    }
    debugPrint('[Seeder] ✗ placeholder for: $name');
    return ExerciseModel(
      id: _uuid.v4(),
      name: name,
      gifUrl: '',
      sets: sets,
      repsFrom: repsFrom,
      repsTo: repsTo,
      restTime: rest,
    );
  }

  // ---------------------------------------------------------------------------
  // Abdallah's Upper/Lower v2 — 4 days, 28 exercises total
  // ---------------------------------------------------------------------------
  static Future<void> _seedAbdallahProgram() async {
    final repo = ExerciseRepository();

    // ── Upper A ───────────────────────────────────────────────────────────────
    final upperA = <ExerciseModel>[
      await _fetch(repo, 'Barbell Bench Press - Medium Grip',
          sets: 4, repsFrom: '6', repsTo: '10', rest: '3 min'),
      await _fetch(repo, 'Wide-Grip Standing Barbell Curl',
          sets: 4, repsFrom: '6', repsTo: '10', rest: '3 min'),
      await _fetch(repo, 'Incline Dumbbell Press',
          sets: 3, repsFrom: '8', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Butterfly',
          sets: 3, repsFrom: '10', repsTo: '15', rest: '90 sec'),
      await _fetch(repo, 'Seated Cable Rows',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Cable Hammer Curls - Rope Attachment',
          sets: 3, repsFrom: '10', repsTo: '15', rest: '90 sec'),
      await _fetch(repo, 'Triceps Pushdown - Rope Attachment',
          sets: 3, repsFrom: '10', repsTo: '15', rest: '90 sec'),
    ];

    // ── Lower A ───────────────────────────────────────────────────────────────
    final lowerA = <ExerciseModel>[
      await _fetch(repo, 'Barbell Squat',
          sets: 4, repsFrom: '6', repsTo: '10', rest: '3 min'),
      await _fetch(repo, 'Romanian Deadlift',
          sets: 4, repsFrom: '8', repsTo: '12', rest: '2-3 min'),
      await _fetch(repo, 'Barbell Hack Squat',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Goblet Squat',
          sets: 3, repsFrom: '10', repsTo: '15', rest: '90 sec'),
      await _fetch(repo, 'Lying Leg Curls',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '90 sec'),
      await _fetch(repo, 'Standing Calf Raises',
          sets: 4, repsFrom: '12', repsTo: '20', rest: '60 sec'),
    ];

    // ── Upper B ───────────────────────────────────────────────────────────────
    final upperB = <ExerciseModel>[
      await _fetch(repo, 'Dumbbell Shoulder Press',
          sets: 4, repsFrom: '8', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Close-Grip Front Lat Pulldown',
          sets: 4, repsFrom: '8', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Barbell Bench Press - Medium Grip',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Elevated Cable Rows',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Cable Seated Lateral Raise',
          sets: 4, repsFrom: '12', repsTo: '15', rest: '60 sec'),
      await _fetch(repo, 'Face Pull',
          sets: 3, repsFrom: '12', repsTo: '15', rest: '60 sec'),
      await _fetch(repo, 'Alternate Incline Dumbbell Curl',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '90 sec'),
      await _fetch(repo, 'Triceps Pushdown',
          sets: 3, repsFrom: '12', repsTo: '15', rest: '90 sec'),
    ];

    // ── Lower B ───────────────────────────────────────────────────────────────
    final lowerB = <ExerciseModel>[
      await _fetch(repo, 'Romanian Deadlift',
          sets: 4, repsFrom: '8', repsTo: '12', rest: '2-3 min'),
      await _fetch(repo, 'Barbell Hip Thrust',
          sets: 4, repsFrom: '8', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Split Squat with Dumbbells',
          sets: 3, repsFrom: '8', repsTo: '12', rest: '2 min'),
      await _fetch(repo, 'Lying Leg Curls',
          sets: 3, repsFrom: '10', repsTo: '12', rest: '90 sec'),
      await _fetch(repo, 'Romanian Deadlift from Deficit',
          sets: 3, repsFrom: '12', repsTo: '15', rest: '90 sec'),
      await _fetch(repo, 'Seated Calf Raise',
          sets: 4, repsFrom: '12', repsTo: '20', rest: '60 sec'),
    ];

    final program = ProgramModel(
      id: _uuid.v4(),
      name: "Abdallah's Upper/Lower v2",
      isActive: true,
      splitType: 'upper_lower',
      goal: 'Muscle Building',
      experienceLevel: 'Intermediate',
      days: [
        WorkoutDayModel(
            id: _uuid.v4(), name: 'Upper A', dayNumber: 1, exercises: upperA),
        WorkoutDayModel(
            id: _uuid.v4(), name: 'Lower A', dayNumber: 2, exercises: lowerA),
        WorkoutDayModel(
            id: _uuid.v4(), name: 'Upper B', dayNumber: 3, exercises: upperB),
        WorkoutDayModel(
            id: _uuid.v4(), name: 'Lower B', dayNumber: 4, exercises: lowerB),
      ],
    );

    final programRepo = ProgramRepository();
    await programRepo.save(program);
    debugPrint(
        '[Seeder] Done — ${program.days.fold(0, (s, d) => s + d.exercises.length)} exercises saved.');
  }
}
