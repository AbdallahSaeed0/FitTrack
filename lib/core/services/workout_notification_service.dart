import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the persistent workout notification shown in the status bar.
/// Only active on Android (iOS foreground notifications work differently).
class WorkoutNotificationService {
  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();
  WorkoutNotificationService._();

  static const int _kNotifId = 888;
  static const String _kChannelId = 'workout_session';
  static const String _kChannelName = 'Workout Session';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Show or update the persistent workout notification.
  ///
  /// [dayName]    — e.g. "Push"
  /// [exerciseName] — current exercise, e.g. "Dumbbell Bench Press"
  /// [exerciseProgress] — e.g. "3 / 7" (current / total exercises)
  /// [nextExerciseName] — name of next exercise, or null if this is the last
  /// [restRemaining]  — seconds left in rest timer, or null if not resting
  Future<void> showWorkoutNotification({
    required String dayName,
    required String exerciseName,
    required String exerciseProgress,
    String? nextExerciseName,
    int? restRemaining,
  }) async {
    if (kIsWeb) return;
    await init();

    final String title = '🏋️ $dayName  ·  $exerciseProgress';
    final String body;

    if (restRemaining != null && restRemaining > 0) {
      final mins = restRemaining ~/ 60;
      final secs = restRemaining % 60;
      final timeStr =
          mins > 0 ? '${mins}m ${secs.toString().padLeft(2, '0')}s' : '${secs}s';
      body = nextExerciseName != null
          ? 'Rest $timeStr  ·  Next: $nextExerciseName'
          : 'Rest $timeStr  ·  Last exercise';
    } else {
      body = nextExerciseName != null
          ? '$exerciseName  ·  Up next: $nextExerciseName'
          : exerciseName;
    }

    final androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: 'Live workout session progress',
      importance: Importance.low,     // low = no sound/vibration on update
      priority: Priority.low,
      ongoing: true,                  // non-dismissable while workout is active
      onlyAlertOnce: true,            // suppress subsequent alert sounds
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF38BDF8), // primaryBlue
      enableVibration: false,
      playSound: false,
    );

    await _plugin.show(
      _kNotifId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Dismiss the workout notification (call when workout ends).
  Future<void> cancelWorkoutNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_kNotifId);
  }
}
