import 'package:hive/hive.dart';
import 'exercise_model.dart';

part 'workout_day_model.g.dart';

@HiveType(typeId: 1)
class WorkoutDayModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int dayNumber;

  @HiveField(3)
  bool isRestDay;

  @HiveField(4)
  List<ExerciseModel> exercises;

  WorkoutDayModel({
    required this.id,
    required this.name,
    required this.dayNumber,
    this.isRestDay = false,
    List<ExerciseModel>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dayNumber': dayNumber,
        'isRestDay': isRestDay,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) => WorkoutDayModel(
        id: json['id'] as String,
        name: json['name'] as String,
        dayNumber: (json['dayNumber'] as num).toInt(),
        isRestDay: json['isRestDay'] as bool? ?? false,
        exercises: (json['exercises'] as List?)
                ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  WorkoutDayModel copyWith({
    String? id,
    String? name,
    int? dayNumber,
    bool? isRestDay,
    List<ExerciseModel>? exercises,
  }) {
    return WorkoutDayModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dayNumber: dayNumber ?? this.dayNumber,
      isRestDay: isRestDay ?? this.isRestDay,
      exercises: exercises ?? this.exercises,
    );
  }
}
