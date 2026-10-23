import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'profile_dialog_widgets.dart';
import 'profile_value_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetWeightDialog extends StatelessWidget {
  static const weightRangeKg = 50.0;
  static const weightRangeLbs = 100.0;

  final double userWeight;
  final bool usesImperialUnits;

  const SetWeightDialog(
      {super.key, required this.userWeight, required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    double selectedWeight = userWeight;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      title: ProfileDialogTitle(
          title: S.of(context).selectWeightDialogLabel,
          icon: Icons.monitor_weight_outlined,
          color: proteinColor),
      scrollable: true,
      content: ProfileValuePicker(
        initialValue: userWeight,
        min: userWeight - (usesImperialUnits ? weightRangeLbs : weightRangeKg),
        max: userWeight + (usesImperialUnits ? weightRangeLbs : weightRangeKg),
        divisions: 1000,
        unit:
            usesImperialUnits ? S.of(context).lbsLabel : S.of(context).kgLabel,
        color: proteinColor,
        onChanged: (value) => selectedWeight = value,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        FilledButton(
            onPressed: () {
              // TODO validate selected weight
              Navigator.pop(context, selectedWeight);
            },
            child: Text(S.of(context).dialogOKLabel)),
      ],
    );
  }
}
