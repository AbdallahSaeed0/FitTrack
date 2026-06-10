import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';
import 'core/services/local_cache_service.dart';
import 'core/services/water_reminder_service.dart';
import 'core/services/workout_notification_service.dart';
import 'core/utils/program_seeder.dart';
import 'data/repositories/meal_log_repository.dart';
import 'data/repositories/program_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/user_profile_repository.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  await LocalCacheService.init();
  await WorkoutNotificationService.instance.init();

  if (SupabaseService.isLoggedIn) {
    await _loadUserData();
  }

  runApp(
    const ProviderScope(
      child: FitTrackApp(),
    ),
  );
}

Future<void> _loadUserData() async {
  await Future.wait([
    UserProfileRepository.instance.init(),
    ProgramRepository.instance.init(),
    SessionRepository.instance.init(),
    MealLogRepository.instance.init(),
  ]);
  await ProgramSeeder.seedIfEmpty();

  WaterReminderService().initialize(
    onReminder: () {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Text('\u{1F4A7}', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Time to drink water! Stay hydrated.'),
            ],
          ),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    },
  );
  WaterReminderService().startReminders();
}
