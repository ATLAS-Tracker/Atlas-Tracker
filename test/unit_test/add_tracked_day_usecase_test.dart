import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';

class MockTrackedDayRepository extends Mock implements TrackedDayRepository {}

void main() {
  test('addDayCaloriesTracked waits for the write (journal bar refresh)',
      () async {
    final repo = MockTrackedDayRepository();
    final day = DateTime(2026, 11, 2);
    var written = false;
    when(() => repo.addDayTrackedCalories(day, 300)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      written = true;
    });

    await AddTrackedDayUsecase(repo).addDayCaloriesTracked(day, 300);

    expect(written, isTrue);
  });
}
