import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/common_config_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class ConfigDataSource {
  static const _configKey = "ConfigKey";
  static const _commonConfigKey = "CommonConfigKey";

  final _log = Logger('ConfigDataSource');
  final HiveDBProvider _hive;

  ConfigDataSource(this._hive);

  Future<bool> configInitialized() async =>
      _hive.configBox.containsKey(_configKey);

  Future<bool> commonConfigInitialized() async =>
      _hive.commonConfigBox.containsKey(_commonConfigKey);

  Future<void> initializeConfig() async =>
      _hive.configBox.put(_configKey, ConfigDBO.empty());

  Future<void> initializeCommonConfig() async {
    _hive.commonConfigBox.put(_commonConfigKey, CommonConfigDBO.empty());
  }

  Future<void> addConfig(ConfigDBO configDBO) async {
    _log.fine('Adding new config item to db');
    await _hive.configBox.put(_configKey, configDBO);
  }

  Future<void> setConfigAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    _log.fine(
        'Updating config hasAcceptedAnonymousData to $hasAcceptedAnonymousData');
    final config = _hive.configBox.get(_configKey) ?? ConfigDBO.empty();
    config.hasAcceptedSendAnonymousData = hasAcceptedAnonymousData;
    config.hasExplicitCrashConsent = true;
    await _hive.configBox.put(_configKey, config);
  }

  Future<AppThemeDBO> getAppTheme() async {
    final config = _hive.commonConfigBox.get(_commonConfigKey);
    return config?.selectedAppTheme ?? AppThemeDBO.defaultTheme;
  }

  Future<void> setConfigAppTheme(AppThemeDBO appTheme) async {
    _log.fine('Updating config appTheme to $appTheme');
    final config = _hive.commonConfigBox.get(_commonConfigKey);
    config?.selectedAppTheme = appTheme;
    await config?.save();
  }

  Future<void> setSupabaseSyncEnabled(bool enabled) async {
    _log.fine('Updating config supabaseSyncEnabled to $enabled');
    final config = _hive.configBox.get(_configKey);
    config?.supabaseSyncEnabled = enabled;
    await config?.save();
  }

  Future<bool> getSupabaseSyncEnabled() async {
    final config = _hive.configBox.get(_configKey);
    return config?.supabaseSyncEnabled ?? true;
  }

  Future<double> getKcalAdjustment() async {
    final config = _hive.configBox.get(_configKey);
    return config?.userKcalAdjustment ?? 0;
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    _log.fine('Updating config kcalAdjustment to $kcalAdjustment');
    final config = _hive.configBox.get(_configKey);
    config?.userKcalAdjustment = kcalAdjustment;
    await config?.save();
  }

  Future<void> setConfigCarbGoal(double carbGoal) async {
    _log.fine('Updating config carbGoal to $carbGoal');
    final config = _hive.configBox.get(_configKey);
    config?.userCarbGoal = carbGoal;
    await config?.save();
  }

  Future<void> setConfigProteinGoal(double proteinGoal) async {
    _log.fine('Updating config proteinGoal to $proteinGoal');
    final config = _hive.configBox.get(_configKey);
    config?.userProteinGoal = proteinGoal;
    await config?.save();
  }

  Future<void> setConfigFatGoal(double fatGoal) async {
    _log.fine('Updating config fatGoal to $fatGoal');
    final config = _hive.configBox.get(_configKey);
    config?.userFatGoal = fatGoal;
    await config?.save();
  }

  Future<ConfigDBO> getConfig() async {
    return _hive.configBox.get(_configKey) ?? ConfigDBO.empty();
  }

  Future<CommonConfigDBO> getCommonConfig() async {
    return _hive.commonConfigBox.get(_commonConfigKey) ??
        CommonConfigDBO.empty();
  }

  Future<bool> getHasAcceptedAnonymousData() async {
    final config = _hive.configBox.get(_configKey);
    return config != null &&
        config.hasExplicitCrashConsent &&
        config.hasAcceptedSendAnonymousData;
  }

  Future<void> setLastDataUpdate(DateTime date) async {
    final config = _hive.configBox.get(_configKey);
    config?.lastDataUpdate = date;
    await config?.save();
  }

  Future<DateTime?> getLastDataUpdate() async {
    final config = _hive.configBox.get(_configKey);
    return config?.lastDataUpdate;
  }
}
