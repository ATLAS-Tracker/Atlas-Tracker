import 'package:opennutritracker/core/data/repository/macro_goal_repository.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class GetMacroGoalUsecase {
  final MacroGoalRepository _macroGoalRepository =
      locator<MacroGoalRepository>();

  static const defaultProteins = MacroGoalEntity.defaultProteins;
  static const defaultCarbs = MacroGoalEntity.defaultCarbs;
  static const defaultFats = MacroGoalEntity.defaultFats;

  GetMacroGoalUsecase();

  Future<double> getCarbsGoal({DateTime? day}) async {
    return MacroGoalEntity.forDay(
            await _macroGoalRepository.getMacroGoal(), day ?? DateTime.now())
        .carbs;
  }

  Future<double> getFatsGoal({DateTime? day}) async {
    return MacroGoalEntity.forDay(
            await _macroGoalRepository.getMacroGoal(), day ?? DateTime.now())
        .fats;
  }

  Future<double> getProteinsGoal({DateTime? day}) async {
    return MacroGoalEntity.forDay(
            await _macroGoalRepository.getMacroGoal(), day ?? DateTime.now())
        .proteins;
  }

  /// Optionnel : récupérer l'entité complète
  Future<MacroGoalEntity?> getMacroGoal() async {
    return await _macroGoalRepository.getMacroGoal();
  }
}
