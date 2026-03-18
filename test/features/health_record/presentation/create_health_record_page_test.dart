import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/create_health_record_page.dart';
import 'package:ai_case_assistant/features/health_record/presentation/providers/health_record_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('submits successfully when rawText is within 1000 characters', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final HealthRecordService service = HealthRecordService(
      database: database,
      aiExtractService: const _FakeAiExtractService(),
      attachmentStorage: const HealthRecordAttachmentStorage(),
    );

    await _pumpCreatePage(tester, service);
    await tester.enterText(find.byType(TextFormField), '喉咙痛两天');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final List<HealthEvent> records = await database.getAllHealthEvents();
    expect(records, hasLength(1));
    expect(records.single.rawText, '喉咙痛两天');
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('submits successfully when rawText is exactly 1000 characters', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final HealthRecordService service = HealthRecordService(
      database: database,
      aiExtractService: const _FakeAiExtractService(),
      attachmentStorage: const HealthRecordAttachmentStorage(),
    );
    final String rawText = List<String>.filled(1000, 'a').join();

    await _pumpCreatePage(tester, service);
    await tester.enterText(find.byType(TextFormField), rawText);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final List<HealthEvent> records = await database.getAllHealthEvents();
    expect(records, hasLength(1));
    expect(records.single.rawText, rawText);
  });

  testWidgets(
    'shows validation error and does not submit when rawText is 1001 characters',
    (WidgetTester tester) async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final HealthRecordService service = HealthRecordService(
        database: database,
        aiExtractService: const _FakeAiExtractService(),
        attachmentStorage: const HealthRecordAttachmentStorage(),
      );
      final String rawText = List<String>.filled(1001, 'a').join();

      await _pumpCreatePage(tester, service);
      await tester.enterText(find.byType(TextFormField), rawText);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      final List<HealthEvent> records = await database.getAllHealthEvents();
      expect(find.text('原始描述不能超过1000字'), findsOneWidget);
      expect(records, isEmpty);
    },
  );

  testWidgets('shows network error message returned by AI extract service', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const AiExtractException exception = AiExtractException(
      type: AiExtractExceptionType.network,
      message: 'network unavailable',
    );
    final HealthRecordService service = HealthRecordService(
      database: database,
      aiExtractService: const _ThrowingAiExtractService(exception),
      attachmentStorage: const HealthRecordAttachmentStorage(),
    );

    await _pumpCreatePage(tester, service);
    await tester.enterText(find.byType(TextFormField), 'test raw text');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text(exception.message), findsWidgets);
  });
}

Future<void> _pumpCreatePage(
  WidgetTester tester,
  HealthRecordService service,
) async {
  final GoRouter router = GoRouter(
    initialLocation: '/create',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Center(child: Text('home'))),
        routes: <RouteBase>[
          GoRoute(
            path: 'create',
            builder: (_, _) => const CreateHealthRecordPage(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        healthRecordServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAiExtractService implements AiExtractService {
  const _FakeAiExtractService();

  @override
  Future<AiExtractResult> extractFromRawText({
    required String rawText,
    required DateTime eventTime,
  }) async {
    return const AiExtractResult(
      symptomSummary: 'summary text',
      notes: null,
    );
  }
}

class _ThrowingAiExtractService implements AiExtractService {
  const _ThrowingAiExtractService(this.exception);

  final AiExtractException exception;

  @override
  Future<AiExtractResult> extractFromRawText({
    required String rawText,
    required DateTime eventTime,
  }) async {
    throw exception;
  }
}
