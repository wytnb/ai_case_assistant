import 'dart:async';
import 'dart:io';

import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_report_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RemoteAiReportService implements AiReportService {
  RemoteAiReportService({required Dio dio}) : _dio = dio;

  static const Duration _reportConnectTimeout = Duration(seconds: 20);
  static const Duration _reportSendTimeout = Duration(seconds: 20);
  static const Duration _reportReceiveTimeout = Duration(seconds: 60);
  final Dio _dio;

  @override
  Future<AiReportResult> generateReport({
    required String reportType,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<AiReportEvent> events,
  }) async {
    final String normalizedReportType = reportType.trim();
    if (normalizedReportType.isEmpty || rangeEnd.isBefore(rangeStart)) {
      throw const AiReportException(
        type: AiReportExceptionType.invalidRequestPayload,
        message: '报告生成参数无效，请稍后重试。',
      );
    }

    try {
      final Map<String, dynamic> requestPayload = <String, dynamic>{
        'reportType': normalizedReportType,
        'rangeStart': rangeStart.toIso8601String(),
        'rangeEnd': rangeEnd.toIso8601String(),
        'events': events.map(_toEventPayload).toList(),
      };
      final int rawTextTotalLength = events.fold<int>(
        0,
        (int total, AiReportEvent event) =>
            total + (event.rawText?.length ?? 0),
      );
      debugPrint(
        '[AI_REPORT] request: reportType=$normalizedReportType, rangeStart=${requestPayload['rangeStart']}, '
        'rangeEnd=${requestPayload['rangeEnd']}, eventCount=${events.length}, '
        'rawTextTotalLength=$rawTextTotalLength',
      );
      debugPrint(
        '[AI_REPORT] timeout override: connect=${_reportConnectTimeout.inSeconds}s, '
        'send=${_reportSendTimeout.inSeconds}s, receive=${_reportReceiveTimeout.inSeconds}s',
      );

      final RequestOptions requestOptions = Options(method: 'POST')
          .compose(_dio.options, '/ai/report', data: requestPayload)
          .copyWith(
            connectTimeout: _reportConnectTimeout,
            sendTimeout: _reportSendTimeout,
            receiveTimeout: _reportReceiveTimeout,
          );
      final Response<dynamic> response = await _dio.fetch<dynamic>(
        requestOptions,
      );

      final dynamic responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        debugPrint(
          '[AI_REPORT] response: titleLength=${_safeTextLength(responseData['title'])}, '
          'summaryLength=${_safeTextLength(responseData['summary'])}, '
          'adviceCount=${_safeListLength(responseData['advice'])}, '
          'markdownLength=${_safeTextLength(responseData['markdown'])}',
        );
      } else {
        debugPrint(
          '[AI_REPORT] response: invalid payload type=${responseData.runtimeType}',
        );
      }

      if (responseData is! Map<String, dynamic>) {
        throw const AiReportException(
          type: AiReportExceptionType.invalidResponsePayload,
          message: '报告结果无效，请稍后重试。',
        );
      }

      final String title = _readRequiredText(responseData['title']);
      final String summary = _readRequiredText(responseData['summary']);
      final String markdown = _readRequiredText(responseData['markdown']);
      final List<String> advice = _readAdvice(responseData['advice']);

      return AiReportResult(
        title: title,
        summary: summary,
        advice: advice,
        markdown: markdown,
      );
    } on AiReportException catch (exception) {
      debugPrint(
        '[AI_REPORT] exception: type=${exception.type}, message=${exception.message}',
      );
      rethrow;
    } on DioException catch (exception) {
      debugPrint(
        '[AI_REPORT] dio exception raw: '
        'type=${exception.type}, '
        'statusCode=${exception.response?.statusCode}, '
        'message=${exception.message}, '
        'error=${exception.error}',
      );
      debugPrint(
        '[AI_REPORT] dio exception request: '
        'path=${exception.requestOptions.path}, '
        'connectTimeout=${exception.requestOptions.connectTimeout}, '
        'sendTimeout=${exception.requestOptions.sendTimeout}, '
        'receiveTimeout=${exception.requestOptions.receiveTimeout}',
      );
      final AiReportException mappedException = _mapDioException(exception);
      debugPrint(
        '[AI_REPORT] exception: type=${mappedException.type}, message=${mappedException.message}',
      );
      throw mappedException;
    } catch (error) {
      const AiReportException mappedException = AiReportException(
        type: AiReportExceptionType.unknown,
        message: '报告生成失败，请稍后重试。',
      );
      debugPrint(
        '[AI_REPORT] exception: type=${error.runtimeType}, message=$error',
      );
      throw mappedException;
    }
  }

  Map<String, dynamic> _toEventPayload(AiReportEvent event) {
    return <String, dynamic>{
      'id': event.id,
      'eventStartTime': event.eventStartTime.toIso8601String(),
      'eventEndTime': event.eventEndTime.toIso8601String(),
      'sourceType': event.sourceType,
      'rawText': event.rawText,
      'symptomSummary': event.symptomSummary,
      'notes': event.notes,
    };
  }

  String _readRequiredText(dynamic value) {
    if (value is! String) {
      throw const AiReportException(
        type: AiReportExceptionType.invalidResponsePayload,
        message: '报告结果无效，请稍后重试。',
      );
    }

    final String normalized = value.trim();
    if (normalized.isEmpty) {
      throw const AiReportException(
        type: AiReportExceptionType.invalidResponsePayload,
        message: '报告结果无效，请稍后重试。',
      );
    }

    return normalized;
  }

  List<String> _readAdvice(dynamic value) {
    if (value is! List<dynamic>) {
      throw const AiReportException(
        type: AiReportExceptionType.invalidResponsePayload,
        message: '报告结果无效，请稍后重试。',
      );
    }

    final List<String> parsedAdvice = value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
    if (parsedAdvice.length != value.length) {
      throw const AiReportException(
        type: AiReportExceptionType.invalidResponsePayload,
        message: '报告结果无效，请稍后重试。',
      );
    }

    return parsedAdvice;
  }

  AiReportException _mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AiReportException(
          type: AiReportExceptionType.timeout,
          message: '请求超时，请稍后重试。',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const AiReportException(
          type: AiReportExceptionType.network,
          message: '网络连接异常，请检查后重试。',
        );
      case DioExceptionType.badResponse:
        return AiReportException(
          type: AiReportExceptionType.upstreamHttpError,
          message: 'AI 服务暂时不可用，请稍后重试。',
          statusCode: exception.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const AiReportException(
          type: AiReportExceptionType.unknown,
          message: '请求已取消，请重试。',
        );
      case DioExceptionType.unknown:
        if (exception.error is TimeoutException) {
          return const AiReportException(
            type: AiReportExceptionType.timeout,
            message: '请求超时，请稍后重试。',
          );
        }
        if (exception.error is SocketException) {
          return const AiReportException(
            type: AiReportExceptionType.network,
            message: '网络连接异常，请检查后重试。',
          );
        }
        return const AiReportException(
          type: AiReportExceptionType.unknown,
          message: '报告生成失败，请稍后重试。',
        );
    }
  }

  int _safeTextLength(dynamic value) {
    if (value is! String) {
      return -1;
    }

    return value.trim().length;
  }

  int _safeListLength(dynamic value) {
    if (value is! List<dynamic>) {
      return -1;
    }

    return value.length;
  }
}
