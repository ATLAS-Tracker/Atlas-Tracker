import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'profile_dialog_widgets.dart';
import 'profile_value_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

class SetWeightDialog extends StatefulWidget {
  static const weightRangeKg = 50.0;

  final double userWeight;

  const SetWeightDialog({super.key, required this.userWeight});

  @override
  State<SetWeightDialog> createState() => _SetWeightDialogState();
}

class _SetWeightDialogState extends State<SetWeightDialog> {
  final _form = GlobalKey<FormState>();
  late double _selectedWeight = widget.userWeight.clamp(0.1, 400);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      title: ProfileDialogTitle(
          title: S.of(context).selectWeightDialogLabel,
          icon: Icons.monitor_weight_outlined,
          color: proteinColor),
      scrollable: true,
      content: Form(
          key: _form,
          child: ProfileValuePicker(
            initialValue: _selectedWeight,
            min: (widget.userWeight - SetWeightDialog.weightRangeKg)
                .clamp(0.1, 400),
            max: (widget.userWeight + SetWeightDialog.weightRangeKg)
                .clamp(0.1, 400),
            divisions: 1000,
            unit: S.of(context).kgLabel,
            color: proteinColor,
            onChanged: (value) => _selectedWeight = value,
          )),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(context, _selectedWeight);
            },
            child: Text(S.of(context).dialogOKLabel)),
      ],
    );
  }
}
