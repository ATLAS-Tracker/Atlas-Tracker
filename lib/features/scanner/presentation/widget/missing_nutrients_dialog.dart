import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

class MissingNutrientsDialog extends StatelessWidget {
  const MissingNutrientsDialog({
    super.key,
    required this.day,
    required this.mealEntity,
    required this.intakeTypeEntity,
    required this.usesImperialUnits,
  });

  final DateTime day;
  final MealEntity mealEntity;
  final IntakeTypeEntity intakeTypeEntity;
  final bool usesImperialUnits;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).missingNutrientsDialogTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        S.of(context).missingNutrientsDialogContent,
        style: TextStyle(
          fontSize: 17,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .popUntil(ModalRoute.withName(NavigationOptions.mainRoute));
          },
          child: Text(
            S.of(context).skipLabel,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(
              NavigationOptions.editMealRoute,
              arguments: EditMealScreenArguments(
                day,
                mealEntity,
                intakeTypeEntity,
                usesImperialUnits,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              S.of(context).enterManuallyLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
