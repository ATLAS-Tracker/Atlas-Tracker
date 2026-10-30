import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Calorie progress split by the energy contributed by each macronutrient.
class MacroEnergyBar extends StatelessWidget {
  final double calories;
  final double goal;
  final double carbs;
  final double fats;
  final double proteins;
  final Color backgroundColor;

  const MacroEnergyBar({
    super.key,
    required this.calories,
    required this.goal,
    required this.carbs,
    required this.fats,
    required this.proteins,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final energy = [
      carbs.clamp(0, double.infinity) * 4,
      fats.clamp(0, double.infinity) * 9,
      proteins.clamp(0, double.infinity) * 4,
    ];
    final total = energy.reduce((a, b) => a + b);
    final shares =
        energy.map((value) => total > 0 ? value / total : 0.0).toList();
    final progress = goal > 0 ? (calories / goal).clamp(0.0, 1.0) : 0.0;
    final colors = [carbColor, fatColor, proteinColor];
    final labels = [s.carbsLabel, s.fatLabel, s.proteinLabel];

    final theme = Theme.of(context);
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      richMessage: TextSpan(
        children: [
          WidgetSpan(
            child: SizedBox(
              key: const ValueKey('macro-energy-legend'),
              width: 168,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i < 2 ? 6 : 0),
                      child: Row(
                        children: [
                          Container(
                            key: ValueKey('legend-dot-$i'),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: colors[i], shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(labels[i],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      height: 1.25,
                                      fontWeight: FontWeight.w500))),
                          const SizedBox(width: 10),
                          Text('${(shares[i] * 100).toStringAsFixed(0)} %',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 12,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
      child: Semantics(
        label:
            '${s.energyLabel}: ${calories.toInt()} / ${goal.toInt()} ${s.kcalLabel}',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: LayoutBuilder(builder: (context, constraints) {
                return ColoredBox(
                  color: backgroundColor,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: constraints.maxWidth * progress,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < shares.length; i++)
                            if (shares[i] > 0)
                              SizedBox(
                                key: ValueKey('energy-segment-$i'),
                                width:
                                    constraints.maxWidth * progress * shares[i],
                                child: ColoredBox(color: colors[i]),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
