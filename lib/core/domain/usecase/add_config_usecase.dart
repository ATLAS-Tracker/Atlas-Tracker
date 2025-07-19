import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class AddConfigUsecase {
  final ConfigRepository _configRepository;

  AddConfigUsecase(this._configRepository);

  Future<void> addConfig(ConfigEntity configEntity) async {
    _configRepository.updateConfig(configEntity);
  }

  Future<void> setConfigHasAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    _configRepository
        .setConfigHasAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  Future<void> setConfigAppTheme(AppThemeEntity appTheme) async {
    await _configRepository.setConfigAppTheme(appTheme);
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    _configRepository.setConfigUsesImperialUnits(usesImperialUnits);
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    _configRepository.setConfigKcalAdjustment(kcalAdjustment);
  }

  Future<void> setConfigMacroGoals(
      double carbGoal, double proteinGoal, double fatGoal) async {
    _configRepository.setUserMacroGoals(carbGoal, proteinGoal, fatGoal);
  }
}
