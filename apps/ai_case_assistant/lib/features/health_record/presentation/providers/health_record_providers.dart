import 'dart:async';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<HealthRecordAttachmentStorage>
healthRecordAttachmentStorageProvider = Provider<HealthRecordAttachmentStorage>(
  (Ref ref) {
    return const HealthRecordAttachmentStorage();
  },
);

final Provider<HealthRecordService> healthRecordServiceProvider =
    Provider<HealthRecordService>((Ref ref) {
      return HealthRecordService(database: ref.watch(appDatabaseProvider));
    });

final FutureProvider<List<HealthEvent>> healthRecordListProvider =
    FutureProvider<List<HealthEvent>>((Ref ref) {
      final DateTimeRange? filter = ref.watch(recordEventTimeFilterProvider);
      return ref.watch(healthRecordServiceProvider).getAllHealthRecords(
        start: filter?.start,
        end: filter?.end,
      );
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

final StateProvider<DateTimeRange?> recordEventTimeFilterProvider =
    StateProvider<DateTimeRange?>((Ref ref) => null);

final AutoDisposeAsyncNotifierProvider<DeleteHealthRecordController, void>
deleteHealthRecordControllerProvider =
    AutoDisposeAsyncNotifierProvider<DeleteHealthRecordController, void>(
      DeleteHealthRecordController.new,
    );

class HealthRecordService {
  HealthRecordService({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<List<HealthEvent>> getAllHealthRecords({
    DateTime? start,
    DateTime? end,
  }) {
    return _database.getAllHealthEvents(start: start, end: end);
  }

  Future<HealthEvent?> getHealthRecordDetail(String id) {
    return _database.getHealthEventById(id);
  }

  Future<List<Attachment>> getAttachmentsByHealthEventId(String healthEventId) {
    return _database.getAttachmentsByHealthEventId(healthEventId);
  }

  Future<void> softDeleteHealthRecord(String healthEventId) async {
    final HealthEvent? record = await _database.getHealthEventByIdIncludingDeleted(
      healthEventId,
    );
    if (record == null || record.status == 'deleted') {
      return;
    }

    final IntakeSession? linkedSession = await _database.getIntakeSessionByHealthEventId(
      healthEventId,
    );
    final DateTime now = _truncateToSeconds(DateTime.now());

    await _database.transaction(() async {
      await _database.updateHealthEventById(
        healthEventId,
        HealthEventsCompanion(
          status: const Value<String>('deleted'),
          deletedAt: Value<DateTime?>(now),
          updatedAt: Value<DateTime>(now),
        ),
      );

      if (linkedSession != null) {
        await _database.updateIntakeSessionById(
          linkedSession.id,
          IntakeSessionsCompanion(
            status: const Value<String>('deleted'),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }
    });
  }

  DateTime _truncateToSeconds(DateTime value) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: value.isUtc,
    );
  }
}

class DeleteHealthRecordController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> deleteHealthRecord(String healthEventId) async {
    state = const AsyncLoading<void>();

    try {
      await ref
          .read(healthRecordServiceProvider)
          .softDeleteHealthRecord(healthEventId);
      state = const AsyncData<void>(null);
      ref.invalidate(healthRecordListProvider);
      ref.invalidate(healthRecordDetailProvider(healthEventId));
      ref.invalidate(healthRecordAttachmentsProvider(healthEventId));
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
