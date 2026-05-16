class LocalExerciseDB {
  static const List<Map<String, dynamic>> exercises = [
    // CHEST
    {
      'id': 'local_bench_press',
      'name': 'barbell bench press',
      'gifUrl': '',
      'bodyParts': ['chest'],
      'equipments': ['barbell'],
      'targetMuscles': ['pectorals'],
      'secondaryMuscles': ['triceps', 'anterior deltoid'],
      'instructions': [
        'Lie flat on bench with feet on ground.',
        'Grip bar slightly wider than shoulder-width.',
        'Lower bar to mid-chest with control.',
        'Press back up to starting position.',
        'Do not lock elbows at the top.',
      ],
    },
    {
      'id': 'local_incline_db_press',
      'name': 'incline dumbbell press',
      'gifUrl': '',
      'bodyParts': ['chest'],
      'equipments': ['dumbbell'],
      'targetMuscles': ['pectoralis major clavicular head'],
      'secondaryMuscles': ['triceps', 'anterior deltoid'],
      'instructions': [
        'Set bench to 30-45 degree incline.',
        'Hold dumbbells at chest level.',
        'Press up until arms extended.',
        'Lower slowly back to start.',
      ],
    },
    {
      'id': 'local_pec_deck',
      'name': 'pec deck fly',
      'gifUrl': '',
      'bodyParts': ['chest'],
      'equipments': ['machine'],
      'targetMuscles': ['pectorals'],
      'secondaryMuscles': ['anterior deltoid'],
      'instructions': [
        'Sit with back flat against pad.',
        'Grip handles at shoulder height.',
        'Bring handles together in front of chest.',
        'Squeeze pecs at center.',
        'Return to start slowly.',
      ],
    },
    {
      'id': 'local_machine_chest_press',
      'name': 'machine chest press',
      'gifUrl': '',
      'bodyParts': ['chest'],
      'equipments': ['machine'],
      'targetMuscles': ['pectorals'],
      'secondaryMuscles': ['triceps', 'anterior deltoid'],
      'instructions': [
        'Adjust seat so handles align with mid-chest.',
        'Press handles forward until arms extended.',
        'Control the weight back to start.',
      ],
    },
    // BACK
    {
      'id': 'local_pull_up',
      'name': 'pull up',
      'gifUrl': '',
      'bodyParts': ['back'],
      'equipments': ['body weight'],
      'targetMuscles': ['latissimus dorsi'],
      'secondaryMuscles': ['biceps', 'rhomboids', 'rear deltoid'],
      'instructions': [
        'Grip bar slightly wider than shoulders.',
        'Hang with arms fully extended.',
        'Pull chest toward bar.',
        'Lower with control.',
      ],
    },
    {
      'id': 'local_seated_cable_row',
      'name': 'seated cable row',
      'gifUrl': '',
      'bodyParts': ['back'],
      'equipments': ['cable'],
      'targetMuscles': ['rhomboids'],
      'secondaryMuscles': ['biceps', 'rear deltoid', 'latissimus dorsi'],
      'instructions': [
        'Sit with feet on platform.',
        'Pull handle to lower abdomen.',
        'Squeeze shoulder blades together.',
        'Extend arms back to start.',
      ],
    },
    {
      'id': 'local_lat_pulldown',
      'name': 'lat pulldown',
      'gifUrl': '',
      'bodyParts': ['back'],
      'equipments': ['cable'],
      'targetMuscles': ['latissimus dorsi'],
      'secondaryMuscles': ['biceps', 'rear deltoid'],
      'instructions': [
        'Grip bar wider than shoulders.',
        'Pull bar to upper chest.',
        'Squeeze lats at bottom.',
        'Control weight back up.',
      ],
    },
    {
      'id': 'local_chest_supported_row',
      'name': 'chest supported machine row',
      'gifUrl': '',
      'bodyParts': ['back'],
      'equipments': ['machine'],
      'targetMuscles': ['rhomboids'],
      'secondaryMuscles': ['biceps', 'rear deltoid'],
      'instructions': [
        'Lie chest-down on pad.',
        'Pull handles to sides.',
        'Squeeze shoulder blades.',
        'Lower with control.',
      ],
    },
    // SHOULDERS
    {
      'id': 'local_seated_db_press',
      'name': 'seated dumbbell shoulder press',
      'gifUrl': '',
      'bodyParts': ['shoulders'],
      'equipments': ['dumbbell'],
      'targetMuscles': ['deltoids'],
      'secondaryMuscles': ['triceps', 'upper pectorals'],
      'instructions': [
        'Sit with back support.',
        'Hold dumbbells at shoulder level.',
        'Press overhead until arms extended.',
        'Lower slowly to start.',
      ],
    },
    {
      'id': 'local_lateral_raise',
      'name': 'dumbbell lateral raises',
      'gifUrl': '',
      'bodyParts': ['shoulders'],
      'equipments': ['dumbbell'],
      'targetMuscles': ['lateral deltoid'],
      'secondaryMuscles': ['anterior deltoid'],
      'instructions': [
        'Stand with dumbbells at sides.',
        'Raise arms to shoulder height.',
        'Keep slight bend in elbows.',
        'Lower with control.',
      ],
    },
    {
      'id': 'local_face_pull',
      'name': 'face pulls',
      'gifUrl': '',
      'bodyParts': ['shoulders'],
      'equipments': ['cable'],
      'targetMuscles': ['rear deltoid'],
      'secondaryMuscles': ['rhomboids', 'middle trapezius'],
      'instructions': [
        'Set cable to face height.',
        'Pull rope to face level.',
        'Separate handles at end.',
        'Return with control.',
      ],
    },
    // BICEPS
    {
      'id': 'local_cable_hammer_curl',
      'name': 'cable hammer curl',
      'gifUrl': '',
      'bodyParts': ['upper arms'],
      'equipments': ['cable'],
      'targetMuscles': ['biceps brachii'],
      'secondaryMuscles': ['forearms'],
      'instructions': [
        'Use rope attachment on cable.',
        'Keep elbows at sides.',
        'Curl rope to shoulders.',
        'Lower with control.',
      ],
    },
    {
      'id': 'local_incline_db_curl',
      'name': 'incline dumbbell curl',
      'gifUrl': '',
      'bodyParts': ['upper arms'],
      'equipments': ['dumbbell'],
      'targetMuscles': ['biceps brachii'],
      'secondaryMuscles': [],
      'instructions': [
        'Sit on incline bench (45 degrees).',
        'Let arms hang straight down.',
        'Curl dumbbells to shoulders.',
        'Lower slowly to stretch.',
      ],
    },
    // TRICEPS
    {
      'id': 'local_rope_pushdown',
      'name': 'rope pushdown',
      'gifUrl': '',
      'bodyParts': ['upper arms'],
      'equipments': ['cable'],
      'targetMuscles': ['triceps brachii'],
      'secondaryMuscles': [],
      'instructions': [
        'Use rope attachment on high cable.',
        'Keep elbows at sides.',
        'Push rope down, split at bottom.',
        'Return to start with control.',
      ],
    },
    {
      'id': 'local_cable_kickback',
      'name': 'cable triceps kickback',
      'gifUrl': '',
      'bodyParts': ['upper arms'],
      'equipments': ['cable'],
      'targetMuscles': ['triceps brachii'],
      'secondaryMuscles': [],
      'instructions': [
        'Hinge forward at hips.',
        'Keep upper arm parallel to floor.',
        'Extend arm back fully.',
        'Return to start.',
      ],
    },
    // LEGS - QUADS
    {
      'id': 'local_barbell_squat',
      'name': 'barbell squat',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['barbell'],
      'targetMuscles': ['quadriceps'],
      'secondaryMuscles': ['glutes', 'hamstrings'],
      'instructions': [
        'Bar on upper back.',
        'Feet shoulder-width apart.',
        'Lower until thighs parallel to ground.',
        'Drive through heels to stand.',
      ],
    },
    {
      'id': 'local_hack_squat',
      'name': 'hack squat',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['machine'],
      'targetMuscles': ['quadriceps'],
      'secondaryMuscles': ['glutes'],
      'instructions': [
        'Stand on platform.',
        'Back against pad.',
        'Lower until deep squat.',
        'Push through heels.',
      ],
    },
    {
      'id': 'local_goblet_squat',
      'name': 'goblet squat',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['dumbbell'],
      'targetMuscles': ['quadriceps'],
      'secondaryMuscles': ['glutes'],
      'instructions': [
        'Hold dumbbell at chest.',
        'Squat down deep.',
        'Keep chest up.',
        'Drive back to standing.',
      ],
    },
    // LEGS - HAMSTRINGS & GLUTES
    {
      'id': 'local_romanian_deadlift',
      'name': 'romanian deadlift',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['barbell'],
      'targetMuscles': ['hamstrings'],
      'secondaryMuscles': ['glutes', 'lower back'],
      'instructions': [
        'Hold bar at hip level.',
        'Hinge at hips, lower bar down legs.',
        'Keep back straight.',
        'Drive hips forward to stand.',
      ],
    },
    {
      'id': 'local_lying_leg_curl',
      'name': 'lying leg curl',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['machine'],
      'targetMuscles': ['hamstrings'],
      'secondaryMuscles': [],
      'instructions': [
        'Lie face down on machine.',
        'Curl heels to glutes.',
        'Squeeze at top.',
        'Lower with control.',
      ],
    },
    {
      'id': 'local_hip_thrust',
      'name': 'barbell hip thrust',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['barbell'],
      'targetMuscles': ['glutes'],
      'secondaryMuscles': ['hamstrings'],
      'instructions': [
        'Upper back on bench.',
        'Bar over hips.',
        'Drive hips up to full extension.',
        'Squeeze glutes at top.',
        'Lower with control.',
      ],
    },
    {
      'id': 'local_bulgarian_split_squat',
      'name': 'bulgarian split squat',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['dumbbell'],
      'targetMuscles': ['quadriceps'],
      'secondaryMuscles': ['glutes', 'hamstrings'],
      'instructions': [
        'Rear foot elevated on bench.',
        'Lower until front thigh parallel.',
        'Drive through front heel.',
        'Alternate legs.',
      ],
    },
    {
      'id': 'local_cable_pull_through',
      'name': 'cable pull through',
      'gifUrl': '',
      'bodyParts': ['upper legs'],
      'equipments': ['cable'],
      'targetMuscles': ['glutes'],
      'secondaryMuscles': ['hamstrings'],
      'instructions': [
        'Face away from cable.',
        'Rope between legs.',
        'Hinge at hips.',
        'Drive hips forward.',
      ],
    },
    // CALVES
    {
      'id': 'local_standing_calf_raise',
      'name': 'standing calf raise',
      'gifUrl': '',
      'bodyParts': ['lower legs'],
      'equipments': ['machine'],
      'targetMuscles': ['gastrocnemius'],
      'secondaryMuscles': ['soleus'],
      'instructions': [
        'Stand on platform.',
        'Shoulders under pads.',
        'Raise heels as high as possible.',
        'Lower slowly for stretch.',
      ],
    },
    {
      'id': 'local_seated_calf_raise',
      'name': 'seated calf raise',
      'gifUrl': '',
      'bodyParts': ['lower legs'],
      'equipments': ['machine'],
      'targetMuscles': ['soleus'],
      'secondaryMuscles': ['gastrocnemius'],
      'instructions': [
        'Sit with knees under pad.',
        'Balls of feet on platform.',
        'Raise heels high.',
        'Lower for deep stretch.',
      ],
    },

    // CARDIO
    {
      'id': 'local_treadmill_walk',
      'name': 'incline treadmill walk',
      'gifUrl': '',
      'bodyParts': ['cardio'],
      'equipments': ['treadmill'],
      'targetMuscles': ['cardiovascular system'],
      'secondaryMuscles': ['calves', 'glutes'],
      'instructions': [
        'Set treadmill to 3–4% incline.',
        'Walk at a brisk pace (3–4 mph).',
        'Keep shoulders back and core engaged.',
        'Duration: 10–15 minutes.',
      ],
    },
    {
      'id': 'local_rowing_machine',
      'name': 'rowing machine',
      'gifUrl': '',
      'bodyParts': ['cardio'],
      'equipments': ['rowing machine'],
      'targetMuscles': ['cardiovascular system'],
      'secondaryMuscles': ['back', 'legs', 'arms'],
      'instructions': [
        'Sit with feet strapped in, knees bent.',
        'Drive through legs first, then pull arms.',
        'Maintain an upright posture throughout.',
        'Duration: 8–10 minutes at a steady pace.',
      ],
    },
    {
      'id': 'local_stationary_bike',
      'name': 'stationary bike',
      'gifUrl': '',
      'bodyParts': ['cardio'],
      'equipments': ['stationary bike'],
      'targetMuscles': ['cardiovascular system'],
      'secondaryMuscles': ['quadriceps', 'hamstrings'],
      'instructions': [
        'Adjust seat so knee is slightly bent at bottom.',
        'Set moderate resistance.',
        'Pedal at a steady RPM.',
        'Duration: 10–15 minutes.',
      ],
    },
    {
      'id': 'local_jump_rope',
      'name': 'jump rope',
      'gifUrl': '',
      'bodyParts': ['cardio'],
      'equipments': ['jump rope'],
      'targetMuscles': ['cardiovascular system'],
      'secondaryMuscles': ['calves', 'shoulders'],
      'instructions': [
        'Hold handles at hip level.',
        'Jump with both feet, keeping jumps low (1–2 inches).',
        'Land softly on the balls of your feet.',
        'Duration: 5–10 minutes.',
      ],
    },
    {
      'id': 'local_burpees',
      'name': 'burpees',
      'gifUrl': '',
      'bodyParts': ['cardio'],
      'equipments': ['body weight'],
      'targetMuscles': ['cardiovascular system'],
      'secondaryMuscles': ['chest', 'legs', 'core'],
      'instructions': [
        'Start standing, then drop hands to floor.',
        'Jump feet back to a plank position.',
        'Perform a push-up.',
        'Jump feet to hands, then explode upward.',
        'Repeat for 30–60 seconds.',
      ],
    },
    {
      'id': 'local_mountain_climbers',
      'name': 'mountain climbers',
      'gifUrl': '',
      'bodyParts': ['cardio'],
      'equipments': ['body weight'],
      'targetMuscles': ['cardiovascular system'],
      'secondaryMuscles': ['core', 'shoulders'],
      'instructions': [
        'Start in a high plank position.',
        'Drive one knee toward your chest.',
        'Quickly switch legs in a running motion.',
        'Duration: 30–60 seconds.',
      ],
    },
  ];

  static Map<String, dynamic>? findByName(String name) {
    final normalized = name.toLowerCase().trim();
    try {
      return exercises.firstWhere(
        (ex) => ex['name'].toString().toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> findByBodyPart(String bodyPart) {
    final lower = bodyPart.toLowerCase();
    return exercises.where((ex) {
      final parts = (ex['bodyParts'] as List).map((p) => p.toString().toLowerCase());
      return parts.contains(lower);
    }).toList();
  }

  static List<Map<String, dynamic>> findByMuscle(String muscle) {
    final lower = muscle.toLowerCase();
    return exercises.where((ex) {
      final targets = (ex['targetMuscles'] as List).map((m) => m.toString().toLowerCase());
      return targets.any((t) => t.contains(lower));
    }).toList();
  }
}
