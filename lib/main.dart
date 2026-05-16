import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/water_reminder_service.dart';
import 'core/utils/program_seeder.dart';
import 'data/services/hive_service.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

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

  await ProgramSeeder.seedIfEmpty();

  runApp(
    const ProviderScope(
      child: FitTrackApp(),
    ),
  );
}
