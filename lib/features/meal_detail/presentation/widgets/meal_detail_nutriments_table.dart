import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MealDetailNutrimentsTable extends StatelessWidget {
  final MealEntity product;
  final bool embedded;

  const MealDetailNutrimentsTable({
    super.key,
    required this.product,
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

    final headerText = headerFor(context, product);

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
              // Embedded: the parent tile shows the header as its subtitle.
              if (!embedded)
                _getNutrimentsTableRow("", headerText, textStyleBold),
              _getNutrimentsTableRow(
                S.of(context).energyLabel,
                "${formatNumber(_adjustValueForServing(product.nutriments.energyKcalPerQuantity?.toDouble() ?? 0))} ${S.of(context).kcalLabel}",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).carbsLabel,
                "${formatQuantity(_adjustValueForServing(product.nutriments.carbohydratesPerQuantity ?? 0))} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                '    ${S.of(context).sugarLabel}',
                "${formatQuantity(_adjustValueForServing(product.nutriments.sugarsPerQuantity ?? 0))} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).fatLabel,
                "${formatQuantity(_adjustValueForServing(product.nutriments.fatPerQuantity ?? 0))} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                '   ${S.of(context).saturatedFatLabel}',
                "${formatQuantity(_adjustValueForServing(product.nutriments.saturatedFatPerQuantity ?? 0))} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).fiberLabel,
                "${formatQuantity(_adjustValueForServing(product.nutriments.fiberPerQuantity ?? 0))} g",
                textStyleNormal,
              ),
              _getNutrimentsTableRow(
                S.of(context).proteinLabel,
                "${formatQuantity(_adjustValueForServing(product.nutriments.proteinsPerQuantity ?? 0))} g",
                textStyleNormal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// What the values are for ("Par portion", "Pour 100 g"…).
  static String headerFor(BuildContext context, MealEntity product) {
    if (product.isPortionBased) {
      return '${S.of(context).perServingLabel}${product.servingSize == null ? '' : ' · ${product.servingSize}'}';
    }
    if (product.mealOrRecipe == MealOrRecipeEntity.recipe) {
      return S.of(context).perServingLabel;
    }
    return '${S.of(context).per100gmlLabel} ${MealEntity.metricUnit(product.mealUnit)}';
  }

  double _adjustValueForServing(double value) {
    if (product.isPortionBased) return value / 100;
    return value;
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
}
