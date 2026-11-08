import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_period_stats.dart';

void main() {
  final day = DateTime(2026, 10, 22);
  UserWeightEntity w(int daysAgo, double kg) => UserWeightEntity(
      id: '$daysAgo', weight: kg, date: day.subtract(Duration(days: daysAgo)));

  test('losing weight: today, average with today, change vs first weigh-in',
      () {
    final s = WeightPeriodStats.of(day, [w(0, 79), w(3, 80), w(6, 81)], 7);
    expect(s.today, 79);
    expect(s.average, closeTo(80, 1e-9));
    expect(s.deltaToAverage, closeTo(-1, 1e-9));
    expect(s.change, closeTo(-2, 1e-9));
  });

  test('gaining weight', () {
    final s = WeightPeriodStats.of(day, [w(1, 60), w(0, 61)], 7);
    expect(s.change, closeTo(1, 1e-9));
    expect(s.deltaToAverage, closeTo(0.5, 1e-9));
  });

  test('stable weight gives zero change', () {
    final s = WeightPeriodStats.of(day, [w(0, 70), w(2, 70), w(5, 70)], 7);
    expect(s.change, 0);
    expect(s.deltaToAverage, 0);
  });

  test('weigh-ins outside the period and in the future are ignored', () {
    final s = WeightPeriodStats.of(
        day,
        [
          w(7, 90),
          w(6, 80),
          w(0, 78),
          UserWeightEntity(
              id: 'future', weight: 50, date: day.add(const Duration(days: 1)))
        ],
        7);
    expect(s.weighIns.map((e) => e.weight), [80, 78]);
    expect(s.change, closeTo(-2, 1e-9));
    expect(WeightPeriodStats.of(day, [w(7, 90), w(0, 78)], 14).change,
        closeTo(-12, 1e-9));
  });

  test('no weigh-in today: dash for today, gap and change; average kept', () {
    final s = WeightPeriodStats.of(day, [w(1, 70), w(4, 72)], 7);
    expect(s.today, isNull);
    expect(s.average, closeTo(71, 1e-9));
    expect(s.deltaToAverage, isNull);
    expect(s.change, isNull);
  });

  test('0 or 1 weigh-in gives no change', () {
    final empty = WeightPeriodStats.of(day, [], 7);
    expect([empty.today, empty.average, empty.change], [null, null, null]);
    final one = WeightPeriodStats.of(day, [w(0, 70)], 7);
    expect(one.today, 70);
    expect(one.change, isNull);
  });

  test('two weigh-ins on the same day count once (latest wins)', () {
    final s = WeightPeriodStats.of(day, [w(0, 70), w(0, 71)], 7);
    expect(s.weighIns, hasLength(1));
    expect(s.today, 71);
    expect(s.change, isNull);
  });
}
