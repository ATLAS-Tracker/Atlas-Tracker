import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _pendingProfile = 'profile_pending';
const _requestTimeout = Duration(seconds: 8);

bool _owns(SupabaseClient client, HiveDBProvider hive, String owner) =>
    client.auth.currentUser?.id == owner && hive.activeUserId == owner;

Future<void> _sendPending(SupabaseClient client, HiveDBProvider hive,
    String owner, String pending) async {
  await client
      .from('users')
      .update(Map<String, dynamic>.from(jsonDecode(pending) as Map))
      .eq('id', owner)
      .timeout(_requestTimeout);
  if (_owns(client, hive, owner) &&
      hive.syncMetadataBox?.get(_pendingProfile) == pending) {
    await hive.syncMetadataBox?.delete(_pendingProfile);
  }
}

/// Retry local edits before reading the server so offline changes survive.
Future<bool> syncProfileFromSupabase(SupabaseClient client) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) return false;
  final hive = locator<HiveDBProvider>();
  if (!_owns(client, hive, userId)) return false;
  try {
    final pending = hive.syncMetadataBox?.get(_pendingProfile);
    if (pending != null) await _sendPending(client, hive, userId, pending);
    if (!_owns(client, hive, userId)) return false;
    final row = await client
        .from('users')
        .select(
          'display_name, role, height_cm, weight_kg, gender, goal, birthday, pal',
        )
        .eq('id', userId)
        .maybeSingle()
        .timeout(_requestTimeout);
    if (!_owns(client, hive, userId)) return false;
    if (hive.syncMetadataBox?.get(_pendingProfile) != null) return true;
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

    if (!_owns(client, hive, userId) ||
        hive.syncMetadataBox?.get(_pendingProfile) != null) {
      return false;
    }
    await locator<AddUserUsecase>().addUser(mergeRemoteProfile(local, row));
    return true;
  } catch (e, s) {
    Logger('ProfileRemoteSync').warning('Profile sync failed', e, s);
    return false;
  }
}

/// Writes the fields edited on the profile page back to Supabase, otherwise
/// [syncProfileFromSupabase] reverts them at the next startup.
Future<void> pushProfileToSupabase(
    SupabaseClient client, UserEntity user) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) return;
  final hive = locator<HiveDBProvider>();
  if (!_owns(client, hive, userId)) return;
  if (!user.heightCM.isFinite ||
      user.heightCM <= 0 ||
      user.heightCM > 300 ||
      !user.weightKG.isFinite ||
      user.weightKG <= 0 ||
      user.weightKG > 400 ||
      user.birthday.isAfter(DateTime.now()) ||
      user.birthday.year < 1900) {
    throw ArgumentError('Invalid profile values');
  }
  final pending = jsonEncode(remoteProfileRow(user));
  await hive.syncMetadataBox?.put(_pendingProfile, pending);
  try {
    if (_owns(client, hive, userId)) {
      await _sendPending(client, hive, userId, pending);
    }
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
