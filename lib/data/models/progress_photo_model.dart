import 'package:hive/hive.dart';

part 'progress_photo_model.g.dart';

@HiveType(typeId: 7)
class ProgressPhotoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String photoPath; // Absolute path to the local image file

  @HiveField(2)
  DateTime dateTaken;

  @HiveField(3)
  double? weightKg; // Optional bodyweight at the time of the photo

  @HiveField(4)
  String? notes;

  ProgressPhotoModel({
    required this.id,
    required this.photoPath,
    required this.dateTaken,
    this.weightKg,
    this.notes,
  });
}
