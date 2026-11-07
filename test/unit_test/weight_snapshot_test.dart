import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_snapshot.dart';

void main() {
  UserWeightEntity entry(int day, double kg) =>
      UserWeightEntity(id: '$day', date: DateTime(2026, 10, day), weight: kg);

  test(
      'current weight is the latest real weigh-in, even without a weigh-in today',
      () {
    final snapshot = WeightSnapshot.at(DateTime(2026, 10, 30),
        [entry(21, 80), entry(23, 78), entry(24, 79), entry(31, 99)]);
    expect(snapshot.current!.weight, 79);
    expect(snapshot.delta, -0.0);
    expect(snapshot.previousAverage, 79);
  });

  test('comparison excludes the current day and weights older than seven days',
      () {
    final snapshot = WeightSnapshot.at(DateTime(2026, 10, 25),
        [entry(16, 100), entry(17, 80), entry(23, 78), entry(24, 77)]);
    expect(snapshot.previousAverage, 79);
    expect(snapshot.delta, -2);
  });

  test('onlyOn hides a weigh-in from another day', () {
    final history = [entry(23, 78), entry(24, 79)];
    final yesterdayOnly = WeightSnapshot.at(DateTime(2026, 10, 25), history)
        .onlyOn(DateTime(2026, 10, 25));
    expect(yesterdayOnly.current, isNull);
    expect(yesterdayOnly.delta, isNull);
    final today = WeightSnapshot.at(DateTime(2026, 10, 24), history)
        .onlyOn(DateTime(2026, 10, 24));
    expect(today.current!.weight, 79);
    expect(today.delta, 1);
  });

  test('no history means no invented weight or trend', () {
    expect(WeightSnapshot.at(DateTime(2026, 10, 25), []).current, isNull);
    final only = WeightSnapshot.at(DateTime(2026, 10, 25), [entry(24, 78)]);
    expect(only.current!.weight, 78);
    expect(only.delta, isNull);
  });
}
