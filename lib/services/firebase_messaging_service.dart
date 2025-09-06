import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/core/domain/usecase/add_macro_goal_usecase.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './local_notifications_service.dart';
import 'package:logging/logging.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._internal();
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService.instance() => _instance;
  String? _lastMessageId;

  final Logger log = Logger('FirebaseMessagingService');

  LocalNotificationsService? _localNotificationsService;

  Future<void> init(
      {required LocalNotificationsService localNotificationsService}) async {
    log.fine('[🔥] Initialisation FirebaseMessagingService démarrée');

    _localNotificationsService = localNotificationsService;

    final succeed = await _handlePushNotificationsToken();
    if (!succeed) {
      log.warning('[❗] Échec de l\'initialisation du token FCM');
      return;
    }

    await _requestPermission();

    // Foreground only: update macros live when user is in app
    log.fine('[🟢] Écoute des messages en foreground...');
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // We intentionally do NOT register background or opened-app handlers
    // so that updates happen only when app is in foreground.

    log.fine('[✅] Initialisation FirebaseMessagingService terminée');
  }

  Future<bool> _handlePushNotificationsToken() async {
    log.fine('[🔑] Récupération du token FCM...');
    final token = await FirebaseMessaging.instance.getToken();
    var success = false;

    if (token != null) {
      log.fine('[✅] Token FCM obtenu: $token');

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;

        if (userId == null) {
          log.severe(
              '[❌] Utilisateur non authentifié, impossible de mettre à jour le token.');
          return false;
        }

        log.fine('[📬] Mise à jour du token dans Supabase pour user: $userId');

        await Supabase.instance.client.from('user_devices').upsert({
          'user_id': userId,
          'fcm_token': token,
        }, onConflict: 'user_id');

        log.fine('[✅] Token FCM mis à jour dans Supabase');
        success = true;
      } catch (e, stack) {
        log.fine('[🔥] UPDATE Erreur lors de l\'update FCM dans Supabase: $e');
        log.fine(stack.toString());
        return false;
      }
    } else {
      log.fine('[❌] Token FCM est nul');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      log.fine('[♻️] Token FCM rafraîchi: $fcmToken');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        log.warning('[⚠️] Utilisateur non authentifié lors du refresh');
        return;
      }

      try {
        await Supabase.instance.client.from('user_devices').upsert({
          'user_id': userId,
          'fcm_token': fcmToken,
        }, onConflict: 'user_id');
        log.fine('[✅] Nouveau token FCM mis à jour après refresh');
      } catch (e, stack) {
        log.severe('[🔥] Erreur lors du refresh FCM dans Supabase: $e');
        log.severe(stack.toString());
      }
    }).onError((error) {
      log.severe('[❌] Erreur lors du rafraîchissement du token FCM: $error');
    });

    return success;
  }

  Future<bool> refreshPushNotificationsToken() async {
    return _handlePushNotificationsToken();
  }

  Future<bool> hasPushNotificationsToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }
    try {
      final result = await Supabase.instance.client
          .from('user_devices')
          .select('fcm_token')
          .eq('user_id', userId)
          .maybeSingle();
      final token = result?['fcm_token'] as String?;
      return token != null && token.isNotEmpty;
    } catch (e, stack) {
      log.warning('[❌] Erreur lors de la récupération du token FCM: $e');
      log.warning(stack.toString());
      return false;
    }
  }

  Future<void> _requestPermission() async {
    log.fine('[🔐] Demande de permission utilisateur...');
    final result = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    log.fine('[📋] Résultat permission: ${result.authorizationStatus}');
    switch (result.authorizationStatus) {
      case AuthorizationStatus.authorized:
        log.fine('[✅] Notifications AUTORISÉES');
        break;
      case AuthorizationStatus.denied:
        log.warning('[🚫] Notifications REFUSÉES');
        break;
      case AuthorizationStatus.notDetermined:
        log.warning('[❓] Autorisation non déterminée');
        break;
      case AuthorizationStatus.provisional:
        log.fine('[🟡] Autorisation provisoire');
        break;
    }
  }

  void _onForegroundMessage(RemoteMessage message) async {
    if (message.messageId != null && message.messageId == _lastMessageId) {
      log.warning('[🛑] Notification déjà traitée: ${message.messageId}');
      return;
    }
    _lastMessageId = message.messageId;
    log.fine('[📥] Message reçu en foreground');
    log.fine(
        '🔸 Notification: ${message.notification?.title} - ${message.notification?.body}');
    log.fine('🔸 Données: ${message.data}');
    log.fine('🔹 Message ID: ${message.messageId}');

    final notificationData = message.notification;
    if (notificationData != null) {
      _localNotificationsService?.showNotification(
        notificationData.title,
        notificationData.body,
        message.data.toString(),
      );
    } else {
      log.warning('[⚠️] Aucune donnée de notification à afficher');
    }

    try {
      await locator.get<AddMacroGoalUsecase>().addMacroGoalFromCoach();
      log.fine('[✅] Objectifs macro mis à jour depuis Supabase');
      // Refresh Home Page
      locator<HomeBloc>().add(const LoadItemsEvent());
      // Refresh Diary Page
      locator<DiaryBloc>().add(const LoadDiaryYearEvent());
      locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
    } catch (e, stack) {
      log.warning('[❌] Erreur lors de la mise à jour des macros : $e');
      log.warning(stack.toString());
    }
  }

  // Removed onMessageOpenedApp handler (foreground only strategy)
}

// Background handler removed (foreground only strategy)
