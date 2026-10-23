import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/features/add_weight/presentation/widgets/weight_trend_color.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DiarySummaryCard extends StatelessWidget {
  final TrackedDayEntity? trackedDay;
  final UserWeightEntity? selectedDayWeight;
  final HomeLoadedState? homeState;
  final VoidCallback? onEditWeight;
  final double? weeklyWeightDelta;

  const DiarySummaryCard({
    super.key,
    required this.trackedDay,
    required this.selectedDayWeight,
    required this.homeState,
    this.onEditWeight,
    this.weeklyWeightDelta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = S.of(context);
    final usesImperialUnits = homeState?.usesImperialUnits ?? false;
    final weightUnit = usesImperialUnits ? s.lbsLabel : s.kgLabel;
    final weight = selectedDayWeight?.weight;
    final displayedWeight = weight == null
        ? null
        : usesImperialUnits
            ? UnitCalc.kgToLbs(weight)
            : weight;
    final calorieGoal =
        trackedDay?.calorieGoal ?? homeState?.totalKcalDaily ?? 0;
    final caloriesTracked = trackedDay?.caloriesTracked ?? 0;
    final remaining = (calorieGoal - caloriesTracked).clamp(0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtlasBrandPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.dailySummaryLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 16),
              Text('${remaining.toInt()} ${s.kcalLeftLabel}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              Text(
                '${caloriesTracked.toInt()} / ${calorieGoal.toInt()} ${s.kcalLabel} ${s.consumedLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: calorieGoal <= 0
                      ? 0
                      : (caloriesTracked / calorieGoal).clamp(0, 1).toDouble(),
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              _DashboardMacro(
                label: s.carbsLabel,
                intake: trackedDay?.carbsTracked ?? 0,
                goal: trackedDay?.carbsGoal ?? homeState?.totalCarbsGoal ?? 0,
                visual: MacroVisuals.carbs,
              ),
              _DashboardMacro(
                label: s.fatLabel,
                intake: trackedDay?.fatTracked ?? 0,
                goal: trackedDay?.fatGoal ?? homeState?.totalFatsGoal ?? 0,
                visual: MacroVisuals.fats,
              ),
              _DashboardMacro(
                label: s.proteinLabel,
                intake: trackedDay?.proteinTracked ?? 0,
                goal: trackedDay?.proteinGoal ??
                    homeState?.totalProteinsGoal ??
                    0,
                visual: MacroVisuals.proteins,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.weightLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  displayedWeight == null
                                      ? s.emptyValueLabel
                                      : '${NumberFormat('0.0', Localizations.localeOf(context).toLanguageTag()).format(displayedWeight)} $weightUnit',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ))),
                        const SizedBox(width: 12),
                        Flexible(
                            child: Tooltip(
                                message: s.weightAverageDeltaLabel,
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      weeklyWeightDelta == null ||
                                              displayedWeight == null
                                          ? s.emptyValueLabel
                                          : '${weeklyWeightDelta! > 0 ? '+' : ''}${NumberFormat('0.0', Localizations.localeOf(context).toLanguageTag()).format(usesImperialUnits ? UnitCalc.kgToLbs(weeklyWeightDelta!) : weeklyWeightDelta!)} $weightUnit',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: weeklyWeightDelta == null ||
                                                homeState == null
                                            ? colors.onSurfaceVariant
                                            : weightTrendColor(
                                                deltaKg: weeklyWeightDelta!,
                                                goal: homeState!.userWeightGoal,
                                                colors: colors),
                                      ),
                                    )))),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEditWeight != null)
                IconButton(
                  tooltip: s.editWeightLabel,
                  onPressed: onEditWeight,
                  icon:
                      Icon(Icons.edit_rounded, color: colors.primary, size: 20),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMacro extends StatelessWidget {
  final String label;
  final double intake;
  final double goal;
  final MacroVisual visual;

  const _DashboardMacro(
      {required this.label,
      required this.intake,
      required this.goal,
      required this.visual});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: MacroIcon(visual: visual, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(label, style: textStyle),
                  Text(
                      '${intake.toInt()} / ${goal.toInt()} ${S.of(context).gramUnit}',
                      style: textStyle)
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: goal <= 0 ? 0 : (intake / goal).clamp(0, 1).toDouble(),
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation(visual.color),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}
