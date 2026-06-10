enum MuscleGroup {
  chest,
  abs,
  obliques,
  frontalDeltoids,
  biceps,
  forearms,
  trapezius,
  rearDeltoids,
  lats,
  lowerBack,
  triceps,
  quadriceps,
  hamstrings,
  glutes,
  calves,
  hipFlexors,
  fullBody,
}

extension MuscleGroupExtension on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.abs:
        return 'Abs';
      case MuscleGroup.obliques:
        return 'Obliques';
      case MuscleGroup.frontalDeltoids:
        return 'Front Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.trapezius:
        return 'Traps';
      case MuscleGroup.rearDeltoids:
        return 'Rear Shoulders';
      case MuscleGroup.lats:
        return 'Lats';
      case MuscleGroup.lowerBack:
        return 'Lower Back';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.quadriceps:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.hipFlexors:
        return 'Hip Flexors';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  bool get isBackMuscle {
    switch (this) {
      case MuscleGroup.trapezius:
      case MuscleGroup.rearDeltoids:
      case MuscleGroup.lats:
      case MuscleGroup.lowerBack:
      case MuscleGroup.triceps:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return true;
      default:
        return false;
    }
  }

  bool get isFrontMuscle {
    switch (this) {
      case MuscleGroup.chest:
      case MuscleGroup.abs:
      case MuscleGroup.obliques:
      case MuscleGroup.frontalDeltoids:
      case MuscleGroup.biceps:
      case MuscleGroup.forearms:
      case MuscleGroup.quadriceps:
      case MuscleGroup.hipFlexors:
        return true;
      default:
        return false;
    }
  }

  static MuscleGroup? fromApiString(String muscle) {
    final lower = muscle.toLowerCase().trim();
    if (lower.contains('chest') || lower.contains('pectoral')) return MuscleGroup.chest;
    if (lower.contains('abs') || lower.contains('abdominal') || lower.contains('core')) return MuscleGroup.abs;
    if (lower.contains('oblique')) return MuscleGroup.obliques;
    if (lower.contains('front delt') || lower.contains('anterior delt')) return MuscleGroup.frontalDeltoids;
    if (lower.contains('rear delt') || lower.contains('posterior delt')) return MuscleGroup.rearDeltoids;
    if (lower.contains('delt') || lower.contains('shoulder')) return MuscleGroup.frontalDeltoids;
    if (lower.contains('bicep')) return MuscleGroup.biceps;
    if (lower.contains('tricep')) return MuscleGroup.triceps;
    if (lower.contains('forearm')) return MuscleGroup.forearms;
    if (lower.contains('trap')) return MuscleGroup.trapezius;
    if (lower.contains('lat') || lower.contains('back') && lower.contains('upper')) return MuscleGroup.lats;
    if (lower.contains('lower back') || lower.contains('erector') || lower.contains('spine')) return MuscleGroup.lowerBack;
    if (lower.contains('back')) return MuscleGroup.lats;
    if (lower.contains('quad') || lower.contains('upper leg') || lower.contains('thigh')) return MuscleGroup.quadriceps;
    if (lower.contains('hamstring')) return MuscleGroup.hamstrings;
    if (lower.contains('glute') || lower.contains('hip') && lower.contains('abduct')) return MuscleGroup.glutes;
    if (lower.contains('hip') || lower.contains('groin')) return MuscleGroup.hipFlexors;
    if (lower.contains('calf') || lower.contains('calves') || lower.contains('lower leg')) return MuscleGroup.calves;
    return null;
  }
}
