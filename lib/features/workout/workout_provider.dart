import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/session_repository.dart';

class WorkoutState {
  final ProgramModel? program;
  final WorkoutDayModel? currentDay;
  final WorkoutSessionModel? session;
  final int currentExerciseIndex;
  final int elapsedSeconds;
  final bool restTimerActive;
  final int restSecondsRemaining;
  final int restSecondsTotal;
  final bool isActive;
  final List<Map<String, dynamic>> completedSets;

  const WorkoutState({
    this.program,
    this.currentDay,
    this.session,
    this.currentExerciseIndex = 0,
    this.elapsedSeconds = 0,
    this.restTimerActive = false,
    this.restSecondsRemaining = 0,
    this.restSecondsTotal = 0,
    this.isActive = false,
    this.completedSets = const [],
  });

  WorkoutState copyWith({
    ProgramModel? program,
    WorkoutDayModel? currentDay,
    WorkoutSessionModel? session,
    int? currentExerciseIndex,
    int? elapsedSeconds,
    bool? restTimerActive,
    int? restSecondsRemaining,
    int? restSecondsTotal,
    bool? isActive,
    List<Map<String, dynamic>>? completedSets,
  }) {
    return WorkoutState(
      program: program ?? this.program,
      currentDay: currentDay ?? this.currentDay,
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      restTimerActive: restTimerActive ?? this.restTimerActive,
      restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
      restSecondsTotal: restSecondsTotal ?? this.restSecondsTotal,
      isActive: isActive ?? this.isActive,
      completedSets: completedSets ?? this.completedSets,
    );
  }
}

class WorkoutNotifier extends Notifier<WorkoutState> {
  Timer? _sessionTimer;
  Timer? _restTimer;
  final _uuid = const Uuid();

  @override
  WorkoutState build() => const WorkoutState();

  void startWorkout(ProgramModel program, WorkoutDayModel day) {
    final session = WorkoutSessionModel(
      id: _uuid.v4(),
      programId: program.id,
      dayName: day.name,
      startTime: DateTime.now(),
      exercises: day.exercises
          .map((e) => LoggedExerciseModel(exerciseId: e.id, exerciseName: e.name))
          .toList(),
    );

    state = WorkoutState(
      program: program,
      currentDay: day,
      session: session,
      isActive: true,
    );
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void logSet({
    required double weight,
    required int reps,
    String? notes,
  }) {
    if (state.session == null || state.currentDay == null) return;

    final exercise = state.currentDay!.exercises[state.currentExerciseIndex];
    final exercises = List<LoggedExerciseModel>.from(state.session!.exercises);
    final exIndex = state.currentExerciseIndex;

    if (exIndex >= exercises.length) return;

    final sets = List<LoggedSetModel>.from(exercises[exIndex].sets);
    sets.add(LoggedSetModel(
      setNumber: sets.length + 1,
      weight: weight,
      reps: reps,
      notes: notes,
    ));
    exercises[exIndex] = LoggedExerciseModel(
      exerciseId: exercises[exIndex].exerciseId,
      exerciseName: exercises[exIndex].exerciseName,
      sets: sets,
    );

    final updatedSession = WorkoutSessionModel(
      id: state.session!.id,
      programId: state.session!.programId,
      dayName: state.session!.dayName,
      startTime: state.session!.startTime,
      exercises: exercises,
    );

    final completedSets = List<Map<String, dynamic>>.from(state.completedSets);
    completedSets.add({'exerciseIndex': exIndex, 'setIndex': sets.length - 1});

    state = state.copyWith(session: updatedSession, completedSets: completedSets);

    HapticFeedback.mediumImpact();
    _startRestTimer(exercise.restTime);
  }

  void _startRestTimer(String restTimeStr) {
    final seconds = _parseRestSeconds(restTimeStr);
    _restTimer?.cancel();
    state = state.copyWith(
      restTimerActive: true,
      restSecondsRemaining: seconds,
      restSecondsTotal: seconds,
    );
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.restSecondsRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(restTimerActive: false, restSecondsRemaining: 0);
        _onRestComplete();
      } else {
        state = state.copyWith(restSecondsRemaining: remaining);
      }
    });
  }

  void _onRestComplete() async {
    HapticFeedback.heavyImpact();
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (hasVibrator) {
        await Vibration.vibrate(pattern: [0, 400, 200, 400]);
      }
    } catch (_) {}

    // Auto-advance to next exercise when all sets for the current one are done
    if (state.currentDay != null) {
      final currentEx = state.currentDay!.exercises[state.currentExerciseIndex];
      final logged = completedSetsForExercise(state.currentExerciseIndex);
      if (logged >= currentEx.sets) {
        nextExercise();
      }
    }
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(restTimerActive: false, restSecondsRemaining: 0);
  }

  void nextExercise() {
    if (state.currentDay == null) return;
    final maxIndex = state.currentDay!.exercises.length - 1;
    if (state.currentExerciseIndex < maxIndex) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
    }
  }

  Future<WorkoutSessionModel?> finishWorkout() async {
    _sessionTimer?.cancel();
    _restTimer?.cancel();

    if (state.session == null) return null;

    final endTime = DateTime.now();
    final duration = endTime.difference(state.session!.startTime).inMinutes;
    final finishedSession = WorkoutSessionModel(
      id: state.session!.id,
      programId: state.session!.programId,
      dayName: state.session!.dayName,
      startTime: state.session!.startTime,
      endTime: endTime,
      durationMinutes: duration,
      exercises: state.session!.exercises,
      completed: true,
    );

    final sessionRepo = SessionRepository();
    await sessionRepo.save(finishedSession);

    if (state.program != null) {
      final programRepo = ProgramRepository();
      await programRepo.advanceDay(state.program!.id);
    }

    state = const WorkoutState();
    return finishedSession;
  }

  void cancelWorkout() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    state = const WorkoutState();
  }

  int _parseRestSeconds(String restTime) {
    final lower = restTime.toLowerCase().replaceAll(' ', '');
    if (lower.contains('-')) {
      final parts = lower.split('-');
      final first = _extractMinutes(parts[0]);
      return (first * 60).round();
    }
    final mins = _extractMinutes(lower);
    return (mins * 60).round();
  }

  double _extractMinutes(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 2.0;
  }

  int completedSetsForExercise(int exerciseIndex) {
    if (state.session == null) return 0;
    if (exerciseIndex >= state.session!.exercises.length) return 0;
    return state.session!.exercises[exerciseIndex].sets.length;
  }
}

final workoutProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(
  WorkoutNotifier.new,
);
