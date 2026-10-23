import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../fixture/intake_for_recipe_fixtures.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/macro_icon.dart';
import 'package:opennutritracker/core/styles/fonts.dart';

class MockHomeBloc extends Mock implements HomeBloc {}

class MockMealDetailBloc extends Mock implements MealDetailBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf'));
    await fonts.load();
  });
  final day = DateTime(2026, 10, 23);
  final intake = IntakeEntity(
      id: 'lunch-chicken',
      unit: 'g',
      amount: 100,
      type: IntakeTypeEntity.lunch,
      dateTime: day,
      meal: IntakeForRecipeFixtures.chicken.meal!);

  setUp(() {
    locator.registerSingleton<HomeBloc>(MockHomeBloc());
    locator.registerSingleton<MealDetailBloc>(MockMealDetailBloc());
  });
  tearDown(() => locator.reset());

  Widget buildMeal(
      {required List<IntakeEntity> intakes,
      Function(BuildContext, IntakeEntity, bool)? onTapped,
      Route<dynamic>? Function(RouteSettings)? onGenerateRoute,
      DateTime? mealDay,
      double textScale = 1,
      bool journal = false,
      void Function(IntakeEntity)? onDelete,
      Function(bool)? onDrag}) {
    return MaterialApp(
      locale: const Locale('fr'),
      theme: ThemeData(textTheme: appTextTheme),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      onGenerateRoute: onGenerateRoute,
      home: Scaffold(
          body: SingleChildScrollView(
              child: IntakeVerticalList(
        day: mealDay ?? day,
        title: 'Déjeuner',
        listIcon: Icons.restaurant,
        addMealType: AddMealType.lunchType,
        intakeList: intakes,
        usesImperialUnits: false,
        compact: true,
        isCollapsible: journal,
        initiallyExpanded: !journal,
        foodPreviewLimit: journal ? null : 2,
        onCopyMealToDateCallback: journal ? (_, __, ___) async {} : null,
        onDeleteIntakeCallback: (item, _) => onDelete?.call(item),
        onItemTappedCallback: onTapped,
        onItemDragCallback: onDrag,
      ))),
    );
  }

  testWidgets('compact meal keeps food details tappable', (tester) async {
    IntakeEntity? selected;
    await tester.pumpWidget(buildMeal(
        intakes: [intake], onTapped: (_, item, __) => selected = item));
    await tester.pumpAndSettle();
    expect(find.text('100 g'), findsOneWidget);
    await tester.tap(find.text('Chicken Breast'));
    expect(selected, same(intake));
    expect(tester.takeException(), isNull);
  });

  for (final populated in [false, true]) {
    testWidgets(
        'meal header adds food to the correct day and meal (populated=$populated)',
        (tester) async {
      RouteSettings? requested;
      await tester.pumpWidget(buildMeal(
          intakes: populated ? [intake] : [],
          onGenerateRoute: (settings) {
            requested = settings;
            return MaterialPageRoute<void>(builder: (_) => const Scaffold());
          }));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ajouter · Déjeuner'));
      await tester.pumpAndSettle();
      expect(requested?.name, NavigationOptions.addMealRoute);
      final arguments = requested!.arguments as AddMealScreenArguments;
      expect(arguments.mealType, AddMealType.lunchType);
      expect(arguments.day, day);
      expect(tester.takeException(), isNull);
    });
  }
  for (final count in [0, 1, 2, 3, 4]) {
    testWidgets(
        'meal with $count foods shows two then expands with full totals',
        (tester) async {
      final foods =
          List.generate(count, (index) => intake.copyWith(id: 'food-$index'));
      await tester.pumpWidget(buildMeal(intakes: foods));
      await tester.pumpAndSettle();
      expect(find.byType(IntakeCard), findsNWidgets(count > 2 ? 2 : count));
      expect(find.text('${count * 165} kcal'), findsWidgets);
      expect(find.text('${count * 31} g'),
          count == 0 ? findsNWidgets(3) : findsOneWidget);
      expect(find.byType(MacroIcon),
          findsNWidgets(3 + (count > 2 ? 2 : count) * 3));
      final toggle = find.byKey(const ValueKey('toggle-meal-foods'));
      if (count <= 2) {
        expect(toggle, findsNothing);
      } else {
        expect(
            find.text(
                count == 3 ? 'Voir 1 autre aliment' : 'Voir 2 autres aliments'),
            findsOneWidget);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(IntakeCard), findsNWidgets(count));
        expect(find.text('${count * 31} g'),
            count == 0 ? findsNWidgets(3) : findsOneWidget);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.byType(IntakeCard), findsNWidgets(2));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('journal shows every food and keeps meal collapse and copy',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final foods = List.generate(
        4, (index) => intake.copyWith(id: 'food-$index', amount: 1000));
    await tester
        .pumpWidget(buildMeal(intakes: foods, journal: true, textScale: 1.5));
    await tester.pumpAndSettle();
    expect(find.byType(IntakeCard), findsNothing);
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.byType(IntakeCard), findsNWidgets(4));
    expect(find.byKey(const ValueKey('toggle-meal-foods')), findsNothing);
    expect(find.byTooltip(S.current.copyMealLabel), findsOneWidget);
    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pumpAndSettle();
    expect(find.byType(IntakeCard), findsNothing);
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.byType(IntakeCard), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('journal delete-all keeps confirmation and cancels safely',
      (tester) async {
    final deleted = <IntakeEntity>[];
    await tester.pumpWidget(
        buildMeal(intakes: [intake], journal: true, onDelete: deleted.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(S.current.deleteAllLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogCancelLabel));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);
    await tester.tap(find.byTooltip(S.current.deleteAllLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();
    expect(deleted, [intake]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new day resets an expanded meal', (tester) async {
    final foods =
        List.generate(4, (index) => intake.copyWith(id: 'food-$index'));
    await tester.pumpWidget(buildMeal(intakes: foods));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toggle-meal-foods')));
    await tester.pumpAndSettle();
    expect(find.byType(IntakeCard), findsNWidgets(4));
    await tester.pumpWidget(
        buildMeal(intakes: foods, mealDay: day.add(const Duration(days: 1))));
    await tester.pumpAndSettle();
    expect(find.byType(IntakeCard), findsNWidgets(2));
  });

  testWidgets('food macros and actions fit a small screen with larger text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final drags = <bool>[];
    await tester.pumpWidget(
        buildMeal(intakes: [intake], textScale: 1.5, onDrag: drags.add));
    await tester.pumpAndSettle();
    expect(find.text('100 g'), findsOneWidget);
    expect(find.byTooltip(S.current.proteinLabel), findsOneWidget);
    final gesture = await tester
        .startGesture(tester.getCenter(find.text('Chicken Breast')));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(const Offset(10, 900));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(drags, [true, false]);
    expect(tester.takeException(), isNull);
  });
}
