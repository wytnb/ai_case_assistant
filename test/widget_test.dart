import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_case_assistant/app/app.dart';

void main() {
  testWidgets('App shows home entry actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('AI 健康病例助手'), findsOneWidget);
    expect(find.text('新增记录'), findsOneWidget);
    expect(find.text('记录列表'), findsOneWidget);
    expect(find.text('健康报告'), findsOneWidget);
  });
}
