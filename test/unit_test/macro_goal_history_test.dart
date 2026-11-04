import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';

void main() {
  final today = DateTime(2026, 11, 4);
  Map<String, dynamic> row(String date, int carbs) => {
        'user_id': 'student',
        'start_date': date,
        'carb_goal': carbs,
        'fat_goal': 60,
        'protein_goal': 120,
      };
  final previous = MacroGoalEntity(
      id: 'student',
      date: DateTime(2026, 11, 1),
      oldCarbsGoal: 100,
      oldFatsGoal: 40,
      oldProteinsGoal: 80,
      newCarbsGoal: 200,
      newFatsGoal: 60,
      newProteinsGoal: 120);

  test('current B stays active when future C is scheduled after A', () {
    final goal = MacroGoalEntity.fromHistory(
        'student',
        [
          row('2026-10-01', 100),
          row('2026-11-01', 200),
          row('2026-11-10', 300),
        ],
        today: today,
        previous: previous)!;
    expect(MacroGoalEntity.forDay(goal, today).carbs, 200);
    expect(MacroGoalEntity.forDay(goal, DateTime(2026, 11, 10)).carbs, 300);
  });
  test('future-only history uses the active local B, never its old A', () {
    final goal = MacroGoalEntity.fromHistory(
        'student', [row('2026-11-10', 300)],
        today: today, previous: previous)!;
    expect(MacroGoalEntity.forDay(goal, today).carbs, 200);
  });
  test('foreign, malformed and implausible goals are excluded', () {
    expect(
        MacroGoalEntity.fromHistory(
            'student',
            [
              {...row('2026-11-01', 200), 'user_id': 'foreign'},
              row('invalid', 200),
              row('2026-11-01', 1001),
            ],
            today: today),
        isNull);
  });
}
