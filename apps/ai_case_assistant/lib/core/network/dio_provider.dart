import 'package:ai_case_assistant/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.aiApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const <String, String>{'Accept': Headers.jsonContentType},
    ),
  );
});
