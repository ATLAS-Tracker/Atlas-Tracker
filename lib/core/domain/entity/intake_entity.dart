import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/data/dbo/data_util.dart';

class IntakeEntity extends Equatable {
  final String id;
  final String unit;
  final double amount;
  final IntakeTypeEntity type;
  final DateTime dateTime;
  final DateTime updatedAt;

  final MealEntity meal;

  IntakeEntity({
    required this.id,
    required this.unit,
    required this.amount,
    required this.type,
    required this.meal,
    required this.dateTime,
    DateTime? updatedAt,
  }) : updatedAt = DateUtilsHelper.roundToSeconds(updatedAt ?? DateTime.now().toUtc());

  factory IntakeEntity.fromIntakeDBO(IntakeDBO intakeDBO) {
    return IntakeEntity(
      id: intakeDBO.id,
      unit: intakeDBO.unit,
      amount: intakeDBO.amount,
      type: IntakeTypeEntity.fromIntakeTypeDBO(intakeDBO.type),
      meal: MealEntity.fromMealDBO(intakeDBO.meal),
      dateTime: intakeDBO.dateTime,
      updatedAt: intakeDBO.updatedAt,
    );
  }

  double get totalKcal => amount * (meal.nutriments.energyPerUnit ?? 0);

  double get totalCarbsGram =>
      amount * (meal.nutriments.carbohydratesPerUnit ?? 0);

  double get totalFatsGram => amount * (meal.nutriments.fatPerUnit ?? 0);

  double get totalProteinsGram =>
      amount * (meal.nutriments.proteinsPerUnit ?? 0);

  @override
  List<Object?> get props => [id, unit, amount, type, dateTime, updatedAt];
}

extension IntakeEntityCopy on IntakeEntity {
  IntakeEntity copyWith({
    String? id,
    String? unit,
    double? amount,
    IntakeTypeEntity? type,
    MealEntity? meal,
    DateTime? dateTime,
    DateTime? updatedAt,
  }) {
    return IntakeEntity(
      id: id ?? this.id,
      unit: unit ?? this.unit,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      meal: meal ?? this.meal,
      dateTime: dateTime ?? this.dateTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
