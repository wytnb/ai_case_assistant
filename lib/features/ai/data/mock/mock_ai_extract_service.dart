import 'dart:async';

import 'package:ai_case_assistant/core/constants/health_record_limits.dart';
import 'package:ai_case_assistant/features/ai/domain/services/ai_extract_service.dart';

class MockAiExtractService implements AiExtractService {
  const MockAiExtractService();

  static const int _summaryMaxLength = 36;

  @override
  Future<AiExtractResult> extractFromRawText({
    required String rawText,
    required DateTime eventTime,
  }) async {
    final String normalizedRawText = _normalizeText(rawText);
    if (normalizedRawText.isEmpty) {
      throw StateError('rawText must not be empty');
    }
    if (normalizedRawText.length > healthRecordRawTextMaxLength) {
      throw StateError('rawText must not exceed 1000 characters');
    }

    if (_shouldFail(normalizedRawText)) {
      throw StateError('mock ai extract failed');
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));

    final String symptomSummary = _buildSymptomSummary(normalizedRawText);

    return AiExtractResult(
      symptomSummary: symptomSummary,
      notes: null,
    );
  }

  String _buildSymptomSummary(String rawText) {
    final String firstSegment = rawText
        .split(RegExp(r'[。！？?!]+'))
        .map((String segment) => segment.trim())
        .firstWhere(
          (String segment) => segment.isNotEmpty,
          orElse: () => rawText,
        );

    return _truncate(firstSegment, _summaryMaxLength);
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
