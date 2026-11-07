import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

part 'meal_detail_event.dart';

part 'meal_detail_state.dart';

class MealDetailBloc extends Bloc<MealDetailEvent, MealDetailState> {
  final log = Logger('MealDetailBloc');
  final AddIntakeUsecase _addIntakeUseCase;

  MealDetailBloc(
    this._addIntakeUseCase,
  ) : super(
          MealDetailInitial(
            totalQuantityConverted: '100',
            selectedUnit: UnitDropdownItem.g.toString(),
          ),
        ) {
    on<UpdateKcalEvent>((event, emit) async {
      try {
        final selectedTotalQuantity =
            event.totalQuantity ?? state.totalQuantityConverted;
        final selectedUnit = event.selectedUnit ?? state.selectedUnit;

        if (selectedUnit.isEmpty || selectedTotalQuantity.isEmpty) {
          return;
        }

        final energyPerUnit = (event.meal.nutriments.energyPerUnit ?? 0);
        final carbsPerUnit = (event.meal.nutriments.carbohydratesPerUnit ?? 0);
        final fatPerUnit = (event.meal.nutriments.fatPerUnit ?? 0);
        final proteinPerUnit = (event.meal.nutriments.proteinsPerUnit ?? 0);

        final quantity = parsePositiveQuantity(selectedTotalQuantity);
        if (quantity == null) return;

        // Convert quantity based on selected unit
        double convertedQuantity = quantity;
        if (selectedUnit == UnitDropdownItem.serving.toString()) {
          // For serving size, multiply by the product's serving quantity
          if (event.meal.servingQuantity != null) {
            convertedQuantity = quantity * event.meal.servingQuantity!;
          }
        }

        emit(
          state.copyWith(
            totalQuantityConverted: convertedQuantity.toString(),
            totalKcal: convertedQuantity * energyPerUnit,
            totalCarbs: convertedQuantity * carbsPerUnit,
            totalFat: convertedQuantity * fatPerUnit,
            totalProtein: convertedQuantity * proteinPerUnit,
            selectedUnit: selectedUnit,
          ),
        );
      } catch (e) {
        log.severe('Error calculating kcal: $e');
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    });
  }

  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) async {
    final quantity = parsePositiveQuantity(amountText);
    if (quantity == null) throw ArgumentError.value(amountText, 'amount');

    final intakeEntity = IntakeEntity(
      id: IdGenerator.getUniqueID(),
      unit: MealEntity.metricUnit(unit),
      amount: quantity,
      type: type,
      meal: meal,
      dateTime: day,
      updatedAt: DateTime.now().toUtc(),
    );
    await _addIntakeUseCase.addIntake(intakeEntity);
  }
}

enum UnitDropdownItem {
  g,
  ml,
  serving;

  UnitDropdownItem fromString(String value) {
    switch (MealEntity.metricUnit(value)) {
      case 'g':
        return UnitDropdownItem.g;
      case 'ml':
        return UnitDropdownItem.ml;
      case 'serving':
        return UnitDropdownItem.serving;
      default:
        return UnitDropdownItem.g;
    }
  }

  @override
  String toString() {
    switch (this) {
      case UnitDropdownItem.g:
        return 'g';
      case UnitDropdownItem.ml:
        return 'ml';
      case UnitDropdownItem.serving:
        return 'serving';
    }
  }
}
