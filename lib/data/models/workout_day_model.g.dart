// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_day_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      exercises: (fields[4] as List?)?.cast<ExerciseModel>(),
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
