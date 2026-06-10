import 'package:flutter/material.dart';
import 'muscle_groups.dart';

class MuscleIntensity {
  final MuscleGroup muscle;
  final int workoutCount;

  const MuscleIntensity({
    required this.muscle,
    required this.workoutCount,
  });

  int get intensityLevel {
    if (workoutCount >= 10) return 5;
    if (workoutCount >= 7) return 4;
    if (workoutCount >= 4) return 3;
    if (workoutCount >= 2) return 2;
    if (workoutCount >= 1) return 1;
    return 0;
  }

  Color get color {
    switch (intensityLevel) {
      case 5:
        return const Color(0xFFEF4444);
      case 4:
        return const Color(0xFFFB923C);
      case 3:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFF60A5FA);
      case 1:
        return const Color(0xFF93C5FD);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  String get intensityLabel {
    switch (intensityLevel) {
      case 5:
        return 'Very High';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      case 1:
        return 'Very Low';
      default:
        return 'Not Worked';
    }
  }
}
