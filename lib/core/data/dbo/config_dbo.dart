import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

part 'config_dbo.g.dart';

/// Used to store config data that is linked to a user
@HiveType(typeId: 13)
@JsonSerializable() // Used for exporting to JSON
class ConfigDBO extends HiveObject {
  @HiveField(0)
  bool hasAcceptedDisclaimer;
  @HiveField(1)
  bool hasAcceptedPolicy;
  @HiveField(2)
  bool hasAcceptedSendAnonymousData;
  // Hive field 3 is retired; the other field IDs must remain unchanged.
  @HiveField(4)
  double? userKcalAdjustment;
  @HiveField(5)
  double? userCarbGoal;
  @HiveField(6)
  double? userProteinGoal;
  @HiveField(7)
  double? userFatGoal;
  @HiveField(8)
  DateTime? lastDataUpdate;
  @HiveField(9)
  bool supabaseSyncEnabled;
  @HiveField(10, defaultValue: false)
  bool hasExplicitCrashConsent;

  ConfigDBO(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy,
      this.hasAcceptedSendAnonymousData,
      {this.userKcalAdjustment,
      this.lastDataUpdate,
      this.hasExplicitCrashConsent = false,
      this.supabaseSyncEnabled = true});

  factory ConfigDBO.empty() => ConfigDBO(true, false, false)
    ..userCarbGoal = 250
    ..userProteinGoal = 120
    ..userFatGoal = 60
    ..supabaseSyncEnabled = true;

  factory ConfigDBO.fromConfigEntity(ConfigEntity entity) => ConfigDBO(
      entity.hasAcceptedDisclaimer,
      entity.hasAcceptedPolicy,
      entity.hasAcceptedSendAnonymousData,
      hasExplicitCrashConsent: entity.hasAcceptedSendAnonymousData,
      lastDataUpdate: entity.lastDataUpdate,
      supabaseSyncEnabled: entity.supabaseSyncEnabled);

  factory ConfigDBO.fromJson(Map<String, dynamic> json) =>
      _$ConfigDBOFromJson(json);

  Map<String, dynamic> toJson() => _$ConfigDBOToJson(this);
}
