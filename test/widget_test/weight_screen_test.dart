import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_weight_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/delete_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/editable_text_widget.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_weight/presentation/add_weight_screen.dart';
import 'package:opennutritracker/features/add_weight/presentation/bloc/weight_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../fixture/user_entity_fixtures.dart';

class MockAddWeight extends Mock implements AddWeightUsecase {}

class MockGetWeight extends Mock implements GetWeightUsecase {}

class MockGetUser extends Mock implements GetUserUsecase {}

class MockGetConfig extends Mock implements GetConfigUsecase {}

class MockHome extends Mock implements HomeBloc {}

class MockCalendar extends Mock implements CalendarDayBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final day = DateTime(2026, 10, 22);
  late MockAddWeight addWeight;
  late MockGetWeight getWeight;
  late MockHome home;
  late MockCalendar calendar;
  late WeightBloc weightBloc;
  late List<UserWeightEntity> savedWeights;

  UserWeightEntity entry(String id, double value, DateTime date) =>
      UserWeightEntity(id: id, weight: value, date: date);

  setUpAll(() async {
    registerFallbackValue(day);
    registerFallbackValue(entry('fallback', 54.4, day));
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf'));
    await fonts.load();
  });

  setUp(() async {
    addWeight = MockAddWeight();
    getWeight = MockGetWeight();
    home = MockHome();
    calendar = MockCalendar();
    final user = MockGetUser();
    final config = MockGetConfig();
    savedWeights = [
      entry('today', 54.4, day),
      entry('previous', 54.2, day.subtract(const Duration(days: 1)))
    ];
    when(() => getWeight.getWeightsFromPastDays(any(), any(),
            includeToday: any(named: 'includeToday')))
        .thenAnswer((_) async => savedWeights);
    when(() => getWeight.getAverageWeight(any(), any()))
        .thenAnswer((_) async => 54.1);
    when(() => getWeight.getLastUserWeight(any()))
        .thenAnswer((_) async => 54.4);
    when(() => user.getUserData()).thenAnswer((_) async =>
        UserEntityFixtures.elderlyLowActiveMaleWantingToGainWeight);
    when(() => config.getConfig())
        .thenAnswer((_) async => const ConfigEntity(true, true, false));
    when(() => addWeight.addUserWeight(any())).thenAnswer((_) async {});
    when(() => calendar.deleteUserWeightItem(any())).thenAnswer((_) async {
      savedWeights = [];
    });
    locator.registerSingleton<GetWeightUsecase>(getWeight);
    locator.registerSingleton<AddWeightUsecase>(addWeight);
    locator.registerSingleton<GetUserUsecase>(user);
    locator.registerSingleton<GetConfigUsecase>(config);
    locator.registerSingleton<HomeBloc>(home);
    locator.registerSingleton<CalendarDayBloc>(calendar);
  });

  tearDown(() async {
    await weightBloc.close();
    await locator.reset();
  });

  Widget screen({bool readOnly = false, bool dark = false, double scale = 1}) =>
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        theme: ThemeData(
            colorScheme: dark ? darkColorScheme : lightColorScheme,
            textTheme: appTextTheme),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: RouteSettings(
                arguments:
                    AddWeightScreenArguments(day: day, isReadOnly: readOnly)),
            builder: (_) => const AddWeightScreen()),
      );
  Future<void> pumpScreen(WidgetTester tester,
      {bool readOnly = false,
      bool dark = false,
      double scale = 1,
      double width = 412}) async {
    weightBloc = WeightBloc();
    locator.registerSingleton<WeightBloc>(weightBloc);
    await tester.binding.setSurfaceSize(Size(width, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(screen(readOnly: readOnly, dark: dark, scale: scale));
    await tester.pumpAndSettle();
  }

  final saveButton = find.byKey(const ValueKey('save-weight'));
  final saved = find.byKey(const ValueKey('weight-saved'));
  final delete = find.byKey(const ValueKey('delete-weight'));

  testWidgets(
      'save waits for persistence, blocks duplicate taps and confirms the saved value',
      (tester) async {
    final pending = Completer<void>();
    when(() => addWeight.addUserWeight(any()))
        .thenAnswer((_) => pending.future);
    await pumpScreen(tester);
    final date = tester
        .widget<Text>(find.byKey(const ValueKey('weight-entry-date')))
        .data!;
    expect(date, contains('22 octobre 2026'));
    expect(saved, findsNothing);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    expect(
        tester
            .widget<EditableTextWidget>(find.byType(EditableTextWidget))
            .disabledEnter,
        isTrue);
    expect(saved, findsNothing);
    await tester.tap(saveButton);
    pending.complete();
    await tester.pumpAndSettle();
    expect(saved, findsOneWidget);
    final value = verify(() => addWeight.addUserWeight(captureAny()))
        .captured
        .single as UserWeightEntity;
    expect(value.weight, 54.4);
    expect(value.date, day);
    await tester.ensureVisible(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(saved, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed saves show an error, allow retry and never show success',
      (tester) async {
    when(() => addWeight.addUserWeight(any()))
        .thenThrow(StateError('test write failure'));
    await pumpScreen(tester);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text(S.current.weightSaveError), findsOneWidget);
    expect(saved, findsNothing);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    verifyNever(() => home.add(const LoadItemsEvent()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving while editing persists the entered comma-decimal value',
      (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byType(EditableTextWidget));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '54,8');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    final value = verify(() => addWeight.addUserWeight(captureAny()))
        .captured
        .single as UserWeightEntity;
    expect(value.weight, 54.8);
    expect(saved, findsOneWidget);
  });

  testWidgets('read-only mode disables editing, saving and deletion',
      (tester) async {
    await pumpScreen(tester, readOnly: true);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    expect(
        tester
            .widget<EditableTextWidget>(find.byType(EditableTextWidget))
            .disabledEnter,
        isTrue);
    await tester.scrollUntilVisible(delete, 200,
        scrollable: find.byType(Scrollable).first);
    expect(tester.widget<TextButton>(delete).onPressed, isNull);
  });

  testWidgets(
      'the compact delete action keeps its confirmation and clears saved feedback',
      (tester) async {
    await pumpScreen(tester);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(saved, findsOneWidget);
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.byType(DeleteDialog), findsOneWidget);
    await tester.tap(find.text(S.current.dialogCancelLabel));
    await tester.pumpAndSettle();
    verifyNever(() => calendar.deleteUserWeightItem(any()));
    expect(saved, findsOneWidget);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();
    verify(() => calendar.deleteUserWeightItem(day)).called(1);
    expect(saved, findsNothing);
    expect(delete, findsNothing);
  });

  testWidgets(
      'chart average uses recorded weights rather than interpolated days',
      (tester) async {
    savedWeights = [
      entry('a', 52, day),
      entry('b', 50, day.subtract(const Duration(days: 1))),
      entry('c', 60, day.subtract(const Duration(days: 6)))
    ];
    await pumpScreen(tester);
    expect(
        find.text(S.current.weightPeriodAverage('54,0', 'kg')), findsOneWidget);
    final chart =
        tester.widget<SfCartesianChart>(find.byType(SfCartesianChart));
    expect((chart.primaryYAxis as NumericAxis).plotBands.single.start, 54);
    expect(find.text(S.current.weightMeasurementsLabel), findsOneWidget);
  });

  testWidgets('no measurements shows an honest empty state without a mean line',
      (tester) async {
    savedWeights = [];
    await pumpScreen(tester);
    expect(find.text(S.current.weightNoMeasurementsLabel), findsOneWidget);
    expect(find.byType(SfCartesianChart), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'weight page fits a narrow screen and enlarged text, dark=$dark',
        (tester) async {
      await pumpScreen(tester, dark: dark, scale: 1.3, width: 320);
      expect(tester.takeException(), isNull);
    });
  }
}
