import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';

class AddWeightUsecase {
  final UserWeightRepository _userWeightRepository;

  AddWeightUsecase(this._userWeightRepository);

  Future<void> addUserWeight(UserWeightEntity userWeightEntity) async {
    if (!userWeightEntity.weight.isFinite ||
        userWeightEntity.weight <= 0 ||
        userWeightEntity.weight > 400) {
      throw ArgumentError.value(userWeightEntity.weight, 'weight');
    }
    return await _userWeightRepository.addUserWeight(userWeightEntity);
  }
}
