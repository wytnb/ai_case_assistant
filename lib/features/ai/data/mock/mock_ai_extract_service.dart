import 'dart:async';

import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';

class MockAiExtractService implements AiExtractService {
  const MockAiExtractService();

  static const int _summaryMaxLength = 36;
  static const int _previewMaxLength = 60;

  @override
  Future<AiExtractResult> extractFromRawText({required String rawText}) async {
    final String normalizedRawText = _normalizeText(rawText);
    if (normalizedRawText.isEmpty) {
      throw StateError('rawText must not be empty');
    }

    if (_shouldFail(normalizedRawText)) {
      throw StateError('mock ai extract failed');
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));

    final String symptomSummary = _buildSymptomSummary(normalizedRawText);
    final String notes = _buildNotes(
      rawText: normalizedRawText,
      symptomSummary: symptomSummary,
    );

    return AiExtractResult(symptomSummary: symptomSummary, notes: notes);
  }

  String _buildSymptomSummary(String rawText) {
    final String firstSegment = rawText
        .split(RegExp(r'[。！？!?；;]+'))
        .map((String segment) => segment.trim())
        .firstWhere(
          (String segment) => segment.isNotEmpty,
          orElse: () => rawText,
        );

    return _truncate(firstSegment, _summaryMaxLength);
  }

  String _buildNotes({
    required String rawText,
    required String symptomSummary,
  }) {
    final String preview = _truncate(rawText, _previewMaxLength);
    return 'AI mock整理：已根据原始描述提炼出“$symptomSummary”。原始描述已保留，便于后续继续核对。重点内容：$preview';
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}...';
  }

  bool _shouldFail(String rawText) {
    return rawText.toLowerCase().contains('mock_fail');
  }
}
