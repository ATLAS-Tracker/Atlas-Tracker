import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'profile_dialog_widgets.dart';
import 'profile_value_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetHeightDialog extends StatelessWidget {
  static const _heightRangeCM = 100.0;

  final double userHeight;

  const SetHeightDialog({super.key, required this.userHeight});

  @override
  Widget build(BuildContext context) {
    double selectedHeight = userHeight;
    final form = GlobalKey<FormState>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      title: ProfileDialogTitle(
          title: S.of(context).selectHeightDialogLabel,
          icon: Icons.height_outlined,
          color: carbColor),
      scrollable: true,
      content: Form(
          key: form,
          child: ProfileValuePicker(
            initialValue: userHeight,
            min: (userHeight - _heightRangeCM).clamp(0.1, 300),
            max: (userHeight + _heightRangeCM).clamp(0.1, 300),
            divisions: 400,
            unit: S.of(context).cmLabel,
            color: carbColor,
            onChanged: (value) => selectedHeight = value,
          )),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              Navigator.pop(context, selectedHeight);
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }
}
