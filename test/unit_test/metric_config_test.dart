import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

// Original on-disk layout, including the retired field 3.
class LegacyConfigAdapter extends TypeAdapter<ConfigDBO> {
  @override
  int get typeId => 13;
  @override
  ConfigDBO read(BinaryReader reader) =>
      throw UnsupportedError('write fixture only');
  @override
  void write(BinaryWriter writer, ConfigDBO config) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(true)
      ..writeByte(1)
      ..write(true)
      ..writeByte(2)
      ..write(false)
      ..writeByte(3)
      ..write(true)
      ..writeByte(4)
      ..write(123.5)
      ..writeByte(5)
      ..write(200.0)
      ..writeByte(6)
      ..write(130.0)
      ..writeByte(7)
      ..write(70.0)
      ..writeByte(8)
      ..write(DateTime.utc(2026, 11, 3))
      ..writeByte(9)
      ..write(false);
  }
}

void main() {
  test(
      'legacy imperial Hive config remains readable without changing the other fields',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('atlas_metric_config_');
    Hive.init(directory.path);
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.registerAdapter(LegacyConfigAdapter(), override: true);
    final legacy = await Hive.openBox<ConfigDBO>('config');
    await legacy.put('config', ConfigDBO.empty());
    await legacy.close();
    Hive.registerAdapter(ConfigDBOAdapter(), override: true);
    final current = await Hive.openBox<ConfigDBO>('config');
    final config = current.get('config')!;
    expect(config.toJson().containsKey('usesImperialUnits'), isFalse);
    expect(config.userKcalAdjustment, 123.5);
    expect(config.userCarbGoal, 200);
    expect(config.userProteinGoal, 130);
    expect(config.userFatGoal, 70);
    expect(config.lastDataUpdate, DateTime.utc(2026, 11, 3));
    expect(config.supabaseSyncEnabled, isFalse);
  });
}
