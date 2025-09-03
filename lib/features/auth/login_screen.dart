import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:app_links/app_links.dart';
import 'package:email_validator/email_validator.dart';
import 'package:opennutritracker/features/auth/validate_password.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'forgot_password_screen.dart';
import 'reset_password_screen.dart';
import 'check_subscription.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_supabase_usecase.dart';
import 'package:opennutritracker/services/firebase_messaging_service.dart';
import 'package:opennutritracker/services/local_notifications_service.dart';
import 'package:opennutritracker/features/sync/supabase_client.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_macro_goal_usecase.dart';
import 'package:url_launcher/url_launcher.dart';

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
          final isGrantingUser500 =
              e.statusCode == "500" &&
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

  UserGenderEntity parseGender(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'female':
        return UserGenderEntity.female;
      case 'male':
        return UserGenderEntity.male;
      default:
        return UserGenderEntity.male; // défaut raisonnable
    }
  }

  UserWeightGoalEntity parseGoal(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'loseweight':
        return UserWeightGoalEntity.loseWeight;
      case 'gainweight':
        return UserWeightGoalEntity.gainWeight;
      case 'maintainweight':
        return UserWeightGoalEntity.maintainWeight;
      default:
        return UserWeightGoalEntity.maintainWeight;
    }
  }

  UserPALEntity parsePal(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'sedentary':
        return UserPALEntity.sedentary;
      case 'lightlyactive':
        return UserPALEntity.lowActive;
      case 'active':
        return UserPALEntity.active;
      case 'veryactive':
        return UserPALEntity.veryActive;
      default:
        return UserPALEntity.active;
    }
  }

  double parseNumToDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  DateTime parseBirthday(dynamic v) {
    if (v == null) return DateTime(2000, 1, 1);
    // Supabase renvoie généralement une string ISO pour DATE/TIMESTAMPTZ
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      return parsed ?? DateTime(2000, 1, 1);
    }
    if (v is DateTime) return v;
    return DateTime(2000, 1, 1);
  }

  Future<bool> _syncUserProfile(String userId) async {
    final addUser = locator<AddUserUsecase>();
    try {
      final rows = await supabase
          .from('users')
          .select(
            'display_name, role, height_cm, weight_kg, gender, goal, birthday, pal',
          )
          .eq('id', userId);

      if (rows.isEmpty) {
        Logger('LoginScreen').warning('No users found with ID $userId');
        return false;
      }

      final row = rows.first;
      final roleStr = (row['role'] as String?) ?? 'student';
      final displayName = (row['display_name'] as String?)?.trim();
      final heightCm = parseNumToDouble(row['height_cm'], fallback: 180);
      final weightKg = parseNumToDouble(row['weight_kg'], fallback: 80);
      final gender = parseGender(row['gender'] as String?);
      final goal = parseGoal(row['goal'] as String?);
      final pal = parsePal(row['pal'] as String?);
      final birthday = parseBirthday(row['birthday']);
      final role = roleStr == 'coach'
          ? UserRoleEntity.coach
          : UserRoleEntity.student;

      final user = UserEntity(
        name: displayName ?? '',
        birthday: birthday,
        heightCM: heightCm,
        weightKG: weightKg,
        gender: gender,
        goal: goal,
        pal: pal,
        role: role,
        profileImagePath: null,
      );

      await addUser.addUser(user);
      return true;
    } catch (e, stackTrace) {
      Logger(
        'LoginScreen',
      ).warning('Error when getting profile from Supabase', e, stackTrace);
      return false;
    }
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
        bool isSubscribed = await SubscriptionService(supabase).checkAndEnforceSubscription(context);
        if (!isSubscribed) {
          return;
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
        final getUser = locator<GetUserUsecase>();
        final hasProfile = await getUser.hasUserData();
        final userId = res.user?.id;

        final profileSynced = userId != null
            ? await _syncUserProfile(userId)
            : false;

        if (!profileSynced && !hasProfile) {
          await supabase.auth.signOut();
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
            return;
          }
        }

        // Récupère les pas du jour depuis Supabase
        try {
          final stepsService = SupabaseDailyStepsService();
          final today = DateUtils.dateOnly(DateTime.now());
          final steps = await stepsService.fetchDailySteps(userId!, today);
          await hive.dailyStepsBox.put(today.toIso8601String(), steps);
        } catch (e, stack) {
          Logger('LoginScreen').warning('Failed to fetch daily steps', e, stack);
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
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: Text(S.of(context).loginForgotPassword),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://atlas-tracker.fr/')),
                child: const Text('En savoir plus : atlas-tracker.fr'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
