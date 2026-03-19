import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_detail_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows action advice and re-open entry for linked intake session',
    (WidgetTester tester) async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'record-1',
          sourceType: 'text',
          rawText: const Value<String?>('raw symptom text'),
          symptomSummary: const Value<String?>('summary text'),
          notes: const Value<String?>('Keep monitoring for 2 days'),
          actionAdvice: const Value<String?>('continue observing temperature'),
          createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
          updatedAt: DateTime.parse('2026-03-15T10:00:00.000'),
        ),
      );
      await database.insertIntakeSession(
        IntakeSessionsCompanion.insert(
          id: 'session-1',
          healthEventId: const Value<String?>('record-1'),
          eventTime: DateTime.parse('2026-03-15T10:00:00.000'),
          followUpModeSnapshot: false,
          status: 'finalized',
          initialRawText: 'raw symptom text',
          mergedRawText: const Value<String?>('raw symptom text'),
          latestQuestion: const Value<String?>.absent(),
          draftSymptomSummary: const Value<String?>('summary text'),
          draftNotes: const Value<String?>('Keep monitoring for 2 days'),
          draftActionAdvice: const Value<String?>(
            'continue observing temperature',
          ),
          createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
          updatedAt: DateTime.parse('2026-03-15T10:10:00.000'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            appDatabaseProvider.overrideWithValue(database),
          ],
          child: const MaterialApp(
            home: HealthRecordDetailPage(healthRecordId: 'record-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(FilledButton), 200);
      await tester.pump();

      expect(find.text('summary text'), findsOneWidget);
      expect(find.text('continue observing temperature'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );

  testWidgets('shows neutral placeholders when stored text fields are blank', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-2',
        sourceType: 'text',
        rawText: const Value<String?>(''),
        symptomSummary: const Value<String?>(''),
        notes: const Value<String?>(''),
        actionAdvice: const Value<String?>(''),
        createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
        updatedAt: DateTime.parse('2026-03-15T10:00:00.000'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: HealthRecordDetailPage(healthRecordId: 'record-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无原始文本'), findsOneWidget);
    expect(find.text('暂无 AI 摘要'), findsOneWidget);
    expect(find.text('暂无备注'), findsOneWidget);
    expect(find.text('暂无建议'), findsOneWidget);
  });
}
