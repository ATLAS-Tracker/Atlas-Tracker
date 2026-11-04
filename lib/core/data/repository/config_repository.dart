import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/common_config_entity.dart';

class ConfigRepository {
  final ConfigDataSource _configDataSource;

  ConfigRepository(this._configDataSource);

  Future<void> updateConfig(ConfigEntity configEntity) async {
    final configDBO = ConfigDBO.fromConfigEntity(configEntity);
    await _configDataSource.addConfig(configDBO);
  }

  Future<void> setConfigHasAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    await _configDataSource
        .setConfigAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  Future<bool> getConfigHasAcceptedAnonymousData() async {
    return await _configDataSource.getHasAcceptedAnonymousData();
  }

  Future<AppThemeEntity> getConfigAppTheme() async {
    final appThemeDBO = await _configDataSource.getAppTheme();
    return AppThemeEntity.fromAppThemeDBO(appThemeDBO);
  }

  Future<void> setConfigAppTheme(AppThemeEntity appTheme) async {
    await _configDataSource
        .setConfigAppTheme(AppThemeDBO.fromAppThemeEntity(appTheme));
  }

  Future<ConfigEntity> getConfig() async {
    final configDBO = await _configDataSource.getConfig();
    return ConfigEntity.fromConfigDBO(configDBO);
  }

  Future<CommonConfigEntity> getCommonConfig() async {
    final commonConfigDBO = await _configDataSource.getCommonConfig();
    return CommonConfigEntity.fromConfigDBO(commonConfigDBO);
  }

  Future<ConfigDBO> getConfigDBO() async {
    final configDBO = await _configDataSource.getConfig();
    return configDBO;
  }

  Future<void> setSupabaseSyncEnabled(bool enabled) async {
    await _configDataSource.setSupabaseSyncEnabled(enabled);
  }

  Future<bool> getSupabaseSyncEnabled() async {
    return await _configDataSource.getSupabaseSyncEnabled();
  }

  Future<double> getConfigKcalAdjustment() async {
    return await _configDataSource.getKcalAdjustment();
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    _configDataSource.setConfigKcalAdjustment(kcalAdjustment);
  }

  Future<void> setUserMacroGoals(
      double carbs, double protein, double fat) async {
    _configDataSource.setConfigCarbGoal(carbs);
    _configDataSource.setConfigProteinGoal(protein);
    _configDataSource.setConfigFatGoal(fat);
  }

  Future<void> setLastDataUpdate(DateTime date) async {
    await _configDataSource.setLastDataUpdate(date);
  }

  Future<DateTime?> getLastDataUpdate() async {
    return await _configDataSource.getLastDataUpdate();
  }
}
