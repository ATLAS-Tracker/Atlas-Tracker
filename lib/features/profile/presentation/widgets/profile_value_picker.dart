import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileValuePicker extends StatefulWidget {
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;

  const ProfileValuePicker(
      {super.key,
      required this.initialValue,
      required this.min,
      required this.max,
      required this.divisions,
      required this.unit,
      required this.color,
      required this.onChanged});

  @override
  State<ProfileValuePicker> createState() => _ProfileValuePickerState();
}

class _ProfileValuePickerState extends State<ProfileValuePicker> {
  late double _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final format =
        NumberFormat('0.##', Localizations.localeOf(context).toLanguageTag());
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${format.format(_value)} ${widget.unit}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 20),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            activeColor: widget.color,
            label: '${format.format(_value)} ${widget.unit}',
            onChanged: (value) {
              setState(() => _value = value);
              widget.onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
