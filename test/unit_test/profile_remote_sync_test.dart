import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_role_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/sync/profile_remote_sync.dart';

void main() {
  final local = UserEntity(
    name: 'Local',
    birthday: DateTime(2000, 1, 1),
    heightCM: 180,
    weightKG: 80,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.veryActive,
    role: UserRoleEntity.student,
  );

  test('remote fields win, null remote fields keep local values', () {
    final merged = mergeRemoteProfile(local, {
      'display_name': 'Virginia',
      'role': 'coach',
      'height_cm': '165.00',
      'weight_kg': 65,
      'gender': 'female',
      'goal': 'loseWeight',
      'birthday': '1999-04-24',
      'pal': null,
    });

    expect(merged.name, 'Virginia');
    expect(merged.role, UserRoleEntity.coach);
    expect(merged.heightCM, 165);
    expect(merged.weightKG, 65);
    expect(merged.gender, UserGenderEntity.female);
    expect(merged.goal, UserWeightGoalEntity.loseWeight);
    expect(merged.birthday, DateTime(1999, 4, 24));
    expect(merged.pal, UserPALEntity.veryActive);
  });

  test('pushed row reads back as the same profile', () {
    for (final pal in UserPALEntity.values) {
      final edited = local.copyWith(
          goal: UserWeightGoalEntity.loseWeight,
          gender: UserGenderEntity.female,
          pal: pal,
          weightKG: 72.5,
          birthday: DateTime(1999, 4, 24));
      final back = mergeRemoteProfile(local, remoteProfileRow(edited));
      expect(back.goal, edited.goal);
      expect(back.gender, edited.gender);
      expect(back.pal, edited.pal);
      expect(back.weightKG, edited.weightKG);
      expect(back.heightCM, edited.heightCM);
      expect(back.birthday, edited.birthday);
    }
  });
}
