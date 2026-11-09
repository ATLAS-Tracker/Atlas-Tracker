import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/macro_goal_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/macro_goal_entity.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shares only today's nutrition totals; the Android widget never needs a token.
class NutritionWidgetService with WidgetsBindingObserver {
  static const channel =
      MethodChannel('com.atlastracker.android/nutrition_widget');
  final HiveDBProvider hive;
  final SupabaseClient client;
  final MacroGoalRepository goals;
  final ConfigRepository config;
  final _log = Logger('NutritionWidget');
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Timer? _debounce;
  Timer? _midnight;
  bool _disposed = false;
  int _revision = 0;

  NutritionWidgetService(this.hive, this.client, this.goals, this.config);

  void start() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    WidgetsBinding.instance.addObserver(this);
    for (final Box box in [
      hive.intakeBox,
      hive.macroGoalBox,
      hive.commonConfigBox
    ]) {
      _subscriptions.add(box.watch().listen((_) => _schedule()));
    }
    _subscriptions.add(client.auth.onAuthStateChange.listen((_) {
      // Clear immediately on logout, even before the user scope is replaced.
      unawaited(refresh());
    }));
    unawaited(refresh());
  }

  void _schedule() {
    _revision++;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), refresh);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final revision = ++_revision;
    _midnight?.cancel();
    final now = DateTime.now();
    _midnight = Timer(
        DateTime(now.year, now.month, now.day + 1).difference(now), refresh);
    final owner = hive.activeUserId;
    bool ownsData() => owner != null && client.auth.currentUser?.id == owner;
    try {
      Map<String, Object>? data;
      if (ownsData()) {
        final goal = await goals.getMacroGoal();
        final theme = await config.getConfigAppTheme();
        if (_disposed || revision != _revision) return;
        if (ownsData() && hive.intakeBox.isOpen) {
          data = nutritionWidgetData(
            day: now,
            intakes: hive.intakeBox.values.map(IntakeEntity.fromIntakeDBO),
            goal: goal,
            theme: theme.name,
          );
        }
      }
      if (_disposed || revision != _revision) return;
      await channel.invokeMethod<void>('update', data);
    } catch (error, stack) {
      // A launcher failure must not interrupt journal saves or authentication.
      _log.warning('Could not update home screen widget', error, stack);
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _revision++;
    _debounce?.cancel();
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}

@visibleForTesting
Map<String, Object> nutritionWidgetData({
  required DateTime day,
  required Iterable<IntakeEntity> intakes,
  required MacroGoalEntity? goal,
  required String theme,
}) {
  final date = DateTime(day.year, day.month, day.day);
  final today = intakes.where((e) =>
      DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day) == date);
  final active = MacroGoalEntity.forDay(goal, date);
  double sum(double Function(IntakeEntity) value) =>
      today.fold(0.0, (total, intake) => total + value(intake));
  return {
    'date': date.toIso8601String().split('T').first,
    'theme': theme,
    'kcal': sum((e) => e.totalKcal),
    'kcalGoal': macroCalories(
        carbs: active.carbs, fat: active.fats, protein: active.proteins),
    'carbs': sum((e) => e.totalCarbsGram),
    'carbsGoal': active.carbs,
    'fats': sum((e) => e.totalFatsGram),
    'fatsGoal': active.fats,
    'proteins': sum((e) => e.totalProteinsGram),
    'proteinsGoal': active.proteins,
  };
}
