import 'package:flutter/material.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockGetConfigUsecase extends Mock implements GetConfigUsecase {}

class MockMealDetailBloc extends Mock implements MealDetailBloc {}

void main() {
  late EditMealBloc bloc;
  setUp(() {
    bloc = EditMealBloc(MockGetConfigUsecase());
    locator.registerSingleton<EditMealBloc>(bloc);
  });
  tearDown(() async {
    await bloc.close();
    await locator.reset();
  });

  for (final mode in ['portion', 'g', 'ml']) {
    testWidgets('custom food $mode keeps reference and navigation context',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      MealDetailScreenArguments? result;
      final day = DateTime(2026, 10, 24);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        theme: ThemeData(colorScheme: darkColorScheme),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        onGenerateRoute: (settings) {
          if (settings.name == NavigationOptions.mealDetailRoute) {
            result = settings.arguments as MealDetailScreenArguments;
            return MaterialPageRoute<void>(builder: (_) => const Scaffold());
          }
          return MaterialPageRoute<void>(
              settings: RouteSettings(
                  arguments: EditMealScreenArguments(
                      day, MealEntity.empty(), IntakeTypeEntity.lunch, false)),
              builder: (_) => const EditMealScreen());
        },
      ));
      await tester.pumpAndSettle();
      if (mode == 'portion') {
        final save = find.byKey(const ValueKey('save-custom-food'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(find.text(S.current.customFoodNameError), findsOneWidget);
        await tester.ensureVisible(find.byType(TextFormField).first);
      }
      if (mode != 'portion') {
        await tester.tap(find.text(S.current.customFoodQuantityMode));
        await tester.pumpAndSettle();
        if (mode == 'ml') {
          await tester.tap(find.text('100 ml'));
          await tester.pumpAndSettle();
        }
      }
      final fields = find.byType(TextFormField);
      final values = mode == 'portion'
          ? ['Nuggets', '6 nuggets', '250,5', '20', '12', '15']
          : ['Nuggets', '250,5', '20', '12', '15'];
      for (var index = 0; index < values.length; index++) {
        await tester.ensureVisible(fields.at(index));
        await tester.enterText(fields.at(index), values[index]);
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester
          .ensureVisible(find.byKey(const ValueKey('save-custom-food')));
      await tester.tap(find.byKey(const ValueKey('save-custom-food')));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.day, day);
      expect(result!.intakeTypeEntity, IntakeTypeEntity.lunch);
      expect(result!.mealEntity.isPortionBased, mode == 'portion');
      expect(result!.mealEntity.nutriments.energyPerUnit,
          mode == 'portion' ? 250.5 : 2.505);
      if (mode == 'portion') {
        expect(result!.mealEntity.servingSize, '6 nuggets');
      } else {
        expect(result!.mealEntity.mealUnit, mode);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'weightless portion detail displays its values and only offers portions',
      (tester) async {
    final meal = bloc.createCustomFood(
        original: MealEntity.empty(),
        name: 'Nuggets',
        brands: '',
        perPortion: true,
        unit: 'g',
        portionName: '6 nuggets',
        kcal: 250,
        carbs: 20,
        fat: 12,
        protein: 15);
    final quantity = TextEditingController(text: '1');
    addTearDown(quantity.dispose);
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
          body: SingleChildScrollView(
              child: Column(children: [
        MealDetailNutrimentsTable(
            product: meal,
            usesImperialUnits: false,
            servingQuantity: 1,
            servingUnit: 'serving'),
        MealDetailBottomSheet(
            product: meal,
            day: DateTime(2026, 10, 24),
            intakeTypeEntity: IntakeTypeEntity.lunch,
            quantityTextController: quantity,
            mealDetailBloc: MockMealDetailBloc(),
            selectedUnit: UnitDropdownItem.serving.toString(),
            onQuantityOrUnitChanged: (_, __) {}),
      ]))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('250 kcal'), findsOneWidget);
    expect(find.textContaining('6 nuggets'), findsWidgets);
    final dropdown = tester
        .widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
    expect(dropdown.items!.map((item) => item.value),
        [UnitDropdownItem.serving.toString()]);
    expect(tester.takeException(), isNull);
  });
}
