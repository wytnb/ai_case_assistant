import 'dart:async';
import 'dart:developer' as developer;

import 'package:ai_case_assistant/core/constants/health_record_limits.dart';
import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:ai_case_assistant/features/intake/data/local/intake_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/ai_intake_service_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final Provider<IntakeAttachmentStorage> intakeAttachmentStorageProvider =
    Provider<IntakeAttachmentStorage>((Ref ref) {
      return const IntakeAttachmentStorage();
    });

final Provider<IntakeService> intakeServiceProvider = Provider<IntakeService>((
  Ref ref,
) {
  return IntakeService(
    database: ref.watch(appDatabaseProvider),
    aiIntakeService: ref.watch(aiIntakeServiceProvider),
    intakeAttachmentStorage: ref.watch(intakeAttachmentStorageProvider),
    healthRecordAttachmentStorage: ref.watch(
      healthRecordAttachmentStorageProvider,
    ),
  );
});

final FutureProvider<List<IntakeSession>> unfinishedIntakeSessionsProvider =
    FutureProvider<List<IntakeSession>>((Ref ref) {
      final DateTimeRange? filter = ref.watch(recordEventTimeFilterProvider);
      return ref.watch(intakeServiceProvider).getUnfinishedSessions(
        start: filter?.start,
        end: filter?.end,
      );
    });

final FutureProvider<Map<String, IntakeSession>> linkedIntakeSessionsProvider =
    FutureProvider<Map<String, IntakeSession>>((Ref ref) {
      return ref
          .watch(intakeServiceProvider)
          .getLinkedSessionsByHealthEventId();
    });

final FutureProviderFamily<IntakeSession?, String> intakeSessionProvider =
    FutureProvider.family<IntakeSession?, String>((Ref ref, String sessionId) {
      return ref.watch(intakeServiceProvider).getSessionById(sessionId);
    });

final FutureProviderFamily<List<IntakeMessage>, String> intakeMessagesProvider =
    FutureProvider.family<List<IntakeMessage>, String>((
      Ref ref,
      String sessionId,
    ) {
      return ref.watch(intakeServiceProvider).getMessagesBySessionId(sessionId);
    });

final AutoDisposeAsyncNotifierProvider<IntakeActionController, void>
intakeActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<IntakeActionController, void>(
      IntakeActionController.new,
    );

final AutoDisposeAsyncNotifierProvider<DeleteDraftSessionController, void>
deleteDraftSessionControllerProvider =
    AutoDisposeAsyncNotifierProvider<DeleteDraftSessionController, void>(
      DeleteDraftSessionController.new,
    );

class IntakeSubmissionResult {
  const IntakeSubmissionResult({
    required this.sessionId,
    required this.isFinal,
    this.healthEventId,
  });

  final String sessionId;
  final bool isFinal;
  final String? healthEventId;
}

class IntakeService {
  IntakeService({
    required AppDatabase database,
    required AiIntakeService aiIntakeService,
    required IntakeAttachmentStorage intakeAttachmentStorage,
    required HealthRecordAttachmentStorage healthRecordAttachmentStorage,
  }) : _database = database,
       _aiIntakeService = aiIntakeService,
       _intakeAttachmentStorage = intakeAttachmentStorage,
       _healthRecordAttachmentStorage = healthRecordAttachmentStorage;

  final AppDatabase _database;
  final AiIntakeService _aiIntakeService;
  final IntakeAttachmentStorage _intakeAttachmentStorage;
  final HealthRecordAttachmentStorage _healthRecordAttachmentStorage;
  static const Uuid _uuid = Uuid();

  Future<List<IntakeSession>> getUnfinishedSessions({
    DateTime? start,
    DateTime? end,
  }) {
    return _database.getUnfinishedIntakeSessions(start: start, end: end);
  }

  Future<Map<String, IntakeSession>> getLinkedSessionsByHealthEventId() async {
    final List<IntakeSession> sessions = await _database
        .getLinkedIntakeSessions();
    return <String, IntakeSession>{
      for (final IntakeSession session in sessions)
        if (session.healthEventId != null) session.healthEventId!: session,
    };
  }

  Future<IntakeSession?> getSessionById(String sessionId) {
    return _database.getIntakeSessionById(sessionId);
  }

  Future<List<IntakeMessage>> getMessagesBySessionId(String sessionId) {
    return _database.getIntakeMessagesBySessionId(sessionId);
  }

  Future<void> hardDeleteDraftSession(String sessionId) async {
    final IntakeSession session = await _requireSession(sessionId);
    final bool isDraft =
        session.healthEventId == null &&
        (session.status == 'questioning' ||
            session.status == 'awaiting_user_input');
    if (!isDraft) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidRequestPayload,
        message: '只允许删除未完成草稿。',
      );
    }

    final List<IntakeMessage> messages = await _database
        .getIntakeMessagesBySessionId(sessionId);
    final List<IntakeSessionAttachment> attachments = await _database
        .getIntakeSessionAttachmentsBySessionId(sessionId);

    await _database.transaction(() async {
      for (final IntakeMessage message in messages) {
        await _database.deleteIntakeMessageById(message.id);
      }
      for (final IntakeSessionAttachment attachment in attachments) {
        await _database.deleteIntakeSessionAttachmentById(attachment.id);
      }
      await _database.deleteIntakeSessionById(sessionId);
    });

    try {
      await _intakeAttachmentStorage.deleteStoredAttachments(
        attachments
            .map((IntakeSessionAttachment attachment) => attachment.filePath)
            .toList(),
      );
    } catch (error, stackTrace) {
      developer.log(
        'hardDeleteDraftSession attachment cleanup failed for $sessionId: $error',
        name: 'IntakeService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<IntakeSubmissionResult> startIntake({
    required String rawText,
    required bool followUpModeEnabled,
    List<String> attachmentSourcePaths = const <String>[],
  }) async {
    final DateTime now = _truncateToSeconds(DateTime.now());
    final String normalizedRawText = _normalizeRequiredUserInput(rawText);
    _validateRawText(normalizedRawText);

    final String sessionId = _uuid.v4();
    final String firstMessageId = _uuid.v4();
    final List<String> stagedFilePaths = <String>[];
    final List<IntakeSessionAttachmentsCompanion> stagedAttachments =
        <IntakeSessionAttachmentsCompanion>[];

    try {
      await _database.transaction(() async {
        await _database.insertIntakeSession(
          IntakeSessionsCompanion.insert(
            id: sessionId,
            healthEventId: const Value<String?>.absent(),
            eventTime: now,
            followUpModeSnapshot: followUpModeEnabled,
            status: 'questioning',
            initialRawText: normalizedRawText,
            mergedRawText: const Value<String?>.absent(),
            latestQuestion: const Value<String?>.absent(),
            draftSymptomSummary: const Value<String?>.absent(),
            draftNotes: const Value<String?>.absent(),
            draftActionAdvice: const Value<String?>.absent(),
            createdAt: now,
            updatedAt: now,
          ),
        );
        await _database.insertIntakeMessage(
          IntakeMessagesCompanion.insert(
            id: firstMessageId,
            sessionId: sessionId,
            seq: 1,
            role: IntakeMessageRole.user.wireValue,
            content: normalizedRawText,
            createdAt: now,
          ),
        );
      });

      for (final String sourcePath in attachmentSourcePaths) {
        final String attachmentId = _uuid.v4();
        final String storedPath = await _intakeAttachmentStorage
            .saveImageAttachment(
              sessionId: sessionId,
              attachmentId: attachmentId,
              sourceFilePath: sourcePath,
            );
        stagedFilePaths.add(storedPath);
        stagedAttachments.add(
          IntakeSessionAttachmentsCompanion.insert(
            id: attachmentId,
            sessionId: sessionId,
            filePath: storedPath,
            fileType: 'image',
            createdAt: now,
          ),
        );
      }

      for (final IntakeSessionAttachmentsCompanion attachment
          in stagedAttachments) {
        await _database.insertIntakeSessionAttachment(attachment);
      }

      final IntakeResponse response = await _aiIntakeService.submitIntake(
        followUpMode: followUpModeEnabled,
        forceFinalize: false,
        eventTime: now,
        messages: <IntakeRequestMessage>[
          IntakeRequestMessage(
            role: IntakeMessageRole.user,
            content: normalizedRawText,
          ),
        ],
      );

      return await _handleResponse(
        sessionId: sessionId,
        response: response,
        forceFinalized: false,
      );
    } catch (_) {
      await _cleanupNewSession(sessionId);
      await _intakeAttachmentStorage.deleteStoredAttachments(stagedFilePaths);
      rethrow;
    }
  }

  Future<IntakeSubmissionResult> submitUserReply({
    required String sessionId,
    required String content,
  }) async {
    final IntakeSession session = await _requireSession(sessionId);
    final DateTime now = _truncateToSeconds(DateTime.now());
    final String normalizedContent = _normalizeRequiredUserInput(content);
    final List<IntakeMessage> existingMessages = await _database
        .getIntakeMessagesBySessionId(sessionId);
    final String messageId = _uuid.v4();

    await _database.insertIntakeMessage(
      IntakeMessagesCompanion.insert(
        id: messageId,
        sessionId: sessionId,
        seq: existingMessages.length + 1,
        role: IntakeMessageRole.user.wireValue,
        content: normalizedContent,
        createdAt: now,
      ),
    );
    await _database.updateIntakeSessionById(
      sessionId,
      IntakeSessionsCompanion(
        status: const Value<String>('questioning'),
        updatedAt: Value<DateTime>(now),
      ),
    );

    final List<IntakeRequestMessage> requestMessages = _toRequestMessages(
      await _database.getIntakeMessagesBySessionId(sessionId),
    );
    final IntakeResponse response = await _aiIntakeService.submitIntake(
      followUpMode: _resolveFollowUpMode(session),
      forceFinalize: false,
      eventTime: session.eventTime,
      messages: requestMessages,
    );
    return _handleResponse(
      sessionId: sessionId,
      response: response,
      forceFinalized: false,
    );
  }

  Future<IntakeSubmissionResult> resumeQuestioning(String sessionId) async {
    final IntakeSession session = await _requireSession(sessionId);
    if (session.status != 'questioning') {
      return IntakeSubmissionResult(
        sessionId: sessionId,
        isFinal:
            session.healthEventId != null &&
            (session.status == 'finalized' ||
                session.status == 'finalized_by_force'),
        healthEventId: session.healthEventId,
      );
    }

    final IntakeResponse response = await _aiIntakeService.submitIntake(
      followUpMode: _resolveFollowUpMode(session),
      forceFinalize: false,
      eventTime: session.eventTime,
      messages: _toRequestMessages(
        await _database.getIntakeMessagesBySessionId(sessionId),
      ),
    );

    return _handleResponse(
      sessionId: sessionId,
      response: response,
      forceFinalized: false,
    );
  }

  Future<IntakeSubmissionResult> forceFinalize(String sessionId) async {
    final IntakeSession session = await _requireSession(sessionId);
    final IntakeResponse response = await _aiIntakeService.submitIntake(
      followUpMode: _resolveFollowUpMode(session),
      forceFinalize: true,
      eventTime: session.eventTime,
      messages: _toRequestMessages(
        await _database.getIntakeMessagesBySessionId(sessionId),
      ),
    );
    return _handleResponse(
      sessionId: sessionId,
      response: response,
      forceFinalized: true,
    );
  }

  Future<IntakeSubmissionResult> _handleResponse({
    required String sessionId,
    required IntakeResponse response,
    required bool forceFinalized,
  }) async {
    final IntakeSession session = await _requireSession(sessionId);
    final DateTime now = _truncateToSeconds(DateTime.now());

    if (response.status == IntakeResponseStatus.needsFollowup) {
      final List<IntakeMessage> existingMessages = await _database
          .getIntakeMessagesBySessionId(sessionId);
      final String assistantMessageId = _uuid.v4();
      await _database.transaction(() async {
        await _database.insertIntakeMessage(
          IntakeMessagesCompanion.insert(
            id: assistantMessageId,
            sessionId: sessionId,
            seq: existingMessages.length + 1,
            role: IntakeMessageRole.assistant.wireValue,
            content: response.question!,
            createdAt: now,
          ),
        );
        await _database.updateIntakeSessionById(
          sessionId,
          IntakeSessionsCompanion(
            status: const Value<String>('awaiting_user_input'),
            mergedRawText: Value<String?>(response.draft.mergedRawText),
            latestQuestion: Value<String?>(response.question),
            draftSymptomSummary: Value<String?>(response.draft.symptomSummary),
            draftNotes: Value<String?>(response.draft.notes),
            draftActionAdvice: Value<String?>(response.draft.actionAdvice),
            updatedAt: Value<DateTime>(now),
          ),
        );
      });
      return IntakeSubmissionResult(sessionId: sessionId, isFinal: false);
    }

    final String healthEventId = await _persistFinalizedRecord(
      session: session,
      draft: response.draft,
      finalizedStatus: forceFinalized ? 'finalized_by_force' : 'finalized',
      updatedAt: now,
    );

    return IntakeSubmissionResult(
      sessionId: sessionId,
      isFinal: true,
      healthEventId: healthEventId,
    );
  }

  Future<String> _persistFinalizedRecord({
    required IntakeSession session,
    required IntakeDraft draft,
    required String finalizedStatus,
    required DateTime updatedAt,
  }) async {
    final String healthEventId = session.healthEventId ?? _uuid.v4();
    final List<IntakeSessionAttachment> stagedAttachments = await _database
        .getIntakeSessionAttachmentsBySessionId(session.id);
    final List<String> promotedFilePaths = <String>[];

    try {
      for (final IntakeSessionAttachment attachment in stagedAttachments) {
        final String promotedPath = await _healthRecordAttachmentStorage
            .saveImageAttachment(
              healthEventId: healthEventId,
              attachmentId: attachment.id,
              sourceFilePath: attachment.filePath,
            );
        promotedFilePaths.add(promotedPath);
      }

      await _database.transaction(() async {
        final HealthEvent? existingRecord = session.healthEventId == null
            ? null
            : await _database.getHealthEventById(session.healthEventId!);

        final HealthEventsCompanion healthEventCompanion =
            HealthEventsCompanion(
              id: Value<String>(healthEventId),
              sourceType: const Value<String>('text'),
              rawText: Value<String?>(draft.mergedRawText),
              symptomSummary: Value<String?>(draft.symptomSummary),
              notes: Value<String?>(draft.notes),
              actionAdvice: Value<String?>(draft.actionAdvice),
              createdAt: Value<DateTime>(
                existingRecord?.createdAt ?? session.eventTime,
              ),
              updatedAt: Value<DateTime>(
                existingRecord == null ? session.eventTime : updatedAt,
              ),
            );

        if (existingRecord == null) {
          await _database.insertHealthEvent(healthEventCompanion);
        } else {
          await _database.updateHealthEventById(
            healthEventId,
            healthEventCompanion,
          );
        }

        for (int index = 0; index < stagedAttachments.length; index += 1) {
          final IntakeSessionAttachment attachment = stagedAttachments[index];
          await _database.insertAttachment(
            AttachmentsCompanion(
              id: Value<String>(attachment.id),
              healthEventId: Value<String>(healthEventId),
              filePath: Value<String>(promotedFilePaths[index]),
              fileType: Value<String>(attachment.fileType),
              createdAt: Value<DateTime>(attachment.createdAt),
            ),
          );
          await _database.deleteIntakeSessionAttachmentById(attachment.id);
        }

        await _database.updateIntakeSessionById(
          session.id,
          IntakeSessionsCompanion(
            healthEventId: Value<String?>(healthEventId),
            status: Value<String>(finalizedStatus),
            mergedRawText: Value<String?>(draft.mergedRawText),
            latestQuestion: const Value<String?>(null),
            draftSymptomSummary: Value<String?>(draft.symptomSummary),
            draftNotes: Value<String?>(draft.notes),
            draftActionAdvice: Value<String?>(draft.actionAdvice),
            updatedAt: Value<DateTime>(updatedAt),
          ),
        );
      });

      await _intakeAttachmentStorage.deleteStoredAttachments(
        stagedAttachments
            .map((IntakeSessionAttachment attachment) => attachment.filePath)
            .toList(),
      );

      return healthEventId;
    } catch (_) {
      await _healthRecordAttachmentStorage.deleteStoredAttachments(
        promotedFilePaths,
      );
      rethrow;
    }
  }

  Future<void> _cleanupNewSession(String sessionId) async {
    final List<IntakeMessage> messages = await _database
        .getIntakeMessagesBySessionId(sessionId);
    final List<IntakeSessionAttachment> attachments = await _database
        .getIntakeSessionAttachmentsBySessionId(sessionId);
    for (final IntakeMessage message in messages) {
      await _database.deleteIntakeMessageById(message.id);
    }
    for (final IntakeSessionAttachment attachment in attachments) {
      await _database.deleteIntakeSessionAttachmentById(attachment.id);
    }
    await _database.deleteIntakeSessionById(sessionId);
  }

  Future<IntakeSession> _requireSession(String sessionId) async {
    final IntakeSession? session = await _database.getIntakeSessionById(
      sessionId,
    );
    if (session == null) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidRequestPayload,
        message: '未找到对应的追问会话。',
      );
    }

    return session;
  }

  bool _resolveFollowUpMode(IntakeSession session) {
    if (session.healthEventId != null) {
      return true;
    }
    return session.followUpModeSnapshot;
  }

  List<IntakeRequestMessage> _toRequestMessages(List<IntakeMessage> messages) {
    return messages.map((IntakeMessage message) {
      return IntakeRequestMessage(
        role: IntakeMessageRole.fromWireValue(message.role),
        content: message.content,
      );
    }).toList();
  }

  String _normalizeRequiredUserInput(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidRequestPayload,
        message: '请输入原始描述',
      );
    }
    return normalized;
  }

  void _validateRawText(String normalizedRawText) {
    if (normalizedRawText.length > healthRecordRawTextMaxLength) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidRequestPayload,
        message: '原始描述不能超过1000字',
      );
    }
  }

  DateTime _truncateToSeconds(DateTime value) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: value.isUtc,
    );
  }
}

class IntakeActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<IntakeSubmissionResult> startIntake({
    required String rawText,
    required bool followUpModeEnabled,
    List<String> attachmentSourcePaths = const <String>[],
  }) async {
    state = const AsyncLoading<void>();
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeServiceProvider)
          .startIntake(
            rawText: rawText,
            followUpModeEnabled: followUpModeEnabled,
            attachmentSourcePaths: attachmentSourcePaths,
          );
      _invalidateAfterMutation(result);
      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }

  Future<IntakeSubmissionResult> submitUserReply({
    required String sessionId,
    required String content,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeServiceProvider)
          .submitUserReply(sessionId: sessionId, content: content);
      _invalidateAfterMutation(result);
      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      ref.invalidate(intakeSessionProvider(sessionId));
      ref.invalidate(intakeMessagesProvider(sessionId));
      ref.invalidate(unfinishedIntakeSessionsProvider);
      rethrow;
    }
  }

  Future<IntakeSubmissionResult> resumeQuestioning(String sessionId) async {
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeServiceProvider)
          .resumeQuestioning(sessionId);
      _invalidateAfterMutation(result);
      return result;
    } catch (_) {
      ref.invalidate(intakeSessionProvider(sessionId));
      ref.invalidate(intakeMessagesProvider(sessionId));
      ref.invalidate(unfinishedIntakeSessionsProvider);
      rethrow;
    }
  }

  Future<IntakeSubmissionResult> forceFinalize(String sessionId) async {
    state = const AsyncLoading<void>();
    try {
      final IntakeSubmissionResult result = await ref
          .read(intakeServiceProvider)
          .forceFinalize(sessionId);
      _invalidateAfterMutation(result);
      state = const AsyncData<void>(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }

  void _invalidateAfterMutation(IntakeSubmissionResult result) {
    ref.invalidate(unfinishedIntakeSessionsProvider);
    ref.invalidate(linkedIntakeSessionsProvider);
    ref.invalidate(intakeSessionProvider(result.sessionId));
    ref.invalidate(intakeMessagesProvider(result.sessionId));
    ref.invalidate(healthRecordListProvider);
    if (result.healthEventId != null) {
      ref.invalidate(healthRecordDetailProvider(result.healthEventId!));
      ref.invalidate(healthRecordAttachmentsProvider(result.healthEventId!));
    }
  }
}

class DeleteDraftSessionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> deleteDraftSession(String sessionId) async {
    state = const AsyncLoading<void>();
    try {
      await ref.read(intakeServiceProvider).hardDeleteDraftSession(sessionId);
      state = const AsyncData<void>(null);
      ref.invalidate(unfinishedIntakeSessionsProvider);
      ref.invalidate(linkedIntakeSessionsProvider);
      ref.invalidate(intakeSessionProvider(sessionId));
      ref.invalidate(intakeMessagesProvider(sessionId));
      ref.invalidate(healthRecordListProvider);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
