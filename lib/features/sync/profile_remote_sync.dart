import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase is the source of truth for the profile: non-null remote fields
/// overwrite the local profile. Returns false if the remote row is missing.
Future<bool> syncProfileFromSupabase(SupabaseClient client) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;
  try {
    final row = await client
        .from('users')
        .select(
          'display_name, role, height_cm, weight_kg, gender, goal, birthday, pal',
        )
        .eq('id', userId)
        .maybeSingle();
    if (row == null) {
      Logger('ProfileRemoteSync').warning('No users row for $userId');
      return false;
    }

    final getUser = locator<GetUserUsecase>();
    final local = await getUser.hasUserData()
        ? await getUser.getUserData()
        : UserEntity(
            name: '',
            birthday: DateTime(2000, 1, 1),
            heightCM: 180,
            weightKG: 80,
            gender: UserGenderEntity.male,
            goal: UserWeightGoalEntity.maintainWeight,
            pal: UserPALEntity.active,
            role: UserRoleEntity.student,
          );

    await locator<AddUserUsecase>().addUser(mergeRemoteProfile(local, row));
    return true;
  } catch (e, s) {
    Logger('ProfileRemoteSync').warning('Profile sync failed', e, s);
    return false;
  }
}

/// Writes the fields edited on the profile page back to Supabase, otherwise
/// [syncProfileFromSupabase] reverts them at the next startup.
// ponytail: offline edits are lost at next startup, queue them if that matters.
Future<void> pushProfileToSupabase(
    SupabaseClient client, UserEntity user) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) return;
  try {
    await client.from('users').update(remoteProfileRow(user)).eq('id', userId);
  } catch (e, s) {
    Logger('ProfileRemoteSync').warning('Profile push failed', e, s);
  }
}

/// Inverse of [mergeRemoteProfile] for the editable fields.
Map<String, dynamic> remoteProfileRow(UserEntity user) => {
      'height_cm': user.heightCM,
      'weight_kg': user.weightKG,
      'gender': user.gender.name,
      'goal': user.goal.name,
      'pal':
          user.pal == UserPALEntity.lowActive ? 'lightlyActive' : user.pal.name,
      'birthday': user.birthday.toIso8601String().substring(0, 10),
    };

UserEntity mergeRemoteProfile(UserEntity local, Map<String, dynamic> row) {
  return local.copyWith(
    name: (row['display_name'] as String?)?.trim(),
    role: switch (row['role']) {
      'coach' => UserRoleEntity.coach,
      'student' => UserRoleEntity.student,
      _ => null,
    },
    heightCM: _toDouble(row['height_cm']),
    weightKG: _toDouble(row['weight_kg']),
    gender: switch ((row['gender'] as String?)?.toLowerCase()) {
      'female' => UserGenderEntity.female,
      'male' => UserGenderEntity.male,
      _ => null,
    },
    goal: switch ((row['goal'] as String?)?.toLowerCase()) {
      'loseweight' => UserWeightGoalEntity.loseWeight,
      'gainweight' => UserWeightGoalEntity.gainWeight,
      'maintainweight' => UserWeightGoalEntity.maintainWeight,
      _ => null,
    },
    pal: switch ((row['pal'] as String?)?.toLowerCase()) {
      'sedentary' => UserPALEntity.sedentary,
      'lightlyactive' => UserPALEntity.lowActive,
      'active' => UserPALEntity.active,
      'veryactive' => UserPALEntity.veryActive,
      _ => null,
    },
    birthday: row['birthday'] is String
        ? DateTime.tryParse(row['birthday'] as String)
        : null,
  );
}

double? _toDouble(dynamic v) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
