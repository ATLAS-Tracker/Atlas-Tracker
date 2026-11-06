import 'package:flutter/material.dart';
import "package:flutter_localizations/flutter_localizations.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/create_meal/create_meal_modal.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: CalendarMealTypeSelector(
          mealName: 'Test meal',
          imagePath: null,
        ),
      ),
    );
  }

  testWidgets('save button enabled without portion inputs', (tester) async {
    await tester.pumpWidget(buildWidget());
    expect(find.byType(TextFormField), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
