import 'package:ai_case_assistant/core/network/dio_provider.dart';
import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_report_service.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AiReportService> aiReportServiceProvider =
    Provider<AiReportService>((Ref ref) {
      return RemoteAiReportService(dio: ref.watch(dioProvider));
    });
