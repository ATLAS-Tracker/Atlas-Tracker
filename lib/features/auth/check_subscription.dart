import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './auth_safe_sign_out.dart';

class SubscriptionService {
  final SupabaseClient client;

  SubscriptionService(this.client);

  /// Pure business logic: check subscription status.
  /// Returns (success, message).
  Future<(bool success, String? message)> checkSubscription() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return (false, "Utilisateur non connecté.");
    }

    try {
      final row = await client
          .from('subscription')
          .select('is_subscribed')
          .eq('id', userId)
          .maybeSingle();

      final isSubscribed = row?['is_subscribed'] as bool? ?? false;

      if (!isSubscribed) {
        return (
          false,
          "Votre abonnement n'est plus actif. Veuillez contacter votre coach."
        );
      }

      return (true, null);
    } on PostgrestException catch (e) {
      return (false, "Erreur Supabase : ${e.message}");
    } catch (_) {
      return (false, "Problème de synchronisation avec le cloud.");
    }
  }

  Future<bool> checkAndEnforceSubscription(BuildContext context) async {
    final (ok, message) = await checkSubscription();

    if (!context.mounted) return false;

    if (!ok) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      await safeSignOut(context);
      return false;
    }

    return true;
  }
}
