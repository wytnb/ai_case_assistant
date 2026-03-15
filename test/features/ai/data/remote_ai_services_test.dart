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
    test('parses notes from a valid payload without rewriting them', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'symptomSummary': 'Sore throat',
            'notes': 'Observe for two more days',
            'eventStartTime': '2026-03-15T08:00:00.000',
            'eventEndTime': '2026-03-15T09:30:00.000',
          }),
      );

      final result = await service.extractFromRawText(rawText: 'Sore throat');

      expect(result.symptomSummary, 'Sore throat');
      expect(result.notes, 'Observe for two more days');
      expect(result.eventStartTime, DateTime.parse('2026-03-15T08:00:00.000'));
      expect(result.eventEndTime, DateTime.parse('2026-03-15T09:30:00.000'));
    });

    test('returns null when notes are missing', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'symptomSummary': 'Sore throat',
            'eventStartTime': '2026-03-15T08:00:00.000',
            'eventEndTime': '2026-03-15T09:30:00.000',
          }),
      );

      final result = await service.extractFromRawText(rawText: 'Sore throat');

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
              'eventStartTime': '2026-03-15T08:00:00.000',
              'eventEndTime': '2026-03-15T09:30:00.000',
            }),
        );

        final result = await service.extractFromRawText(rawText: 'Sore throat');

        expect(result.notes, isNull);
      }
    });

    test('rejects payloads missing event time fields', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'symptomSummary': 'Sore throat',
            'notes': 'Observe for two more days',
            'eventStartTime': '2026-03-15T08:00:00.000',
          }),
      );

      expect(
        () => service.extractFromRawText(rawText: 'Sore throat'),
        throwsA(
          isA<AiExtractException>().having(
            (AiExtractException error) => error.type,
            'type',
            AiExtractExceptionType.invalidResponsePayload,
          ),
        ),
      );
    });

    test('rejects payloads with reversed event time range', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'symptomSummary': 'Sore throat',
            'notes': 'Observe for two more days',
            'eventStartTime': '2026-03-15T10:00:00.000',
            'eventEndTime': '2026-03-15T09:30:00.000',
          }),
      );

      expect(
        () => service.extractFromRawText(rawText: 'Sore throat'),
        throwsA(
          isA<AiExtractException>().having(
            (AiExtractException error) => error.type,
            'type',
            AiExtractExceptionType.invalidResponsePayload,
          ),
        ),
      );
    });
  });

  group('RemoteAiReportService', () {
    test(
      'sends eventStartTime and eventEndTime without legacy eventTime',
      () async {
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
              eventStartTime: DateTime.parse('2026-03-15T08:00:00.000'),
              eventEndTime: DateTime.parse('2026-03-15T09:30:00.000'),
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
        expect(eventPayload['eventStartTime'], '2026-03-15T08:00:00.000');
        expect(eventPayload['eventEndTime'], '2026-03-15T09:30:00.000');
        expect(eventPayload.containsKey('eventTime'), isFalse);
      },
    );
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
