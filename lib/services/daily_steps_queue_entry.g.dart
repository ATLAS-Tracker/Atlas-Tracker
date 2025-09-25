// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_steps_queue_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyStepsQueueEntryAdapter extends TypeAdapter<DailyStepsQueueEntry> {
  @override
  final int typeId = 23;

  @override
  DailyStepsQueueEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStepsQueueEntry(
      date: fields[0] as DateTime,
      steps: fields[1] as int,
      queuedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStepsQueueEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.steps)
      ..writeByte(2)
      ..write(obj.queuedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStepsQueueEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
