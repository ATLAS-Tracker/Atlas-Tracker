import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/features/add_weight/presentation/widgets/weight_trend_color.dart';

void main() {
  const cases = [
    (UserWeightGoalEntity.loseWeight, -0.5, true),
    (UserWeightGoalEntity.loseWeight, 0.0, false),
    (UserWeightGoalEntity.loseWeight, 0.5, false),
    (UserWeightGoalEntity.gainWeight, -0.5, false),
    (UserWeightGoalEntity.gainWeight, 0.0, false),
    (UserWeightGoalEntity.gainWeight, 0.5, true),
    (UserWeightGoalEntity.maintainWeight, -0.5, false),
    (UserWeightGoalEntity.maintainWeight, -0.2, true),
    (UserWeightGoalEntity.maintainWeight, 0.0, true),
    (UserWeightGoalEntity.maintainWeight, 0.2, true),
    (UserWeightGoalEntity.maintainWeight, 0.5, false),
  ];
  for (final colors in [lightColorScheme, darkColorScheme]) {
    for (final (goal, deltaKg, isOnTarget) in cases) {
      test('${colors.brightness} $goal variation $deltaKg kg', () {
        expect(weightTrendColor(deltaKg: deltaKg, goal: goal, colors: colors),
            isOnTarget ? lunchColor : colors.error);
      });
    }
  }
}
