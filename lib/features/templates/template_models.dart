class ExerciseTemplate {
  final String name;
  final int sets;
  final String reps;
  final String muscle;
  final String restTime;

  const ExerciseTemplate({
    required this.name,
    required this.sets,
    required this.reps,
    required this.muscle,
    this.restTime = '2-3 min',
  });
}

class WorkoutDayTemplate {
  final String name;
  final List<ExerciseTemplate> exercises;

  const WorkoutDayTemplate({required this.name, required this.exercises});

  int get estimatedMinutes => exercises.fold(0, (sum, e) {
        const restSecs = 150; // 2.5 min avg rest
        final setTime = e.sets * (45 + restSecs);
        return sum + setTime ~/ 60;
      });
}

class ProgramTemplate {
  final String id;
  final String name;
  final String description;
  final String difficulty; // Beginner / Intermediate / Advanced
  final int daysPerWeek;
  final String goal; // Strength / Hypertrophy / Endurance
  final List<String> equipment;
  final List<WorkoutDayTemplate> workoutDays;
  final int estimatedWeeks;

  const ProgramTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.daysPerWeek,
    required this.goal,
    required this.equipment,
    required this.workoutDays,
    this.estimatedWeeks = 8,
  });

  int get avgMinutesPerSession {
    if (workoutDays.isEmpty) return 60;
    final total = workoutDays.fold(0, (s, d) => s + d.estimatedMinutes);
    return total ~/ workoutDays.length;
  }
}
