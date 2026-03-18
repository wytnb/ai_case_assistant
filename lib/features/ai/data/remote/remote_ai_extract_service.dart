import 'dart:developer' as developer;

import 'package:ai_case_assistant/core/constants/health_record_limits.dart';
import 'package:ai_case_assistant/features/ai/data/remote/event_time_formatter.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:dio/dio.dart';

class RemoteAiExtractService implements AiExtractService {
  RemoteAiExtractService({required Dio dio}) : _dio = dio;

  static const int _summaryMaxLength = 36;
  final Dio _dio;

  @override
  Future<AiExtractResult> extractFromRawText({
    required String rawText,
    required DateTime eventTime,
  }) async {
    final String normalizedRawText = rawText.trim();
    final String formattedEventTime = formatEventTimeForApi(eventTime);
    _validateRawText(normalizedRawText);

    try {
      developer.log(
        'POST /ai/extract rawTextLength=${normalizedRawText.length} eventTime=$formattedEventTime',
        name: 'RemoteAiExtractService',
      );
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/ai/extract',
        data: <String, String>{
          'rawText': normalizedRawText,
          'eventTime': formattedEventTime,
        },
      );

      final dynamic responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        developer.log(
          'POST /ai/extract invalidResponse payloadType=${responseData.runtimeType}',
          name: 'RemoteAiExtractService',
        );
        throw const AiExtractException(
          type: AiExtractExceptionType.invalidResponsePayload,
          message: '提取结果无效，请稍后重试。',
        );
      }

      final String? remoteSymptomSummary = _readValidText(
        responseData['symptomSummary'],
      );
      final String symptomSummary =
          remoteSymptomSummary ??
          _buildFallbackSymptomSummary(normalizedRawText);

      developer.log(
        'POST /ai/extract success summaryLength=${symptomSummary.length} notesLength=${_safeTextLength(responseData['notes'])}',
        name: 'RemoteAiExtractService',
      );

      return AiExtractResult(
        symptomSummary: symptomSummary,
        notes: _readValidText(responseData['notes']),
      );
    } on AiExtractException {
      rethrow;
    } on DioException catch (exception) {
      developer.log(
        'POST /ai/extract dioFailure type=${exception.type} statusCode=${exception.response?.statusCode} '
        'message=${exception.message} error=${exception.error}',
        name: 'RemoteAiExtractService',
        error: exception,
        stackTrace: exception.stackTrace,
      );
      throw _mapDioException(exception);
    } catch (error, stackTrace) {
      developer.log(
        'POST /ai/extract unexpectedFailure type=${error.runtimeType} message=$error',
        name: 'RemoteAiExtractService',
        error: error,
        stackTrace: stackTrace,
      );
      throw const AiExtractException(
        type: AiExtractExceptionType.unknown,
        message: '提取失败，请稍后重试。',
      );
    }
  }

  String? _readValidText(dynamic value) {
    if (value is! String) {
      return null;
    }

    final String normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }

  String _buildFallbackSymptomSummary(String rawText) {
    final String firstSegment = rawText
        .split(RegExp(r'[。！？?!]+'))
        .map((String segment) => segment.trim())
        .firstWhere(
          (String segment) => segment.isNotEmpty,
          orElse: () => rawText,
        );
    return _truncate(firstSegment, _summaryMaxLength);
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}...';
  }

  void _validateRawText(String normalizedRawText) {
    if (normalizedRawText.isEmpty) {
      throw const AiExtractException(
        type: AiExtractExceptionType.invalidRequestPayload,
        message: '请输入原始描述',
      );
    }

    if (normalizedRawText.length > healthRecordRawTextMaxLength) {
      throw const AiExtractException(
        type: AiExtractExceptionType.invalidRequestPayload,
        message: '原始描述不能超过1000字',
      );
    }
  }

  AiExtractException _mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const AiExtractException(
          type: AiExtractExceptionType.network,
          message: '网络连接异常，请检查后重试。',
        );
      case DioExceptionType.badResponse:
        return AiExtractException(
          type: AiExtractExceptionType.upstreamHttpError,
          message: 'AI 服务暂时不可用，请稍后重试。',
          statusCode: exception.response?.statusCode,
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const AiExtractException(
          type: AiExtractExceptionType.unknown,
          message: '提取失败，请稍后重试。',
        );
    }
  }

  int _safeTextLength(dynamic value) {
    if (value is! String) {
      return -1;
    }

    return value.trim().length;
  }
}
