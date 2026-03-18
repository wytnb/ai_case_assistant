import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_report_service.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteAiExtractService', () {
    test(
      'parses notes from a valid payload and sends +08:00 eventTime without milliseconds',
      () async {
      late Map<String, dynamic> requestPayload;
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = TestHttpClientAdapter((
            RequestOptions options,
          ) async {
            requestPayload = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{
                'symptomSummary': 'Sore throat',
                'notes': 'Observe for two more days',
              }),
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          }),
      );

      final DateTime eventTime = DateTime.utc(2026, 3, 15, 0);
      final result = await service.extractFromRawText(
        rawText: 'Sore throat',
        eventTime: eventTime,
      );

      expect(requestPayload['rawText'], 'Sore throat');
      expect(requestPayload['eventTime'], '2026-03-15T08:00:00+08:00');
      expect(result.symptomSummary, 'Sore throat');
      expect(result.notes, 'Observe for two more days');
    });

    test('returns null when notes are missing', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'symptomSummary': 'Sore throat',
          }),
      );

      final result = await service.extractFromRawText(
        rawText: 'Sore throat',
        eventTime: DateTime.utc(2026, 3, 15, 0),
      );

      expect(result.notes, isNull);
    });

    test('returns null when notes are blank or invalid', () async {
      final List<dynamic> invalidNotesValues = <dynamic>['   ', 123, false];

      for (final dynamic invalidValue in invalidNotesValues) {
        final RemoteAiExtractService service = RemoteAiExtractService(
          dio: Dio()
            ..httpClientAdapter = _buildAdapter(<String, dynamic>{
              'symptomSummary': 'Sore throat',
              'notes': invalidValue,
            }),
        );

        final result = await service.extractFromRawText(
          rawText: 'Sore throat',
          eventTime: DateTime.utc(2026, 3, 15, 0),
        );

        expect(result.notes, isNull);
      }
    });

    test('falls back to rawText when symptomSummary is missing', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()..httpClientAdapter = _buildAdapter(<String, dynamic>{}),
      );

      final result = await service.extractFromRawText(
        rawText: 'Sore throat with mild cough.',
        eventTime: DateTime.utc(2026, 3, 15, 0),
      );

      expect(result.symptomSummary, 'Sore throat with mild cough.');
    });

    test('rejects non-object payloads', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()..httpClientAdapter = _buildRawAdapter(<dynamic>['invalid']),
      );

      expect(
        () => service.extractFromRawText(
          rawText: 'Sore throat',
          eventTime: DateTime.utc(2026, 3, 15, 0),
        ),
        throwsA(
          isA<AiExtractException>().having(
            (AiExtractException error) => error.type,
            'type',
            AiExtractExceptionType.invalidResponsePayload,
          ),
        ),
      );
    });

    test('rejects rawText longer than 1000 characters before sending request', () async {
      int requestCount = 0;
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = TestHttpClientAdapter((
            RequestOptions options,
          ) async {
            requestCount += 1;
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{'symptomSummary': 'summary'}),
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          }),
      );
      final String rawText = List<String>.filled(1001, 'a').join();

      expect(
        () => service.extractFromRawText(
          rawText: rawText,
          eventTime: DateTime.utc(2026, 3, 15, 0),
        ),
        throwsA(
          isA<AiExtractException>().having(
            (AiExtractException error) => error.type,
            'type',
            AiExtractExceptionType.invalidRequestPayload,
          ),
        ),
      );
      expect(requestCount, 0);
    });
  });

  group('RemoteAiReportService', () {
    test('sends eventTime without legacy event fields', () async {
      late Map<String, dynamic> requestPayload;
      final TestHttpClientAdapter adapter = TestHttpClientAdapter((
        RequestOptions options,
      ) async {
        requestPayload = Map<String, dynamic>.from(
          options.data as Map<String, dynamic>,
        );
        return ResponseBody.fromString(
          jsonEncode(<String, dynamic>{
            'title': 'Weekly report',
            'summary': 'Summary',
            'advice': <String>['Rest'],
            'markdown': '# Weekly report',
          }),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
          },
        );
      });
      final RemoteAiReportService service = RemoteAiReportService(
        dio: Dio()..httpClientAdapter = adapter,
      );

      await service.generateReport(
        reportType: 'week',
        rangeStart: DateTime.parse('2026-03-10T00:00:00.000'),
        rangeEnd: DateTime.parse('2026-03-16T23:59:59.000'),
        events: <AiReportEvent>[
          AiReportEvent(
            id: 'event-1',
            eventTime: DateTime.utc(2026, 3, 15, 0),
            sourceType: 'text',
            rawText: 'Sore throat',
            symptomSummary: 'Sore throat',
            notes: 'Observe for two more days',
          ),
        ],
      );

      final Map<String, dynamic> eventPayload =
          (requestPayload['events'] as List<dynamic>).single
              as Map<String, dynamic>;
      expect(eventPayload['eventTime'], '2026-03-15T08:00:00+08:00');
      expect(eventPayload.containsKey('eventStartTime'), isFalse);
      expect(eventPayload.containsKey('eventEndTime'), isFalse);
    });
  });
}

TestHttpClientAdapter _buildAdapter(Map<String, dynamic> payload) {
  return TestHttpClientAdapter(
    (RequestOptions options) async => ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    ),
  );
}

TestHttpClientAdapter _buildRawAdapter(Object payload) {
  return TestHttpClientAdapter(
    (RequestOptions options) async => ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    ),
  );
}

class TestHttpClientAdapter implements HttpClientAdapter {
  TestHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
