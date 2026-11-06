import 'dart:io';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
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
import 'package:opennutritracker/features/edit_meal/domain/create_custom_food.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockGetConfigUsecase extends Mock implements GetConfigUsecase {}

class MockMealDetailBloc extends Mock implements MealDetailBloc {}

class MockRecipeRepository extends Mock implements RecipeRepository {}

void main() {
  late Directory photoDir;
  setUpAll(() async {
    registerFallbackValue(MealEntity.empty());
    photoDir = await Directory.systemTemp.createTemp('atlas-custom-photo-');
    await File('assets/icon/app_icon.png')
        .copy('${photoDir.path}/selected.png');
    await File('assets/icon/app_icon.png').copy('${photoDir.path}/old.png');
  });
  tearDownAll(() async {
    await photoDir.delete(recursive: true);
  });
  setUp(() {
    final recipes = MockRecipeRepository();
    when(() => recipes.saveFood(any())).thenAnswer((_) async {});
    locator.registerSingleton<RecipeRepository>(recipes);
  });
  tearDown(() async {
    await locator.reset();
  });

  for (final mode in [
    'portion',
    'g',
    'ml',
    'photo',
    'save-error',
    'photo-error'
  ]) {
    testWidgets('custom food $mode keeps reference and navigation context',
        (tester) async {
      final perPortion = mode == 'portion' || mode == 'photo';
      if (mode == 'photo' || mode == 'photo-error') {
        PathHelper.overrideDirectory = photoDir;
        addTearDown(() => PathHelper.overrideDirectory = null);
        const channel = MethodChannel('plugins.flutter.io/image_picker');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                channel,
                (call) async => call.method == 'pickImage'
                    ? '${photoDir.path}/${mode == 'photo-error' ? 'missing' : 'selected'}.png'
                    : null);
        addTearDown(() => TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null));
      }
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
                      day,
                      mode == 'photo'
                          ? MealEntity.empty().copyWith(
                              mainImageUrl: 'old.png',
                              thumbnailImageUrl: 'old.png')
                          : MealEntity.empty(),
                      IntakeTypeEntity.lunch)),
              builder: (_) => const EditMealScreen());
        },
      ));
      await tester.pumpAndSettle();
      if (mode == 'photo' || mode == 'photo-error') {
        await tester.tap(find.byKey(const ValueKey('custom-food-photo')));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.text(S.current.customFoodChangePhoto), findsOneWidget);
      }
      if (mode == 'portion') {
        final save = find.byKey(const ValueKey('save-custom-food'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(find.text(S.current.customFoodNameError), findsOneWidget);
        await tester.ensureVisible(find.byType(TextFormField).first);
      }
      if (!perPortion) {
        await tester.tap(find.text(S.current.customFoodQuantityMode));
        await tester.pumpAndSettle();
        if (mode == 'ml') {
          await tester.tap(find.text('100 ml'));
          await tester.pumpAndSettle();
        }
      }
      final fields = find.byType(TextFormField);
      final values = perPortion
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
      if (mode == 'save-error') {
        when(() => locator<RecipeRepository>().saveFood(any()))
            .thenThrow(StateError('storage unavailable'));
      }
      await tester.tap(find.byKey(const ValueKey('save-custom-food')));
      if (mode == 'photo' || mode == 'photo-error') {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
      }
      await tester.pumpAndSettle();
      if (mode == 'save-error' || mode == 'photo-error') {
        expect(result, isNull);
        expect(
            find.text(mode == 'photo-error'
                ? S.current.customFoodPhotoError
                : S.current.intakeSaveError),
            findsOneWidget);
        expect(
            tester
                .widget<FilledButton>(
                    find.byKey(const ValueKey('save-custom-food')))
                .onPressed,
            isNotNull);
        return;
      }
      expect(result, isNotNull);
      expect(result!.day, day);
      expect(result!.intakeTypeEntity, IntakeTypeEntity.lunch);
      expect(result!.mealEntity.isPortionBased, perPortion);
      expect(result!.mealEntity.nutriments.energyPerUnit,
          perPortion ? 250.5 : 2.505);
      if (perPortion) {
        expect(result!.mealEntity.servingSize, '6 nuggets');
      } else {
        expect(result!.mealEntity.mealUnit, mode);
      }
      if (mode == 'photo' || mode == 'photo-error') {
        final path = result!.mealEntity.mainImageUrl!;
        expect(path, startsWith('food_photo_'));
        expect(result!.mealEntity.thumbnailImageUrl, path);
        expect(
            await tester
                .runAsync(() => File('${photoDir.path}/$path').exists()),
            isTrue);
        expect(
            await tester
                .runAsync(() => File('${photoDir.path}/old.png').exists()),
            isTrue);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'weightless portion detail displays its values and only offers portions',
      (tester) async {
    final meal = createCustomFood(
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
            product: meal, servingQuantity: 1, servingUnit: 'serving'),
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
