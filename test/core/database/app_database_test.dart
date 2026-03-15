import 'package:ai_case_assistant/core/database/app_database.dart';
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
      'createHealthRecord saves extracted event times and createdAt',
      () async {
        final DateTime eventStartTime = DateTime.parse(
          '2026-03-15T08:00:00.000',
        );
        final DateTime eventEndTime = DateTime.parse('2026-03-15T09:30:00.000');
        final HealthRecordService service = HealthRecordService(
          database: database,
          aiExtractService: FakeAiExtractService(
            result: AiExtractResult(
              symptomSummary: 'summary text',
              notes: 'Keep monitoring for 2 days',
              eventStartTime: eventStartTime,
              eventEndTime: eventEndTime,
            ),
          ),
          attachmentStorage: const HealthRecordAttachmentStorage(),
        );
        final DateTime beforeCreate = DateTime.now();

        final String id = await service.createHealthRecord(rawText: 'raw text');
        final DateTime afterCreate = DateTime.now();
        final HealthEvent? record = await database.getHealthEventById(id);

        expect(record, isNotNull);
        expect(record!.eventStartTime, eventStartTime);
        expect(record.eventEndTime, eventEndTime);
        expect(record.notes, 'Keep monitoring for 2 days');
        expect(
          record.createdAt.isBefore(
            beforeCreate.subtract(const Duration(seconds: 1)),
          ),
          isFalse,
        );
        expect(
          record.createdAt.isAfter(afterCreate.add(const Duration(seconds: 1))),
          isFalse,
        );
      },
    );

    test(
      'createHealthRecord keeps notes empty when AI does not return notes',
      () async {
        final DateTime eventStartTime = DateTime.parse(
          '2026-03-15T08:00:00.000',
        );
        final DateTime eventEndTime = DateTime.parse('2026-03-15T09:30:00.000');
        final HealthRecordService service = HealthRecordService(
          database: database,
          aiExtractService: FakeAiExtractService(
            result: AiExtractResult(
              symptomSummary: 'summary text',
              notes: null,
              eventStartTime: eventStartTime,
              eventEndTime: eventEndTime,
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

    test('orders records by eventEndTime descending', () async {
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'older',
          eventStartTime: DateTime.parse('2026-03-14T08:00:00.000'),
          eventEndTime: DateTime.parse('2026-03-14T09:00:00.000'),
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
          eventStartTime: DateTime.parse('2026-03-15T08:00:00.000'),
          eventEndTime: DateTime.parse('2026-03-15T09:00:00.000'),
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

    test('filters report source records by eventEndTime only', () async {
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'included',
          eventStartTime: DateTime.parse('2026-03-15T08:00:00.000'),
          eventEndTime: DateTime.parse('2026-03-15T09:00:00.000'),
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
          eventStartTime: DateTime.parse('2026-03-15T08:00:00.000'),
          eventEndTime: DateTime.parse('2026-03-17T09:00:00.000'),
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
    'migrates legacy eventTime into eventStartTime/eventEndTime and createdAt',
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
        'legacy-1',
        $oldEventTimeSeconds,
        'text',
        'old raw text',
        'old summary',
        'old notes',
        1,
        2
      );
    ''');
      legacyDatabase.execute('PRAGMA user_version = 2;');

      final AppDatabase database = AppDatabase(
        NativeDatabase.opened(legacyDatabase, closeUnderlyingOnClose: false),
      );

      final HealthEvent? record = await database.getHealthEventById('legacy-1');
      final List<QueryRow> columns = await database
          .customSelect("PRAGMA table_info('health_events');")
          .get();

      expect(record, isNotNull);
      expect(record!.eventStartTime, oldEventTime);
      expect(record.eventEndTime, oldEventTime);
      expect(record.createdAt, oldEventTime);
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        containsAll(<String>['event_start_time', 'event_end_time']),
      );
      expect(
        columns.map((QueryRow row) => row.read<String>('name')),
        isNot(contains('event_time')),
      );

      await database.close();
      legacyDatabase.dispose();
    },
  );
}

class FakeAiExtractService implements AiExtractService {
  FakeAiExtractService({required this.result});

  final AiExtractResult result;

  @override
  Future<AiExtractResult> extractFromRawText({required String rawText}) async {
    return result;
  }
}
