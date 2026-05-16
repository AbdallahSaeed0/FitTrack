import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/workout_day_model.dart';
import '../models/program_model.dart';
import '../models/session_model.dart';
import '../models/user_profile_model.dart';
import '../models/progress_photo_model.dart';
import '../models/meal_log_model.dart';

class HiveService {
  static const String programsBox = 'programs';
  static const String sessionsBox = 'sessions';
  static const String exerciseCacheBox = 'exerciseCache';
  static const String userProfileBox = 'userProfile';
  static const String settingsBox = 'settings';
  static const String progressPhotosBox = 'progressPhotos';
  static const String mealLogsBox = 'mealLogs';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ExerciseModelAdapter());
    Hive.registerAdapter(WorkoutDayModelAdapter());
    Hive.registerAdapter(ProgramModelAdapter());
    Hive.registerAdapter(LoggedSetModelAdapter());
    Hive.registerAdapter(LoggedExerciseModelAdapter());
    Hive.registerAdapter(WorkoutSessionModelAdapter());
    Hive.registerAdapter(UserProfileModelAdapter());
    Hive.registerAdapter(ProgressPhotoModelAdapter());
    Hive.registerAdapter(MealLogAdapter());

    await Hive.openBox<ProgramModel>(programsBox);
    await Hive.openBox<WorkoutSessionModel>(sessionsBox);
    await Hive.openBox<ExerciseModel>(exerciseCacheBox);
    await Hive.openBox<UserProfileModel>(userProfileBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox<ProgressPhotoModel>(progressPhotosBox);
    await Hive.openBox<MealLog>(mealLogsBox);

    await _clearCorruptedExerciseCache();
    await _forceRepairProgramData();
  }

  // One-time cleanup: if the exercise cache was written before TypeAdapters were
  // registered the values are stored as raw Maps and will crash on read.
  // We clear it once; the cache is a pure performance layer and rebuilds itself.
  static Future<void> _clearCorruptedExerciseCache() async {
    const cleanedKey = 'exerciseCacheCleared_v1';
    final alreadyDone =
        Hive.box(settingsBox).get(cleanedKey, defaultValue: false) as bool;
    if (alreadyDone) return;

    await Hive.box<ExerciseModel>(exerciseCacheBox).clear();
    await Hive.box(settingsBox).put(cleanedKey, true);
  }

  // One-time force repair: clears all programs so any exercises stored as raw
  // Maps (from before ExerciseModel adapter was properly registered) are wiped.
  // Resets the seeder version so ProgramSeeder re-seeds fresh data immediately.
  static Future<void> _forceRepairProgramData() async {
    const repairKey = 'programDataForceRepairedV2';
    final alreadyDone =
        Hive.box(settingsBox).get(repairKey, defaultValue: false) as bool;
    if (alreadyDone) return;

    await Hive.box<ProgramModel>(programsBox).clear();
    await Hive.box(settingsBox).delete('seederVersion');
    await Hive.box(settingsBox).put(repairKey, true);
  }

  static Box<ProgramModel> get programs => Hive.box<ProgramModel>(programsBox);
  static Box<WorkoutSessionModel> get sessions =>
      Hive.box<WorkoutSessionModel>(sessionsBox);
  static Box<ExerciseModel> get exerciseCache =>
      Hive.box<ExerciseModel>(exerciseCacheBox);
  static Box<UserProfileModel> get userProfile =>
      Hive.box<UserProfileModel>(userProfileBox);
  static Box get settings => Hive.box(settingsBox);
  static Box<ProgressPhotoModel> get progressPhotos =>
      Hive.box<ProgressPhotoModel>(progressPhotosBox);
  static Box<MealLog> get mealLogs => Hive.box<MealLog>(mealLogsBox);
}
