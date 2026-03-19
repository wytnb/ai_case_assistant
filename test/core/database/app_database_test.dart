import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('AppDatabase and HealthRecordService', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'createHealthRecord uses the same eventTime for createdAt and updatedAt',
      () async {
        final FakeAiExtractService aiExtractService = FakeAiExtractService(
          result: const AiExtractResult(
            symptomSummary: 'summary text',
            notes: 'Keep monitoring for 2 days',
          ),
        );
        final HealthRecordService service = HealthRecordService(
          database: database,
          aiExtractService: aiExtractService,
          attachmentStorage: const HealthRecordAttachmentStorage(),
        );

        final String id = await service.createHealthRecord(rawText: 'raw text');
        final HealthEvent? record = await database.getHealthEventById(id);

        expect(record, isNotNull);
        expect(aiExtractService.lastRawText, 'raw text');
        expect(aiExtractService.lastEventTime, isNotNull);
        expect(record!.createdAt, aiExtractService.lastEventTime);
        expect(record.updatedAt, aiExtractService.lastEventTime);
        expect(record.notes, 'Keep monitoring for 2 days');
      },
    );

    test(
      'createHealthRecord keeps notes empty when AI does not return notes',
      () async {
        final HealthRecordService service = HealthRecordService(
          database: database,
          aiExtractService: FakeAiExtractService(
            result: const AiExtractResult(
              symptomSummary: 'summary text',
              notes: null,
            ),
          ),
          attachmentStorage: const HealthRecordAttachmentStorage(),
        );

        final String id = await service.createHealthRecord(rawText: 'raw text');
        final HealthEvent? record = await database.getHealthEventById(id);

        expect(record, isNotNull);
        expect(record!.notes, isNull);
      },
    );

    test(
      'createHealthRecord rejects rawText longer than 1000 characters without calling AI',
      () async {
        final FakeAiExtractService aiExtractService = FakeAiExtractService(
          result: const AiExtractResult(
            symptomSummary: 'summary text',
            notes: null,
          ),
        );
        final HealthRecordService service = HealthRecordService(
          database: database,
          aiExtractService: aiExtractService,
          attachmentStorage: const HealthRecordAttachmentStorage(),
        );
        final String rawText = List<String>.filled(
          HealthRecordService.rawTextMaxLength + 1,
          'a',
        ).join();

        expect(
          () => service.createHealthRecord(rawText: rawText),
          throwsA(
            isA<AiExtractException>()
                .having(
                  (AiExtractException error) => error.type,
                  'type',
                  AiExtractExceptionType.invalidRequestPayload,
                )
                .having(
                  (AiExtractException error) => error.message,
                  'message',
                  '原始描述不能超过1000字',
                ),
          ),
        );
        expect(aiExtractService.callCount, 0);
      },
    );

    test('orders records by createdAt descending', () async {
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'older',
          sourceType: 'text',
          rawText: const Value<String?>('older'),
          symptomSummary: const Value<String?>('older'),
          notes: const Value<String?>('older'),
          createdAt: DateTime.parse('2026-03-14T09:00:00.000'),
          updatedAt: DateTime.parse('2026-03-14T09:00:00.000'),
        ),
      );
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'newer',
          sourceType: 'text',
          rawText: const Value<String?>('newer'),
          symptomSummary: const Value<String?>('newer'),
          notes: const Value<String?>('newer'),
          createdAt: DateTime.parse('2026-03-15T09:00:00.000'),
          updatedAt: DateTime.parse('2026-03-15T09:00:00.000'),
        ),
      );

      final List<HealthEvent> records = await database.getAllHealthEvents();

      expect(records.map((HealthEvent item) => item.id), <String>[
        'newer',
        'older',
      ]);
    });

    test('filters report source records by createdAt only', () async {
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'included',
          sourceType: 'text',
          rawText: const Value<String?>('included'),
          symptomSummary: const Value<String?>('included'),
          notes: const Value<String?>('included'),
          createdAt: DateTime.parse('2026-03-15T09:00:00.000'),
          updatedAt: DateTime.parse('2026-03-15T09:00:00.000'),
        ),
      );
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'excluded',
          sourceType: 'text',
          rawText: const Value<String?>('excluded'),
          symptomSummary: const Value<String?>('excluded'),
          notes: const Value<String?>('excluded'),
          createdAt: DateTime.parse('2026-03-17T09:00:00.000'),
          updatedAt: DateTime.parse('2026-03-17T09:00:00.000'),
        ),
      );

      final List<HealthEvent> records = await database.getHealthEventsByRange(
        rangeStart: DateTime.parse('2026-03-15T00:00:00.000'),
        rangeEnd: DateTime.parse('2026-03-16T23:59:59.000'),
      );

      expect(records.map((HealthEvent item) => item.id), <String>['included']);
    });
  });

  test(
    'migrates schema 2 eventTime into createdAt and removes legacy columns',
    () async {
      final sqlite.Database legacyDatabase = sqlite.sqlite3.openInMemory();
      final DateTime oldEventTime = DateTime.parse('2026-03-12T07:30:00.000');
      final int oldEventTimeSeconds =
          oldEventTime.millisecondsSinceEpoch ~/ 1000;
      legacyDatabase.execute('''
      CREATE TABLE health_events (
        id TEXT NOT NULL PRIMARY KEY,
        event_time INTEGER NOT NULL,
        source_type TEXT NOT NULL,
        raw_text TEXT,
        symptom_summary TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
      legacyDatabase.execute('''
      CREATE TABLE attachments (
        id TEXT NOT NULL PRIMARY KEY,
        health_event_id TEXT NOT NULL REFERENCES health_events (id),
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
      legacyDatabase.execute('''
      CREATE TABLE reports (
        id TEXT NOT NULL PRIMARY KEY,
        report_type TEXT NOT NULL,
        range_start INTEGER NOT NULL,
        range_end INTEGER NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        advice_json TEXT NOT NULL,
        markdown TEXT NOT NULL,
        generated_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
      legacyDatabase.execute('''
      INSERT INTO health_events (
        id,
        event_time,
        source_type,
        raw_text,
        symptom_summary,
        notes,
        created_at,
        updated_at
      ) VALUES (
        'legacy-2',
        $oldEventTimeSeconds,
        'text',
        'old raw text',
        'old summary',
        'old notes',
        1,
        $oldEventTimeSeconds
      );
    ''');
      legacyDatabase.execute('PRAGMA user_version = 2;');

      final AppDatabase database = AppDatabase(
        NativeDatabase.opened(legacyDatabase, closeUnderlyingOnClose: false),
      );

      final HealthEvent? record = await database.getHealthEventById('legacy-2');
      final List<QueryRow> columns = await _healthEventColumns(database);

      expect(record, isNotNull);
      expect(record!.createdAt, oldEventTime);
      expect(record.updatedAt, oldEventTime);
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        isNot(contains('event_time')),
      );
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        isNot(contains('event_start_time')),
      );
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        isNot(contains('event_end_time')),
      );

      await database.close();
      legacyDatabase.dispose();
    },
  );

  test(
    'migrates schema 3 health_events by dropping start/end columns and keeping createdAt',
    () async {
      final sqlite.Database legacyDatabase = sqlite.sqlite3.openInMemory();
      final DateTime createdAt = DateTime.parse('2026-03-14T07:30:00.000');
      final DateTime updatedAt = DateTime.parse('2026-03-14T08:30:00.000');
      final DateTime eventStartTime = DateTime.parse('2026-03-14T06:30:00.000');
      final DateTime eventEndTime = DateTime.parse('2026-03-14T07:00:00.000');
      legacyDatabase.execute('''
        CREATE TABLE health_events (
          id TEXT NOT NULL PRIMARY KEY,
          event_start_time INTEGER NOT NULL,
          event_end_time INTEGER NOT NULL,
          source_type TEXT NOT NULL,
          raw_text TEXT,
          symptom_summary TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      legacyDatabase.execute('''
        CREATE TABLE attachments (
          id TEXT NOT NULL PRIMARY KEY,
          health_event_id TEXT NOT NULL REFERENCES health_events (id),
          file_path TEXT NOT NULL,
          file_type TEXT NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');
      legacyDatabase.execute('''
        CREATE TABLE reports (
          id TEXT NOT NULL PRIMARY KEY,
          report_type TEXT NOT NULL,
          range_start INTEGER NOT NULL,
          range_end INTEGER NOT NULL,
          title TEXT NOT NULL,
          summary TEXT NOT NULL,
          advice_json TEXT NOT NULL,
          markdown TEXT NOT NULL,
          generated_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');
      legacyDatabase.execute('''
        INSERT INTO health_events (
          id,
          event_start_time,
          event_end_time,
          source_type,
          raw_text,
          symptom_summary,
          notes,
          created_at,
          updated_at
        ) VALUES (
          'legacy-3',
          ${eventStartTime.millisecondsSinceEpoch ~/ 1000},
          ${eventEndTime.millisecondsSinceEpoch ~/ 1000},
          'text',
          'old raw text',
          'old summary',
          'old notes',
          ${createdAt.millisecondsSinceEpoch ~/ 1000},
          ${updatedAt.millisecondsSinceEpoch ~/ 1000}
        );
      ''');
      legacyDatabase.execute('PRAGMA user_version = 3;');

      final AppDatabase database = AppDatabase(
        NativeDatabase.opened(legacyDatabase, closeUnderlyingOnClose: false),
      );

      final HealthEvent? record = await database.getHealthEventById('legacy-3');
      final List<QueryRow> columns = await _healthEventColumns(database);

      expect(record, isNotNull);
      expect(record!.createdAt, createdAt);
      expect(record.updatedAt, updatedAt);
      expect(record.rawText, 'old raw text');
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        isNot(contains('event_start_time')),
      );
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        isNot(contains('event_end_time')),
      );

      await database.close();
      legacyDatabase.dispose();
    },
  );

  test(
    'migrates schema 4 by adding actionAdvice and new intake tables',
    () async {
      final sqlite.Database legacyDatabase = sqlite.sqlite3.openInMemory();
      final DateTime createdAt = DateTime.parse('2026-03-14T07:30:00.000');
      final DateTime updatedAt = DateTime.parse('2026-03-14T08:30:00.000');
      legacyDatabase.execute('''
      CREATE TABLE health_events (
        id TEXT NOT NULL PRIMARY KEY,
        source_type TEXT NOT NULL,
        raw_text TEXT,
        symptom_summary TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
      legacyDatabase.execute('''
      CREATE TABLE attachments (
        id TEXT NOT NULL PRIMARY KEY,
        health_event_id TEXT NOT NULL REFERENCES health_events (id),
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
      legacyDatabase.execute('''
      CREATE TABLE reports (
        id TEXT NOT NULL PRIMARY KEY,
        report_type TEXT NOT NULL,
        range_start INTEGER NOT NULL,
        range_end INTEGER NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        advice_json TEXT NOT NULL,
        markdown TEXT NOT NULL,
        generated_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
      legacyDatabase.execute('''
      INSERT INTO health_events (
        id,
        source_type,
        raw_text,
        symptom_summary,
        notes,
        created_at,
        updated_at
      ) VALUES (
        'legacy-4',
        'text',
        'old raw text',
        'old summary',
        'old notes',
        ${createdAt.millisecondsSinceEpoch ~/ 1000},
        ${updatedAt.millisecondsSinceEpoch ~/ 1000}
      );
    ''');
      legacyDatabase.execute('PRAGMA user_version = 4;');

      final AppDatabase database = AppDatabase(
        NativeDatabase.opened(legacyDatabase, closeUnderlyingOnClose: false),
      );

      final HealthEvent? record = await database.getHealthEventById('legacy-4');
      final List<QueryRow> healthEventColumns = await _tableColumns(
        database,
        'health_events',
      );
      final List<QueryRow> tableRows = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table';")
          .get();

      expect(record, isNotNull);
      expect(record!.actionAdvice, isNull);
      expect(
        healthEventColumns.map((QueryRow row) => row.read<String>('name')),
        contains('action_advice'),
      );
      expect(
        tableRows.map((QueryRow row) => row.read<String>('name')),
        containsAll(<String>[
          'app_settings',
          'intake_sessions',
          'intake_messages',
          'intake_session_attachments',
        ]),
      );

      await database.close();
      legacyDatabase.dispose();
    },
  );
}

Future<List<QueryRow>> _healthEventColumns(AppDatabase database) {
  return database.customSelect("PRAGMA table_info('health_events');").get();
}

Future<List<QueryRow>> _tableColumns(AppDatabase database, String tableName) {
  return database.customSelect("PRAGMA table_info('$tableName');").get();
}

class FakeAiExtractService implements AiExtractService {
  FakeAiExtractService({required this.result});

  final AiExtractResult result;
  int callCount = 0;
  String? lastRawText;
  DateTime? lastEventTime;

  @override
  Future<AiExtractResult> extractFromRawText({
    required String rawText,
    required DateTime eventTime,
  }) async {
    callCount += 1;
    lastRawText = rawText;
    lastEventTime = eventTime;
    return result;
  }
}
