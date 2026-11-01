import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:app_links/app_links.dart';
import 'package:email_validator/email_validator.dart';
import 'package:opennutritracker/features/auth/validate_password.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'reset_password_screen.dart';
import 'otp_password_reset_email_screen.dart';
import 'check_subscription.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_supabase_usecase.dart';
import 'package:opennutritracker/features/sync/journal_remote_sync_service.dart';
import 'package:opennutritracker/features/sync/startup_remote_sync_service.dart';
import 'package:opennutritracker/features/sync/profile_remote_sync.dart';
import 'package:opennutritracker/services/firebase_messaging_service.dart';
import 'package:opennutritracker/services/local_notifications_service.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_macro_goal_usecase.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'auth_safe_sign_out.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  Timer? _deepLinkDebounce;
  final supabase = Supabase.instance.client;

  // Deep-link / auth
  StreamSubscription<Uri?>? _linksSub;
  bool _handledDeepLink = false; // évite de consommer le flow PKCE 2x
  bool _navigatedToReset = false; // évite la navigation multiple

  /// Navigate to the home screen after a successful sign-in.
  void _navigateHome() =>
      Navigator.of(context).pushReplacementNamed(NavigationOptions.mainRoute);

  /// Display an error message and log it.
  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$error')));
    Logger('LoginScreen').warning('Auth error', error);
  }

  /// Configure deep-link handling (password-reset flow).
  void _configDeepLink() {
    final links = AppLinks();

    _linksSub = links.uriLinkStream.listen((Uri? uri) async {
      if (!mounted || uri == null || uri.host != 'login-callback') return;

      // Debounce pour éviter 2 appels en rafale (Android activity resume, etc.)
      _deepLinkDebounce?.cancel();
      _deepLinkDebounce = Timer(const Duration(milliseconds: 250), () async {
        if (_handledDeepLink) return;
        _handledDeepLink = true;

        try {
          // Consomme le flow state UNE fois
          await supabase.auth.getSessionFromUrl(uri);
          // Ne pas naviguer ici : on attend l’event passwordRecovery
        } on AuthException catch (e, s) {
          final msg = e.message.toLowerCase();

          // ➜ Cas “bruyant mais OK” : 500 ‘Database error granting user’
          final isGrantingUser500 = e.statusCode == "500" &&
              msg.contains('database error granting user');

          // ➜ Cas « déjà consommé »
          final alreadyConsumed =
              msg.contains('flow state') || e.statusCode == "404";

          if (isGrantingUser500 || alreadyConsumed) {
            Logger('LoginScreen').fine('Deep-link secondaire ignoré: $e');
            // On relâche le verrou pour autoriser une future tentative si besoin
            _handledDeepLink = false;
            return;
          }

          Logger('LoginScreen').warning('Deep-link error', e, s);
          _handledDeepLink = false;
        } catch (e, s) {
          Logger('LoginScreen').warning('Deep-link error', e, s);
          _handledDeepLink = false;
        }
      });
    });
  }

  /// Écoute les changements d’état auth (dont passwordRecovery).
  void _listenAuthEvents() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (!mounted) return;

      if (event == AuthChangeEvent.passwordRecovery && !_navigatedToReset) {
        _navigatedToReset = true;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
      }
    });
  }

  /// Attempt to authenticate with e-mail / password.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();

    // Capture tout ce qui touche au context avant l'async gap
    final l10n = S.of(context);

    try {
      // ❌ Ne pas faire de signOut() avant un signIn : ça peut casser le flow PKCE.
      // await supabase.auth.signOut();

      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: pass,
      );

      if (res.session != null) {
        // ── 1. Prépare Hive pour le user (nécessaire à l’import)
        final hive = locator<HiveDBProvider>();
        await hive.initForUser(res.user?.id);
        await registerUserScope(hive);

        // Check subscription status
        // If the user is not subscribed anymore push is data to save them for later
        if (mounted) {
          bool isSubscribed = await SubscriptionService(supabase)
              .checkAndEnforceSubscription(context);
          if (!isSubscribed) {
            return;
          }
        }

        // ── 2. Tente l’import
        final importData = locator<ImportDataSupabaseUsecase>();
        final importSuccessful = await importData.importData(
          ExportImportBloc.exportZipFileName,
          ExportImportBloc.userActivityJsonFileName,
          ExportImportBloc.userIntakeJsonFileName,
          ExportImportBloc.trackedDayJsonFileName,
          ExportImportBloc.userWeightJsonFileName,
          ExportImportBloc.recipesJsonFileName,
          ExportImportBloc.userJsonFileName,
        );

        // ── 3. ERREUR D’IMPORT  →  on déconnecte la session
        if (!importSuccessful) {
          try {
            await supabase.auth.signOut(); // libère le « verrou »
          } catch (e, s) {
            Logger('LoginScreen').warning('Forced sign-out failed', e, s);
          }

          // Nettoie la base locale (facultatif mais recommandé)
          await hive.initForUser(null);
          await registerUserScope(hive);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).exportImportErrorLabel)),
            );
          }
          return; // reste sur l’écran de login
        }

        // ── 4. Rafraîchit le profil depuis Supabase pour annuler un import obsolète
        await locator<JournalRemoteSyncService>().syncAtStartup();
        await locator<StartupRemoteSyncService>().syncAtStartup();

        final getUser = locator<GetUserUsecase>();
        final hasProfile = await getUser.hasUserData();
        final isUserProfileSync = await syncProfileFromSupabase(supabase);
        if (!hasProfile && !isUserProfileSync && mounted) {
          await safeSignOut(context);
          return;
        }

        // Récupérer les objectifs si student
        final user = await getUser.getUserData();
        if (user.role == UserRoleEntity.student) {
          try {
            final user = await locator.get<GetUserUsecase>().getUserData();
            if (user.role == UserRoleEntity.student) {
              await locator.get<AddMacroGoalUsecase>().addMacroGoalFromCoach();
              Logger(
                'LoginScreen',
              ).fine('[✅] Objectifs macro mis à jour depuis Supabase');
            }
          } catch (e, stack) {
            Logger(
              'LoginScreen',
            ).warning('[❌] Erreur lors de la mise à jour des macros : $e');
            Logger('LoginScreen').warning(stack.toString());
            if (!mounted) return;
            await safeSignOut(context);
            return;
          }
        }

        // ✅ Init Firebase Messaging & Local Notifications après login
        final localNotificationsService = LocalNotificationsService.instance();
        await localNotificationsService.init();

        final firebaseMessagingService = FirebaseMessagingService.instance();
        await firebaseMessagingService.init(
          localNotificationsService: localNotificationsService,
        );

        // ── 5. Tout est OK  →  on passe à l’app
        _navigateHome();
      }
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();

      if (!mounted) return; // context might be gone

      if (message.contains('error granting user')) {
        _showError(l10n.loginAlreadySignedIn);
      } else {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _configDeepLink();
    _listenAuthEvents();
  }

  @override
  void dispose() {
    _deepLinkDebounce?.cancel();
    _linksSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).loginTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: S.of(context).loginEmailLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? S.of(context).loginEmailRequired
                    : (EmailValidator.validate(v.trim())
                        ? null
                        : S.of(context).loginEmailInvalid),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: S.of(context).loginPasswordLabel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => validatePassword(context, value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(S.of(context).loginButton),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OtpPasswordResetEmailScreen(),
                  ),
                ),
                child: Text(S.of(context).loginForgotPassword),
              ),
              const SizedBox(height: 24),
              // TODO: uncomment as soon as the website is finalized
              /*TextButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://atlas-tracker.fr/')),
                child: Text(S.of(context).learnMoreLabel),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
