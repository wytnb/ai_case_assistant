import 'package:ai_case_assistant/app/presentation/pages/home_page.dart';
import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:ai_case_assistant/features/settings/data/settings_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first launch requires checking consent before continue', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SettingsRepository settingsRepository = SettingsRepository(
      database: database,
    );

    await tester.pumpWidget(_buildApp(database));
    await _pumpHomePage(tester);

    expect(find.text('《AI 健康病例助手使用说明与免责提示》'), findsOneWidget);

    final Finder continueFinder = find.widgetWithText(FilledButton, '同意并继续');
    expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);

    await tester.scrollUntilVisible(find.byType(Checkbox), 300);
    await tester.tap(find.byType(Checkbox));
    await _pumpHomePage(tester);
    expect(tester.widget<FilledButton>(continueFinder).onPressed, isNotNull);

    await tester.tap(continueFinder);
    await _pumpHomePage(tester);
    for (int i = 0; i < 8; i++) {
      if (find.text('《AI 健康病例助手使用说明与免责提示》').evaluate().isEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('《AI 健康病例助手使用说明与免责提示》'), findsNothing);
    expect(await settingsRepository.getFirstUseDisclaimerAccepted(), isTrue);
  });

  testWidgets('does not show disclaimer dialog when consent already accepted', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final SettingsRepository settingsRepository = SettingsRepository(
      database: database,
    );
    await settingsRepository.setFirstUseDisclaimerAccepted(true);

    await tester.pumpWidget(_buildApp(database));
    await _pumpHomePage(tester);

    expect(find.text('《AI 健康病例助手使用说明与免责提示》'), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('invalid consent setting falls back to not accepted', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DateTime now = DateTime.parse('2026-03-19T10:00:00.000');
    await database.upsertAppSetting(
      AppSettingsCompanion(
        key: const Value<String>(
          SettingsRepository.firstUseDisclaimerAcceptedKey,
        ),
        valueType: Value<String>(AppSettingValueType.stringType.storageValue),
        boolValue: const Value<bool?>.absent(),
        intValue: const Value<int?>.absent(),
        doubleValue: const Value<double?>.absent(),
        stringValue: const Value<String?>('invalid'),
        jsonValue: const Value<String?>.absent(),
        createdAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
      ),
    );

    await tester.pumpWidget(_buildApp(database));
    await _pumpHomePage(tester);

    expect(find.text('《AI 健康病例助手使用说明与免责提示》'), findsOneWidget);
    final Finder continueFinder = find.widgetWithText(FilledButton, '同意并继续');
    expect(tester.widget<FilledButton>(continueFinder).onPressed, isNull);
  });
}

Widget _buildApp(AppDatabase database) {
  return ProviderScope(
    overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
    child: const MaterialApp(home: HomePage()),
  );
}

Future<void> _pumpHomePage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
}
