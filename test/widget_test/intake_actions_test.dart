import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_actions.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockAddIntake extends Mock implements AddIntakeUsecase {}

void main() {
  final intake = IntakeEntity(
      id: 'original',
      unit: 'g',
      amount: 150,
      type: IntakeTypeEntity.lunch,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 11, 1));
  setUpAll(() => registerFallbackValue(intake));
  tearDown(() => locator.reset());

  testWidgets(
      'one undo restores every deleted food with its original destination',
      (tester) async {
    final add = MockAddIntake();
    final restored = <IntakeEntity>[];
    when(() => add.addIntakes(any())).thenAnswer((call) async {
      restored.addAll(call.positionalArguments.first as List<IntakeEntity>);
    });
    locator.registerSingleton<AddIntakeUsecase>(add);
    final foods = [intake, intake.copyWith(id: 'second', amount: 75)];
    final deleted = <String>[];
    var refreshes = 0;
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
                    child: const Text('Supprimer'),
                    onPressed: () => deleteIntakesWithUndo(
                        context,
                        foods,
                        (food) async => deleted.add(food.id),
                        () => refreshes++))))));
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(deleted, ['original', 'second']);
    expect(restored, isEmpty);
    await tester.tap(find.text(S.current.undoLabel));
    await tester.pumpAndSettle();
    expect(restored.map((food) => food.id), ['original', 'second']);
    expect(restored.map((food) => food.amount), [150, 75]);
    expect(
        restored.every((food) =>
            food.dateTime == intake.dateTime && food.type == intake.type),
        isTrue);
    expect(refreshes, 2);
    verify(() => add.addIntakes(any())).called(1);
    verifyNever(() => add.addIntake(any()));
  });

  testWidgets('opening and dismissing actions never deletes the food',
      (tester) async {
    var deletes = 0;
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
                    child: const Text('Actions'),
                    onPressed: () => showIntakeActions(context, intake,
                            edit: () {}, delete: () async {
                          deletes++;
                        }, refresh: () {}))))));
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    for (final label in [
      'Modifier',
      'Copier',
      'Déplacer',
      S.current.dialogDeleteLabel
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(deletes, 0);
  });
}
