import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'profile_dialog_widgets.dart';

class SetWeightGoalDialog extends StatelessWidget {
  const SetWeightGoalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.only(top: 12, bottom: 20),
      title: ProfileDialogTitle(
          title: S.of(context).chooseWeightGoalLabel,
          icon: Icons.flag_outlined,
          color: dinnerColor),
      children: [
        ProfileDialogOption(
            label: S.of(context).goalLoseWeight,
            icon: Icons.trending_down_rounded,
            color: lunchColor,
            onPressed: () =>
                Navigator.pop(context, UserWeightGoalEntity.loseWeight)),
        ProfileDialogOption(
            label: S.of(context).goalMaintainWeight,
            icon: Icons.trending_flat_rounded,
            color: proteinColor,
            onPressed: () =>
                Navigator.pop(context, UserWeightGoalEntity.maintainWeight)),
        ProfileDialogOption(
            label: S.of(context).goalGainWeight,
            icon: Icons.trending_up_rounded,
            color: breakfastColor,
            onPressed: () =>
                Navigator.pop(context, UserWeightGoalEntity.gainWeight)),
      ],
    );
  }
}
