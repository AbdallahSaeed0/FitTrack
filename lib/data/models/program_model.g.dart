// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgramModelAdapter extends TypeAdapter<ProgramModel> {
  @override
  final int typeId = 2;

  @override
  ProgramModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgramModel(
      id: fields[0] as String,
      name: fields[1] as String,
      isActive: fields[2] as bool,
      days: (fields[3] as List?)?.cast<WorkoutDayModel>(),
      splitType: fields[4] as String,
      goal: fields[5] as String,
      experienceLevel: fields[6] as String,
      techniques: (fields[7] as List?)?.cast<String>(),
      currentDayIndex: fields[8] as int,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProgramModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.days)
      ..writeByte(4)
      ..write(obj.splitType)
      ..writeByte(5)
      ..write(obj.goal)
      ..writeByte(6)
      ..write(obj.experienceLevel)
      ..writeByte(7)
      ..write(obj.techniques)
      ..writeByte(8)
      ..write(obj.currentDayIndex)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgramModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
