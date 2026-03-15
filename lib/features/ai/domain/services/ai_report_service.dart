class AiReportEvent {
  const AiReportEvent({
    required this.id,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.sourceType,
    this.rawText,
    this.symptomSummary,
    this.notes,
  });

  final String id;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
  final String sourceType;
  final String? rawText;
  final String? symptomSummary;
  final String? notes;
}

class AiReportResult {
  const AiReportResult({
    required this.title,
    required this.summary,
    required this.advice,
    required this.markdown,
  });

  final String title;
  final String summary;
  final List<String> advice;
  final String markdown;
}

abstract class AiReportService {
  Future<AiReportResult> generateReport({
    required String reportType,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<AiReportEvent> events,
  });
}
