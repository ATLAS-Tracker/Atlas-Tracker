import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/features/sync/startup_remote_sync_service.dart';

void main() {
  group('StartupRemoteSyncService diff helpers', () {
    test('pulls remote tracked days missing locally or newer than local', () {
      final day = DateTime.utc(2026, 6, 8);
      final oldDay = DateTime.utc(2026, 6, 7);
      final local = [
        trackedDay(day, updatedAt: DateTime.utc(2026, 6, 8, 8)),
      ];
      final remote = [
        trackedDay(day, updatedAt: DateTime.utc(2026, 6, 8, 9)),
        trackedDay(oldDay, updatedAt: DateTime.utc(2026, 6, 7, 9)),
      ];

      final toSave = StartupRemoteSyncService.remoteTrackedDaysToSave(
        local: local,
        remote: remote,
      );

      expect(toSave.map((d) => d.day), containsAll([day, oldDay]));
    });

    test('pushes local tracked days missing remotely or newer than remote', () {
      final day = DateTime.utc(2026, 6, 8);
      final localOnly = DateTime.utc(2026, 6, 9);
      final local = [
        trackedDay(day, updatedAt: DateTime.utc(2026, 6, 8, 10)),
        trackedDay(localOnly, updatedAt: DateTime.utc(2026, 6, 9, 8)),
      ];
      final remote = [
        trackedDay(day, updatedAt: DateTime.utc(2026, 6, 8, 9)),
      ];

      final toUpload = StartupRemoteSyncService.localTrackedDaysToUpload(
        local: local,
        remote: remote,
      );

      expect(toUpload.map((d) => d.day), containsAll([day, localOnly]));
    });

    test('pulls and pushes weights using calendar-day keys and updatedat', () {
      final day = DateTime.utc(2026, 6, 8, 12);
      final localOnly = DateTime.utc(2026, 6, 9, 18);
      final remoteOnly = DateTime.utc(2026, 6, 10, 7);
      final local = [
        weight('local-newer', 80, day, DateTime.utc(2026, 6, 8, 10)),
        weight('local-only', 81, localOnly, DateTime.utc(2026, 6, 9, 8)),
      ];
      final remote = [
        weight('remote-older', 79, day, DateTime.utc(2026, 6, 8, 9)),
        weight('remote-only', 82, remoteOnly, DateTime.utc(2026, 6, 10, 8)),
      ];

      final toUpload = StartupRemoteSyncService.localWeightsToUpload(
        local: local,
        remote: remote,
      );
      final toSave = StartupRemoteSyncService.remoteWeightsToSave(
        local: local,
        remote: remote,
      );

      expect(toUpload.map((w) => w.id), containsAll(['local-newer', 'local-only']));
      expect(toSave.map((w) => w.id), contains('remote-only'));
      expect(toSave.map((w) => w.id), isNot(contains('remote-older')));
    });
  });
}

TrackedDayDBO trackedDay(DateTime day, {required DateTime updatedAt}) {
  return TrackedDayDBO(
    day: day,
    calorieGoal: 2000,
    caloriesTracked: 1000,
    carbsGoal: 200,
    carbsTracked: 100,
    fatGoal: 70,
    fatTracked: 30,
    proteinGoal: 120,
    proteinTracked: 60,
    caloriesBurned: 0,
    updatedAt: updatedAt,
  );
}

UserWeightDbo weight(String id, double value, DateTime date, DateTime updatedAt) {
  return UserWeightDbo(id, value, date, updatedAt);
}
