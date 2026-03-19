// ignore_for_file: experimental_member_use

import 'dart:io';

import 'package:ai_case_assistant/features/intake/data/local/tables/intake_messages.dart';
import 'package:ai_case_assistant/features/intake/data/local/tables/intake_session_attachments.dart';
import 'package:ai_case_assistant/features/intake/data/local/tables/intake_sessions.dart';
import 'package:ai_case_assistant/features/health_record/data/local/tables/attachments.dart';
import 'package:ai_case_assistant/features/health_record/data/local/tables/health_events.dart';
import 'package:ai_case_assistant/features/report/data/local/tables/reports.dart';
import 'package:ai_case_assistant/features/settings/data/local/tables/app_settings.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    HealthEvents,
    Attachments,
    Reports,
    AppSettings,
    IntakeSessions,
    IntakeMessages,
    IntakeSessionAttachments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
            columnTransformer: <GeneratedColumn<Object>, Expression<Object>>{
              healthEvents.createdAt: const CustomExpression<DateTime>(
                'event_time',
              ),
            },
          ),
        );
      } else if (from < 5) {
        await migrator.alterTable(TableMigration(healthEvents));
      }
      if (from < 5) {
        await migrator.createTable(appSettings);
        await migrator.createTable(intakeSessions);
        await migrator.createTable(intakeMessages);
        await migrator.createTable(intakeSessionAttachments);
      }
    },
  );

  Future<List<HealthEvent>> getAllHealthEvents() {
    return (select(healthEvents)..orderBy(<OrderingTerm Function(HealthEvents)>[
          (HealthEvents table) => OrderingTerm.desc(table.createdAt),
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
                table.createdAt.isBiggerOrEqualValue(rangeStart) &
                table.createdAt.isSmallerOrEqualValue(rangeEnd),
          )
          ..orderBy(<OrderingTerm Function(HealthEvents)>[
            (HealthEvents table) => OrderingTerm.desc(table.createdAt),
          ]))
        .get();
  }

  Future<void> insertHealthEvent(HealthEventsCompanion companion) async {
    await into(healthEvents).insert(companion);
  }

  Future<void> updateHealthEventById(
    String id,
    HealthEventsCompanion companion,
  ) async {
    await (update(
      healthEvents,
    )..where((HealthEvents table) => table.id.equals(id))).write(companion);
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

  Future<AppSetting?> getAppSettingByKey(String keyValue) {
    return (select(appSettings)
          ..where((AppSettings table) => table.key.equals(keyValue)))
        .getSingleOrNull();
  }

  Future<void> upsertAppSetting(AppSettingsCompanion companion) async {
    await into(appSettings).insertOnConflictUpdate(companion);
  }

  Future<void> insertIntakeSession(IntakeSessionsCompanion companion) async {
    await into(intakeSessions).insert(companion);
  }

  Future<void> updateIntakeSessionById(
    String id,
    IntakeSessionsCompanion companion,
  ) async {
    await (update(
      intakeSessions,
    )..where((IntakeSessions table) => table.id.equals(id))).write(companion);
  }

  Future<IntakeSession?> getIntakeSessionById(String id) {
    return (select(
      intakeSessions,
    )..where((IntakeSessions table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<IntakeSession?> getIntakeSessionByHealthEventId(String healthEventId) {
    return (select(intakeSessions)..where(
          (IntakeSessions table) => table.healthEventId.equals(healthEventId),
        ))
        .getSingleOrNull();
  }

  Future<List<IntakeSession>> getUnfinishedIntakeSessions() {
    return (select(intakeSessions)
          ..where(
            (IntakeSessions table) =>
                table.status.equals('questioning') |
                table.status.equals('awaiting_user_input'),
          )
          ..orderBy(<OrderingTerm Function(IntakeSessions)>[
            (IntakeSessions table) => OrderingTerm.desc(table.updatedAt),
          ]))
        .get();
  }

  Future<List<IntakeSession>> getLinkedIntakeSessions() {
    return (select(
      intakeSessions,
    )..where((IntakeSessions table) => table.healthEventId.isNotNull())).get();
  }

  Future<void> insertIntakeMessage(IntakeMessagesCompanion companion) async {
    await into(intakeMessages).insert(companion);
  }

  Future<void> deleteIntakeMessageById(String id) async {
    await (delete(
      intakeMessages,
    )..where((IntakeMessages table) => table.id.equals(id))).go();
  }

  Future<List<IntakeMessage>> getIntakeMessagesBySessionId(
    String sessionIdValue,
  ) {
    return (select(intakeMessages)
          ..where(
            (IntakeMessages table) => table.sessionId.equals(sessionIdValue),
          )
          ..orderBy(<OrderingTerm Function(IntakeMessages)>[
            (IntakeMessages table) => OrderingTerm.asc(table.seq),
          ]))
        .get();
  }

  Future<void> insertIntakeSessionAttachment(
    IntakeSessionAttachmentsCompanion companion,
  ) async {
    await into(intakeSessionAttachments).insert(companion);
  }

  Future<List<IntakeSessionAttachment>> getIntakeSessionAttachmentsBySessionId(
    String sessionIdValue,
  ) {
    return (select(intakeSessionAttachments)
          ..where(
            (IntakeSessionAttachments table) =>
                table.sessionId.equals(sessionIdValue),
          )
          ..orderBy(<OrderingTerm Function(IntakeSessionAttachments)>[
            (IntakeSessionAttachments table) =>
                OrderingTerm.asc(table.createdAt),
          ]))
        .get();
  }

  Future<void> deleteIntakeSessionAttachmentById(String id) async {
    await (delete(
      intakeSessionAttachments,
    )..where((IntakeSessionAttachments table) => table.id.equals(id))).go();
  }

  Future<void> deleteIntakeSessionById(String id) async {
    await (delete(
      intakeSessions,
    )..where((IntakeSessions table) => table.id.equals(id))).go();
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
