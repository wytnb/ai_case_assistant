import 'package:ai_case_assistant/core/config/app_config.dart';
import 'package:ai_case_assistant/core/network/dio_provider.dart';
import 'package:ai_case_assistant/features/ai/data/mock/mock_ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AiExtractService> aiExtractServiceProvider =
    Provider<AiExtractService>((Ref ref) {
      if (AppConfig.useMockAiExtract) {
        return const MockAiExtractService();
      }

      return RemoteAiExtractService(dio: ref.watch(dioProvider));
    });
