// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_day_model.dart';

// Eagerly converts stored objects to ExerciseModel.
// If any item is a raw Map (written before the adapter was registered) it is
// silently dropped; the seeder-version bump will re-seed fresh data.
List<ExerciseModel> _safeExerciseList(dynamic raw) {
  if (raw == null) return [];
  final list = raw as List;
  final result = <ExerciseModel>[];
  for (final item in list) {
    if (item is ExerciseModel) result.add(item);
    // Map items are silently skipped — stale data cleaned up by seeder v3
  }
  return result;
}

class WorkoutDayModelAdapter extends TypeAdapter<WorkoutDayModel> {
  @override
  final int typeId = 1;

  @override
  WorkoutDayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutDayModel(
      id: fields[0] as String,
      name: fields[1] as String,
      dayNumber: fields[2] as int,
      isRestDay: fields[3] as bool,
      exercises: _safeExerciseList(fields[4]),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutDayModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.dayNumber)
      ..writeByte(3)
      ..write(obj.isRestDay)
      ..writeByte(4)
      ..write(obj.exercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDayModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
