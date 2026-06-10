import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/program_repository.dart';

final programRepositoryProvider =
    Provider((_) => ProgramRepository.instance);
final exerciseRepositoryProvider = Provider((_) => ExerciseRepository());

final programsProvider =
    NotifierProvider<ProgramsNotifier, List<ProgramModel>>(
  ProgramsNotifier.new,
);

class ProgramsNotifier extends Notifier<List<ProgramModel>> {
  @override
  List<ProgramModel> build() => ProgramRepository.instance.getAll();

  void refresh() => state = ProgramRepository.instance.getAll();

  /// Re-looks up every exercise in every program by name and patches
  /// the stored gifUrl when the repository has a better URL available.
  ///
  /// Patching rules:
  ///  - Current gifUrl is empty → always patch
  ///  - Current gifUrl starts with 'assets/' (Kaggle local GIF) → keep as-is
  ///  - Current gifUrl is a network URL but the repo now has a different
  ///    (fixed/updated) URL → patch
  Future<int> refreshExerciseImages() async {
    final repo = ExerciseRepository();
    final programs = ProgramRepository.instance.getAll();
    int patched = 0;

    for (final program in programs) {
      bool programChanged = false;
      final updatedDays = await Future.wait(program.days.map((day) async {
        bool dayChanged = false;
        final updatedExercises =
            await Future.wait(day.exercises.map((ex) async {
          // Never touch exercises that already have a local Kaggle GIF.
          if (ex.gifUrl.startsWith('assets/')) return ex;

          final found = await repo.getByExactName(ex.name);
          if (found == null || found.gifUrl.isEmpty) return ex;

          // Patch if empty OR if the URL changed (old broken → new fixed).
          if (ex.gifUrl.isEmpty || ex.gifUrl != found.gifUrl) {
            dayChanged = true;
            programChanged = true;
            patched++;
            return ex.copyWith(gifUrl: found.gifUrl);
          }
          return ex;
        }));
        return dayChanged ? day.copyWith(exercises: updatedExercises) : day;
      }));

      if (programChanged) {
        await ProgramRepository.instance
            .save(program.copyWith(days: updatedDays));
      }
    }

    state = ProgramRepository.instance.getAll();
    return patched;
  }

  Future<void> addProgram(ProgramModel program) async {
    await ProgramRepository.instance.save(program);
    state = ProgramRepository.instance.getAll();
  }

  Future<void> updateProgram(ProgramModel program) async {
    await ProgramRepository.instance.save(program);
    state = ProgramRepository.instance.getAll();
  }

  Future<void> deleteProgram(String id) async {
    await ProgramRepository.instance.delete(id);
    state = ProgramRepository.instance.getAll();
  }

  Future<void> setActive(String id) async {
    await ProgramRepository.instance.setActive(id);
    state = ProgramRepository.instance.getAll();
  }

  ProgramModel? getActive() => ProgramRepository.instance.getActive();

  ProgramModel? getById(String id) => ProgramRepository.instance.getById(id);
}

final activeProgramProvider = Provider<ProgramModel?>((ref) {
  final programs = ref.watch(programsProvider);
  try {
    return programs.firstWhere((p) => p.isActive);
  } catch (_) {
    return null;
  }
});

class ProgramGeneratorService {
  final ExerciseRepository _repo;
  final _uuid = const Uuid();

  ProgramGeneratorService(this._repo);

  Future<ProgramModel> generateFromTemplate({
    required String name,
    required String splitType,
    required String goal,
    required String experienceLevel,
    required int daysPerWeek,
    required List<String> techniques,
  }) async {
    final days = <WorkoutDayModel>[];

    if (splitType == 'upper_lower') {
      days.addAll(await _buildUpperLower(daysPerWeek));
    } else if (splitType == 'push_pull_legs') {
      days.addAll(await _buildPPL(daysPerWeek));
    } else if (splitType == 'full_body') {
      days.addAll(await _buildFullBody(daysPerWeek));
    }

    return ProgramModel(
      id: _uuid.v4(),
      name: name,
      splitType: splitType,
      goal: goal,
      experienceLevel: experienceLevel,
      techniques: techniques,
      days: days,
    );
  }

  Future<List<WorkoutDayModel>> _buildUpperLower(int daysPerWeek) async {
    final chest = await _repo.getSimilarExercises('chest', limit: 8);
    final back = await _repo.getSimilarExercises('back', limit: 8);
    final shoulders = await _repo.getSimilarExercises('shoulders', limit: 6);
    final upperLegs =
        await _repo.getSimilarExercises('upper legs', limit: 10);
    final lowerLegs =
        await _repo.getSimilarExercises('lower legs', limit: 4);

    return [
      _buildDay(0, 'Upper A',
          [..._pick(chest, 3), ..._pick(back, 3), ..._pick(shoulders, 2)]),
      _buildDay(
          1, 'Lower A', [..._pick(upperLegs, 4), ..._pick(lowerLegs, 2)]),
      _buildDay(2, 'Upper B',
          [..._pick(chest, 2), ..._pick(back, 3), ..._pick(shoulders, 3)]),
      _buildDay(
          3, 'Lower B', [..._pick(upperLegs, 4), ..._pick(lowerLegs, 2)]),
    ];
  }

  Future<List<WorkoutDayModel>> _buildPPL(int daysPerWeek) async {
    final chest = await _repo.getSimilarExercises('chest', limit: 6);
    final shoulders =
        await _repo.getSimilarExercises('shoulders', limit: 5);
    final upperArms =
        await _repo.getSimilarExercises('upper arms', limit: 8);
    final back = await _repo.getSimilarExercises('back', limit: 6);
    final upperLegs =
        await _repo.getSimilarExercises('upper legs', limit: 8);
    final lowerLegs =
        await _repo.getSimilarExercises('lower legs', limit: 4);

    final triceps = upperArms
        .where((e) =>
            e.name.toLowerCase().contains('tricep') ||
            e.name.toLowerCase().contains('pushdown') ||
            e.name.toLowerCase().contains('extension'))
        .toList();
    final biceps = upperArms
        .where((e) =>
            e.name.toLowerCase().contains('curl') ||
            e.name.toLowerCase().contains('bicep'))
        .toList();
    final armsRest = upperArms
        .where((e) => !triceps.contains(e) && !biceps.contains(e))
        .toList();

    return [
      _buildDay(0, 'Push', [
        ..._pick(chest, 3),
        ..._pick(shoulders, 2),
        ..._pick(triceps.isNotEmpty ? triceps : armsRest, 2),
      ]),
      _buildDay(1, 'Pull', [
        ..._pick(back, 4),
        ..._pick(biceps.isNotEmpty ? biceps : armsRest, 3),
      ]),
      _buildDay(
          2, 'Legs', [..._pick(upperLegs, 4), ..._pick(lowerLegs, 2)]),
    ];
  }

  Future<List<WorkoutDayModel>> _buildFullBody(int daysPerWeek) async {
    final chest = await _repo.getSimilarExercises('chest', limit: 5);
    final back = await _repo.getSimilarExercises('back', limit: 5);
    final upperLegs =
        await _repo.getSimilarExercises('upper legs', limit: 5);
    final shoulders =
        await _repo.getSimilarExercises('shoulders', limit: 4);

    final exercises = [
      ..._pick(chest, 2),
      ..._pick(back, 2),
      ..._pick(upperLegs, 2),
      ..._pick(shoulders, 1),
    ];
    return [
      _buildDay(0, 'Full Body A', exercises),
      _buildDay(1, 'Full Body B', exercises.reversed.toList()),
      _buildDay(2, 'Full Body C', exercises),
    ];
  }

  WorkoutDayModel _buildDay(
      int index, String name, List<ExerciseModel> exercises) {
    return WorkoutDayModel(
      id: const Uuid().v4(),
      name: name,
      dayNumber: index + 1,
      exercises: exercises
          .map((e) => e.copyWith(sets: 3, repsFrom: '8', repsTo: '12'))
          .toList(),
    );
  }

  List<ExerciseModel> _pick(List<ExerciseModel> list, int count) {
    if (list.isEmpty) return [];
    return list
        .where((e) {
          final n = e.name.toLowerCase();
          return !n.contains('dip') &&
              !n.contains('deadlift') &&
              !n.contains('barbell row');
        })
        .take(count)
        .toList();
  }
}

final programGeneratorProvider = Provider((ref) {
  return ProgramGeneratorService(ref.read(exerciseRepositoryProvider));
});
