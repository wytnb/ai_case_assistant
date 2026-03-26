import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_list_page.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:ai_case_assistant/features/intake/data/local/intake_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('shows tabs and uses raw text titles instead of summaries', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertIntakeSession(
      IntakeSessionsCompanion.insert(
        id: 'session-1',
        healthEventId: const Value<String?>.absent(),
        eventTime: DateTime.parse('2026-03-15T10:00:00.000'),
        followUpModeSnapshot: true,
        status: 'awaiting_user_input',
        initialRawText: '原始草稿文本',
        mergedRawText: const Value<String?>('合并后的草稿原文'),
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
        rawText: const Value<String?>('正式记录原始文本'),
        symptomSummary: const Value<String?>('summary text'),
        notes: const Value<String?>('Keep monitoring for 2 days'),
        actionAdvice: const Value<String?>('继续观察'),
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

    expect(find.text('正式记录'), findsOneWidget);
    expect(find.text('草稿记录'), findsOneWidget);
    expect(find.text('正式记录原始文本'), findsOneWidget);
    expect(find.text('合并后的草稿原文'), findsNothing);
    expect(find.text('summary text'), findsNothing);
    expect(find.text('来源：text'), findsNothing);
    expect(find.text('继续补充'), findsNothing);

    await tester.tap(find.text('草稿记录'));
    await tester.pumpAndSettle();

    expect(find.text('合并后的草稿原文'), findsOneWidget);
    expect(find.text('追问摘要'), findsNothing);
    expect(find.text('继续追问'), findsOneWidget);
  });

  testWidgets('date range filter and delete state update both tabs', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertHealthEvent(
      HealthEventsCompanion.insert(
        id: 'record-in',
        sourceType: 'text',
        rawText: const Value<String?>('范围内正式记录'),
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
        rawText: const Value<String?>('范围外正式记录'),
        symptomSummary: const Value<String?>('summary'),
        notes: const Value<String?>('notes'),
        actionAdvice: const Value<String?>('advice'),
        createdAt: DateTime.parse('2026-03-20T10:00:00.000'),
        updatedAt: DateTime.parse('2026-03-20T10:00:00.000'),
      ),
    );
    await database.insertIntakeSession(
      IntakeSessionsCompanion.insert(
        id: 'draft-in',
        healthEventId: const Value<String?>.absent(),
        eventTime: DateTime.parse('2026-03-15T11:00:00.000'),
        followUpModeSnapshot: true,
        status: 'awaiting_user_input',
        initialRawText: '范围内草稿',
        mergedRawText: const Value<String?>('范围内草稿'),
        latestQuestion: const Value<String?>('问题'),
        draftSymptomSummary: const Value<String?>('摘要'),
        draftNotes: const Value<String?>(''),
        draftActionAdvice: const Value<String?>(''),
        createdAt: DateTime.parse('2026-03-15T11:00:00.000'),
        updatedAt: DateTime.parse('2026-03-15T11:30:00.000'),
      ),
    );
    await database.insertIntakeMessage(
      IntakeMessagesCompanion.insert(
        id: 'm1',
        sessionId: 'draft-in',
        seq: 1,
        role: 'user',
        content: '范围内草稿',
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
        initialRawText: '范围外草稿',
        mergedRawText: const Value<String?>('范围外草稿'),
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HealthRecordListPage()),
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

    expect(find.text('范围内正式记录'), findsOneWidget);
    expect(find.text('范围外正式记录'), findsNothing);

    await tester.tap(find.text('草稿记录'));
    await tester.pumpAndSettle();
    expect(find.text('范围内草稿'), findsOneWidget);
    expect(find.text('范围外草稿'), findsNothing);

    await container
        .read(deleteHealthRecordControllerProvider.notifier)
        .deleteHealthRecord('record-in');
    await tester.pumpAndSettle();
    expect(await database.getHealthEventById('record-in'), isNull);

    await tester.tap(find.text('草稿记录'));
    await tester.pumpAndSettle();
    await container
        .read(deleteDraftSessionControllerProvider.notifier)
        .deleteDraftSession('draft-in');
    await tester.pumpAndSettle();
    expect(await database.getIntakeSessionById('draft-in'), isNull);
  });

  testWidgets('overflow delete on draft card stays on list page and succeeds', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertIntakeSession(
      IntakeSessionsCompanion.insert(
        id: 'draft-menu',
        healthEventId: const Value<String?>.absent(),
        eventTime: DateTime.parse('2026-03-15T11:00:00.000'),
        followUpModeSnapshot: true,
        status: 'awaiting_user_input',
        initialRawText: '用于菜单删除的草稿',
        mergedRawText: const Value<String?>('用于菜单删除的草稿'),
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
        content: '用于菜单删除的草稿',
        createdAt: DateTime.parse('2026-03-15T11:00:00.000'),
      ),
    );

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
      ProviderScope(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('草稿记录'));
    await tester.pumpAndSettle();

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
    expect(find.text('还没有健康记录'), findsOneWidget);
  });

  testWidgets(
    'overflow delete on draft card stays successful after async service gap',
    (WidgetTester tester) async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.insertIntakeSession(
        IntakeSessionsCompanion.insert(
          id: 'draft-delayed',
          healthEventId: const Value<String?>.absent(),
          eventTime: DateTime.parse('2026-03-15T11:00:00.000'),
          followUpModeSnapshot: true,
          status: 'awaiting_user_input',
          initialRawText: '用于异步删除回归的草稿',
          mergedRawText: const Value<String?>('用于异步删除回归的草稿'),
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
          id: 'draft-delayed-message',
          sessionId: 'draft-delayed',
          seq: 1,
          role: 'user',
          content: '用于异步删除回归的草稿',
          createdAt: DateTime.parse('2026-03-15T11:00:00.000'),
        ),
      );

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
        ProviderScope(
          overrides: <Override>[
            appDatabaseProvider.overrideWithValue(database),
            intakeServiceProvider.overrideWithValue(
              _DelayedDeleteIntakeService(database: database),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('草稿记录'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      expect(await database.getIntakeSessionById('draft-delayed'), isNull);
      expect(find.text('草稿记录已删除。'), findsOneWidget);
      expect(find.text('删除失败，请稍后重试。'), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/records',
      );
      expect(find.text('还没有健康记录'), findsOneWidget);
    },
  );
  testWidgets('back on root records page falls back to home', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final GoRouter router = GoRouter(
      initialLocation: '/records',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Center(child: Text('home'))),
        ),
        GoRoute(
          path: '/records',
          builder: (_, _) => const HealthRecordListPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
    expect(find.text('home'), findsOneWidget);
  });
}

class _DelayedDeleteIntakeService extends IntakeService {
  _DelayedDeleteIntakeService({required super.database})
    : super(
        aiIntakeService: _NoopAiIntakeService(),
        intakeAttachmentStorage: const IntakeAttachmentStorage(),
        healthRecordAttachmentStorage: const HealthRecordAttachmentStorage(),
      );

  @override
  Future<void> hardDeleteDraftSession(String sessionId) async {
    await super.hardDeleteDraftSession(sessionId);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _NoopAiIntakeService implements AiIntakeService {
  @override
  Future<IntakeResponse> submitIntake({
    required bool followUpMode,
    required bool forceFinalize,
    required DateTime eventTime,
    required List<IntakeRequestMessage> messages,
  }) {
    throw UnimplementedError();
  }
}
