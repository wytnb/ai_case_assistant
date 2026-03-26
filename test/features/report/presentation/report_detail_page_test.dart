import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:ai_case_assistant/features/report/presentation/pages/report_detail_page.dart';
import 'package:ai_case_assistant/features/report/presentation/providers/report_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows disclaimer section at the bottom of report detail', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DateTime now = DateTime.parse('2026-03-19T10:00:00.000');
    await database.insertReport(
      ReportsCompanion.insert(
        id: 'report-1',
        reportType: 'week',
        rangeStart: DateTime.parse('2026-03-13T00:00:00.000'),
        rangeEnd: DateTime.parse('2026-03-19T23:59:59.999'),
        title: '周报标题',
        summary: '周报摘要',
        adviceJson: '["建议一"]',
        markdown: 'markdown 内容',
        generatedAt: now,
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          reportServiceProvider.overrideWithValue(
            ReportService(
              database: database,
              aiReportService: const _UnusedAiReportService(),
            ),
          ),
        ],
        child: const MaterialApp(home: ReportDetailPage(reportId: 'report-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('免责说明'), 300);
    await tester.pump();

    expect(find.text('免责说明'), findsOneWidget);
    expect(
      find.textContaining('本报告由 AI 基于你提交的文字、图片及已完成的正式健康记录自动生成'),
      findsOneWidget,
    );
  });

  testWidgets('shows deleted-source warning when a source record was removed after report generation', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DateTime generatedAt = DateTime.parse('2026-03-19T10:00:00.000');
    await database.insertReport(
      ReportsCompanion.insert(
        id: 'report-1',
        reportType: 'week',
        rangeStart: DateTime.parse('2026-03-13T00:00:00.000'),
        rangeEnd: DateTime.parse('2026-03-19T23:59:59.999'),
        title: '周报标题',
        summary: '周报摘要',
        adviceJson: '["建议一"]',
        markdown: 'markdown 内容',
        generatedAt: generatedAt,
        createdAt: generatedAt,
      ),
    );
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-1',
        sourceType: 'text',
        status: const Value<String>('deleted'),
        rawText: const Value<String?>('raw text'),
        symptomSummary: const Value<String?>('summary'),
        notes: const Value<String?>('notes'),
        actionAdvice: const Value<String?>('advice'),
        deletedAt: Value<DateTime?>(DateTime.parse('2026-03-20T10:00:00.000')),
        createdAt: DateTime.parse('2026-03-18T09:00:00.000'),
        updatedAt: DateTime.parse('2026-03-20T10:00:00.000'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          reportServiceProvider.overrideWithValue(
            ReportService(
              database: database,
              aiReportService: const _UnusedAiReportService(),
            ),
          ),
        ],
        child: const MaterialApp(home: ReportDetailPage(reportId: 'report-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('部分记录来源已被删除'), findsOneWidget);
  });
}

class _UnusedAiReportService implements AiReportService {
  const _UnusedAiReportService();

  @override
  Future<AiReportResult> generateReport({
    required String reportType,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<AiReportEvent> events,
  }) {
    throw UnimplementedError('This test does not generate reports.');
  }
}
