import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

class ConfigEntity extends Equatable {
  final bool hasAcceptedDisclaimer;
  final bool hasAcceptedPolicy;
  final bool hasAcceptedSendAnonymousData;
  final double? userKcalAdjustment;
  final double? userCarbGoal;
  final double? userProteinGoal;
  final double? userFatGoal;
  final DateTime? lastDataUpdate;
  final bool supabaseSyncEnabled;

  const ConfigEntity(this.hasAcceptedDisclaimer, this.hasAcceptedPolicy,
      this.hasAcceptedSendAnonymousData,
      {this.userKcalAdjustment,
      this.userCarbGoal,
      this.userProteinGoal,
      this.userFatGoal,
      this.lastDataUpdate,
      this.supabaseSyncEnabled = true});

  factory ConfigEntity.fromConfigDBO(ConfigDBO dbo) => ConfigEntity(
        dbo.hasAcceptedDisclaimer,
        dbo.hasAcceptedPolicy,
        dbo.hasAcceptedSendAnonymousData && dbo.hasExplicitCrashConsent,
        userKcalAdjustment: dbo.userKcalAdjustment,
        userCarbGoal: dbo.userCarbGoal,
        userProteinGoal: dbo.userProteinGoal,
        userFatGoal: dbo.userFatGoal,
        lastDataUpdate: dbo.lastDataUpdate,
        supabaseSyncEnabled: dbo.supabaseSyncEnabled,
      );

  @override
  List<Object?> get props => [
        hasAcceptedDisclaimer,
        hasAcceptedPolicy,
        hasAcceptedSendAnonymousData,
        userKcalAdjustment,
        userCarbGoal,
        userProteinGoal,
        userFatGoal,
        lastDataUpdate,
        supabaseSyncEnabled,
      ];
}
