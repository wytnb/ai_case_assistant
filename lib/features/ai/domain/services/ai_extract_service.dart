class AiExtractResult {
  const AiExtractResult({
    required this.symptomSummary,
    required this.notes,
  });

  final String symptomSummary;
  final String? notes;
}

abstract class AiExtractService {
  Future<AiExtractResult> extractFromRawText({
    required String rawText,
    required DateTime eventTime,
  });
}
