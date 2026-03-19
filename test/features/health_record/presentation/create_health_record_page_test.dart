import 'dart:io';

import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/health_record/data/local/health_record_attachment_storage.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/create_health_record_page.dart';
import 'package:ai_case_assistant/features/intake/data/local/intake_attachment_storage.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/presentation/providers/intake_providers.dart';
import 'package:ai_case_assistant/features/settings/data/settings_repository.dart';
import 'package:ai_case_assistant/features/settings/presentation/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('followUpMode=false direct-final goes to record detail', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SettingsRepository settingsRepository = SettingsRepository(
      database: database,
    );
    await settingsRepository.setFollowUpModeEnabled(false);
    final FakeAiIntakeService aiIntakeService = FakeAiIntakeService()
      ..enqueue(
        const IntakeResponse(
          status: IntakeResponseStatus.finalResult,
          question: null,
          draft: IntakeDraft(
            mergedRawText: '合并描述',
            symptomSummary: '摘要',
            notes: '',
            actionAdvice: '建议',
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

    await _pumpCreatePage(
      tester,
      database: database,
      settingsRepository: settingsRepository,
      intakeService: service,
    );
    await tester.enterText(find.byType(TextFormField), '喉咙痛两天');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final List<HealthEvent> records = await database.getAllHealthEvents();
    expect(records, hasLength(1));
    expect(find.text('detail'), findsOneWidget);
  });

  testWidgets('followUpMode=true and needs_followup goes to intake page', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SettingsRepository settingsRepository = SettingsRepository(
      database: database,
    );
    await settingsRepository.setFollowUpModeEnabled(true);
    final FakeAiIntakeService aiIntakeService = FakeAiIntakeService()
      ..enqueue(
        const IntakeResponse(
          status: IntakeResponseStatus.needsFollowup,
          question: '有没有发烧？',
          draft: IntakeDraft(
            mergedRawText: '喉咙痛两天',
            symptomSummary: '喉咙痛',
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

    await _pumpCreatePage(
      tester,
      database: database,
      settingsRepository: settingsRepository,
      intakeService: service,
    );
    await tester.enterText(find.byType(TextFormField), '喉咙痛两天');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final List<HealthEvent> records = await database.getAllHealthEvents();
    expect(records, isEmpty);
    expect(find.text('intake'), findsOneWidget);
  });

  testWidgets(
    'shows validation error and does not submit when rawText is 1001 characters',
    (WidgetTester tester) async {
      final AppDatabase database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final SettingsRepository settingsRepository = SettingsRepository(
        database: database,
      );
      final TestIntakeAttachmentStorage intakeStorage =
          TestIntakeAttachmentStorage();
      final TestHealthRecordAttachmentStorage healthStorage =
          TestHealthRecordAttachmentStorage();
      addTearDown(intakeStorage.dispose);
      addTearDown(healthStorage.dispose);
      final IntakeService service = IntakeService(
        database: database,
        aiIntakeService: FakeAiIntakeService(),
        intakeAttachmentStorage: intakeStorage,
        healthRecordAttachmentStorage: healthStorage,
      );
      final String rawText = List<String>.filled(1001, 'a').join();

      await _pumpCreatePage(
        tester,
        database: database,
        settingsRepository: settingsRepository,
        intakeService: service,
      );
      await tester.enterText(find.byType(TextFormField), rawText);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('原始描述不能超过1000字'), findsOneWidget);
      expect(await database.getAllHealthEvents(), isEmpty);
    },
  );

  testWidgets('shows intake error message returned by service', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SettingsRepository settingsRepository = SettingsRepository(
      database: database,
    );
    final TestIntakeAttachmentStorage intakeStorage =
        TestIntakeAttachmentStorage();
    final TestHealthRecordAttachmentStorage healthStorage =
        TestHealthRecordAttachmentStorage();
    addTearDown(intakeStorage.dispose);
    addTearDown(healthStorage.dispose);
    final IntakeService service = IntakeService(
      database: database,
      aiIntakeService: const ThrowingAiIntakeService(
        AiIntakeException(
          type: AiIntakeExceptionType.network,
          message: 'network unavailable',
        ),
      ),
      intakeAttachmentStorage: intakeStorage,
      healthRecordAttachmentStorage: healthStorage,
    );

    await _pumpCreatePage(
      tester,
      database: database,
      settingsRepository: settingsRepository,
      intakeService: service,
    );
    await tester.enterText(find.byType(TextFormField), 'test raw text');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('network unavailable'), findsWidgets);
  });
}

Future<void> _pumpCreatePage(
  WidgetTester tester, {
  required AppDatabase database,
  required SettingsRepository settingsRepository,
  required IntakeService intakeService,
}) async {
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
          GoRoute(
            path: 'records/:id',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('detail'))),
          ),
          GoRoute(
            path: 'intake/:id',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('intake'))),
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
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
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
    if (_responses.isEmpty) {
      throw StateError('No queued response');
    }
    return _responses.removeAt(0);
  }
}

class ThrowingAiIntakeService implements AiIntakeService {
  const ThrowingAiIntakeService(this.exception);

  final AiIntakeException exception;

  @override
  Future<IntakeResponse> submitIntake({
    required bool followUpMode,
    required bool forceFinalize,
    required DateTime eventTime,
    required List<IntakeRequestMessage> messages,
  }) async {
    throw exception;
  }
}

class TestIntakeAttachmentStorage extends IntakeAttachmentStorage {
  TestIntakeAttachmentStorage()
    : _root = Directory.systemTemp.createTempSync('create-page-intake');

  final Directory _root;

  @override
  Future<String> saveImageAttachment({
    required String sessionId,
    required String attachmentId,
    required String sourceFilePath,
  }) async {
    final Directory target = Directory('${_root.path}/$sessionId');
    await target.create(recursive: true);
    final File destination = File('${target.path}/$attachmentId.tmp');
    await File(sourceFilePath).copy(destination.path);
    return destination.path;
  }

  Future<void> dispose() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }
}

class TestHealthRecordAttachmentStorage extends HealthRecordAttachmentStorage {
  TestHealthRecordAttachmentStorage()
    : _root = Directory.systemTemp.createTempSync('create-page-health');

  final Directory _root;

  @override
  Future<String> saveImageAttachment({
    required String healthEventId,
    required String attachmentId,
    required String sourceFilePath,
  }) async {
    final Directory target = Directory('${_root.path}/$healthEventId');
    await target.create(recursive: true);
    final File destination = File('${target.path}/$attachmentId.final');
    await File(sourceFilePath).copy(destination.path);
    return destination.path;
  }

  Future<void> dispose() async {
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }
}
