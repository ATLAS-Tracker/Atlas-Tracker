import 'package:opennutritracker/core/utils/number_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/features/profile/student_macros_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Poppins')
      ..addFont(rootBundle.load('fonts/Poppins-Regular.ttf'))
      ..addFont(rootBundle.load('fonts/Poppins-Bold.ttf'));
    await fonts.load();
  });

  for (final width in [320.0, 412.0]) {
    for (final scale in [1.0, 1.5]) {
      for (final consumed in [0.0, 700.0, 1800.0, 12345.0]) {
        testWidgets(
            'energy ring fits $consumed kcal at width=$width scale=$scale',
            (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            supportedLocales: S.delegate.supportedLocales,
            theme: ThemeData(textTheme: appTextTheme),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            // Same geometry as the day view: half the width, square.
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: StudentEnergyCard(consumed: consumed, goal: 2000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ]),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(formatNumber(consumed)), findsOneWidget);

          await tester.tap(find.byType(StudentEnergyCard));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('${(consumed / 2000 * 100).round()} %'),
              findsOneWidget);
        });
      }
    }
  }
}
