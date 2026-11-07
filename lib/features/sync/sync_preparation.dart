import 'dart:convert';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_weight_dbo.dart';
import 'package:opennutritracker/core/data/sync_metadata.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class PreparedSyncSnapshot {
  final String? userId;
  final Map<String, List<Map<String, dynamic>>> tables;
  final Set<String> rejected;
  const PreparedSyncSnapshot(this.userId, this.tables, this.rejected);
  List<Map<String, dynamic>> rows(String table) => tables[table] ?? const [];
}

/// The only conversion from user-scoped local records to uploadable rows.
class SyncPreparation {
  static const tables = [
    'user_intakes',
    'user_recipes',
    'tracked_days',
    'user_weight'
  ];

  static PreparedSyncSnapshot fromHive(HiveDBProvider hive, String? userId) =>
      prepare(
        userId: userId,
        ownerId: hive.activeUserId,
        intakes: hive.intakeBox.values.toList(),
        recipes: hive.recipeBox.values.toList(),
        days: hive.trackedDayBox.values.toList(),
        weights: hive.userWeightBox.values.toList(),
        deletions: SyncMetadata(hive.syncMetadataBox).deletions,
      );

  static PreparedSyncSnapshot prepare({
    required String? userId,
    required String? ownerId,
    required List<IntakeDBO> intakes,
    required List<RecipesDBO> recipes,
    required List<TrackedDayDBO> days,
    required List<UserWeightDbo> weights,
    List<Map<String, dynamic>> deletions = const [],
    DateTime? now,
  }) {
    if (userId == null || userId.isEmpty || userId != ownerId) {
      return const PreparedSyncSnapshot(null, {}, {'owner'});
    }
    final clock = (now ?? DateTime.now()).toUtc();
    final result = {
      for (final table in tables) table: <Map<String, dynamic>>[]
    };
    final rejected = <String>{};
    Map<String, dynamic> detached(Map<String, dynamic> value) =>
        Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
    bool validDate(DateTime date) =>
        date.year >= 2000 && date.year <= clock.year + 2;
    bool validVersion(DateTime date) =>
        date.millisecondsSinceEpoch >= 0 &&
        !date.isAfter(clock.add(const Duration(minutes: 5)));
    bool number(num? value, double max, {bool positive = false}) =>
        value != null &&
        value.isFinite &&
        (positive ? value > 0 : value >= 0) &&
        value <= max;
    bool mealValid(MealDBO meal) {
      final nutrients = meal.nutriments;
      return number(nutrients.energyKcalPerQuantity, 1000000) &&
          [
            nutrients.carbohydratesPerQuantity,
            nutrients.fatPerQuantity,
            nutrients.proteinsPerQuantity,
            nutrients.sugarsPerQuantity,
            nutrients.saturatedFatPerQuantity,
            nutrients.fiberPerQuantity
          ].every((value) => value == null || number(value, 100000)) &&
          (meal.servingQuantity == null ||
              number(meal.servingQuantity, 100000, positive: true));
    }

    final tombstones = <String, Map<String, dynamic>>{};
    for (final deletion in deletions) {
      final table = deletion['table'];
      final id = deletion['record_id'];
      final version =
          DateTime.tryParse(deletion['modified_at']?.toString() ?? '');
      if (!tables.contains(table) ||
          id is! String ||
          id.isEmpty ||
          id.length > 256 ||
          version == null ||
          !validVersion(version)) {
        rejected.add('deletion/$id');
        continue;
      }
      if (table == 'user_weight' &&
          (DateTime.tryParse(id) == null || !validDate(DateTime.parse(id)))) {
        rejected.add('deletion/$id');
        continue;
      }
      final key = '$table/$id';
      final previous = tombstones[key];
      if (previous == null ||
          version.isAfter(DateTime.parse(previous['modified_at'] as String))) {
        tombstones[key] = {
          'table': table,
          'record_id': id,
          'modified_at': version.toUtc().toIso8601String()
        };
      }
    }
    bool deleted(String table, String id, DateTime version) {
      final row = tombstones['$table/$id'];
      return row != null &&
          !version.isAfter(DateTime.parse(row['modified_at'] as String));
    }

    Map<String, dynamic> envelope(
            String id, Map<String, dynamic> payload, DateTime version) =>
        {
          'user_id': userId,
          'record_id': id,
          'payload': payload,
          'modified_at': version.toUtc().toIso8601String(),
          'deleted_at': null,
        };
    final newestIntakes =
        _newest(intakes, (row) => row.id, (row) => row.updatedAt);
    final sums = <String, List<double>>{};
    final latestIntake = <String, DateTime>{};
    final unsafeDays = <String>{};
    for (final row in newestIntakes.values) {
      if (deleted('user_intakes', row.id, row.updatedAt)) continue;
      if (row.id.isEmpty ||
          row.id.length > 256 ||
          !validDate(row.dateTime) ||
          !validVersion(row.updatedAt) ||
          !number(row.amount, row.unit == 'serving' ? 1000 : 100000,
              positive: true) ||
          !mealValid(row.meal)) {
        rejected.add('user_intakes/${row.id}');
        unsafeDays.add(row.dateTime.toDayKey());
        continue;
      }
      final intake = IntakeEntity.fromIntakeDBO(row);
      final values = [
        intake.totalKcal,
        intake.totalCarbsGram,
        intake.totalFatsGram,
        intake.totalProteinsGram
      ];
      final day = row.dateTime.toDayKey();
      final sum = sums.putIfAbsent(day, () => [0, 0, 0, 0]);
      for (var i = 0; i < values.length; i++) {
        sum[i] += values[i];
      }
      if (latestIntake[day] == null ||
          row.updatedAt.isAfter(latestIntake[day]!)) {
        latestIntake[day] = row.updatedAt;
      }
      final payload = detached(row.toJson());
      payload['unit'] = MealEntity.metricUnit(row.unit);
      payload['dateTime'] = day;
      result['user_intakes']!.add(envelope(row.id, payload, row.updatedAt));
    }
    for (final entry in sums.entries) {
      if (!number(entry.value[0], 100000) ||
          entry.value.skip(1).any((value) => !number(value, 25000))) {
        unsafeDays.add(entry.key);
        rejected.add('tracked_days/${entry.key}');
      }
    }
    result['user_intakes']!.removeWhere(
        (row) => unsafeDays.contains((row['payload'] as Map)['dateTime']));
    final newestDays =
        _newest(days, (row) => row.day.toDayKey(), (row) => row.updatedAt);
    for (final day in {...newestDays.keys, ...sums.keys}) {
      if (unsafeDays.contains(day) || !validDate(DateTime.parse(day))) continue;
      final source = newestDays[day];
      if (source != null &&
          (!validVersion(source.updatedAt) ||
              !number(source.calorieGoal, 10000) ||
              !number(source.caloriesBurned, 100000) ||
              [source.carbsGoal, source.fatGoal, source.proteinGoal]
                  .any((value) => value != null && !number(value, 1000)))) {
        rejected.add('tracked_days/$day');
        continue;
      }
      final totals = sums[day] ?? [0.0, 0.0, 0.0, 0.0];
      var version = source?.updatedAt ?? latestIntake[day]!;
      if (latestIntake[day]?.isAfter(version) == true) {
        version = latestIntake[day]!;
      }
      result['tracked_days']!.add({
        'user_id': userId,
        'day': day,
        'calorieGoal': source?.calorieGoal ?? 0,
        'carbsGoal': source?.carbsGoal,
        'fatGoal': source?.fatGoal,
        'proteinGoal': source?.proteinGoal,
        'caloriesTracked': totals[0],
        'carbsTracked': totals[1],
        'fatTracked': totals[2],
        'proteinTracked': totals[3],
        'caloriesBurned': source?.caloriesBurned ?? 0,
        'modified_at': version.toUtc().toIso8601String(),
      });
    }
    final newestRecipes = _newest(
        recipes,
        (row) => row.recipe.code ?? row.recipe.name ?? '',
        (row) => row.updatedAt);
    for (final entry in newestRecipes.entries) {
      final row = entry.value;
      if (deleted('user_recipes', entry.key, row.updatedAt)) continue;
      if (entry.key.isEmpty ||
          entry.key.length > 256 ||
          !validVersion(row.updatedAt) ||
          !mealValid(row.recipe) ||
          row.ingredients.any((ingredient) =>
              !number(ingredient.amount, 100000, positive: true) ||
              ingredient.meal == null ||
              !mealValid(ingredient.meal!))) {
        rejected.add('user_recipes/${entry.key}');
        continue;
      }
      result['user_recipes']!
          .add(envelope(entry.key, detached(row.toJson()), row.updatedAt));
    }
    final newestWeights =
        _newest(weights, (row) => row.date.toDayKey(), (row) => row.updatedat);
    for (final entry in newestWeights.entries) {
      final row = entry.value;
      if (deleted('user_weight', entry.key, row.updatedat)) continue;
      if (row.id.isEmpty ||
          !validDate(row.date) ||
          !validVersion(row.updatedat) ||
          !number(row.weight, 400, positive: true)) {
        rejected.add('user_weight/${entry.key}');
        continue;
      }
      result['user_weight']!.add({
        'user_id': userId,
        'id': row.id,
        'date': entry.key,
        'weight': row.weight,
        'modified_at': row.updatedat.toUtc().toIso8601String(),
        'deleted_at': null
      });
    }
    for (final deletion in tombstones.values) {
      final table = deletion['table'] as String;
      final id = deletion['record_id'] as String;
      final dateField = table == 'user_weight' ? 'date' : 'record_id';
      if (table == 'tracked_days' ||
          result[table]!.any((row) => row[dateField] == id)) {
        continue;
      }
      final version = deletion['modified_at'];
      result[table]!.add({
        'user_id': userId,
        dateField: id,
        if (table == 'user_weight') ...{
          'id': IdGenerator.uuid.v5('6ba7b811-9dad-11d1-80b4-00c04fd430c8',
              '$userId/user_weight/$id'),
          'weight': 0
        },
        if (table != 'user_weight') 'payload': <String, dynamic>{},
        'modified_at': version,
        'deleted_at': version
      });
    }
    for (final rows in result.values) {
      rows.sort((a, b) => (a['record_id'] ?? a['day'] ?? a['date'])
          .toString()
          .compareTo((b['record_id'] ?? b['day'] ?? b['date']).toString()));
    }
    return PreparedSyncSnapshot(userId, result, rejected);
  }

  static Map<String, T> _newest<T>(
      Iterable<T> rows, String Function(T) key, DateTime Function(T) version) {
    final result = <String, T>{};
    for (final row in rows) {
      final previous = result[key(row)];
      if (previous == null || version(row).isAfter(version(previous))) {
        result[key(row)] = row;
      }
    }
    return result;
  }
}
