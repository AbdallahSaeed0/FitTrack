class ApiConstants {
  static const String baseUrl = 'https://exercisedb.dev/api/v1';
  static const String gifBaseUrl = 'https://static.exercisedb.dev/media';

  static String exerciseGifUrl(String exerciseId) => '$gifBaseUrl/$exerciseId.gif';

  static const String allExercises = '/exercises';
  static const String exerciseByName = '/exercises/name';
  static const String exerciseByBodyPart = '/exercises/bodyPart';
  static const String exerciseByEquipment = '/exercises/equipment';
  static const String exerciseByTarget = '/exercises/target';
}
