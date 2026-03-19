import 'dart:io';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/data/local/intake_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/presentation/pages/intake_page.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('submitting another reply finalizes and goes to detail page', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await _seedAwaitingSession(database);
    final FakeAiIntakeService aiIntakeService = FakeAiIntakeService()
      ..enqueue(
        const IntakeResponse(
          status: IntakeResponseStatus.finalResult,
          question: null,
          draft: IntakeDraft(
            mergedRawText: 'updated raw text',
            symptomSummary: 'updated summary',
            notes: '',
            actionAdvice: 'keep resting',
          ),
        ),
      );
    final TestIntakeAttachmentStorage intakeStorage =
        TestIntakeAttachmentStorage();
    final TestHealthRecordAttachmentStorage healthStorage =
        TestHealthRecordAttachmentStorage();
    addTearDown(intakeStorage.dispose);
    addTearDown(healthStorage.dispose);
    final IntakeService service = IntakeService(
      database: database,
      aiIntakeService: aiIntakeService,
      intakeAttachmentStorage: intakeStorage,
      healthRecordAttachmentStorage: healthStorage,
    );

    await _pumpIntakePage(tester, database: database, intakeService: service);
    await tester.enterText(find.byType(TextField), 'I added more details');
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsOneWidget);
    expect(
      (await database.getAllHealthEvents()).single.actionAdvice,
      'keep resting',
    );
  });

  testWidgets('force finalize marks session finalized_by_force', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await _seedAwaitingSession(database);
    final FakeAiIntakeService aiIntakeService = FakeAiIntakeService()
      ..enqueue(
        const IntakeResponse(
          status: IntakeResponseStatus.finalResult,
          question: null,
          draft: IntakeDraft(
            mergedRawText: 'forced final raw text',
            symptomSummary: 'summary',
            notes: '',
            actionAdvice: '',
          ),
        ),
      );
    final TestIntakeAttachmentStorage intakeStorage =
        TestIntakeAttachmentStorage();
    final TestHealthRecordAttachmentStorage healthStorage =
        TestHealthRecordAttachmentStorage();
    addTearDown(intakeStorage.dispose);
    addTearDown(healthStorage.dispose);
    final IntakeService service = IntakeService(
      database: database,
      aiIntakeService: aiIntakeService,
      intakeAttachmentStorage: intakeStorage,
      healthRecordAttachmentStorage: healthStorage,
    );

    await _pumpIntakePage(tester, database: database, intakeService: service);
    await tester.tap(find.text('退出追问，生成最终记录'));
    await tester.pumpAndSettle();

    final IntakeSession? session = await database.getIntakeSessionById(
      'session-1',
    );
    expect(session!.status, 'finalized_by_force');
  });

  testWidgets('questioning session auto-replays on open', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DateTime now = DateTime.parse('2026-03-19T10:00:00.000');
    await database.insertIntakeSession(
      IntakeSessionsCompanion.insert(
        id: 'session-1',
        healthEventId: const Value<String?>.absent(),
        eventTime: now,
        followUpModeSnapshot: true,
        status: 'questioning',
        initialRawText: 'initial description',
        mergedRawText: const Value<String?>('old merged text'),
        latestQuestion: const Value<String?>('previous question'),
        draftSymptomSummary: const Value<String?>('old summary'),
        draftNotes: const Value<String?>(''),
        draftActionAdvice: const Value<String?>(''),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.insertIntakeMessage(
      IntakeMessagesCompanion.insert(
        id: 'm1',
        sessionId: 'session-1',
        seq: 1,
        role: 'user',
        content: 'initial description',
        createdAt: now,
      ),
    );
    final FakeAiIntakeService aiIntakeService = FakeAiIntakeService()
      ..enqueue(
        const IntakeResponse(
          status: IntakeResponseStatus.needsFollowup,
          question: 'Could you share how long it lasted?',
          draft: IntakeDraft(
            mergedRawText: 'new merged text',
            symptomSummary: 'new summary',
            notes: '',
            actionAdvice: '',
          ),
        ),
      );
    final TestIntakeAttachmentStorage intakeStorage =
        TestIntakeAttachmentStorage();
    final TestHealthRecordAttachmentStorage healthStorage =
        TestHealthRecordAttachmentStorage();
    addTearDown(intakeStorage.dispose);
    addTearDown(healthStorage.dispose);
    final IntakeService service = IntakeService(
      database: database,
      aiIntakeService: aiIntakeService,
      intakeAttachmentStorage: intakeStorage,
      healthRecordAttachmentStorage: healthStorage,
    );

    await _pumpIntakePage(tester, database: database, intakeService: service);
    await tester.pumpAndSettle();

    expect(find.text('Could you share how long it lasted?'), findsNWidgets(2));
    expect(
      (await database.getIntakeSessionById('session-1'))!.status,
      'awaiting_user_input',
    );
  });
}

Future<void> _seedAwaitingSession(AppDatabase database) async {
  final DateTime now = DateTime.parse('2026-03-19T10:00:00.000');
  await database.insertIntakeSession(
    IntakeSessionsCompanion.insert(
      id: 'session-1',
      healthEventId: const Value<String?>.absent(),
      eventTime: now,
      followUpModeSnapshot: true,
      status: 'awaiting_user_input',
      initialRawText: 'initial description',
      mergedRawText: const Value<String?>('merged text'),
      latestQuestion: const Value<String?>('Did you have a fever?'),
      draftSymptomSummary: const Value<String?>('follow-up summary'),
      draftNotes: const Value<String?>(''),
      draftActionAdvice: const Value<String?>(''),
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.insertIntakeMessage(
    IntakeMessagesCompanion.insert(
      id: 'm1',
      sessionId: 'session-1',
      seq: 1,
      role: 'user',
      content: 'initial description',
      createdAt: now,
    ),
  );
  await database.insertIntakeMessage(
    IntakeMessagesCompanion.insert(
      id: 'm2',
      sessionId: 'session-1',
      seq: 2,
      role: 'assistant',
      content: 'Did you have a fever?',
      createdAt: now,
    ),
  );
}

Future<void> _pumpIntakePage(
  WidgetTester tester, {
  required AppDatabase database,
  required IntakeService intakeService,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: '/intake/session-1',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: Text('home'))),
        routes: <RouteBase>[
          GoRoute(
            path: 'intake/:id',
            builder: (_, GoRouterState state) =>
                IntakePage(sessionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'records/:id',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('detail'))),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        intakeServiceProvider.overrideWithValue(intakeService),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class FakeAiIntakeService implements AiIntakeService {
  final List<IntakeResponse> _responses = <IntakeResponse>[];

  void enqueue(IntakeResponse response) {
    _responses.add(response);
  }

  @override
  Future<IntakeResponse> submitIntake({
    required bool followUpMode,
    required bool forceFinalize,
    required DateTime eventTime,
    required List<IntakeRequestMessage> messages,
  }) async {
    return _responses.removeAt(0);
  }
}

class TestIntakeAttachmentStorage extends IntakeAttachmentStorage {
  TestIntakeAttachmentStorage()
    : _root = Directory.systemTemp.createTempSync('intake-page-intake');

  final Directory _root;

  Future<void> dispose() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }
}

class TestHealthRecordAttachmentStorage extends HealthRecordAttachmentStorage {
  TestHealthRecordAttachmentStorage()
    : _root = Directory.systemTemp.createTempSync('intake-page-health');

  final Directory _root;

  Future<void> dispose() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }
}
