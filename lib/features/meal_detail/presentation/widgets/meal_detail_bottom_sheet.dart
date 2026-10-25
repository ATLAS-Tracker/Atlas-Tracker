// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';

class MealDetailBottomSheet extends StatelessWidget {
  final MealEntity product;
  final DateTime day;
  final IntakeTypeEntity intakeTypeEntity;
  final TextEditingController quantityTextController;
  final MealDetailBloc mealDetailBloc;

  final String selectedUnit;

  final Function(String?, String?) onQuantityOrUnitChanged;

  const MealDetailBottomSheet({
    super.key,
    required this.product,
    required this.day,
    required this.intakeTypeEntity,
    required this.quantityTextController,
    required this.onQuantityOrUnitChanged,
    required this.mealDetailBloc,
    required this.selectedUnit,
  });

  @override
  Widget build(BuildContext context) {
    final productMissingRequiredInfo = _hasRequiredProductInfoMissing();
    return BottomSheet(
      elevation: 0,
      backgroundColor: Colors.transparent,
      onClosing: () {},
      enableDrag: false,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.06),
              width: 1,
            ),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            enabled: !productMissingRequiredInfo,
                            controller: quantityTextController
                              ..addListener(() {
                                onQuantityOrUnitChanged(
                                  quantityTextController.text,
                                  selectedUnit,
                                );
                              }),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+([.,]\d{0,2})?$'),
                              ),
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              labelText: S.of(context).quantityLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: (product.mealOrRecipe ==
                                    MealOrRecipeEntity.recipe)
                                ? UnitDropdownItem.serving.toString()
                                : (product.isLiquid &&
                                        selectedUnit ==
                                            UnitDropdownItem.g.toString())
                                    ? UnitDropdownItem.ml.toString()
                                    : selectedUnit,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLow,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              labelText: S.of(context).unitLabel,
                            ),
                            items: (product.isPortionBased ||
                                    product.mealOrRecipe ==
                                        MealOrRecipeEntity.recipe)
                                ? [_getServingDropdownItem(context)]
                                : <DropdownMenuItem<String>>[
                                    if (product.hasServingValues)
                                      _getServingDropdownItem(context),
                                    if (product.isSolid ||
                                        (!product.isLiquid && !product.isSolid))
                                      ..._getSolidUnitDropdownItems(context),
                                    if (product.isLiquid ||
                                        (!product.isLiquid && !product.isSolid))
                                      ..._getLiquidUnitDropdownItems(context)
                                  ],
                            onChanged: (value) {
                              onQuantityOrUnitChanged(
                                quantityTextController.text,
                                value,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, // Make button full width
                      child: FilledButton.icon(
                        onPressed: !productMissingRequiredInfo
                            ? () {
                                onAddButtonPressed(context);
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
                        icon: const Icon(Icons.add_outlined),
                        label: Text(S.of(context).addLabel),
                      ),
                    ),
                    productMissingRequiredInfo
                        ? Text(
                            S.of(context).missingProductInfo,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasRequiredProductInfoMissing() {
    final productNutriments = product.nutriments;
    if (productNutriments.energyKcalPerQuantity == null ||
        productNutriments.carbohydratesPerQuantity == null ||
        productNutriments.fatPerQuantity == null ||
        productNutriments.proteinsPerQuantity == null) {
      return true;
    } else {
      return false;
    }
  }

  void onAddButtonPressed(BuildContext context) {
    late final CreateMealBloc createMealBloc = locator<CreateMealBloc>();

    if (createMealBloc.state.isOnCreateMealScreen) {
      createMealBloc.addIntake(
        mealDetailBloc.state.selectedUnit,
        mealDetailBloc.state.totalQuantityConverted,
        intakeTypeEntity,
        product,
        day,
      );
    } else {
      // Persist serving as count when selected, otherwise use converted quantity
      final isServing = mealDetailBloc.state.selectedUnit ==
          UnitDropdownItem.serving.toString();
      final amountToPersist = isServing
          ? quantityTextController.text // e.g., "1" portion
          : mealDetailBloc
              .state.totalQuantityConverted; // converted g/ml or imperial

      mealDetailBloc.addIntake(
        context,
        mealDetailBloc.state.selectedUnit,
        amountToPersist,
        intakeTypeEntity,
        product,
        day,
      );

      // ici

      // Refresh Home Page
      locator<HomeBloc>().add(const LoadItemsEvent());

      // Refresh Diary Page
      locator<DiaryBloc>().add(const LoadDiaryYearEvent());
      locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
    }

    // Show snackbar and return to dashboard
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(S.of(context).infoAddedIntakeLabel)));
    Navigator.of(context).pop();
  }

  DropdownMenuItem<String> _getServingDropdownItem(BuildContext context) {
    final portionLabel = S.of(context).servingLabel;
    final quantity = product.servingQuantity;
    final unit = product.servingUnit;
    final hasPhysicalQuantity = quantity != null &&
        quantity.isFinite &&
        quantity > 0 &&
        ['g', 'ml', 'oz', 'fl oz', 'fl.oz'].contains(unit);
    final description = hasPhysicalQuantity
        ? '${NumberFormat('0.##', Localizations.localeOf(context).toString()).format(quantity)} ${_localizedUnit(context, unit)}'
        : product.servingSize?.trim();
    final label = description == null ||
            description.isEmpty ||
            description.toLowerCase() == portionLabel.toLowerCase() ||
            description.toLowerCase() == 'serving'
        ? portionLabel
        : '$portionLabel ($description)';

    return DropdownMenuItem(
      value: UnitDropdownItem.serving.toString(),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  List<DropdownMenuItem<String>> _getSolidUnitDropdownItems(
    BuildContext context,
  ) {
    return [
      DropdownMenuItem(
        value: UnitDropdownItem.g.toString(),
        child: Text(
          S.of(context).gramUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      DropdownMenuItem(
        value: UnitDropdownItem.oz.toString(),
        child: Text(
          S.of(context).ozUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _getLiquidUnitDropdownItems(
    BuildContext context,
  ) {
    return [
      DropdownMenuItem(
        value: UnitDropdownItem.ml.toString(),
        child: Text(
          S.of(context).milliliterUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      DropdownMenuItem(
        value: UnitDropdownItem.flOz.toString(),
        child: Text(
          S.of(context).flOzUnit,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ];
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
