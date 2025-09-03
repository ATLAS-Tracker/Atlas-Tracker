import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient client;

  SubscriptionService(this.client);

  Future<bool> checkAndEnforceSubscription(BuildContext context) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final row = await client
          .from('subscription')
          .select('is_subscribed')
          .eq('id', userId)
          .maybeSingle();

      final isSubscribed = row?['subscribed'] as bool? ?? false;

      if (!isSubscribed) {
        _showMessage(context,
            "Votre abonnement n'est plus actif. Veuillez contacter votre coach.");
        return await safeLogout(context);
      }

      return true;
    } on PostgrestException catch (e) {
      _showMessage(context, "Erreur Supabase : ${e.message}");
      return await safeLogout(context);
    } catch (_) {
      _showMessage(context, "Problème de synchronisation avec le cloud.");
      return await safeLogout(context);
    }
  }

  void _showMessage(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<bool> safeLogout(BuildContext context) async {
    try {
      await client.auth.signOut();
    } catch (_) {
      _showMessage(context, "Erreur lors de la déconnexion.");
    }
    return false;
  }
}
