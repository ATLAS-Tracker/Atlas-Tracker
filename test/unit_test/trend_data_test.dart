import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/features/profile/student_macros_page.dart';

void main() {
  test('each trend day is compared to the goal in force that day', () {
    final today = DateTime.now();
    String key(int daysAgo) => DateFormat('yyyy-MM-dd')
        .format(DateTime(today.year, today.month, today.day - daysAgo));
    final data = trendDataFrom({
      // Objectif 2000 jusqu'à il y a 2 jours, puis 1500.
      key(3): {'calorieGoal': 2000, 'caloriesTracked': 2100},
      key(1): {'calorieGoal': 1500, 'caloriesTracked': 1400},
      key(0): {'caloriesTracked': 1600},
    }, 7);

    expect(data.days[3].calorieGoal, 2000);
    expect(data.days[4].calorieGoal, 2000); // hérité de la veille
    expect(data.days[5].calorieGoal, 1500);
    expect(data.days[6].calorieGoal, 1500);
    // Moyenne des objectifs des jours saisis : (2000 + 1500 + 1500) / 3.
    expect(data.calorieGoal, closeTo(5000 / 3, 0.01));
  });
}
