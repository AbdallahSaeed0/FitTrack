import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 6)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  double height;

  @HiveField(3)
  double weight;

  @HiveField(4)
  bool useKg;

  @HiveField(5)
  bool isFirstLaunch;

  @HiveField(6)
  String? photoPath;

  @HiveField(7)
  String? fitnessGoal; // 'muscle', 'fat_loss', 'recomp', 'maintenance'

  UserProfileModel({
    this.name = 'Abdallah',
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
}
