import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DashboardWidget extends StatelessWidget {
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final int dailyStepCount;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;
  final UserWeightEntity? userWeight;
  final double? weeklyWeightDelta;
  final double targetWeight;
  final UserWeightGoalEntity userWeightGoal;
  final bool usesImperialUnits;

  const DashboardWidget({
    super.key,
    required this.totalKcalSupplied,
    required this.dailyStepCount,
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
    required this.userWeight,
    required this.weeklyWeightDelta,
    required this.targetWeight,
    required this.userWeightGoal,
    required this.usesImperialUnits,
  });

  double _progress(double supplied, double goal) {
    if (supplied <= 0 || goal <= 0) return 0;
    if (supplied >= goal) return 1;
    return supplied / goal;
  }

  double _displayWeight(double weightKg) {
    return usesImperialUnits ? UnitCalc.kgToLbs(weightKg) : weightKg;
  }

  String _goalTitle(S s) {
    switch (userWeightGoal) {
      case UserWeightGoalEntity.loseWeight:
        return s.goalLoseWeightDashboard;
      case UserWeightGoalEntity.maintainWeight:
        return s.goalMaintainWeightDashboard;
      case UserWeightGoalEntity.gainWeight:
        return s.goalGainWeightDashboard;
    }
  }

  void _openWeightScreen(BuildContext context) {
    Navigator.of(context).pushNamed(
      NavigationOptions.addWeightRoute,
      arguments: AddWeightScreenArguments(
        day: DateTime.now(),
        isReadOnly: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final colorScheme = theme.colorScheme;
    final brandOnSurface = colorScheme.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colorScheme.onPrimary;
    final brandSecondary = brandOnSurface.withValues(alpha: 0.74);
    final brandTertiary = brandOnSurface.withValues(alpha: 0.58);
    final kcalLeftLabel = totalKcalLeft.clamp(0, totalKcalDaily).toDouble();
    final consumedProgress = _progress(totalKcalSupplied, totalKcalDaily);
    final weightUnit = usesImperialUnits ? s.lbsLabel : s.kgLabel;
    final targetWeightLabel = _displayWeight(targetWeight);
    final currentWeightLabel =
        userWeight == null ? null : _displayWeight(userWeight!.weight);
    final remainingWeightLabel = currentWeightLabel == null
        ? null
        : (targetWeightLabel - currentWeightLabel).abs().toStringAsFixed(1);
    final remainingWeightText = remainingWeightLabel == null
        ? null
        : '${remainingWeightLabel.replaceAll(' ', '\u00A0')}\u00A0$weightUnit\u00A0${s.remainingWeightLabel}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtlasBrandPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.coachObjectiveLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brandTertiary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _goalTitle(s),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: brandOnSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            remainingWeightText == null
                                ? '${s.targetShortLabel} ${targetWeightLabel.toStringAsFixed(1)} $weightUnit'
                                : '${s.targetShortLabel} ${targetWeightLabel.toStringAsFixed(1)} $weightUnit\n$remainingWeightText',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brandSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    _WeightSummaryCard(
                      userWeight: userWeight,
                      weeklyWeightDelta: weeklyWeightDelta,
                      usesImperialUnits: usesImperialUnits,
                      userWeightGoal: userWeightGoal,
                      onTap: () => _openWeightScreen(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: brandOnSurface.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 18),
                Text(
                  '${kcalLeftLabel.toInt()} ${s.kcalLeftLabel}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: brandOnSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalKcalSupplied.toInt()} / ${totalKcalDaily.toInt()} ${s.kcalLabel} ${s.consumedLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brandSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: consumedProgress,
                    backgroundColor: brandOnSurface.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(brandOnSurface),
                  ),
                ),
                const SizedBox(height: 20),
                _WeightButton(
                  onTap: () => _openWeightScreen(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MacroSummaryCard(
                  label: s.carbsLabel,
                  intake: totalCarbsIntake,
                  goal: totalCarbsGoal,
                  visual: MacroVisuals.carbs,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroSummaryCard(
                  label: s.fatLabel,
                  intake: totalFatsIntake,
                  goal: totalFatsGoal,
                  visual: MacroVisuals.fats,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroSummaryCard(
                  label: s.proteinLabel,
                  intake: totalProteinsIntake,
                  goal: totalProteinsGoal,
                  visual: MacroVisuals.proteins,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightSummaryCard extends StatelessWidget {
  final UserWeightEntity? userWeight;
  final double? weeklyWeightDelta;
  final bool usesImperialUnits;
  final UserWeightGoalEntity userWeightGoal;
  final VoidCallback onTap;

  const _WeightSummaryCard({
    required this.userWeight,
    required this.weeklyWeightDelta,
    required this.usesImperialUnits,
    required this.userWeightGoal,
    required this.onTap,
  });

  Color _trendColor(BuildContext context, double delta) {
    const maintainTolerance = 0.2;

    switch (userWeightGoal) {
      case UserWeightGoalEntity.loseWeight:
        if (delta < 0) return lunchColor;
        if (delta > 0) return Theme.of(context).colorScheme.error;
        return Colors.orange;
      case UserWeightGoalEntity.maintainWeight:
        if (delta.abs() <= maintainTolerance) return lunchColor;
        return Theme.of(context).colorScheme.error;
      case UserWeightGoalEntity.gainWeight:
        if (delta > 0) return lunchColor;
        if (delta < 0) return Theme.of(context).colorScheme.error;
        return Colors.orange;
    }
  }

  String _trendLabel(double? delta, String unit) {
    if (delta == null) return '—';
    final sign = delta > 0
        ? '+ '
        : delta < 0
            ? '- '
            : '';
    return '$sign${delta.abs().toStringAsFixed(1)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = S.of(context);
    final weight = userWeight?.weight == null
        ? null
        : usesImperialUnits
            ? UnitCalc.kgToLbs(userWeight!.weight)
            : userWeight!.weight;
    final unit = usesImperialUnits ? s.lbsLabel : s.kgLabel;
    final delta = weeklyWeightDelta == null
        ? null
        : usesImperialUnits
            ? UnitCalc.kgToLbs(weeklyWeightDelta!)
            : weeklyWeightDelta;
    final deltaColor = weeklyWeightDelta == null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.48)
        : _trendColor(context, weeklyWeightDelta!);

    return Semantics(
      button: true,
      label: s.selectMyWeightLabel,
      child: SizedBox(
        width: 126,
        child: Material(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        weight == null ? '—' : weight.toStringAsFixed(1),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        unit,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.currentWeightLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: deltaColor.withValues(
                        alpha: colorScheme.brightness == Brightness.dark
                            ? 0.20
                            : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _trendLabel(delta, unit),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WeightButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brandOnSurface = colorScheme.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colorScheme.onPrimary;
    final brandSecondary = brandOnSurface.withValues(alpha: 0.76);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: brandOnSurface.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: brandOnSurface.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(Icons.insert_chart_outlined, color: brandSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                S.of(context).selectMyWeightLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: brandOnSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: brandSecondary),
          ],
        ),
      ),
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  final String label;
  final double intake;
  final double goal;
  final MacroVisual visual;

  const _MacroSummaryCard({
    required this.label,
    required this.intake,
    required this.goal,
    required this.visual,
  });

  double get progress {
    if (intake <= 0 || goal <= 0) return 0;
    if (intake >= goal) return 1;
    return intake / goal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final macroSurface = Color.alphaBlend(
      colorScheme.onSurface.withValues(
        alpha: colorScheme.brightness == Brightness.dark ? 0.08 : 0.00,
      ),
      colorScheme.surfaceContainerLowest,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: macroSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.22 : 0.05,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MacroIcon(visual: visual, size: 24),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${intake.toInt()} / ${goal.toInt()} g',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: visual.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(visual.color),
            ),
          ),
        ],
      ),
    );
  }
}
