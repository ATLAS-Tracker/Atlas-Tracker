import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './auth_safe_sign_out.dart';

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

      final isSubscribed = row?['is_subscribed'] as bool? ?? false;

      if (!isSubscribed) {
        _showMessage(context,
            "Votre abonnement n'est plus actif. Veuillez contacter votre coach.");
        await safeSignOut(context);
        return false;
      }

      return true;
    } on PostgrestException catch (e) {
      _showMessage(context, "Erreur Supabase : ${e.message}");
      await safeSignOut(context);
      return false;
    } catch (_) {
      _showMessage(context, "Problème de synchronisation avec le cloud.");
      await safeSignOut(context);
      return false;
    }
  }

  void _showMessage(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }
}
