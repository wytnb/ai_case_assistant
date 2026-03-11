import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_case_assistant/app/app.dart';

void main() {
  testWidgets('App shows home entry actions', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('AI 健康病例助手'), findsWidgets);
    expect(find.text('进入健康记录列表'), findsOneWidget);
    expect(find.text('进入新增记录'), findsOneWidget);
    expect(find.text('进入报告页'), findsOneWidget);
  });
}
