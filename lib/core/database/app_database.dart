// ignore_for_file: experimental_member_use

import 'dart:io';

import 'package:ai_case_assistant/features/health_record/data/local/tables/attachments.dart';
import 'package:ai_case_assistant/features/health_record/data/local/tables/health_events.dart';
import 'package:ai_case_assistant/features/report/data/local/tables/reports.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: <Type>[HealthEvents, Attachments, Reports])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.createTable(reports);
      }
      if (from < 3) {
        await migrator.alterTable(
          TableMigration(
            healthEvents,
            newColumns: <GeneratedColumn<Object>>[
              healthEvents.eventStartTime,
              healthEvents.eventEndTime,
            ],
            columnTransformer: <GeneratedColumn<Object>, Expression<Object>>{
              healthEvents.eventStartTime: const CustomExpression<DateTime>(
                'event_time',
              ),
              healthEvents.eventEndTime: const CustomExpression<DateTime>(
                'event_time',
              ),
              healthEvents.createdAt: const CustomExpression<DateTime>(
                'event_time',
              ),
            },
          ),
        );
      }
    },
  );

  Future<List<HealthEvent>> getAllHealthEvents() {
    return (select(healthEvents)..orderBy(<OrderingTerm Function(HealthEvents)>[
          (HealthEvents table) => OrderingTerm.desc(table.eventEndTime),
        ]))
        .get();
  }

  Future<HealthEvent?> getHealthEventById(String id) {
    return (select(
      healthEvents,
    )..where((HealthEvents table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<List<HealthEvent>> getHealthEventsByRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return (select(healthEvents)
          ..where(
            (HealthEvents table) =>
                table.eventEndTime.isBiggerOrEqualValue(rangeStart) &
                table.eventEndTime.isSmallerOrEqualValue(rangeEnd),
          )
          ..orderBy(<OrderingTerm Function(HealthEvents)>[
            (HealthEvents table) => OrderingTerm.desc(table.eventEndTime),
          ]))
        .get();
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

  Future<void> insertReport(ReportsCompanion companion) async {
    await into(reports).insert(companion);
  }

  Future<void> updateReportById(String id, ReportsCompanion companion) async {
    await (update(
      reports,
    )..where((Reports table) => table.id.equals(id))).write(companion);
  }

  Future<List<Report>> getAllReports() {
    return (select(reports)..orderBy(<OrderingTerm Function(Reports)>[
          (Reports table) => OrderingTerm.desc(table.generatedAt),
        ]))
        .get();
  }

  Future<List<Report>> getReportsByScope({
    required String reportType,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return (select(reports)
          ..where(
            (Reports table) =>
                table.reportType.equals(reportType) &
                table.rangeStart.equals(rangeStart) &
                table.rangeEnd.equals(rangeEnd),
          )
          ..orderBy(<OrderingTerm Function(Reports)>[
            (Reports table) => OrderingTerm.desc(table.generatedAt),
          ]))
        .get();
  }

  Future<void> deleteReportById(String id) async {
    await (delete(reports)..where((Reports table) => table.id.equals(id))).go();
  }

  Future<Report?> getReportById(String id) {
    return (select(
      reports,
    )..where((Reports table) => table.id.equals(id))).getSingleOrNull();
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
