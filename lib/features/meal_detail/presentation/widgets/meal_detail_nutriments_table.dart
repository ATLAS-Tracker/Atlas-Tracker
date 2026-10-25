import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailNutrimentsTable extends StatelessWidget {
  final MealEntity product;
  final bool usesImperialUnits;
  final double? servingQuantity;
  final String? servingUnit;
  final bool embedded;

  const MealDetailNutrimentsTable({
    super.key,
    required this.product,
    required this.usesImperialUnits,
    this.servingQuantity,
    this.servingUnit,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyleNormal =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textStyleBold = Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle();

    final unit = product.mealUnit ?? FDCConst.fdcDefaultUnit;

    final headerText = product.isPortionBased
        ? '${S.of(context).perServingLabel}${product.servingSize == null ? '' : ' · ${product.servingSize}'}'
        : (usesImperialUnits && servingQuantity != null) ||
                product.mealOrRecipe == MealOrRecipeEntity.recipe
            ? "${S.of(context).perServingLabel} (${servingQuantity!.roundToPrecision(1)} ${_localizedUnit(context, servingUnit)})"
            : "${S.of(context).per100gmlLabel} $unit";

    return Container(
      padding: EdgeInsets.all(embedded ? 0 : 16),
      decoration: embedded
          ? null
          : BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!embedded) ...[
            Text(
              S.of(context).nutritionInfoLabel,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16.0),
          ],
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1)
            },
            border: TableBorder(
                horizontalInside: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.06))),
            children: <TableRow>[
              _getNutrimentsTableRow("", headerText, textStyleBold),
              _getNutrimentsTableRow(
                S.of(context).energyLabel,
                "${_adjustValueForServing(product.nutriments.energyKcalPerQuantity?.toDouble() ?? 0).toInt()} ${S.of(context).kcalLabel}",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).fatLabel,
                "${_adjustValueForServing(product.nutriments.fatPerQuantity ?? 0).roundToPrecision(2)} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                '   ${S.of(context).saturatedFatLabel}',
                "${_adjustValueForServing(product.nutriments.saturatedFatPerQuantity ?? 0).roundToPrecision(2)} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).carbohydrateLabel,
                "${_adjustValueForServing(product.nutriments.carbohydratesPerQuantity ?? 0).roundToPrecision(2)} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                '    ${S.of(context).sugarLabel}',
                "${_adjustValueForServing(product.nutriments.sugarsPerQuantity ?? 0).roundToPrecision(2)} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).fiberLabel,
                "${_adjustValueForServing(product.nutriments.fiberPerQuantity ?? 0).roundToPrecision(2)} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).proteinLabel,
                "${_adjustValueForServing(product.nutriments.proteinsPerQuantity ?? 0).roundToPrecision(2)} g",
                textStyleNormal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _adjustValueForServing(double value) {
    if (product.isPortionBased) return value / 100;
    if (!usesImperialUnits || servingQuantity == null) {
      return value;
    }
    // Calculate per serving value based on 100g reference
    return (value * servingQuantity!) / 100;
  }

  TableRow _getNutrimentsTableRow(
    String label,
    String quantityString,
    TextStyle textStyle,
  ) {
    return TableRow(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
          child: Text(label, style: textStyle),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerRight,
          child: Text(quantityString, style: textStyle),
        ),
      ],
    );
  }

  String _localizedUnit(BuildContext context, String? unit) {
    switch (unit) {
      case 'serving':
        return S.of(context).servingLabel;
      case 'g':
        return S.of(context).gramUnit;
      case 'ml':
        return S.of(context).milliliterUnit;
      case 'oz':
        return S.of(context).ozUnit;
      case 'fl oz':
      case 'fl.oz':
        return S.of(context).flOzUnit;
      default:
        return unit ?? S.of(context).gramUnit;
    }
  }
}
