class WarmupExercise {
  final String name;
  final int durationSeconds;
  final String description;

  const WarmupExercise({
    required this.name,
    required this.durationSeconds,
    required this.description,
  });

  String get durationLabel {
    if (durationSeconds >= 60 && durationSeconds % 60 == 0) {
      return '${durationSeconds ~/ 60} min';
    }
    return '${durationSeconds}s';
  }
}

class WarmupLibrary {
  static const _general = [
    WarmupExercise(name: 'Jumping Jacks', durationSeconds: 60, description: 'Full body activation'),
    WarmupExercise(name: 'Arm Circles', durationSeconds: 45, description: 'Forward and backward arm rotations'),
    WarmupExercise(name: 'High Knees', durationSeconds: 45, description: 'Raise knees to hip level alternately'),
    WarmupExercise(name: 'Leg Swings', durationSeconds: 45, description: 'Front-to-back swings, 15 each leg'),
  ];

  static const _upper = [
    WarmupExercise(name: 'Arm Circles', durationSeconds: 45, description: 'Forward and backward rotations'),
    WarmupExercise(name: 'Band Pull-Aparts', durationSeconds: 60, description: 'Activate rear delts and upper back'),
    WarmupExercise(name: 'Scapular Push-Ups', durationSeconds: 45, description: 'Activate serratus anterior'),
    WarmupExercise(name: 'Empty Bar Press', durationSeconds: 90, description: '2 sets of 10 reps with empty bar'),
  ];

  static const _lower = [
    WarmupExercise(name: 'Jumping Jacks', durationSeconds: 60, description: 'Raise heart rate'),
    WarmupExercise(name: 'Bodyweight Squats', durationSeconds: 60, description: '15–20 reps to activate legs'),
    WarmupExercise(name: 'Glute Bridges', durationSeconds: 60, description: '15–20 reps to activate glutes'),
    WarmupExercise(name: 'Leg Swings (side to side)', durationSeconds: 45, description: 'Hip mobility, 15 each leg'),
  ];

  static const cooldowns = [
    WarmupExercise(name: 'Light Walking', durationSeconds: 120, description: 'Lower heart rate gradually'),
    WarmupExercise(name: 'Quad Stretch', durationSeconds: 60, description: 'Hold 30 sec each leg'),
    WarmupExercise(name: 'Hamstring Stretch', durationSeconds: 60, description: 'Hold 30 sec each leg'),
    WarmupExercise(name: 'Chest Doorway Stretch', durationSeconds: 60, description: 'Hold 30 sec each side'),
    WarmupExercise(name: "Child's Pose", durationSeconds: 60, description: 'Full body relaxation'),
  ];

  static List<WarmupExercise> forDay(String dayName) {
    final lower = dayName.toLowerCase();
    if (lower.contains('upper')) return _upper;
    if (lower.contains('lower') || lower.contains('leg') || lower.contains('squat')) return _lower;
    return _general;
  }
}
