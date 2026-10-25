import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recipe_search_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/recipe_results_list.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MockRecipeBloc extends Mock implements RecipeSearchBloc {}

void main() {
  for (final showCreateButton in [true, false]) {
    testWidgets(
        'empty recipe search exposes creation only outside ingredient search: $showCreateButton',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final bloc = MockRecipeBloc();
      when(() => bloc.state).thenReturn(
          const RecipeLoadedState(recipes: [], usesImperialUnits: false));
      when(() => bloc.stream)
          .thenAnswer((_) => const Stream<RecipeSearchState>.empty());
      String? requestedRoute;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        onGenerateRoute: (settings) {
          requestedRoute = settings.name;
          return MaterialPageRoute<void>(builder: (_) => const Scaffold());
        },
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RecipeResultsList(
                    day: DateTime(2026, 10, 25),
                    mealType: AddMealType.lunchType,
                    bloc: bloc,
                    showCreateButton: showCreateButton))),
      ));
      await tester.pumpAndSettle();
      final create = find.byKey(const ValueKey('create-recipe'));
      if (showCreateButton) {
        expect(create, findsOneWidget);
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(requestedRoute, NavigationOptions.createMealRoute);
      } else {
        expect(create, findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
