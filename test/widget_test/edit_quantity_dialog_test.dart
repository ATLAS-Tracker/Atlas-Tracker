import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  testWidgets(
      'quantity editing rejects invalid values and accepts French decimals',
      (tester) async {
    EditDialogResult? result;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                  child: const Text('Modifier'),
                  onPressed: () async {
                    result = await showDialog<EditDialogResult>(
                        context: context,
                        builder: (_) => EditDialog(
                            intakeEntity: IntakeEntity(
                                id: 'food',
                                unit: 'g',
                                amount: 150,
                                type: IntakeTypeEntity.lunch,
                                meal: MealEntity.empty(),
                                dateTime: DateTime(2026, 11, 3))));
                  }))),
    ));
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '150');
    for (final text in ['', '0', '-1', 'NaN', 'abc']) {
      await tester.enterText(find.byType(TextFormField), text);
      await tester.tap(find.text(S.current.dialogOKLabel));
      await tester.pumpAndSettle();
      expect(find.byType(EditDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.enterText(find.byType(TextFormField), '150,5');
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();
    expect(result!.amount, 150.5);
  });
}
