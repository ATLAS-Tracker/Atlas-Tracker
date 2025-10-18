import 'package:flutter/material.dart';
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
      children: [
        const SizedBox(height: 32.0),
        Center(
          child: Column(
            children: [
              ProfilePhotoPicker(
                initialImagePath: user.profileImagePath,
                onImagePicked: (path) {
                  final updatedUser = user.copyWith(profileImagePath: path);
                  _profileBloc.updateUser(updatedUser);
                },
              ),
              const SizedBox(height: 16.0),
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        const SizedBox(height: 32.0),
        if (!isCoach)
          ListTile(
            title: Text(
              S.of(context).activityLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              user.pal.getName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.directions_walk_outlined),
            ),
            onTap: () => _showSetPALCategoryDialog(context, user),
          ),
        if (!isCoach)
          ListTile(
            title: Text(
              S.of(context).goalLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              user.goal.getName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.flag_outlined),
            ),
            onTap: () => _showSetGoalDialog(context, user),
          ),
        if (!isCoach)
          ListTile(
            title: Text(
              S.of(context).weightLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${_profileBloc.getDisplayWeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).lbsLabel : S.of(context).kgLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.monitor_weight_outlined),
            ),
            onTap: () {
              _showSetWeightDialog(context, user, usesImperialUnits);
            },
          ),
        if (!isCoach)
          ListTile(
            title: Text(
              S.of(context).heightLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              '${_profileBloc.getDisplayHeight(user, usesImperialUnits)} ${usesImperialUnits ? S.of(context).ftLabel : S.of(context).cmLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.height_outlined),
            ),
            onTap: () {
              _showSetHeightDialog(context, user, usesImperialUnits);
            },
          ),
        if (!isCoach)
          ListTile(
            title: Text(
              S.of(context).ageLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              S.of(context).yearsLabel(user.age),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: const SizedBox(
              height: double.infinity,
              child: Icon(Icons.cake_outlined),
            ),
            onTap: () {
              _showSetBirthdayDialog(context, user);
            },
          ),
        if (!isCoach)
          ListTile(
            title: Text(
              S.of(context).genderLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Text(
              user.gender.getName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            leading: SizedBox(
              height: double.infinity,
              child: Icon(user.gender.getIcon()),
            ),
            onTap: () {
              _showSetGenderDialog(context, user);
            },
          ),
        if (isCoach)
          ListTile(
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
        ListTile(
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
