// auth_safe_sign_out.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:opennutritracker/generated/l10n.dart';

import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_supabase_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';

final _log = Logger('AuthSafeSignOut');

Future<void> safeSignOut(BuildContext context) async {
  final supabase = locator<SupabaseClient>();
  final exportUsecase = locator<ExportDataSupabaseUsecase>();
  final configRepo = locator<ConfigRepository>();
  final connectivity = locator<Connectivity>();
  final userId = supabase.auth.currentUser?.id;

  // Si pas de réseau, on abandonne
  if (await connectivity.checkConnectivity() == ConnectivityResult.none) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).signOutOfflineMessage)),
      );
    }
    return;
  }

  // Affiche un loader si l’utilisateur est connecté
  if (userId != null && context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  bool exportOk = true;

  try {
    if (userId != null) {
      // ——— Toujours exporter ———
      Future<bool> doExport() => exportUsecase.exportData(
            ExportImportBloc.exportZipFileName,
            ExportImportBloc.userActivityJsonFileName,
            ExportImportBloc.userIntakeJsonFileName,
            ExportImportBloc.trackedDayJsonFileName,
            ExportImportBloc.userWeightJsonFileName,
            ExportImportBloc.recipesJsonFileName,
            ExportImportBloc.userJsonFileName,
          );

      exportOk = await doExport();
      if (!exportOk) {
        _log.warning('Export échoué – nouvelle tentative');
        exportOk = await doExport();
      }

      if (exportOk) {
        // On marque la date de dernière sauvegarde (optionnel, pratique)
        await configRepo.setLastDataUpdate(DateTime.now().toUtc());
        _log.fine('Export réussi avant déconnexion');
      }
    } else {
      _log.warning('safeSignOut appelé sans session active');
    }
  } catch (err, stack) {
    exportOk = false;
    _log.severe('Erreur pendant export', err, stack);
  }

  // ——— Si l’export a échoué → on reste connecté, on ferme le loader et on prévient ———
  if (!exportOk) {
    if (context.mounted && userId != null) {
      Navigator.of(context, rootNavigator: true).pop(); // ferme le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).signOutSyncFailedMessage)),
      );
    }
    return;
  }

  // ——— Déconnexion (seulement si export OK) ———
  try {
    // Synchronise today's steps before signing out
    if (userId != null) {
      try {
        final hive = locator<HiveDBProvider>();
        final today = DateUtils.dateOnly(DateTime.now());
        final key = today.toIso8601String();
        final steps =
            hive.dailyStepsBox.get(key, defaultValue: 0) as int;
        await SupabaseDailyStepsService().upsertDailySteps([
          {
            'user_id': userId,
            'date': key.split('T').first,
            'steps': steps,
          }
        ]);
      } catch (err, stack) {
        _log.warning('Failed to sync today steps', err, stack);
      }
    }

    try {
      await supabase.auth.signOut();
    } catch (err, stack) {
      _log.warning('Erreur pendant signOut', err, stack);
    }

    final hive = locator<HiveDBProvider>();
    await hive.initForUser(null);
    await registerUserScope(hive);

    if (!context.mounted) return;

    // Ferme le loader + revient à la racine puis va sur l’écran de login
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
    Navigator.of(context).pushReplacementNamed(NavigationOptions.loginRoute);
    _log.fine('safeSignOut terminé → retour login');
  } catch (err, stack) {
    _log.severe('Erreur post-signOut', err, stack);
    if (context.mounted && userId != null) {
      Navigator.of(context, rootNavigator: true)
          .pop(); // au cas où le loader est encore là
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).exportImportErrorLabel)),
      );
    }
  }
}
