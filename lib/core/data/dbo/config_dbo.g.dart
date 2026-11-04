// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_dbo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfigDBOAdapter extends TypeAdapter<ConfigDBO> {
  @override
  final int typeId = 13;

  @override
  ConfigDBO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfigDBO(
      fields[0] as bool,
      fields[1] as bool,
      fields[2] as bool,
      userKcalAdjustment: fields[4] as double?,
      lastDataUpdate: fields[8] as DateTime?,
      hasExplicitCrashConsent: fields[10] == null ? false : fields[10] as bool,
      supabaseSyncEnabled: fields[9] as bool,
    )
      ..userCarbGoal = fields[5] as double?
      ..userProteinGoal = fields[6] as double?
      ..userFatGoal = fields[7] as double?;
  }

  @override
  void write(BinaryWriter writer, ConfigDBO obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.hasAcceptedDisclaimer)
      ..writeByte(1)
      ..write(obj.hasAcceptedPolicy)
      ..writeByte(2)
      ..write(obj.hasAcceptedSendAnonymousData)
      ..writeByte(4)
      ..write(obj.userKcalAdjustment)
      ..writeByte(5)
      ..write(obj.userCarbGoal)
      ..writeByte(6)
      ..write(obj.userProteinGoal)
      ..writeByte(7)
      ..write(obj.userFatGoal)
      ..writeByte(8)
      ..write(obj.lastDataUpdate)
      ..writeByte(9)
      ..write(obj.supabaseSyncEnabled)
      ..writeByte(10)
      ..write(obj.hasExplicitCrashConsent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigDBOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigDBO _$ConfigDBOFromJson(Map<String, dynamic> json) => ConfigDBO(
      json['hasAcceptedDisclaimer'] as bool,
      json['hasAcceptedPolicy'] as bool,
      json['hasAcceptedSendAnonymousData'] as bool,
      userKcalAdjustment: (json['userKcalAdjustment'] as num?)?.toDouble(),
      lastDataUpdate: json['lastDataUpdate'] == null
          ? null
          : DateTime.parse(json['lastDataUpdate'] as String),
      hasExplicitCrashConsent:
          json['hasExplicitCrashConsent'] as bool? ?? false,
      supabaseSyncEnabled: json['supabaseSyncEnabled'] as bool? ?? true,
    )
      ..userCarbGoal = (json['userCarbGoal'] as num?)?.toDouble()
      ..userProteinGoal = (json['userProteinGoal'] as num?)?.toDouble()
      ..userFatGoal = (json['userFatGoal'] as num?)?.toDouble();

Map<String, dynamic> _$ConfigDBOToJson(ConfigDBO instance) => <String, dynamic>{
      'hasAcceptedDisclaimer': instance.hasAcceptedDisclaimer,
      'hasAcceptedPolicy': instance.hasAcceptedPolicy,
      'hasAcceptedSendAnonymousData': instance.hasAcceptedSendAnonymousData,
      'userKcalAdjustment': instance.userKcalAdjustment,
      'userCarbGoal': instance.userCarbGoal,
      'userProteinGoal': instance.userProteinGoal,
      'userFatGoal': instance.userFatGoal,
      'lastDataUpdate': instance.lastDataUpdate?.toIso8601String(),
      'supabaseSyncEnabled': instance.supabaseSyncEnabled,
      'hasExplicitCrashConsent': instance.hasExplicitCrashConsent,
    };
