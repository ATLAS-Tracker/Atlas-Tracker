// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps_date_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StepsDateDboAdapter extends TypeAdapter<StepsDateDbo> {
  @override
  final int typeId = 21;

  @override
  StepsDateDbo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StepsDateDbo(
      lastSteps: fields[0] as int,
      nowSteps: fields[1] as int,
      diff: fields[2] as int,
      lastDate: fields[3] as DateTime,
    )
      ..errorSteps = fields[4] as int
      ..initialStep = fields[5] as int;
  }

  @override
  void write(BinaryWriter writer, StepsDateDbo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.lastSteps)
      ..writeByte(1)
      ..write(obj.nowSteps)
      ..writeByte(2)
      ..write(obj.diff)
      ..writeByte(3)
      ..write(obj.lastDate)
      ..writeByte(4)
      ..write(obj.errorSteps)
      ..writeByte(5)
      ..write(obj.initialStep);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepsDateDboAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
