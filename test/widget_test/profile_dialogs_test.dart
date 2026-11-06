import 'package:opennutritracker/features/profile/presentation/widgets/profile_value_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_dialog_widgets.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_gender_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_goal_dialog.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_pal_category_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  final menus = [
    (const SetGenderDialog(), UserGenderEntity.values),
    (const SetWeightGoalDialog(), UserWeightGoalEntity.values),
    (const SetPALCategoryDialog(), UserPALEntity.values),
  ];
  for (final menu in menus) {
    testWidgets('${menu.$1.runtimeType} preserves every option result',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Object? selected;
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
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                      onPressed: () async {
                        selected = await showDialog<Object>(
                            context: context, builder: (_) => menu.$1);
                      },
                      child: const Text('open'),
                    ))),
      ));
      for (var index = 0; index < menu.$2.length; index++) {
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final option = find.byType(ProfileDialogOption).at(index);
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pumpAndSettle();
        expect(selected, menu.$2[index]);
        expect(tester.takeException(), isNull);
      }
    });
  }
  for (final imperial in [false, true]) {
    for (final weight in [false, true]) {
      testWidgets(
          'numeric profile menu saves selected value, weight=$weight imperial=$imperial',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        double? saved;
        late StateSetter rebuildDialog;
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
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        onPressed: () async {
                          saved = await showDialog<double>(
                              context: context,
                              builder: (_) =>
                                  StatefulBuilder(builder: (_, setState) {
                                    rebuildDialog = setState;
                                    return weight
                                        ? ProfileValueDialog.weight(
                                            value: imperial ? 170 : 78)
                                        : ProfileValueDialog.height(
                                            value: imperial ? 6 : 180);
                                  }));
                        },
                        child: const Text('open'),
                      ))),
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Slider), const Offset(30, 0));
        await tester.pumpAndSettle();
        final chosen = tester.widget<Slider>(find.byType(Slider)).value;
        // A dependency change rebuilds the dialog after editing.
        rebuildDialog(() {});
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(find.byType(Slider)).value, chosen);
        expect(saved, isNull);
        await tester.tap(find.text(S.current.dialogOKLabel));
        await tester.pumpAndSettle();
        expect(saved, chosen);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(S.current.dialogCancelLabel));
        await tester.pumpAndSettle();
        expect(saved, isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final entry in [
    (const ProfileValueDialog.height(value: 350), 300.0),
    (const ProfileValueDialog.weight(value: 450), 400.0),
    (const ProfileValueDialog.height(value: 0), 0.1),
    (const ProfileValueDialog.weight(value: 0), 0.1),
  ]) {
    testWidgets('numeric profile clamps ${entry.$1}', (tester) async {
      double? saved;
      await tester.pumpWidget(MaterialApp(
        supportedLocales: S.delegate.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () async {
                  saved = await showDialog<double>(
                      context: context, builder: (_) => entry.$1);
                },
                child: const Text('open'))),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<Slider>(find.byType(Slider)).value, entry.$2);
      await tester.tap(find.text(S.current.dialogOKLabel));
      await tester.pumpAndSettle();
      expect(saved, entry.$2);
    });
  }
}
