import 'dart:developer' as developer;

import 'package:ai_case_assistant/features/ai/data/remote/event_time_formatter.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:dio/dio.dart';

class RemoteAiIntakeService implements AiIntakeService {
  RemoteAiIntakeService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<IntakeResponse> submitIntake({
    required bool followUpMode,
    required bool forceFinalize,
    required DateTime eventTime,
    required List<IntakeRequestMessage> messages,
  }) async {
    if (messages.isEmpty) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidRequestPayload,
        message: '追问消息不能为空。',
      );
    }

    final Map<String, dynamic> requestPayload = <String, dynamic>{
      'followUpMode': followUpMode,
      'forceFinalize': forceFinalize,
      'eventTime': formatEventTimeForApi(eventTime),
      'messages': messages
          .map((IntakeRequestMessage item) => item.toJson())
          .toList(),
    };

    try {
      developer.log(
        'POST /ai/intake messageCount=${messages.length} followUpMode=$followUpMode forceFinalize=$forceFinalize',
        name: 'RemoteAiIntakeService',
      );
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/ai/intake',
        data: requestPayload,
      );
      final dynamic responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw const AiIntakeException(
          type: AiIntakeExceptionType.invalidResponsePayload,
          message: '追问结果无效，请稍后重试。',
        );
      }

      final IntakeResponseStatus status = _readStatus(responseData['status']);
      final Map<String, dynamic> draftPayload = _readDraftPayload(
        responseData['draft'],
      );
      final IntakeDraft draft = IntakeDraft(
        mergedRawText: _readRequiredString(draftPayload['mergedRawText']),
        symptomSummary: _readRequiredString(draftPayload['symptomSummary']),
        notes: _readRequiredString(draftPayload['notes']),
        actionAdvice: _readRequiredString(draftPayload['actionAdvice']),
      );

      if (status == IntakeResponseStatus.needsFollowup) {
        return IntakeResponse(
          status: status,
          question: _readRequiredString(responseData['question']),
          draft: draft,
        );
      }

      if (responseData['question'] != null) {
        throw const AiIntakeException(
          type: AiIntakeExceptionType.invalidResponsePayload,
          message: '追问结果无效，请稍后重试。',
        );
      }

      return IntakeResponse(status: status, question: null, draft: draft);
    } on AiIntakeException {
      rethrow;
    } on DioException catch (exception) {
      throw _mapDioException(exception);
    } catch (_) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.unknown,
        message: '追问失败，请稍后重试。',
      );
    }
  }

  IntakeResponseStatus _readStatus(dynamic value) {
    if (value is! String) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidResponsePayload,
        message: '追问结果无效，请稍后重试。',
      );
    }

    try {
      return IntakeResponseStatus.fromWireValue(value);
    } on ArgumentError {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidResponsePayload,
        message: '追问结果无效，请稍后重试。',
      );
    }
  }

  Map<String, dynamic> _readDraftPayload(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidResponsePayload,
        message: '追问结果无效，请稍后重试。',
      );
    }

    return value;
  }

  String _readRequiredString(dynamic value) {
    if (value is! String) {
      throw const AiIntakeException(
        type: AiIntakeExceptionType.invalidResponsePayload,
        message: '追问结果无效，请稍后重试。',
      );
    }

    return value.trim();
  }

  AiIntakeException _mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const AiIntakeException(
          type: AiIntakeExceptionType.network,
          message: '网络连接异常，请检查后重试。',
        );
      case DioExceptionType.badResponse:
        return AiIntakeException(
          type: AiIntakeExceptionType.upstreamHttpError,
          message: 'AI 服务暂时不可用，请稍后重试。',
          statusCode: exception.response?.statusCode,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const AiIntakeException(
          type: AiIntakeExceptionType.unknown,
          message: '追问失败，请稍后重试。',
        );
    }
  }
}
