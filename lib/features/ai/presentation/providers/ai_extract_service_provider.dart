import 'package:ai_case_assistant/features/ai/data/mock/mock_ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AiExtractService> aiExtractServiceProvider =
    Provider<AiExtractService>((Ref ref) {
      return const MockAiExtractService();
    });
