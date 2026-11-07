import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';

const _restoredKey = 'legacyBackupRestored';

/// Meals and saved foods read from a pre-row-sync logout backup.
typedef LegacyJournal = ({List<IntakeDBO> intakes, List<RecipesDBO> recipes});

/// Older exports may lack versions; an intake falls back to its own date.
LegacyJournal parseLegacyBackup(Uint8List zip) {
  final archive = ZipDecoder().decodeBytes(zip);
  List<Map<String, dynamic>> rows(String name) {
    final file = archive.findFile(name);
    if (file == null) return const [];
    return (jsonDecode(utf8.decode(file.content as List<int>)) as List)
        .cast<Map<String, dynamic>>();
  }

  return (
    intakes: rows(ExportImportBloc.userIntakeJsonFileName)
        .map((row) => IntakeDBO.fromJson(
            {...row, 'updatedAt': row['updatedAt'] ?? row['dateTime']}))
        .toList(),
    recipes: rows(ExportImportBloc.recipesJsonFileName)
        .map(RecipesDBO.fromJson)
        .toList(),
  );
}

/// Before row sync, meals lived only on the device and in the zip uploaded at
/// sign-out. Restores them once into an empty journal so the next sync pushes
/// them to user_intakes. Weights, days and profile already sync from tables,
/// so they are not touched (the old importer's deletions would propagate).
Future<void> restoreLegacyBackupOnce(SupabaseClient client, String owner) async {
  final hive = locator<HiveDBProvider>();
  final metadata = hive.syncMetadataBox;
  if (metadata == null || metadata.get(_restoredKey) != null) return;
  if (hive.intakeBox.isNotEmpty) {
    await metadata.put(_restoredKey, 'local');
    return;
  }
  const timeout = Duration(seconds: 8);
  final remote = await client
      .from('user_intakes')
      .select('record_id')
      .eq('user_id', owner)
      .limit(1)
      .timeout(timeout);
  if (remote.isNotEmpty) {
    await metadata.put(_restoredKey, 'remote');
    return;
  }
  final bucket = client.storage.from('exports');
  final files = await bucket.list(path: owner).timeout(timeout);
  if (!files.any((f) => f.name == ExportImportBloc.exportZipFileName)) {
    await metadata.put(_restoredKey, 'none');
    return;
  }
  final zip = await bucket
      .download('$owner/${ExportImportBloc.exportZipFileName}')
      .timeout(const Duration(seconds: 30));
  final journal = parseLegacyBackup(zip);
  if (client.auth.currentUser?.id != owner || hive.activeUserId != owner) return;
  await locator<IntakeRepository>().addAllIntakeDBOs(journal.intakes);
  final recipes = journal.recipes
      .where((r) => !hive.recipeBox.containsKey(r.recipe.code ?? r.recipe.name))
      .toList();
  if (recipes.isNotEmpty) {
    await locator<RecipeRepository>().addAllRecipeDBOs(recipes);
  }
  await metadata.put(_restoredKey, 'zip');
  Logger('LegacyBackupRestore').info(
      'Restored ${journal.intakes.length} intakes, ${recipes.length} recipes.');
}
