import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';

class ManageAccountDialog extends StatefulWidget {
  const ManageAccountDialog({super.key});

  @override
  State<ManageAccountDialog> createState() => _ManageAccountDialogState();
}

class _ManageAccountDialogState extends State<ManageAccountDialog> {
  bool _syncEnabled = true;
  bool _saving = false;

  final _addConfig = locator<AddConfigUsecase>();
  final _configRepo = locator<ConfigRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _configRepo.getSupabaseSyncEnabled();
      if (!mounted) return;
      setState(() => _syncEnabled = enabled);
    } catch (e) {
      debugPrint('Load supabase_sync_enabled failed: $e');
    }
  }

  Future<void> _toggleSync(bool value) async {
    setState(() {
      _syncEnabled = value;
      _saving = true;
    });
    try {
      await _addConfig.setSupabaseSyncEnabled(value); // <-- PERSISTE (await)
      // Optionnel: relire pour vérifier qu'on a bien stocké
      final saved = await _configRepo.getSupabaseSyncEnabled();
      if (!mounted) return;
      if (saved != value) {
        setState(() => _syncEnabled = saved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.of(context).savePreferenceFailed)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _syncEnabled = !value); // rollback visuel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).errorPrefix} $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).manageAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).manageAccountDescription),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(S.of(context).manageAccountEnableSync),
              value: _syncEnabled,
              onChanged: _saving ? null : _toggleSync,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _confirmDelete(context),
              child: Text(S.of(context).manageAccountDelete),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).manageAccountConfirmTitle),
        content: Text(S.of(context).manageAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).manageAccountConfirmAction),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).userNotConnected)),
      );
      return;
    }

    try {
      final response = await supabase.functions.invoke('delete_my_account');
      if (!mounted) return;

      if (response.status == 200) {
        final hive = locator<HiveDBProvider>();
        await hive.deleteCurrentUserDatabase();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).accountDeletedSuccess)),
        );

        try {
          debugPrint('Appel supabase.auth.signOut()');
          await supabase.auth.signOut();
        } catch (err, stack) {
          debugPrint('Erreur pendant signOut: $err\n$stack');
        }

        final hive2 = locator<HiveDBProvider>();
        await hive2.initForUser(null);
        await registerUserScope(hive2);
        if (!mounted) return;

        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
        if (!mounted) return;

        Navigator.of(context)
            .pushReplacementNamed(NavigationOptions.loginRoute);
        debugPrint('safeSignOut terminé → retour login.');
      } else {
        final errorMessage = response.data?['error'] ?? S.of(context).loginUnknownError;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).failedToDeleteWithReason(errorMessage))),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Error deleting account: $e\n$stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).genericErrorOccurred)),
      );
    }
  }
}
