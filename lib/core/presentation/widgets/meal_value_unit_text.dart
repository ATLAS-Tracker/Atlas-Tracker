import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealValueUnitText extends StatelessWidget {
  final double value;
  final MealEntity meal;
  final String? displayUnit;
  final TextStyle? textStyle;
  final String? prefix;
  final double? portionCount;

  const MealValueUnitText({
    super.key,
    required this.value,
    required this.meal,
    this.displayUnit,
    this.textStyle,
    this.prefix = '',
    this.portionCount,
  });

  @override
  Widget build(BuildContext context) {
    final mealUnit = meal.mealUnit ?? 'g';
    var targetUnit = MealEntity.metricUnit(displayUnit ?? mealUnit);
    final count = portionCount ?? (targetUnit == 'serving' ? value : null);
    final servingInPhysicalUnits = portionCount == null &&
        targetUnit == 'serving' &&
        ['g', 'ml'].contains(meal.servingUnit) &&
        meal.servingQuantity != null;
    if (servingInPhysicalUnits) targetUnit = meal.servingUnit!;
    // Portion totals are already converted to their physical unit by the bloc.
    final convertedValue =
        servingInPhysicalUnits ? value * meal.servingQuantity! : value;
    final unitToDisplay = _localizeUnit(context, targetUnit);

    final quantity = '${formatQuantity(convertedValue)} $unitToDisplay';
    final num? numericCount = count == null
        ? null
        : count == count.roundToDouble()
            ? count.toInt()
            : count;
    final portions = count == null
        ? null
        : S
            .of(context)
            .selectedPortionCount(numericCount!)
            .replaceFirst(numericCount.toString(), formatQuantity(count));
    final label = portions == null
        ? quantity
        : ['g', 'ml'].contains(targetUnit)
            ? S.of(context).selectedPortionWeight(portions, quantity)
            : portions;

    return Text(
      '$prefix$label',
      style: textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  String _localizeUnit(BuildContext context, String unit) {
    switch (unit) {
      case 'g':
        return S.of(context).gramUnit;
      case 'ml':
        return S.of(context).milliliterUnit;
      case 'serving':
        return S.of(context).servingLabel;
      default:
        return unit;
    }
  }
}
