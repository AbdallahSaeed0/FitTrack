// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseModelAdapter extends TypeAdapter<ExerciseModel> {
  @override
  final int typeId = 0;

  @override
  ExerciseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseModel(
      id: fields[0] as String,
      name: fields[1] as String,
      gifUrl: fields[2] as String,
      sets: fields[3] as int,
      repsFrom: fields[4] as String,
      repsTo: fields[5] as String,
      restTime: fields[6] as String,
      technique: fields[7] as String,
      isNew: fields[8] as bool,
      targetMuscles: (fields[9] as List?)?.cast<String>(),
      secondaryMuscles: (fields[10] as List?)?.cast<String>(),
      bodyParts: (fields[11] as List?)?.cast<String>(),
      equipments: (fields[12] as List?)?.cast<String>(),
      instructions: (fields[13] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.gifUrl)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.repsFrom)
      ..writeByte(5)
      ..write(obj.repsTo)
      ..writeByte(6)
      ..write(obj.restTime)
      ..writeByte(7)
      ..write(obj.technique)
      ..writeByte(8)
      ..write(obj.isNew)
      ..writeByte(9)
      ..write(obj.targetMuscles)
      ..writeByte(10)
      ..write(obj.secondaryMuscles)
      ..writeByte(11)
      ..write(obj.bodyParts)
      ..writeByte(12)
      ..write(obj.equipments)
      ..writeByte(13)
      ..write(obj.instructions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
