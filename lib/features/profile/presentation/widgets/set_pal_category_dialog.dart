import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'profile_dialog_widgets.dart';

class SetPALCategoryDialog extends StatelessWidget {
  const SetPALCategoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.only(top: 12, bottom: 20),
      title: ProfileDialogTitle(
          title: S.of(context).selectPalCategoryLabel,
          icon: Icons.directions_walk_outlined,
          color: lunchColor),
      children: [
        ProfileDialogOption(
            label: S.of(context).palSedentaryLabel,
            icon: Icons.chair_outlined,
            color: proteinColor,
            onPressed: () => Navigator.pop(context, UserPALEntity.sedentary)),
        ProfileDialogOption(
            label: S.of(context).palLowLActiveLabel,
            icon: Icons.directions_walk_rounded,
            color: lunchColor,
            onPressed: () => Navigator.pop(context, UserPALEntity.lowActive)),
        ProfileDialogOption(
            label: S.of(context).palActiveLabel,
            icon: Icons.directions_run_rounded,
            color: breakfastColor,
            onPressed: () => Navigator.pop(context, UserPALEntity.active)),
        ProfileDialogOption(
            label: S.of(context).palVeryActiveLabel,
            icon: Icons.fitness_center_rounded,
            color: dinnerColor,
            onPressed: () => Navigator.pop(context, UserPALEntity.veryActive)),
      ],
    );
  }
}
