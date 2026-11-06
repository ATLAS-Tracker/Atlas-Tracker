import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/generated/l10n.dart';

enum _IntakeAction { edit, copy, move, delete }

Future<void> deleteIntakesWithUndo(
    BuildContext context,
    List<IntakeEntity> intakes,
    Future<void> Function(IntakeEntity) delete,
    VoidCallback refresh) async {
  final snapshot = List<IntakeEntity>.of(intakes);
  for (final intake in snapshot) {
    await delete(intake);
  }
  refresh();
  if (!context.mounted) return;
  showUndo(context, () async {
    await locator<AddIntakeUsecase>().addIntakes(snapshot);
    refresh();
  });
}

void showUndo(BuildContext context, Future<void> Function() restore) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(S.of(context).itemDeletedSnackbar),
    duration: const Duration(seconds: 8),
    action: SnackBarAction(
        label: S.of(context).undoLabel,
        onPressed: () async {
          try {
            await restore();
          } catch (_) {
            if (context.mounted) {
              messenger.showSnackBar(
                  SnackBar(content: Text(S.of(context).restoreFailedLabel)));
            }
          }
        }),
  ));
}

Future<void> showIntakeActions(
  BuildContext context,
  IntakeEntity intake, {
  required VoidCallback edit,
  required Future<void> Function() delete,
  required VoidCallback refresh,
}) async {
  final s = S.of(context);
  final action = await showModalBottomSheet<_IntakeAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final entry in [
              (_IntakeAction.edit, Icons.edit_outlined, s.editLabel),
              (_IntakeAction.copy, Icons.copy_outlined, s.copyIntakeLabel),
              (
                _IntakeAction.move,
                Icons.drive_file_move_outline,
                s.moveIntakeLabel
              ),
              (_IntakeAction.delete, Icons.delete_outline, s.dialogDeleteLabel),
            ])
              ListTile(
                  leading: Icon(entry.$2,
                      color: entry.$1 == _IntakeAction.delete
                          ? Theme.of(context).colorScheme.error
                          : null),
                  title: Text(entry.$3),
                  onTap: () => Navigator.pop(context, entry.$1)),
          ])));
  if (!context.mounted || action == null) return;
  if (action == _IntakeAction.edit) {
    edit();
    return;
  }
  if (action == _IntakeAction.delete) {
    await delete();
    return;
  }
  final destination = await selectIntakeDestination(context,
      day: intake.dateTime, type: intake.type);
  if (destination == null) return;
  if (action == _IntakeAction.copy) {
    await locator<AddIntakeUsecase>().addIntake(intake.copyWith(
        id: IdGenerator.getUniqueID(),
        dateTime: destination.$1,
        type: destination.$2,
        updatedAt: DateTime.now().toUtc()));
  } else {
    await locator<UpdateIntakeUsecase>().updateIntake(intake.id, {
      'dateTime': destination.$1,
      'type': destination.$2,
    });
  }
  refresh();
}

Future<(DateTime, IntakeTypeEntity)?> selectIntakeDestination(
        BuildContext context,
        {required DateTime day,
        required IntakeTypeEntity type}) =>
    showDialog<(DateTime, IntakeTypeEntity)>(
        context: context,
        builder: (_) => _IntakeDestination(day: day, type: type));

class _IntakeDestination extends StatefulWidget {
  final DateTime day;
  final IntakeTypeEntity type;
  const _IntakeDestination({required this.day, required this.type});
  @override
  State<_IntakeDestination> createState() => _IntakeDestinationState();
}

class _IntakeDestinationState extends State<_IntakeDestination> {
  late DateTime day = DateUtils.dateOnly(widget.day);
  late IntakeTypeEntity type = widget.type;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final labels = [
      s.breakfastLabel,
      s.lunchLabel,
      s.dinnerLabel,
      s.snackLabel
    ];
    return AlertDialog(
        scrollable: true,
        title: Text(s.copyMealTargetDateLabel),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label:
                  Text(MaterialLocalizations.of(context).formatMediumDate(day)),
              onPressed: () async {
                final selected = await showDatePicker(
                    context: context,
                    initialDate: day,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200));
                if (selected != null && mounted) setState(() => day = selected);
              }),
          DropdownButtonFormField<IntakeTypeEntity>(
              initialValue: type,
              items: [
                for (final meal in IntakeTypeEntity.values)
                  DropdownMenuItem(value: meal, child: Text(labels[meal.index]))
              ],
              onChanged: (value) => setState(() => type = value ?? type)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.dialogCancelLabel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, (day, type)),
              child: Text(s.dialogOKLabel)),
        ]);
  }
}
