import 'dart:async';
import 'dart:convert';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:ai_case_assistant/features/ai/presentation/providers/ai_report_service_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final Provider<ReportService> reportServiceProvider = Provider<ReportService>((
  Ref ref,
) {
  return ReportService(
    database: ref.watch(appDatabaseProvider),
    aiReportService: ref.watch(aiReportServiceProvider),
  );
});

final FutureProvider<List<Report>> reportListProvider =
    FutureProvider<List<Report>>((Ref ref) {
      return ref.watch(reportServiceProvider).getAllReports();
    });

final FutureProviderFamily<Report?, String> reportDetailProvider =
    FutureProvider.family<Report?, String>((Ref ref, String id) {
      return ref.watch(reportServiceProvider).getReportDetail(id);
    });

final AutoDisposeAsyncNotifierProvider<GenerateWeeklyReportController, void>
generateWeeklyReportControllerProvider =
    AutoDisposeAsyncNotifierProvider<GenerateWeeklyReportController, void>(
      GenerateWeeklyReportController.new,
    );

class ReportService {
  ReportService({
    required AppDatabase database,
    required AiReportService aiReportService,
  }) : _database = database,
       _aiReportService = aiReportService;

  static const int _reportEventRawTextMaxLength = 500;
  final AppDatabase _database;
  final AiReportService _aiReportService;
  static const Uuid _uuid = Uuid();

  Future<String> generateWeeklyReport() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime rangeStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      final DateTime rangeEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
        999,
      );

      final List<HealthEvent> sourceEvents = await _database
          .getHealthEventsByRange(rangeStart: rangeStart, rangeEnd: rangeEnd);

      final List<AiReportEvent> aiEvents = sourceEvents
          .map(
            (HealthEvent event) => AiReportEvent(
              id: event.id,
              eventTime: event.eventTime,
              sourceType: event.sourceType,
              rawText: _truncateOptionalText(
                _normalizeOptionalText(event.rawText),
                _reportEventRawTextMaxLength,
              ),
              symptomSummary: _normalizeOptionalText(event.symptomSummary),
              notes: _normalizeOptionalText(event.notes),
            ),
          )
          .toList();

      final AiReportResult generated = await _aiReportService.generateReport(
        reportType: 'week',
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        events: aiEvents,
      );

      final String reportId = _uuid.v4();
      final DateTime generatedAt = DateTime.now();
      debugPrint(
        '[REPORT] insertReport start: id=$reportId, reportType=week, rangeStart=${rangeStart.toIso8601String()}, '
        'rangeEnd=${rangeEnd.toIso8601String()}, generatedAt=${generatedAt.toIso8601String()}',
      );
      await _database.insertReport(
        ReportsCompanion(
          id: Value<String>(reportId),
          reportType: const Value<String>('week'),
          rangeStart: Value<DateTime>(rangeStart),
          rangeEnd: Value<DateTime>(rangeEnd),
          title: Value<String>(generated.title),
          summary: Value<String>(generated.summary),
          adviceJson: Value<String>(jsonEncode(generated.advice)),
          markdown: Value<String>(generated.markdown),
          generatedAt: Value<DateTime>(generatedAt),
          createdAt: Value<DateTime>(generatedAt),
        ),
      );
      debugPrint('[REPORT] insertReport success: id=$reportId');

      return reportId;
    } catch (error) {
      debugPrint(
        '[REPORT] exception: type=${error.runtimeType}, message=$error',
      );
      rethrow;
    }
  }

  Future<List<Report>> getAllReports() {
    return _database.getAllReports();
  }

  Future<Report?> getReportDetail(String id) {
    return _database.getReportById(id);
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

  String? _truncateOptionalText(String? value, int maxLength) {
    if (value == null || value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}...';
  }
}

class GenerateWeeklyReportController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> generateWeeklyReport() async {
    state = const AsyncLoading<void>();

    try {
      final String reportId = await ref
          .read(reportServiceProvider)
          .generateWeeklyReport();
      state = const AsyncData<void>(null);
      ref.invalidate(reportListProvider);
      ref.invalidate(reportDetailProvider(reportId));

      return reportId;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
