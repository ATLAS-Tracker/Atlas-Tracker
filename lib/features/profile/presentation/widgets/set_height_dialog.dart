import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'profile_dialog_widgets.dart';
import 'profile_value_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetHeightDialog extends StatelessWidget {
  static const _heightRangeCM = 100.0;
  static const _heightRangeFt = 10;

  final double userHeight;
  final bool usesImperialUnits;

  const SetHeightDialog(
      {super.key, required this.userHeight, required this.usesImperialUnits});

  @override
  Widget build(BuildContext context) {
    double selectedHeight = userHeight;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      title: ProfileDialogTitle(
          title: S.of(context).selectHeightDialogLabel,
          icon: Icons.height_outlined,
          color: carbColor),
      scrollable: true,
      content: ProfileValuePicker(
        initialValue: userHeight,
        min: userHeight - (usesImperialUnits ? _heightRangeFt : _heightRangeCM),
        max: userHeight + (usesImperialUnits ? _heightRangeFt : _heightRangeCM),
        divisions: 400,
        unit: usesImperialUnits ? S.of(context).ftLabel : S.of(context).cmLabel,
        color: carbColor,
        onChanged: (value) => selectedHeight = value,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        FilledButton(
            onPressed: () {
              // TODO validate selected height
              Navigator.pop(context, selectedHeight);
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }
}
