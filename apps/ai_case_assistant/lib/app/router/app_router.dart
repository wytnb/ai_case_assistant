import 'package:ai_case_assistant/app/router/records_navigation.dart';
import 'package:ai_case_assistant/app/presentation/pages/home_page.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/create_health_record_page.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_detail_page.dart';
import 'package:ai_case_assistant/features/health_record/presentation/pages/health_record_list_page.dart';
import 'package:ai_case_assistant/features/intake/presentation/pages/intake_page.dart';
import 'package:ai_case_assistant/features/report/presentation/pages/report_detail_page.dart';
import 'package:ai_case_assistant/features/report/presentation/pages/report_list_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/records',
      builder: (context, state) => HealthRecordListPage(
        initialTab: HealthRecordListTab.fromQueryValue(
          state.uri.queryParameters['tab'],
        ),
      ),
    ),
    GoRoute(
      path: '/records/new',
      builder: (context, state) => const CreateHealthRecordPage(),
    ),
    GoRoute(
      path: '/records/:id',
      builder: (context, state) =>
          HealthRecordDetailPage(healthRecordId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/intake/:id',
      builder: (context, state) =>
          IntakePage(sessionId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportListPage(),
    ),
    GoRoute(
      path: '/reports/:id',
      builder: (context, state) =>
          ReportDetailPage(reportId: state.pathParameters['id']!),
    ),
  ],
);
