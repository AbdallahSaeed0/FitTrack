// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_photo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgressPhotoModelAdapter extends TypeAdapter<ProgressPhotoModel> {
  @override
  final int typeId = 7;

  @override
  ProgressPhotoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressPhotoModel(
      id: fields[0] as String,
      photoPath: fields[1] as String,
      dateTaken: fields[2] as DateTime,
      weightKg: fields[3] as double?,
      notes: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressPhotoModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.photoPath)
      ..writeByte(2)
      ..write(obj.dateTaken)
      ..writeByte(3)
      ..write(obj.weightKg)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressPhotoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
