// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/refresh_journal.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_or_recipe_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/features/create_meal/presentation/bloc/create_meal_bloc.dart';

class MealDetailBottomSheet extends StatefulWidget {
  final MealEntity product;
  final DateTime day;
  final IntakeTypeEntity intakeTypeEntity;
  final TextEditingController quantityTextController;
  final MealDetailBloc mealDetailBloc;

  final String selectedUnit;
  final IntakeEntity? intakeToEdit;

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
    this.intakeToEdit,
  });

  @override
  State<MealDetailBottomSheet> createState() => _MealDetailBottomSheetState();
}

class _MealDetailBottomSheetState extends State<MealDetailBottomSheet> {
  bool _saving = false;
  MealEntity get product => widget.product;
  DateTime get day => widget.day;
  IntakeTypeEntity get intakeTypeEntity => widget.intakeTypeEntity;
  TextEditingController get quantityTextController =>
      widget.quantityTextController;
  MealDetailBloc get mealDetailBloc => widget.mealDetailBloc;
  String get selectedUnit => widget.selectedUnit;
  IntakeEntity? get intakeToEdit => widget.intakeToEdit;
  Function(String?, String?) get onQuantityOrUnitChanged =>
      widget.onQuantityOrUnitChanged;

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
                            controller: quantityTextController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (text) =>
                                parsePositiveQuantity(text) == null
                                    ? S.of(context).positiveQuantityError
                                    : null,
                            onChanged: (text) {
                              onQuantityOrUnitChanged(
                                text,
                                selectedUnit,
                              );
                            },
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
                      child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: quantityTextController,
                          builder: (context, value, _) => FilledButton.icon(
                                onPressed: !_saving &&
                                        !productMissingRequiredInfo &&
                                        parsePositiveQuantity(value.text) !=
                                            null
                                    ? () {
                                        onAddButtonPressed(context);
                                      }
                                    : null,
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ).copyWith(
                                    elevation:
                                        ButtonStyleButton.allOrNull(0.0)),
                                icon: const Icon(Icons.add_outlined),
                                label: Text(intakeToEdit == null
                                    ? S.of(context).addLabel
                                    : S.of(context).saveQuantityLabel),
                              )),
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

  Future<void> onAddButtonPressed(BuildContext context) async {
    final quantity = parsePositiveQuantity(quantityTextController.text);
    if (_saving || quantity == null) return;
    setState(() => _saving = true);
    try {
      late final CreateMealBloc createMealBloc = locator<CreateMealBloc>();

      if (intakeToEdit != null) {
        final updated = await locator<UpdateIntakeUsecase>()
            .updateIntake(intakeToEdit!.id, {
          'amount': quantity,
          'unit': selectedUnit,
          'meal': product,
        });
        if (updated == null) throw StateError('Intake no longer exists');
        refreshJournalViews();
      } else if (createMealBloc.state.isOnCreateMealScreen) {
        await createMealBloc.addIntake(
          mealDetailBloc.state.selectedUnit,
          mealDetailBloc.state.totalQuantityConverted,
          intakeTypeEntity,
          product,
          day,
        );
      } else {
        final amountToPersist = quantity.toString();

        // Await the write so the refresh below reads the updated day.
        await mealDetailBloc.addIntake(
          context,
          mealDetailBloc.state.selectedUnit,
          amountToPersist,
          intakeTypeEntity,
          product,
          day,
        );
        refreshJournalViews();
      }

      if (!context.mounted) return;

      // Show snackbar and return to dashboard
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text(intakeToEdit == null
              ? S.of(context).infoAddedIntakeLabel
              : S.of(context).itemUpdatedSnackbar)));
      Navigator.of(context).pop();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).intakeSaveError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DropdownMenuItem<String> _getServingDropdownItem(BuildContext context) {
    final portionLabel = S.of(context).servingLabel;
    final quantity = product.servingQuantity;
    final unit = product.servingUnit;
    final hasPhysicalQuantity = quantity != null &&
        quantity.isFinite &&
        quantity > 0 &&
        ['g', 'ml'].contains(unit);
    final description = hasPhysicalQuantity
        ? '${formatQuantity(quantity)} ${_localizedUnit(context, unit)}'
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
      default:
        return unit ?? S.of(context).gramUnit;
    }
  }
}
