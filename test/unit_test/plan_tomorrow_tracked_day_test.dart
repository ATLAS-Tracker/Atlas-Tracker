import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

void main() {
  test('food planned for tomorrow is visible to the diary reload', () async {
    final tempDir = await Directory.systemTemp.createTemp('hive_plan_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(trackedDayDBOTypeId)) {
      Hive.registerAdapter(TrackedDayDBOAdapter());
    }
    final hive = HiveDBProvider()
      ..trackedDayBox = await Hive.openBox<TrackedDayDBO>('plan_test');
    final repo = TrackedDayRepository(TrackedDayDataSource(hive));
    final usecase = AddTrackedDayUsecase(repo);

    // Same steps as MealDetailBloc._updateTrackedDay for a new day.
    final tomorrow =
        DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));
    expect(await usecase.hasTrackedDay(tomorrow), isFalse);
    await usecase.addNewTrackedDay(tomorrow, 1700, 180, 60, 110);
    await usecase.addDayCaloriesTracked(tomorrow, 400);
    await usecase.addDayMacrosTracked(tomorrow,
        carbsTracked: 50, fatTracked: 10, proteinTracked: 20);

    // Same query and key as DiaryBloc / DiaryPage.
    final now = DateTime.now();
    const year = Duration(days: 356);
    final days = await repo.getTrackedDayByRange(
        now.subtract(year), now.add(year));
    final map = {for (final d in days) d.day.toParsedDay(): d};
    final day = map[tomorrow.toParsedDay()];

    expect(day?.caloriesTracked, 400);
    expect(day?.carbsTracked, 50);

    await hive.trackedDayBox.close();
    await Hive.deleteFromDisk();
  });
}
