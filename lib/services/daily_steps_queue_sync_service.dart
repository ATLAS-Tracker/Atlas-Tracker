import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/env.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyStepsQueueSyncService with WidgetsBindingObserver {
  DailyStepsQueueSyncService({
    HiveDBProvider? hive,
    Connectivity? connectivity,
    String? Function()? userIdProvider,
  })  : _hive = hive ?? locator<HiveDBProvider>(),
        _connectivity = connectivity ?? locator<Connectivity>(),
        _userIdProvider = userIdProvider;

  final HiveDBProvider _hive;
  final Connectivity _connectivity;
  final String? Function()? _userIdProvider;
  final Logger _log = Logger('DailyStepsQueueSyncService');

  bool _isInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> init() async {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        unawaited(syncPendingSteps());
      }
    });
    unawaited(syncPendingSteps());
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    WidgetsBinding.instance.removeObserver(this);
    await _authSubscription?.cancel();
    _authSubscription = null;
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncPendingSteps());
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> queueTodaySteps(int steps) async {
    await queueStepsForDate(DateTime.now(), steps);
  }

  Future<void> queueStepsForDate(DateTime date, int steps) async {
    final sanitizedSteps = steps < 0 ? 0 : steps;
    final day = DateUtils.dateOnly(date);
    final key = day.toIso8601String();
    try {
      final box = _resolveDailyStepsBox();
      if (box == null) {
        _log.fine(
          'Daily steps box unavailable while queuing steps for $key; skipping.',
        );
        return;
      }
      await box.put(key, sanitizedSteps);
    } catch (error, stack) {
      _log.severe('Failed to queue steps for $key', error, stack);
    }
  }

  Future<void> syncPendingSteps() async {
    try {
      final connectivityStatus = await _connectivity.checkConnectivity();
      if (connectivityStatus == ConnectivityResult.none) {
        _log.fine('No connectivity, skipping queued steps sync.');
        return;
      }

      final supabase = Supabase.instance.client;
      final userId =
          _userIdProvider?.call() ?? supabase.auth.currentUser?.id;
      final accessToken = supabase.auth.currentSession?.accessToken;

      if (userId == null || accessToken == null) {
        _log.fine('No authenticated session, skipping queued steps sync.');
        return;
      }

      final box = _resolveDailyStepsBox();
      if (box == null) {
        _log.fine('Daily steps box unavailable, skipping queued steps sync.');
        return;
      }
      final payload = <Map<String, dynamic>>[];
      final keysToDelete = <String>[];

      for (final rawKey in box.keys) {
        final key = rawKey;
        if (key is! String) {
          continue;
        }

        final int? steps = box.get(key);
        if (steps == null) {
          continue;
        }

        final formattedDate = _formatDateKey(key);
        if (formattedDate == null) {
          continue;
        }

        payload.add({
          'user_id': userId,
          'date': formattedDate,
          'steps': steps,
        });
        keysToDelete.add(key);
      }

      if (payload.isEmpty) {
        _log.fine('No queued steps to sync.');
        return;
      }

      final url = Env.supabaseProjectUrl;
      final anonKey = Env.supabaseProjectAnonKey;
      final entriesForIsolate =
          payload.map((e) => Map<String, dynamic>.from(e)).toList();

      final success = await Isolate.run(
        () => _pushStepsToSupabase(
          url: url,
          anonKey: anonKey,
          accessToken: accessToken,
          entries: entriesForIsolate,
        ),
      );

      if (success) {
        await box.deleteAll(keysToDelete);
        _log.fine('Queued steps synced (${payload.length} entries).');
      } else {
        _log.warning('Queued steps sync failed.');
      }
    } catch (error, stack) {
      _log.severe('Failed to sync queued steps', error, stack);
    }
  }

  String? _formatDateKey(String key) {
    try {
      final parsed = DateTime.parse(key);
      return DateUtils.dateOnly(parsed).toIso8601String().split('T').first;
    } catch (_) {
      _log.warning('Invalid steps queue key encountered: $key');
      return null;
    }
  }

  Box<int>? _resolveDailyStepsBox() {
    try {
      final current = _hive.dailyStepsBox;
      if (current.isOpen) {
        return current;
      }
    } catch (error, stack) {
      _log.finer(
        'Failed to read current daily steps box reference',
        error,
        stack,
      );
    }

    final userId = _hive.activeUserId;
    final boxName = userId == null
        ? HiveDBProvider.dailyStepsBoxName
        : '${userId}_${HiveDBProvider.dailyStepsBoxName}';

    if (!Hive.isBoxOpen(boxName)) {
      return null;
    }

    try {
      return Hive.box<int>(boxName);
    } catch (error, stack) {
      _log.warning(
        'Unable to resolve reopened daily steps box $boxName',
        error,
        stack,
      );
      return null;
    }
  }
}

Future<bool> _pushStepsToSupabase({
  required String url,
  required String anonKey,
  required String accessToken,
  required List<Map<String, dynamic>> entries,
}) async {
  final client = http.Client();
  try {
    final uri = Uri.parse('$url/rest/v1/daily_steps?on_conflict=user_id,date');
    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
        'Authorization': 'Bearer $accessToken',
        'apikey': anonKey,
      },
      body: jsonEncode(entries),
    );

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isSuccess) {
      developer.log(
        'DailyStepsQueueSyncService isolate sync failed '
        '(status ${response.statusCode}): ${response.body}',
      );
    }
    return isSuccess;
  } catch (error, stack) {
    developer.log(
      'DailyStepsQueueSyncService isolate error: $error',
      error: error,
      stackTrace: stack,
    );
    return false;
  } finally {
    client.close();
  }
}
