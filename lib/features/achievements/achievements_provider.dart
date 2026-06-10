import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/meal_log_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'achievement_model.dart';

const _kKey = 'achievements_v1';

List<AchievementModel> _defaults() => [
      // Consistency
      AchievementModel(
          id: 'first_workout',
          title: 'First Rep',
          description: 'Complete your first workout',
          emoji: '🏋️',
          category: AchievementCategory.consistency,
          targetProgress: 1),
      AchievementModel(
          id: 'workouts_7',
          title: 'Week Warrior',
          description: 'Complete 7 workouts',
          emoji: '⚡',
          category: AchievementCategory.consistency,
          targetProgress: 7),
      AchievementModel(
          id: 'workouts_30',
          title: 'Month Grind',
          description: 'Complete 30 workouts',
          emoji: '🔥',
          category: AchievementCategory.consistency,
          targetProgress: 30),
      AchievementModel(
          id: 'workouts_100',
          title: 'Centurion',
          description: 'Complete 100 workouts',
          emoji: '💯',
          category: AchievementCategory.consistency,
          targetProgress: 100),
      AchievementModel(
          id: 'streak_7',
          title: '7-Day Streak',
          description: 'Train 7 days in a row',
          emoji: '🗓️',
          category: AchievementCategory.consistency,
          targetProgress: 7),
      AchievementModel(
          id: 'streak_30',
          title: '30-Day Legend',
          description: 'Train 30 days in a row',
          emoji: '🏆',
          category: AchievementCategory.consistency,
          targetProgress: 30),
      // Strength
      AchievementModel(
          id: 'first_pr',
          title: 'Record Breaker',
          description: 'Set your first personal record',
          emoji: '🥇',
          category: AchievementCategory.strength,
          targetProgress: 1),
      AchievementModel(
          id: 'prs_10',
          title: 'PR Machine',
          description: 'Set 10 different exercise PRs',
          emoji: '📈',
          category: AchievementCategory.strength,
          targetProgress: 10),
      AchievementModel(
          id: 'volume_session_1k',
          title: 'Ton Crusher',
          description: 'Lift 1,000 kg in a single workout',
          emoji: '💪',
          category: AchievementCategory.strength,
          targetProgress: 1000),
      AchievementModel(
          id: 'volume_total_100k',
          title: 'Volume King',
          description: 'Lift 100,000 kg total across all workouts',
          emoji: '👑',
          category: AchievementCategory.strength,
          targetProgress: 100000),
      // Milestones
      AchievementModel(
          id: 'days_30',
          title: 'One Month Strong',
          description: 'Use FitTrack for 30 days',
          emoji: '📅',
          category: AchievementCategory.milestones,
          targetProgress: 30),
      AchievementModel(
          id: 'days_180',
          title: 'Half Year Hero',
          description: 'Use FitTrack for 6 months',
          emoji: '🌟',
          category: AchievementCategory.milestones,
          targetProgress: 180),
      AchievementModel(
          id: 'days_365',
          title: 'Year One',
          description: 'Use FitTrack for a full year',
          emoji: '🎂',
          category: AchievementCategory.milestones,
          targetProgress: 365),
      // Nutrition
      AchievementModel(
          id: 'nutrition_7',
          title: 'Clean Eater',
          description: 'Log meals 7 days in a row',
          emoji: '🥗',
          category: AchievementCategory.nutrition,
          targetProgress: 7),
      AchievementModel(
          id: 'nutrition_30',
          title: 'Nutrition Ninja',
          description: 'Log meals 30 days in a row',
          emoji: '🥦',
          category: AchievementCategory.nutrition,
          targetProgress: 30),
      // Dedication
      AchievementModel(
          id: 'early_bird',
          title: 'Early Bird',
          description: 'Complete a workout before 7 AM',
          emoji: '🌅',
          category: AchievementCategory.dedication,
          targetProgress: 1),
      AchievementModel(
          id: 'night_owl',
          title: 'Night Owl',
          description: 'Complete a workout after 9 PM',
          emoji: '🌙',
          category: AchievementCategory.dedication,
          targetProgress: 1),
    ];

int _computeStreak(List<WorkoutSessionModel> sessions) {
  if (sessions.isEmpty) return 0;
  final dates = sessions
      .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  int streak = 0;
  DateTime current = dates.first;
  for (final d in dates) {
    if (current.difference(d).inDays <= 1) {
      streak++;
      current = d;
    } else {
      break;
    }
  }
  return streak;
}

int _nutritionStreak() {
  try {
    final logs = MealLogRepository.instance.getAll();
    if (logs.isEmpty) return 0;
    final dates = logs
        .map((l) => DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime current = dates.first;
    for (final d in dates) {
      if (current.difference(d).inDays <= 1) {
        streak++;
        current = d;
      } else {
        break;
      }
    }
    return streak;
  } catch (_) {
    return 0;
  }
}

class AchievementsNotifier extends Notifier<List<AchievementModel>> {
  @override
  List<AchievementModel> build() {
    Future.microtask(_load);
    return _defaults();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final savedMap = {for (final item in list) item['id'] as String: item};
      state = _defaults().map((a) {
        final saved = savedMap[a.id];
        return saved != null ? a.applyJson(saved) : a;
      }).toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kKey, jsonEncode(state.map((a) => a.toJson()).toList()));
  }

  /// Call after a workout is completed. Returns newly unlocked achievements.
  Future<List<AchievementModel>> checkAfterWorkout(
      WorkoutSessionModel session) async {
    final allSessions = SessionRepository.instance
        .getAll()
        .where((s) => s.completed)
        .toList();
    final totalWorkouts = allSessions.length;
    final streak = _computeStreak(allSessions);
    final nutStreak = _nutritionStreak();

    // Count exercises that have a max weight (distinct PRs)
    final Map<String, double> exerciseMax = {};
    double totalVolume = 0;
    double sessionVolume = 0;

    for (final s in allSessions) {
      for (final ex in s.exercises) {
        for (final set in ex.sets) {
          if (!set.isBodyweight) {
            final key = ex.exerciseName.toLowerCase().trim();
            final prev = exerciseMax[key] ?? 0;
            if (set.weight > prev) exerciseMax[key] = set.weight;
            totalVolume += set.weight * set.reps;
          }
        }
      }
    }
    final prCount = exerciseMax.length;

    for (final ex in session.exercises) {
      for (final set in ex.sets) {
        sessionVolume += set.weight * set.reps;
      }
    }

    final firstSession = allSessions.isEmpty
        ? DateTime.now()
        : allSessions
            .reduce((a, b) =>
                a.startTime.isBefore(b.startTime) ? a : b)
            .startTime;
    final daysSinceFirst =
        DateTime.now().difference(firstSession).inDays + 1;

    final updated = List<AchievementModel>.from(state);
    final newlyUnlocked = <AchievementModel>[];
    final now = DateTime.now();

    for (int i = 0; i < updated.length; i++) {
      final a = updated[i];
      if (a.isUnlocked) continue;

      int newProgress = a.currentProgress;
      switch (a.id) {
        case 'first_workout':
          newProgress = totalWorkouts.clamp(0, 1);
          break;
        case 'workouts_7':
          newProgress = totalWorkouts.clamp(0, 7);
          break;
        case 'workouts_30':
          newProgress = totalWorkouts.clamp(0, 30);
          break;
        case 'workouts_100':
          newProgress = totalWorkouts.clamp(0, 100);
          break;
        case 'streak_7':
          newProgress = streak.clamp(0, 7);
          break;
        case 'streak_30':
          newProgress = streak.clamp(0, 30);
          break;
        case 'first_pr':
          newProgress = prCount.clamp(0, 1);
          break;
        case 'prs_10':
          newProgress = prCount.clamp(0, 10);
          break;
        case 'volume_session_1k':
          newProgress = sessionVolume.round().clamp(0, 1000);
          break;
        case 'volume_total_100k':
          newProgress = totalVolume.round().clamp(0, 100000);
          break;
        case 'days_30':
          newProgress = daysSinceFirst.clamp(0, 30);
          break;
        case 'days_180':
          newProgress = daysSinceFirst.clamp(0, 180);
          break;
        case 'days_365':
          newProgress = daysSinceFirst.clamp(0, 365);
          break;
        case 'nutrition_7':
          newProgress = nutStreak.clamp(0, 7);
          break;
        case 'nutrition_30':
          newProgress = nutStreak.clamp(0, 30);
          break;
        case 'early_bird':
          newProgress = allSessions.any((s) => s.startTime.hour < 7) ? 1 : 0;
          break;
        case 'night_owl':
          newProgress =
              allSessions.any((s) => s.startTime.hour >= 21) ? 1 : 0;
          break;
      }

      var next = a.copyWith(currentProgress: newProgress);
      if (newProgress >= a.targetProgress) {
        next = next.copyWith(isUnlocked: true, unlockedDate: now);
        newlyUnlocked.add(next);
      }
      updated[i] = next;
    }

    state = updated;
    await _persist();
    return newlyUnlocked;
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, List<AchievementModel>>(
        AchievementsNotifier.new);
