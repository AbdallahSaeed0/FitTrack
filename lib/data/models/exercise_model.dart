import 'package:hive/hive.dart';

part 'exercise_model.g.dart';

@HiveType(typeId: 0)
class ExerciseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String gifUrl;

  @HiveField(3)
  int sets;

  @HiveField(4)
  String repsFrom;

  @HiveField(5)
  String repsTo;

  @HiveField(6)
  String restTime;

  @HiveField(7)
  String technique;

  @HiveField(8)
  bool isNew;

  @HiveField(9)
  List<String> targetMuscles;

  @HiveField(10)
  List<String> secondaryMuscles;

  @HiveField(11)
  List<String> bodyParts;

  @HiveField(12)
  List<String> equipments;

  @HiveField(13)
  List<String> instructions;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.gifUrl,
    this.sets = 3,
    this.repsFrom = '8',
    this.repsTo = '12',
    this.restTime = '2-3 min',
    this.technique = 'standard',
    this.isNew = false,
    List<String>? targetMuscles,
    List<String>? secondaryMuscles,
    List<String>? bodyParts,
    List<String>? equipments,
    List<String>? instructions,
  })  : targetMuscles = targetMuscles ?? [],
        secondaryMuscles = secondaryMuscles ?? [],
        bodyParts = bodyParts ?? [],
        equipments = equipments ?? [],
        instructions = instructions ?? [];

  ExerciseModel copyWith({
    String? id,
    String? name,
    String? gifUrl,
    int? sets,
    String? repsFrom,
    String? repsTo,
    String? restTime,
    String? technique,
    bool? isNew,
    List<String>? targetMuscles,
    List<String>? secondaryMuscles,
    List<String>? bodyParts,
    List<String>? equipments,
    List<String>? instructions,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gifUrl: gifUrl ?? this.gifUrl,
      sets: sets ?? this.sets,
      repsFrom: repsFrom ?? this.repsFrom,
      repsTo: repsTo ?? this.repsTo,
      restTime: restTime ?? this.restTime,
      technique: technique ?? this.technique,
      isNew: isNew ?? this.isNew,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      bodyParts: bodyParts ?? this.bodyParts,
      equipments: equipments ?? this.equipments,
      instructions: instructions ?? this.instructions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gifUrl': gifUrl,
        'sets': sets,
        'repsFrom': repsFrom,
        'repsTo': repsTo,
        'restTime': restTime,
        'technique': technique,
        'targetMuscles': targetMuscles,
        'secondaryMuscles': secondaryMuscles,
        'bodyParts': bodyParts,
        'equipments': equipments,
        'instructions': instructions,
      };

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        gifUrl: json['gifUrl']?.toString() ?? '',
        sets: (json['sets'] as num?)?.toInt() ?? 3,
        repsFrom: json['repsFrom']?.toString() ?? '8',
        repsTo: json['repsTo']?.toString() ?? '12',
        restTime: json['restTime']?.toString() ?? '2-3 min',
        technique: json['technique']?.toString() ?? 'standard',
        targetMuscles: List<String>.from(json['targetMuscles'] ?? []),
        secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
        bodyParts: List<String>.from(json['bodyParts'] ?? []),
        equipments: List<String>.from(json['equipments'] ?? []),
        instructions: List<String>.from(json['instructions'] ?? []),
      );

  factory ExerciseModel.fromApi(Map<String, dynamic> json) {
    // Handle both 'target' (string) and 'targetMuscles' (array) API formats
    List<String> parsedTargetMuscles;
    if (json['targetMuscles'] is List) {
      parsedTargetMuscles = List<String>.from(json['targetMuscles']);
    } else if (json['target'] != null) {
      parsedTargetMuscles = [json['target'].toString()];
    } else {
      parsedTargetMuscles = [];
    }

    // Handle both 'bodyPart' (string) and 'bodyParts' (array)
    List<String> parsedBodyParts;
    if (json['bodyParts'] is List) {
      parsedBodyParts = List<String>.from(json['bodyParts']);
    } else if (json['bodyPart'] != null) {
      parsedBodyParts = [json['bodyPart'].toString()];
    } else {
      parsedBodyParts = [];
    }

    // Handle both 'equipment' (string) and 'equipments' (array)
    List<String> parsedEquipments;
    if (json['equipments'] is List) {
      parsedEquipments = List<String>.from(json['equipments']);
    } else if (json['equipment'] != null) {
      parsedEquipments = [json['equipment'].toString()];
    } else {
      parsedEquipments = [];
    }

    return ExerciseModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gifUrl: json['gifUrl']?.toString() ?? '',
      targetMuscles: parsedTargetMuscles,
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      bodyParts: parsedBodyParts,
      equipments: parsedEquipments,
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}
