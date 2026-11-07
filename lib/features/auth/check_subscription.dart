import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './auth_safe_sign_out.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SubscriptionService {
  final SupabaseClient client;

  SubscriptionService(this.client);

  /// Pure business logic: check subscription status.
  /// Returns (success, codeWithOptionalDetails).
  Future<(bool success, String? code)> checkSubscription() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return (false, 'user_not_connected');
    }

    try {
      final row = await client
          .from('subscription')
          .select('is_subscribed')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      final isSubscribed = row?['is_subscribed'] as bool? ?? false;

      if (!isSubscribed) {
        return (false, 'subscription_inactive');
      }

      return (true, null);
    } on PostgrestException catch (e) {
      return (false, 'supabase_error:${e.message}');
    } catch (_) {
      return (false, 'cloud_sync_problem');
    }
  }

  Future<bool> checkAndEnforceSubscription(BuildContext context) async {
    final (ok, code) = await checkSubscription();

    if (!context.mounted) return false;

    if (!ok) {
      if (code != null) {
        String msg;
        if (code.startsWith('supabase_error:')) {
          final detail = code.substring('supabase_error:'.length);
          msg = S.of(context).supabaseError(detail);
        } else if (code == 'user_not_connected') {
          msg = S.of(context).userNotConnected;
        } else if (code == 'subscription_inactive') {
          msg = S.of(context).subscriptionInactiveMessage;
        } else {
          msg = S.of(context).cloudSyncProblem;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      await safeSignOut(context);
      return false;
    }

    return true;
  }
}
