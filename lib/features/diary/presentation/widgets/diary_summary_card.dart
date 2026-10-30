import 'package:opennutritracker/core/presentation/widgets/macro_energy_bar.dart';
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

    return AtlasBrandPanel(
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
          MacroEnergyBar(
            calories: caloriesTracked,
            goal: calorieGoal,
            carbs: trackedDay?.carbsTracked ?? 0,
            fats: trackedDay?.fatTracked ?? 0,
            proteins: trackedDay?.proteinTracked ?? 0,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
          ),
          ExpansionTile(
            key: ValueKey(trackedDay?.day),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            textColor: Colors.white,
            collapsedTextColor: Colors.white,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(s.kcalMacrosLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            children: [
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.weightLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.74),
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
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
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
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: weeklyWeightDelta == null ||
                                                  homeState == null
                                              ? Colors.white
                                                  .withValues(alpha: 0.74)
                                              : weightTrendColor(
                                                  deltaKg: weeklyWeightDelta!,
                                                  goal:
                                                      homeState!.userWeightGoal,
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
                        Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
        ],
      ),
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
            ],
          )),
        ],
      ),
    );
  }
}
