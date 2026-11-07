import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class UserWeightDataSource {
  final HiveDBProvider _hive;

  UserWeightDataSource(this._hive);

  String _normaliseDateToKey(DateTime date) {
    /* Normalizes the given date to midnight for use as a unique daily key*/
    return DateTime(date.year, date.month, date.day).toString();
  }

  Future<void> addUserWeight(UserWeightDbo userWeightDbo) async {
    /* Use the date at midnight as the key to ensure one entry per day */
    final key = _normaliseDateToKey(userWeightDbo.date);
    final version = SyncMetadata(_hive.syncMetadataBox).nextLocalVersion(
        'user_weight',
        userWeightDbo.date.toDayKey(),
        _hive.userWeightBox.get(key)?.updatedat);
    await SyncMetadata(_hive.syncMetadataBox)
        .markWeightPending(userWeightDbo.date.toDayKey(), version);
    await _hive.userWeightBox.put(
        key,
        UserWeightDbo(userWeightDbo.id, userWeightDbo.weight,
            userWeightDbo.date, version));
  }

  Future<void> deleteUserWeightByDate(DateTime dateTime,
      {DateTime? deletedAt}) async {
    final metadata = SyncMetadata(_hive.syncMetadataBox);
    await metadata.markDeleted('user_weight', dateTime.toDayKey(),
        previous:
            _hive.userWeightBox.get(_normaliseDateToKey(dateTime))?.updatedat,
        version: deletedAt);
    final version = metadata.deletedAt('user_weight', dateTime.toDayKey());
    if (deletedAt == null && version != null) {
      await metadata.markWeightPending(dateTime.toDayKey(), version);
    }
    await _hive.userWeightBox.delete(_normaliseDateToKey(dateTime));
  }

  Future<UserWeightDbo?> getUserWeightByDate(DateTime dateTime) async {
    return _hive.userWeightBox.get(_normaliseDateToKey(dateTime));
  }

  Future<UserWeightDbo?> getLastSavedUserWeight(DateTime date) async {
    for (int i = _hive.userWeightBox.length - 1; i >= 0; i--) {
      final dbo = _hive.userWeightBox.getAt(i);
      if (dbo != null && !dbo.date.isAfter(date)) {
        return dbo;
      }
    }
    return null;
  }

  Future<List<UserWeightDbo>> getAllUserWeights() async {
    return _hive.userWeightBox.values.toList();
  }

  Future<void> addAllUserWeights(List<UserWeightDbo> userWeightDbos) async {
    final mapped = <String, UserWeightDbo>{};
    final metadata = SyncMetadata(_hive.syncMetadataBox);
    for (final dbo in userWeightDbos) {
      final key = _normaliseDateToKey(dbo.date);
      final current = mapped[key] ?? _hive.userWeightBox.get(key);
      final deleted = metadata.deletedAt('user_weight', dbo.date.toDayKey());
      if ((current == null || dbo.updatedat.isAfter(current.updatedat)) &&
          (deleted == null || dbo.updatedat.isAfter(deleted))) {
        mapped[key] = dbo;
      }
    }
    await _hive.userWeightBox.putAll(mapped);
  }
}
