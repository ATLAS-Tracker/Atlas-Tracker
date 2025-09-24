// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps_date_dbo.dart';

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
      lastDate: fields[0] as DateTime?,
      nowDate: fields[1] as DateTime?,
      lastSteps: fields[2] as int?,
      nowSteps: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StepsDateDbo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lastDate)
      ..writeByte(1)
      ..write(obj.nowDate)
      ..writeByte(2)
      ..write(obj.lastSteps)
      ..writeByte(3)
      ..write(obj.nowSteps);
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
