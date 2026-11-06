import 'package:opennutritracker/features/add_weight/presentation/widgets/weight_trend_color.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_energy_bar.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DashboardWidget extends StatelessWidget {
  final double totalKcalDaily;
  final double totalKcalSupplied;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;
  final UserWeightEntity? userWeight;
  final double? weeklyWeightDelta;
  final UserWeightGoalEntity userWeightGoal;

  const DashboardWidget({
    super.key,
    required this.totalKcalSupplied,
    required this.totalKcalDaily,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
    required this.userWeight,
    required this.weeklyWeightDelta,
    required this.userWeightGoal,
  });

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
    final brandOnSurface = atlasBrandOnSurface(colorScheme);
    final brandSecondary = brandOnSurface.withValues(alpha: 0.74);
    final brandTertiary = brandOnSurface.withValues(alpha: 0.58);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtlasBrandPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final goalDetails = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.goalLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: brandTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userWeightGoal.getName(context),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: brandOnSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  );
                  final weightCard = _WeightSummaryCard(
                    userWeight: userWeight,
                    weeklyWeightDelta: weeklyWeightDelta,
                    userWeightGoal: userWeightGoal,
                    onTap: () => _openWeightScreen(context),
                  );
                  if (constraints.maxWidth < 260 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        goalDetails,
                        const SizedBox(height: 12),
                        Align(
                            alignment: Alignment.centerRight, child: weightCard)
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: goalDetails),
                      const SizedBox(width: 18),
                      weightCard
                    ],
                  );
                }),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: brandOnSurface.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 18),
                Text(
                  calorieBalanceLabel(s, totalKcalDaily, totalKcalSupplied),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: brandOnSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatNumber(totalKcalSupplied)} / ${formatNumber(totalKcalDaily)} ${s.kcalLabel} ${s.consumedLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brandSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                MacroEnergyBar(
                  calories: totalKcalSupplied,
                  goal: totalKcalDaily,
                  carbs: totalCarbsIntake,
                  fats: totalFatsIntake,
                  proteins: totalProteinsIntake,
                  backgroundColor: brandOnSurface.withValues(alpha: 0.18),
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
  final UserWeightGoalEntity userWeightGoal;
  final VoidCallback onTap;

  const _WeightSummaryCard({
    required this.userWeight,
    required this.weeklyWeightDelta,
    required this.userWeightGoal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = S.of(context);
    final weight = userWeight?.weight;
    final unit = s.kgLabel;
    final delta = weeklyWeightDelta;
    final deltaColor = weeklyWeightDelta == null
        ? theme.colorScheme.onSurface.withValues(alpha: 0.48)
        : weightTrendColor(
            deltaKg: weeklyWeightDelta!,
            goal: userWeightGoal,
            colors: colorScheme);

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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weight == null
                              ? '—'
                              : formatNumber(weight, decimals: 1),
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
                      delta == null
                          ? '—'
                          : '${formatNumber(delta, decimals: 1, signed: true)} $unit',
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
    final brandOnSurface = atlasBrandOnSurface(colorScheme);
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${formatNumber(intake)} / ${formatNumber(goal)} g',
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
