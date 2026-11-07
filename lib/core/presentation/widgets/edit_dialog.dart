import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/core/utils/number_format.dart';

enum EditDialogAction { updateAmount, deleteItem, viewProduct }

class EditDialogResult {
  final EditDialogAction action;
  final double? amount;

  const EditDialogResult({required this.action, this.amount});
}

class EditDialog extends StatefulWidget {
  final IntakeEntity intakeEntity;

  const EditDialog({super.key, required this.intakeEntity});

  @override
  State<StatefulWidget> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController amountEditingController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    amountEditingController =
        TextEditingController(text: formatQuantity(widget.intakeEntity.amount));
  }

  @override
  void dispose() {
    amountEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(S.of(context).editItemDialogTitle),
      content: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: amountEditingController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (text) => parsePositiveQuantity(text) == null
                  ? S.of(context).positiveQuantityError
                  : null,
              decoration: InputDecoration(
                  labelText: S.of(context).quantityLabel,
                  suffixText:
                      widget.intakeEntity.unit.toLowerCase() == 'serving'
                          ? S.of(context).servingLabel
                          : MealEntity.metricUnit(widget.intakeEntity.unit)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceTint,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  side: BorderSide.none,
                ),
                onPressed: () {
                  Navigator.of(context).pop(
                    const EditDialogResult(
                        action: EditDialogAction.viewProduct),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(S.of(context).viewProductSheetButtonLabel),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () {
                  Navigator.of(context).pop(
                    const EditDialogResult(action: EditDialogAction.deleteItem),
                  );
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(S.of(context).dialogDeleteLabel),
              ),
            ),
          ])),
      actions: [
        TextButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              final newAmount =
                  parsePositiveQuantity(amountEditingController.text)!;
              Navigator.of(context).pop(EditDialogResult(
                  action: EditDialogAction.updateAmount, amount: newAmount));
            },
            child: Text(S.of(context).dialogOKLabel)),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel))
      ],
    );
  }
}
