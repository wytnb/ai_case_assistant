import 'dart:async';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/presentation/providers/ai_extract_service_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final Provider<HealthRecordService> healthRecordServiceProvider =
    Provider<HealthRecordService>((Ref ref) {
      return HealthRecordService(
        database: ref.watch(appDatabaseProvider),
        aiExtractService: ref.watch(aiExtractServiceProvider),
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
  HealthRecordService({
    required AppDatabase database,
    required AiExtractService aiExtractService,
  }) : _database = database,
       _aiExtractService = aiExtractService;

  final AppDatabase _database;
  final AiExtractService _aiExtractService;
  static const Uuid _uuid = Uuid();

  Future<String> createHealthRecord({required String rawText}) async {
    final String id = _uuid.v4();
    final DateTime now = DateTime.now();
    final String normalizedRawText = rawText.trim();
    final AiExtractResult extractResult = await _aiExtractService
        .extractFromRawText(rawText: normalizedRawText);
    final String? normalizedSymptomSummary = _normalizeOptionalText(
      extractResult.symptomSummary,
    );
    final String? normalizedNotes = _normalizeOptionalText(extractResult.notes);

    await _database.insertHealthEvent(
      HealthEventsCompanion(
        id: Value<String>(id),
        eventTime: Value<DateTime>(now),
        sourceType: const Value<String>('text'),
        rawText: Value<String>(normalizedRawText),
        symptomSummary: normalizedSymptomSummary == null
            ? const Value<String?>.absent()
            : Value<String?>(normalizedSymptomSummary),
        notes: normalizedNotes == null
            ? const Value<String?>.absent()
            : Value<String?>(normalizedNotes),
        createdAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
      ),
    );

    return id;
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

  String? _normalizeOptionalText(String? value) {
    if (value == null) {
      return null;
    }

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}

class CreateHealthRecordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> createHealthRecord({required String rawText}) async {
    state = const AsyncLoading<void>();

    try {
      final String id = await ref
          .read(healthRecordServiceProvider)
          .createHealthRecord(rawText: rawText);

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
