import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:email_validator/email_validator.dart';
import 'package:opennutritracker/features/auth/validate_password.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'forgot_password_screen.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_supabase_usecase.dart';
import 'package:opennutritracker/services/firebase_messaging_service.dart';
import 'package:opennutritracker/services/local_notifications_service.dart';
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
  final supabase = Supabase.instance.client;

  /// Navigate to the home screen after a successful sign-in.
  void _navigateHome() =>
      Navigator.of(context).pushReplacementNamed(NavigationOptions.mainRoute);

  /// Display an error message and log it.
  void _showError(Object error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
    Logger('LoginScreen').warning('Auth error', error);
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
        // ── 1. Prépare Hive pour le user (nécessaire à l’import) + add user profile if needed
        final hive = locator<HiveDBProvider>();
        await hive.initForUser(res.user?.id);
        await registerUserScope(hive);

        final getUser = locator<GetUserUsecase>();

        final hasProfile = await getUser.hasUserData();
        if (!hasProfile) {
          final userId = res.user?.id;
          final addUser = locator<AddUserUsecase>();

          try {
            final List<Map<String, dynamic>> rows = await supabase
                .from('users')
                .select(
                    'display_name, role, height_cm, weight_kg, gender, goal, birthday, pal')
                .eq('id', userId!);

            if (rows.isEmpty) {
              debugPrint('No users found with ID $userId');
              // On continue quand même : le profil local sera créé par défaut
            }

            if (rows.isNotEmpty) {
              final row = rows.first;
              final roleStr = (row['role'] as String?) ?? 'student';
              final displayName = (row['display_name'] as String?)?.trim();
              final heightCm =
                  parseNumToDouble(row['height_cm'], fallback: 180);
              final weightKg = parseNumToDouble(row['weight_kg'], fallback: 80);
              final gender = parseGender(row['gender'] as String?);
              final goal = parseGoal(row['goal'] as String?);
              final pal = parsePal(row['pal'] as String?);
              final birthday = parseBirthday(row['birthday']);
              final role = roleStr == 'coach'
                  ? UserRoleEntity.coach
                  : UserRoleEntity.student;

              final user = UserEntity(
                name: displayName!,
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
            }
          } catch (e, stackTrace) {
            debugPrint('Error when getting profile from Supabase: $e');
            debugPrint('Stack trace: $stackTrace');
            await supabase.auth.signOut();
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

        // Récupérer les objectifs si student
        final user = await getUser.getUserData();
        if (user.role == UserRoleEntity.student) {
          try {
            final user = await locator.get<GetUserUsecase>().getUserData();
            if (user.role == UserRoleEntity.student) {
              await locator.get<AddMacroGoalUsecase>().addMacroGoalFromCoach();
              Logger('LoginScreen')
                  .fine('[✅] Objectifs macro mis à jour depuis Supabase');
            }
          } catch (e, stack) {
            Logger('LoginScreen')
                .warning('[❌] Erreur lors de la mise à jour des macros : $e');
            Logger('LoginScreen').warning(stack.toString());
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

        // ── 4. Tout est OK  →  on passe à l’app
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
  }

  @override
  void dispose() {
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
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
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
