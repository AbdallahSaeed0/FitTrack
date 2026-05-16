class WarmupExercise {
  final String name;
  final int durationSeconds;
  final String description;
  final List<String> instructions;

  const WarmupExercise({
    required this.name,
    required this.durationSeconds,
    required this.description,
    this.instructions = const [],
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
    WarmupExercise(
      name: 'Jumping Jacks',
      durationSeconds: 60,
      description: 'Full body activation',
      instructions: [
        'Stand with feet together, arms at your sides',
        'Jump and simultaneously spread feet shoulder-width apart and raise arms overhead',
        'Jump back to starting position',
        'Keep a steady, controlled rhythm throughout',
      ],
    ),
    WarmupExercise(
      name: 'Arm Circles',
      durationSeconds: 45,
      description: 'Forward and backward arm rotations',
      instructions: [
        'Stand with feet shoulder-width apart, extend arms out to the sides',
        'Make small circles forward for 10 seconds',
        'Gradually increase the circle size over the next 10 seconds',
        'Reverse direction and repeat for the remaining time',
      ],
    ),
    WarmupExercise(
      name: 'High Knees',
      durationSeconds: 45,
      description: 'Raise knees to hip level alternately',
      instructions: [
        'Stand tall with feet hip-width apart',
        'Drive your right knee up toward your chest',
        'Quickly switch — bring left knee up as right foot lands',
        'Pump opposite arms in rhythm with your knees',
        'Keep your torso upright throughout',
      ],
    ),
    WarmupExercise(
      name: 'Leg Swings',
      durationSeconds: 45,
      description: 'Front-to-back swings, 15 each leg',
      instructions: [
        'Stand next to a wall and hold it lightly for balance',
        'Shift weight to one leg and let the other hang free',
        'Swing the free leg forward as high as comfortable, then swing it back behind you',
        'Let the momentum carry it — this is a dynamic stretch, not a kick',
        'Complete 15 swings, then switch legs',
      ],
    ),
  ];

  static const _upper = [
    WarmupExercise(
      name: 'Arm Circles',
      durationSeconds: 45,
      description: 'Forward and backward rotations',
      instructions: [
        'Stand with feet shoulder-width apart, extend arms out to the sides',
        'Make small circles forward for 10 seconds',
        'Gradually increase the circle size',
        'Reverse direction and repeat for the remaining time',
        'Feel the shoulders warming up throughout the range of motion',
      ],
    ),
    WarmupExercise(
      name: 'Band Pull-Aparts',
      durationSeconds: 60,
      description: 'Activate rear delts and upper back',
      instructions: [
        'Hold a resistance band at shoulder height with both hands, arms extended',
        'Pull the band apart by moving your hands out to the sides',
        'Squeeze your shoulder blades together at the end of the movement',
        'Return to start in a slow, controlled manner',
        'Keep your arms straight throughout — this is not a bicep curl',
        'If no band, mimic the movement with your arms',
      ],
    ),
    WarmupExercise(
      name: 'Scapular Push-Ups',
      durationSeconds: 45,
      description: 'Activate serratus anterior',
      instructions: [
        'Start in a high push-up position with arms fully extended',
        'Keeping elbows locked straight, let your shoulder blades pinch together — your chest will dip slightly',
        'Then push through your hands to spread the shoulder blades apart as far as possible',
        'This is a very small movement — do not bend the elbows',
        'Focus on feeling the muscles around your shoulder blades working',
      ],
    ),
    WarmupExercise(
      name: 'Empty Bar Press',
      durationSeconds: 90,
      description: '2 sets of 10 reps with empty bar',
      instructions: [
        'Grip the bar just outside shoulder width with a firm overhand grip',
        'Unrack and hold at upper chest with elbows at roughly 45°',
        'Take a breath, brace your core, and press the bar straight up to full lockout',
        'Lower slowly back to your upper chest under control',
        'Use these reps to groove your pressing pattern — not to fatigue yourself',
        'Rest 30 seconds between the two sets',
      ],
    ),
  ];

  static const _lower = [
    WarmupExercise(
      name: 'Jumping Jacks',
      durationSeconds: 60,
      description: 'Raise heart rate',
      instructions: [
        'Stand with feet together, arms at your sides',
        'Jump and simultaneously spread feet and raise arms overhead',
        'Jump back to starting position',
        'Aim for a steady pace that gets your heart rate up',
      ],
    ),
    WarmupExercise(
      name: 'Bodyweight Squats',
      durationSeconds: 60,
      description: '15–20 reps to activate legs',
      instructions: [
        'Stand with feet slightly wider than shoulder-width, toes turned out slightly',
        'Push your hips back and bend your knees simultaneously',
        'Lower until your thighs are parallel to the floor (or as deep as comfortable)',
        'Keep your chest tall and knees tracking over your toes',
        'Drive through your heels to stand back up',
        'These should feel easy — you are activating muscles, not training them',
      ],
    ),
    WarmupExercise(
      name: 'Glute Bridges',
      durationSeconds: 60,
      description: '15–20 reps to activate glutes',
      instructions: [
        'Lie on your back with knees bent and feet flat on the floor, hip-width apart',
        'Press your feet firmly into the ground and squeeze your glutes',
        'Lift your hips until your body forms a straight line from shoulders to knees',
        'Hold the top position for 1–2 seconds, focusing on the glute squeeze',
        'Lower your hips slowly back to the floor',
        'Repeat for 15–20 reps',
      ],
    ),
    WarmupExercise(
      name: 'Leg Swings (side to side)',
      durationSeconds: 45,
      description: 'Hip mobility, 15 each leg',
      instructions: [
        'Face a wall and hold it with both hands for support',
        'Shift your weight to one leg',
        'Swing the other leg out to the side as high as comfortable',
        'Swing it back across your body to the opposite side in a smooth arc',
        'Let momentum guide the movement — do not force the range',
        'Complete 15 swings, then switch legs',
      ],
    ),
  ];

  static const cooldowns = [
    WarmupExercise(
      name: 'Light Walking',
      durationSeconds: 120,
      description: 'Lower heart rate gradually',
      instructions: [
        'Walk at an easy, relaxed pace',
        'Focus on slowing your breathing — breathe in through your nose, out through your mouth',
        'Let your arms swing naturally at your sides',
        'Continue until your heart rate feels close to resting',
      ],
    ),
    WarmupExercise(
      name: 'Quad Stretch',
      durationSeconds: 60,
      description: 'Hold 30 sec each leg',
      instructions: [
        'Stand on one leg — hold a wall for balance if needed',
        'Bend your other knee and grab your ankle behind you',
        'Pull your heel toward your glute until you feel a stretch in the front of your thigh',
        'Keep your knees together and stand tall',
        'Hold for 30 seconds, then switch legs',
      ],
    ),
    WarmupExercise(
      name: 'Hamstring Stretch',
      durationSeconds: 60,
      description: 'Hold 30 sec each leg',
      instructions: [
        'Sit on the floor with one leg extended, the other foot against your inner thigh',
        'Keeping your back straight, hinge forward from the hips toward your extended foot',
        'Reach toward your toes — go only as far as comfortable without rounding your spine',
        'Hold for 30 seconds, then switch legs',
      ],
    ),
    WarmupExercise(
      name: 'Chest Doorway Stretch',
      durationSeconds: 60,
      description: 'Hold 30 sec each side',
      instructions: [
        'Stand in a doorway and place one forearm against the door frame at 90°',
        'Step forward with the same-side leg until you feel a stretch across your chest and front shoulder',
        'Keep your core braced and do not let your lower back arch excessively',
        'Hold for 30 seconds, then switch sides',
      ],
    ),
    WarmupExercise(
      name: "Child's Pose",
      durationSeconds: 60,
      description: 'Full body relaxation',
      instructions: [
        'Kneel on the floor and sit back toward your heels',
        'Extend your arms forward on the floor and lower your forehead down',
        'Let your chest sink toward the ground with each exhale',
        'Breathe slowly and deeply — this is your recovery time',
        'Hold for the full 60 seconds',
      ],
    ),
  ];

  static List<WarmupExercise> forDay(String dayName) {
    final lower = dayName.toLowerCase();
    if (lower.contains('upper')) { return _upper; }
    if (lower.contains('lower') ||
        lower.contains('leg') ||
        lower.contains('squat')) { return _lower; }
    return _general;
  }
}
