class LoggedSetModel {
  int setNumber;
  double weight;
  int reps;
  int actualRestSeconds;
  String? notes;
  DateTime loggedAt;
  bool toFailure;
  bool isBodyweight;
  // true = weight stored is per-hand; display shows "each arm"
  bool isUnilateral;
  // When isUnilateral and both sides differ: weight = left, weightRight = right.
  // null means both sides use the same weight (weight).
  double? weightRight;
  // For dropset: each successive weight after the initial drop.
  // Top weight stays in `weight`; this list holds the subsequent drops in order.
  // null/empty = not a dropset.
  List<double>? dropWeights;
  // Cardio sets: duration of the activity. Non-null marks this as a cardio set.
  int? durationSeconds;
  // Cardio sets: optional distance covered.
  double? distanceKm;

  LoggedSetModel({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.actualRestSeconds = 0,
    this.notes,
    DateTime? loggedAt,
    this.toFailure = false,
    this.isBodyweight = false,
    this.isUnilateral = false,
    this.weightRight,
    this.dropWeights,
    this.durationSeconds,
    this.distanceKm,
  }) : loggedAt = loggedAt ?? DateTime.now();

  /// True for cardio sets logged by duration (rather than weight × reps).
  bool get isCardio => durationSeconds != null;

  /// Human-readable summary, e.g. "10kg × 8 reps" or "20 min · 3.2 km".
  String formatSummary() {
    if (isCardio) {
      final mins = durationSeconds! ~/ 60;
      final secs = durationSeconds! % 60;
      final durationStr =
          secs == 0 ? '$mins min' : '${mins}m ${secs}s';
      if (distanceKm != null && distanceKm! > 0) {
        final distStr = distanceKm! == distanceKm!.floorToDouble()
            ? distanceKm!.toInt().toString()
            : distanceKm!.toStringAsFixed(2);
        return '$durationStr · ${distStr}km';
      }
      return durationStr;
    }
    final wStr = isBodyweight
        ? 'BW'
        : (weight == weight.floorToDouble()
            ? '${weight.toInt()}kg'
            : '${weight.toStringAsFixed(1)}kg');
    return '$wStr × $reps reps';
  }

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'weight': weight,
        'reps': reps,
        'actualRestSeconds': actualRestSeconds,
        'notes': notes,
        'loggedAt': loggedAt.toIso8601String(),
        'toFailure': toFailure,
        'isBodyweight': isBodyweight,
        'isUnilateral': isUnilateral,
        'weightRight': weightRight,
        'dropWeights': dropWeights,
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
      };

  factory LoggedSetModel.fromJson(Map<String, dynamic> json) => LoggedSetModel(
        setNumber: (json['setNumber'] as num).toInt(),
        weight: (json['weight'] as num).toDouble(),
        reps: (json['reps'] as num).toInt(),
        actualRestSeconds: (json['actualRestSeconds'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String?,
        loggedAt: json['loggedAt'] != null
            ? DateTime.parse(json['loggedAt'] as String)
            : DateTime.now(),
        toFailure: json['toFailure'] as bool? ?? false,
        isBodyweight: json['isBodyweight'] as bool? ?? false,
        isUnilateral: json['isUnilateral'] as bool? ?? false,
        weightRight: (json['weightRight'] as num?)?.toDouble(),
        dropWeights: (json['dropWeights'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      );
}

class LoggedExerciseModel {
  String exerciseId;
  String exerciseName;
  List<LoggedSetModel> sets;

  LoggedExerciseModel({
    required this.exerciseId,
    required this.exerciseName,
    List<LoggedSetModel>? sets,
  }) : sets = sets ?? [];

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory LoggedExerciseModel.fromJson(Map<String, dynamic> json) =>
      LoggedExerciseModel(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: (json['sets'] as List?)
                ?.map((s) => LoggedSetModel.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class WorkoutSessionModel {
  String id;
  String programId;
  String dayName;
  DateTime startTime;
  DateTime? endTime;
  int durationMinutes;
  List<LoggedExerciseModel> exercises;
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

  Map<String, dynamic> toRow(String userId) => {
        'id': id,
        'user_id': userId,
        'program_id': programId,
        'day_name': dayName,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_minutes': durationMinutes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'completed': completed,
      };

  factory WorkoutSessionModel.fromRow(Map<String, dynamic> row) =>
      WorkoutSessionModel(
        id: row['id'] as String,
        programId: row['program_id'] as String? ?? '',
        dayName: row['day_name'] as String? ?? '',
        startTime: DateTime.parse(row['start_time'] as String),
        endTime: row['end_time'] != null
            ? DateTime.parse(row['end_time'] as String)
            : null,
        durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
        exercises: (row['exercises'] as List?)
                ?.map((e) =>
                    LoggedExerciseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        completed: row['completed'] as bool? ?? false,
      );
}
