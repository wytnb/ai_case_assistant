import 'dart:async';
import 'dart:developer' as developer;

import 'package:ai_case_assistant/core/constants/health_record_limits.dart';
import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/presentation/providers/ai_extract_service_provider.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final Provider<HealthRecordAttachmentStorage>
healthRecordAttachmentStorageProvider = Provider<HealthRecordAttachmentStorage>(
  (Ref ref) {
    return const HealthRecordAttachmentStorage();
  },
);

final Provider<HealthRecordService> healthRecordServiceProvider =
    Provider<HealthRecordService>((Ref ref) {
      return HealthRecordService(
        database: ref.watch(appDatabaseProvider),
        aiExtractService: ref.watch(aiExtractServiceProvider),
        attachmentStorage: ref.watch(healthRecordAttachmentStorageProvider),
      );
    });

final FutureProvider<List<HealthEvent>> healthRecordListProvider =
    FutureProvider<List<HealthEvent>>((Ref ref) {
      return ref.watch(healthRecordServiceProvider).getAllHealthRecords();
    });

final healthRecordDetailProvider = FutureProvider.family<HealthEvent?, String>((
  Ref ref,
  String id,
) {
  return ref.watch(healthRecordServiceProvider).getHealthRecordDetail(id);
});

final healthRecordAttachmentsProvider =
    FutureProvider.family<List<Attachment>, String>((Ref ref, String id) {
      return ref
          .watch(healthRecordServiceProvider)
          .getAttachmentsByHealthEventId(id);
    });

final AutoDisposeAsyncNotifierProvider<CreateHealthRecordController, void>
createHealthRecordControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreateHealthRecordController, void>(
      CreateHealthRecordController.new,
    );

class HealthRecordService {
  static const int rawTextMaxLength = healthRecordRawTextMaxLength;

  HealthRecordService({
    required AppDatabase database,
    required AiExtractService aiExtractService,
    required HealthRecordAttachmentStorage attachmentStorage,
  }) : _database = database,
       _aiExtractService = aiExtractService,
       _attachmentStorage = attachmentStorage;

  final AppDatabase _database;
  final AiExtractService _aiExtractService;
  final HealthRecordAttachmentStorage _attachmentStorage;
  static const Uuid _uuid = Uuid();

  Future<String> createHealthRecord({
    required String rawText,
    List<String> attachmentSourcePaths = const <String>[],
  }) async {
    final DateTime now = _truncateToSeconds(DateTime.now());
    final String normalizedRawText = rawText.trim();
    _validateRawText(normalizedRawText);
    final String healthEventId = _uuid.v4();
    developer.log(
      'createHealthRecord started id=$healthEventId rawTextLength=${normalizedRawText.length} '
      'attachmentCount=${attachmentSourcePaths.length} eventTime=$now',
      name: 'HealthRecordService',
    );
    final AiExtractResult extractResult = await _aiExtractService
        .extractFromRawText(rawText: normalizedRawText, eventTime: now);
    final String normalizedSymptomSummary = _normalizeStoredText(
      extractResult.symptomSummary,
    );
    final String? normalizedNotes = extractResult.notes == null
        ? null
        : _normalizeStoredText(extractResult.notes!);
    developer.log(
      'createHealthRecord aiExtracted id=$healthEventId summaryLength=${normalizedSymptomSummary.length} '
      'notesLength=${normalizedNotes?.length ?? 0}',
      name: 'HealthRecordService',
    );

    final List<String> copiedFilePaths = <String>[];
    final List<AttachmentsCompanion> attachmentCompanions =
        <AttachmentsCompanion>[];

    try {
      for (final String sourcePath in attachmentSourcePaths) {
        final String attachmentId = _uuid.v4();
        final String storedFilePath = await _attachmentStorage
            .saveImageAttachment(
              healthEventId: healthEventId,
              attachmentId: attachmentId,
              sourceFilePath: sourcePath,
            );
        copiedFilePaths.add(storedFilePath);
        attachmentCompanions.add(
          AttachmentsCompanion(
            id: Value<String>(attachmentId),
            healthEventId: Value<String>(healthEventId),
            filePath: Value<String>(storedFilePath),
            fileType: const Value<String>('image'),
            createdAt: Value<DateTime>(now),
          ),
        );
      }

      await _database.transaction(() async {
        await _database.insertHealthEvent(
          HealthEventsCompanion(
            id: Value<String>(healthEventId),
            sourceType: const Value<String>('text'),
            rawText: Value<String>(normalizedRawText),
            symptomSummary: Value<String?>(normalizedSymptomSummary),
            notes: normalizedNotes == null
                ? const Value<String?>.absent()
                : Value<String?>(normalizedNotes),
            actionAdvice: const Value<String?>.absent(),
            createdAt: Value<DateTime>(now),
            updatedAt: Value<DateTime>(now),
          ),
        );

        for (final AttachmentsCompanion attachment in attachmentCompanions) {
          await _database.insertAttachment(attachment);
        }
      });
      developer.log(
        'createHealthRecord persisted id=$healthEventId attachmentCount=${attachmentCompanions.length}',
        name: 'HealthRecordService',
      );
    } catch (error, stackTrace) {
      developer.log(
        'createHealthRecord failed id=$healthEventId type=${error.runtimeType} message=$error',
        name: 'HealthRecordService',
        error: error,
        stackTrace: stackTrace,
      );
      await _attachmentStorage.deleteStoredAttachments(copiedFilePaths);
      rethrow;
    }

    return healthEventId;
  }

  Future<List<HealthEvent>> getAllHealthRecords() {
    return _database.getAllHealthEvents();
  }

  Future<HealthEvent?> getHealthRecordDetail(String id) {
    return _database.getHealthEventById(id);
  }

  Future<List<Attachment>> getAttachmentsByHealthEventId(String healthEventId) {
    return _database.getAttachmentsByHealthEventId(healthEventId);
  }

  String _normalizeStoredText(String value) {
    return value.trim();
  }

  void _validateRawText(String normalizedRawText) {
    if (normalizedRawText.isEmpty) {
      throw const AiExtractException(
        type: AiExtractExceptionType.invalidRequestPayload,
        message: '请输入原始描述',
      );
    }

    if (normalizedRawText.length > rawTextMaxLength) {
      throw const AiExtractException(
        type: AiExtractExceptionType.invalidRequestPayload,
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

class CreateHealthRecordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> createHealthRecord({
    required String rawText,
    List<String> attachmentSourcePaths = const <String>[],
  }) async {
    state = const AsyncLoading<void>();

    try {
      final String id = await ref
          .read(healthRecordServiceProvider)
          .createHealthRecord(
            rawText: rawText,
            attachmentSourcePaths: attachmentSourcePaths,
          );

      state = const AsyncData<void>(null);
      ref.invalidate(healthRecordListProvider);
      ref.invalidate(healthRecordDetailProvider(id));
      ref.invalidate(healthRecordAttachmentsProvider(id));

      return id;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
