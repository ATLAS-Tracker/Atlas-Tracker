import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../fixture/intake_for_recipe_fixtures.dart';

class MockUpdate extends Mock implements UpdateIntakeUsecase {}

class MockAdd extends Mock implements AddIntakeUsecase {}

class MockHome extends Mock implements HomeBloc {}

class MockDiary extends Mock implements DiaryBloc {}

class MockDay extends Mock implements CalendarDayBloc {}

void main() {
  tearDown(() => locator.reset());
  testWidgets(
      'editing a journal food waits for one update and never adds a duplicate',
      (tester) async {
    final original = IntakeEntity(
        id: 'original',
        unit: 'g',
        amount: 150,
        type: IntakeTypeEntity.lunch,
        meal: IntakeForRecipeFixtures.chicken.meal!,
        dateTime: DateTime(2026, 11, 1));
    final update = MockUpdate();
    final add = MockAdd();
    final pending = Completer<IntakeEntity?>();
    when(() => update.updateIntake('original', any()))
        .thenAnswer((_) => pending.future);
    locator.registerSingleton<UpdateIntakeUsecase>(update);
    locator.registerSingleton<HomeBloc>(MockHome());
    locator.registerSingleton<DiaryBloc>(MockDiary());
    locator.registerSingleton<CalendarDayBloc>(MockDay());
    final detail = MealDetailBloc(add);
    addTearDown(detail.close);
    final controller = TextEditingController(text: '150');
    addTearDown(controller.dispose);
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
                    child: const Text('Ouvrir'),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                                body: MealDetailBottomSheet(
                                    product: original.meal,
                                    intakeToEdit: original,
                                    day: original.dateTime,
                                    intakeTypeEntity: original.type,
                                    quantityTextController: controller,
                                    mealDetailBloc: detail,
                                    selectedUnit: 'g',
                                    onQuantityOrUnitChanged:
                                        (_, __) {})))))))));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.pump();
    final save = find.byWidgetPredicate((widget) => widget is FilledButton);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextFormField), '150,5');
    await tester.pump();
    await tester.tap(find.text(S.current.saveQuantityLabel));
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    pending.complete(original.copyWith(amount: 150.5));
    await tester.pumpAndSettle();
    final fields = verify(() => update.updateIntake('original', captureAny()))
        .captured
        .single as Map<String, dynamic>;
    expect(fields['amount'], 150.5);
    expect(fields['unit'], 'g');
    verifyZeroInteractions(add);
    expect(find.text('Ouvrir'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
