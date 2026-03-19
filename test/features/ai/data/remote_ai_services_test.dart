import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_extract_service.dart';
import 'package:ai_case_assistant/features/ai/data/remote/remote_ai_report_service.dart';
import 'package:ai_case_assistant/features/ai/domain/exceptions/ai_extract_exception.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_report_service.dart';
import 'package:ai_case_assistant/features/intake/data/remote/remote_ai_intake_service.dart';
import 'package:ai_case_assistant/features/intake/domain/exceptions/ai_intake_exception.dart';
import 'package:ai_case_assistant/features/intake/domain/services/ai_intake_service.dart';
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
      },
    );

    test('preserves blank notes when the field exists', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'symptomSummary': 'Sore throat',
            'notes': '   ',
          }),
      );

      final result = await service.extractFromRawText(
        rawText: 'Sore throat',
        eventTime: DateTime.utc(2026, 3, 15, 0),
      );

      expect(result.notes, '');
    });

    test(
      'preserves blank symptomSummary instead of falling back to rawText',
      () async {
        final RemoteAiExtractService service = RemoteAiExtractService(
          dio: Dio()
            ..httpClientAdapter = _buildAdapter(<String, dynamic>{
              'symptomSummary': '   ',
            }),
        );

        final result = await service.extractFromRawText(
          rawText: 'Sore throat with mild cough.',
          eventTime: DateTime.utc(2026, 3, 15, 0),
        );

        expect(result.symptomSummary, '');
      },
    );

    test('rejects payloads where symptomSummary is missing', () async {
      final RemoteAiExtractService service = RemoteAiExtractService(
        dio: Dio()..httpClientAdapter = _buildAdapter(<String, dynamic>{}),
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
  });

  group('RemoteAiIntakeService', () {
    test('sends expected intake request body', () async {
      late Map<String, dynamic> requestPayload;
      final RemoteAiIntakeService service = RemoteAiIntakeService(
        dio: Dio()
          ..httpClientAdapter = TestHttpClientAdapter((
            RequestOptions options,
          ) async {
            requestPayload = Map<String, dynamic>.from(
              options.data as Map<String, dynamic>,
            );
            return ResponseBody.fromString(
              jsonEncode(<String, dynamic>{
                'status': 'final',
                'question': null,
                'draft': <String, dynamic>{
                  'mergedRawText': 'merged',
                  'symptomSummary': 'summary',
                  'notes': '',
                  'actionAdvice': '',
                },
              }),
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>['application/json'],
              },
            );
          }),
      );

      await service.submitIntake(
        followUpMode: false,
        forceFinalize: false,
        eventTime: DateTime.utc(2026, 3, 15, 0),
        messages: const <IntakeRequestMessage>[
          IntakeRequestMessage(
            role: IntakeMessageRole.user,
            content: 'Sore throat',
          ),
        ],
      );

      expect(requestPayload['followUpMode'], false);
      expect(requestPayload['forceFinalize'], false);
      expect(requestPayload['eventTime'], '2026-03-15T08:00:00+08:00');
      expect(requestPayload['messages'], <Map<String, dynamic>>[
        <String, dynamic>{'role': 'user', 'content': 'Sore throat'},
      ]);
    });

    test('parses needs_followup payload', () async {
      final RemoteAiIntakeService service = RemoteAiIntakeService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'status': 'needs_followup',
            'question': '有没有发烧？',
            'draft': <String, dynamic>{
              'mergedRawText': '喉咙痛两天',
              'symptomSummary': '喉咙痛',
              'notes': '',
              'actionAdvice': '继续观察体温',
            },
          }),
      );

      final result = await service.submitIntake(
        followUpMode: true,
        forceFinalize: false,
        eventTime: DateTime.utc(2026, 3, 15, 0),
        messages: const <IntakeRequestMessage>[
          IntakeRequestMessage(role: IntakeMessageRole.user, content: '喉咙痛两天'),
        ],
      );

      expect(result.status, IntakeResponseStatus.needsFollowup);
      expect(result.question, '有没有发烧？');
      expect(result.draft.symptomSummary, '喉咙痛');
      expect(result.draft.notes, '');
      expect(result.draft.actionAdvice, '继续观察体温');
    });

    test('parses final payload and preserves blank symptomSummary', () async {
      final RemoteAiIntakeService service = RemoteAiIntakeService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'status': 'final',
            'question': null,
            'draft': <String, dynamic>{
              'mergedRawText': 'merged',
              'symptomSummary': '   ',
              'notes': '',
              'actionAdvice': '',
            },
          }),
      );

      final result = await service.submitIntake(
        followUpMode: true,
        forceFinalize: false,
        eventTime: DateTime.utc(2026, 3, 15, 0),
        messages: const <IntakeRequestMessage>[
          IntakeRequestMessage(role: IntakeMessageRole.user, content: 'text'),
        ],
      );

      expect(result.status, IntakeResponseStatus.finalResult);
      expect(result.question, isNull);
      expect(result.draft.symptomSummary, '');
    });

    test('rejects payloads where draft.symptomSummary is missing', () async {
      final RemoteAiIntakeService service = RemoteAiIntakeService(
        dio: Dio()
          ..httpClientAdapter = _buildAdapter(<String, dynamic>{
            'status': 'final',
            'question': null,
            'draft': <String, dynamic>{
              'mergedRawText': 'merged',
              'notes': '',
              'actionAdvice': '',
            },
          }),
      );

      expect(
        () => service.submitIntake(
          followUpMode: true,
          forceFinalize: false,
          eventTime: DateTime.utc(2026, 3, 15, 0),
          messages: const <IntakeRequestMessage>[
            IntakeRequestMessage(role: IntakeMessageRole.user, content: 'text'),
          ],
        ),
        throwsA(
          isA<AiIntakeException>().having(
            (AiIntakeException error) => error.type,
            'type',
            AiIntakeExceptionType.invalidResponsePayload,
          ),
        ),
      );
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
