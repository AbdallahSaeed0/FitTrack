import 'exercise_model.dart';

/// A pure-Dart model for entries from the bundled free-exercise-db JSON.
/// Never persisted to Hive — only used as an in-memory read layer.
class FreeExerciseEntry {
  final String id;
  final String name;
  final String? force;
  final String? level;
  final String? mechanic;
  final String? equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String category;
  final List<String> images;

  const FreeExerciseEntry({
    required this.id,
    required this.name,
    this.force,
    this.level,
    this.mechanic,
    this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.category,
    required this.images,
  });

  static const _base =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

  /// Full URLs for every image (free-exercise-db stores paths like "Squat/0.jpg").
  List<String> get imageUrls => images.map((p) => '$_base$p').toList();

  factory FreeExerciseEntry.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    // free-exercise-db has no 'id' field — derive one from the name
    final id = json['id'] as String? ??
        name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return FreeExerciseEntry(
      id: id,
      name: name,
      force: json['force'] as String?,
      level: json['level'] as String?,
      mechanic: json['mechanic'] as String?,
      equipment: json['equipment'] as String?,
      primaryMuscles: _strList(json['primaryMuscles']),
      secondaryMuscles: _strList(json['secondaryMuscles']),
      instructions: _strList(json['instructions']),
      category: json['category'] as String? ?? 'strength',
      images: _strList(json['images']),
    );
  }

  static List<String> _strList(dynamic val) =>
      val is List ? val.map((e) => e.toString()).toList() : const [];

  /// Maps free-exercise-db primaryMuscles → canonical body-part names
  /// used by the rest of the app (matching Kaggle's bodyParts field).
  static List<String> _muscleToBodyParts(List<String> muscles) {
    const mapping = <String, String>{
      'abdominals': 'waist',
      'obliques': 'waist',
      'lats': 'back',
      'middle back': 'back',
      'lower back': 'back',
      'traps': 'back',
      'upper back': 'back',
      'rhomboids': 'back',
      'chest': 'chest',
      'pectorals': 'chest',
      'shoulders': 'shoulders',
      'delts': 'shoulders',
      'biceps': 'upper arms',
      'triceps': 'upper arms',
      'forearms': 'lower arms',
      'quadriceps': 'upper legs',
      'hamstrings': 'upper legs',
      'glutes': 'upper legs',
      'adductors': 'upper legs',
      'abductors': 'upper legs',
      'calves': 'lower legs',
      'neck': 'neck',
    };
    final parts = <String>{};
    for (final m in muscles) {
      final bp = mapping[m.toLowerCase()];
      if (bp != null) parts.add(bp);
    }
    // Fallback: keep originals so nothing is lost
    if (parts.isEmpty) parts.addAll(muscles);
    return parts.toList();
  }

  /// Convert to the [ExerciseModel] used throughout the app.
  ExerciseModel toExerciseModel({
    int sets = 3,
    String repsFrom = '8',
    String repsTo = '12',
    String restTime = '2-3 min',
    String technique = 'standard',
  }) {
    return ExerciseModel(
      id: id,
      name: name,
      gifUrl: imageUrls.isNotEmpty ? imageUrls[0] : '',
      sets: sets,
      repsFrom: repsFrom,
      repsTo: repsTo,
      restTime: restTime,
      technique: technique,
      targetMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      // Proper body-part names so filtering by 'back', 'chest', etc. works
      bodyParts: _muscleToBodyParts(primaryMuscles),
      equipments: equipment != null && equipment!.isNotEmpty ? [equipment!] : [],
      instructions: instructions,
    );
  }
}
