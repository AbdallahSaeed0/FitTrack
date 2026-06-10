import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import '../../core/utils/web_storage_stub.dart'
    if (dart.library.html) '../../core/utils/web_storage_web.dart';
import '../../core/services/workout_notification_service.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../programs/programs_provider.dart';

// Sentinel so copyWith can distinguish "not passed" from "explicitly null"
const _kClear = Object();
const _kPrefsKey = 'active_workout';

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
  final Map<int, int> targetSetAdjustments;
  // Non-null for a brief window when a PR is detected during logSet.
  final String? prExerciseName;

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
    this.targetSetAdjustments = const {},
    this.prExerciseName,
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
    Map<int, int>? targetSetAdjustments,
    // Use _kClear sentinel to explicitly clear; omit to keep current value.
    Object? prExerciseName = _kClear,
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
      targetSetAdjustments: targetSetAdjustments ?? this.targetSetAdjustments,
      prExerciseName: identical(prExerciseName, _kClear)
          ? this.prExerciseName
          : prExerciseName as String?,
    );
  }
}

class WorkoutNotifier extends Notifier<WorkoutState> {
  Timer? _sessionTimer;
  Timer? _restTimer;
  final _uuid = const Uuid();

  @override
  WorkoutState build() {
    if (kIsWeb) {
      // Web: restore synchronously from localStorage
      final saved = loadWorkoutState();
      if (saved != null) {
        final restored = _restoreFromJson(saved);
        if (restored != null) {
          Future.microtask(() {
            _startSessionTimer();
            _updateNotification();
          });
          return restored;
        }
      }
    } else {
      // Native (Android/iOS): restore asynchronously from SharedPreferences
      Future.microtask(_tryRestoreNative);
    }
    return const WorkoutState();
  }

  // ── Native session restore ────────────────────────────────────────────────

  Future<void> _tryRestoreNative() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kPrefsKey);
      if (saved != null) {
        final restored = _restoreFromJson(saved);
        if (restored != null) {
          state = restored;
          _startSessionTimer();
          _updateNotification();
        }
      }
    } catch (e) {
      debugPrint('[WorkoutNotifier] native restore failed: $e');
    }
  }

  WorkoutState? _restoreFromJson(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final day = WorkoutDayModel.fromJson(
          map['currentDay'] as Map<String, dynamic>);
      final session = WorkoutSessionModel.fromRow(
          map['session'] as Map<String, dynamic>);
      final elapsed = DateTime.now()
          .difference(session.startTime)
          .inSeconds
          .clamp(0, 86400);
      final rawAdj = map['targetSetAdjustments'] as Map<String, dynamic>?;
      final adj = rawAdj != null
          ? rawAdj.map((k, v) => MapEntry(int.parse(k), v as int))
          : <int, int>{};
      final programId = map['programId'] as String?;
      final program = programId != null
          ? ProgramRepository.instance.getById(programId)
          : null;
      return WorkoutState(
        program: program,
        currentDay: day,
        session: session,
        currentExerciseIndex:
            (map['currentExerciseIndex'] as num?)?.toInt() ?? 0,
        elapsedSeconds: elapsed,
        isActive: true,
        targetSetAdjustments: adj,
      );
    } catch (e) {
      debugPrint('[WorkoutNotifier] restore failed: $e');
      _clearPersisted();
      return null;
    }
  }

  // ── Unified persistence ───────────────────────────────────────────────────

  void _persist() {
    if (state.session == null || state.currentDay == null) return;
    try {
      final map = {
        'currentDay': state.currentDay!.toJson(),
        'session': state.session!.toRow(''),
        'currentExerciseIndex': state.currentExerciseIndex,
        'targetSetAdjustments':
            state.targetSetAdjustments.map((k, v) => MapEntry(k.toString(), v)),
        if (state.program != null) 'programId': state.program!.id,
      };
      final encoded = jsonEncode(map);
      if (kIsWeb) {
        saveWorkoutState(encoded);
      } else {
        SharedPreferences.getInstance()
            .then((prefs) => prefs.setString(_kPrefsKey, encoded));
      }
    } catch (_) {}
  }

  void _clearPersisted() {
    if (kIsWeb) {
      clearWorkoutState();
    } else {
      SharedPreferences.getInstance()
          .then((prefs) => prefs.remove(_kPrefsKey));
    }
  }

  // ── Workout control ───────────────────────────────────────────────────────

  void startWorkout(ProgramModel program, WorkoutDayModel day) {
    final session = WorkoutSessionModel(
      id: _uuid.v4(),
      programId: program.id,
      dayName: day.name,
      startTime: DateTime.now(),
      exercises: day.exercises
          .map((e) =>
              LoggedExerciseModel(exerciseId: e.id, exerciseName: e.name))
          .toList(),
    );

    state = WorkoutState(
      program: program,
      currentDay: day,
      session: session,
      isActive: true,
    );
    _startSessionTimer();
    _persist();
    _updateNotification();
  }

  /// Pushes a fresh notification with the current workout state.
  void _updateNotification() {
    if (kIsWeb || state.currentDay == null) return;
    final exercises = state.currentDay!.exercises;
    final exIdx = state.currentExerciseIndex.clamp(0, exercises.length - 1);
    final current = exercises[exIdx];
    final next = exIdx + 1 < exercises.length ? exercises[exIdx + 1] : null;

    WorkoutNotificationService.instance.showWorkoutNotification(
      dayName: state.currentDay!.name,
      exerciseName: current.name,
      exerciseProgress: '${exIdx + 1} / ${exercises.length}',
      nextExerciseName: next?.name,
      restRemaining:
          state.restTimerActive ? state.restSecondsRemaining : null,
    );
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      // Persist every 30s to keep startTime accurate across restores
      if (state.elapsedSeconds % 30 == 0) _persist();
      // Refresh notification every 5s when not resting (exercise name doesn't change often)
      if (!state.restTimerActive && state.elapsedSeconds % 5 == 0) {
        _updateNotification();
      }
    });
  }

  void logSet({
    required double weight,
    required int reps,
    String? notes,
    bool toFailure = false,
    bool isBodyweight = false,
    bool isUnilateral = false,
    double? weightRight,
    List<double>? dropWeights,
    int? durationSeconds,
    double? distanceKm,
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
      toFailure: toFailure,
      isBodyweight: isBodyweight,
      isUnilateral: isUnilateral,
      weightRight: weightRight,
      dropWeights: dropWeights,
      durationSeconds: durationSeconds,
      distanceKm: distanceKm,
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

    final completedSets =
        List<Map<String, dynamic>>.from(state.completedSets);
    completedSets.add({'exerciseIndex': exIndex, 'setIndex': sets.length - 1});

    // PR detection: only trigger if exercise has prior history (not first ever log).
    String? detectedPr;
    if (!isBodyweight && weight > 0) {
      final exerciseName = exercises[exIndex].exerciseName;
      final history = SessionRepository.instance
          .getExerciseHistory(exerciseName, limit: 500);
      if (history.isNotEmpty) {
        double historicalMax = 0;
        for (final entry in history) {
          for (final s in entry.sets) {
            if (s.weight > historicalMax) historicalMax = s.weight;
          }
        }
        if (weight > historicalMax) {
          detectedPr = exerciseName;
        }
      }
    }

    state = state.copyWith(
      session: updatedSession,
      completedSets: completedSets,
      prExerciseName: detectedPr,
    );

    HapticFeedback.mediumImpact();
    _startRestTimer(exercise.restTime);
    _persist();

    // Auto-clear the PR flag after 4 seconds.
    if (detectedPr != null) {
      Future.delayed(const Duration(seconds: 4), () {
        if (state.prExerciseName == detectedPr) {
          state = state.copyWith(prExerciseName: null);
        }
      });
    }
  }

  void removeLastSet(int exerciseIndex) {
    if (state.session == null) return;
    if (exerciseIndex >= state.session!.exercises.length) return;

    final exercises = List<LoggedExerciseModel>.from(state.session!.exercises);
    final sets = List<LoggedSetModel>.from(exercises[exerciseIndex].sets);

    if (sets.isEmpty) return;

    sets.removeLast();
    final removedSetIndex = sets.length;

    final completedSets = List<Map<String, dynamic>>.from(state.completedSets)
      ..removeWhere((e) =>
          e['exerciseIndex'] == exerciseIndex &&
          e['setIndex'] == removedSetIndex);

    exercises[exerciseIndex] = LoggedExerciseModel(
      exerciseId: exercises[exerciseIndex].exerciseId,
      exerciseName: exercises[exerciseIndex].exerciseName,
      sets: sets,
    );

    final updatedSession = WorkoutSessionModel(
      id: state.session!.id,
      programId: state.session!.programId,
      dayName: state.session!.dayName,
      startTime: state.session!.startTime,
      exercises: exercises,
    );

    state =
        state.copyWith(session: updatedSession, completedSets: completedSets);
    _persist();
  }

  void editSet({
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
    String? notes,
    bool toFailure = false,
    bool isBodyweight = false,
    bool isUnilateral = false,
    double? weightRight,
    List<double>? dropWeights,
    int? durationSeconds,
    double? distanceKm,
  }) {
    if (state.session == null) return;
    final exercises = List<LoggedExerciseModel>.from(state.session!.exercises);
    if (exerciseIndex >= exercises.length) return;
    final sets = List<LoggedSetModel>.from(exercises[exerciseIndex].sets);
    if (setIndex >= sets.length) return;
    final original = sets[setIndex];
    sets[setIndex] = LoggedSetModel(
      setNumber: setIndex + 1,
      weight: weight,
      reps: reps,
      notes: notes,
      toFailure: toFailure,
      isBodyweight: isBodyweight,
      isUnilateral: isUnilateral,
      weightRight: weightRight,
      dropWeights: dropWeights,
      durationSeconds: durationSeconds,
      distanceKm: distanceKm,
      actualRestSeconds: original.actualRestSeconds,
      loggedAt: original.loggedAt,
    );
    exercises[exerciseIndex] = LoggedExerciseModel(
      exerciseId: exercises[exerciseIndex].exerciseId,
      exerciseName: exercises[exerciseIndex].exerciseName,
      sets: sets,
    );
    state = state.copyWith(
      session: WorkoutSessionModel(
        id: state.session!.id,
        programId: state.session!.programId,
        dayName: state.session!.dayName,
        startTime: state.session!.startTime,
        exercises: exercises,
      ),
    );
    _persist();
  }

  void addTargetSet(int exerciseIndex) {
    final adj = Map<int, int>.from(state.targetSetAdjustments);
    adj[exerciseIndex] = (adj[exerciseIndex] ?? 0) + 1;
    state = state.copyWith(targetSetAdjustments: adj);
    _persist();
  }

  void removeTargetSet(int exerciseIndex) {
    final adj = Map<int, int>.from(state.targetSetAdjustments);
    final currentAdjust = adj[exerciseIndex] ?? 0;
    final exercise = state.currentDay?.exercises[exerciseIndex];
    final baseTarget = exercise?.sets ?? 1;
    // Don't go below 1 total set
    if (baseTarget + currentAdjust <= 1) return;
    adj[exerciseIndex] = currentAdjust - 1;
    state = state.copyWith(targetSetAdjustments: adj);
    _persist();
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
        _updateNotification(); // clear rest info from notification
        _onRestComplete();
      } else {
        state = state.copyWith(restSecondsRemaining: remaining);
        _updateNotification(); // live countdown in notification
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

    if (state.currentDay != null) {
      final exIdx = state.currentExerciseIndex;
      final currentEx = state.currentDay!.exercises[exIdx];
      final logged = completedSetsForExercise(exIdx);
      final target =
          currentEx.sets + (state.targetSetAdjustments[exIdx] ?? 0);
      if (logged >= target) {
        nextExercise();
      }
    }
  }

  /// Called on app-resume to re-sync elapsed seconds from wall-clock startTime.
  void syncElapsedTime(int elapsed) {
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(restTimerActive: false, restSecondsRemaining: 0);
  }

  void addRestSeconds(int seconds) {
    if (!state.restTimerActive) return;
    state = state.copyWith(
      restSecondsRemaining: state.restSecondsRemaining + seconds,
      restSecondsTotal: state.restSecondsTotal + seconds,
    );
  }

  void skipExercise() => nextExercise();

  void adjustStartTime(DateTime newStart) {
    if (state.session == null) return;
    final updated = WorkoutSessionModel(
      id: state.session!.id,
      programId: state.session!.programId,
      dayName: state.session!.dayName,
      startTime: newStart,
      exercises: state.session!.exercises,
    );
    final elapsed = DateTime.now().difference(newStart).inSeconds;
    state = state.copyWith(
      session: updated,
      elapsedSeconds: elapsed.clamp(0, 86400),
    );
    _persist();
  }

  void nextExercise() {
    if (state.currentDay == null) return;
    final maxIndex = state.currentDay!.exercises.length - 1;
    if (state.currentExerciseIndex < maxIndex) {
      state =
          state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
      _persist();
      _updateNotification();
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state =
          state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
      _persist();
      _updateNotification();
    }
  }

  void setCurrentExercise(int idx) {
    if (state.currentDay == null) return;
    final maxIndex = state.currentDay!.exercises.length - 1;
    if (idx < 0 || idx > maxIndex) return;
    state = state.copyWith(currentExerciseIndex: idx);
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

    await SessionRepository.instance.save(finishedSession);
    _clearPersisted();

    // Use session.programId as fallback: state.program is null when the
    // workout was restored from persisted storage (program is not persisted).
    final programId =
        state.program?.id ?? state.session!.programId;
    if (programId.isNotEmpty) {
      await ProgramRepository.instance.advanceDay(programId);
      ref.read(programsProvider.notifier).refresh();
    }

    WorkoutNotificationService.instance.cancelWorkoutNotification();
    state = const WorkoutState();
    return finishedSession;
  }

  void cancelWorkout() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _clearPersisted();
    WorkoutNotificationService.instance.cancelWorkoutNotification();
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

  int targetSetsForExercise(int exerciseIndex) {
    final base = state.currentDay?.exercises[exerciseIndex].sets ?? 0;
    return base + (state.targetSetAdjustments[exerciseIndex] ?? 0);
  }
}

final workoutProvider =
    NotifierProvider<WorkoutNotifier, WorkoutState>(WorkoutNotifier.new);
