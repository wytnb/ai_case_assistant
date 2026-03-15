class AiExtractResult {
  const AiExtractResult({
    required this.symptomSummary,
    required this.notes,
    required this.eventStartTime,
    required this.eventEndTime,
  });

  final String symptomSummary;
  final String? notes;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
}

abstract class AiExtractService {
  Future<AiExtractResult> extractFromRawText({required String rawText});
}
