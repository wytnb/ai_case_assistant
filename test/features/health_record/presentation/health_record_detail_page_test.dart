import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_detail_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows stored notes verbatim in the detail page', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-1',
        sourceType: 'text',
        rawText: const Value<String?>('raw symptom text'),
        symptomSummary: const Value<String?>('summary text'),
        notes: const Value<String?>('Keep monitoring for 2 days'),
        createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
        updatedAt: DateTime.parse('2026-03-15T10:00:00.000'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          home: HealthRecordDetailPage(healthRecordId: 'record-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('raw symptom text'), findsOneWidget);
    expect(find.text('summary text'), findsOneWidget);
    expect(find.text('事件时间'), findsOneWidget);
    expect(find.text('开始时间'), findsNothing);
    expect(find.text('结束时间'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Keep monitoring for 2 days'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Keep monitoring for 2 days'), findsOneWidget);
  });

  testWidgets('shows empty-state text when notes are missing', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-2',
        sourceType: 'text',
        rawText: const Value<String?>('raw symptom text'),
        symptomSummary: const Value<String?>('summary text'),
        notes: const Value<String?>.absent(),
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

    expect(find.text('Keep monitoring for 2 days'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('暂无备注'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('暂无备注'), findsOneWidget);
  });
}
