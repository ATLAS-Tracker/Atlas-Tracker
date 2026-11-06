import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:opennutritracker/generated/l10n.dart';

double? parsePositiveQuantity(String? text) {
  final value = double.tryParse((text ?? '')
      .trim()
      .replaceAll(RegExp(r'[\s\u00a0\u202f]'), '')
      .replaceAll(',', '.'));
  return value != null && value.isFinite && value > 0 ? value : null;
}

NumberFormat numberFormatter({int decimals = 0}) =>
    NumberFormat.decimalPatternDigits(locale: 'fr_FR', decimalDigits: decimals);

String formatQuantity(num value) =>
    formatNumber(value, decimals: 2).replaceFirst(RegExp(r',?0+$'), '');

String formatNumber(num value, {int decimals = 0, bool signed = false}) {
  final scale = math.pow(10, decimals);
  final rounded = (value * scale).round() / scale;
  final formatter = numberFormatter(decimals: decimals);
  final text = formatter
      .format(rounded == 0 ? 0 : rounded)
      .replaceAll('\u00a0', '\u202f');
  return signed && rounded > 0 ? '+$text' : text;
}

int remainingCalories(double goal, double consumed) =>
    goal.round() - consumed.round();

String calorieBalanceLabel(S s, double goal, double consumed) {
  final remaining = remainingCalories(goal, consumed);
  return remaining < 0
      ? s.caloriesAboveGoal(formatNumber(-remaining))
      : '${formatNumber(remaining)} ${s.kcalLeftLabel}';
}

bool isWithinNutritionGoal(double consumed, double goal) {
  final displayedConsumed = consumed.round();
  final displayedGoal = goal.round();
  return displayedGoal > 0 &&
      displayedConsumed > 0 &&
      displayedConsumed >= displayedGoal * 0.9 &&
      displayedConsumed <= displayedGoal * 1.1;
}

double macroCalories(
        {required num carbs, required num fat, required num protein}) =>
    (carbs * 4 + fat * 9 + protein * 4).toDouble();

String capitalizeFirst(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

bool exceedsNutritionGoal(double consumed, double goal) =>
    consumed.round() > goal.round() * 1.1;
