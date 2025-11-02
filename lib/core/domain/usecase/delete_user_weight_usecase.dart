import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';

class DeleteUserWeightUsecase {
  final UserWeightRepository _userWeightRepository;

  DeleteUserWeightUsecase(this._userWeightRepository);

  Future<void> deleteTodayUserWeight() async {
    await _userWeightRepository.deleteUserWeightByDate(DateTime.now());
  }

  Future<void> deleteUserWeightByDate(DateTime date) async {
    await _userWeightRepository.deleteUserWeightByDate(date);
  }
}
