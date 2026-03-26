import 'package:ai_case_assistant/core/network/dio_provider.dart';
import 'package:ai_case_assistant/features/intake/data/remote/remote_ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<AiIntakeService> aiIntakeServiceProvider =
    Provider<AiIntakeService>((Ref ref) {
      return RemoteAiIntakeService(dio: ref.watch(dioProvider));
    });
