import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/formatters/one_decimal_place_formatter.dart';

class EditableTextWidget extends StatefulWidget {
  final String initialValue;
  final bool disabledEnter;
  final String unit;
  final TextStyle? textStyle;
  final TextStyle? unitStyle;
  final double width;

  const EditableTextWidget({
    super.key,
    required this.initialValue,
    required this.disabledEnter,
    this.unit = 'kg',
    this.textStyle,
    this.unitStyle,
    this.width = 135.0,
  });

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late WeightBloc _weightBloc;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _weightBloc = locator<WeightBloc>();
  }

  @override
  void didUpdateWidget(covariant EditableTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      if (!_isEditing) {
        _textController.text = widget.initialValue;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveAndSwitchToDisplayMode(String selectedWeight) {
    if (!mounted) return;

    String normalizedValue = selectedWeight.replaceAll(',', '.');

    setState(() {
      _isEditing = false;
      _textController.text = selectedWeight;
    });

    if (normalizedValue.isEmpty) {
      return;
    }

    _weightBloc.add(WeightSet(double.parse(normalizedValue)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle effectiveTextStyle =
        widget.textStyle ?? theme.textTheme.headlineMedium ?? const TextStyle();
    final TextStyle effectiveUnitStyle = widget.unitStyle ?? effectiveTextStyle;
    final String weightUnit = " ${widget.unit}";
    final TextPainter unitWidthPainter = TextPainter(
      text: TextSpan(text: weightUnit, style: effectiveUnitStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final TextPainter inputWidthPainter = TextPainter(
      text: TextSpan(text: _textController.text, style: effectiveTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    final double maxInputWidth = (widget.width - unitWidthPainter.width)
        .clamp(48.0, widget.width)
        .toDouble();
    final double inputWidth = inputWidthPainter.width
        .clamp(
          48.0,
          maxInputWidth,
        )
        .toDouble();

    return SizedBox(
      width: widget.width,
      child: _isEditing && !widget.disabledEnter
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: inputWidth,
                    child: TextFormField(
                      controller: _textController,
                      style: effectiveTextStyle,
                      textAlign: TextAlign.end,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      inputFormatters: [
                        OneDecimalPlaceFormatter(
                          maxValue: _weightBloc.maxWeight,
                        ),
                      ],
                      onTapOutside: (event) =>
                          _saveAndSwitchToDisplayMode(_textController.text),
                      onFieldSubmitted: (newValue) {
                        _saveAndSwitchToDisplayMode(newValue);
                      },
                    ),
                  ),
                  Text(weightUnit, style: effectiveUnitStyle),
                ],
              ),
            )
          : Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isEditing = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _focusNode.requestFocus();
                  });
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: _textController.text),
                        TextSpan(text: weightUnit, style: effectiveUnitStyle),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: effectiveTextStyle,
                  ),
                ),
              ),
            ),
    );
  }
}
