import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';
import 'package:dio/dio.dart';

class RemoteAiExtractService implements AiExtractService {
  RemoteAiExtractService({required Dio dio}) : _dio = dio;

  static const int _summaryMaxLength = 36;
  static const int _notesPreviewMaxLength = 60;
  final Dio _dio;

  @override
  Future<AiExtractResult> extractFromRawText({required String rawText}) async {
    final String normalizedRawText = rawText.trim();
    if (normalizedRawText.isEmpty) {
      throw const AiExtractException(
        type: AiExtractExceptionType.invalidResponsePayload,
        message: '提取结果无效，请稍后重试。',
      );
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/ai/extract',
        data: <String, String>{'rawText': normalizedRawText},
      );

      final dynamic responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
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
      final String notes =
          _readValidText(responseData['notes']) ??
          _buildFallbackNotes(
            rawText: normalizedRawText,
            symptomSummary: symptomSummary,
          );

      return AiExtractResult(symptomSummary: symptomSummary, notes: notes);
    } on AiExtractException {
      rethrow;
    } on DioException catch (exception) {
      throw _mapDioException(exception);
    } catch (_) {
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
        .split(RegExp(r'[。！？!?；;]+'))
        .map((String segment) => segment.trim())
        .firstWhere(
          (String segment) => segment.isNotEmpty,
          orElse: () => rawText,
        );
    return _truncate(firstSegment, _summaryMaxLength);
  }

  String _buildFallbackNotes({
    required String rawText,
    required String symptomSummary,
  }) {
    final String preview = _truncate(rawText, _notesPreviewMaxLength);
    return 'AI 提取已完成。当前摘要：$symptomSummary。原始描述已保留：$preview';
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}...';
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
}
