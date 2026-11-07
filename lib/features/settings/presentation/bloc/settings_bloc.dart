import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/app_const.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final log = Logger('SettingsBloc');

  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  SettingsBloc(
      this._getConfigUsecase,
      this._addConfigUsecase,
      this._addTrackedDayUsecase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase)
      : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoadingState());

      final userConfig = await _getConfigUsecase.getConfig();
      final commonConfig = await _getConfigUsecase.getCommonConfig();
      final appVersion = await AppConst.getVersionNumber();

      emit(SettingsLoadedState(appVersion,
          userConfig.hasAcceptedSendAnonymousData, commonConfig.appTheme));
    });
  }

  Future<void> setHasAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    await _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  void setAppTheme(AppThemeEntity appTheme) async {
    await _addConfigUsecase.setConfigAppTheme(appTheme);
  }

  Future<double> getKcalAdjustment() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userKcalAdjustment ?? 0;
  }

  Future<double?> getUserCarbGoal() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userCarbGoal;
  }

  Future<double?> getUserProteinGoal() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userProteinGoal;
  }

  Future<double?> getUserFatGoal() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userFatGoal;
  }

  void setKcalAdjustment(double kcalAdjustment) {
    _addConfigUsecase.setConfigKcalAdjustment(kcalAdjustment);
  }

  void setMacroGoals(double carbGoal, double proteinGoal, double fatGoal) {
    _addConfigUsecase.setConfigMacroGoals(carbGoal, proteinGoal, fatGoal);
  }

  void updateTrackedDay(DateTime day) async {
    final day = DateTime.now();
    final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
    final totalCarbsGoal = await _getMacroGoalUsecase.getCarbsGoal();
    final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal();
    final totalProteinGoal = await _getMacroGoalUsecase.getProteinsGoal();

    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);

    if (hasTrackedDay) {
      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
      await _addTrackedDayUsecase.updateDayMacroGoals(day,
          carbsGoal: totalCarbsGoal,
          fatGoal: totalFatGoal,
          proteinGoal: totalProteinGoal);
    }
  }
}
