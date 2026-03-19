import 'package:ai_case_assistant/app/presentation/pages/home_page.dart';
import 'package:ai_case_assistant/core/database/app_database.dart';
import 'package:ai_case_assistant/core/database/app_database_provider.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('follow-up mode switch persists after rebuild', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    Widget buildApp() {
      return ProviderScope(
        overrides: <Override>[appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: HomePage()),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final Finder switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    await tester.tap(switchFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
  });
}
