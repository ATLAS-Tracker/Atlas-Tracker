import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/path_helper.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/profile_photo_picker.dart';

void main() {
  testWidgets('missing avatar after reinstall shows a usable photo placeholder',
      (tester) async {
    final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('atlas_missing_avatar_')))!;
    PathHelper.overrideDirectory = directory;
    addTearDown(() async {
      PathHelper.overrideDirectory = null;
      await tester.runAsync(() => directory.delete(recursive: true));
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ProfilePhotoPicker(
                initialImagePath: 'missing.jpg', onImagePicked: (_) {}))));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
