import 'template_models.dart';

const List<ProgramTemplate> kProgramTemplates = [
  // ── BEGINNER ─────────────────────────────────────────────────────────────────
  ProgramTemplate(
    id: 'full_body_3x',
    name: 'Full Body 3×/Week',
    description:
        'A classic 3-day full-body routine. Perfect for beginners building a foundation of strength across all major muscle groups.',
    difficulty: 'Beginner',
    daysPerWeek: 3,
    goal: 'Strength',
    equipment: ['Barbell', 'Dumbbells', 'Bench', 'Squat Rack'],
    estimatedWeeks: 8,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Full Body A',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '5', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 3, reps: '5', muscle: 'Chest', restTime: '3 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 3, reps: '5', muscle: 'Back', restTime: '3 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 2, reps: '8-10', muscle: 'Shoulders', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 2, reps: '10-12', muscle: 'Legs', restTime: '2-3 min'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Full Body B',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '5', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '5', muscle: 'Shoulders', restTime: '3 min'),
          ExerciseTemplate(name: 'Deadlift', sets: 1, reps: '5', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Dumbbell Row', sets: 3, reps: '8-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Dip', sets: 2, reps: '8-10', muscle: 'Chest', restTime: '2-3 min'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Full Body C',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '5', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 3, reps: '5', muscle: 'Chest', restTime: '3 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 3, reps: '5', muscle: 'Back', restTime: '3 min'),
          ExerciseTemplate(name: 'Bicep Curl', sets: 2, reps: '10-12', muscle: 'Arms', restTime: '2 min'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 2, reps: '10-12', muscle: 'Arms', restTime: '2 min'),
        ],
      ),
    ],
  ),

  ProgramTemplate(
    id: 'upper_lower_2x',
    name: 'Upper/Lower 2×/Week',
    description:
        'A simple 4-day upper/lower split. Great for beginners who want to train each muscle group twice a week.',
    difficulty: 'Beginner',
    daysPerWeek: 4,
    goal: 'Hypertrophy',
    equipment: ['Barbell', 'Dumbbells', 'Bench', 'Squat Rack', 'Cable Machine'],
    estimatedWeeks: 8,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Upper A',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 3, reps: '8-10', muscle: 'Chest', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 3, reps: '8-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '10-12', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Lat Pulldown', sets: 3, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Bicep Curl', sets: 2, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 2, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Lower A',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Press', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Curl', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Calf Raise', sets: 3, reps: '15-20', muscle: 'Calves'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Upper B',
        exercises: [
          ExerciseTemplate(name: 'Incline Dumbbell Press', sets: 3, reps: '10-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Pull Up', sets: 3, reps: '6-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 3, reps: '12-15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Cable Row', sets: 3, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Hammer Curl', sets: 2, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Skull Crusher', sets: 2, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Lower B',
        exercises: [
          ExerciseTemplate(name: 'Deadlift', sets: 3, reps: '5-6', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Bulgarian Split Squat', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Leg Curl', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Standing Calf Raise', sets: 4, reps: '15-20', muscle: 'Calves'),
        ],
      ),
    ],
  ),

  ProgramTemplate(
    id: 'starting_strength',
    name: 'Starting Strength',
    description:
        'Mark Rippetoe\'s classic beginner barbell program. Add weight every session on the big 5 compound lifts.',
    difficulty: 'Beginner',
    daysPerWeek: 3,
    goal: 'Strength',
    equipment: ['Barbell', 'Squat Rack', 'Bench', 'Power Rack'],
    estimatedWeeks: 12,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Workout A',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '5', muscle: 'Legs', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 3, reps: '5', muscle: 'Chest', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Deadlift', sets: 1, reps: '5', muscle: 'Back', restTime: '5 min'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Workout B',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '5', muscle: 'Legs', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '5', muscle: 'Shoulders', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 3, reps: '5', muscle: 'Back', restTime: '3-5 min'),
        ],
      ),
    ],
  ),

  // ── INTERMEDIATE ──────────────────────────────────────────────────────────────
  ProgramTemplate(
    id: 'ppl_6x',
    name: 'Push / Pull / Legs',
    description:
        'The classic PPL 6-day split. High frequency + volume for intermediate lifters chasing hypertrophy.',
    difficulty: 'Intermediate',
    daysPerWeek: 6,
    goal: 'Hypertrophy',
    equipment: ['Barbell', 'Dumbbells', 'Bench', 'Squat Rack', 'Cable Machine', 'Leg Press'],
    estimatedWeeks: 12,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Push Day',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 4, reps: '8-10', muscle: 'Chest', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '8-10', muscle: 'Shoulders', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Incline Dumbbell Press', sets: 3, reps: '10-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 3, reps: '12-15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 3, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Overhead Tricep Extension', sets: 2, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Pull Day',
        exercises: [
          ExerciseTemplate(name: 'Deadlift', sets: 4, reps: '6-8', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Pull Up', sets: 3, reps: '8-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 3, reps: '8-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Face Pull', sets: 3, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Bicep Curl', sets: 3, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Hammer Curl', sets: 2, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Leg Day',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 4, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Press', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Curl', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Calf Raise', sets: 4, reps: '15-20', muscle: 'Calves'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Push Day 2',
        exercises: [
          ExerciseTemplate(name: 'Incline Barbell Press', sets: 4, reps: '8-10', muscle: 'Chest', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Dumbbell Shoulder Press', sets: 3, reps: '10-12', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Cable Fly', sets: 3, reps: '12-15', muscle: 'Chest'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 4, reps: '12-15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Skull Crusher', sets: 3, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 2, reps: '15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Pull Day 2',
        exercises: [
          ExerciseTemplate(name: 'Lat Pulldown', sets: 4, reps: '8-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Cable Row', sets: 3, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Dumbbell Row', sets: 3, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Rear Delt Fly', sets: 3, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Incline Dumbbell Curl', sets: 3, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Cable Curl', sets: 2, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Leg Day 2',
        exercises: [
          ExerciseTemplate(name: 'Front Squat', sets: 4, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Bulgarian Split Squat', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Leg Curl', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Standing Calf Raise', sets: 4, reps: '15-20', muscle: 'Calves'),
        ],
      ),
    ],
  ),

  ProgramTemplate(
    id: 'upper_lower_4x',
    name: 'Upper/Lower 4×/Week',
    description:
        'Abdallah\'s proven 4-day upper/lower split with strength emphasis on A days and hypertrophy on B days.',
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    goal: 'Hypertrophy',
    equipment: ['Barbell', 'Dumbbells', 'Bench', 'Squat Rack', 'Cable Machine'],
    estimatedWeeks: 12,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Upper A (Strength)',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 4, reps: '4-6', muscle: 'Chest', restTime: '3-4 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 4, reps: '4-6', muscle: 'Back', restTime: '3-4 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '6-8', muscle: 'Shoulders', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Weighted Pull Up', sets: 3, reps: '6-8', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 3, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Bicep Curl', sets: 3, reps: '10-12', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Lower A (Strength)',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 4, reps: '4-6', muscle: 'Legs', restTime: '3-4 min'),
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 4, reps: '6-8', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Leg Press', sets: 3, reps: '8-10', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Curl', sets: 3, reps: '8-10', muscle: 'Legs'),
          ExerciseTemplate(name: 'Calf Raise', sets: 4, reps: '10-15', muscle: 'Calves'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Upper B (Hypertrophy)',
        exercises: [
          ExerciseTemplate(name: 'Incline Dumbbell Press', sets: 4, reps: '10-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Cable Row', sets: 4, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Dumbbell Shoulder Press', sets: 3, reps: '10-12', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Lat Pulldown', sets: 3, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 3, reps: '15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Hammer Curl', sets: 3, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Skull Crusher', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Lower B (Hypertrophy)',
        exercises: [
          ExerciseTemplate(name: 'Deadlift', sets: 4, reps: '6-8', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Bulgarian Split Squat', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Leg Curl', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Standing Calf Raise', sets: 4, reps: '15-20', muscle: 'Calves'),
        ],
      ),
    ],
  ),

  ProgramTemplate(
    id: '531_beginners',
    name: '5/3/1 for Beginners',
    description:
        'Jim Wendler\'s 5/3/1 adapted for beginners. Focus on slow, steady strength progression on the big 4 lifts.',
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    goal: 'Strength',
    equipment: ['Barbell', 'Squat Rack', 'Bench', 'Power Rack'],
    estimatedWeeks: 16,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Squat / OHP',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '5/5/5+', muscle: 'Legs', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '5/5/5+', muscle: 'Shoulders', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 5, reps: '5', muscle: 'Back'),
          ExerciseTemplate(name: 'Pull Up', sets: 5, reps: '5-10', muscle: 'Back'),
          ExerciseTemplate(name: 'Plank', sets: 3, reps: '30-60s', muscle: 'Core'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Deadlift / Bench',
        exercises: [
          ExerciseTemplate(name: 'Deadlift', sets: 3, reps: '5/5/5+', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 3, reps: '5/5/5+', muscle: 'Chest', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Dumbbell Row', sets: 5, reps: '5', muscle: 'Back'),
          ExerciseTemplate(name: 'Dip', sets: 5, reps: '5-10', muscle: 'Chest'),
          ExerciseTemplate(name: 'Leg Raise', sets: 3, reps: '10-15', muscle: 'Core'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Squat / OHP Alt',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '3/3/3+', muscle: 'Legs', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '3/3/3+', muscle: 'Shoulders', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 5, reps: '5', muscle: 'Back'),
          ExerciseTemplate(name: 'Chin Up', sets: 5, reps: '5-10', muscle: 'Back'),
          ExerciseTemplate(name: 'Ab Wheel Rollout', sets: 3, reps: '8-10', muscle: 'Core'),
        ],
      ),
    ],
  ),

  // ── ADVANCED ─────────────────────────────────────────────────────────────────
  ProgramTemplate(
    id: 'ppl_advanced',
    name: 'PPL Progressive Overload',
    description:
        'High-volume PPL with structured progressive overload. Add weight on compounds, add reps on accessories.',
    difficulty: 'Advanced',
    daysPerWeek: 6,
    goal: 'Hypertrophy',
    equipment: ['Barbell', 'Dumbbells', 'Cable Machine', 'Bench', 'Squat Rack', 'Leg Press'],
    estimatedWeeks: 12,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Push (Heavy)',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 5, reps: '5', muscle: 'Chest', restTime: '3-4 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 4, reps: '6-8', muscle: 'Shoulders', restTime: '3 min'),
          ExerciseTemplate(name: 'Incline Dumbbell Press', sets: 3, reps: '8-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Cable Fly', sets: 3, reps: '12-15', muscle: 'Chest'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 4, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 3, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Overhead Tricep Extension', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Pull (Heavy)',
        exercises: [
          ExerciseTemplate(name: 'Deadlift', sets: 5, reps: '5', muscle: 'Back', restTime: '4-5 min'),
          ExerciseTemplate(name: 'Weighted Pull Up', sets: 4, reps: '6-8', muscle: 'Back', restTime: '3 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 4, reps: '6-8', muscle: 'Back', restTime: '3 min'),
          ExerciseTemplate(name: 'Face Pull', sets: 4, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Barbell Curl', sets: 4, reps: '8-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Hammer Curl', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Legs (Heavy)',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 5, reps: '5', muscle: 'Legs', restTime: '4 min'),
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 4, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Leg Press', sets: 3, reps: '10-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Curl', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 3, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Standing Calf Raise', sets: 5, reps: '15-20', muscle: 'Calves'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Push (Volume)',
        exercises: [
          ExerciseTemplate(name: 'Incline Barbell Press', sets: 4, reps: '8-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Dumbbell Shoulder Press', sets: 4, reps: '8-12', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Pec Deck Fly', sets: 4, reps: '12-15', muscle: 'Chest'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 5, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Rope Pushdown', sets: 4, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Overhead Tricep Extension', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Pull (Volume)',
        exercises: [
          ExerciseTemplate(name: 'Lat Pulldown', sets: 4, reps: '8-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Cable Row', sets: 4, reps: '8-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Dumbbell Row', sets: 4, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Rear Delt Fly', sets: 4, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Incline Dumbbell Curl', sets: 4, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Cable Curl', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Legs (Volume)',
        exercises: [
          ExerciseTemplate(name: 'Front Squat', sets: 4, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Bulgarian Split Squat', sets: 4, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Hack Squat', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Leg Curl', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Calf Raise', sets: 5, reps: '15-20', muscle: 'Calves'),
        ],
      ),
    ],
  ),

  ProgramTemplate(
    id: 'arnold_split',
    name: 'Arnold Split',
    description:
        'Arnold Schwarzenegger\'s 6-day split: Chest+Back, Shoulders+Arms, Legs. High volume for serious muscle building.',
    difficulty: 'Advanced',
    daysPerWeek: 6,
    goal: 'Hypertrophy',
    equipment: ['Barbell', 'Dumbbells', 'Cable Machine', 'Bench', 'Squat Rack'],
    estimatedWeeks: 12,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Chest & Back A',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 4, reps: '6-10', muscle: 'Chest', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Weighted Pull Up', sets: 4, reps: '6-10', muscle: 'Back', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Incline Dumbbell Press', sets: 4, reps: '8-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Barbell Row', sets: 4, reps: '8-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Cable Fly', sets: 3, reps: '12-15', muscle: 'Chest'),
          ExerciseTemplate(name: 'Cable Row', sets: 3, reps: '12-15', muscle: 'Back'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Shoulders & Arms A',
        exercises: [
          ExerciseTemplate(name: 'Overhead Press', sets: 4, reps: '8-10', muscle: 'Shoulders', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Barbell Curl', sets: 4, reps: '8-10', muscle: 'Arms'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 4, reps: '12-15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Skull Crusher', sets: 4, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Front Raise', sets: 3, reps: '12-15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Hammer Curl', sets: 3, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Legs A',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 5, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 4, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Press', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Curl', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Standing Calf Raise', sets: 5, reps: '15-20', muscle: 'Calves'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Chest & Back B',
        exercises: [
          ExerciseTemplate(name: 'Incline Barbell Press', sets: 4, reps: '6-10', muscle: 'Chest', restTime: '2-3 min'),
          ExerciseTemplate(name: 'Deadlift', sets: 4, reps: '6-8', muscle: 'Back', restTime: '3-4 min'),
          ExerciseTemplate(name: 'Dumbbell Bench Press', sets: 4, reps: '10-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Lat Pulldown', sets: 4, reps: '10-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Dip', sets: 3, reps: '10-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Dumbbell Row', sets: 3, reps: '12-15', muscle: 'Back'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Shoulders & Arms B',
        exercises: [
          ExerciseTemplate(name: 'Dumbbell Shoulder Press', sets: 4, reps: '8-12', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Incline Dumbbell Curl', sets: 4, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Face Pull', sets: 4, reps: '15-20', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Overhead Tricep Extension', sets: 4, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Arnold Press', sets: 3, reps: '10-12', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Cable Curl', sets: 3, reps: '12-15', muscle: 'Arms'),
          ExerciseTemplate(name: 'Rope Pushdown', sets: 3, reps: '12-15', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Legs B',
        exercises: [
          ExerciseTemplate(name: 'Front Squat', sets: 4, reps: '8-10', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Bulgarian Split Squat', sets: 4, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Leg Curl', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Calf Raise', sets: 5, reps: '15-20', muscle: 'Calves'),
        ],
      ),
    ],
  ),

  ProgramTemplate(
    id: 'phul',
    name: 'PHUL',
    description:
        'Power Hypertrophy Upper Lower. 4-day split hitting both strength (Mon/Thu) and hypertrophy (Tue/Fri).',
    difficulty: 'Advanced',
    daysPerWeek: 4,
    goal: 'Strength',
    equipment: ['Barbell', 'Dumbbells', 'Cable Machine', 'Bench', 'Squat Rack'],
    estimatedWeeks: 12,
    workoutDays: [
      WorkoutDayTemplate(
        name: 'Upper Power',
        exercises: [
          ExerciseTemplate(name: 'Barbell Bench Press', sets: 3, reps: '3-5', muscle: 'Chest', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Overhead Press', sets: 3, reps: '3-5', muscle: 'Shoulders', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Weighted Pull Up', sets: 3, reps: '3-5', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Row', sets: 3, reps: '3-5', muscle: 'Back', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Barbell Curl', sets: 3, reps: '8-10', muscle: 'Arms'),
          ExerciseTemplate(name: 'Skull Crusher', sets: 3, reps: '8-10', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Lower Power',
        exercises: [
          ExerciseTemplate(name: 'Barbell Squat', sets: 3, reps: '3-5', muscle: 'Legs', restTime: '3-5 min'),
          ExerciseTemplate(name: 'Deadlift', sets: 3, reps: '3-5', muscle: 'Back', restTime: '4-5 min'),
          ExerciseTemplate(name: 'Leg Press', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Curl', sets: 3, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Standing Calf Raise', sets: 4, reps: '10-12', muscle: 'Calves'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Upper Hypertrophy',
        exercises: [
          ExerciseTemplate(name: 'Incline Dumbbell Press', sets: 4, reps: '8-12', muscle: 'Chest'),
          ExerciseTemplate(name: 'Cable Fly', sets: 4, reps: '10-15', muscle: 'Chest'),
          ExerciseTemplate(name: 'Lat Pulldown', sets: 4, reps: '8-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Cable Row', sets: 4, reps: '8-12', muscle: 'Back'),
          ExerciseTemplate(name: 'Lateral Raise', sets: 4, reps: '12-15', muscle: 'Shoulders'),
          ExerciseTemplate(name: 'Hammer Curl', sets: 4, reps: '10-12', muscle: 'Arms'),
          ExerciseTemplate(name: 'Tricep Pushdown', sets: 4, reps: '10-12', muscle: 'Arms'),
        ],
      ),
      WorkoutDayTemplate(
        name: 'Lower Hypertrophy',
        exercises: [
          ExerciseTemplate(name: 'Romanian Deadlift', sets: 4, reps: '8-12', muscle: 'Legs', restTime: '3 min'),
          ExerciseTemplate(name: 'Bulgarian Split Squat', sets: 4, reps: '10-12', muscle: 'Legs'),
          ExerciseTemplate(name: 'Leg Extension', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Leg Curl', sets: 4, reps: '12-15', muscle: 'Legs'),
          ExerciseTemplate(name: 'Seated Calf Raise', sets: 4, reps: '15-20', muscle: 'Calves'),
        ],
      ),
    ],
  ),
];
