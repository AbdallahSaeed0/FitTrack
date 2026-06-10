import 'workout_day_model.dart';

class ProgramModel {
  String id;
  String name;
  bool isActive;
  List<WorkoutDayModel> days;
  String splitType;
  String goal;
  String experienceLevel;
  List<String> techniques;
  int currentDayIndex;
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

  Map<String, dynamic> toRow(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'is_active': isActive,
        'split_type': splitType,
        'goal': goal,
        'experience_level': experienceLevel,
        'techniques': techniques,
        'current_day_index': currentDayIndex,
        'days': days.map((d) => d.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
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

  factory ProgramModel.fromRow(Map<String, dynamic> row) => ProgramModel(
        id: row['id'] as String,
        name: row['name'] as String,
        isActive: row['is_active'] as bool? ?? false,
        splitType: row['split_type'] as String? ?? 'custom',
        goal: row['goal'] as String? ?? '',
        experienceLevel: row['experience_level'] as String? ?? '',
        techniques: List<String>.from(row['techniques'] ?? []),
        currentDayIndex: (row['current_day_index'] as num?)?.toInt() ?? 0,
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.now(),
        days: (row['days'] as List?)
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
