import 'dart:io';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/data/local/intake_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:ai_case_assistant/features/settings/data/settings_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsRepository', () {
    late AppDatabase database;
    late SettingsRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = SettingsRepository(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    test('returns false when follow_up_mode_enabled is missing', () async {
      expect(await repository.getFollowUpModeEnabled(), false);
    });

    test('persists follow_up_mode_enabled as a typed bool setting', () async {
      await repository.setFollowUpModeEnabled(true);

      final AppSetting? stored = await database.getAppSettingByKey(
        SettingsRepository.followUpModeEnabledKey,
      );

      expect(stored, isNotNull);
      expect(stored!.valueType, 'bool');
      expect(stored.boolValue, true);
      expect(stored.intValue, isNull);
      expect(await repository.getFollowUpModeEnabled(), true);
    });
  });

  group('IntakeService', () {
    late AppDatabase database;
    late FakeAiIntakeService aiIntakeService;
    late TestIntakeAttachmentStorage intakeAttachmentStorage;
    late TestHealthRecordAttachmentStorage healthRecordAttachmentStorage;
    late IntakeService service;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      aiIntakeService = FakeAiIntakeService();
      intakeAttachmentStorage = TestIntakeAttachmentStorage();
      healthRecordAttachmentStorage = TestHealthRecordAttachmentStorage();
      service = IntakeService(
        database: database,
        aiIntakeService: aiIntakeService,
        intakeAttachmentStorage: intakeAttachmentStorage,
        healthRecordAttachmentStorage: healthRecordAttachmentStorage,
      );
    });

    tearDown(() async {
      await database.close();
      await intakeAttachmentStorage.dispose();
      await healthRecordAttachmentStorage.dispose();
    });

    test(
      'needs_followup persists session and messages without creating a health event',
      () async {
        aiIntakeService.enqueue(
          const IntakeResponse(
            status: IntakeResponseStatus.needsFollowup,
            question: '有没有发烧？',
            draft: IntakeDraft(
              mergedRawText: '喉咙痛两天',
              symptomSummary: '喉咙痛',
              notes: '',
              actionAdvice: '继续观察体温',
            ),
          ),
        );

        final IntakeSubmissionResult result = await service.startIntake(
          rawText: '喉咙痛两天',
          followUpModeEnabled: true,
        );

        final IntakeSession? session = await service.getSessionById(
          result.sessionId,
        );
        final List<IntakeMessage> messages = await service
            .getMessagesBySessionId(result.sessionId);
        final List<HealthEvent> records = await database.getAllHealthEvents();

        expect(result.isFinal, false);
        expect(session, isNotNull);
        expect(session!.status, 'awaiting_user_input');
        expect(session.latestQuestion, '有没有发烧？');
        expect(messages.map((IntakeMessage item) => item.role), <String>[
          'user',
          'assistant',
        ]);
        expect(records, isEmpty);
      },
    );

    test(
      'direct final creates session, record, and promotes staged attachments',
      () async {
        final File sourceFile = await _createTempFile('image-content');
        aiIntakeService.enqueue(
          const IntakeResponse(
            status: IntakeResponseStatus.finalResult,
            question: null,
            draft: IntakeDraft(
              mergedRawText: '合并后的描述',
              symptomSummary: '症状摘要',
              notes: '',
              actionAdvice: '观察补水',
            ),
          ),
        );

        final IntakeSubmissionResult result = await service.startIntake(
          rawText: '初始描述',
          followUpModeEnabled: false,
          attachmentSourcePaths: <String>[sourceFile.path],
        );

        final IntakeSession? session = await service.getSessionById(
          result.sessionId,
        );
        final HealthEvent? record = await database.getHealthEventById(
          result.healthEventId!,
        );
        final List<Attachment> attachments = await database
            .getAttachmentsByHealthEventId(result.healthEventId!);
        final List<IntakeSessionAttachment> staged = await database
            .getIntakeSessionAttachmentsBySessionId(result.sessionId);

        expect(result.isFinal, true);
        expect(session!.status, 'finalized');
        expect(session.healthEventId, result.healthEventId);
        expect(record, isNotNull);
        expect(record!.rawText, '合并后的描述');
        expect(record.symptomSummary, '症状摘要');
        expect(record.notes, '');
        expect(record.actionAdvice, '观察补水');
        expect(attachments, hasLength(1));
        expect(File(attachments.single.filePath).existsSync(), isTrue);
        expect(staged, isEmpty);
      },
    );

    test(
      'force finalize writes the original record id back and marks session finalized_by_force',
      () async {
        aiIntakeService
          ..enqueue(
            const IntakeResponse(
              status: IntakeResponseStatus.needsFollowup,
              question: '有没有发烧？',
              draft: IntakeDraft(
                mergedRawText: '喉咙痛两天',
                symptomSummary: '喉咙痛',
                notes: '',
                actionAdvice: '',
              ),
            ),
          )
          ..enqueue(
            const IntakeResponse(
              status: IntakeResponseStatus.finalResult,
              question: null,
              draft: IntakeDraft(
                mergedRawText: '喉咙痛三天，已补充无发烧',
                symptomSummary: '喉咙痛',
                notes: '',
                actionAdvice: '继续观察',
              ),
            ),
          );

        final IntakeSubmissionResult first = await service.startIntake(
          rawText: '喉咙痛两天',
          followUpModeEnabled: true,
        );
        final IntakeSubmissionResult finalResult = await service.forceFinalize(
          first.sessionId,
        );

        final IntakeSession? session = await service.getSessionById(
          first.sessionId,
        );
        final HealthEvent? record = await database.getHealthEventById(
          finalResult.healthEventId!,
        );

        expect(session, isNotNull);
        expect(session!.status, 'finalized_by_force');
        expect(session.healthEventId, finalResult.healthEventId);
        expect(record!.actionAdvice, '继续观察');
      },
    );

    test(
      'resumeQuestioning completes an interrupted round and keeps the same session',
      () async {
        final DateTime now = DateTime.parse('2026-03-19T10:00:00.000');
        await database.insertIntakeSession(
          IntakeSessionsCompanion.insert(
            id: 'session-1',
            healthEventId: const Value<String?>.absent(),
            eventTime: now,
            followUpModeSnapshot: true,
            status: 'questioning',
            initialRawText: '初始描述',
            mergedRawText: const Value<String?>('旧合并描述'),
            latestQuestion: const Value<String?>('上一轮问题'),
            draftSymptomSummary: const Value<String?>('旧摘要'),
            draftNotes: const Value<String?>(''),
            draftActionAdvice: const Value<String?>(''),
            createdAt: now,
            updatedAt: now,
          ),
        );
        await database.insertIntakeMessage(
          IntakeMessagesCompanion.insert(
            id: 'm1',
            sessionId: 'session-1',
            seq: 1,
            role: 'user',
            content: '初始描述',
            createdAt: now,
          ),
        );

        aiIntakeService.enqueue(
          const IntakeResponse(
            status: IntakeResponseStatus.needsFollowup,
            question: '补充一下持续时间？',
            draft: IntakeDraft(
              mergedRawText: '新合并描述',
              symptomSummary: '新摘要',
              notes: '',
              actionAdvice: '',
            ),
          ),
        );

        final IntakeSubmissionResult result = await service.resumeQuestioning(
          'session-1',
        );
        final IntakeSession? session = await service.getSessionById(
          'session-1',
        );
        final List<IntakeMessage> messages = await service
            .getMessagesBySessionId('session-1');

        expect(result.isFinal, false);
        expect(session!.status, 'awaiting_user_input');
        expect(session.latestQuestion, '补充一下持续时间？');
        expect(messages, hasLength(2));
      },
    );

    test(
      'reopening a finalized session updates the original health event instead of creating a duplicate',
      () async {
        aiIntakeService
          ..enqueue(
            const IntakeResponse(
              status: IntakeResponseStatus.finalResult,
              question: null,
              draft: IntakeDraft(
                mergedRawText: '第一版描述',
                symptomSummary: '第一版摘要',
                notes: '',
                actionAdvice: '',
              ),
            ),
          )
          ..enqueue(
            const IntakeResponse(
              status: IntakeResponseStatus.finalResult,
              question: null,
              draft: IntakeDraft(
                mergedRawText: '更新后的描述',
                symptomSummary: '更新后的摘要',
                notes: '',
                actionAdvice: '继续休息',
              ),
            ),
          );

        final IntakeSubmissionResult first = await service.startIntake(
          rawText: '第一版',
          followUpModeEnabled: false,
        );
        final DateTime firstCreatedAt = (await database.getHealthEventById(
          first.healthEventId!,
        ))!.createdAt;

        await service.submitUserReply(
          sessionId: first.sessionId,
          content: '我补充了新的情况',
        );

        final List<HealthEvent> records = await database.getAllHealthEvents();
        final HealthEvent updatedRecord = records.single;
        final IntakeSession? session = await service.getSessionById(
          first.sessionId,
        );

        expect(records, hasLength(1));
        expect(updatedRecord.id, first.healthEventId);
        expect(updatedRecord.createdAt, firstCreatedAt);
        expect(updatedRecord.rawText, '更新后的描述');
        expect(updatedRecord.symptomSummary, '更新后的摘要');
        expect(updatedRecord.actionAdvice, '继续休息');
        expect(session!.healthEventId, first.healthEventId);
      },
    );
  });
}

Future<File> _createTempFile(String content) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'intake-test-source',
  );
  final File file = File('${directory.path}/source.txt');
  await file.writeAsString(content);
  return file;
}

class FakeAiIntakeService implements AiIntakeService {
  final List<IntakeResponse> _queuedResponses = <IntakeResponse>[];
  final List<RecordedIntakeRequest> recordedRequests =
      <RecordedIntakeRequest>[];

  void enqueue(IntakeResponse response) {
    _queuedResponses.add(response);
  }

  @override
  Future<IntakeResponse> submitIntake({
    required bool followUpMode,
    required bool forceFinalize,
    required DateTime eventTime,
    required List<IntakeRequestMessage> messages,
  }) async {
    recordedRequests.add(
      RecordedIntakeRequest(
        followUpMode: followUpMode,
        forceFinalize: forceFinalize,
        eventTime: eventTime,
        messages: messages,
      ),
    );
    if (_queuedResponses.isEmpty) {
      throw StateError('No queued intake response');
    }
    return _queuedResponses.removeAt(0);
  }
}

class RecordedIntakeRequest {
  const RecordedIntakeRequest({
    required this.followUpMode,
    required this.forceFinalize,
    required this.eventTime,
    required this.messages,
  });

  final bool followUpMode;
  final bool forceFinalize;
  final DateTime eventTime;
  final List<IntakeRequestMessage> messages;
}

class TestIntakeAttachmentStorage extends IntakeAttachmentStorage {
  TestIntakeAttachmentStorage()
    : _root = Directory.systemTemp.createTempSync('intake-stage');

  final Directory _root;

  @override
  Future<String> saveImageAttachment({
    required String sessionId,
    required String attachmentId,
    required String sourceFilePath,
  }) async {
    final Directory target = Directory('${_root.path}/$sessionId');
    await target.create(recursive: true);
    final File destination = File('${target.path}/$attachmentId.tmp');
    await File(sourceFilePath).copy(destination.path);
    return destination.path;
  }

  Future<void> dispose() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }
}

class TestHealthRecordAttachmentStorage extends HealthRecordAttachmentStorage {
  TestHealthRecordAttachmentStorage()
    : _root = Directory.systemTemp.createTempSync('health-record-stage');

  final Directory _root;

  @override
  Future<String> saveImageAttachment({
    required String healthEventId,
    required String attachmentId,
    required String sourceFilePath,
  }) async {
    final Directory target = Directory('${_root.path}/$healthEventId');
    await target.create(recursive: true);
    final File destination = File('${target.path}/$attachmentId.final');
    await File(sourceFilePath).copy(destination.path);
    return destination.path;
  }

  Future<void> dispose() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }
}
