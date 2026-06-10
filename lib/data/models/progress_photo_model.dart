class ProgressPhotoModel {
  String id;
  String photoPath;
  DateTime dateTaken;
  double? weightKg;
  String? notes;

  ProgressPhotoModel({
    required this.id,
    required this.photoPath,
    required this.dateTaken,
    this.weightKg,
    this.notes,
  });
}
