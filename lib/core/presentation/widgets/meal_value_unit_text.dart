import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealValueUnitText extends StatelessWidget {
  final double value;
  final MealEntity meal;
  final String? displayUnit;
  final bool usesImperialUnits;
  final TextStyle? textStyle;
  final String? prefix;

  const MealValueUnitText({
    super.key,
    required this.value,
    required this.meal,
    this.displayUnit,
    required this.usesImperialUnits,
    this.textStyle,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final mealUnit = meal.mealUnit ?? 'g/ml';
    final targetUnit = displayUnit ?? _convertUnit(mealUnit);
    final convertedValue = _convertValue(value, mealUnit, targetUnit);
    final unitToDisplay = _localizeUnit(context, targetUnit);

    return Text(
      '$prefix${_formatValue(convertedValue)} $unitToDisplay',
      style: textStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  double _convertValue(double value, String fromUnit, String toUnit) {
    // If units are the same, no conversion needed
    if (fromUnit == toUnit) return value;

    // Convert to base unit first (g or ml)
    double baseValue = _convertToBaseUnit(value, fromUnit);

    // Then convert from base unit to target unit
    return _convertFromBaseUnit(baseValue, toUnit);
  }

  double _convertToBaseUnit(double value, String fromUnit) {
    switch (fromUnit) {
      case 'oz':
        return UnitCalc.ozToG(value);
      case 'fl oz' || 'fl.oz':
        return UnitCalc.flOzToMl(value);
      default:
        return value;
    }
  }

  double _convertFromBaseUnit(double value, String toUnit) {
    switch (toUnit) {
      case 'oz':
        return UnitCalc.gToOz(value);
      case 'fl oz' || 'fl.oz':
        return UnitCalc.mlToFlOz(value);
      default:
        return value;
    }
  }

  String _convertUnit(String unit) {
    switch (unit) {
      case 'g':
        return usesImperialUnits ? 'oz' : 'g';
      case 'ml':
        return usesImperialUnits ? 'fl oz' : 'ml';
      default:
        return unit;
    }
  }

  String _localizeUnit(BuildContext context, String unit) {
    switch (unit) {
      case 'g':
        return S.of(context).gramUnit;
      case 'ml':
        return S.of(context).milliliterUnit;
      case 'oz':
        return S.of(context).ozUnit;
      case 'fl oz':
      case 'fl.oz':
        return S.of(context).flOzUnit;
      case 'g/ml':
      case 'gml':
        return S.of(context).gramMilliliterUnit;
      case 'serving':
        return S.of(context).servingLabel;
      default:
        return unit;
    }
  }

  String _formatValue(double value) {
    final formattedValue = value.toStringAsFixed(2);
    return formattedValue.endsWith('.00')
        ? formattedValue.substring(0, formattedValue.length - 3)
        : formattedValue.endsWith('0')
        ? formattedValue.substring(0, formattedValue.length - 1)
        : formattedValue;
  }
}
