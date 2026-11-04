import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_weight_repository.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'journal_sync_engine.dart';

/// Public lifecycle for the single owner-scoped journal synchronization queue.
class JournalRemoteSyncService {
  final JournalSyncEngine _engine;
  static const String intakesTable = 'user_intakes';
  static const String recipesTable = 'user_recipes';

  JournalRemoteSyncService({
    required IntakeRepository intakeRepository,
    required RecipeRepository recipeRepository,
    required TrackedDayRepository trackedDayRepository,
    required UserWeightRepository userWeightRepository,
    required ConfigRepository configRepository,
    required SupabaseClient client,
    required HiveDBProvider hive,
  }) : _engine = JournalSyncEngine(
            hive: hive,
            client: client,
            config: configRepository,
            intakes: intakeRepository,
            recipes: recipeRepository,
            days: trackedDayRepository,
            weights: userWeightRepository);

  Future<void> startAutoPush() => _engine.start();
  Future<void> stopAutoPush() => _engine.stop();
  Future<void> syncAtStartup() => _engine.sync();
  Future<void> syncLocalToRemote() => _engine.sync();

  static List<IntakeDBO> remoteIntakesToSave({
    required List<IntakeDBO> local,
    required List<IntakeDBO> remote,
  }) =>
      _newer(remote, local, (row) => row.id, (row) => row.updatedAt);

  static List<IntakeDBO> localIntakesToUpload({
    required List<IntakeDBO> local,
    required List<IntakeDBO> remote,
  }) =>
      _newer(local, remote, (row) => row.id, (row) => row.updatedAt);

  static List<RecipesDBO> remoteRecipesToSave({
    required List<RecipesDBO> local,
    required List<RecipesDBO> remote,
  }) =>
      _newer(remote, local, recipeKey, (row) => row.updatedAt);

  static List<RecipesDBO> localRecipesToUpload({
    required List<RecipesDBO> local,
    required List<RecipesDBO> remote,
  }) =>
      _newer(local, remote, recipeKey, (row) => row.updatedAt);

  static List<T> _newer<T>(List<T> incoming, List<T> existing,
      String Function(T) key, DateTime Function(T) version) {
    final current = <String, T>{};
    final candidates = <String, T>{};
    for (final row in existing) {
      final previous = current[key(row)];
      if (previous == null || version(row).isAfter(version(previous))) {
        current[key(row)] = row;
      }
    }
    for (final row in incoming) {
      final previous = candidates[key(row)];
      if (previous == null || version(row).isAfter(version(previous))) {
        candidates[key(row)] = row;
      }
    }
    return candidates.values
        .where((row) =>
            current[key(row)] == null ||
            version(row).isAfter(version(current[key(row)] as T)))
        .toList();
  }

  static String recipeKey(RecipesDBO recipe) =>
      recipe.recipe.code ?? recipe.recipe.name ?? '';
}
