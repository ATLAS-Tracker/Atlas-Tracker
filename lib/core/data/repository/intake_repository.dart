import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

class IntakeRepository {
  final IntakeDataSource _intakeDataSource;

  IntakeRepository(this._intakeDataSource);

  Future<void> addIntake(IntakeEntity intakeEntity) async {
    final intakeDBO = IntakeDBO.fromIntakeEntity(intakeEntity);

    await _intakeDataSource.addIntake(intakeDBO);
  }

  Future<void> addAllIntakeDBOs(List<IntakeDBO> intakeDBOs) async {
    await _intakeDataSource.addAllIntakes(intakeDBOs);
  }

  Future<void> addIntakes(List<IntakeEntity> intakes) =>
      _intakeDataSource.addAllIntakes(
          intakes.map(IntakeDBO.fromIntakeEntity).toList(),
          localWrite: true);

  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    await _intakeDataSource.deleteIntakeFromId(intakeEntity.id);
  }

  Future<void> deleteIntakeById(String id, {DateTime? deletedAt}) =>
      _intakeDataSource.deleteIntakeFromId(id, deletedAt: deletedAt);

  Future<IntakeEntity?> updateIntake(
      String intakeId, Map<String, dynamic> fields) async {
    final dboFields = Map<String, dynamic>.of(fields);
    if (dboFields['type'] is IntakeTypeEntity) {
      dboFields['type'] = IntakeTypeDBO.fromIntakeTypeEntity(dboFields['type']);
    }
    if (dboFields['meal'] is MealEntity) {
      dboFields['meal'] = MealDBO.fromMealEntity(dboFields['meal']);
    }
    var result = await _intakeDataSource.updateIntake(intakeId, dboFields);
    return result == null ? null : IntakeEntity.fromIntakeDBO(result);
  }

  Future<List<IntakeDBO>> getAllIntakesDBO() async {
    return await _intakeDataSource.getAllIntakes();
  }

  Future<List<IntakeEntity>> getIntakeByDateAndType(
      IntakeTypeEntity intakeType, DateTime date) async {
    final intakeDBOList = await _intakeDataSource.getAllIntakesByDate(
        IntakeTypeDBO.fromIntakeTypeEntity(intakeType), date);

    return intakeDBOList
        .map((intakeDBO) => IntakeEntity.fromIntakeDBO(intakeDBO))
        .toList();
  }

  Future<List<IntakeEntity>> getRecentIntake() async {
    final intakeList = await _intakeDataSource.getRecentlyAddedIntake();

    return intakeList
        .map((intakeDBO) => IntakeEntity.fromIntakeDBO(intakeDBO))
        .toList();
  }

  Future<IntakeEntity?> getIntakeById(String intakeId) async {
    final result = await _intakeDataSource.getIntakeById(intakeId);
    return result == null ? null : IntakeEntity.fromIntakeDBO(result);
  }

  Future<List<IntakeEntity>> getIntakeRecipe() async {
    final intakeList = await _intakeDataSource.getIntakeRecipe();
    return intakeList
        .map((intakeDBO) => IntakeEntity.fromIntakeDBO(intakeDBO))
        .toList();
  }
}
