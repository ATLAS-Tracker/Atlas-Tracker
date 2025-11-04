import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class UserActivityDataSource {
  final log = Logger('UserActivityDataSource');
  final HiveDBProvider _hive;

  UserActivityDataSource(this._hive);

  Future<void> _ensureReady() => _hive.ensureReady();

  Future<void> addUserActivity(UserActivityDBO userActivityDBO) async {
    await _ensureReady();
    log.fine('Adding new user activity to db');
    _hive.userActivityBox.add(userActivityDBO);
  }

  Future<void> addAllUserActivities(
      List<UserActivityDBO> userActivityDBOList) async {
    await _ensureReady();
    log.fine('Adding new user activities to db');
    _hive.userActivityBox.addAll(userActivityDBOList);
  }

  Future<void> deleteIntakeFromId(String activityId) async {
    await _ensureReady();
    log.fine('Deleting activity item from db');
    _hive.userActivityBox.values
        .where((dbo) => dbo.id == activityId)
        .toList()
        .forEach((element) {
      element.delete();
    });
  }

  Future<List<UserActivityDBO>> getAllUserActivities() async {
    await _ensureReady();
    return _hive.userActivityBox.values.toList();
  }

  Future<List<UserActivityDBO>> getAllUserActivitiesByDate(
      DateTime dateTime) async {
    await _ensureReady();
    return _hive.userActivityBox.values
        .where((activity) => DateUtils.isSameDay(dateTime, activity.date))
        .toList();
  }

  Future<List<UserActivityDBO>> getRecentlyAddedUserActivity(
      {int number = 20}) async {
    await _ensureReady();
    final userActivities =
        _hive.userActivityBox.values.toList().reversed.toList();

    // Sort list by date (descending or ascending, adjust as needed)
    userActivities.sort(
        (a, b) => b.date.compareTo(a.date)); // Or a.date.compareTo(b.date)

    // Filter to get unique activities based on their code
    final filterActivityCodes = <String>{};
    final uniqueUserActivities = userActivities
        .where((activity) =>
            filterActivityCodes.add(activity.physicalActivityDBO.code))
        .toList();

    // Return the desired number or full list if not enough items
    try {
      return uniqueUserActivities.getRange(0, number).toList();
    } on RangeError catch (_) {
      return uniqueUserActivities.toList();
    }
  }
}
