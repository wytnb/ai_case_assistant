import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_list_page.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android device list filter and overflow delete work together', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-in',
        sourceType: 'text',
        rawText: const Value<String?>('筛选范围内正式记录'),
        symptomSummary: const Value<String?>('summary'),
        notes: const Value<String?>('notes'),
        actionAdvice: const Value<String?>('advice'),
        createdAt: DateTime.parse('2026-03-15T10:00:00.000'),
        updatedAt: DateTime.parse('2026-03-15T10:00:00.000'),
      ),
    );
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-out',
        sourceType: 'text',
        rawText: const Value<String?>('筛选范围外正式记录'),
        symptomSummary: const Value<String?>('summary'),
        notes: const Value<String?>('notes'),
        actionAdvice: const Value<String?>('advice'),
        createdAt: DateTime.parse('2026-03-20T10:00:00.000'),
        updatedAt: DateTime.parse('2026-03-20T10:00:00.000'),
      ),
    );
    await database.insertIntakeSession(
      IntakeSessionsCompanion.insert(
        id: 'draft-menu',
        healthEventId: const Value<String?>.absent(),
        eventTime: DateTime.parse('2026-03-15T11:00:00.000'),
        followUpModeSnapshot: true,
        status: 'awaiting_user_input',
        initialRawText: '用于真机删除验证的草稿',
        mergedRawText: const Value<String?>('用于真机删除验证的草稿'),
        latestQuestion: const Value<String?>('请补充持续时间'),
        draftSymptomSummary: const Value<String?>('摘要'),
        draftNotes: const Value<String?>(''),
        draftActionAdvice: const Value<String?>(''),
        createdAt: DateTime.parse('2026-03-15T11:00:00.000'),
        updatedAt: DateTime.parse('2026-03-15T11:30:00.000'),
      ),
    );
    await database.insertIntakeMessage(
      IntakeMessagesCompanion.insert(
        id: 'draft-menu-message',
        sessionId: 'draft-menu',
        seq: 1,
        role: 'user',
        content: '用于真机删除验证的草稿',
        createdAt: DateTime.parse('2026-03-15T11:00:00.000'),
      ),
    );
    await database.insertIntakeSession(
      IntakeSessionsCompanion.insert(
        id: 'draft-out',
        healthEventId: const Value<String?>.absent(),
        eventTime: DateTime.parse('2026-03-20T11:00:00.000'),
        followUpModeSnapshot: true,
        status: 'awaiting_user_input',
        initialRawText: '筛选范围外草稿',
        mergedRawText: const Value<String?>('筛选范围外草稿'),
        latestQuestion: const Value<String?>('问题'),
        draftSymptomSummary: const Value<String?>('摘要'),
        draftNotes: const Value<String?>(''),
        draftActionAdvice: const Value<String?>(''),
        createdAt: DateTime.parse('2026-03-20T11:00:00.000'),
        updatedAt: DateTime.parse('2026-03-20T11:30:00.000'),
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final GoRouter router = GoRouter(
      initialLocation: '/records',
      routes: <RouteBase>[
        GoRoute(
          path: '/records',
          builder: (_, _) => const HealthRecordListPage(),
        ),
        GoRoute(
          path: '/records/:id',
          builder: (_, GoRouterState state) => Scaffold(
            body: Center(child: Text('record-${state.pathParameters['id']}')),
          ),
        ),
        GoRoute(
          path: '/intake/:id',
          builder: (_, GoRouterState state) => Scaffold(
            body: Center(child: Text('intake-${state.pathParameters['id']}')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(recordEventTimeFilterProvider.notifier)
        .state = DateTimeRange(
      start: DateTime.parse('2026-03-15T00:00:00.000'),
      end: DateTime.parse('2026-03-15T23:59:59.999'),
    );
    await tester.pumpAndSettle();

    expect(find.text('筛选范围内正式记录'), findsOneWidget);
    expect(find.text('筛选范围外正式记录'), findsNothing);
    expect(find.text('清空'), findsOneWidget);

    await tester.tap(find.text('草稿记录'));
    await tester.pumpAndSettle();

    expect(find.text('用于真机删除验证的草稿'), findsOneWidget);
    expect(find.text('筛选范围外草稿'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(await database.getIntakeSessionById('draft-menu'), isNull);
    expect(find.text('草稿记录已删除。'), findsOneWidget);
    expect(find.text('未找到追问会话'), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/records',
    );

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('正式记录'));
    await tester.pumpAndSettle();

    expect(find.text('筛选范围内正式记录'), findsOneWidget);
    expect(find.text('筛选范围外正式记录'), findsOneWidget);
  });
}
