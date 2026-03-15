import 'package:ai_case_assistant/features/ai/data/mock/mock_ai_extract_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns null notes without adding mock-generated text', () async {
    const MockAiExtractService service = MockAiExtractService();

    final result = await service.extractFromRawText(
      rawText: 'Sore throat with mild cough.',
    );

    expect(result.symptomSummary, isNotEmpty);
    expect(result.notes, isNull);
    expect(result.eventStartTime.isAfter(result.eventEndTime), isFalse);
  });
}
