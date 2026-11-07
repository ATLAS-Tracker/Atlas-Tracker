import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';

class UserWeightRepository {
  final UserWeightDataSource _userWeightDataSource;

  UserWeightRepository(this._userWeightDataSource);

  Future<void> addUserWeight(UserWeightEntity userWeight) async {
    final userWeightDbo = UserWeightDbo.fromUserWeightEntity(userWeight);

    await _userWeightDataSource.addUserWeight(userWeightDbo);
  }

  Future<void> deleteUserWeightByDate(DateTime dateTime,
      {DateTime? deletedAt}) async {
    await _userWeightDataSource.deleteUserWeightByDate(dateTime,
        deletedAt: deletedAt);
  }

  Future<UserWeightEntity?> getUserWeightByDate(DateTime dateTime) async {
    final UserWeightDbo? weightDbo =
        await _userWeightDataSource.getUserWeightByDate(dateTime);

    if (weightDbo == null) {
      return null;
    }

    return UserWeightEntity.fromUserWeightDbo(weightDbo);
  }

  Future<UserWeightEntity?> getLastUserWeight(DateTime date) async {
    final lastUserWeight =
        await _userWeightDataSource.getLastSavedUserWeight(date);
    if (lastUserWeight == null) {
      return null;
    }
    return UserWeightEntity.fromUserWeightDbo(lastUserWeight);
  }

  Future<List<UserWeightDbo>> getAllUserWeightDBOs() async {
    return await _userWeightDataSource.getAllUserWeights();
  }

  Future<void> addAllUserWeightDBOs(List<UserWeightDbo> userWeights) async {
    await _userWeightDataSource.addAllUserWeights(userWeights);
  }
}
