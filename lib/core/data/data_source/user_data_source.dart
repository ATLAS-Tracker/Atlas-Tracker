import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';

class UserDataSource {
  final String _userKey;
  final log = Logger('UserDataSource');
  final HiveDBProvider _hive;

  UserDataSource(this._hive, this._userKey);

  Future<void> _ensureReady() => _hive.ensureReady();

  Future<void> saveUserData(UserDBO userDBO) async {
    await _ensureReady();
    log.fine('Updating user in db');
    await _hive.userBox.put(_userKey, userDBO);
  }

  Future<bool> hasUserData() async {
    await _ensureReady();
    return _hive.userBox.containsKey(_userKey);
  }

  Future<UserDBO> getUserData() async {
    await _ensureReady();
    return _hive.userBox.get(_userKey)!;
  }
}
