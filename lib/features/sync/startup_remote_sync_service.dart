import 'dart:async';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Performs a lightweight bidirectional synchronization at app startup.
///
/// Existing export/import ZIP behavior is kept intact. This service is focused
/// on the row-based Supabase tables that already have live local watchers:
/// tracked days and user weights.
class StartupRemoteSyncService {
  StartupRemoteSyncService({
    required TrackedDayRepository trackedDayRepository,
    required UserWeightRepository userWeightRepository,
    required ConfigRepository configRepository,
    required SupabaseClient client,
    SupabaseTrackedDayService? trackedDayService,
    SupabaseUserWeightService? userWeightService,
  })  : _trackedDayRepository = trackedDayRepository,
        _userWeightRepository = userWeightRepository,
        _configRepository = configRepository,
        _client = client,
        _trackedDayService = trackedDayService ?? SupabaseTrackedDayService(client: client),
        _userWeightService = userWeightService ?? SupabaseUserWeightService(client: client);

  final TrackedDayRepository _trackedDayRepository;
  final UserWeightRepository _userWeightRepository;
  final ConfigRepository _configRepository;
  final SupabaseClient _client;
  final SupabaseTrackedDayService _trackedDayService;
  final SupabaseUserWeightService _userWeightService;
  final Logger _log = Logger('StartupRemoteSyncService');

  bool _running = false;

  Future<void> syncAtStartup() async {
    if (_running) return;
    _running = true;
    try {
      if (_client.auth.currentSession == null) {
        _log.fine('No Supabase session; skipping startup sync.');
        return;
      }
      if (!await _configRepository.getSupabaseSyncEnabled()) {
        _log.fine('Supabase sync disabled; skipping startup sync.');
        return;
      }

      await Future.wait([
        _syncTrackedDays(),
        _syncUserWeights(),
      ]);
    } catch (error, stack) {
      _log.warning('Startup sync failed; app will continue with local data.', error, stack);
    } finally {
      _running = false;
    }
  }

  Future<void> _syncTrackedDays() async {
    final local = await _trackedDayRepository.getAllTrackedDaysDBO();
    final remote = await _fetchRemoteTrackedDays();

    final toSave = remoteTrackedDaysToSave(local: local, remote: remote);
    if (toSave.isNotEmpty) {
      await _trackedDayRepository.addAllTrackedDays(toSave);
    }

    final toUpload = localTrackedDaysToUpload(local: local, remote: remote);
    if (toUpload.isNotEmpty) {
      await _trackedDayService.upsertTrackedDays(
        toUpload.map(_trackedDayJsonForSupabase).toList(),
      );
    }

    _log.fine('Startup tracked_days sync: pulled=${toSave.length}, pushed=${toUpload.length}.');
  }

  Future<void> _syncUserWeights() async {
    final local = await _userWeightRepository.getAllUserWeightDBOs();
    final remote = await _fetchRemoteUserWeights();

    final toSave = remoteWeightsToSave(local: local, remote: remote);
    if (toSave.isNotEmpty) {
      await _userWeightRepository.addAllUserWeightDBOs(toSave);
    }

    final toUpload = localWeightsToUpload(local: local, remote: remote);
    if (toUpload.isNotEmpty) {
      await _userWeightService.upsertUserWeights(
        toUpload.map((w) => w.toJson()).toList(),
      );
    }

    _log.fine('Startup user_weight sync: pulled=${toSave.length}, pushed=${toUpload.length}.');
  }

  Future<List<TrackedDayDBO>> _fetchRemoteTrackedDays() async {
    final rows = await _client.from('tracked_days').select();
    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row as Map))
        .map(TrackedDayDBO.fromJson)
        .toList();
  }

  Future<List<UserWeightDbo>> _fetchRemoteUserWeights() async {
    final rows = await _client.from('user_weight').select();
    return rows
        .map<Map<String, dynamic>>((row) {
          final json = Map<String, dynamic>.from(row as Map);
          // Some Supabase schemas expose snake_case while the existing DBO uses
          // `updatedat`. Accept both without changing generated DBO code.
          json['updatedat'] ??= json['updated_at'];
          return json;
        })
        .map(UserWeightDbo.fromJson)
        .toList();
  }

  static List<TrackedDayDBO> remoteTrackedDaysToSave({
    required List<TrackedDayDBO> local,
    required List<TrackedDayDBO> remote,
  }) {
    final localByDay = {for (final day in local) _dayKey(day.day): day};
    return remote.where((remoteDay) {
      final localDay = localByDay[_dayKey(remoteDay.day)];
      return localDay == null || remoteDay.updatedAt.isAfter(localDay.updatedAt);
    }).toList();
  }

  static List<TrackedDayDBO> localTrackedDaysToUpload({
    required List<TrackedDayDBO> local,
    required List<TrackedDayDBO> remote,
  }) {
    final remoteByDay = {for (final day in remote) _dayKey(day.day): day};
    return local.where((localDay) {
      final remoteDay = remoteByDay[_dayKey(localDay.day)];
      return remoteDay == null || localDay.updatedAt.isAfter(remoteDay.updatedAt);
    }).toList();
  }

  static List<UserWeightDbo> remoteWeightsToSave({
    required List<UserWeightDbo> local,
    required List<UserWeightDbo> remote,
  }) {
    final localByDate = {for (final weight in local) _dayKey(weight.date): weight};
    return remote.where((remoteWeight) {
      final localWeight = localByDate[_dayKey(remoteWeight.date)];
      return localWeight == null || remoteWeight.updatedat.isAfter(localWeight.updatedat);
    }).toList();
  }

  static List<UserWeightDbo> localWeightsToUpload({
    required List<UserWeightDbo> local,
    required List<UserWeightDbo> remote,
  }) {
    final remoteByDate = {for (final weight in remote) _dayKey(weight.date): weight};
    return local.where((localWeight) {
      final remoteWeight = remoteByDate[_dayKey(localWeight.date)];
      return remoteWeight == null || localWeight.updatedat.isAfter(remoteWeight.updatedat);
    }).toList();
  }

  static String _dayKey(DateTime date) {
    final localDate = date.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day).toIso8601String();
  }

  static Map<String, dynamic> _trackedDayJsonForSupabase(TrackedDayDBO dbo) {
    final json = dbo.toJson();
    final local = dbo.day.toLocal();
    json['day'] = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return json;
  }
}
