import 'dart:io';

import 'package:ai_case_assistant/features/health_record/data/local/tables/attachments.dart';
import 'package:ai_case_assistant/features/health_record/data/local/tables/health_events.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[HealthEvents, Attachments])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<HealthEvent>> getAllHealthEvents() {
    return (select(healthEvents)..orderBy(<OrderingTerm Function(HealthEvents)>[
          (HealthEvents table) => OrderingTerm.desc(table.eventTime),
        ]))
        .get();
  }

  Future<HealthEvent?> getHealthEventById(String id) {
    return (select(
      healthEvents,
    )..where((HealthEvents table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertHealthEvent(HealthEventsCompanion companion) async {
    await into(healthEvents).insert(companion);
  }

  Future<void> insertAttachment(AttachmentsCompanion companion) async {
    await into(attachments).insert(companion);
  }

  Future<List<Attachment>> getAttachmentsByHealthEventId(String healthEventId) {
    return (select(attachments)
          ..where(
            (Attachments table) => table.healthEventId.equals(healthEventId),
          )
          ..orderBy(<OrderingTerm Function(Attachments)>[
            (Attachments table) => OrderingTerm.asc(table.createdAt),
          ]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory databaseDirectory =
        await getApplicationDocumentsDirectory();
    final File file = File(
      path.join(databaseDirectory.path, 'app_database.sqlite'),
    );

    return NativeDatabase.createInBackground(file);
  });
}
