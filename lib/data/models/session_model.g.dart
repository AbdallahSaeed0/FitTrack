// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

class LoggedSetModelAdapter extends TypeAdapter<LoggedSetModel> {
  @override
  final int typeId = 3;

  @override
  LoggedSetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoggedSetModel(
      setNumber: fields[0] as int,
      weight: fields[1] as double,
      reps: fields[2] as int,
      actualRestSeconds: fields[3] as int,
      notes: fields[4] as String?,
      loggedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LoggedSetModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.setNumber)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.actualRestSeconds)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.loggedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggedSetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LoggedExerciseModelAdapter extends TypeAdapter<LoggedExerciseModel> {
  @override
  final int typeId = 4;

  @override
  LoggedExerciseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoggedExerciseModel(
      exerciseId: fields[0] as String,
      exerciseName: fields[1] as String,
      sets: (fields[2] as List).cast<LoggedSetModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, LoggedExerciseModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.sets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggedExerciseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSessionModelAdapter extends TypeAdapter<WorkoutSessionModel> {
  @override
  final int typeId = 5;

  @override
  WorkoutSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSessionModel(
      id: fields[0] as String,
      programId: fields[1] as String,
      dayName: fields[2] as String,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      durationMinutes: fields[5] as int,
      exercises: (fields[6] as List).cast<LoggedExerciseModel>(),
      completed: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSessionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.programId)
      ..writeByte(2)
      ..write(obj.dayName)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.durationMinutes)
      ..writeByte(6)
      ..write(obj.exercises)
      ..writeByte(7)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
