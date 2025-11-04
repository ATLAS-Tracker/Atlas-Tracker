import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class UserWeightDataSource {
  final HiveDBProvider _hive;

  UserWeightDataSource(this._hive);

  Future<void> _ensureReady() => _hive.ensureReady();

  String _normaliseDateToKey(DateTime date) {
    /* Normalizes the given date to midnight for use as a unique daily key*/
    return DateTime(date.year, date.month, date.day).toString();
  }

  Future<void> addUserWeight(UserWeightDbo userWeightDbo) async {
    /* Use the date at midnight as the key to ensure one entry per day */
    await _ensureReady();
    await _hive.userWeightBox.put(
        _normaliseDateToKey(userWeightDbo.date), userWeightDbo);
  }

  Future<void> deleteUserWeightByDate(DateTime dateTime) async {
    await _ensureReady();
    await _hive.userWeightBox.delete(_normaliseDateToKey(dateTime));
  }

  Future<UserWeightDbo?> getUserWeightByDate(DateTime dateTime) async {
    await _ensureReady();
    return _hive.userWeightBox.get(_normaliseDateToKey(dateTime));
  }

  Future<UserWeightDbo?> getLastSavedUserWeight(DateTime date) async {
    await _ensureReady();
    for (int i = _hive.userWeightBox.length - 1; i >= 0; i--) {
      final dbo = _hive.userWeightBox.getAt(i);
      if (dbo != null && !dbo.date.isAfter(date)) {
        return dbo;
      }
    }
    return null;
  }

  Future<List<UserWeightDbo>> getAllUserWeights() async {
    await _ensureReady();
    return _hive.userWeightBox.values.toList();
  }

  Future<void> addAllUserWeights(List<UserWeightDbo> userWeightDbos) async {
    await _ensureReady();
    final Map<String, UserWeightDbo> mapped = {
      for (var dbo in userWeightDbos) _normaliseDateToKey(dbo.date): dbo
    };
    await _hive.userWeightBox.putAll(mapped);
  }
}
