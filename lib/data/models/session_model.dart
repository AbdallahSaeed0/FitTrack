import 'package:hive/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 3)
class LoggedSetModel extends HiveObject {
  @HiveField(0)
  int setNumber;

  @HiveField(1)
  double weight;

  @HiveField(2)
  int reps;

  @HiveField(3)
  int actualRestSeconds;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  DateTime loggedAt;

  LoggedSetModel({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.actualRestSeconds = 0,
    this.notes,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();
}

@HiveType(typeId: 4)
class LoggedExerciseModel extends HiveObject {
  @HiveField(0)
  String exerciseId;

  @HiveField(1)
  String exerciseName;

  @HiveField(2)
  List<LoggedSetModel> sets;

  LoggedExerciseModel({
    required this.exerciseId,
    required this.exerciseName,
    List<LoggedSetModel>? sets,
  }) : sets = sets ?? [];
}

@HiveType(typeId: 5)
class WorkoutSessionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String programId;

  @HiveField(2)
  String dayName;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime? endTime;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  List<LoggedExerciseModel> exercises;

  @HiveField(7)
  bool completed;

  WorkoutSessionModel({
    required this.id,
    required this.programId,
    required this.dayName,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    List<LoggedExerciseModel>? exercises,
    this.completed = false,
  }) : exercises = exercises ?? [];
}
