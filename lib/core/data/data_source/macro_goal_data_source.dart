import 'package:opennutritracker/core/data/data_source/macro_goal_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class MacroGoalDataSource {
  final HiveDBProvider _hive;
  static const String _key = 'macro_goal';

  MacroGoalDataSource(this._hive);

  Future<void> saveMacroGoal(MacroGoalDbo macroGoalDbo) async {
    await _hive.ensureReady();
    await _hive.macroGoalBox.put(_key, macroGoalDbo);
  }

  Future<MacroGoalDbo?> getMacroGoal() async {
    await _hive.ensureReady();
    return _hive.macroGoalBox.get(_key);
  }

  Future<void> deleteMacroGoal() async {
    await _hive.ensureReady();
    await _hive.macroGoalBox.delete(_key);
  }

  Future<bool> hasMacroGoal() async {
    await _hive.ensureReady();
    return _hive.macroGoalBox.containsKey(_key);
  }
}
