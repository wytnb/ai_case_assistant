import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_list_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows unfinished intake section separately from formal records',
    (WidgetTester tester) async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.insertIntakeSession(
        IntakeSessionsCompanion.insert(
          id: 'session-1',
          healthEventId: const Value<String?>.absent(),
          eventTime: DateTime.parse('2026-03-15T10:00:00.000'),
          followUpModeSnapshot: true,
          status: 'awaiting_user_input',
          initialRawText: '原始描述',
          mergedRawText: const Value<String?>('合并描述'),
          latestQuestion: const Value<String?>('有没有发烧？'),
          draftSymptomSummary: const Value<String?>('追问摘要'),
          draftNotes: const Value<String?>(''),
          draftActionAdvice: const Value<String?>(''),
          createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
          updatedAt: DateTime.parse('2026-03-15T10:30:00.000'),
        ),
      );
      await database.insertHealthEvent(
        HealthEventsCompanion.insert(
          id: 'record-1',
          sourceType: 'text',
          rawText: const Value<String?>('raw symptom text'),
          symptomSummary: const Value<String?>('summary text'),
          notes: const Value<String?>('Keep monitoring for 2 days'),
          actionAdvice: const Value<String?>('继续观察'),
          createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
          updatedAt: DateTime.parse('2026-03-15T10:00:00.000'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            appDatabaseProvider.overrideWithValue(database),
          ],
          child: const MaterialApp(home: HealthRecordListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('未完成追问'), findsOneWidget);
      expect(find.text('正式记录'), findsOneWidget);
      expect(find.text('追问摘要'), findsOneWidget);
      expect(find.text('summary text'), findsOneWidget);
      expect(find.text('继续追问'), findsOneWidget);
    },
  );

  testWidgets('shows neutral placeholder when symptomSummary is blank', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-1',
        sourceType: 'text',
        rawText: const Value<String?>('raw symptom text'),
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
        child: const MaterialApp(home: HealthRecordListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无 AI 摘要'), findsOneWidget);
    expect(find.textContaining('raw symptom text'), findsNothing);
  });
}
