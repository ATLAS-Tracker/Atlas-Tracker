import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

void main() {
  test(
      'crash reports require a new explicit choice and retain it across restarts',
      () async {
    final directory = await Directory.systemTemp.createTemp('atlas_consent_');
    Hive.init(directory.path);
    Hive.registerAdapter(ConfigDBOAdapter());
    final hive = HiveDBProvider();
    hive.configBox = await Hive.openBox<ConfigDBO>('config');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final source = ConfigDataSource(hive);
    expect(await source.getHasAcceptedAnonymousData(), isFalse);
    await source.addConfig(ConfigDBO(true, true, true));
    expect(await source.getHasAcceptedAnonymousData(), isFalse,
        reason: 'legacy automatic defaults do not prove consent');
    await source.setConfigAcceptedAnonymousData(true);
    expect(await source.getHasAcceptedAnonymousData(), isTrue);
    await hive.configBox.close();
    hive.configBox = await Hive.openBox<ConfigDBO>('config');
    expect(await source.getHasAcceptedAnonymousData(), isTrue);
    await source.setConfigAcceptedAnonymousData(false);
    expect(await source.getHasAcceptedAnonymousData(), isFalse);
  });
}
