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
    return FreeExerciseEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
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

  /// Convert to the Hive-persisted [ExerciseModel] used throughout the app.
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
      // First image becomes the thumbnail URL used by ExerciseGifWidget
      gifUrl: imageUrls.isNotEmpty ? imageUrls[0] : '',
      sets: sets,
      repsFrom: repsFrom,
      repsTo: repsTo,
      restTime: restTime,
      technique: technique,
      targetMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      // Re-use primaryMuscles as bodyParts so ReplaceExerciseScreen filtering works
      bodyParts: primaryMuscles,
      equipments: equipment != null && equipment!.isNotEmpty ? [equipment!] : [],
      instructions: instructions,
    );
  }
}
