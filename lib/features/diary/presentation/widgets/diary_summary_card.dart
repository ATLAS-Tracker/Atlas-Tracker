import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DiarySummaryCard extends StatelessWidget {
  final TrackedDayEntity? trackedDay;
  final UserWeightEntity? selectedDayWeight;
  final HomeLoadedState? homeState;
  final VoidCallback? onEditWeight;

  const DiarySummaryCard({
    super.key,
    required this.trackedDay,
    required this.selectedDayWeight,
    required this.homeState,
    this.onEditWeight,
  });

  double _displayWeight(double weightKg, bool usesImperialUnits) {
    return usesImperialUnits ? UnitCalc.kgToLbs(weightKg) : weightKg;
  }

  Color _brandOnSurface(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.brightness == Brightness.dark
        ? lightColorScheme.onPrimary
        : colorScheme.onPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);
    final brandOnSurface = _brandOnSurface(context);
    final brandSecondary = brandOnSurface.withValues(alpha: 0.74);
    final brandMuted = brandOnSurface.withValues(alpha: 0.56);
    final usesImperialUnits = homeState?.usesImperialUnits ?? false;
    final weightUnit = usesImperialUnits ? s.lbsLabel : s.kgLabel;
    final displayedWeight = selectedDayWeight == null
        ? null
        : _displayWeight(selectedDayWeight!.weight, usesImperialUnits);
    final targetWeight = homeState == null
        ? null
        : _displayWeight(homeState!.targetWeight, usesImperialUnits);
    final remainingWeight = displayedWeight == null || targetWeight == null
        ? null
        : (targetWeight - displayedWeight).abs();
    final calorieGoal =
        trackedDay?.calorieGoal ?? homeState?.totalKcalDaily ?? 0;
    final caloriesTracked = trackedDay?.caloriesTracked ?? 0;

    return AtlasBrandPanel(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      borderRadius: BorderRadius.circular(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brandOnSurface.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: brandOnSurface,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.dailySummaryLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: brandOnSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${s.weightLabel} • ${s.kcalMacrosLabel}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: brandSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                s.weightLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: brandMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              if (onEditWeight != null) ...[
                const SizedBox(width: 6),
                _SummaryActionButton(
                  icon: Icons.edit_rounded,
                  tooltip: s.editWeightLabel,
                  brandOnSurface: brandOnSurface,
                  onPressed: onEditWeight!,
                  diameter: 28,
                  iconSize: 15,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  displayedWeight == null
                      ? s.emptyValueLabel
                      : displayedWeight.toStringAsFixed(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: brandOnSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              if (displayedWeight != null) ...[
                const SizedBox(width: 8),
                Text(
                  weightUnit,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: brandSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WeightContextPill(
                  label: s.targetShortLabel,
                  value: targetWeight == null
                      ? s.notAvailableLabel
                      : '${targetWeight.toStringAsFixed(1)} $weightUnit',
                  brandOnSurface: brandOnSurface,
                  brandMuted: brandMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeightContextPill(
                  label: s.remainingToLoseLabel,
                  value: remainingWeight == null
                      ? s.emptyValueLabel
                      : '${remainingWeight.toStringAsFixed(1)} $weightUnit',
                  brandOnSurface: brandOnSurface,
                  brandMuted: brandMuted,
                  valueColor: lunchColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _EnergyConsumedPanel(
            caloriesTracked: caloriesTracked,
            calorieGoal: calorieGoal,
            brandOnSurface: brandOnSurface,
            brandSecondary: brandSecondary,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DiaryMacroPill(
                  label: s.carbsLabel,
                  intake: trackedDay?.carbsTracked ?? 0,
                  goal: trackedDay?.carbsGoal ?? homeState?.totalCarbsGoal ?? 0,
                  visual: MacroVisuals.carbs,
                  brandOnSurface: brandOnSurface,
                  brandSecondary: brandSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DiaryMacroPill(
                  label: s.fatLabel,
                  intake: trackedDay?.fatTracked ?? 0,
                  goal: trackedDay?.fatGoal ?? homeState?.totalFatsGoal ?? 0,
                  visual: MacroVisuals.fats,
                  brandOnSurface: brandOnSurface,
                  brandSecondary: brandSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DiaryMacroPill(
                  label: s.proteinLabel,
                  intake: trackedDay?.proteinTracked ?? 0,
                  goal: trackedDay?.proteinGoal ??
                      homeState?.totalProteinsGoal ??
                      0,
                  visual: MacroVisuals.proteins,
                  brandOnSurface: brandOnSurface,
                  brandSecondary: brandSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color brandOnSurface;
  final VoidCallback onPressed;
  final double diameter;
  final double iconSize;

  const _SummaryActionButton({
    required this.icon,
    required this.tooltip,
    required this.brandOnSurface,
    required this.onPressed,
    this.diameter = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: brandOnSurface.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Icon(
              icon,
              color: brandOnSurface,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightContextPill extends StatelessWidget {
  final String label;
  final String value;
  final Color brandOnSurface;
  final Color brandMuted;
  final Color? valueColor;

  const _WeightContextPill({
    required this.label,
    required this.value,
    required this.brandOnSurface,
    required this.brandMuted,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: brandOnSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandOnSurface.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: brandMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: valueColor ?? brandOnSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyConsumedPanel extends StatelessWidget {
  final double caloriesTracked;
  final double calorieGoal;
  final Color brandOnSurface;
  final Color brandSecondary;

  const _EnergyConsumedPanel({
    required this.caloriesTracked,
    required this.calorieGoal,
    required this.brandOnSurface,
    required this.brandSecondary,
  });

  double _progress(double supplied, double goal) {
    if (supplied <= 0 || goal <= 0) return 0;
    if (supplied >= goal) return 1;
    return supplied / goal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: brandOnSurface.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandOnSurface.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.energyConsumedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: brandSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${caloriesTracked.toInt()} ${s.kcalLabel}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: brandOnSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _progress(caloriesTracked, calorieGoal),
              backgroundColor: brandOnSurface.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation<Color>(brandOnSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryMacroPill extends StatelessWidget {
  final String label;
  final double intake;
  final double goal;
  final MacroVisual visual;
  final Color brandOnSurface;
  final Color brandSecondary;

  const _DiaryMacroPill({
    required this.label,
    required this.intake,
    required this.goal,
    required this.visual,
    required this.brandOnSurface,
    required this.brandSecondary,
  });

  double _progress(double supplied, double goal) {
    if (supplied <= 0 || goal <= 0) return 0;
    if (supplied >= goal) return 1;
    return supplied / goal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: brandOnSurface.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brandOnSurface.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: brandOnSurface,
              shape: BoxShape.circle,
            ),
            child: MacroIcon(visual: visual, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: brandSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${intake.toInt()} / ${goal.toInt()} ${S.of(context).gramUnit}',
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: brandOnSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: _progress(intake, goal),
              backgroundColor: brandOnSurface.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(visual.color),
            ),
          ),
        ],
      ),
    );
  }
}
