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

  Future<void> _ensureReady() => _hive.ensureReady();

  Future<bool> configInitialized() async {
    await _ensureReady();
    return _hive.configBox.containsKey(_configKey);
  }

  Future<bool> commonConfigInitialized() async {
    await _ensureReady();
    return _hive.commonConfigBox.containsKey(_commonConfigKey);
  }

  Future<void> initializeConfig() async {
    await _ensureReady();
    await _hive.configBox.put(_configKey, ConfigDBO.empty());
  }

  Future<void> initializeCommonConfig() async {
    await _ensureReady();
    _hive.commonConfigBox.put(_commonConfigKey, CommonConfigDBO.empty());
  }

  Future<void> addConfig(ConfigDBO configDBO) async {
    await _ensureReady();
    _log.fine('Adding new config item to db');
    _hive.configBox.put(_configKey, configDBO);
  }

  Future<void> setConfigAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    await _ensureReady();
    _log.fine(
        'Updating config hasAcceptedAnonymousData to $hasAcceptedAnonymousData');
    final config = _hive.configBox.get(_configKey);
    config?.hasAcceptedSendAnonymousData = hasAcceptedAnonymousData;
    await config?.save();
  }

  Future<AppThemeDBO> getAppTheme() async {
    await _ensureReady();
    final config = _hive.commonConfigBox.get(_commonConfigKey);
    return config?.selectedAppTheme ?? AppThemeDBO.defaultTheme;
  }

  Future<void> setConfigAppTheme(AppThemeDBO appTheme) async {
    await _ensureReady();
    _log.fine('Updating config appTheme to $appTheme');
    final config = _hive.commonConfigBox.get(_commonConfigKey);
    config?.selectedAppTheme = appTheme;
    await config?.save();
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    await _ensureReady();
    _log.fine('Updating config usesImperialUnits to $usesImperialUnits');
    final config = _hive.configBox.get(_configKey);
    config?.usesImperialUnits = usesImperialUnits;
    await config?.save();
  }

  Future<void> setSupabaseSyncEnabled(bool enabled) async {
    await _ensureReady();
    _log.fine('Updating config supabaseSyncEnabled to $enabled');
    final config = _hive.configBox.get(_configKey);
    config?.supabaseSyncEnabled = enabled;
    await config?.save();
  }

  Future<bool> getSupabaseSyncEnabled() async {
    await _ensureReady();
    final config = _hive.configBox.get(_configKey);
    return config?.supabaseSyncEnabled ?? true;
  }

  Future<double> getKcalAdjustment() async {
    await _ensureReady();
    final config = _hive.configBox.get(_configKey);
    return config?.userKcalAdjustment ?? 0;
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    await _ensureReady();
    _log.fine('Updating config kcalAdjustment to $kcalAdjustment');
    final config = _hive.configBox.get(_configKey);
    config?.userKcalAdjustment = kcalAdjustment;
    await config?.save();
  }

  Future<void> setConfigCarbGoal(double carbGoal) async {
    await _ensureReady();
    _log.fine('Updating config carbGoal to $carbGoal');
    final config = _hive.configBox.get(_configKey);
    config?.userCarbGoal = carbGoal;
    await config?.save();
  }

  Future<void> setConfigProteinGoal(double proteinGoal) async {
    await _ensureReady();
    _log.fine('Updating config proteinGoal to $proteinGoal');
    final config = _hive.configBox.get(_configKey);
    config?.userProteinGoal = proteinGoal;
    await config?.save();
  }

  Future<void> setConfigFatGoal(double fatGoal) async {
    await _ensureReady();
    _log.fine('Updating config fatGoal to $fatGoal');
    final config = _hive.configBox.get(_configKey);
    config?.userFatGoal = fatGoal;
    await config?.save();
  }

  Future<ConfigDBO> getConfig() async {
    await _ensureReady();
    return _hive.configBox.get(_configKey) ?? ConfigDBO.empty();
  }

  Future<CommonConfigDBO> getCommonConfig() async {
    await _ensureReady();
    return _hive.commonConfigBox.get(_commonConfigKey) ??
        CommonConfigDBO.empty();
  }

  Future<bool> getHasAcceptedAnonymousData() async {
    await _ensureReady();
    final config = _hive.configBox.get(_configKey);
    return config?.hasAcceptedSendAnonymousData ?? true;
  }

  Future<void> setLastDataUpdate(DateTime date) async {
    await _ensureReady();
    final config = _hive.configBox.get(_configKey);
    config?.lastDataUpdate = date;
    await config?.save();
  }

  Future<DateTime?> getLastDataUpdate() async {
    await _ensureReady();
    final config = _hive.configBox.get(_configKey);
    return config?.lastDataUpdate;
  }
}
