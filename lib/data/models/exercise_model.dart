const _kSentinel = Object();

class ExerciseModel {
  String id;
  String name;
  String gifUrl;
  int sets;
  String repsFrom;
  String repsTo;
  String restTime;
  String technique;
  String? supersetGroupId;
  int supersetOrder;
  bool isNew;
  List<String> targetMuscles;
  List<String> secondaryMuscles;
  List<String> bodyParts;
  List<String> equipments;
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
    this.supersetGroupId,
    this.supersetOrder = 0,
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

  /// True for exercises logged by duration/distance instead of weight × reps.
  bool get isCardio =>
      bodyParts.any((b) => b.toLowerCase() == 'cardio') ||
      targetMuscles
          .any((m) => m.toLowerCase().contains('cardiovascular'));

  ExerciseModel copyWith({
    String? id,
    String? name,
    String? gifUrl,
    int? sets,
    String? repsFrom,
    String? repsTo,
    String? restTime,
    String? technique,
    Object? supersetGroupId = _kSentinel,
    int? supersetOrder,
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
      supersetGroupId: identical(supersetGroupId, _kSentinel)
          ? this.supersetGroupId
          : supersetGroupId as String?,
      supersetOrder: supersetOrder ?? this.supersetOrder,
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
        'supersetGroupId': supersetGroupId,
        'supersetOrder': supersetOrder,
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
        supersetGroupId: json['supersetGroupId']?.toString(),
        supersetOrder: (json['supersetOrder'] as num?)?.toInt() ?? 0,
        targetMuscles: List<String>.from(json['targetMuscles'] ?? []),
        secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
        bodyParts: List<String>.from(json['bodyParts'] ?? []),
        equipments: List<String>.from(json['equipments'] ?? []),
        instructions: List<String>.from(json['instructions'] ?? []),
      );

  factory ExerciseModel.fromApi(Map<String, dynamic> json) {
    List<String> parsedTargetMuscles;
    if (json['targetMuscles'] is List) {
      parsedTargetMuscles = List<String>.from(json['targetMuscles']);
    } else if (json['target'] != null) {
      parsedTargetMuscles = [json['target'].toString()];
    } else {
      parsedTargetMuscles = [];
    }

    List<String> parsedBodyParts;
    if (json['bodyParts'] is List) {
      parsedBodyParts = List<String>.from(json['bodyParts']);
    } else if (json['bodyPart'] != null) {
      parsedBodyParts = [json['bodyPart'].toString()];
    } else {
      parsedBodyParts = [];
    }

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
