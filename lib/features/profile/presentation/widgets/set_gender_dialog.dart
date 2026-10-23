import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'profile_dialog_widgets.dart';

class SetGenderDialog extends StatelessWidget {
  const SetGenderDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.only(top: 12, bottom: 20),
      title: ProfileDialogTitle(
          title: S.of(context).selectGenderDialogLabel,
          icon: Icons.person_outline,
          color: proteinColor),
      children: [
        ProfileDialogOption(
            label: S.of(context).genderMaleLabel,
            color: proteinColor,
            onPressed: () => Navigator.pop(context, UserGenderEntity.male)),
        ProfileDialogOption(
            label: S.of(context).genderFemaleLabel,
            color: snackColor,
            onPressed: () => Navigator.pop(context, UserGenderEntity.female)),
      ],
    );
  }
}
