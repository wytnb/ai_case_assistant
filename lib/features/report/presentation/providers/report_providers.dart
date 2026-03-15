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

enum ReportGenerationType {
  week(reportType: 'week', displayName: '周报', rangeDays: 7),
  month(reportType: 'month', displayName: '月报', rangeDays: 30),
  quarter(reportType: 'quarter', displayName: '季报', rangeDays: 90);

  const ReportGenerationType({
    required this.reportType,
    required this.displayName,
    required this.rangeDays,
  });

  final String reportType;
  final String displayName;
  final int rangeDays;
}

final StateProvider<ReportGenerationType> selectedReportTypeProvider =
    StateProvider<ReportGenerationType>((Ref ref) {
      return ReportGenerationType.week;
    });

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

  Future<String> generateReport(ReportGenerationType reportType) async {
    try {
      final DateTime now = DateTime.now();
      final _ReportRange reportRange = _buildReportRange(now, reportType);

      final List<HealthEvent> sourceEvents = await _database
          .getHealthEventsByRange(
            rangeStart: reportRange.rangeStart,
            rangeEnd: reportRange.rangeEnd,
          );

      final List<AiReportEvent> aiEvents = sourceEvents
          .map(
            (HealthEvent event) => AiReportEvent(
              id: event.id,
              eventStartTime: event.eventStartTime,
              eventEndTime: event.eventEndTime,
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
        reportType: reportType.reportType,
        rangeStart: reportRange.rangeStart,
        rangeEnd: reportRange.rangeEnd,
        events: aiEvents,
      );

      final DateTime generatedAt = DateTime.now();
      final List<Report> scopedReports = await _database.getReportsByScope(
        reportType: reportType.reportType,
        rangeStart: reportRange.rangeStart,
        rangeEnd: reportRange.rangeEnd,
      );
      final Report? existingReport = scopedReports.isEmpty
          ? null
          : scopedReports.first;
      final String reportId = existingReport?.id ?? _uuid.v4();
      debugPrint(
        '[REPORT] insertReport start: id=$reportId, reportType=${reportType.reportType}, '
        'rangeStart=${reportRange.rangeStart.toIso8601String()}, '
        'rangeEnd=${reportRange.rangeEnd.toIso8601String()}, '
        'generatedAt=${generatedAt.toIso8601String()}, '
        'overwrite=${existingReport != null}, '
        'duplicateCount=${scopedReports.length}',
      );

      if (existingReport == null) {
        await _database.insertReport(
          ReportsCompanion(
            id: Value<String>(reportId),
            reportType: Value<String>(reportType.reportType),
            rangeStart: Value<DateTime>(reportRange.rangeStart),
            rangeEnd: Value<DateTime>(reportRange.rangeEnd),
            title: Value<String>(generated.title),
            summary: Value<String>(generated.summary),
            adviceJson: Value<String>(jsonEncode(generated.advice)),
            markdown: Value<String>(generated.markdown),
            generatedAt: Value<DateTime>(generatedAt),
            createdAt: Value<DateTime>(generatedAt),
          ),
        );
      } else {
        await _database.updateReportById(
          reportId,
          ReportsCompanion(
            reportType: Value<String>(reportType.reportType),
            rangeStart: Value<DateTime>(reportRange.rangeStart),
            rangeEnd: Value<DateTime>(reportRange.rangeEnd),
            title: Value<String>(generated.title),
            summary: Value<String>(generated.summary),
            adviceJson: Value<String>(jsonEncode(generated.advice)),
            markdown: Value<String>(generated.markdown),
            generatedAt: Value<DateTime>(generatedAt),
            createdAt: Value<DateTime>(existingReport.createdAt),
          ),
        );
        for (final Report duplicatedReport in scopedReports.skip(1)) {
          await _database.deleteReportById(duplicatedReport.id);
        }
      }
      debugPrint('[REPORT] insertReport success: id=$reportId');

      return reportId;
    } catch (error) {
      debugPrint(
        '[REPORT] exception: type=${error.runtimeType}, message=$error',
      );
      rethrow;
    }
  }

  Future<String> generateWeeklyReport() async {
    return generateReport(ReportGenerationType.week);
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

  _ReportRange _buildReportRange(
    DateTime now,
    ReportGenerationType reportType,
  ) {
    final DateTime rangeStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: reportType.rangeDays - 1));
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

    return _ReportRange(rangeStart: rangeStart, rangeEnd: rangeEnd);
  }
}

class GenerateWeeklyReportController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> generateReport(ReportGenerationType reportType) async {
    state = const AsyncLoading<void>();

    try {
      final String reportId = await ref
          .read(reportServiceProvider)
          .generateReport(reportType);
      state = const AsyncData<void>(null);
      ref.invalidate(reportListProvider);
      ref.invalidate(reportDetailProvider(reportId));

      return reportId;
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }

  Future<String> generateWeeklyReport() async {
    return generateReport(ReportGenerationType.week);
  }
}

class _ReportRange {
  const _ReportRange({required this.rangeStart, required this.rangeEnd});

  final DateTime rangeStart;
  final DateTime rangeEnd;
}
