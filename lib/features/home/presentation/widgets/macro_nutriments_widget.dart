import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MacroNutrientsView extends StatelessWidget {
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;

  const MacroNutrientsView({
    super.key,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _MacronutrientItem(
              intake: totalCarbsIntake,
              goal: totalCarbsGoal,
              label: S.of(context).carbsLabel,
              color: carbColor,
            ),
          ),
          Expanded(
            child: _MacronutrientItem(
              intake: totalFatsIntake,
              goal: totalFatsGoal,
              label: S.of(context).fatLabel,
              color: fatColor,
            ),
          ),
          Expanded(
            child: _MacronutrientItem(
              intake: totalProteinsIntake,
              goal: totalProteinsGoal,
              label: S.of(context).proteinLabel,
              color: proteinColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacronutrientItem extends StatelessWidget {
  final double intake;
  final double goal;
  final String label;
  final Color color;

  const _MacronutrientItem({
    required this.intake,
    required this.goal,
    required this.label,
    required this.color,
  });

  double _getGoalPercentage(double goal, double supplied) {
    if (supplied <= 0 || goal <= 0) {
      return 0;
    } else if (supplied > goal) {
      return 1;
    } else {
      return supplied / goal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: 15.0,
          lineWidth: 6.0,
          animation: true,
          percent: _getGoalPercentage(goal, intake),
          progressColor: color,
          backgroundColor: color.withAlpha(50),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8.0),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            '${intake.toInt()}/${goal.toInt()} g',
            style: theme.textTheme.titleSmall?.copyWith(
              color: onSurfaceColor,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurfaceColor,
            ),
          ),
        ),
      ],
    );
  }
}
