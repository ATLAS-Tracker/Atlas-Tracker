import 'package:flutter/material.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/core/presentation/widgets/atlas_brand_panel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_gender_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_goal_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_height_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_pal_category_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_photo_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'coach_students_page.dart';
import 'presentation/widgets/manage_account_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileBloc _profileBloc;

  @override
  void initState() {
    _profileBloc = locator<ProfileBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: _profileBloc,
      builder: (context, state) {
        if (state is ProfileInitial) {
          _profileBloc.add(LoadProfileEvent());
          return _getLoadingContent();
        } else if (state is ProfileLoadingState) {
          return _getLoadingContent();
        } else if (state is ProfileErrorState) {
          return _getErrorContent(context, state.message);
        } else if (state is ProfileLoadedState) {
          return _getLoadedContent(context, state.userBMI, state.userEntity,
              state.usesImperialUnits);
        } else {
          return _getLoadingContent();
        }
      },
    );
  }

  Widget _getLoadingContent() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _getErrorContent(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _profileBloc.add(LoadProfileEvent()),
            child: Text(S.of(context).retryLabel),
          ),
        ],
      ),
    );
  }

  Widget _getLoadedContent(BuildContext context, UserBMIEntity bmiEntity,
      UserEntity user, bool usesImperialUnits) {
    final isCoach = user.role == UserRoleEntity.coach;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        AtlasBrandPanel(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2)),
                child: ProfilePhotoPicker(
                  size: 72,
                  initialImagePath: user.profileImagePath,
                  onImagePicked: (path) {
                    final updatedUser = user.copyWith(profileImagePath: path);
                    _profileBloc.updateUser(updatedUser);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  BlocBuilder<HomeBloc, HomeState>(
                    bloc: locator<HomeBloc>(),
                    builder: (context, state) {
                      final coach = !isCoach && state is HomeLoadedState
                          ? state.coachName?.trim()
                          : null;
                      return Text(
                        coach == null || coach.isEmpty
                            ? user.role.getName(context)
                            : '${user.role.getName(context)} · $coach',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ],
              )),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!isCoach)
          _ProfileTile(
            accent: lunchColor,
            title: Text(
              S.of(context).activityLabel,
            ),
            subtitle: Text(
              user.pal.getName(context),
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.directions_walk_outlined),
            ),
            onTap: () => _showSetPALCategoryDialog(context, user),
          ),
        if (!isCoach)
          _ProfileTile(
            accent: dinnerColor,
            title: Text(
              S.of(context).goalLabel,
            ),
            subtitle: Text(
              user.goal.getName(context),
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.flag_outlined),
            ),
            onTap: () => _showSetGoalDialog(context, user),
          ),
        if (!isCoach)
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth < 260 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(
                    width: width,
                    child: _ProfileTile(
                      compact: true,
                      accent: proteinColor,
                      title: Text(
                        S.of(context).weightLabel,
                      ),
                      subtitle: Text(
                        '${_profileBloc.getDisplayWeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).lbsLabel : S.of(context).kgLabel}',
                      ),
                      leading: const SizedBox(
                        height: double.infinity,
                        child: Icon(Icons.monitor_weight_outlined),
                      ),
                      onTap: () {
                        _showSetWeightDialog(context, user, usesImperialUnits);
                      },
                    )),
                SizedBox(
                    width: width,
                    child: _ProfileTile(
                      compact: true,
                      accent: carbColor,
                      title: Text(
                        S.of(context).heightLabel,
                      ),
                      subtitle: Text(
                        '${_profileBloc.getDisplayHeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).ftLabel : S.of(context).cmLabel}',
                      ),
                      leading: const SizedBox(
                        height: double.infinity,
                        child: Icon(Icons.height_outlined),
                      ),
                      onTap: () {
                        _showSetHeightDialog(context, user, usesImperialUnits);
                      },
                    )),
                SizedBox(
                    width: width,
                    child: _ProfileTile(
                      compact: true,
                      accent: snackColor,
                      title: Text(
                        S.of(context).ageLabel,
                      ),
                      subtitle: Text(
                        S.of(context).yearsLabel(user.age),
                      ),
                      leading: const SizedBox(
                        height: double.infinity,
                        child: Icon(Icons.cake_outlined),
                      ),
                      onTap: () {
                        _showSetBirthdayDialog(context, user);
                      },
                    )),
                SizedBox(
                    width: width,
                    child: _ProfileTile(
                      compact: true,
                      accent: dinnerColor,
                      title: Text(
                        S.of(context).genderLabel,
                      ),
                      subtitle: Text(
                        user.gender.getName(context),
                      ),
                      leading: SizedBox(
                        height: double.infinity,
                        child: Icon(user.gender.getIcon()),
                      ),
                      onTap: () {
                        _showSetGenderDialog(context, user);
                      },
                    )),
              ]),
            );
          }),
        const SizedBox(height: 10),
        if (isCoach)
          _ProfileTile(
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.group_outlined),
            ),
            title: Text(S.of(context).coachStudentsLabel),
            onTap: () async {
              // 1. Effectuez l'opération asynchrone
              final connectivityResult =
                  await locator<Connectivity>().checkConnectivity();

              // 2. APRÈS l'await, vérifiez si le widget est toujours monté
              if (!mounted) return;

              // 3. Maintenant, vous pouvez utiliser le context en toute sécurité
              final isConnected = connectivityResult != ConnectivityResult.none;

              if (isConnected) {
                Navigator.push(
                  // ignore: use_build_context_synchronously
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CoachStudentsPage(),
                  ),
                );
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    // ignore: use_build_context_synchronously
                    content: Text(S.of(context).noInternetConnectionMessage),
                  ),
                );
              }
            },
          ),
        _ProfileTile(
          leading: const SizedBox(
            height: double.infinity,
            child: Icon(Icons.manage_accounts_outlined),
          ),
          title: Text(S.of(context).manageAccountTitle),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const ManageAccountDialog(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _showSetPALCategoryDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedPalCategory = await showDialog<UserPALEntity>(
        context: context,
        builder: (BuildContext context) => const SetPALCategoryDialog());
    if (selectedPalCategory != null) {
      userEntity.pal = selectedPalCategory;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGoalDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGoal = await showDialog<UserWeightGoalEntity>(
        context: context,
        builder: (BuildContext context) => const SetWeightGoalDialog());
    if (selectedGoal != null) {
      userEntity.goal = selectedGoal;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetHeightDialog(BuildContext context, UserEntity userEntity,
      bool usesImperialUnits) async {
    final selectedHeight = await showDialog<double>(
        context: context,
        builder: (context) => SetHeightDialog(
              userHeight: usesImperialUnits
                  ? UnitCalc.cmToFeet(userEntity.heightCM)
                  : userEntity.heightCM,
              usesImperialUnits: usesImperialUnits,
            ));
    if (selectedHeight != null) {
      if (usesImperialUnits) {
        userEntity.heightCM = UnitCalc.feetToCm(selectedHeight);
      } else {
        userEntity.heightCM = selectedHeight;
      }

      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetWeightDialog(BuildContext context, UserEntity userEntity,
      bool usesImperialSystem) async {
    final selectedWeight = await showDialog<double>(
        context: context,
        builder: (context) => SetWeightDialog(
              userWeight: usesImperialSystem
                  ? UnitCalc.kgToLbs(userEntity.weightKG)
                  : userEntity.weightKG,
              usesImperialUnits: usesImperialSystem,
            ));
    if (selectedWeight != null) {
      if (usesImperialSystem) {
        userEntity.weightKG = UnitCalc.lbsToKg(selectedWeight);
      } else {
        userEntity.weightKG = selectedWeight;
      }
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetBirthdayDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedDate = await showDatePicker(
        context: context,
        builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                datePickerTheme: DatePickerThemeData(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  headerBackgroundColor: snackColor.withValues(alpha: 0.12),
                  headerForegroundColor:
                      Theme.of(context).colorScheme.onSurface,
                ),
              ),
              child: child!,
            ),
        initialDate: userEntity.birthday,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (selectedDate != null) {
      userEntity.birthday = selectedDate;
      _profileBloc.updateUser(userEntity);
    }
  }

  Future<void> _showSetGenderDialog(
      BuildContext context, UserEntity userEntity) async {
    final selectedGender = await showDialog<UserGenderEntity>(
        context: context,
        builder: (BuildContext context) => const SetGenderDialog());
    if (selectedGender != null) {
      userEntity.gender = selectedGender;

      _profileBloc.updateUser(userEntity);
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final Widget title;
  final Color? accent;
  final Widget? subtitle;
  final Widget leading;
  final VoidCallback onTap;
  final bool compact;

  const _ProfileTile(
      {this.accent,
      required this.title,
      this.subtitle,
      required this.leading,
      required this.onTap,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tint = accent ?? colors.primary;
    final icon = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12)),
      child:
          IconTheme(data: IconThemeData(color: tint, size: 21), child: leading),
    );
    final label = DefaultTextStyle.merge(
        style: theme.textTheme.bodySmall!.copyWith(
            color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
        child: title);
    final value = subtitle == null
        ? null
        : DefaultTextStyle.merge(
            style: theme.textTheme.titleMedium!.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3),
            child: subtitle!);
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 10),
      child: Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colors.onSurface.withValues(alpha: 0.05))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(height: 18),
                      label,
                      if (value != null) ...[const SizedBox(height: 4), value],
                    ],
                  )
                : Row(children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          if (value != null) ...[
                            label,
                            const SizedBox(height: 4),
                            value
                          ] else
                            DefaultTextStyle.merge(
                                style: theme.textTheme.titleSmall!
                                    .copyWith(fontWeight: FontWeight.w700),
                                child: title),
                        ])),
                  ]),
          ),
        ),
      ),
    );
  }
}
