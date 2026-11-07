import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class GetKcalGoalUsecase {
  GetKcalGoalUsecase();

  Future<double> getKcalGoal({DateTime? day}) async {
    final getMacroGoalUsecase = locator<GetMacroGoalUsecase>();
    final protein = await getMacroGoalUsecase.getProteinsGoal(day: day);
    final carbs = await getMacroGoalUsecase.getCarbsGoal(day: day);
    final fats = await getMacroGoalUsecase.getFatsGoal(day: day);
    final kcal = macroCalories(carbs: carbs, fat: fats, protein: protein);
    return kcal;
  }
}
