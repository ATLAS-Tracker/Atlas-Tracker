import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';

class MealDetailMacroNutrients extends StatelessWidget {
  final String typeString;
  final double? value;
  final MacroVisual visual;

  const MealDetailMacroNutrients(
      {super.key,
      required this.typeString,
      required this.value,
      required this.visual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(9)),
          child: MacroIcon(visual: visual, size: 19),
        ),
        const SizedBox(height: 8),
        FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('${value?.roundToPrecision(1) ?? "?"} g',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800))),
        const SizedBox(height: 4),
        FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(typeString,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.76)))),
      ]),
    );
  }
}
