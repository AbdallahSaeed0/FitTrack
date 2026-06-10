class UserProfileModel {
  String name;
  int age;
  double height;
  double weight;
  bool useKg;
  bool isFirstLaunch;
  String? photoPath;
  String? fitnessGoal;

  UserProfileModel({
    this.name = 'User',
    this.age = 25,
    this.height = 175,
    this.weight = 75,
    this.useKg = true,
    this.isFirstLaunch = true,
    this.photoPath,
    this.fitnessGoal,
  });

  UserProfileModel copyWith({
    String? name,
    int? age,
    double? height,
    double? weight,
    bool? useKg,
    bool? isFirstLaunch,
    String? photoPath,
    bool clearPhoto = false,
    String? fitnessGoal,
  }) {
    return UserProfileModel(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      useKg: useKg ?? this.useKg,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
    );
  }

  /// Full serialization — used for **local cache** only.
  /// Includes `photo_path` (device-local, not pushed to Supabase).
  Map<String, dynamic> toRow() => {
        'name': name,
        'age': age,
        'height': height,
        'weight': weight,
        'use_kg': useKg,
        'is_first_launch': isFirstLaunch,
        'fitness_goal': fitnessGoal,
        'photo_path': photoPath,
      };

  /// Subset sent to Supabase — includes avatar_url (remote URL), not the
  /// device-local photo_path field used only for the local cache.
  Map<String, dynamic> toSupabaseRow() => {
        'name': name,
        'age': age,
        'height': height,
        'weight': weight,
        'use_kg': useKg,
        'is_first_launch': isFirstLaunch,
        'fitness_goal': fitnessGoal,
        // Only send to Supabase when it's an actual remote URL.
        if (photoPath != null && photoPath!.startsWith('http'))
          'avatar_url': photoPath,
      };

  factory UserProfileModel.fromRow(Map<String, dynamic> row) =>
      UserProfileModel(
        name: row['name'] as String? ?? 'User',
        age: (row['age'] as num?)?.toInt() ?? 25,
        height: (row['height'] as num?)?.toDouble() ?? 175,
        weight: (row['weight'] as num?)?.toDouble() ?? 75,
        useKg: row['use_kg'] as bool? ?? true,
        isFirstLaunch: row['is_first_launch'] as bool? ?? true,
        fitnessGoal: row['fitness_goal'] as String?,
        // Prefer remote avatar_url (persistent); fall back to local photo_path
        // (cached from before Supabase Storage was introduced).
        photoPath: (row['avatar_url'] as String?)?.isNotEmpty == true
            ? row['avatar_url'] as String
            : row['photo_path'] as String?,
      );
}
