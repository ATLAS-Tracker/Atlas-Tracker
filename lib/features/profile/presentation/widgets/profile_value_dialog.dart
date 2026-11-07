import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/color_macro.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'profile_dialog_widgets.dart';
import 'profile_value_picker.dart';

class ProfileValueDialog extends StatefulWidget {
  final double value;
  final bool _height;

  const ProfileValueDialog.height({super.key, required this.value})
      : _height = true;
  const ProfileValueDialog.weight({super.key, required this.value})
      : _height = false;

  double get _maximum => _height ? 300 : 400;
  double get _range => _height ? 100 : 50;

  @override
  State<ProfileValueDialog> createState() => _ProfileValueDialogState();
}

class _ProfileValueDialogState extends State<ProfileValueDialog> {
  final _form = GlobalKey<FormState>();
  late double _selected = widget.value.clamp(0.1, widget._maximum);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final color = widget._height ? carbColor : proteinColor;
    return AlertDialog(
      title: ProfileDialogTitle(
          title: widget._height
              ? s.selectHeightDialogLabel
              : s.selectWeightDialogLabel,
          icon: widget._height
              ? Icons.height_outlined
              : Icons.monitor_weight_outlined,
          color: color),
      scrollable: true,
      content: Form(
          key: _form,
          child: ProfileValuePicker(
              initialValue: _selected,
              min: (widget.value - widget._range).clamp(0.1, widget._maximum),
              max: (widget.value + widget._range).clamp(0.1, widget._maximum),
              divisions: widget._height ? 400 : 1000,
              unit: widget._height ? s.cmLabel : s.kgLabel,
              color: color,
              onChanged: (value) => _selected = value)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.dialogCancelLabel)),
        FilledButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(context, _selected);
            },
            child: Text(s.dialogOKLabel)),
      ],
    );
  }
}
