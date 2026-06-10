import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';

class WizardDay {
  final String name;
  final List<ExerciseModel> exercises;
  const WizardDay({required this.name, this.exercises = const []});
  WizardDay copyWith({String? name, List<ExerciseModel>? exercises}) =>
      WizardDay(name: name ?? this.name, exercises: exercises ?? this.exercises);
}

class WizardState {
  final int step;
  final String programName;
  final String splitType;
  final String goal;
  final String level;
  final List<WizardDay> days;
  final int currentDayIndex;
  final bool isAutoFilling;

  const WizardState({
    this.step = 0,
    this.programName = '',
    this.splitType = '',
    this.goal = 'Muscle Building',
    this.level = 'Intermediate',
    this.days = const [],
    this.currentDayIndex = 0,
    this.isAutoFilling = false,
  });

  WizardState copyWith({
    int? step,
    String? programName,
    String? splitType,
    String? goal,
    String? level,
    List<WizardDay>? days,
    int? currentDayIndex,
    bool? isAutoFilling,
  }) =>
      WizardState(
        step: step ?? this.step,
        programName: programName ?? this.programName,
        splitType: splitType ?? this.splitType,
        goal: goal ?? this.goal,
        level: level ?? this.level,
        days: days ?? this.days,
        currentDayIndex: currentDayIndex ?? this.currentDayIndex,
        isAutoFilling: isAutoFilling ?? this.isAutoFilling,
      );

  bool get canNext {
    switch (step) {
      case 0:
        return programName.trim().isNotEmpty && splitType.isNotEmpty;
      case 1:
        return days.isNotEmpty &&
            days.every((d) => d.name.trim().isNotEmpty);
      case 2:
        return days.any((d) => d.exercises.isNotEmpty);
      default:
        return true;
    }
  }
}

class WizardNotifier extends Notifier<WizardState> {
  @override
  WizardState build() => const WizardState();

  void setName(String name) => state = state.copyWith(programName: name);

  void setSplit(String split) {
    state = state.copyWith(splitType: split, days: _defaultDays(split));
    // Kick off background exercise pre-population for non-custom splits
    if (split != 'custom') {
      Future.microtask(autoFillExercises);
    }
  }

  void setGoal(String g) => state = state.copyWith(goal: g);
  void setLevel(String l) => state = state.copyWith(level: l);

  void setDayName(int i, String name) {
    final days = [...state.days];
    days[i] = days[i].copyWith(name: name);
    state = state.copyWith(days: days);
  }

  void addDay() {
    final days = [
      ...state.days,
      WizardDay(name: 'Day ${state.days.length + 1}'),
    ];
    state = state.copyWith(days: days);
  }

  void removeDay(int i) {
    if (state.days.length <= 1) return;
    final days = [...state.days]..removeAt(i);
    final idx = state.currentDayIndex.clamp(0, days.length - 1);
    state = state.copyWith(days: days, currentDayIndex: idx);
  }

  void setCurrentDay(int i) => state = state.copyWith(currentDayIndex: i);

  void toggleExercise(ExerciseModel ex) {
    final days = [...state.days];
    final day = days[state.currentDayIndex];
    final exercises = [...day.exercises];
    final idx = exercises.indexWhere((e) => e.id == ex.id);
    if (idx >= 0) {
      exercises.removeAt(idx);
    } else {
      exercises.add(ex.copyWith(sets: 3, repsFrom: '8', repsTo: '12'));
    }
    days[state.currentDayIndex] = day.copyWith(exercises: exercises);
    state = state.copyWith(days: days);
  }

  void updateExercise(
    int dayIdx,
    int exIdx, {
    int? sets,
    String? repsFrom,
    String? repsTo,
  }) {
    final days = [...state.days];
    final day = days[dayIdx];
    final exercises = [...day.exercises];
    final ex = exercises[exIdx];
    exercises[exIdx] = ex.copyWith(
      sets: sets ?? ex.sets,
      repsFrom: repsFrom ?? ex.repsFrom,
      repsTo: repsTo ?? ex.repsTo,
    );
    days[dayIdx] = day.copyWith(exercises: exercises);
    state = state.copyWith(days: days);
  }

  /// Link exIdx with the exercise directly above it (exIdx - 1) as a superset.
  /// Pass link=false to unlink.
  void linkSuperset(int dayIdx, int exIdx, bool link) {
    if (exIdx <= 0) return;
    final days = [...state.days];
    final day = days[dayIdx];
    final exercises = [...day.exercises];

    if (link) {
      final prev = exercises[exIdx - 1];
      final groupId = prev.supersetGroupId ?? const Uuid().v4();
      // Ensure previous is in the group.
      if (prev.supersetGroupId == null) {
        exercises[exIdx - 1] = prev.copyWith(supersetGroupId: groupId, supersetOrder: 0);
      }
      // Find the highest order in this group so far.
      int maxOrder = 0;
      for (final ex in exercises) {
        if (ex.supersetGroupId == groupId && ex.supersetOrder > maxOrder) {
          maxOrder = ex.supersetOrder;
        }
      }
      exercises[exIdx] = exercises[exIdx].copyWith(
        supersetGroupId: groupId,
        supersetOrder: maxOrder + 1,
      );
    } else {
      // Unlink: clear only this exercise's group membership.
      exercises[exIdx] = exercises[exIdx].copyWith(
        supersetGroupId: null,
        supersetOrder: 0,
      );
    }
    days[dayIdx] = day.copyWith(exercises: exercises);
    state = state.copyWith(days: days);
  }

  void reorderExercise(int dayIdx, int oldIdx, int newIdx) {
    final days = [...state.days];
    final day = days[dayIdx];
    final exercises = [...day.exercises];
    final item = exercises.removeAt(oldIdx);
    exercises.insert(newIdx > oldIdx ? newIdx - 1 : newIdx, item);
    days[dayIdx] = day.copyWith(exercises: exercises);
    state = state.copyWith(days: days);
  }

  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void reset() => state = const WizardState();

  // ── Auto-fill exercises from repository ─────────────────────────────────────

  Future<void> autoFillExercises() async {
    if (state.splitType == 'custom') return;
    state = state.copyWith(isAutoFilling: true);
    final repo = ExerciseRepository();
    try {
      final currentDays = state.days;
      final split = state.splitType;
      List<WizardDay> newDays;
      switch (split) {
        case 'upper_lower':
          newDays = await _fillUpperLower(repo, currentDays);
          break;
        case 'push_pull_legs':
          newDays = await _fillPPL(repo, currentDays);
          break;
        case 'full_body':
          newDays = await _fillFullBody(repo, currentDays);
          break;
        default:
          state = state.copyWith(isAutoFilling: false);
          return;
      }
      state = state.copyWith(days: newDays, isAutoFilling: false);
    } catch (_) {
      state = state.copyWith(isAutoFilling: false);
    }
  }

  Future<List<WizardDay>> _fillUpperLower(
      ExerciseRepository repo, List<WizardDay> days) async {
    final chest = await repo.getSimilarExercises('chest', limit: 8);
    final back = await repo.getSimilarExercises('back', limit: 8);
    final shoulders = await repo.getSimilarExercises('shoulders', limit: 6);
    final upperLegs = await repo.getSimilarExercises('upper legs', limit: 10);
    final lowerLegs = await repo.getSimilarExercises('lower legs', limit: 4);

    final picks = [
      [..._pick(chest, 3), ..._pick(back, 3), ..._pick(shoulders, 2)],
      [..._pick(upperLegs, 4), ..._pick(lowerLegs, 2)],
      [..._pick(chest, 2), ..._pick(back, 3), ..._pick(shoulders, 3)],
      [..._pick(upperLegs, 4), ..._pick(lowerLegs, 2)],
    ];

    return List.generate(days.length.clamp(0, picks.length), (i) {
      return days[i].copyWith(exercises: _withDefaults(picks[i]));
    });
  }

  Future<List<WizardDay>> _fillPPL(
      ExerciseRepository repo, List<WizardDay> days) async {
    final chest = await repo.getSimilarExercises('chest', limit: 6);
    final shoulders = await repo.getSimilarExercises('shoulders', limit: 5);
    final upperArms = await repo.getSimilarExercises('upper arms', limit: 8);
    final back = await repo.getSimilarExercises('back', limit: 6);
    final upperLegs = await repo.getSimilarExercises('upper legs', limit: 8);
    final lowerLegs = await repo.getSimilarExercises('lower legs', limit: 4);

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
    final armsRest =
        upperArms.where((e) => !triceps.contains(e) && !biceps.contains(e)).toList();

    final picks = [
      [
        ..._pick(chest, 3),
        ..._pick(shoulders, 2),
        ..._pick(triceps.isNotEmpty ? triceps : armsRest, 2),
      ],
      [
        ..._pick(back, 4),
        ..._pick(biceps.isNotEmpty ? biceps : armsRest, 3),
      ],
      [..._pick(upperLegs, 4), ..._pick(lowerLegs, 2)],
    ];

    return List.generate(days.length.clamp(0, picks.length), (i) {
      return days[i].copyWith(exercises: _withDefaults(picks[i]));
    });
  }

  Future<List<WizardDay>> _fillFullBody(
      ExerciseRepository repo, List<WizardDay> days) async {
    final chest = await repo.getSimilarExercises('chest', limit: 5);
    final back = await repo.getSimilarExercises('back', limit: 5);
    final upperLegs = await repo.getSimilarExercises('upper legs', limit: 5);
    final shoulders = await repo.getSimilarExercises('shoulders', limit: 4);

    final exercises = _withDefaults([
      ..._pick(chest, 2),
      ..._pick(back, 2),
      ..._pick(upperLegs, 2),
      ..._pick(shoulders, 1),
    ]);

    return List.generate(days.length, (i) {
      return days[i].copyWith(exercises: i.isEven ? exercises : exercises.reversed.toList());
    });
  }

  List<ExerciseModel> _pick(List<ExerciseModel> list, int count) {
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

  List<ExerciseModel> _withDefaults(List<ExerciseModel> exercises) {
    return exercises
        .map((e) => e.copyWith(sets: 3, repsFrom: '8', repsTo: '12'))
        .toList();
  }

  // ── Day name defaults ────────────────────────────────────────────────────────

  static List<WizardDay> _defaultDays(String split) {
    switch (split) {
      case 'upper_lower':
        return [
          const WizardDay(name: 'Upper A'),
          const WizardDay(name: 'Lower A'),
          const WizardDay(name: 'Upper B'),
          const WizardDay(name: 'Lower B'),
        ];
      case 'push_pull_legs':
        return [
          const WizardDay(name: 'Push'),
          const WizardDay(name: 'Pull'),
          const WizardDay(name: 'Legs'),
        ];
      case 'full_body':
        return [
          const WizardDay(name: 'Full Body A'),
          const WizardDay(name: 'Full Body B'),
          const WizardDay(name: 'Full Body C'),
        ];
      case 'custom':
        return [
          const WizardDay(name: 'Day 1'),
          const WizardDay(name: 'Day 2'),
        ];
      default:
        return [];
    }
  }
}

final wizardProvider =
    NotifierProvider<WizardNotifier, WizardState>(WizardNotifier.new);
