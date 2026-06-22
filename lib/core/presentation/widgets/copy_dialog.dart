import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CopyDialog extends StatefulWidget {
  const CopyDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return CopyDialogState();
  }
}

class CopyDialogState extends State<CopyDialog> {
  AddMealType _selectedValue = AddMealType.breakfastType;
  AddMealType get selectedMealType => _selectedValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colorScheme.primary.withValues(
                  alpha:
                      colorScheme.brightness == Brightness.dark ? 0.24 : 0.12,
                ),
                colorScheme.surfaceContainerHighest,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.content_copy_rounded,
              color: colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).copyDialogTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: DropdownButtonFormField<AddMealType>(
        initialValue: _selectedValue,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          filled: true,
          fillColor: Color.alphaBlend(
            colorScheme.primary.withValues(
              alpha: colorScheme.brightness == Brightness.dark ? 0.12 : 0.06,
            ),
            colorScheme.surfaceContainerHighest,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide:
                BorderSide(color: colorScheme.primary.withValues(alpha: 0.55)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dropdownColor: colorScheme.surfaceContainerHighest,
        onChanged: (AddMealType? addMealType) {
          if (addMealType != null) {
            setState(() {
              _selectedValue = addMealType;
            });
          }
        },
        items: AddMealType.values.map((AddMealType addMealType) {
          return DropdownMenuItem(
            value: addMealType,
            child: Text(addMealType.getTypeName(context)),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(_selectedValue);
          },
          icon: const Icon(Icons.today_rounded, size: 18),
          label: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
