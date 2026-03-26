import 'dart:convert';

import 'package:ai_case_assistant/core/config/app_config.dart';
import 'package:ai_case_assistant/features/ai/data/remote/event_time_formatter.dart';
import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_report_service.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_report_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:ai_case_assistant/features/intake/data/remote/remote_ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const bool _runRealAiApiTests = bool.fromEnvironment(
  'RUN_REAL_AI_API_TESTS',
  defaultValue: false,
);
const String _configuredAiApiBaseUrl = String.fromEnvironment(
  'AI_API_BASE_URL',
  defaultValue: AppConfig.aiApiBaseUrl,
);

void main() {
  final String? skipReason = _resolveSkipReason();

  group('Real AI API integration', () {
    group('/ai/intake', () {
      test('success case logs input and mapped final result', () async {
        final DateTime eventTime = DateTime.utc(2026, 3, 19, 2, 0);
        final List<IntakeRequestMessage> messages =
            const <IntakeRequestMessage>[
              IntakeRequestMessage(
                role: IntakeMessageRole.user,
                content: '喉咙痛两天，今天稍微好一些，没有继续补充更多信息。',
              ),
            ];
        final _RecordedDioClient client = _createRecordedDioClient();
        final RemoteAiIntakeService service = RemoteAiIntakeService(
          dio: client.dio,
        );

        final IntakeResponse result = await service.submitIntake(
          followUpMode: false,
          forceFinalize: false,
          eventTime: eventTime,
          messages: messages,
        );

        _logCase(
          caseId: 'intake-success-1',
          endpoint: '/ai/intake',
          requestBody: <String, dynamic>{
            'followUpMode': false,
            'forceFinalize': false,
            'eventTime': formatEventTimeForApi(eventTime),
            'messages': messages
                .map((IntakeRequestMessage item) => item.toJson())
                .toList(),
          },
          recorded: client.record,
          mappedResult: <String, dynamic>{
            'status': result.status.wireValue,
            'question': result.question,
            'draft': <String, dynamic>{
              'mergedRawText': result.draft.mergedRawText,
              'symptomSummary': result.draft.symptomSummary,
              'notes': result.draft.notes,
              'actionAdvice': result.draft.actionAdvice,
            },
          },
        );

        expect(result.status, IntakeResponseStatus.finalResult);
      }, skip: skipReason);

      test(
        'failure case logs actual raw response when messages is missing',
        () async {
          final Map<String, dynamic> input = <String, dynamic>{
            'followUpMode': true,
            'forceFinalize': false,
            'eventTime': '2026-03-19T10:00:00+08:00',
          };
          final Response<dynamic> response = await _postRaw(
            path: '/ai/intake',
            body: input,
          );

          _logRawResponse(
            caseId: 'intake-failure-1',
            endpoint: '/ai/intake',
            requestBody: input,
            response: response,
          );

          expect(_looksLikeIntakeSuccess(response.data), isFalse);
        },
        skip: skipReason,
      );
    });

    group('/ai/report', () {
      test('success case 1 logs input and actual mapped result', () async {
        final DateTime rangeStart = DateTime.parse('2026-03-10T00:00:00.000');
        final DateTime rangeEnd = DateTime.parse('2026-03-16T23:59:59.999');
        final List<AiReportEvent> events = <AiReportEvent>[
          AiReportEvent(
            id: 'real-report-event-1',
            eventTime: DateTime.utc(2026, 3, 15, 0),
            sourceType: 'text',
            rawText: '昨天晚上八点开始喉咙痛，到九点半左右最明显。',
            symptomSummary: '喉咙痛',
            notes: null,
          ),
        ];
        final _RecordedDioClient client = _createRecordedDioClient();
        final RemoteAiReportService service = RemoteAiReportService(
          dio: client.dio,
        );

        final result = await service.generateReport(
          reportType: 'week',
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          events: events,
        );

        _logCase(
          caseId: 'report-success-1',
          endpoint: '/ai/report',
          requestBody: <String, dynamic>{
            'reportType': 'week',
            'rangeStart': rangeStart.toIso8601String(),
            'rangeEnd': rangeEnd.toIso8601String(),
            'events': events.map(_reportEventToJson).toList(),
          },
          recorded: client.record,
          mappedResult: <String, dynamic>{
            'title': result.title,
            'summary': result.summary,
            'advice': result.advice,
            'markdown': result.markdown,
          },
        );

        expect(result.title.trim(), isNotEmpty);
        expect(result.summary.trim(), isNotEmpty);
        expect(result.markdown.trim(), isNotEmpty);
        expect(
          result.advice.every((String item) => item.trim().isNotEmpty),
          isTrue,
        );
      }, skip: skipReason);

      test('success case 2 logs input and actual mapped result', () async {
        final DateTime rangeStart = DateTime.parse('2026-03-01T00:00:00.000');
        final DateTime rangeEnd = DateTime.parse('2026-03-30T23:59:59.999');
        final List<AiReportEvent> events = <AiReportEvent>[
          AiReportEvent(
            id: 'real-report-event-2',
            eventTime: DateTime.utc(2026, 3, 11, 6),
            sourceType: 'text',
            rawText: '上周三下午两点开始头痛，持续到晚上七点。',
            symptomSummary: '头痛',
            notes: null,
          ),
          AiReportEvent(
            id: 'real-report-event-3',
            eventTime: DateTime.utc(2026, 3, 18, 1),
            sourceType: 'text',
            rawText: '今天早上九点开始胃胀，到中午缓解一些。',
            symptomSummary: '胃胀',
            notes: null,
          ),
        ];
        final _RecordedDioClient client = _createRecordedDioClient();
        final RemoteAiReportService service = RemoteAiReportService(
          dio: client.dio,
        );

        final result = await service.generateReport(
          reportType: 'month',
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          events: events,
        );

        _logCase(
          caseId: 'report-success-2',
          endpoint: '/ai/report',
          requestBody: <String, dynamic>{
            'reportType': 'month',
            'rangeStart': rangeStart.toIso8601String(),
            'rangeEnd': rangeEnd.toIso8601String(),
            'events': events.map(_reportEventToJson).toList(),
          },
          recorded: client.record,
          mappedResult: <String, dynamic>{
            'title': result.title,
            'summary': result.summary,
            'advice': result.advice,
            'markdown': result.markdown,
          },
        );

        expect(result.title.trim(), isNotEmpty);
        expect(result.summary.trim(), isNotEmpty);
        expect(result.markdown.trim(), isNotEmpty);
        expect(
          result.advice.every((String item) => item.trim().isNotEmpty),
          isTrue,
        );
      }, skip: skipReason);

      test(
        'failure case 1 logs actual raw response when reportType is empty',
        () async {
          final Map<String, dynamic> input = <String, dynamic>{
            'reportType': '',
            'rangeStart': '2026-03-10T00:00:00.000',
            'rangeEnd': '2026-03-16T23:59:59.999',
            'events': <Map<String, dynamic>>[],
          };
          final Response<dynamic> response = await _postRaw(
            path: '/ai/report',
            body: input,
          );

          _logRawResponse(
            caseId: 'report-failure-1',
            endpoint: '/ai/report',
            requestBody: input,
            response: response,
          );

          expect(_looksLikeReportSuccess(response.data), isFalse);
        },
        skip: skipReason,
      );

      test(
        'failure case 2 logs actual raw response when rangeEnd is earlier than rangeStart',
        () async {
          final Map<String, dynamic> input = <String, dynamic>{
            'reportType': 'week',
            'rangeStart': '2026-03-16T23:59:59.999',
            'rangeEnd': '2026-03-10T00:00:00.000',
            'events': <Map<String, dynamic>>[],
          };
          final Response<dynamic> response = await _postRaw(
            path: '/ai/report',
            body: input,
          );

          _logRawResponse(
            caseId: 'report-failure-2',
            endpoint: '/ai/report',
            requestBody: input,
            response: response,
          );

          expect(
            _looksLikeReportSuccess(response.data) == false ||
                _looksLikeEmptyReportFallback(response.data),
            isTrue,
          );
        },
        skip: skipReason,
      );
    });
  });
}

String? _resolveSkipReason() {
  if (!_runRealAiApiTests) {
    return 'Set RUN_REAL_AI_API_TESTS=true to run real AI API integration tests.';
  }

  if (_configuredAiApiBaseUrl.trim().isEmpty) {
    return 'AI_API_BASE_URL must be provided when running real AI API integration tests.';
  }

  return null;
}

_RecordedDioClient _createRecordedDioClient() {
  final _RecordedHttpInteraction record = _RecordedHttpInteraction();
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _configuredAiApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const <String, String>{'Accept': Headers.jsonContentType},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        record.path = options.path;
        record.requestBody = _normalizeForLog(options.data);
        handler.next(options);
      },
      onResponse:
          (Response<dynamic> response, ResponseInterceptorHandler handler) {
            record.statusCode = response.statusCode;
            record.responseBody = _normalizeForLog(response.data);
            handler.next(response);
          },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        record.statusCode = error.response?.statusCode;
        record.responseBody = _normalizeForLog(error.response?.data);
        handler.next(error);
      },
    ),
  );

  return _RecordedDioClient(dio: dio, record: record);
}

Future<Response<dynamic>> _postRaw({
  required String path,
  required Map<String, dynamic> body,
}) async {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _configuredAiApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const <String, String>{'Accept': Headers.jsonContentType},
      validateStatus: (_) => true,
    ),
  );

  return dio.post<dynamic>(path, data: body);
}

void _logCase({
  required String caseId,
  required String endpoint,
  required Object? requestBody,
  required _RecordedHttpInteraction recorded,
  required Object? mappedResult,
}) {
  debugPrintSynchronously('''
=== $caseId ===
endpoint: $endpoint
request:
${_prettyJson(requestBody)}
actualHttpPath: ${recorded.path}
actualHttpStatus: ${recorded.statusCode}
actualResponse:
${_prettyJson(recorded.responseBody)}
mappedResult:
${_prettyJson(mappedResult)}
''');
}

void _logRawResponse({
  required String caseId,
  required String endpoint,
  required Object? requestBody,
  required Response<dynamic> response,
}) {
  debugPrintSynchronously('''
=== $caseId ===
endpoint: $endpoint
request:
${_prettyJson(requestBody)}
actualHttpStatus: ${response.statusCode}
actualResponse:
${_prettyJson(_normalizeForLog(response.data))}
''');
}

Map<String, dynamic> _reportEventToJson(AiReportEvent event) {
  return <String, dynamic>{
    'id': event.id,
    'eventTime': formatEventTimeForApi(event.eventTime),
    'sourceType': event.sourceType,
    'rawText': event.rawText,
    'symptomSummary': event.symptomSummary,
    'notes': event.notes,
  };
}

bool _looksLikeReportSuccess(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return false;
  }

  return data['title'] is String &&
      data['summary'] is String &&
      data['markdown'] is String &&
      data['advice'] is List<dynamic>;
}

bool _looksLikeEmptyReportFallback(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return false;
  }

  final dynamic summary = data['summary'];
  final dynamic advice = data['advice'];
  if (summary is! String || advice is! List<dynamic>) {
    return false;
  }

  return summary.contains('暂无健康记录') && advice.isNotEmpty;
}

Object? _normalizeForLog(Object? data) {
  if (data is Map<String, dynamic>) {
    return data.map<String, Object?>(
      (String key, dynamic value) =>
          MapEntry<String, Object?>(key, _normalizeForLog(value)),
    );
  }

  if (data is List<dynamic>) {
    return data.map<Object?>((dynamic item) => _normalizeForLog(item)).toList();
  }

  if (data is AiReportException) {
    return <String, Object?>{
      'type': data.type.name,
      'message': data.message,
      'statusCode': data.statusCode,
    };
  }

  if (data is AiIntakeException) {
    return <String, Object?>{
      'type': data.type.name,
      'message': data.message,
      'statusCode': data.statusCode,
    };
  }

  return data;
}

String _prettyJson(Object? value) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(_normalizeForLog(value));
}

class _RecordedDioClient {
  const _RecordedDioClient({required this.dio, required this.record});

  final Dio dio;
  final _RecordedHttpInteraction record;
}

class _RecordedHttpInteraction {
  String? path;
  int? statusCode;
  Object? requestBody;
  Object? responseBody;
}

bool _looksLikeIntakeSuccess(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return false;
  }

  final dynamic draft = data['draft'];
  return (data['status'] == 'final' || data['status'] == 'needs_followup') &&
      draft is Map<String, dynamic> &&
      draft['mergedRawText'] is String &&
      draft['symptomSummary'] is String &&
      draft['notes'] is String &&
      draft['actionAdvice'] is String;
}
