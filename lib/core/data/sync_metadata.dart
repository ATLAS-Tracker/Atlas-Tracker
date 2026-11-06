import 'dart:convert';
import 'package:hive/hive.dart';

/// Durable deletion versions, kept in the same encrypted, user-scoped store.
class SyncMetadata {
  final Box<String>? box;
  SyncMetadata(this.box);

  Set<String> get journalDays => {
        for (final key in box?.keys ?? <dynamic>[])
          if (key.toString().startsWith('journal_day/'))
            key.toString().substring('journal_day/'.length),
      };

  Future<void> markJournalDays(Iterable<String> days) async {
    await box?.putAll({for (final day in days) 'journal_day/$day': day});
  }

  DateTime? pendingWeight(String day) =>
      DateTime.tryParse(box?.get('weight_pending/$day') ?? '');

  Future<void> markWeightPending(String day, DateTime version) async {
    await box?.put('weight_pending/$day', version.toUtc().toIso8601String());
  }

  Future<void> acknowledgeWeight(String day, DateTime version) async {
    final pending = pendingWeight(day);
    if (pending != null && !pending.isAfter(version)) {
      await box?.delete('weight_pending/$day');
    }
  }

  String _key(String table, String id) => '$table/$id';

  DateTime? deletedAt(String table, String id) {
    final value = box?.get(_key(table, id));
    if (value == null) return null;
    return DateTime.tryParse(
        (jsonDecode(value) as Map)['modified_at'] as String);
  }

  static DateTime nextVersion(DateTime? previous) {
    final clock = DateTime.now().toUtc().millisecondsSinceEpoch;
    final prior = previous?.toUtc().millisecondsSinceEpoch ?? -1;
    return DateTime.fromMillisecondsSinceEpoch(
        clock > prior ? clock : prior + 1,
        isUtc: true);
  }

  DateTime nextLocalVersion(String table, String id, DateTime? previous) {
    final deleted = deletedAt(table, id);
    final latest =
        deleted != null && (previous == null || deleted.isAfter(previous))
            ? deleted
            : previous;
    return nextVersion(latest);
  }

  Future<void> markDeleted(String table, String id,
      {DateTime? previous, DateTime? version}) async {
    final changed = version ?? nextLocalVersion(table, id, previous);
    final existing = deletedAt(table, id);
    if (existing != null && !changed.isAfter(existing)) return;
    await box?.put(
        _key(table, id),
        jsonEncode({
          'table': table,
          'record_id': id,
          'modified_at': changed.toUtc().toIso8601String(),
        }));
  }

  List<Map<String, dynamic>> get deletions => [
        for (final key in box?.keys ?? <dynamic>[])
          if (['user_intakes/', 'user_recipes/', 'user_weight/']
              .any((prefix) => key.toString().startsWith(prefix)))
            Map<String, dynamic>.from(jsonDecode(box!.get(key)!) as Map),
      ];
}
