import 'package:hive/hive.dart';
import 'workout_day_model.dart';

part 'program_model.g.dart';

@HiveType(typeId: 2)
class ProgramModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  List<WorkoutDayModel> days;

  @HiveField(4)
  String splitType;

  @HiveField(5)
  String goal;

  @HiveField(6)
  String experienceLevel;

  @HiveField(7)
  List<String> techniques;

  @HiveField(8)
  int currentDayIndex;

  @HiveField(9)
  DateTime createdAt;

  ProgramModel({
    required this.id,
    required this.name,
    this.isActive = false,
    List<WorkoutDayModel>? days,
    this.splitType = 'custom',
    this.goal = 'Muscle Building',
    this.experienceLevel = 'Intermediate',
    List<String>? techniques,
    this.currentDayIndex = 0,
    DateTime? createdAt,
  })  : days = days ?? [],
        techniques = techniques ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'splitType': splitType,
        'goal': goal,
        'experienceLevel': experienceLevel,
        'techniques': techniques,
        'currentDayIndex': currentDayIndex,
        'createdAt': createdAt.toIso8601String(),
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory ProgramModel.fromJson(Map<String, dynamic> json) => ProgramModel(
        id: json['id'] as String,
        name: json['name'] as String,
        isActive: false,
        splitType: json['splitType'] as String? ?? 'custom',
        goal: json['goal'] as String? ?? '',
        experienceLevel: json['experienceLevel'] as String? ?? '',
        techniques: List<String>.from(json['techniques'] ?? []),
        currentDayIndex: (json['currentDayIndex'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        days: (json['days'] as List?)
                ?.map((d) => WorkoutDayModel.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [],
      );

  ProgramModel copyWith({
    String? id,
    String? name,
    bool? isActive,
    List<WorkoutDayModel>? days,
    String? splitType,
    String? goal,
    String? experienceLevel,
    List<String>? techniques,
    int? currentDayIndex,
    DateTime? createdAt,
  }) {
    return ProgramModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      days: days ?? this.days,
      splitType: splitType ?? this.splitType,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      techniques: techniques ?? this.techniques,
      currentDayIndex: currentDayIndex ?? this.currentDayIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get trainingDaysCount => days.where((d) => !d.isRestDay).length;
}
