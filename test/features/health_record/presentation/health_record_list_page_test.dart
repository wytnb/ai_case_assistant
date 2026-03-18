import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_list_page.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a single event time based on createdAt in the list', (
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
        child: const MaterialApp(home: HealthRecordListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('summary text'), findsOneWidget);
    expect(find.text('2026-03-15 10:00'), findsOneWidget);
    expect(find.textContaining(' - '), findsNothing);
  });
}
