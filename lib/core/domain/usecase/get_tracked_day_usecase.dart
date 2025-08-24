import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

class GetTrackedDayUsecase {
  final TrackedDayRepository _trackedDayRepository;

  GetTrackedDayUsecase(this._trackedDayRepository);

  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async {
    return await _trackedDayRepository.getTrackedDay(day);
  }

  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
    DateTime start,
    DateTime end,
  ) {
    return _trackedDayRepository.getTrackedDayByRange(start, end);
  }

  Future<List<DateTime>> getTrackedDaysFrom(DateTime start) async {
    final List<TrackedDayDBO> trackedDays = await _trackedDayRepository
        .getAllTrackedDaysDBO();
    final startDay = DateTime(start.year, start.month, start.day);
    return trackedDays
        .map((dbo) => DateTime(dbo.day.year, dbo.day.month, dbo.day.day))
        .where((day) => !day.isBefore(startDay))
        .toList();
  }
}
