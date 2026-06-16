import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';

class GetWeightUsecase {
  final UserWeightRepository _userWeightRepository =
      locator<UserWeightRepository>();
  final GetUserUsecase _getUserUsecase = locator<GetUserUsecase>();

  Future<UserWeightEntity?> getUserWeightByDate(DateTime dateTime) async {
    return await _userWeightRepository.getUserWeightByDate(dateTime);
  }

  Future<UserWeightEntity?> getTodayUserWeight() async {
    return await _userWeightRepository.getUserWeightByDate(DateTime.now());
  }

  /// Fetches the last recorded weight for the user.
  ///
  /// If no weight entries are found in the repository, this function
  /// falls back to returning the user's default weight as specified
  /// in their profile (userData.weightKG).
  ///
  /// Returns a [Future<double>] representing the user's last known weight
  /// or their default weight if no entries exist.
  Future<double> getLastUserWeight(DateTime date) async {
    final UserWeightEntity? lastUserWeight =
        await _userWeightRepository.getLastUserWeight(date);

    if (lastUserWeight != null) {
      return lastUserWeight.weight;
    }

    // If no last weight is found, fetch the user's default weight from their profile.
    final userData = await _getUserUsecase.getUserData();
    return userData.weightKG;
  }

  Future<List<UserWeightEntity>> getAllUserWeights() async {
    final weights = await _userWeightRepository.getAllUserWeightDBOs();
    final entities = weights.map(UserWeightEntity.fromUserWeightDbo).toList();
    entities.sort((a, b) => a.date.compareTo(b.date));
    return entities;
  }

  Future<List<UserWeightEntity>> getWeightsFromPastDays(
      DateTime currentDay, int days,
      {bool includeToday = false}) async {
    final List<UserWeightEntity> weights = [];

    final int lastOffset = includeToday ? days - 1 : days;

    for (int i = includeToday ? 0 : 1; i <= lastOffset; i++) {
      DateTime date = currentDay.subtract(Duration(days: i));
      UserWeightEntity? weight = await getUserWeightByDate(date);

      if (weight != null) {
        weights.add(weight);
      }
    }
    return weights;
  }

  /// Computes the average weight from entries recorded in the last `numberOfDays` past calendar days.
  ///
  /// For example, if `numberOfDays` is 7, it will look for weight entries from yesterday
  /// up to 7 days ago and calculate their average.
  /// If no weights are found in that period, it falls back to the user's default weight.
  Future<double> getAverageWeight(DateTime date, int numberOfDays) async {
    final List<UserWeightEntity> userWeights =
        await getWeightsFromPastDays(date, numberOfDays);

    if (userWeights.isEmpty) {
      final userData = await _getUserUsecase.getUserData();
      return userData.weightKG;
    }

    final List<double> weights =
        userWeights.map((entity) => entity.weight).toList();
    double sum = weights.reduce((value, element) => value + element);
    return sum / weights.length;
  }
}
